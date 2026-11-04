import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

Widget _steps({
  int? value,
  int initialValue = 0,
  ValueChanged<int>? onChanged,
  Axis orientation = Axis.horizontal,
  int? loadingStep,
  int? disabledStep,
}) {
  const titles = ['Account', 'Profile', 'Billing'];
  return PanelSteps(
    value: value,
    initialValue: initialValue,
    onChanged: onChanged,
    orientation: orientation,
    children: [
      for (var i = 0; i < titles.length; i++)
        PanelStep(
          loading: i == loadingStep,
          enabled: i != disabledStep,
          title: Text(titles[i]),
          description: const Text('A line about it'),
        ),
    ],
  );
}

Finder _step(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(PanelPressable));

void main() {
  testWidgets('builds both orientations in every theme', (tester) async {
    for (final theme in allThemes) {
      for (final orientation in Axis.values) {
        await tester.pumpWidget(
          wrap(
            _steps(value: 1, orientation: orientation, onChanged: (_) {}),
            theme: theme,
          ),
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('each step works out its own state', (tester) async {
    await tester.pumpWidget(wrap(_steps(value: 1)));
    // Before the current step: a check. The current one and those after it:
    // their numbers.
    expect(
      find.byWidgetPredicate(
        (w) => w is PanelIcon && w.icon == PanelIcons.check,
      ),
      findsOneWidget,
    );
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('a loading step shows a spinner while current', (tester) async {
    await tester.pumpWidget(wrap(_steps(value: 1, loadingStep: 1)));
    expect(find.byType(PanelSpinner), findsOneWidget);
    expect(find.text('2'), findsNothing);
    await tester.pumpWidget(wrap(_steps(value: 0, loadingStep: 1)));
    expect(find.byType(PanelSpinner), findsNothing);
  });

  testWidgets('a loading step spins even when forced complete', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PanelSteps(
          value: 1,
          children: [
            PanelStep(),
            PanelStep(completed: true, loading: true),
            PanelStep(),
          ],
        ),
      ),
    );
    expect(find.byType(PanelSpinner), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is PanelIcon && w.icon == PanelIcons.check,
      ),
      findsOneWidget,
    );
  });

  testWidgets('pressing a step selects it', (tester) async {
    final steps = <int>[];
    await tester.pumpWidget(wrap(_steps(onChanged: steps.add)));
    await tester.tap(find.text('Billing'));
    await tester.pumpAndSettle();
    expect(steps, [2]);
    // Uncontrolled, it moved: the two before are now complete.
    expect(
      find.byWidgetPredicate(
        (w) => w is PanelIcon && w.icon == PanelIcons.check,
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('a disabled step ignores presses', (tester) async {
    final steps = <int>[];
    await tester.pumpWidget(
      wrap(_steps(disabledStep: 2, onChanged: steps.add)),
    );
    await tester.tap(find.text('Billing'));
    await tester.pumpAndSettle();
    expect(steps, isEmpty);
  });

  testWidgets('without onChanged the stepper is read-only', (tester) async {
    await tester.pumpWidget(wrap(_steps(value: 1)));
    expect(find.byType(PanelPressable), findsNothing);
  });

  testWidgets('steps announce their position and state', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(_steps(value: 1, onChanged: (_) {})));
    expect(
      tester.getSemantics(_step('Account')),
      isSemantics(value: 'step 1 of 3, completed', isSelected: false),
    );
    expect(
      tester.getSemantics(_step('Profile')),
      isSemantics(
        value: 'step 2 of 3, current step',
        isSelected: true,
        isButton: true,
      ),
    );
    expect(
      tester.getSemantics(_step('Billing')),
      isSemantics(value: 'step 3 of 3, not started'),
    );
    handle.dispose();
  });

  testWidgets('connectors fill once the step before them is done', (
    tester,
  ) async {
    final colors = PanelThemeData.panelLight.colors;
    for (final orientation in Axis.values) {
      await tester.pumpWidget(wrap(_steps(value: 1, orientation: orientation)));
      final lines = find.descendant(
        of: find.byType(PanelSteps),
        matching: find.byType(ColoredBox),
      );
      // Two connectors for three steps; the first leads out of a done step.
      expect(tester.widgetList<ColoredBox>(lines).map((line) => line.color), [
        colors.primary,
        colors.muted,
      ]);
      final first = tester.getSize(lines.first);
      expect(orientation == Axis.horizontal ? first.height : first.width, 2);
    }
  });

  testWidgets('a vertical connector runs down the middle of its circle', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(_steps(value: 1, orientation: Axis.vertical)));
    final line = tester.getRect(
      find
          .descendant(
            of: find.byType(PanelSteps),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    final steps = tester.getRect(find.byType(PanelSteps));
    expect(line.left - steps.left, 14);
    expect(line.height, 32);
  });

  testWidgets('a read-only stepper still says where each step stands', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(_steps(value: 1)));
    expect(find.bySemanticsLabel(RegExp('Billing')), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Billing')),
      isSemantics(value: 'step 3 of 3, not started', isButton: false),
    );
    handle.dispose();
  });
}
