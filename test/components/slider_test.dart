import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

/// A 300pt slider holding its own value, recording every report.
class _Volume extends StatefulWidget {
  const _Volume({
    this.initial = 20,
    this.max = 100,
    this.step = 1,
    this.enabled = true,
    this.focusNode,
    this.changes,
    this.ends,
  });

  final double initial;
  final double max;
  final double step;
  final bool enabled;
  final FocusNode? focusNode;
  final List<double>? changes;
  final List<double>? ends;

  @override
  State<_Volume> createState() => _VolumeState();
}

class _VolumeState extends State<_Volume> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: PanelSlider(
        value: _value,
        max: widget.max,
        step: widget.step,
        semanticLabel: 'Volume',
        focusNode: widget.focusNode,
        onChanged: widget.enabled
            ? (value) {
                widget.changes?.add(value);
                setState(() => _value = value);
              }
            : null,
        onChangeEnd: widget.ends?.add,
      ),
    );
  }
}

/// A 300pt range slider holding its own span.
class _Price extends StatefulWidget {
  const _Price({this.minSteps = 0, this.changes, this.ends});

  final int minSteps;
  final List<RangeValues>? changes;
  final List<RangeValues>? ends;

  @override
  State<_Price> createState() => _PriceState();
}

class _PriceState extends State<_Price> {
  RangeValues _values = const RangeValues(20, 80);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: PanelRangeSlider(
        values: _values,
        label: 'Price',
        minStepsBetweenThumbs: widget.minSteps,
        onChanged: (values) {
          widget.changes?.add(values);
          setState(() => _values = values);
        },
        onChangeEnd: widget.ends?.add,
      ),
    );
  }
}

/// How far the first thumb's knob is scaled: 1 at rest, 0.86 held.
double _knobScale(WidgetTester tester) => tester
    .widget<ScaleTransition>(
      find
          .descendant(
            of: find.byType(PanelSlider),
            matching: find.byType(ScaleTransition),
          )
          .first,
    )
    .scale
    .value;

/// Where on a 300pt md track (28pt thumb, 272pt of travel) the thumb's centre
/// sits for [fraction].
Offset _at(WidgetTester tester, Finder slider, double fraction) {
  final rect = tester.getRect(slider);
  return Offset(rect.left + 14 + fraction * 272, rect.bottom - 10);
}

