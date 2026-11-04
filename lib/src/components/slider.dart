import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show RangeValues;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_hit_slop.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_tokens.dart';
import '../theme/panel_typography.dart';

/// The colour of a slider's fill and thumb.
enum PanelSliderColor {
  /// The `primary` token.
  primary,

  /// The `success` token.
  success,

  /// The `warning` token.
  warning,

  /// The `destructive` token.
  destructive,

  /// The `info` token.
  info,
}

/// How big a slider is.
enum PanelSliderSize {
  /// A 16pt track with a 24pt thumb.
  sm,

  /// A 20pt track with a 28pt thumb, the default.
  md,

  /// A 24pt track with a 32pt thumb.
  lg,
}

/// Track height (which is also the thumb's) and thumb width per size. The
/// thumb is wider than it is tall, so the pill reads as a grip.
const _sliderMetrics = {
  PanelSliderSize.sm: (height: 16.0, thumb: 24.0),
  PanelSliderSize.md: (height: 20.0, thumb: 28.0),
  PanelSliderSize.lg: (height: 24.0, thumb: 32.0),
};

/// How far the knob shrinks while its thumb is held.
const _knobPressedScale = 0.86;

/// The grab area around the track: the pill is small, the target should not
/// be.
const _hitSlop = 16.0;

/// Picks a number by dragging a thumb along a track.
///
/// ```dart
/// PanelSlider(
///   label: 'Volume',
///   showValue: true,
///   value: volume,
///   onChanged: (v) => setState(() => volume = v),
/// )
/// ```
///
/// The thumb is a pill exactly as tall as the track rather than a disc
/// floating over it, with a knob inside that shrinks while it is held: the
/// press feedback lives on the part being looked at. A drag follows the finger
/// 1:1 and reports each step it crosses; on release the thumb springs onto
/// the step. A press on the track springs the thumb there.
///
/// With focus, the arrow keys move it a step, Page Up and Page Down a tenth of
/// the range, and Home and End to either end. Screen readers can adjust it a
/// step at a time.
///
/// For a span picked by two thumbs, see [PanelRangeSlider].
class PanelSlider extends StatelessWidget {
  /// Creates a slider.
  const PanelSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.label,
    this.showValue = false,
    this.formatValue,
    this.color = PanelSliderColor.primary,
    this.size = PanelSliderSize.md,
    this.haptics = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// The value, held between [min] and [max].
  final double value;

  /// Called with each new value while the thumb moves, already snapped to
  /// [step]. Keep it cheap. Null disables the slider.
  final ValueChanged<double>? onChanged;

  /// Called once when a drag, a press or a key settles the value: the place
  /// for expensive side effects. PanelUI's `onValueCommit`.
  final ValueChanged<double>? onChangeEnd;

  /// The lower bound.
  final double min;

  /// The upper bound.
  final double max;

  /// Snap granularity: the value is always a whole number of steps from
  /// [min]. Zero or less moves freely.
  final double step;

  /// A caption above the track, at its start. Also the accessible name.
  final String? label;

  /// Shows the value above the track, at its end.
  final bool showValue;

  /// Writes the value, for the caption and for screen readers. Defaults to
  /// the rounded number.
  final String Function(double value)? formatValue;

  /// The colour of the fill and the thumb.
  final PanelSliderColor color;

  /// The size.
  final PanelSliderSize size;

  /// A selection tick of the haptic engine each time the value lands on a
  /// new step.
  final bool haptics;

  /// The accessible name, when [label] is not shown or not enough.
  final String? semanticLabel;

