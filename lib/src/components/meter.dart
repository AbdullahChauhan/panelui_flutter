import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_tokens.dart';
import '../theme/panel_typography.dart';

/// The colour a [PanelMeter] reads in.
enum PanelMeterColor {
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

  /// The muted foreground, for a reading with no judgement attached.
  muted,
}

/// How thick a [PanelMeter] is.
enum PanelMeterSize {
  /// 6pt.
  sm(6, 4),

  /// 8pt, the default.
  md(8, 6),

  /// 12pt.
  lg(12, 6);

  const PanelMeterSize(this.thickness, this.segmentGap);

  /// Track thickness.
  final double thickness;

  /// Gap between segments.
  final double segmentGap;
}

/// A point on the scale where a [PanelMeter] changes colour.
@immutable
class PanelMeterThreshold {
  /// Colours readings at or above [from] in [color].
  const PanelMeterThreshold({required this.from, required this.color});

  /// Where on the scale the colour takes over, in the units of the reading
  /// (gigabytes on a disk meter), not as a percentage.
  final double from;

  /// The colour from there up.
  final PanelMeterColor color;
}

/// A measurement on a fixed scale, coloured by where it falls: disk used,
/// battery left, a score, a password's strength.
///
/// A meter is not a progress bar: progress is a task moving towards an end,
/// a meter is a reading that sits where it sits and may go back down. The
/// difference shows in the colour: [thresholds] make it a judgement about the
/// reading. Which direction is bad is yours to say: thresholds climbing to
/// destructive suit a disk filling up, falling to it a battery running down.
/// [segments] draws the scale as discrete blocks, all or nothing, because
/// four blocks say "three of four" where a bar says "about seventy percent".
///
/// The value is read against [min] and [max], which default to 0 and 100, so
/// a percentage needs neither. Set them and the meter speaks in whatever is
/// being measured, and screen readers are told the real scale.
///
/// ```dart
/// PanelMeter(
///   label: 'Storage',
///   value: 212,
///   max: 256,
///   showValueLabel: true,
///   valueLabel: '212 of 256 GB',
///   thresholds: const [
///     PanelMeterThreshold(from: 192, color: PanelMeterColor.warning),
///     PanelMeterThreshold(from: 240, color: PanelMeterColor.destructive),
///   ],
/// )
/// ```
///
/// The fill springs to each new reading and never past it; under reduced
/// motion it lands on the reading instead. It is announced as a progress bar
/// with its label and reading, the nearest role a platform offers.
class PanelMeter extends StatefulWidget {
  /// Creates a meter.
  const PanelMeter({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.label,
    this.showValueLabel = false,
    this.valueLabel,
    this.formatValue,
    this.semanticLabel,
    this.color = PanelMeterColor.primary,
    this.thresholds = const [],
    this.segments = 0,
    this.size = PanelMeterSize.md,
  });

  /// The reading. Values outside the scale are held at its ends.
  final double value;

  /// The bottom of the scale, where the bar reads as empty. A bound that is
  /// not finite falls back to its default, and a scale with no span reads as
  /// empty.
  final double min;

  /// The top of the scale, where the bar reads as full.
  final double max;

  /// What is being measured, drawn above the track. Also the accessible
  /// name: without one a meter announces a number with nothing attached.
  final String? label;

  /// Draw the reading above the track, opposite the label.
  final bool showValueLabel;

  /// Text for the reading, in place of the formatted value: a word where a
  /// number reads worse ("Strong", "Almost full"). It is spoken whether or
  /// not it is drawn.
  final String? valueLabel;

  /// Writes the reading, for a quantity rather than a share ("64 GB"). The
  /// default is the share of the scale as a rounded percentage.
  final String Function(double value)? formatValue;

  /// The accessible name, where the caption is drawn some other way.
  final String? semanticLabel;

  /// The colour below every threshold.
  final PanelMeterColor color;

  /// Points where the colour changes. The highest one the reading has reached
  /// wins, so their order does not matter.
  final List<PanelMeterThreshold> thresholds;

