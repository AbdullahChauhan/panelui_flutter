import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import 'helpers.dart';

void main() {
  group('PanelPressable', () {
    Finder scaleOf(Key key) =>
        find.descendant(of: find.byKey(key), matching: find.byType(Transform));

    testWidgets('only the innermost of two pressables shows a press', (
      tester,
    ) async {
      const outer = Key('outer');
      const inner = Key('inner');
      var innerTaps = 0;
      var outerTaps = 0;
      await tester.pumpWidget(
        wrap(
          PanelPressable(
            key: outer,
            onPressed: () => outerTaps++,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: PanelPressable(
                key: inner,
                onPressed: () => innerTaps++,
                child: const SizedBox.square(dimension: 40),
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(inner)),
      );
      // Past the press timeout, when both would otherwise report a press.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 100));
      double scale(Key key) =>
          tester.widget<Transform>(scaleOf(key).first).transform.entry(0, 0);
      expect(scale(inner), closeTo(0.97, 0.001));
      // The outer one holds still.
      expect(scale(outer), 1);
      await gesture.up();
      await tester.pumpAndSettle();
      expect((innerTaps, outerTaps), (1, 0));
    });

    testWidgets('a press keeps the content and its state', (tester) async {
      await tester.pumpWidget(
        wrap(PanelPressable(onPressed: () {}, child: const _Counter())),
      );
      final before = tester.state(find.byType(_Counter));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(_Counter)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.state(find.byType(_Counter)), same(before));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(_Counter)), same(before));
    });

    testWidgets('rings only the control that holds focus', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final innerFocus = FocusNode();
      addTearDown(innerFocus.dispose);
      await tester.pumpWidget(
        wrap(
          PanelPressable(
            onPressed: () {},
            focusRingRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: PanelPressable(
                focusNode: innerFocus,
                onPressed: () {},
                focusRingRadius: BorderRadius.circular(4),
                child: const SizedBox.square(dimension: 40),
              ),
            ),
          ),
        ),
      );
      innerFocus.requestFocus();
      await tester.pump();
      final rings = tester
          .widgetList<PanelFocusRing>(find.byType(PanelFocusRing))
          .map((r) => r.visible)
          .toList();
      // Outer first, then inner.
      expect(rings, [false, true]);
    });

    testWidgets('a link is announced as one', (tester) async {
      await tester.pumpWidget(
        wrap(
          PanelPressable(
            onPressed: () {},
            link: true,
            isButton: false,
            semanticLabel: 'Docs',
            child: const Text('Docs'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Docs')),
        isSemantics(label: 'Docs', isLink: true),
      );
    });

    testWidgets('Enter activates a focused control', (tester) async {
      var taps = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        wrap(
          PanelPressable(
            focusNode: focus,
            onPressed: () => taps++,
            child: const SizedBox.square(dimension: 40),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('PanelFocusRing', () {
    Iterable<Border> bordersOf(WidgetTester tester) => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(PanelFocusRing),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => (box.decoration as BoxDecoration).border! as Border);

    Future<void> ring(WidgetTester tester, PanelFocusRingStyle style) =>
        tester.pumpWidget(
          wrap(
            PanelFocusRing(
              visible: true,
              borderRadius: BorderRadius.circular(8),
              style: style,
              child: const SizedBox.square(dimension: 40),
            ),
          ),
        );

    testWidgets('the offset ring sits 2pt clear of the control', (
      tester,
    ) async {
      await ring(tester, PanelFocusRingStyle.offset);
      final borders = bordersOf(tester).toList();
      expect(borders, hasLength(2));
      // The background band fills the gap; the ring runs from 2pt to 4pt.
      expect(borders.first.top.color, PanelColors.panelLight.background);
      expect(borders.last.top.color, PanelColors.panelLight.ring);
      expect(borders.last.top.strokeAlign, 3);
    });

    testWidgets('the soft ring is the ring colour at 40%', (tester) async {
      await ring(tester, PanelFocusRingStyle.soft);
      final side = bordersOf(tester).single.top;
      expect(side.width, 3);
      expect(side.color.a, closeTo(PanelColors.panelLight.ring.a * 0.4, 1e-6));
    });

    testWidgets('the inset ring stays inside a clipped control', (
      tester,
    ) async {
      await ring(tester, PanelFocusRingStyle.inset);
      expect(
        bordersOf(tester).single.top.strokeAlign,
        BorderSide.strokeAlignInside,
      );
    });
  });

  test("PanelCurves.inOutQuad is Reanimated's curve exactly", () {
    expect(PanelCurves.inOutQuad.transform(0.25), 0.125);
    expect(PanelCurves.inOutQuad.transform(0.5), 0.5);
    expect(PanelCurves.inOutQuad.transform(0.75), 0.875);
    expect(panelEase, PanelCurves.inOutQuad);
  });

  test('mixOklab reaches both ends and keeps translucency', () {
    const a = Color(0xFFFF0000);
    const b = Color(0xFF0000FF);
    Matcher near(Color c) => predicate<Color>(
      (x) =>
          (x.r - c.r).abs() < 1e-3 &&
          (x.g - c.g).abs() < 1e-3 &&
          (x.b - c.b).abs() < 1e-3 &&
          (x.a - c.a).abs() < 1e-3,
      'close to $c',
    );
    expect(a.mixOklab(b, 0), near(a));
    expect(a.mixOklab(b, 1), near(b));
    expect(
      const Color(0x00000000).mixOklab(const Color(0x80000000), 0.5).a,
      closeTo(0.25, 1e-3),
    );
  });
}

/// A stateful child, to tell whether its state survives.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  Widget build(BuildContext context) => const SizedBox.square(dimension: 40);
}
