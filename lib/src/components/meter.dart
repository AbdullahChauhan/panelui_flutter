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

  /// Where on the scale the colour takes over.
  final double from;

  /// The colour from there up.
  final PanelMeterColor color;
}

/// A measurement on a fixed scale, coloured by where it falls.
///
/// The difference from a progress bar is the colour: [thresholds] make it a
/// judgement about the reading. Which direction is bad is yours to say:
/// thresholds climbing to destructive suit a disk filling up, falling to it a
/// battery running down. [segments] draws the scale as discrete blocks, all or
/// nothing, because four blocks say "three of four" where a bar says "about
/// seventy percent".
///
/// ```dart
/// PanelMeter(
///   label: 'Storage',
///   value: 212,
///   max: 256,
///   valueLabel: '212 of 256 GB',
///   thresholds: const [
///     PanelMeterThreshold(from: 192, color: PanelMeterColor.warning),
///     PanelMeterThreshold(from: 240, color: PanelMeterColor.destructive),
///   ],
/// )
/// ```
class PanelMeter extends StatefulWidget {
  /// Creates a meter.
  const PanelMeter({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.label,
    this.showValueLabel = true,
    this.valueLabel,
    this.color = PanelMeterColor.primary,
    this.thresholds = const [],
    this.segments = 0,
    this.size = PanelMeterSize.md,
  });

  /// The reading. Values outside the scale are held at its ends.
  final double value;

  /// The bottom of the scale.
  final double min;

  /// The top of the scale.
  final double max;

  /// What is being measured. Also the accessible name.
  final String? label;

  /// Draw the value above the track, opposite the label.
  final bool showValueLabel;

  /// Text for the value, in place of a rounded percent: "212 of 256 GB",
  /// "Strong". It is spoken whether or not it is drawn.
  final String? valueLabel;

  /// The colour below every threshold.
  final PanelMeterColor color;

  /// Points where the colour changes. The highest one reached wins.
  final List<PanelMeterThreshold> thresholds;

  /// Draw this many discrete blocks instead of a bar. 0 draws a bar.
  final int segments;

  /// The thickness.
  final PanelMeterSize size;

  @override
  State<PanelMeter> createState() => _PanelMeterState();
}

class _PanelMeterState extends State<PanelMeter>
    with SingleTickerProviderStateMixin {
  // Settles without overshooting: the number is the information, and an
  // overshoot past it would be decoration that misreports it.
  static const _spring = SpringDescription(
    mass: 0.6,
    stiffness: 180,
    damping: 20,
  );

  late final AnimationController _fill = AnimationController.unbounded(
    vsync: this,
    value: _fraction,
  );
  late double _from = _fraction;

  double get _held => widget.value.isNaN
      ? widget.min
      : widget.value.clamp(widget.min, widget.max).toDouble();

  double get _fraction => widget.max > widget.min
      ? ((_held - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0)
      : 0;

  @override
  void didUpdateWidget(PanelMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _fraction;
    if (target == _fill.value) return;
    _from = _fill.value;
    if (panelReduceMotion(context)) {
      _fill.value = target;
    } else {
      _fill.springTo(target, _spring);
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  PanelMeterColor get _resolvedColor {
    PanelMeterThreshold? winner;
    for (final t in widget.thresholds) {
      if (!t.from.isFinite || _held < t.from) continue;
      if (winner == null || t.from > winner.from) winner = t;
    }
    return winner?.color ?? widget.color;
  }

  static (Color track, Color fill) _palette(PanelColors c, PanelMeterColor m) {
    Color tint(Color x) => x.withValues(alpha: 0.16);
    return switch (m) {
      PanelMeterColor.primary => (tint(c.primary), c.primary),
      PanelMeterColor.success => (tint(c.success), c.success),
      PanelMeterColor.warning => (tint(c.warning), c.warning),
      PanelMeterColor.destructive => (tint(c.destructive), c.destructive),
      PanelMeterColor.info => (tint(c.info), c.info),
      PanelMeterColor.muted => (c.muted, c.mutedForeground),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final (trackColor, fillColor) = _palette(c, _resolvedColor);
    final thickness = widget.size.thickness;
    final valueText = widget.valueLabel ?? '${(_fraction * 100).round()}%';
    final count = widget.segments.clamp(0, 100);

    Widget bar;
    if (count > 0) {
      final lit = _fraction <= 0
          ? 0
          : _fraction >= 1
          ? count
          : (_fraction * count).ceil().clamp(1, count);
      bar = Row(
        spacing: widget.size.segmentGap,
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                curve: panelEase,
                opacity: i < lit ? 1 : 0.22,
                child: Container(
                  height: thickness,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(thickness / 2),
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      bar = Container(
        height: thickness,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(thickness / 2),
        ),
        child: AnimatedBuilder(
          animation: _fill,
          builder: (context, _) {
            // Clamp to the span of this move, so the spring never draws past
            // the reading it is heading for.
            final target = _fraction;
            final lo = _from < target ? _from : target;
            final hi = _from < target ? target : _from;
            final t = _fill.value.clamp(lo, hi).clamp(0.0, 1.0);
            return FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: t,
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(thickness / 2),
                ),
              ),
            );
          },
        ),
      );
    }

    final hasHeader = widget.label != null || widget.showValueLabel;
    return Semantics(
      container: true,
      label: widget.label,
      value: valueText,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          if (hasHeader)
            Row(
              spacing: 8,
              children: [
                if (widget.label != null)
                  Expanded(
                    child: Text(
                      widget.label!,
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
                if (widget.showValueLabel)
                  Text(
                    valueText,
                    maxLines: 1,
                    style: theme.typography.style(
                      PanelTextSize.sm,
                      color: c.mutedForeground,
                    ),
                  ),
              ],
            ),
          bar,
        ],
      ),
    );
  }
}