  /// Draw this many discrete blocks instead of a bar, up to 100. 0 draws a
  /// bar. Any reading above the floor lights at least one block, so "a
  /// little" never looks like "none".
  final int segments;

  /// The thickness.
  final PanelMeterSize size;

  @override
  State<PanelMeter> createState() => _PanelMeterState();
}

/// How long a segment takes to light or go out.
const Duration _segmentDuration = Duration(milliseconds: 180);

/// How faint an unlit segment sits: present, but plainly not counted.
const double _segmentUnlit = 0.22;

/// A bound on the block count, so a stray number cannot build without limit.
const int _maxSegments = 100;

class _PanelMeterState extends State<PanelMeter>
    with SingleTickerProviderStateMixin {
  late _MeterScale _scale = _scaleOf(widget);
  late final AnimationController _fill = AnimationController.unbounded(
    vsync: this,
    value: _scale.fraction,
  );

  /// Where the fill's current move began. The drawn fill is held between it
  /// and the reading, as PanelUI's `overshootClamping` holds it: the number
  /// is the information, and a spring past it would misreport it.
  late double _from = _scale.fraction;

  double get _drawn {
    final target = _scale.fraction;
    return _fill.value.clamp(math.min(_from, target), math.max(_from, target));
  }

  @override
  void didUpdateWidget(PanelMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final drawn = _drawn;
    final previous = _scale.fraction;
    _scale = _scaleOf(widget);
    final target = _scale.fraction;
    if (target == previous) return;
    _from = drawn;
    // Reduced motion lands on the reading: the number is the information,
    // and the spring is decoration.
    if (panelReduceMotion(context)) {
      _fill.value = target;
    } else {
      _fill.springTo(target, PanelSprings.fill);
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  /// The highest threshold the reading has reached, or the base colour.
  PanelMeterColor get _resolvedColor {
    PanelMeterThreshold? winner;
    for (final threshold in widget.thresholds) {
      if (!threshold.from.isFinite || _scale.value < threshold.from) continue;
      if (winner == null || threshold.from > winner.from) winner = threshold;
    }
    return winner?.color ?? widget.color;
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final scale = _scale;
    final (track, fill) = _palette(c, _resolvedColor);
    final thickness = widget.size.thickness;
    final readout =
        widget.valueLabel ??
        widget.formatValue?.call(scale.value) ??
        '${(scale.fraction * 100).round()}%';
    final count = widget.segments.clamp(0, _maxSegments);

    final Widget bar;
    if (count > 0) {
      bar = _Segments(
        count: count,
        lit: _litSegments(scale.fraction, count),
        color: fill,
        size: widget.size,
        animate: !panelReduceMotion(context),
      );
    } else {
      final radius = BorderRadius.circular(thickness / 2);
      bar = Container(
        height: thickness,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: track, borderRadius: radius),
        child: AnimatedBuilder(
          animation: _fill,
          child: DecoratedBox(
            decoration: BoxDecoration(color: fill, borderRadius: radius),
          ),
          builder: (context, child) => FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: _drawn,
            child: child,
          ),
        ),
      );
    }

    final hasHeader = widget.label != null || widget.showValueLabel;
    final numeric = _isNumeric(readout, scale);
    return Semantics(
      container: true,
      label: widget.semanticLabel ?? widget.label,
      value: readout,
      role: numeric ? SemanticsRole.progressBar : null,
      minValue: numeric ? _plain(scale.min) : null,
      maxValue: numeric ? _plain(scale.max) : null,
      // The caption row draws the name and the reading the bar already
      // carries, so it is not read a second time.
      excludeSemantics: true,
      child: !hasHeader
          ? bar
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                _Caption(
                  label: widget.label,
                  readout: widget.showValueLabel ? readout : null,
                ),
                bar,
              ],
            ),
    );
  }

  static (Color track, Color fill) _palette(PanelColors c, PanelMeterColor m) {
    Color tint(Color color) => color.withValues(alpha: 0.16);
    return switch (m) {
      PanelMeterColor.primary => (tint(c.primary), c.primary),
      PanelMeterColor.success => (tint(c.success), c.success),
      PanelMeterColor.warning => (tint(c.warning), c.warning),
      PanelMeterColor.destructive => (tint(c.destructive), c.destructive),
      PanelMeterColor.info => (tint(c.info), c.info),
      PanelMeterColor.muted => (c.muted, c.mutedForeground),
    };
  }
}

