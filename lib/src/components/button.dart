import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_theme_data.dart';
import '../theme/panel_tokens.dart';
import 'spinner.dart';

/// How a [PanelButton] looks.
enum PanelButtonVariant {
  /// Filled with the `primary` token. The main action of a screen.
  primary,

  /// A quiet tinted fill.
  secondary,

  /// A bordered button on the popover fill.
  outline,

  /// No fill until hovered.
  ghost,

  /// Filled with the `destructive` token.
  destructive,

  /// A neutral bordered surface for third-party sign-in.
  social,
}

/// How big a [PanelButton] is.
enum PanelButtonSize {
  /// 28pt, for a dense row: a toolbar or a table cell.
  xs,

  /// 36pt.
  sm,

  /// 44pt, the default.
  md,

  /// 48pt.
  lg,

  /// 56pt, for the one control a screen is built around.
  xl,

  /// A 44pt square for a lone icon.
  icon,
}

class _Metrics {
  const _Metrics({
    required this.minHeight,
    required this.minWidth,
    required this.padding,
    required this.gap,
    required this.fontSize,
    required this.iconSize,
    required this.spinner,
    this.hitSlop = 0,
  });

  final double minHeight;
  final double minWidth;
  final EdgeInsets padding;
  final double gap;
  final double fontSize;
  final double iconSize;
  final PanelSpinnerSize spinner;

  /// Extra room that takes a press, so the compact sizes still offer a
  /// finger-sized target (PanelUI's `BUTTON_HIT_SLOP`).
  final double hitSlop;
}

const Map<PanelButtonSize, _Metrics> _metrics = {
  PanelButtonSize.xs: _Metrics(
    minHeight: 28,
    minWidth: 28,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    gap: 4,
    fontSize: 12,
    iconSize: 14,
    spinner: PanelSpinnerSize.sm,
    hitSlop: 10,
  ),
  PanelButtonSize.sm: _Metrics(
    minHeight: 36,
    minWidth: 36,
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    gap: 6,
    fontSize: 14,
    iconSize: 16,
    spinner: PanelSpinnerSize.sm,
    hitSlop: 6,
  ),
  PanelButtonSize.md: _Metrics(
    minHeight: 44,
    minWidth: 44,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    gap: 8,
    fontSize: 16,
    iconSize: 18,
    spinner: PanelSpinnerSize.sm,
    hitSlop: 2,
  ),
  PanelButtonSize.lg: _Metrics(
    minHeight: 48,
    minWidth: 0,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    gap: 8,
    fontSize: 18,
    iconSize: 20,
    spinner: PanelSpinnerSize.md,
  ),
  PanelButtonSize.xl: _Metrics(
    minHeight: 56,
    minWidth: 0,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    gap: 8,
    fontSize: 18,
    iconSize: 20,
    spinner: PanelSpinnerSize.md,
  ),
  PanelButtonSize.icon: _Metrics(
    minHeight: 44,
    minWidth: 44,
    padding: EdgeInsets.zero,
    gap: 8,
    fontSize: 16,
    iconSize: 20,
    spinner: PanelSpinnerSize.sm,
    hitSlop: 2,
  ),
};

/// The colours one variant resolves to in the current theme.
class _Palette {
  const _Palette({
    required this.fill,
    required this.hoverFill,
    required this.border,
    required this.foreground,
    required this.shadow,
    required this.spinnerTrack,
  });

  final Color fill;
  final Color hoverFill;
  final Color border;
  final Color foreground;
  final bool shadow;
  final Color spinnerTrack;

  static Color _fade(Color color, double factor) =>
      color.withValues(alpha: color.a * factor);

  factory _Palette.of(PanelColors c, PanelButtonVariant variant) {
    const clear = Color(0x00000000);
    switch (variant) {
      case PanelButtonVariant.primary:
        return _Palette(
          fill: c.primary,
          hoverFill: _fade(c.primary, 0.9),
          border: c.primary,
          foreground: c.primaryForeground,
          shadow: true,
          spinnerTrack: _fade(c.primaryForeground, 0.32),
        );
      case PanelButtonVariant.secondary:
        return _Palette(
          fill: c.secondary,
          hoverFill: _fade(c.secondary, 0.8),
          border: clear,
          foreground: c.secondaryForeground,
          shadow: false,
          spinnerTrack: _fade(c.secondaryForeground, 0.24),
        );
      case PanelButtonVariant.outline:
        return _Palette(
          fill: c.popover,
          hoverFill: Color.alphaBlend(c.accent, c.popover),
          border: c.input,
          foreground: c.foreground,
          shadow: true,
          spinnerTrack: c.muted,
        );
      case PanelButtonVariant.ghost:
        return _Palette(
          fill: clear,
          hoverFill: c.accent,
          border: clear,
          foreground: c.foreground,
          shadow: false,
          spinnerTrack: c.muted,
        );
      case PanelButtonVariant.destructive:
        return _Palette(
          fill: c.destructive,
          hoverFill: _fade(c.destructive, 0.9),
          border: c.destructive,
          foreground: c.destructiveSolidForeground,
          shadow: true,
          spinnerTrack: _fade(c.destructiveSolidForeground, 0.32),
        );
      case PanelButtonVariant.social:
        return _Palette(
          fill: c.card,
          hoverFill: Color.alphaBlend(c.accent, c.card),
          border: c.input,
          foreground: c.foreground,
          shadow: true,
          spinnerTrack: c.muted,
        );
    }
  }
}

