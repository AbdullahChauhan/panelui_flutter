import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_tokens.dart';
import '../theme/panel_typography.dart';

/// The colour of a [PanelProgress] bar. The track is the same colour at 16%.
enum PanelProgressColor {
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

/// How thick a [PanelProgress] bar is.
enum PanelProgressSize {
  /// A 6pt track.
  sm,

  /// An 8pt track, the default.
  md,

  /// A 12pt track.
  lg,
}

const _trackHeight = {
  PanelProgressSize.sm: 6.0,
  PanelProgressSize.md: 8.0,
  PanelProgressSize.lg: 12.0,
};

/// Settles the fill onto a new value.
const _fillSpring = SpringDescription(mass: 0.6, stiffness: 180, damping: 20);

/// Fraction of the track covered by the sliding bar in indeterminate mode.
const _indeterminateWidth = 0.4;

/// How long the bar takes to cross the track once.
const _sweepDuration = Duration(milliseconds: 1100);

/// One half of the fade that stands in for the sweep under reduced motion.
const _pulseDuration = Duration(milliseconds: 900);

/// How far the fade goes down: faint enough to read as a pulse, not a flicker.
const _pulseFloor = 0.35;

/// Reanimated's `Easing.inOut(Easing.ease)`: the ease-in curve run forwards
/// over the first half and mirrored over the second.
class _InOutEase extends Curve {
  const _InOutEase();

  @override
  double transformInternal(double t) => t < 0.5
      ? Curves.easeIn.transform(t * 2) / 2
      : 1 - Curves.easeIn.transform((1 - t) * 2) / 2;
}

/// A determinate or indeterminate progress bar.
///
/// ```dart
/// PanelProgress(value: 64, label: 'Downloading', showValueLabel: true)
/// PanelProgress(value: 1250, max: 2000, formatValue: (v) => '\$${v.round()}')
/// const PanelProgress(indeterminate: true, color: PanelProgressColor.info)
/// ```
///
/// [value] is read against [min] and [max], which default to 0 and 100, so a
/// percentage needs neither. Set them and the bar speaks in whatever the work
/// is counted in: bytes uploaded, seats filled. Nothing has to be converted to
/// a percent on the way in, and the screen reader is told the real range.
///
/// The fill springs to each new value. [indeterminate] sweeps a bar across the
/// track for work of unknown length. Under reduced motion the fill lands on
/// its value instead of springing, and the indeterminate bar fills the track
/// and pulses in place: a bar that froze would read as one that had hung.
///
/// Give it [label] or [showValueLabel] and it draws a caption row above the
/// track; otherwise the track stands alone.
class PanelProgress extends StatefulWidget {
  /// Creates a progress bar.
  const PanelProgress({
    super.key,
    this.value = 0,
    this.min = 0,
    this.max = 100,
    this.indeterminate = false,
    this.color = PanelProgressColor.primary,
    this.size = PanelProgressSize.md,
    this.label,
    this.showValueLabel = false,
    this.valueLabel,
    this.formatValue,
    this.semanticLabel,
  });

  /// Where the work has got to, between [min] and [max]. Ignored while
  /// [indeterminate].
  final double value;

  /// The value at which the bar reads as empty.
  final double min;

  /// The value at which the bar reads as full.
  final double max;

  /// Loops a bar across the track for work of unknown length.
  final bool indeterminate;

  /// The colour of the bar and its track.
  final PanelProgressColor color;

  /// The thickness.
  final PanelProgressSize size;

  /// A caption above the track, at its start. Also the accessible name.
  final String? label;

  /// Draws the value above the track, at its end. Hidden while
  /// [indeterminate], when there is nothing meaningful to show.
  final bool showValueLabel;

  /// Text for the value, in place of the formatted one: a byte count, a step
  /// tally, anything that is not a bare percentage.
  final String? valueLabel;

  /// Writes the value, for a currency or a count. The default is the share of
  /// the range as a rounded percentage.
  final String Function(double value)? formatValue;

  /// The accessible name, when [label] is not shown or not enough.
  final String? semanticLabel;

  @override
  State<PanelProgress> createState() => _PanelProgressState();
}

/// How far along [value] is, 0 to 1. An empty or inverted range has no
/// position in it, so it reads as empty rather than dividing by zero.
double _fractionOf(double value, double min, double max) {
  final span = max - min;
  if (!(span > 0)) return 0;
  return ((value - min) / span).clamp(0.0, 1.0);
}

/// [value] held inside the range, so a stray number cannot escape the track.
double _clampTo(double value, double min, double max) {
  if (!(value > min)) return min;
  if (value > max) return max;
  return value;
}

/// A number as a screen reader should hear it: no trailing `.0`.
String _plain(double value) =>
    value == value.roundToDouble() ? value.round().toString() : '$value';

class _PanelProgressState extends State<PanelProgress>
    with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController.unbounded(
    vsync: this,
    value: _target,
  );
  late final AnimationController _loop = AnimationController(vsync: this);
  bool? _reduced;

