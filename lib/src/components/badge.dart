import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_tokens.dart';
import '../theme/panel_typography.dart';

/// How a [PanelBadge] is coloured.
enum PanelBadgeVariant {
  /// Filled with the `primary` token: PanelUI's `default`, for the one thing
  /// on a screen that should be seen first.
  primary,

  /// A quiet tinted fill.
  secondary,

  /// A hairline border and no fill.
  outline,

  /// Filled with the `destructive` token.
  destructive,

  /// A tinted success fill with success text.
  success,

  /// A tinted warning fill with warning text.
  warning,

  /// A tinted info fill with info text.
  info,
}

/// How big a [PanelBadge] is.
enum PanelBadgeSize {
  /// 10px text.
  xs,

  /// 11px text.
  sm,

  /// 12px text, the default.
  md,

  /// 14px text.
  lg,

  /// 16px text.
  xl,
}

/// The outline of a [PanelBadge].
enum PanelBadgeShape {
  /// A rounded rectangle around a label: PanelUI's `default` shape.
  label,

  /// A bare status dot, with no label.
  dot,

  /// A circle sized for a count over an avatar or an icon.
  count,
}

/// A small status label, dot or count.
///
/// ```dart
/// const PanelBadge(child: Text('New'))
/// const PanelBadge(variant: PanelBadgeVariant.success, child: Text('Paid'))
/// const PanelBadge.count(12)
/// const PanelBadge.dot(variant: PanelBadgeVariant.destructive)
/// ```
///
/// A badge keeps to the size of its content at the start of its parent, as
/// PanelUI's `self-start` does, so a stretching column does not widen it into
/// a bar. Its label and icons take the variant's text colour; an icon is drawn
/// at 14pt unless it is given a size.
///
/// A dot takes the variant's own fill, so a status dot is the same faint tint
/// a status label sits on. For a status that has to be seen at a glance, put
/// a solid dot beside the text inside a label badge, 4pt from it (the badge's
/// `gap-1`).
class PanelBadge extends StatelessWidget {
  /// A badge around [child].
  const PanelBadge({
    super.key,
    this.child,
    this.variant = PanelBadgeVariant.primary,
    this.size = PanelBadgeSize.md,
    this.shape = PanelBadgeShape.label,
  }) : count = null;

  /// A circular count, shown as "99+" past 99 and announced as, say, "128
  /// unread".
  const PanelBadge.count(
    int this.count, {
    super.key,
    this.variant = PanelBadgeVariant.primary,
    this.size = PanelBadgeSize.md,
  }) : child = null,
       shape = PanelBadgeShape.count;

  /// A bare status dot.
  const PanelBadge.dot({
    super.key,
    this.variant = PanelBadgeVariant.primary,
    this.size = PanelBadgeSize.md,
  }) : child = null,
       count = null,
       shape = PanelBadgeShape.dot;

  /// The label.
  final Widget? child;

  /// The number shown by [PanelBadge.count].
  final int? count;

  /// The colouring.
  final PanelBadgeVariant variant;

  /// The size.
  final PanelBadgeSize size;

  /// The outline.
  final PanelBadgeShape shape;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final palette = _BadgePalette.of(theme.colors, variant);
    final metrics = _BadgeMetrics.of(size);
    final labelStyle = metrics.labelStyle(theme.typography, palette.text);
    final Widget badge = switch (shape) {
      PanelBadgeShape.dot => ExcludeSemantics(
        child: Container(
          width: metrics.dot,
          height: metrics.dot,
          decoration: BoxDecoration(
            color: palette.fill,
            shape: BoxShape.circle,
            border: Border.all(color: palette.border),
          ),
        ),
      ),
      PanelBadgeShape.count => _BadgeBox(
        palette: palette,
        labelStyle: labelStyle,
        height: metrics.countHeight,
        padding: EdgeInsets.symmetric(horizontal: metrics.countPadding),
        radius: metrics.countHeight / 2,
        child: _label,
      ),
      PanelBadgeShape.label => _BadgeBox(
        palette: palette,
        labelStyle: labelStyle,
        padding: metrics.padding,
        radius: theme.radii.sm,
        child: _label,
      ),
    };

    final aligned = Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: badge,
    );
    final value = count;
    if (value == null) return aligned;
    return Semantics(
      label: '$value unread',
      excludeSemantics: true,
      child: aligned,
    );
  }

  /// The count, clamped so the badge keeps its shape, or the child.
  Widget get _label {
    final value = count;
    if (value == null) return child ?? const SizedBox.shrink();
    return Text(value > _maxCount ? '$_maxCount+' : '$value');
  }
}