/// A button.
///
/// ```dart
/// PanelButton(onPressed: save, child: const Text('Save'))
/// PanelButton(
///   variant: PanelButtonVariant.outline,
///   leading: const PanelIcon(PanelIcons.plus),
///   onPressed: add,
///   child: const Text('New project'),
/// )
/// ```
///
/// Text and icons inside it take the colour that reads against its fill, so
/// an icon passed as [leading] follows the theme without a hardcoded colour.
/// A button with a null [onPressed] is disabled and drawn at 64% opacity;
/// so is one that is [loading], which shows a spinner in place of [leading].
class PanelButton extends StatelessWidget {
  /// Creates a button.
  const PanelButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.child,
    this.variant,
    this.size,
    this.fullWidth,
    this.loading = false,
    this.leading,
    this.trailing,
    this.spinnerColor,
    this.spinnerTrackColor,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Called when the button is tapped. Null disables the button.
  final VoidCallback? onPressed;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// The label, usually a [Text].
  final Widget? child;

  /// The look. Defaults to the enclosing [PanelButtonGroup]'s, then primary.
  final PanelButtonVariant? variant;

  /// The size. Defaults to the enclosing [PanelButtonGroup]'s, then md.
  final PanelButtonSize? size;

  /// Stretch to the width available.
  final bool? fullWidth;

  /// Shows a spinner and blocks presses while an action is in flight.
  final bool loading;

  /// Content before the label (PanelUI's `startContent`), such as an icon.
  final Widget? leading;

  /// Content after the label (PanelUI's `endContent`).
  final Widget? trailing;

  /// The colour of the loading spinner's arc. Defaults to the label colour.
  final Color? spinnerColor;

  /// The colour of the loading spinner's track.
  final Color? spinnerTrackColor;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// The accessible name, for a button whose child is not text.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final group = PanelButtonGroup.maybeScopeOf(context);
    final attached = group?.attached ?? false;
    final resolvedVariant =
        variant ?? group?.variant ?? PanelButtonVariant.primary;
    final resolvedSize = size ?? group?.size ?? PanelButtonSize.md;
    final metrics = _metrics[resolvedSize]!;
    final palette = _Palette.of(theme.colors, resolvedVariant);
    final enabled = !loading && (onPressed != null || onLongPress != null);
    final stretch = fullWidth ?? (attached && (group?.fullWidth ?? false));

    final radius = attached
        ? BorderRadius.zero
        : BorderRadius.circular(
            resolvedSize == PanelButtonSize.xs
                ? theme.radii.md
                : theme.radii.lg,
          );

    final labelStyle = theme.typography.sized(
      metrics.fontSize,
      weight: FontWeight.w500,
      color: palette.foreground,
    );

    final lead = loading
        ? PanelSpinner(
            size: metrics.spinner,
            color: spinnerColor ?? palette.foreground,
            trackColor: spinnerTrackColor ?? palette.spinnerTrack,
          )
        : leading;

    final isIcon = resolvedSize == PanelButtonSize.icon;
    final row = Row(
      mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: metrics.gap,
      children: [
        ?lead,
        if (child != null)
          Flexible(
            child: DefaultTextStyle(
              style: labelStyle,
              textAlign: TextAlign.center,
              child: child!,
            ),
          ),
        ?trailing,
      ],
    );

    final content = IconTheme(
      data: IconThemeData(color: palette.foreground, size: metrics.iconSize),
      child: DefaultTextStyle(
        style: labelStyle,
        textAlign: TextAlign.center,
        child: row,
      ),
    );

