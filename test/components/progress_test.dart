import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

Widget _bar(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    wrap(
      Directionality(
        textDirection: direction,
        child: SizedBox(width: 300, child: child),
      ),
    );

SemanticsData _barSemantics(WidgetTester tester) => tester
    .getSemantics(
      find
          .descendant(
            of: find.byType(PanelProgress),
            matching: find.byType(CustomPaint),
          )
          .first,
    )
    .getSemanticsData();

void main() {
  testWidgets('draws a caption row with the label and the percentage', (
    tester,
  ) async {
    await tester.pumpWidget(
      _bar(
        const PanelProgress(
          value: 64,
          label: 'Downloading',
          showValueLabel: true,
        ),
      ),
    );
    expect(find.text('Downloading'), findsOneWidget);
    expect(find.text('64%'), findsOneWidget);
    // The track alone is the bar's height; the caption sits 8pt above it.
    expect(tester.getSize(find.byType(PanelProgress)).height, 20 + 8 + 8);
  });

  testWidgets('without a label or value the track stands alone', (
    tester,
  ) async {
    await tester.pumpWidget(_bar(const PanelProgress(value: 30)));
    expect(find.byType(Text), findsNothing);
    expect(tester.getSize(find.byType(PanelProgress)), const Size(300, 8));
  });

  testWidgets('sizes set the track height', (tester) async {
    const heights = {
      PanelProgressSize.sm: 6.0,
      PanelProgressSize.md: 8.0,
      PanelProgressSize.lg: 12.0,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      await tester.pumpWidget(_bar(PanelProgress(value: 50, size: size)));
      expect(tester.getSize(find.byType(PanelProgress)).height, height);
    }
  });

  testWidgets('reads the value against its own range', (tester) async {
    await tester.pumpWidget(
      _bar(
        const PanelProgress(
          value: 1250,
          max: 2000,
          label: 'Budget',
          showValueLabel: true,
        ),
      ),
    );
    // 62.5% rounds to 63.
    expect(find.text('63%'), findsOneWidget);

    await tester.pumpWidget(
      _bar(
        const PanelProgress(value: 72, min: 40, max: 80, showValueLabel: true),
      ),
    );
    expect(find.text('80%'), findsOneWidget);
  });

  testWidgets('a value outside the range is held at its end', (tester) async {
    await tester.pumpWidget(
      _bar(const PanelProgress(value: 140, showValueLabel: true)),
    );
    expect(find.text('100%'), findsOneWidget);
    await tester.pumpWidget(
      _bar(const PanelProgress(value: -20, showValueLabel: true)),
    );
    expect(find.text('0%'), findsOneWidget);
    // An empty range reads as empty rather than dividing by zero.
    await tester.pumpWidget(
      _bar(
        const PanelProgress(value: 5, min: 10, max: 10, showValueLabel: true),
      ),
    );
    expect(find.text('0%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('valueLabel and formatValue write the readout', (tester) async {
    await tester.pumpWidget(
      _bar(
        const PanelProgress(
          value: 18,
          max: 24,
          valueLabel: '18 of 24',
          showValueLabel: true,
        ),
      ),
    );
    expect(find.text('18 of 24'), findsOneWidget);

    await tester.pumpWidget(
      _bar(
        PanelProgress(
          value: 1250,
          max: 2000,
          formatValue: (v) => '\$${v.round()}',
          showValueLabel: true,
        ),
      ),
    );
    expect(find.text('\$1250'), findsOneWidget);
  });

  testWidgets('is announced as a progress bar with its range', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _bar(
        const PanelProgress(
          value: 64,
          label: 'Downloading',
          showValueLabel: true,
        ),
      ),
    );
    final data = _barSemantics(tester);
    expect(data.label, 'Downloading');
    expect(data.value, '64%');
    expect(data.role, SemanticsRole.progressBar);
    expect(data.minValue, '0');
    expect(data.maxValue, '100');
    // The caption is not read a second time.
    expect(find.bySemanticsLabel('Downloading'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a readout in words is announced as it is written', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _bar(
        const PanelProgress(
          value: 40,
          label: 'Storage',
          valueLabel: '8.2 GB of 20 GB',
        ),
      ),
    );
    final data = _barSemantics(tester);
    expect(data.value, '8.2 GB of 20 GB');
    expect(data.role, isNot(SemanticsRole.progressBar));
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('the fill springs to a new value and settles', (tester) async {
    await tester.pumpWidget(_bar(const PanelProgress(value: 20)));
    await tester.pumpWidget(_bar(const PanelProgress(value: 80)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reduced motion lands the fill on its value', (tester) async {
    Widget bar(double value) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _bar(PanelProgress(value: value)),
    );
    await tester.pumpWidget(bar(20));
    await tester.pumpWidget(bar(80));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('indeterminate loops, hides the value and reports busy', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _bar(
        const PanelProgress(
          indeterminate: true,
          label: 'Syncing',
          showValueLabel: true,
          color: PanelProgressColor.info,
        ),
      ),
    );
    expect(find.text('Syncing'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.hasRunningAnimations, isTrue);
    final data = _barSemantics(tester);
    expect(data.role, SemanticsRole.loadingSpinner);
    expect(data.value, isEmpty);

    // Turning determinate stops the loop and lets the fill settle.
    await tester.pumpWidget(_bar(const PanelProgress(value: 50)));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    handle.dispose();
  });

  testWidgets('reduced motion pulses the indeterminate bar in place', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _bar(const PanelProgress(indeterminate: true)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));
    // It still moves, because a bar that froze would read as hung.
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the looping bar repaints inside a boundary of its own', (
    tester,
  ) async {
    await tester.pumpWidget(_bar(const PanelProgress(indeterminate: true)));
    expect(
      find.descendant(
        of: find.byType(PanelProgress),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a long label gives way to the value', (tester) async {
    await tester.pumpWidget(
      _bar(
        const PanelProgress(
          value: 64,
          label: 'Uploading the quarterly report and every attachment with it',
          showValueLabel: true,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final value = tester.getRect(find.text('64%'));
    expect(value.right, tester.getRect(find.byType(PanelProgress)).right);
  });

  testWidgets('builds in every theme, colour and direction', (tester) async {
    for (final theme in allThemes) {
      for (final color in PanelProgressColor.values) {
        for (final direction in TextDirection.values) {
          await tester.pumpWidget(
            wrap(
              Directionality(
                textDirection: direction,
                child: SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      PanelProgress(
                        value: 60,
                        color: color,
                        label: 'Uploading',
                        showValueLabel: true,
                      ),
                      PanelProgress(indeterminate: true, color: color),
                    ],
                  ),
                ),
              ),
              theme: theme,
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
  });
}