  /// An optional focus node for the thumb.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final onChangeEnd = this.onChangeEnd;
    return _SliderCore(
      range: false,
      low: min,
      high: value,
      onChanged: onChanged == null ? null : (_, high) => onChanged(high),
      onChangeEnd: onChangeEnd == null ? null : (_, high) => onChangeEnd(high),
      min: min,
      max: max,
      step: step,
      minStepsBetweenThumbs: 0,
      label: label,
      showValue: showValue,
      formatValue: formatValue,
      color: color,
      size: size,
      haptics: haptics,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}

/// Picks a span by dragging two thumbs along a track.
///
/// ```dart
/// PanelRangeSlider(
///   label: 'Price',
///   showValue: true,
///   values: price,
///   max: 1000,
///   step: 20,
///   onChanged: (v) => setState(() => price = v),
/// )
/// ```
///
/// The fill runs between the thumbs. A press on the track moves whichever
/// thumb is nearer; when both sit on one spot it takes the one that has
/// somewhere to go. The thumbs can meet but never cross, and
/// [minStepsBetweenThumbs] keeps them that many steps apart. Each thumb takes
/// focus and keys of its own.
///
/// It is the two-thumb form of [PanelSlider], with [RangeValues] in place of a
/// single number, as Flutter's own `RangeSlider` has.
class PanelRangeSlider extends StatelessWidget {
  /// Creates a range slider.
  const PanelRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.minStepsBetweenThumbs = 0,
    this.label,
    this.showValue = false,
    this.formatValue,
    this.color = PanelSliderColor.primary,
    this.size = PanelSliderSize.md,
    this.haptics = false,
    this.semanticLabel,
  });

  /// The span. Given the wrong way round it is read the right way round.
  final RangeValues values;

  /// Called with each new span while a thumb moves, snapped to [step]. Null
  /// disables the slider.
  final ValueChanged<RangeValues>? onChanged;

  /// Called once when a drag, a press or a key settles the span.
  final ValueChanged<RangeValues>? onChangeEnd;

  /// The lower bound.
  final double min;

  /// The upper bound.
  final double max;

  /// Snap granularity. Zero or less moves freely.
  final double step;

  /// How many steps the thumbs must stay apart. 0 lets them meet; 1 keeps a
  /// step between them, so the span is never empty, which is what a filter
  /// wants.
  final int minStepsBetweenThumbs;

  /// A caption above the track, at its start. Also the accessible name.
  final String? label;

  /// Shows the span above the track, at its end.
  final bool showValue;

  /// Writes each end of the span. Defaults to the rounded number.
  final String Function(double value)? formatValue;

  /// The colour of the fill and the thumbs.
  final PanelSliderColor color;

  /// The size.
  final PanelSliderSize size;

  /// A selection tick of the haptic engine each time a thumb lands on a new
  /// step.
  final bool haptics;

  /// The accessible name, when [label] is not shown or not enough.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final onChangeEnd = this.onChangeEnd;
    return _SliderCore(
      range: true,
      low: math.min(values.start, values.end),
      high: math.max(values.start, values.end),
      onChanged: onChanged == null
          ? null
          : (low, high) => onChanged(RangeValues(low, high)),
      onChangeEnd: onChangeEnd == null
          ? null
          : (low, high) => onChangeEnd(RangeValues(low, high)),
      min: min,
      max: max,
      step: step,
      minStepsBetweenThumbs: minStepsBetweenThumbs,
      label: label,
      showValue: showValue,
      formatValue: formatValue,
      color: color,
      size: size,
      haptics: haptics,
      semanticLabel: semanticLabel,
      focusNode: null,
      autofocus: false,
    );
  }
}

/// Which thumb a gesture or a key moves. A one-thumb slider only has [high].
enum _Thumb { low, high }

/// A key's request to move a thumb.
enum _Move { left, right, up, down, pageUp, pageDown, home, end }

class _MoveIntent extends Intent {
  const _MoveIntent(this.move);

  final _Move move;
}

class _SliderCore extends StatefulWidget {
  const _SliderCore({
    required this.range,
    required this.low,
    required this.high,
    required this.onChanged,
    required this.onChangeEnd,
    required this.min,
    required this.max,
    required this.step,
    required this.minStepsBetweenThumbs,
    required this.label,
    required this.showValue,
    required this.formatValue,
    required this.color,
    required this.size,
    required this.haptics,
    required this.semanticLabel,
    required this.focusNode,
    required this.autofocus,
  });

  final bool range;

  /// The lower end of a range; [min] for a one-thumb slider.
  final double low;

