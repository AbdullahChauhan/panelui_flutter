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