    return PanelPressable(
      onPressed: enabled ? onPressed : null,
      onLongPress: enabled ? onLongPress : null,
      pressScale: attached ? 1 : 0.97,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      focusRingRadius: attached ? null : radius,
      // Joined segments cannot borrow room from each other without two
      // actions claiming the same pixels.
      hitSlop: attached ? null : EdgeInsets.all(metrics.hitSlop),
      builder: (context, state) {
        final Color fill;
        if (attached && state.pressed) {
          // A joined segment cannot shrink without pulling away from its
          // neighbours, so a press tints it instead.
          fill = theme.colors.accent;
        } else {
          fill = state.hovered ? palette.hoverFill : palette.fill;
        }
        // Only the fill crossfades (hover, press). Size, border and shadow
        // change with the props and should land at once.
        Widget box = TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: fill),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          builder: (context, color, child) => Container(
            constraints: isIcon
                ? BoxConstraints.tight(Size.square(metrics.minHeight))
                : BoxConstraints(
                    minHeight: metrics.minHeight,
                    minWidth: metrics.minWidth,
                  ),
            padding: metrics.padding,
            decoration: BoxDecoration(
              color: color,
              borderRadius: radius,
              border: Border.all(
                color: attached ? const Color(0x00000000) : palette.border,
              ),
              boxShadow: palette.shadow && !attached ? theme.shadows.sm : null,
            ),
            child: child,
          ),
          child: Center(
            widthFactor: stretch ? null : 1,
            heightFactor: 1,
            child: content,
          ),
        );
        if (stretch) box = SizedBox(width: double.infinity, child: box);
        return Opacity(opacity: enabled ? 1 : 0.64, child: box);
      },
    );
  }
}

/// What a [PanelButtonGroup] tells the buttons inside it.
@immutable
class PanelButtonGroupScope {
  /// Creates a scope.
  const PanelButtonGroupScope({
    this.variant,
    this.size,
    this.attached = true,
    this.fullWidth = false,
  });

  /// Fills in for a button that did not choose a variant.
  final PanelButtonVariant? variant;

  /// Fills in for a button that did not choose a size.
  final PanelButtonSize? size;

  /// The buttons are joined into one shape, so each drops its own.
  final bool attached;

  /// The segments share the row equally.
  final bool fullWidth;

  @override
  bool operator ==(Object other) =>
      other is PanelButtonGroupScope &&
      other.variant == variant &&
      other.size == size &&
      other.attached == attached &&
      other.fullWidth == fullWidth;

  @override
  int get hashCode => Object.hash(variant, size, attached, fullWidth);
}

class _ButtonGroupInherited extends InheritedWidget {
  const _ButtonGroupInherited({required this.scope, required super.child});

  final PanelButtonGroupScope scope;

  @override
  bool updateShouldNotify(_ButtonGroupInherited oldWidget) =>
      scope != oldWidget.scope;
}

/// A run of buttons that reads as one control.
///
/// Attached (the default), the buttons are joined into a single bordered
/// shape with hairlines between them, and each drops its own radius, border,
/// shadow and press-shrink, which would pull a segment away from its
/// neighbours. Detached, they are simply spaced 8pt apart.
///
/// [variant] and [size] fill in for any button that did not set its own, so
/// the odd segment that should stand out still can.
class PanelButtonGroup extends StatelessWidget {
  /// Creates a group.
  const PanelButtonGroup({
    super.key,
    required this.children,
    this.orientation = Axis.horizontal,
    this.variant,
    this.size = PanelButtonSize.md,
    this.attached = true,
    this.fullWidth = false,
  });

  /// The buttons.
  final List<Widget> children;

  /// Whether the buttons run across or down.
  final Axis orientation;

  /// The default variant for the buttons.
  final PanelButtonVariant? variant;

  /// The default size for the buttons, which also sets the group's radius.
  final PanelButtonSize size;

  /// Join the buttons into one shape.
  final bool attached;

  /// Stretch to the width available and share it equally.
  final bool fullWidth;

  /// The scope of the nearest group, or null for a button standing alone.
  static PanelButtonGroupScope? maybeScopeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ButtonGroupInherited>()
      ?.scope;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final horizontal = orientation == Axis.horizontal;
    final scope = PanelButtonGroupScope(
      variant: variant,
      size: size,
      attached: attached,
      fullWidth: fullWidth,
    );

    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && attached) {
        items.add(
          horizontal
              ? Container(width: 1, color: theme.colors.border)
              : Container(height: 1, color: theme.colors.border),
        );
      }
      items.add(fullWidth ? Expanded(child: children[i]) : children[i]);
    }

    final Widget run = horizontal
        ? Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: attached ? 0 : 8,
            children: items,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: attached ? 0 : 8,
            children: items,
          );

    Widget group = horizontal
        ? IntrinsicHeight(child: run)
        : IntrinsicWidth(child: run);

    if (attached) {
      group = Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colors.popover,
          border: Border.all(color: theme.colors.input),
          borderRadius: BorderRadius.circular(_groupRadius(theme)),
          boxShadow: theme.shadows.sm,
        ),
        child: group,
      );
    }

    return _ButtonGroupInherited(scope: scope, child: group);
  }

  double _groupRadius(PanelThemeData theme) {
    switch (size) {
      case PanelButtonSize.xs:
        return theme.radii.md;
      case PanelButtonSize.sm:
        return theme.radii.lg;
      case PanelButtonSize.md:
      case PanelButtonSize.lg:
      case PanelButtonSize.icon:
        return theme.radii.xl;
      case PanelButtonSize.xl:
        return theme.radii.xxl;
    }
  }
}
