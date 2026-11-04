import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

void main() {
  testWidgets('picks a mode and marks the chosen one', (tester) async {
    ThemeMode? picked;
    await tester.pumpWidget(
      wrap(
        PanelThemeSelector(
          label: 'Appearance',
          value: ThemeMode.system,
          onChanged: (m) => picked = m,
        ),
      ),
    );
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(picked, ThemeMode.dark);
    expect(
      tester.getSemantics(find.bySemanticsLabel('System')),
      isSemantics(
        label: 'System',
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
  });

  testWidgets('is a radio group named once, by its heading', (tester) async {
    await tester.pumpWidget(
      wrap(
        PanelThemeSelector(
          label: 'Appearance',
          value: ThemeMode.light,
          onChanged: (_) {},
        ),
      ),
    );
    expect(
      tester.getSemantics(
        find
            .descendant(
              of: find.byType(PanelThemeSelector),
              matching: find.byType(Semantics),
            )
            .first,
      ),
      isSemantics(label: 'Appearance', role: SemanticsRole.radioGroup),
    );
    expect(find.bySemanticsLabel('Appearance'), findsOneWidget);
  });

  testWidgets('draws the options it is given, in order', (tester) async {
    await tester.pumpWidget(
      wrap(
        PanelThemeSelector(
          options: const [ThemeMode.dark, ThemeMode.light],
          value: ThemeMode.light,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('System'), findsNothing);
    expect(
      tester.getCenter(find.text('Dark')).dx,
      lessThan(tester.getCenter(find.text('Light')).dx),
    );
  });

  testWidgets('a press does not shrink an option', (tester) async {
    await tester.pumpWidget(
      wrap(PanelThemeSelector(value: ThemeMode.light, onChanged: (_) {})),
    );
    final press = await tester.startGesture(
      tester.getCenter(find.text('Dark')),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      find.descendant(
        of: find.byType(PanelThemeSelector),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    await press.up();
  });

  testWidgets('the artwork keeps its proportions at the small size', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PanelThemeSelector(
          size: PanelThemeSelectorSize.sm,
          value: ThemeMode.light,
          onChanged: (_) {},
        ),
      ),
    );
    final artwork = find.descendant(
      of: find.byType(PanelThemeSelector),
      matching: find.byType(CustomPaint),
    );
    // 72 wide, and 70/88 of that rounded: 57.
    expect(tester.getSize(artwork.first), const Size(72, 57));
  });

  testWidgets('can draw an option with artwork of its own', (tester) async {
    await tester.pumpWidget(
      wrap(
        PanelThemeSelector(
          value: ThemeMode.dark,
          onChanged: (_) {},
          previewBuilder: (context, mode) =>
              SizedBox(width: 60, height: 40, child: Text('shot ${mode.name}')),
        ),
      ),
    );
    expect(find.text('shot dark'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PanelThemeSelector),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  testWidgets('a null onChanged disables it', (tester) async {
    await tester.pumpWidget(
      wrap(const PanelThemeSelector(value: ThemeMode.light, onChanged: null)),
    );
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.4);
  });

  testWidgets('both artworks build in every theme', (tester) async {
    for (final theme in allThemes) {
      for (final variant in PanelThemePreviewVariant.values) {
        await tester.pumpWidget(
          wrap(
            theme: theme,
            PanelThemeSelector(
              variant: variant,
              size: PanelThemeSelectorSize.sm,
              value: ThemeMode.dark,
              onChanged: (_) {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    }
  });
}
