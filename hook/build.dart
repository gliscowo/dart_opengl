import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    final glUri = Uri.file(switch (input.config.code.targetOS) {
      OS.linux => 'libGL.so.1',
      OS.windows => 'Opengl32.dll',
      OS.macOS => '/System/Library/Frameworks/OpenGL.framework/Versions/Current/OpenGL',
      _ => throw Exception('${input.packageName} does not support ${input.config.code.targetOS.name}'),
    });

    output.assets.code.add(CodeAsset(package: input.packageName, name: 'gl', linkMode: DynamicLoadingSystem(glUri)));
  });
}
