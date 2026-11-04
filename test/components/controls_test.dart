import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

void main() {
  group('PanelSwitch', () {
    testWidgets('reports the flipped value', (tester) async {
      bool? received;
      await tester.pumpWidget(
        wrap(PanelSwitch(value: false, onChanged: (v) => received = v)),
      );
      await tester.tap(find.byType(PanelSwitch));
      expect(received, isTrue);
    });

    testWidgets('springs the thumb across', (tester) async {
      var value = false;
      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) => PanelSwitch(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      double thumbLeft() => tester
          .widget<Positioned>(
            find
                .descendant(
                  of: find.byType(PanelSwitch),
                  matching: find.byType(Positioned),
                )
                .last,
          )
          .left!;
      expect(thumbLeft(), 4);
      await tester.tap(find.byType(PanelSwitch));
      await tester.pumpAndSettle();
      // md: 4 + (48 - 20 - 8) of travel.
      expect(thumbLeft(), closeTo(24, 0.01));
    });

    testWidgets('announces as a toggle, and disables without onChanged', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const PanelSwitch(
            value: true,
            onChanged: null,
            semanticLabel: 'Wi-Fi',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PanelSwitch)),
        isSemantics(label: 'Wi-Fi', isToggled: true, isEnabled: false),
      );
    });
  });

  group('PanelCheckbox', () {
    testWidgets('toggles from the box and from the label', (tester) async {
      final values = <bool>[];
      await tester.pumpWidget(
        wrap(
          PanelCheckbox(value: false, label: 'Accept', onChanged: values.add),
        ),
      );
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(values, [true]);
    });

    testWidgets('an indeterminate box resolves to true', (tester) async {
      bool? received;
      await tester.pumpWidget(
        wrap(
          PanelCheckbox(
            value: false,
            indeterminate: true,
            label: 'All',
            onChanged: (v) => received = v,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PanelCheckbox)),
        isSemantics(isCheckStateMixed: true),
      );
      await tester.tap(find.text('All'));
      expect(received, isTrue);
    });

    testWidgets('shows the tick only when checked', (tester) async {
      await tester.pumpWidget(
        wrap(PanelCheckbox(value: false, onChanged: (_) {})),
      );
      expect(find.byType(PanelIcon), findsNothing);
      await tester.pumpWidget(
        wrap(PanelCheckbox(value: true, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PanelIcon), findsOneWidget);
    });

    testWidgets('builds both variants in every theme', (tester) async {
      for (final theme in allThemes) {
        await tester.pumpWidget(
          wrap(
            theme: theme,
            Column(
              children: [
                for (final size in PanelCheckboxSize.values)
                  PanelCheckbox(
                    value: true,
                    size: size,
                    label: 'Label',
                    description: 'Description',
                    onChanged: (_) {},
                  ),
                PanelCheckbox(
                  variant: PanelCheckboxVariant.card,
                  value: true,
                  label: 'Pro',
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('PanelInput', () {
    testWidgets('reports edits and shows its label', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        wrap(
          PanelInput(
            label: 'Email',
            placeholder: 'you@example.com',
            onChanged: values.add,
          ),
        ),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('you@example.com'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'a@b.co');
      expect(values.last, 'a@b.co');
    });

    testWidgets('an error replaces the description', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PanelInput(
            label: 'Username',
            description: 'Pick something memorable.',
            errorMessage: 'That username is taken.',
          ),
        ),
      );
      expect(find.text('That username is taken.'), findsOneWidget);
      expect(find.text('Pick something memorable.'), findsNothing);
    });

    testWidgets('the border crosses to the ring colour on focus', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const PanelInput(label: 'Name')));
      Color border() {
        final container = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(PanelFieldFrame),
                matching: find.byType(Container),
              ),
            )
            .firstWhere((c) => c.decoration is BoxDecoration);
        final decoration = container.decoration! as BoxDecoration;
        return (decoration.border! as Border).top.color;
      }

      expect(border(), PanelColors.panelLight.input);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(border(), PanelColors.panelLight.ring);
    });

    testWidgets('a textarea counts characters against its limit', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const PanelTextarea(showCount: true, maxLength: 10)),
      );
      expect(find.text('0/10'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      expect(find.text('5/10'), findsOneWidget);
    });
  });
}
