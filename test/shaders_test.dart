import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_ui/liquid_glass_ui.dart';

const List<String> _shaders = <String>[
  'glass_lighting.frag',
  'glass_refraction.frag',
];

void main() {
  tearDown(LiquidGlassShaders.debugReset);

  testWidgets('shader programs load from the asset bundle', (tester) async {
    expect(LiquidGlassShaders.status.value, LiquidGlassShaderStatus.notLoaded);
    await tester.runAsync(LiquidGlassShaders.ensureLoaded);
    expect(LiquidGlassShaders.status.value, LiquidGlassShaderStatus.ready);
    expect(LiquidGlassShaders.lightingProgram, isNotNull);
    expect(LiquidGlassShaders.refractionProgram, isNotNull);
    expect(LiquidGlassShaders.loadError, isNull);
  });

  testWidgets('surfaces paint with the lighting shader once loaded', (
    tester,
  ) async {
    await tester.runAsync(LiquidGlassShaders.ensureLoaded);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: LiquidGlassSurface(quality: LiquidGlassQuality.standard),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium falls back when backdrop shaders are unsupported', (
    tester,
  ) async {
    await tester.runAsync(LiquidGlassShaders.ensureLoaded);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: LiquidGlassSurface(quality: LiquidGlassQuality.premium),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    if (!LiquidGlassShaders.rendererSupportsBackdropShaders) {
      expect(LiquidGlassShaders.supportsRefraction, isFalse);
      expect(find.byType(BackdropFilter), findsOneWidget);
    }
  });

  group('impellerc compilation', () {
    final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final String exe = Platform.isWindows ? 'impellerc.exe' : 'impellerc';
    File? impellerc;
    Directory? shaderLib;
    if (flutterRoot != null) {
      final Directory engine = Directory(
        '$flutterRoot/bin/cache/artifacts/engine',
      );
      if (engine.existsSync()) {
        for (final FileSystemEntity e in engine.listSync(recursive: true)) {
          if (impellerc == null &&
              e is File &&
              e.uri.pathSegments.last == exe) {
            impellerc = e;
          }
          if (shaderLib == null &&
              e is Directory &&
              e.uri.pathSegments.where((s) => s.isNotEmpty).last ==
                  'shader_lib') {
            shaderLib = e;
          }
        }
      }
    }
    final bool available = impellerc != null && shaderLib != null;

    for (final String shader in _shaders) {
      test(
        '$shader compiles for SkSL, GLES, Vulkan and Metal',
        () async {
          final Directory out = await Directory.systemTemp.createTemp('lg');
          try {
            final ProcessResult result =
                await Process.run(impellerc!.path, <String>[
                  '--sksl',
                  '--runtime-stage-gles',
                  '--runtime-stage-gles3',
                  '--runtime-stage-vulkan',
                  '--runtime-stage-metal',
                  '--iplr',
                  '--sl=${out.path}/$shader.iplr',
                  '--spirv=${out.path}/$shader.spirv',
                  '--input=shaders/$shader',
                  '--input-type=frag',
                  '--include=shaders',
                  '--include=${shaderLib!.path}',
                ]);
            expect(
              result.exitCode,
              0,
              reason: '${result.stdout}\n${result.stderr}',
            );
          } finally {
            await out.delete(recursive: true);
          }
        },
        skip: available ? false : 'impellerc not found in the Flutter SDK',
      );
    }
  });
}