  double get _target => _fractionOf(widget.value, widget.min, widget.max);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = panelReduceMotion(context);
    if (reduced == _reduced) return;
    _reduced = reduced;
    _syncLoop();
  }

  @override
  void didUpdateWidget(PanelProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indeterminate != widget.indeterminate) _syncLoop();
    if (widget.indeterminate) return;
    final target = _target;
    final oldTarget = _fractionOf(
      oldWidget.value,
      oldWidget.min,
      oldWidget.max,
    );
    if (target == oldTarget && !oldWidget.indeterminate) return;
    // The number is the information; the overshoot is decoration, so reduced
    // motion lands on the value instead.
    if (_reduced ?? false) {
      _fill.value = target;
    } else {
      _fill.springTo(target, _fillSpring);
    }
  }

  /// The loop is tied to [PanelProgress.indeterminate] and to how much motion
  /// is wanted, not to the value: restarting it whenever the value moved would
  /// leave it cycling from wherever the bar had got to.
  void _syncLoop() {
    if (!widget.indeterminate) {
      _loop.stop();
      return;
    }
    final reduced = _reduced ?? false;
    _loop
      ..duration = reduced ? _pulseDuration : _sweepDuration
      ..value = 0
      // The sweep restarts at the start edge; the pulse turns around, because
      // one that snapped back to full strength would be the flicker reduced
      // motion is there to avoid.
      ..repeat(reverse: reduced);
  }

  @override
  void dispose() {
    _fill.dispose();
    _loop.dispose();
    super.dispose();
  }

  String _readout(double clamped, double fraction) {
    final valueLabel = widget.valueLabel;
    if (valueLabel != null) return valueLabel;
    final format = widget.formatValue;
    if (format != null) return format(clamped);
    return '${(fraction * 100).round()}%';
  }

  /// Whether [readout] can stand as a progress bar's value for assistive
  /// technology: a number inside the range, or a percentage.
  bool _numeric(String readout) {
    if (!(widget.max > widget.min)) return false;
    final number = double.tryParse(readout);
    if (number != null) return number >= widget.min && number <= widget.max;
    if (!readout.endsWith('%')) return false;
    final percent = double.tryParse(readout.substring(0, readout.length - 1));
    return percent != null && percent >= 0 && percent <= 100;
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final indicator = _colorOf(c, widget.color);
    final indeterminate = widget.indeterminate;
    final clamped = _clampTo(widget.value, widget.min, widget.max);
    final spoken = _readout(clamped, _target);

    final bar = SizedBox(
      height: _trackHeight[widget.size],
      width: double.infinity,
      child: CustomPaint(
        painter: _ProgressPainter(
          fill: _fill,
          loop: _loop,
          indeterminate: indeterminate,
          reduced: _reduced ?? false,
          track: indicator.withValues(alpha: indicator.a * 0.16),
          indicator: indicator,
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    );

    final numeric = !indeterminate && _numeric(spoken);
    final track = Semantics(
      container: true,
      label: widget.semanticLabel ?? widget.label,
      value: indeterminate ? null : spoken,
      // Indeterminate has no value to announce, so the role is what separates
      // "working, length unknown" from "empty and going nowhere".
      role: indeterminate
          ? SemanticsRole.loadingSpinner
          : (numeric ? SemanticsRole.progressBar : null),
      minValue: numeric ? _plain(widget.min) : null,
      maxValue: numeric ? _plain(widget.max) : null,
      child: bar,
    );

    // The value label is meaningless while looping, so it is dropped there.
    final showValue = widget.showValueLabel && !indeterminate;
    if (widget.label == null && !showValue) return track;

    final header = ExcludeSemantics(
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: widget.label == null
                ? const SizedBox.shrink()
                : Text(
                    widget.label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.style(
                      PanelTextSize.sm,
                      weight: FontWeight.w500,
                      color: c.foreground,
                    ),
                  ),
          ),
          if (showValue)
            Text(
              spoken,
              style: theme.typography.style(
                PanelTextSize.sm,
                color: c.mutedForeground,
              ),
            ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [header, track],
    );
  }
}

Color _colorOf(PanelColors c, PanelProgressColor color) {
  switch (color) {
    case PanelProgressColor.primary:
      return c.primary;
    case PanelProgressColor.success:
      return c.success;
    case PanelProgressColor.warning:
      return c.warning;
    case PanelProgressColor.destructive:
      return c.destructive;
    case PanelProgressColor.info:
      return c.info;
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({
    required this.fill,
    required this.loop,
    required this.indeterminate,
    required this.reduced,
    required this.track,
    required this.indicator,
    required this.rtl,
  }) : super(repaint: Listenable.merge([fill, loop]));

  final Animation<double> fill;
  final Animation<double> loop;
  final bool indeterminate;
  final bool reduced;
  final Color track;
  final Color indicator;
  final bool rtl;

  static const _ease = _InOutEase();

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final trackShape = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(trackShape, Paint()..color = track);

    double start;
    double width;
    var opacity = 1.0;
    if (!indeterminate) {
      // The spring may overshoot past either end; the track clips it.
      start = 0;
      width = size.width * math.max(fill.value, 0);
    } else if (reduced) {
      // Nothing travels: the whole track carries the bar and the bar breathes.
      start = 0;
      width = size.width;
      opacity = 1 - _ease.transform(loop.value) * (1 - _pulseFloor);
    } else {
      width = size.width * _indeterminateWidth;
      start = -width + _ease.transform(loop.value) * (size.width + width);
    }
    if (width <= 0) return;

    // The bar runs the way the text does.
    final left = rtl ? size.width - start - width : start;
    canvas
      ..save()
      ..clipRRect(trackShape)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 0, width, size.height),
          radius,
        ),
        Paint()..color = indicator.withValues(alpha: indicator.a * opacity),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.loop != loop ||
      oldDelegate.indeterminate != indeterminate ||
      oldDelegate.reduced != reduced ||
      oldDelegate.track != track ||
      oldDelegate.indicator != indicator ||
      oldDelegate.rtl != rtl;
}