/// Where a reading sits on a meter's scale: PanelUI's `normalizeScale`.
///
/// Bounds that are not finite fall back to their defaults, a top below the
/// bottom collapses onto it, and a reading is held inside the result, so a
/// malformed scale reads as empty rather than throwing or escaping the track.
typedef _MeterScale = ({double min, double max, double value, double fraction});

_MeterScale _scaleOf(PanelMeter meter) {
  final floor = meter.min.isFinite ? meter.min : 0.0;
  final top = meter.max.isFinite ? meter.max : 100.0;
  final ceiling = top > floor ? top : floor;
  final value = meter.value;
  final held = value.isNaN ? floor : value.clamp(floor, ceiling).toDouble();
  // Divided through by the largest magnitude first, so a scale near the ends
  // of the double range cannot overflow its own span.
  final magnitude = math.max(math.max(floor.abs(), ceiling.abs()), 1.0);
  final position = ceiling > floor
      ? (held / magnitude - floor / magnitude) /
            (ceiling / magnitude - floor / magnitude)
      : 0.0;
  return (
    min: floor,
    max: ceiling,
    value: held,
    fraction: position.clamp(0.0, 1.0),
  );
}

/// How many of [count] blocks are lit at [fraction]: rounded up, so any
/// reading above the floor lights at least one.
int _litSegments(double fraction, int count) {
  if (fraction <= 0) return 0;
  if (fraction >= 1) return count;
  return math.min((fraction * count).ceil(), count);
}

/// Whether [readout] can stand as a progress bar's value for assistive
/// technology: a number inside the scale, or a percentage.
bool _isNumeric(String readout, _MeterScale scale) {
  if (!(scale.max > scale.min)) return false;
  final number = double.tryParse(readout);
  if (number != null) return number >= scale.min && number <= scale.max;
  if (!readout.endsWith('%')) return false;
  final percent = double.tryParse(readout.substring(0, readout.length - 1));
  return percent != null && percent >= 0 && percent <= 100;
}

/// A bound as a screen reader should hear it: no trailing `.0`.
String _plain(double value) =>
    value == value.roundToDouble() ? value.round().toString() : '$value';

/// The label at the start of the row above the track, and the reading at its
/// end.
class _Caption extends StatelessWidget {
  const _Caption({required this.label, required this.readout});

  final String? label;
  final String? readout;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    return Row(
      spacing: 8,
      children: [
        if (label != null)
          Expanded(
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.style(
                PanelTextSize.sm,
                weight: FontWeight.w500,
                color: c.foreground,
              ),
            ),
          )
        else
          const Spacer(),
        if (readout != null)
          Text(
            readout!,
            maxLines: 1,
            style: theme.typography.style(
              PanelTextSize.sm,
              color: c.mutedForeground,
            ),
          ),
      ],
    );
  }
}

/// A segmented meter's blocks, each lighting or going out on its own.
class _Segments extends StatelessWidget {
  const _Segments({
    required this.count,
    required this.lit,
    required this.color,
    required this.size,
    required this.animate,
  });

  final int count;
  final int lit;
  final Color color;
  final PanelMeterSize size;

  /// Whether a block fades as it lights; under reduced motion it switches.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final thickness = size.thickness;
    final block = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(thickness / 2),
      ),
    );
    return SizedBox(
      height: thickness,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: size.segmentGap,
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: AnimatedOpacity(
                duration: animate ? _segmentDuration : Duration.zero,
                curve: panelEase,
                opacity: i < lit ? 1 : _segmentUnlit,
                child: block,
              ),
            ),
        ],
      ),
    );
  }
}
