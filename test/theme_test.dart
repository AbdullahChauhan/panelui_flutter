import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

void main() {
  group('generated tokens', () {
    test('match PanelUI theme.css', () {
      // Spot checks against the CSS, one per kind of value.
      expect(PanelColors.panelLight.background, const Color(0xFFFFFFFF));
      expect(PanelColors.panelLight.foreground, const Color(0xFF262626));
      expect(PanelColors.panelDark.background, const Color(0xFF141414));
      expect(PanelColors.moonDark.primary, const Color(0xFF5E6AD2));
      expect(PanelColors.grassLight.primary, const Color(0xFF24B47E));
      // rgba(0, 0, 0, 0.035) -> alpha round(0.035 * 255) = 9
      expect(PanelColors.panelLight.inset, const Color(0x09000000));
      // rgba(255, 255, 255, 0.08)
      expect(PanelColors.panelDark.muted, const Color(0x14FFFFFF));
    });

    test('radius scales differ by family', () {
      expect(PanelRadii.panel.lg, 10);
      expect(PanelRadii.moon.lg, 12);
      expect(PanelRadii.grass.lg, 14);
      expect(PanelRadii.panel.xxxl, 24);
    });

    test('every family pairs a light and a dark theme', () {
      for (final family in PanelThemeFamily.values) {
        expect(family.light.brightness, Brightness.light);
        expect(family.dark.brightness, Brightness.dark);
        expect(family.resolve(Brightness.dark), family.dark);
      }
    });
  });

  group('PanelThemeData', () {
    test('lerp reaches both ends', () {
      const a = PanelThemeData.panelLight;
      const b = PanelThemeData.moonDark;
      expect(a.lerp(b, 0).colors, a.colors);
      expect(a.lerp(b, 1).colors, b.colors);
      expect(a.lerp(b, 1).radii, b.radii);
      expect(a.lerp(b, 0.5).radii.lg, 11);
    });

    test('copyWith replaces only what is given', () {
      final custom = PanelThemeData.panelLight.copyWith(
        colors: PanelColors.panelLight.copyWith(
          primary: const Color(0xFF0000FF),
        ),
      );
      expect(custom.colors.primary, const Color(0xFF0000FF));
      expect(custom.colors.background, PanelColors.panelLight.background);
      expect(custom.radii, PanelRadii.panel);
    });

    test('toMaterialTheme carries the extension and the palette', () {
      final material = PanelThemeData.grassDark.toMaterialTheme();
      expect(material.extension<PanelThemeData>(), PanelThemeData.grassDark);
      expect(material.brightness, Brightness.dark);
      expect(material.colorScheme.primary, PanelColors.grassDark.primary);
      expect(
        material.scaffoldBackgroundColor,
        PanelColors.grassDark.background,
      );
    });
  });

  group('PanelTheme.of', () {
    testWidgets('prefers an enclosing PanelTheme', (tester) async {
      late PanelThemeData found;
      await tester.pumpWidget(
        MaterialApp(
          theme: PanelThemeData.panelLight.toMaterialTheme(),
          home: PanelTheme(
            data: PanelThemeData.moonDark,
            child: Builder(
              builder: (context) {
                found = PanelTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(found, PanelThemeData.moonDark);
    });

    testWidgets('falls back to the Material extension', (tester) async {
      late PanelThemeData found;
      await tester.pumpWidget(
        MaterialApp(
          theme: PanelThemeData.grassLight.toMaterialTheme(),
          home: Builder(
            builder: (context) {
              found = context.panelTheme;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(found, PanelThemeData.grassLight);
    });

    testWidgets('falls back to Panel in the platform brightness', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      late PanelThemeData found;
      await tester.pumpWidget(
        MediaQuery.fromView(
          view: tester.view,
          child: Builder(
            builder: (context) {
              found = PanelTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(found, PanelThemeData.panelDark);
    });

    testWidgets('AnimatedPanelTheme crossfades to the new theme', (
      tester,
    ) async {
      PanelThemeData? found;
      Widget build(PanelThemeData data) => Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedPanelTheme(
          data: data,
          child: Builder(
            builder: (context) {
              found = PanelTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(build(PanelThemeData.panelLight));
      await tester.pumpWidget(build(PanelThemeData.panelDark));
      await tester.pump(const Duration(milliseconds: 125));
      expect(
        found!.colors.background,
        isNot(PanelColors.panelLight.background),
      );
      expect(found!.colors.background, isNot(PanelColors.panelDark.background));
      await tester.pumpAndSettle();
      expect(found!.colors, PanelColors.panelDark);
    });
  });

  test('type scale pairs sizes with Tailwind line heights', () {
    const typography = PanelTypography();
    final sm = typography.style(PanelTextSize.sm);
    expect(sm.fontSize, 14);
    expect(sm.fontSize! * sm.height!, 20);
    expect(sm.leadingDistribution, TextLeadingDistribution.even);
    expect(typography.sized(13).height, isNull);
  });
}
