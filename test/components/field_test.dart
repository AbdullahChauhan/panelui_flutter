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

    testWidgets('a single error is a plain line', (tester) async {
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
