import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'gl_functions.dart';

OpenGL? _instance;

/// Load the OpenGL functions of this platform's standard OpenGL library
/// or the ones located in the binary at [libaryPath], if provided
OpenGL loadOpenGLFromPath([String? libraryPath]) {
  if (_instance != null) return _instance!;

  if (libraryPath == null) {
    if (Platform.isWindows) {
      libraryPath = "Opengl32.dll";
    } else if (Platform.isLinux) {
      libraryPath = "libGL.so.1";
    } else if (Platform.isMacOS) {
      libraryPath = "/System/Library/Frameworks/OpenGL.framework/Versions/Current/OpenGL";
    } else {
      throw GlInitError(
        "Cannot locate OpenGL binary on platform ${Platform.operatingSystem}, a path must be supplied manually",
      );
    }
  }

  DynamicLibrary openGlLibrary;
  try {
    openGlLibrary = DynamicLibrary.open(libraryPath);
  } catch (e) {
    throw GlInitError("Failed to load OpenGL binary", e);
  }

  return loadOpenGL(openGlLibrary);
}

/// Load the OpenGL functions from [library]
OpenGL loadOpenGL(DynamicLibrary library) {
  String? getProcAddressFunction;
  if (Platform.isLinux) {
    getProcAddressFunction = "glXGetProcAddress";
  } else if (Platform.isWindows) {
    getProcAddressFunction = "wglGetProcAddress";
  }

  int Function(Pointer<Utf8>)? getProcAddress;
  if (getProcAddressFunction != null) {
    try {
      getProcAddress = library.lookupFunction<Int64 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>(
          getProcAddressFunction,
          isLeaf: true);
    } catch (e) {
      throw GlInitError("Failed to link platform-specific OpenGL API retrieval function", e);
    }
  }

  Pointer<T> lookupSymbol<T extends NativeType>(String symbol) {
    if (library.providesSymbol(symbol)) {
      return library.lookup(symbol);
    } else if (getProcAddress != null) {
      return Pointer.fromAddress(getProcAddress(symbol.toNativeUtf8()));
    } else {
      return nullptr;
    }
  }

  return _instance = OpenGL(lookupSymbol);
}

class GlInitError extends Error {
  final String message;
  final Object? cause;

  GlInitError(this.message, [this.cause]);

  @override
  String toString() => cause != null ? "$message\nCaused by: $cause" : message;
}