void main() {
  testWidgets('a press on the track moves the thumb there', (tester) async {
    final changes = <double>[];
    final ends = <double>[];
    await tester.pumpWidget(wrap(_Volume(changes: changes, ends: ends)));
    expect(tester.getSize(find.byType(PanelSlider)), const Size(300, 20));

    await tester.tapAt(_at(tester, find.byType(PanelSlider), 0.5));
    await tester.pumpAndSettle();
    expect(changes, [50]);
    expect(ends, [50]);
  });

  testWidgets('a drag follows the finger and commits once', (tester) async {
    final changes = <double>[];
    final ends = <double>[];
    await tester.pumpWidget(wrap(_Volume(changes: changes, ends: ends)));

    await tester.dragFrom(
      _at(tester, find.byType(PanelSlider), 0.2),
      const Offset(68, 0),
    );
    await tester.pumpAndSettle();
    expect(changes, isNotEmpty);
    expect(changes.last, 45);
    // Every report is on a step, and none is repeated back to back.
    for (var i = 0; i < changes.length; i++) {
      expect(changes[i], changes[i].roundToDouble());
      if (i > 0) expect(changes[i], isNot(changes[i - 1]));
    }
    expect(ends, [45]);

    // On release the thumb springs onto the step.
    final thumb = tester.getRect(find.bySemanticsLabel('Volume'));
    expect(
      thumb.center.dx,
      closeTo(_at(tester, find.byType(PanelSlider), 0.45).dx, 0.5),
    );
  });

  testWidgets('the knob shrinks while the thumb is held', (tester) async {
    await tester.pumpWidget(wrap(const _Volume()));
    final gesture = await tester.startGesture(
      _at(tester, find.byType(PanelSlider), 0.2),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(_knobScale(tester), closeTo(0.86, 0.001));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_knobScale(tester), closeTo(1, 0.001));
  });

  testWidgets('disabled mid-drag, it lets go and returns to its value', (
    tester,
  ) async {
    final changes = <double>[];
    Widget slider({required bool enabled}) => wrap(
      SizedBox(
        width: 300,
        child: PanelSlider(
          value: 20,
          semanticLabel: 'Volume',
          onChanged: enabled ? changes.add : null,
        ),
      ),
    );
    await tester.pumpWidget(slider(enabled: true));
    final gesture = await tester.startGesture(
      _at(tester, find.byType(PanelSlider), 0.2),
    );
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(changes, isNotEmpty);
    final reported = changes.length;

    await tester.pumpWidget(slider(enabled: false));
    await gesture.moveBy(const Offset(40, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes.length, reported);
    final thumb = tester.getRect(find.bySemanticsLabel('Volume'));
    expect(
      thumb.center.dx,
      closeTo(_at(tester, find.byType(PanelSlider), 0.2).dx, 0.5),
    );
    expect(_knobScale(tester), closeTo(1, 0.001));
  });

  testWidgets('values snap to the step', (tester) async {
    final changes = <double>[];
    await tester.pumpWidget(
      wrap(_Volume(initial: 2, max: 5, changes: changes)),
    );
    // 62% of 0–5 is 3.1, which lands on 3.
    await tester.tapAt(_at(tester, find.byType(PanelSlider), 0.62));
    await tester.pumpAndSettle();
    expect(changes, [3]);
  });

  testWidgets('fractional steps are reported without float noise', (
    tester,
  ) async {
    final changes = <double>[];
    await tester.pumpWidget(
      wrap(_Volume(initial: 0, max: 1, step: 0.1, changes: changes)),
    );
    await tester.tapAt(_at(tester, find.byType(PanelSlider), 0.3));
    await tester.pumpAndSettle();
    expect(changes, [0.3]);
  });

  testWidgets('a disabled slider ignores presses and drags', (tester) async {
    final changes = <double>[];
    await tester.pumpWidget(wrap(_Volume(enabled: false, changes: changes)));
    await tester.tapAt(_at(tester, find.byType(PanelSlider), 0.8));
    await tester.dragFrom(
      _at(tester, find.byType(PanelSlider), 0.2),
      const Offset(100, 0),
    );
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(PanelSlider),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, 0.5);
  });

  testWidgets('arrow, page, Home and End keys move it', (tester) async {
    final changes = <double>[];
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      wrap(_Volume(initial: 40, focusNode: node, changes: changes)),
    );
    node.requestFocus();
    await tester.pump();

    for (final key in [
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.pageUp,
      LogicalKeyboardKey.pageDown,
      LogicalKeyboardKey.end,
      LogicalKeyboardKey.home,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }
    expect(changes, [41, 42, 41, 40, 50, 40, 100, 0]);
  });

  testWidgets('in a right-to-left layout the arrows and the track turn', (
    tester,
  ) async {
    final changes = <double>[];
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      wrap(
        Directionality(
          textDirection: TextDirection.rtl,
          child: _Volume(initial: 40, focusNode: node, changes: changes),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(changes, [41]);

    // The far left of the track is the top of the range.
    final rect = tester.getRect(find.byType(PanelSlider));
    await tester.tapAt(Offset(rect.left + 14, rect.center.dy));
    await tester.pumpAndSettle();
    expect(changes, [41, 100]);
  });

  testWidgets('is announced as an adjustable slider', (tester) async {
    final handle = tester.ensureSemantics();
    final changes = <double>[];
    await tester.pumpWidget(wrap(_Volume(initial: 40, changes: changes)));
    final thumb = find.bySemanticsLabel('Volume');
    expect(
      tester.getSemantics(thumb),
      isSemantics(
        label: 'Volume',
        value: '40',
        increasedValue: '41',
        decreasedValue: '39',
        isSlider: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    tester.semantics.increase(find.semantics.byLabel('Volume'));
    await tester.pumpAndSettle();
    expect(changes, [41]);
    tester.semantics.decrease(find.semantics.byLabel('Volume'));
    await tester.pumpAndSettle();
    expect(changes, [41, 40]);
    handle.dispose();
  });

  testWidgets('at an end it offers only the way back', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const _Volume(initial: 100)));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Volume')),
      isSemantics(
        label: 'Volume',
        value: '100',
        decreasedValue: '99',
        isSlider: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasDecreaseAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a controlled value that changes elsewhere moves the thumb', (
    tester,
  ) async {
    Widget slider(double value) => wrap(
      SizedBox(
        width: 300,
        child: PanelSlider(
          value: value,
          semanticLabel: 'Volume',
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpWidget(slider(0));
    await tester.pumpWidget(slider(100));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(PanelSlider));
    expect(
      tester.getRect(find.bySemanticsLabel('Volume')).right,
      closeTo(rect.right, 0.5),
    );
  });

  testWidgets('label and showValue draw the caption row', (tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 300,
          child: PanelSlider(
            label: 'Budget',
            showValue: true,
            value: 340,
            max: 1000,
            step: 20,
            formatValue: (v) => '\$${v.round()}',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('\$340'), findsOneWidget);
    // A 20pt caption, 8pt of gap, and the 20pt track.
    expect(tester.getSize(find.byType(PanelSlider)).height, 48);
  });

  testWidgets('sizes set the track height', (tester) async {
    const heights = {
      PanelSliderSize.sm: 16.0,
      PanelSliderSize.md: 20.0,
      PanelSliderSize.lg: 24.0,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 300,
            child: PanelSlider(value: 40, size: size, onChanged: (_) {}),
          ),
        ),
      );
      expect(tester.getSize(find.byType(PanelSlider)).height, height);
    }
  });

  testWidgets('range: a press moves the nearer thumb', (tester) async {
    final changes = <RangeValues>[];
    final ends = <RangeValues>[];
    await tester.pumpWidget(wrap(_Price(changes: changes, ends: ends)));
    final slider = find.byType(PanelRangeSlider);
    await tester.tapAt(_at(tester, slider, 0.1));
    await tester.pumpAndSettle();
    await tester.tapAt(_at(tester, slider, 0.9));
    await tester.pumpAndSettle();
    expect(changes, const [RangeValues(10, 80), RangeValues(10, 90)]);
    expect(ends, changes);
    expect(find.text('10 – 90'), findsNothing); // showValue is off
  });

  testWidgets('range: the thumbs meet but never cross', (tester) async {
    final changes = <RangeValues>[];
    await tester.pumpWidget(wrap(_Price(changes: changes)));
    final slider = find.byType(PanelRangeSlider);
    // Drag the upper thumb far below the lower one.
    await tester.dragFrom(_at(tester, slider, 0.8), const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(changes.last, const RangeValues(20, 20));
  });

  testWidgets('range: minStepsBetweenThumbs keeps a gap', (tester) async {
    final changes = <RangeValues>[];
    await tester.pumpWidget(wrap(_Price(minSteps: 5, changes: changes)));
    final slider = find.byType(PanelRangeSlider);
    await tester.dragFrom(_at(tester, slider, 0.2), const Offset(250, 0));
    await tester.pumpAndSettle();
    expect(changes.last, const RangeValues(75, 80));
  });

  testWidgets('range: each thumb is its own adjustable', (tester) async {
    final handle = tester.ensureSemantics();
    final changes = <RangeValues>[];
    await tester.pumpWidget(wrap(_Price(changes: changes)));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Price, minimum')),
      isSemantics(
        label: 'Price, minimum',
        value: '20',
        increasedValue: '21',
        decreasedValue: '19',
        isSlider: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    final upper = find.bySemanticsLabel('Price, maximum');
    expect(tester.getSemantics(upper).getSemanticsData().value, '80');
    tester.semantics.increase(find.semantics.byLabel('Price, maximum'));
    await tester.pumpAndSettle();
    expect(changes, const [RangeValues(20, 81)]);
    handle.dispose();
  });

  testWidgets('range: a span given backwards is read the right way round', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 300,
          child: PanelRangeSlider(
            values: const RangeValues(80, 20),
            showValue: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('20 – 80'), findsOneWidget);
  });

  testWidgets('a press in the slop above the track moves nothing', (
    tester,
  ) async {
    final changes = <double>[];
    var value = 20.0;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 300,
            // A caption above, so the slop has room inside the slider.
            child: PanelSlider(
              label: 'Volume',
              value: value,
              onChanged: (next) => setState(() {
                changes.add(next);
                value = next;
              }),
            ),
          ),
        ),
      ),
    );
    final slider = find.byType(PanelSlider);
    final above = _at(tester, slider, 0.8) - const Offset(0, 20);
    await tester.tapAt(above);
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    // A drag that starts there still takes the thumb.
    await tester.dragFrom(
      Offset(_at(tester, slider, 0.2).dx, above.dy),
      const Offset(68, 0),
    );
    await tester.pumpAndSettle();
    expect(changes.last, 45);
  });

  testWidgets('keyboard focus rings the thumb 2pt off it', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(wrap(_Volume(focusNode: node)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(node.hasFocus, isTrue);
    final ring = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          ((widget.decoration as BoxDecoration).border as Border?)?.top.color ==
              PanelColors.panelLight.ring,
    );
    expect(ring, findsOneWidget);
    final side =
        ((tester.widget<DecoratedBox>(ring).decoration as BoxDecoration).border!
                as Border)
            .top;
    expect(side.width, 2);
    expect(side.strokeAlign, 3);
    expect(tester.getSize(ring), const Size(28, 20));
  });

  testWidgets('a moving thumb repaints inside a boundary of its own', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const _Volume()));
    expect(
      find.descendant(
        of: find.byType(PanelSlider),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
  });

  testWidgets('every colour and size builds in every theme', (tester) async {
    for (final theme in allThemes) {
      for (final color in PanelSliderColor.values) {
        await tester.pumpWidget(
          wrap(
            SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final size in PanelSliderSize.values)
                    PanelSlider(
                      value: 40,
                      color: color,
                      size: size,
                      label: 'Brightness',
                      showValue: true,
                      onChanged: (_) {},
                    ),
                  PanelRangeSlider(
                    values: const RangeValues(30, 60),
                    color: color,
                    label: 'Range',
                    showValue: true,
                    onChanged: (_) {},
                  ),
                  const PanelSlider(value: 30, onChanged: null),
                ],
              ),
            ),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
}
