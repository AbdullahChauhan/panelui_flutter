import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

void main() {
  group('PanelOtpInput', () {
    testWidgets('spreads the code over cells and completes once', (
      tester,
    ) async {
      final completed = <String>[];
      final changes = <String>[];
      await tester.pumpWidget(
        wrap(
          PanelOtpInput(
            length: 4,
            onChanged: changes.add,
            onCompleted: completed.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '12a3');
      await tester.pump();
      // Digits only.
      expect(changes.last, '123');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(completed, isEmpty);
      await tester.enterText(find.byType(TextField), '12345');
      await tester.pumpAndSettle();
      expect(completed, ['1234']);
      expect(find.text('5'), findsNothing);
    });

    testWidgets('masks characters and shows an error', (tester) async {
      final controller = TextEditingController(text: '42');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wrap(
          PanelOtpInput(
            controller: controller,
            mask: true,
            groupEvery: 3,
            errorMessage: 'That code has expired.',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('•'), findsNWidgets(2));
      expect(find.text('4'), findsNothing);
      expect(find.text('That code has expired.'), findsOneWidget);
    });

    testWidgets('builds in every theme', (tester) async {
      for (final theme in allThemes) {
        await tester.pumpWidget(
          wrap(theme: theme, const PanelOtpInput(placeholder: '0')),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('PanelNumberInput', () {
    Widget host({double initial = 1, double min = 0, double max = 3}) {
      var value = initial;
      return wrap(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 240,
            child: PanelNumberInput(
              label: 'Quantity',
              value: value,
              min: min,
              max: max,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
    }

    testWidgets('a tap steps exactly once', (tester) async {
      await tester.pumpWidget(host());
      await tester.tap(find.bySemanticsLabel('Increase Quantity'));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Decrease Quantity'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('holding repeats and stops at the bound', (tester) async {
      await tester.pumpWidget(host(initial: 0, max: 5));
      final gesture = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('Increase Quantity')),
      );
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('typed text is snapped and clamped on submit', (tester) async {
      await tester.pumpWidget(host(max: 10));
      await tester.enterText(find.byType(TextField), '42');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('10'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('10'), findsOneWidget);
    });
  });
}