  /// The value of a one-thumb slider, or the upper end of a range.
  final double high;
  final void Function(double low, double high)? onChanged;
  final void Function(double low, double high)? onChangeEnd;
  final double min;
  final double max;
  final double step;
  final int minStepsBetweenThumbs;
  final String? label;
  final bool showValue;
  final String Function(double value)? formatValue;
  final PanelSliderColor color;
  final PanelSliderSize size;
  final bool haptics;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<_SliderCore> createState() => _SliderCoreState();
}

class _SliderCoreState extends State<_SliderCore>
    with TickerProviderStateMixin {
  // Positions along the track, 0 to 1. `low` sits at 0 on a one-thumb slider,
  // so the fill reads the same either way: from `low` to `high`.
  late final AnimationController _low = AnimationController.unbounded(
    vsync: this,
    value: widget.range ? _fraction(_lowValue) : 0,
  );
  late final AnimationController _high = AnimationController.unbounded(
    vsync: this,
    value: _fraction(_highValue),
  );
  late final AnimationController _lowKnob = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _highKnob = AnimationController.unbounded(
    vsync: this,
  );
  late final Listenable _motion = Listenable.merge([
    _low,
    _high,
    _lowKnob,
    _highKnob,
  ]);

  FocusNode? _ownHighFocus;
  late final FocusNode _lowFocus = FocusNode(
    debugLabel: 'PanelRangeSlider low',
  );
  FocusNode get _highFocus =>
      widget.focusNode ?? (_ownHighFocus ??= FocusNode(debugLabel: 'Slider'));

  bool _lowFocused = false;
  bool _highFocused = false;

  _Thumb _active = _Thumb.high;

  /// True from the moment a drag starts until it ends. A controlled parent
  /// echoes every change straight back, and springing the thumb onto that
  /// echo would fight the finger.
  bool _dragging = false;
  double _dragStartX = 0;
  double _dragStartLow = 0;
  double _dragStartHigh = 0;
  double _trackWidth = 0;

  /// Where each thumb was last sent to settle, so a parent that holds a
  /// different value than the one reported is caught up with.
  late double _lowTarget = _low.value;
  late double _highTarget = _high.value;

  /// The pair last reported to the parent, or last received from it. A pair
  /// is reported only when it moves off this one, so a drag reports each step
  /// once even before the parent has rebuilt, and a thumb ticks only when it
  /// lands on a new step. Each thumb has its own end of it, so the stationary
  /// end of a range cannot swallow the moving one's ticks.
  late double _reportedLow = _lowValue;
  late double _reportedHigh = _highValue;

  static const Map<ShortcutActivator, Intent> _shortcuts = {
    SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveIntent(_Move.left),
    SingleActivator(LogicalKeyboardKey.arrowRight): _MoveIntent(_Move.right),
    SingleActivator(LogicalKeyboardKey.arrowUp): _MoveIntent(_Move.up),
    SingleActivator(LogicalKeyboardKey.arrowDown): _MoveIntent(_Move.down),
    SingleActivator(LogicalKeyboardKey.pageUp): _MoveIntent(_Move.pageUp),
    SingleActivator(LogicalKeyboardKey.pageDown): _MoveIntent(_Move.pageDown),
    SingleActivator(LogicalKeyboardKey.home): _MoveIntent(_Move.home),
    SingleActivator(LogicalKeyboardKey.end): _MoveIntent(_Move.end),
  };

  late final Map<Type, Action<Intent>> _lowActions = {
    _MoveIntent: CallbackAction<_MoveIntent>(
      onInvoke: (intent) => _key(_Thumb.low, intent.move),
    ),
  };
  late final Map<Type, Action<Intent>> _highActions = {
    _MoveIntent: CallbackAction<_MoveIntent>(
      onInvoke: (intent) => _key(_Thumb.high, intent.move),
    ),
  };

  bool get _enabled => widget.onChanged != null;
  double get _span => widget.max > widget.min ? widget.max - widget.min : 0;

  /// How far a key or a screen reader moves a thumb: one step, or a
  /// hundredth of the range on a slider that moves freely.
  double get _stepSize =>
      widget.step > 0 ? widget.step : (_span > 0 ? _span / 100 : 1);

  /// Ordered and clamped, so a caller who passes the ends the wrong way round
  /// gets the span they meant rather than a fill of negative width.
  double get _lowValue => _clamp(widget.low);
  double get _highValue => _clamp(widget.high);

  /// The fraction the thumbs must keep between them.
  double get _gap => _span > 0 && widget.minStepsBetweenThumbs > 0
      ? widget.minStepsBetweenThumbs * widget.step / _span
      : 0;

  double _clamp(double value) =>
      value.clamp(widget.min, math.max(widget.min, widget.max));

  double _fraction(double value) =>
      _span > 0 ? ((value - widget.min) / _span).clamp(0.0, 1.0) : 0;

  double _valueAt(double fraction) => widget.min + fraction * _span;

  /// [value] on the nearest step, inside the range, without the float noise
  /// repeated steps leave (0.30000000000000004).
  double _snap(double value) {
    final step = widget.step;
    final max = math.max(widget.min, widget.max);
    if (step <= 0) return value.clamp(widget.min, max);
    final stepped = ((value - widget.min) / step).round() * step + widget.min;
    final text = step.toString();
    final dot = text.indexOf('.');
    final decimals = dot < 0 || text.contains('e') ? 0 : text.length - dot - 1;
    final tidy = double.parse(stepped.toStringAsFixed(math.min(decimals, 10)));
    return tidy.clamp(widget.min, max);
  }

  String _print(double value) =>
      widget.formatValue?.call(value) ?? value.round().toString();

  @override
  void didUpdateWidget(_SliderCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reportedLow = _lowValue;
    _reportedHigh = _highValue;
    final low = widget.range ? _fraction(_lowValue) : 0.0;
    final high = _fraction(_highValue);
    if (!_enabled) {
      // Disabled mid-gesture, the slider never hears the gesture end, so it
      // lets go here and puts the thumbs back on the values it holds.
      if (_dragging) {
        _dragging = false;
        _settle(_Thumb.low, low);
        _settle(_Thumb.high, high);
      }
      if (_lowKnob.isAnimating || _lowKnob.value != 0) {
        _pressKnob(_Thumb.low, false);
      }
      if (_highKnob.isAnimating || _highKnob.value != 0) {
        _pressKnob(_Thumb.high, false);
      }
    }
    if (_dragging) return;
    // Keep the thumbs in step with a controlled value that changed elsewhere,
    // or that the parent held somewhere other than where they were sent.
    if (low != _lowTarget) _settle(_Thumb.low, low);
    if (high != _highTarget) _settle(_Thumb.high, high);
  }

  @override
  void dispose() {
    _low.dispose();
    _high.dispose();
    _lowKnob.dispose();
    _highKnob.dispose();
    _lowFocus.dispose();
    _ownHighFocus?.dispose();
    super.dispose();
  }

  AnimationController _position(_Thumb thumb) =>
      thumb == _Thumb.low ? _low : _high;

  /// Springs [thumb] onto [fraction], or puts it there under reduced motion.
  void _settle(_Thumb thumb, double fraction) {
    if (thumb == _Thumb.low) {
      _lowTarget = fraction;
    } else {
      _highTarget = fraction;
    }
    final controller = _position(thumb);
    if (panelReduceMotion(context)) {
      controller.value = fraction;
    } else {
      controller.springTo(fraction, PanelSprings.snap);
    }
  }

  void _pressKnob(_Thumb thumb, bool down) {
    final knob = thumb == _Thumb.low ? _lowKnob : _highKnob;
    final target = down ? 1.0 : 0.0;
    if (panelReduceMotion(context)) {
      knob.value = target;
    } else {
      knob.springTo(target, PanelSprings.knob);
    }
  }

  /// Reports a new pair of values, ticking if [thumb] landed on a new step.
  void _report(double low, double high, {required bool end, _Thumb? thumb}) {
    if (low != _reportedLow || high != _reportedHigh) {
      final landed = switch (thumb) {
        _Thumb.low => low != _reportedLow,
        _Thumb.high => high != _reportedHigh,
        null => false,
      };
      if (widget.haptics && landed) HapticFeedback.selectionClick();
      _reportedLow = low;
      _reportedHigh = high;
      widget.onChanged?.call(low, high);
    }
    if (end) widget.onChangeEnd?.call(low, high);
  }

  double get _travel => math.max(_trackWidth - _metrics.thumb, 1);

  ({double height, double thumb}) get _metrics => _sliderMetrics[widget.size]!;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  /// The position along the track under [x], measured from the start edge,
  /// with the thumb's centre as the reference point.
  double _fractionAt(double x) {
    final along = _rtl ? _trackWidth - x : x;
    return ((along - _metrics.thumb / 2) / _travel).clamp(0.0, 1.0);
  }

  /// Which thumb a press at [x] takes. A tie goes to the thumb the press is
  /// outside of: with both stacked at one end, the nearer one may have
  /// nowhere to go, and a range that cannot be pulled off its own end is a
  /// broken control.
  _Thumb _pick(double x) {
    if (!widget.range) return _Thumb.high;
    final along = _rtl ? _trackWidth - x : x;
    final p = (along - _metrics.thumb / 2) / _travel;
    final toLow = (p - _low.value).abs();
    final toHigh = (p - _high.value).abs();
    if (toLow == toHigh) return p < _low.value ? _Thumb.low : _Thumb.high;
    return toLow < toHigh ? _Thumb.low : _Thumb.high;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _active = _pick(event.localPosition.dx);
    _pressKnob(_active, true);
    (_active == _Thumb.low ? _lowFocus : _highFocus).requestFocus();
  }

  void _handlePointerUp(PointerEvent event) {
    _pressKnob(_Thumb.low, false);
    _pressKnob(_Thumb.high, false);
  }

  void _handleDragStart(DragStartDetails details) {
    _dragging = true;
    _dragStartX = details.localPosition.dx;
    _dragStartLow = _low.value;
    _dragStartHigh = _high.value;
    _low.stop();
    _high.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    // A finger moving right in a right-to-left layout is moving back along
    // the scale.
    final sign = _rtl ? -1 : 1;
    final delta = (details.localPosition.dx - _dragStartX) * sign / _travel;
    if (!widget.range) {
      _high.value = (_dragStartHigh + delta).clamp(0.0, 1.0);
    } else if (_active == _Thumb.low) {
      // Each thumb is bounded by the other rather than by the track, so they
      // can meet but never cross.
      final ceiling = math.max(_high.value - _gap, 0.0);
      _low.value = (_dragStartLow + delta).clamp(0.0, ceiling);
    } else {
      final floor = math.min(_low.value + _gap, 1.0);
      _high.value = (_dragStartHigh + delta).clamp(floor, 1.0);
    }
    _reportPositions(end: false);
  }

  void _handleDragEnd([DragEndDetails? details]) {
    if (!_dragging) return;
    _dragging = false;
    final (low, high) = _reportPositions(end: true);
    // On release the thumb springs onto the step it was reported at.
    if (widget.range) _settle(_Thumb.low, _fraction(low));
    _settle(_Thumb.high, _fraction(high));
  }

  (double, double) _reportPositions({required bool end}) {
    final low = widget.range ? _snap(_valueAt(_low.value)) : widget.min;
    final high = _snap(_valueAt(_high.value));
    _report(low, high, end: end, thumb: _active);
    return (low, high);
  }

  void _handleTapUp(TapUpDetails details) {
    final next = _fractionAt(details.localPosition.dx);
    final thumb = _pick(details.localPosition.dx);
    var low = _lowValue;
    var high = _highValue;
    if (!widget.range) {
      high = _snap(_valueAt(next));
    } else if (thumb == _Thumb.low) {
      final bounded = math.min(next, math.max(_high.value - _gap, 0.0));
      low = _snap(_valueAt(bounded));
    } else {
      final bounded = math.max(next, math.min(_low.value + _gap, 1.0));
      high = _snap(_valueAt(bounded));
    }
    _settle(thumb, _fraction(thumb == _Thumb.low ? low : high));
    _report(widget.range ? low : widget.min, high, end: true, thumb: thumb);
  }

  /// Moves [thumb] by [steps] steps, or to [to], for a key or a screen
  /// reader.
  void _nudge(_Thumb thumb, {int steps = 0, double? to}) {
    if (!_enabled) return;
    final gapValue = widget.minStepsBetweenThumbs * widget.step;
    final current = thumb == _Thumb.low ? _lowValue : _highValue;
    final max = math.max(widget.min, widget.max);
    final wanted = to ?? current + steps * _stepSize;
    final double bounded;
    if (!widget.range) {
      bounded = wanted.clamp(widget.min, max);
    } else if (thumb == _Thumb.low) {
      bounded = wanted.clamp(
        widget.min,
        math.max(_highValue - gapValue, widget.min),
      );
    } else {
      bounded = wanted.clamp(math.min(_lowValue + gapValue, max), max);
    }
    final next = _snap(bounded);
    if (next == current) return;
    _settle(thumb, _fraction(next));
    if (thumb == _Thumb.low) {
      _report(next, _highValue, end: true, thumb: thumb);
    } else {
      _report(
        widget.range ? _lowValue : widget.min,
        next,
        end: true,
        thumb: thumb,
      );
    }
  }

  Object? _key(_Thumb thumb, _Move move) {
    // The left and right arrows follow the layout, so in a right-to-left one
    // left is forward. Up, down and the page keys do not turn around.
    final forward = _rtl ? -1 : 1;
    final page = math.max(1, (_span / _stepSize / 10).round());
    switch (move) {
      case _Move.left:
        _nudge(thumb, steps: -forward);
      case _Move.right:
        _nudge(thumb, steps: forward);
      case _Move.up:
        _nudge(thumb, steps: 1);
      case _Move.down:
        _nudge(thumb, steps: -1);
      case _Move.pageUp:
        _nudge(thumb, steps: page);
      case _Move.pageDown:
        _nudge(thumb, steps: -page);
      case _Move.home:
        _nudge(thumb, to: widget.min);
      case _Move.end:
        _nudge(thumb, to: widget.max);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final metrics = _metrics;
    final fill = _colorOf(c, widget.color);
    final enabled = _enabled;
    final rtl = _rtl;
    final radius = BorderRadius.circular(metrics.height / 2);
    final low = _lowValue;
    final high = _highValue;
    final shown = widget.range
        ? '${_print(low)} – ${_print(high)}'
        : _print(high);

    Widget thumb(_Thumb which) {
      final knob = which == _Thumb.low ? _lowKnob : _highKnob;
      final focused = which == _Thumb.low ? _lowFocused : _highFocused;
      Widget pill = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: fill, borderRadius: radius),
        child: Transform.scale(
          scale: 1 - knob.value * (1 - _knobPressedScale),
          // `background`, not a per-colour on-token: the status foregrounds
          // are the darker text hues meant for soft fills, and would barely
          // show on a solid one.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: radius,
              boxShadow: theme.shadows.sm,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
      if (focused) {
        pill = DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: c.ring.withValues(alpha: 0.4),
              width: 3,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: pill,
        );
      }
      return pill;
    }

    Widget semantics(_Thumb which, Widget child) {
      final isLow = which == _Thumb.low;
      final name = widget.semanticLabel ?? widget.label;
      final String? label;
      if (!widget.range) {
        label = name;
      } else if (isLow) {
        label = name == null ? 'Minimum' : '$name, minimum';
      } else {
        label = name == null ? 'Maximum' : '$name, maximum';
      }
      final current = isLow ? low : high;
      final gapValue = widget.minStepsBetweenThumbs * widget.step;
      final max = math.max(widget.min, widget.max);
      final floor = widget.range && !isLow ? low + gapValue : widget.min;
      final ceiling = widget.range && isLow ? high - gapValue : max;
      final up = _snap(math.min(current + _stepSize, ceiling));
      final down = _snap(math.max(current - _stepSize, floor));
      final canUp = enabled && up > current;
      final canDown = enabled && down < current;
      return Semantics(
        container: true,
        slider: true,
        enabled: enabled,
        label: label,
        value: widget.range ? _print(current) : shown,
        increasedValue: canUp ? _print(up) : null,
        decreasedValue: canDown ? _print(down) : null,
        onIncrease: canUp ? () => _nudge(which, steps: 1) : null,
        onDecrease: canDown ? () => _nudge(which, steps: -1) : null,
        child: FocusableActionDetector(
          enabled: enabled,
          focusNode: isLow ? _lowFocus : _highFocus,
          autofocus: !isLow && widget.autofocus,
          shortcuts: _shortcuts,
          actions: isLow ? _lowActions : _highActions,
          onShowFocusHighlight: (value) {
            if (isLow ? _lowFocused == value : _highFocused == value) return;
            setState(() {
              if (isLow) {
                _lowFocused = value;
              } else {
                _highFocused = value;
              }
            });
          },
          child: child,
        ),
      );
    }

    final track = LayoutBuilder(
      builder: (context, constraints) {
        _trackWidth = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _motion,
          builder: (context, _) {
            final travel = math.max(_trackWidth - metrics.thumb, 0.0);
            double left(double t) => rtl ? travel - t * travel : t * travel;
            final lowT = _low.value;
            final highT = _high.value;
            // The fill runs under both thumbs rather than up to them, so
            // neither shows a seam against it as it moves.
            final fillWidth =
                math.max((highT - lowT) * travel, 0.0) + metrics.thumb;
            return SizedBox(
              height: metrics.height,
              width: _trackWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.muted,
                        borderRadius: radius,
                      ),
                    ),
                  ),
                  Positioned(
                    left: rtl ? left(highT) : left(lowT),
                    top: 0,
                    bottom: 0,
                    width: fillWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: radius,
                      ),
                    ),
                  ),
                  if (widget.range)
                    Positioned(
                      key: const ValueKey(_Thumb.low),
                      left: left(lowT),
                      top: 0,
                      bottom: 0,
                      width: metrics.thumb,
                      child: semantics(_Thumb.low, thumb(_Thumb.low)),
                    ),
                  Positioned(
                    key: const ValueKey(_Thumb.high),
                    left: left(highT),
                    top: 0,
                    bottom: 0,
                    width: metrics.thumb,
                    child: semantics(_Thumb.high, thumb(_Thumb.high)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final interactive = PanelHitSlop(
      slop: const EdgeInsets.all(_hitSlop),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: Listener(
          onPointerDown: enabled ? _handlePointerDown : null,
          onPointerUp: enabled ? _handlePointerUp : null,
          onPointerCancel: enabled ? _handlePointerUp : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            dragStartBehavior: DragStartBehavior.down,
            onHorizontalDragStart: enabled ? _handleDragStart : null,
            onHorizontalDragUpdate: enabled ? _handleDragUpdate : null,
            onHorizontalDragEnd: enabled ? _handleDragEnd : null,
            onHorizontalDragCancel: enabled ? _handleDragEnd : null,
            onTapUp: enabled ? _handleTapUp : null,
            child: track,
          ),
        ),
      ),
    );

    final hasHeader = widget.label != null || widget.showValue;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (hasHeader)
            // The thumbs carry the name and the value for screen readers.
            ExcludeSemantics(
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: widget.label == null
                        ? const SizedBox.shrink()
                        : Text(
                            widget.label!,
                            style: theme.typography.style(
                              PanelTextSize.sm,
                              weight: FontWeight.w500,
                              color: c.foreground,
                            ),
                          ),
                  ),
                  if (widget.showValue)
                    Text(
                      shown,
                      style: theme.typography.style(
                        PanelTextSize.sm,
                        color: c.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
          interactive,
        ],
      ),
    );
  }
}

Color _colorOf(PanelColors c, PanelSliderColor color) {
  switch (color) {
    case PanelSliderColor.primary:
      return c.primary;
    case PanelSliderColor.success:
      return c.success;
    case PanelSliderColor.warning:
      return c.warning;
    case PanelSliderColor.destructive:
      return c.destructive;
    case PanelSliderColor.info:
      return c.info;
  }
}
