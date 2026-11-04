import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

void main() {
  group('PanelOtpInput', () {
    Finder caret() => find.descendant(
      of: find.byType(PanelOtpInput),
      matching: find.byType(FadeTransition),
    );

    // A cell's character, and not the hidden field holding the same text.
    Finder cellText(String text) =>
        find.byWidgetPredicate((w) => w is Text && w.data == text);

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
      // An edit that leaves it full is not a second completion.
      await tester.enterText(find.byType(TextField), '4321');
      await tester.pumpAndSettle();
      expect(completed, ['1234']);
    });

    testWidgets('a code set from outside is trimmed and does not complete', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final completed = <String>[];
      await tester.pumpWidget(
        wrap(
          PanelOtpInput(
            length: 4,
            controller: controller,
            onCompleted: completed.add,
          ),
        ),
      );
      controller.text = 'ab123456';
      await tester.pumpAndSettle();
      expect(controller.text, '1234');
      expect(find.text('4'), findsOneWidget);
      expect(completed, isEmpty);
      // Typed back to full, it completes.
      await tester.enterText(find.byType(TextField), '123');
      await tester.enterText(find.byType(TextField), '1239');
      await tester.pumpAndSettle();
      expect(completed, ['1239']);
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
            semanticLabel: 'Verification code',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('•'), findsNWidgets(2));
      expect(find.text('4'), findsNothing);
      expect(find.text('That code has expired.'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(
          label: 'Verification code',
          isTextField: true,
          validationResult: SemanticsValidationResult.invalid,
        ),
      );
    });

    testWidgets('a character zooms in without fading', (tester) async {
      await tester.pumpWidget(wrap(const PanelOtpInput(length: 4)));
      await tester.enterText(find.byType(TextField), '7');
      await tester.pump();
      double scale() => tester
          .widget<Transform>(
            find.ancestor(of: cellText('7'), matching: find.byType(Transform)),
          )
          .transform
          .storage[0];
      // A quarter of the way through 140ms, on Reanimated's ease-in-out
      // curve: an eighth of the size, where a linear zoom would be a quarter.
      await tester.pump(const Duration(milliseconds: 35));
      expect(scale(), closeTo(0.125, 0.03));
      final opacities = tester.widgetList<Opacity>(
        find.ancestor(of: cellText('7'), matching: find.byType(Opacity)),
      );
      expect(opacities.map((o) => o.opacity), everyElement(1));
      // Not settled: the caret blinks on in the next cell.
      await tester.pump(const Duration(milliseconds: 105));
      expect(scale(), 1);
    });

    testWidgets('the caret is lit for 560ms and then fades', (tester) async {
      await tester.pumpWidget(wrap(const PanelOtpInput(length: 4)));
      await tester.tap(find.byType(PanelOtpInput));
      await tester.pump();
      double opacity() => tester.widget<FadeTransition>(caret()).opacity.value;
      expect(opacity(), 1);
      await tester.pump(const Duration(milliseconds: 540));
      expect(opacity(), 1);
      await tester.pump(const Duration(milliseconds: 300));
      expect(opacity(), closeTo(0.5, 0.05));
      await tester.pump(const Duration(milliseconds: 270));
      expect(opacity(), lessThan(0.05));
      await tester.pump(const Duration(milliseconds: 20));
      expect(opacity(), 1);
    });

    testWidgets('with reduced motion the caret holds and digits land', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(reduceMotion: true, const PanelOtpInput(length: 4)),
      );
      await tester.tap(find.byType(PanelOtpInput));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.widget<FadeTransition>(caret()).opacity.value, 1);
      await tester.enterText(find.byType(TextField), '5');
      await tester.pump();
      expect(
        find.ancestor(of: cellText('5'), matching: find.byType(Transform)),
        findsNothing,
      );
    });

    testWidgets('the cell awaiting input takes a 2pt ring over 150ms', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const PanelOtpInput(length: 4)));
      double width() => tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(PanelOtpInput),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as BoxDecoration).border)
          .whereType<Border>()
          .first
          .top
          .width;
      expect(width(), 1);
      await tester.tap(find.byType(PanelOtpInput));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(width(), 2);
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
    Widget host({
      double initial = 1,
      double min = 0,
      double max = 3,
      double step = 1,
      String Function(double value)? formatValue,
      ValueChanged<double>? onChanged,
    }) {
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
              step: step,
              formatValue: formatValue,
              onChanged: (v) {
                onChanged?.call(v);
                setState(() => value = v);
              },
            ),
          ),
        ),
      );
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    String shown(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

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
      await type(tester, '42');
      expect(shown(tester), '10');
      await type(tester, 'abc');
      expect(shown(tester), '10');
    });

    testWidgets('a press while typing steps from what was typed', (
      tester,
    ) async {
      await tester.pumpWidget(host(max: 10));
      await tester.enterText(find.byType(TextField), '7');
      await tester.tap(find.bySemanticsLabel('Increase Quantity'));
      await tester.pump();
      expect(shown(tester), '8');
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pumpAndSettle();
      expect(shown(tester), '8');
    });

    testWidgets('reads a leading number, as parseFloat does', (tester) async {
      await tester.pumpWidget(host(max: 10));
      await type(tester, '7 seats');
      expect(shown(tester), '7');
      // Not numbers: the last good value stays.
      await type(tester, 'NaN');
      expect(shown(tester), '7');
      await type(tester, '-');
      expect(shown(tester), '7');
      // Too large for a double, and clamped rather than thrown.
      await type(tester, '1e999');
      expect(shown(tester), '10');
    });

    testWidgets('shows numbers as PanelUI prints them', (tester) async {
      await tester.pumpWidget(host(step: 0.25));
      expect(shown(tester), '1');
      await tester.tap(find.bySemanticsLabel('Increase Quantity'));
      await tester.pumpAndSettle();
      expect(shown(tester), '1.25');
      await tester.pumpWidget(host(initial: 0.2, step: 0.1, max: 1));
      await tester.tap(find.bySemanticsLabel('Increase Quantity'));
      await tester.pumpAndSettle();
      // Not 0.30000000000000004.
      expect(shown(tester), '0.3');
    });

    testWidgets('snaps from the minimum and rounds halves up', (tester) async {
      await tester.pumpWidget(host(min: double.negativeInfinity, max: 10));
      await type(tester, '-2.5');
      expect(shown(tester), '-2');
    });

    testWidgets('keeps a minimum that is between whole steps', (tester) async {
      final changes = <double>[];
      await tester.pumpWidget(
        host(initial: 1.5, min: 0.5, max: 10, onChanged: changes.add),
      );
      expect(shown(tester), '1.5');
      await type(tester, '3');
      expect(shown(tester), '3.5');
      await tester.tap(find.bySemanticsLabel('Increase Quantity'));
      await tester.pumpAndSettle();
      expect(changes, [3.5, 4.5]);
      expect(shown(tester), '4.5');
    });

    testWidgets('a step finer than a double resolves is kept', (tester) async {
      await tester.pumpWidget(host(initial: 4e-20, step: 1e-20, max: 1));
      expect(shown(tester), '4e-20');
      await tester.tap(find.bySemanticsLabel('Increase Quantity'));
      await tester.pumpAndSettle();
      expect(shown(tester), '5e-20');
    });

    testWidgets('a value past a bound is shown at it', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 240,
            child: PanelNumberInput(value: 12, max: 5, onChanged: (_) {}),
          ),
        ),
      );
      expect(shown(tester), '5');
      expect(
        tester.getSemantics(find.bySemanticsLabel('Increase value')),
        isSemantics(isButton: true, isEnabled: false),
      );
    });

    testWidgets('a formatted value survives a visit to the field', (
      tester,
    ) async {
      final changes = <double>[];
      await tester.pumpWidget(
        host(
          initial: 1000,
          max: 5000,
          formatValue: (v) => v == 1000 ? '1,000' : '$v',
          onChanged: changes.add,
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      // Focus selects the whole number, ready to be typed over.
      final controller = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(shown(tester), '1,000');
    });

    testWidgets('the buttons fill the height and the field takes the rest', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      final button = tester.getRect(find.bySemanticsLabel('Decrease Quantity'));
      // md: w-12 and the full height inside the border.
      expect(button.size, const Size(48, 46));
      final control = button.left - 1;
      // A press near the top of the middle still reaches the field.
      await tester.tapAt(Offset(control + 120, button.top + 2));
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.context?.widget, isNotNull);
      expect(focusIsWithin(tester, find.byType(TextField)), isTrue);
    });

    testWidgets('a disabled input dims, and its label with it', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 240,
            child: PanelNumberInput(label: 'Seats', value: 2, onChanged: null),
          ),
        ),
      );
      expect(
        tester.widget<PanelLabel>(find.byType(PanelLabel)).isDisabled,
        isTrue,
      );
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.64);
    });

    testWidgets('names the field by its label, with its states', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 240,
            child: PanelNumberInput(
              label: 'Guests',
              isRequired: true,
              errorMessage: 'Up to eight.',
              value: 9,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(
          label: 'Guests',
          value: '9',
          isTextField: true,
          isRequired: true,
          validationResult: SemanticsValidationResult.invalid,
        ),
      );
    });
  });
}
