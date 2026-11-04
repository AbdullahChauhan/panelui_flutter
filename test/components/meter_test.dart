import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

void main() {
  group('PanelMeter', () {
    testWidgets('the highest threshold reached sets the colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 300,
            child: PanelMeter(
              label: 'Storage',
              value: 245,
              max: 256,
              thresholds: [
                PanelMeterThreshold(
                  from: 240,
                  color: PanelMeterColor.destructive,
                ),
                PanelMeterThreshold(from: 192, color: PanelMeterColor.warning),
              ],
            ),
          ),
        ),
      );
      final fills = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(FractionallySizedBox),
              matching: find.byType(Container),
            ),
          )
          .map((c) => (c.decoration! as BoxDecoration).color);
      expect(fills, contains(PanelColors.panelLight.destructive));
      expect(find.text('96%'), findsOneWidget);
    });

    testWidgets('segments light at least one block above the floor', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 300,
            child: PanelMeter(value: 1, segments: 4),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final opacities = tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .map((o) => o.opacity)
          .toList();
      expect(opacities, [1, 0.22, 0.22, 0.22]);
    });

    testWidgets('announces its label and reading', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 300,
            child: PanelMeter(label: 'Battery', value: 40, valueLabel: '40%'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PanelMeter)),
        isSemantics(label: 'Battery', value: '40%'),
      );
    });
  });

  testWidgets('scroll fades appear only where there is more to scroll', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          height: 200,
          width: 200,
          child: PanelScrollFade(
            child: ListView(
              children: [for (var i = 0; i < 30; i++) Text('Row $i')],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    double opacityAt(int index) => tester
        .widgetList<Opacity>(
          find.descendant(
            of: find.byType(PanelScrollFade),
            matching: find.byType(Opacity),
          ),
        )
        .elementAt(index)
        .opacity;
    expect(opacityAt(0), 0);
    expect(opacityAt(1), 1);
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(opacityAt(0), 1);
  });
}
