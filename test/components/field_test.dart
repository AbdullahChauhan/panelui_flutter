import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

void main() {
  group('PanelField', () {
    testWidgets('a horizontal field reads as one node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          PanelField(
            orientation: Axis.horizontal,
            title: 'Marketing emails',
            description: 'At most weekly.',
            child: PanelSwitch(value: true, onChanged: (_) {}),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PanelSwitch)),
        isSemantics(
          label: 'Marketing emails\nAt most weekly.',
          isToggled: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('dedupes errors and lists more than one', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PanelField(
            label: 'Email',
            errors: ['Required.', 'Required.', 'Use a verified domain.'],
            child: PanelInput(),
          ),
        ),
      );
      expect(find.text('Required.'), findsOneWidget);
      expect(find.text('Use a verified domain.'), findsOneWidget);
      expect(find.text('•'), findsNWidgets(2));
    });

    testWidgets('a single error is a plain line, announced', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PanelField(
            label: 'Email',
            errors: ['Required.'],
            child: PanelInput(),
          ),
        ),
      );
      expect(find.text('•'), findsNothing);
      expect(
        tester.getSemantics(find.text('Required.')),
        isSemantics(label: 'Required.', isLiveRegion: true),
      );
    });

    testWidgets('empty validator results are not errors', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PanelField(
            label: 'Email',
            errors: [null, ''],
            child: PanelInput(),
          ),
        ),
      );
      expect(find.byType(PanelFieldError), findsNothing);
      final label = tester.widget<PanelLabel>(find.byType(PanelLabel));
      expect(label.isInvalid, isFalse);
    });

    testWidgets('a vertical field stacks its label, title and control', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const PanelField(
            label: 'Name',
            title: 'Your details',
            description: 'As it appears on your card.',
            child: PanelInput(),
          ),
        ),
      );
      final label = tester.getRect(find.text('Name'));
      final title = tester.getRect(find.text('Your details'));
      final input = tester.getRect(find.byType(PanelInput));
      final description = tester.getRect(
        find.text('As it appears on your card.'),
      );
      expect(title.top - label.bottom, 8);
      expect(input.top - title.bottom, 8);
      expect(description.top - input.bottom, 8);
    });

    testWidgets('a disabled field dims, and its label with it', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PanelField(
            label: 'Plan',
            isDisabled: true,
            child: PanelInput(enabled: false),
          ),
        ),
      );
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.64);
      expect(
        tester.widget<PanelLabel>(find.byType(PanelLabel).first).isDisabled,
        isTrue,
      );
    });
  });

  group('PanelFieldSet', () {
    testWidgets('announces its legend as a heading', (tester) async {
      await tester.pumpWidget(
        wrap(
          PanelFieldSet(
            legend: 'Notifications',
            children: [
              PanelCheckbox(value: true, label: 'Email', onChanged: (_) {}),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Notifications')),
        isSemantics(label: 'Notifications', isHeader: true),
      );
    });
  });

  testWidgets('typography roles build in every theme', (tester) async {
    for (final theme in allThemes) {
      await tester.pumpWidget(
        wrap(
          theme: theme,
          const SingleChildScrollView(
            child: Column(
              children: [
                PanelText.h1('h1'),
                PanelText.h2('h2'),
                PanelText.h3('h3'),
                PanelText.h4('h4'),
                PanelText.h5('h5'),
                PanelText.h6('h6'),
                PanelText.lead('lead'),
                PanelText.large('large'),
                PanelText.small('small'),
                PanelBlockquote(child: Text('quote')),
                PanelCode('code'),
                PanelList(ordered: true, items: [Text('one'), Text('two')]),
                PanelList(items: [Text('dot')]),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
    expect(find.text('2.'), findsOneWidget);
  });

  testWidgets('headings are announced as headings', (tester) async {
    await tester.pumpWidget(wrap(const PanelText.h2('Billing')));
    expect(
      tester.getSemantics(find.text('Billing')),
      isSemantics(label: 'Billing', isHeader: true),
    );
  });
}
