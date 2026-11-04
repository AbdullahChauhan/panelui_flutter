import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_tokens.dart';

/// How a [PanelBadge] is coloured.
enum PanelBadgeVariant {
  /// Filled with the `primary` token.
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
  /// A rounded rectangle around a label.
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
class PanelBadge extends StatelessWidget {
  /// A badge around [child].
  const PanelBadge({
    super.key,
    this.child,
    this.variant = PanelBadgeVariant.primary,
    this.size = PanelBadgeSize.md,
    this.shape = PanelBadgeShape.label,
  }) : count = null;

  /// A circular count, shown as "99+" past 99.
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

  static const _fontSize = {
    PanelBadgeSize.xs: 10.0,
    PanelBadgeSize.sm: 11.0,
    PanelBadgeSize.md: 12.0,
    PanelBadgeSize.lg: 14.0,
    PanelBadgeSize.xl: 16.0,
  };

  static const _padding = {
    PanelBadgeSize.xs: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    PanelBadgeSize.sm: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    PanelBadgeSize.md: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    PanelBadgeSize.lg: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    PanelBadgeSize.xl: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  };

  static const _dot = {
    PanelBadgeSize.xs: 4.0,
    PanelBadgeSize.sm: 6.0,
    PanelBadgeSize.md: 8.0,
    PanelBadgeSize.lg: 10.0,
    PanelBadgeSize.xl: 12.0,
  };

  // Height and horizontal padding of the count circle.
  static const _count = {
    PanelBadgeSize.xs: (14.0, 4.0),
    PanelBadgeSize.sm: (16.0, 4.0),
    PanelBadgeSize.md: (20.0, 6.0),
    PanelBadgeSize.lg: (24.0, 8.0),
    PanelBadgeSize.xl: (28.0, 8.0),
  };

  (Color fill, Color border, Color text) _palette(PanelColors c) {
    const clear = Color(0x00000000);
    switch (variant) {
      case PanelBadgeVariant.primary:
        return (c.primary, clear, c.primaryForeground);
      case PanelBadgeVariant.secondary:
        return (c.secondary, clear, c.secondaryForeground);
      case PanelBadgeVariant.outline:
        return (clear, c.border, c.foreground);
      case PanelBadgeVariant.destructive:
        return (c.destructive, clear, c.destructiveSolidForeground);
      case PanelBadgeVariant.success:
        return (c.successSubtle, clear, c.successForeground);
      case PanelBadgeVariant.warning:
        return (c.warningSubtle, clear, c.warningForeground);
      case PanelBadgeVariant.info:
        return (c.infoSubtle, clear, c.infoForeground);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final (fill, border, text) = _palette(theme.colors);

    if (shape == PanelBadgeShape.dot) {
      // A status dot takes the solid status colour. The tinted fill a status
      // label sits on is 8-16% opaque, which vanishes at 8px across.
      final c = theme.colors;
      final dotColor = switch (variant) {
        PanelBadgeVariant.success => c.success,
        PanelBadgeVariant.warning => c.warning,
        PanelBadgeVariant.info => c.info,
        PanelBadgeVariant.outline => c.mutedForeground,
        _ => fill,
      };
      final d = _dot[size]!;
      return ExcludeSemantics(
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
      );
    }

    final style = theme.typography.sized(
      _fontSize[size]!,
      weight: FontWeight.w500,
      color: text,
    );
    final value = count;
    final Widget label = value != null
        ? Text('${value > 99 ? 99 : value}${value > 99 ? '+' : ''}')
        : child ?? const SizedBox.shrink();

    final isCount = shape == PanelBadgeShape.count;
    final (countHeight, countPadding) = _count[size]!;
    final badge = Container(
      constraints: isCount
          ? BoxConstraints(minWidth: countHeight, minHeight: countHeight)
          : null,
      height: isCount ? countHeight : null,
      padding: isCount
          ? EdgeInsets.symmetric(horizontal: countPadding)
          : _padding[size],
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(
          isCount ? countHeight / 2 : theme.radii.sm,
        ),
      ),
      child: IconTheme(
        data: IconThemeData(color: text, size: _fontSize[size]! + 2),
        child: DefaultTextStyle(
          style: style,
          textAlign: TextAlign.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [label],
          ),
        ),
      ),
    );
    if (value == null) return badge;
    return Semantics(
      label: '$value unread',
      excludeSemantics: true,
      child: badge,
    );
  }
}