/// Counts past this render as "99+" so the badge keeps its shape.
const int _maxCount = 99;

/// The size an icon in a badge is drawn at unless it is given one: the web
/// badge's `[&_svg]:size-3.5`.
const double _glyphSize = 14;

/// One size of a [PanelBadge], from PanelUI's `size` variants and its `dot`
/// and `count` compound variants.
class _BadgeMetrics {
  const _BadgeMetrics({
    required this.padding,
    required this.fontSize,
    required this.step,
    required this.dot,
    required this.countHeight,
    required this.countPadding,
  });

  static _BadgeMetrics of(PanelBadgeSize size) => switch (size) {
    PanelBadgeSize.xs => const _BadgeMetrics(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      fontSize: 10,
      step: null,
      dot: 4,
      countHeight: 14,
      countPadding: 4,
    ),
    PanelBadgeSize.sm => const _BadgeMetrics(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      fontSize: 11,
      step: null,
      dot: 6,
      countHeight: 16,
      countPadding: 4,
    ),
    PanelBadgeSize.md => const _BadgeMetrics(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      fontSize: 12,
      step: PanelTextSize.xs,
      dot: 8,
      countHeight: 20,
      countPadding: 6,
    ),
    PanelBadgeSize.lg => const _BadgeMetrics(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      fontSize: 14,
      step: PanelTextSize.sm,
      dot: 10,
      countHeight: 24,
      countPadding: 8,
    ),
    PanelBadgeSize.xl => const _BadgeMetrics(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      fontSize: 16,
      step: PanelTextSize.base,
      dot: 12,
      countHeight: 28,
      countPadding: 8,
    ),
  };

  final EdgeInsets padding;

  /// The label size for the two bare sizes (`text-[10px]`, `text-[11px]`),
  /// which keep the font's own line height.
  final double fontSize;

  /// The type-scale step for the others (`text-xs` … `text-base`), whose
  /// paired line height sets the badge's height.
  final PanelTextSize? step;

  /// The diameter of a dot.
  final double dot;

  /// The height, and least width, of a count.
  final double countHeight;

  final double countPadding;

  TextStyle labelStyle(PanelTypography typography, Color color) {
    final step = this.step;
    if (step == null) {
      return typography.sized(fontSize, weight: FontWeight.w500, color: color);
    }
    return typography.style(step, weight: FontWeight.w500, color: color);
  }
}

/// The colours one variant resolves to in the current theme.
class _BadgePalette {
  const _BadgePalette(this.fill, this.border, this.text);

  factory _BadgePalette.of(PanelColors c, PanelBadgeVariant variant) =>
      switch (variant) {
        PanelBadgeVariant.primary => _BadgePalette(
          c.primary,
          _clear,
          c.primaryForeground,
        ),
        PanelBadgeVariant.secondary => _BadgePalette(
          c.secondary,
          _clear,
          c.secondaryForeground,
        ),
        PanelBadgeVariant.outline => _BadgePalette(
          _clear,
          c.border,
          c.foreground,
        ),
        PanelBadgeVariant.destructive => _BadgePalette(
          c.destructive,
          _clear,
          c.destructiveSolidForeground,
        ),
        PanelBadgeVariant.success => _BadgePalette(
          c.successSubtle,
          _clear,
          c.successForeground,
        ),
        PanelBadgeVariant.warning => _BadgePalette(
          c.warningSubtle,
          _clear,
          c.warningForeground,
        ),
        PanelBadgeVariant.info => _BadgePalette(
          c.infoSubtle,
          _clear,
          c.infoForeground,
        ),
      };

  static const Color _clear = Color(0x00000000);

  final Color fill;

  /// Transparent but for the outline variant: every badge keeps the 1px
  /// border, so an outline badge is no larger than a filled one beside it.
  final Color border;

  final Color text;
}

/// A label or count badge: the bordered box, and its content centred in it.
class _BadgeBox extends StatelessWidget {
  const _BadgeBox({
    required this.palette,
    required this.labelStyle,
    required this.padding,
    required this.radius,
    required this.child,
    this.height,
  });

  final _BadgePalette palette;
  final TextStyle labelStyle;
  final EdgeInsets padding;
  final double radius;
  final Widget child;

  /// A fixed height, which is also the least width: a count's circle.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final height = this.height;
    return Container(
      constraints: height == null
          ? null
          : BoxConstraints(minWidth: height, minHeight: height),
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.fill,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: IconTheme(
        data: IconThemeData(color: palette.text, size: _glyphSize),
        child: DefaultTextStyle(
          style: labelStyle,
          textAlign: TextAlign.center,
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}
