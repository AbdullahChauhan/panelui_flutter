import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

Widget _meter(PanelMeter meter, {bool reduceMotion = false}) =>
    wrap(reduceMotion: reduceMotion, SizedBox(width: 300, child: meter));

SemanticsData _semantics(WidgetTester tester) =>
    tester.getSemantics(find.byType(PanelMeter)).getSemanticsData();

/// The colours of the fill, or of every segment.
Iterable<Color?> _fills(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(PanelMeter),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((box) => (box.decoration as BoxDecoration).color);

void main() {
  group('PanelMeter', () {
    testWidgets('the highest threshold reached sets the colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _meter(
          const PanelMeter(
            label: 'Storage',
            value: 245,
            max: 256,
            showValueLabel: true,
            thresholds: [
              PanelMeterThreshold(
                from: 240,
                color: PanelMeterColor.destructive,
              ),
              PanelMeterThreshold(from: 192, color: PanelMeterColor.warning),
            ],
          ),
        ),
      );
      expect(_fills(tester), contains(PanelColors.panelLight.destructive));
      expect(find.text('96%'), findsOneWidget);
    });

    testWidgets('draws the reading only when asked to', (tester) async {
      await tester.pumpWidget(
        _meter(const PanelMeter(label: 'Battery', value: 40)),
      );
      expect(find.text('Battery'), findsOneWidget);
      expect(find.text('40%'), findsNothing);
      expect(_semantics(tester).value, '40%');
    });

    testWidgets('segments light at least one block above the floor', (
      tester,
    ) async {
      await tester.pumpWidget(_meter(const PanelMeter(value: 1, segments: 4)));
      await tester.pumpAndSettle();
      final opacities = tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .map((o) => o.opacity)
          .toList();
      expect(opacities, [1, 0.22, 0.22, 0.22]);
    });

    testWidgets('segments switch at once under reduced motion', (tester) async {
      await tester.pumpWidget(
        _meter(const PanelMeter(value: 1, segments: 4), reduceMotion: true),
      );
      final durations = tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .map((o) => o.duration);
      expect(durations, everyElement(Duration.zero));
    });

    testWidgets('the fill springs to a new reading, never past it', (
      tester,
    ) async {
      double fraction() => tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
      await tester.pumpWidget(_meter(const PanelMeter(value: 20)));
      expect(fraction(), 0.2);
      await tester.pumpWidget(_meter(const PanelMeter(value: 80)));
      var peak = 0.0;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        peak = fraction() > peak ? fraction() : peak;
      }
      expect(peak, lessThanOrEqualTo(0.8));
      await tester.pumpAndSettle();
      expect(fraction(), 0.8);
    });

    testWidgets('a malformed scale reads as empty instead of throwing', (
      tester,
    ) async {
      for (final meter in const [
        PanelMeter(value: 50, min: 10, max: 5),
        PanelMeter(value: double.nan),
        PanelMeter(value: double.infinity, max: double.infinity),
      ]) {
        await tester.pumpWidget(_meter(meter));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        _meter(const PanelMeter(value: 50, min: 10, max: 5)),
      );
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        0,
      );
    });

    testWidgets('announces as a progress bar with its scale', (tester) async {
      await tester.pumpWidget(
        _meter(
          PanelMeter(
            label: 'Storage',
            value: 168,
            max: 256,
            formatValue: (v) => v.round().toString(),
          ),
        ),
      );
      final data = _semantics(tester);
      expect(data.label, 'Storage');
      expect(data.value, '168');
      expect(data.role, SemanticsRole.progressBar);
      expect(data.minValue, '0');
      expect(data.maxValue, '256');
    });

    testWidgets('a reading in words is spoken as written, with its name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _meter(
          const PanelMeter(
            label: 'Password strength',
            semanticLabel: 'Strength of the new password',
            value: 3,
            max: 4,
            segments: 4,
            valueLabel: 'Strong',
          ),
        ),
      );
      final data = _semantics(tester);
      expect(data.label, 'Strength of the new password');
      expect(data.value, 'Strong');
      expect(data.role, isNot(SemanticsRole.progressBar));
      expect(tester.takeException(), isNull);
    });
  });

  group('PanelScrollFade', () {
    double opacityAt(WidgetTester tester, int index) => tester
        .widgetList<Opacity>(
          find.descendant(
            of: find.byType(PanelScrollFade),
            matching: find.byType(Opacity),
          ),
        )
        .elementAt(index)
        .opacity;

    Widget list({double fadeInDistance = 24}) => wrap(
      SizedBox(
        height: 200,
        width: 200,
        child: PanelScrollFade(
          fadeInDistance: fadeInDistance,
          color: const Color(0x80FF0000),
          child: ListView(
            children: [for (var i = 0; i < 30; i++) Text('Row $i')],
          ),
        ),
      ),
    );

    testWidgets('fades appear only where there is more to scroll', (
      tester,
    ) async {
      await tester.pumpWidget(list());
      await tester.pump();
      expect(opacityAt(tester, 0), 0);
      expect(opacityAt(tester, 1), 1);
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(opacityAt(tester, 0), 1);
    });

    testWidgets('an edge fades in over the distance it is given', (
      tester,
    ) async {
      await tester.pumpWidget(list(fadeInDistance: 100));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -40));
      await tester.pumpAndSettle();
      expect(opacityAt(tester, 0), closeTo(0.4, 0.05));
    });

    testWidgets('the edge is opaque whatever the colour\'s alpha', (
      tester,
    ) async {
      await tester.pumpWidget(list());
      final gradient =
          (tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.byType(PanelScrollFade),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration)
              .gradient!;
      expect(gradient.colors.first, const Color(0xFFFF0000));
      expect(gradient.colors.last, const Color(0x00FF0000));
    });
  });
}
