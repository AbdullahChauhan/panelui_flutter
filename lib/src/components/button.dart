import 'dart:math' as math;

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

  /// Filled with the `destructive` token, for the action that cannot be
  /// taken back.
  destructive,

  /// A neutral bordered surface for third-party sign-in, sized for a
  /// full-width stack.
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
/// An icon is drawn at 16pt unless it is given a size (20pt in the
/// [PanelButtonSize.icon] square).
///
/// A button with a null [onPressed] is disabled and drawn at 64% opacity; so
/// is one that is [loading], which shows a spinner in place of [leading].
///
/// On a pointer device the fill of an outline, ghost or social button turns
/// to the `accent` token under the pointer, with its content in
/// `accentForeground`, and a filled one lightens a little; keyboard focus
/// draws a ring around it.
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
    this.spinnerSize,
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

  /// Stretch to the width available. Defaults to true inside a full-width
  /// attached [PanelButtonGroup].
  final bool? fullWidth;

  /// Shows a spinner and blocks presses while an action is in flight.
  final bool loading;

  /// Content before the label (PanelUI's `startContent`), such as an icon.
  final Widget? leading;

  /// Content after the label (PanelUI's `endContent`).
  final Widget? trailing;

  /// The colour of the loading spinner's arc. Defaults to the label colour.
  final Color? spinnerColor;

  /// The colour of the loading spinner's track. Defaults to a tint of the
  /// label colour on a filled button and the `muted` token on the others. Set
  /// it along with [spinnerColor]: beside an arc in another colour, the
  /// default track reads as a second spinner.
  final Color? spinnerTrackColor;

  /// The loading spinner's size. Defaults to one picked from the button's.
  final PanelSpinnerSize? spinnerSize;

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
    final resolvedSize = size ?? group?.size ?? PanelButtonSize.md;
    final metrics = _ButtonMetrics.of(resolvedSize);
    final palette = _ButtonPalette.of(
      theme.colors,
      variant ?? group?.variant ?? PanelButtonVariant.primary,
    );
    final enabled = !loading && (onPressed != null || onLongPress != null);
    final stretch = fullWidth ?? (attached && (group?.fullWidth ?? false));
    // A joined segment gives its corners to the group, which draws the shape
    // once. At 28pt the default radius starts to read as a pill, so xs steps
    // down one.
    final radius = attached
        ? BorderRadius.zero
        : BorderRadius.circular(
            resolvedSize == PanelButtonSize.xs
                ? theme.radii.md
                : theme.radii.lg,
          );

    final lead = loading
        ? PanelSpinner(
            size: spinnerSize ?? metrics.spinner,
            color: spinnerColor ?? palette.foreground,
            trackColor: spinnerTrackColor ?? palette.spinnerTrack,
          )
        : leading;
    final content = Row(
      mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: metrics.gap,
      children: [
        ?lead,
        // A constrained label wraps, and every line of it is centred.
        if (child != null) Flexible(child: child!),
        ?trailing,
      ],
    );

    return PanelPressable(
      onPressed: enabled ? onPressed : null,
      onLongPress: enabled ? onLongPress : null,
      // A joined segment cannot shrink without pulling away from its
      // neighbours, so it takes PanelUI's press tint below instead of the
      // 0.97 press scale.
      pressScale: attached ? 1 : 0.97,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      // The group clips a segment's outside, so a joined segment draws its
      // ring inside itself instead (see _ButtonSurface.innerRing).
      focusRingRadius: attached ? null : radius,
      focusRingColor: palette.focusRing,
      // Joined segments cannot borrow room from each other without two
      // actions claiming the same pixels.
      hitSlop: attached ? null : EdgeInsets.all(metrics.hitSlop),
      builder: (context, state) => Opacity(
        opacity: enabled ? 1 : _disabledOpacity,
        child: _ButtonSurface(
          ink: palette.ink(hovered: state.hovered),
          // PanelUI's `active:bg-accent`, which lands at once.
          pressedFill: attached && state.pressed ? theme.colors.accent : null,
          innerRing: attached && state.focused ? palette.focusRing : null,
          border: attached ? _clear : palette.border,
          shadow: palette.shadow && !attached ? theme.shadows.sm : null,
          radius: radius,
          constraints: resolvedSize == PanelButtonSize.icon
              ? BoxConstraints.tight(Size.square(metrics.minHeight))
              : BoxConstraints(
                  minHeight: metrics.minHeight,
                  minWidth: metrics.minWidth,
                ),
          padding: metrics.padding,
          labelStyle: theme.typography.sized(
            metrics.fontSize,
            weight: FontWeight.w500,
          ),
          iconSize: resolvedSize == PanelButtonSize.icon
              ? _iconSquareGlyphSize
              : _glyphSize,
          stretch: stretch,
          child: content,
        ),
      ),
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

/// A run of buttons that reads as one control.
///
/// Attached (the default), the buttons are joined into a single bordered
/// shape with hairlines between them. Each drops its own radius, border,
/// shadow and press-shrink, which would pull a segment away from its
/// neighbours, and tints while pressed instead. Detached, they are simply
/// spaced 8pt apart.
///
/// [variant] and [size] fill in for any button that did not set its own, so
/// the odd segment that should stand out (the selected one, the destructive
/// one) still can.
///
/// The buttons stay buttons: a loading or disabled segment, or one that opens
/// a popover, works inside a group as it does alone. For a control that owns
/// which segment is on, use `PanelToggleButtonGroup`; for switching panels of
/// content, `PanelTabs`.
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

  /// Whether the buttons run across or down. Down is the toolbar beside a
  /// canvas.
  final Axis orientation;

  /// The default variant for the buttons.
  final PanelButtonVariant? variant;

  /// The default size for the buttons, which also sets the group's radius.
  final PanelButtonSize size;

  /// Join the buttons into one shape. Off, it is a plain row of separate
  /// buttons sharing a variant and a size: a toolbar rather than a segmented
  /// control.
  final bool attached;

  /// Span the width available. Across, the segments share it equally rather
  /// than by content, so the divisions do not move when the labels change.
  final bool fullWidth;

  /// The scope of the nearest group, or null for a button standing alone.
  static PanelButtonGroupScope? maybeScopeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ButtonGroupInherited>()
      ?.scope;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final horizontal = orientation == Axis.horizontal;
    final shareRow = fullWidth && horizontal;
    final divider = horizontal
        ? Container(width: _hairline, color: theme.colors.border)
        : Container(height: _hairline, color: theme.colors.border);

    final run = Flex(
      direction: orientation,
      mainAxisSize: shareRow ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: attached ? 0 : _detachedGap,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 && attached) divider,
          if (shareRow) Expanded(child: children[i]) else children[i],
        ],
      ],
    );

    // Every segment takes the cross size of the largest (PanelUI's
    // `items-stretch`) and the hairlines run the full length, so the run is
    // measured before it is laid out. A full-width column already has its
    // width from its parent.
    Widget group = horizontal
        ? IntrinsicHeight(child: run)
        : fullWidth
        ? run
        : IntrinsicWidth(child: run);

    if (attached) {
      final radius = _radius(theme);
      group = Container(
        decoration: BoxDecoration(
          color: theme.colors.popover,
          border: Border.all(color: theme.colors.input),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: theme.shadows.sm,
        ),
        // Clipped inside the border, as PanelUI's `overflow-hidden` is, so a
        // filled end segment rounds off without painting over the border.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(math.max(0, radius - _hairline)),
          child: group,
        ),
      );
    }

    return _ButtonGroupInherited(
      scope: PanelButtonGroupScope(
        variant: variant,
        size: size,
        attached: attached,
        fullWidth: fullWidth,
      ),
      child: group,
    );
  }

  /// Matched to the height the buttons will be: a radius that suits a 36pt
  /// run reads as a rectangle around a 48pt one.
  double _radius(PanelThemeData theme) => switch (size) {
    PanelButtonSize.xs => theme.radii.md,
    PanelButtonSize.sm => theme.radii.lg,
    PanelButtonSize.md ||
    PanelButtonSize.lg ||
    PanelButtonSize.icon => theme.radii.xl,
    PanelButtonSize.xl => theme.radii.xxl,
  };
}

const Color _clear = Color(0x00000000);

/// PanelUI's `opacity-[0.64]` on a disabled or loading button.
const double _disabledOpacity = 0.64;

/// The size an icon in a button is drawn at unless it is given one: PanelUI's
/// glyphs default to 16, which is also the web button's
/// `[&_svg]:size-4`.
const double _glyphSize = 16;

/// The icon size in the 44pt icon square: the web button's 44pt `icon-lg`
/// draws its glyph at `size-5`.
const double _iconSquareGlyphSize = 20;

/// How long a hover takes to cross to its colours: the web button's
/// `transition-[background-color,color,…] duration-150`.
const Duration _hoverDuration = Duration(milliseconds: 150);

/// Tailwind's default transition easing, `cubic-bezier(0.4, 0, 0.2, 1)`.
const Curve _hoverCurve = Curves.fastOutSlowIn;

/// The web button's `focus-visible:ring-[3px]`, which PanelPressable also
/// draws outside a standalone button.
const double _focusRingWidth = 3;

/// The width of the group's border (`Border.all`'s default) and of the
/// dividers between its segments.
const double _hairline = 1;

/// PanelUI's `gap-2` between detached buttons.
const double _detachedGap = 8;

/// One size of a [PanelButton], from PanelUI's `size` variants.
class _ButtonMetrics {
  const _ButtonMetrics({
    required this.minHeight,
    required this.minWidth,
    required this.padding,
    required this.gap,
    required this.fontSize,
    required this.spinner,
    this.hitSlop = 0,
  });

  static _ButtonMetrics of(PanelButtonSize size) => switch (size) {
    PanelButtonSize.xs => const _ButtonMetrics(
      minHeight: 28,
      minWidth: 28,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      gap: 4,
      fontSize: 12,
      spinner: PanelSpinnerSize.sm,
      hitSlop: 10,
    ),
    PanelButtonSize.sm => const _ButtonMetrics(
      minHeight: 36,
      minWidth: 36,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      gap: 6,
      fontSize: 14,
      spinner: PanelSpinnerSize.sm,
      hitSlop: 6,
    ),
    PanelButtonSize.md => const _ButtonMetrics(
      minHeight: 44,
      minWidth: 44,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      gap: 8,
      fontSize: 16,
      spinner: PanelSpinnerSize.sm,
      hitSlop: 2,
    ),
    PanelButtonSize.lg => const _ButtonMetrics(
      minHeight: 48,
      minWidth: 0,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      gap: 8,
      fontSize: 18,
      spinner: PanelSpinnerSize.md,
    ),
    PanelButtonSize.xl => const _ButtonMetrics(
      minHeight: 56,
      minWidth: 0,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      gap: 8,
      fontSize: 18,
      spinner: PanelSpinnerSize.md,
    ),
    PanelButtonSize.icon => const _ButtonMetrics(
      minHeight: 44,
      minWidth: 44,
      padding: EdgeInsets.zero,
      gap: 8,
      fontSize: 16,
      spinner: PanelSpinnerSize.sm,
      hitSlop: 2,
    ),
  };

  /// The least height. A label scaled up by the platform grows the box.
  final double minHeight;

  /// The least width, so a one-character label still makes a square.
  final double minWidth;

  final EdgeInsets padding;

  /// The space between the leading content, the label and the trailing
  /// content.
  final double gap;

  /// The label's size, with the font's own line height (`text-[16px]`), so
  /// the padding and the glyphs make up the box.
  final double fontSize;

  /// The spinner shown while loading.
  final PanelSpinnerSize spinner;

  /// Room past each edge that also takes a press, so even the compact sizes
  /// reach a 48pt target (PanelUI's `BUTTON_HIT_SLOP`).
  final double hitSlop;
}

/// The two colours a button crossfades on hover: its fill, and the colour of
/// its label and icons.
typedef _ButtonInk = ({Color fill, Color content});

class _ButtonInkTween extends Tween<_ButtonInk> {
  _ButtonInkTween({super.end});

  @override
  _ButtonInk lerp(double t) => (
    fill: Color.lerp(begin!.fill, end!.fill, t)!,
    content: Color.lerp(begin!.content, end!.content, t)!,
  );
}

/// The colours one variant resolves to in the current theme.
class _ButtonPalette {
  const _ButtonPalette({
    required this.fill,
    required this.hoverFill,
    required this.border,
    required this.foreground,
    required this.hoverForeground,
    required this.shadow,
    required this.spinnerTrack,
    required this.focusRing,
  });

  /// The resting colours come from PanelUI's `tv()` table, the hover ones
  /// from its web button (`hover:bg-primary/90`, `hover:bg-accent
  /// hover:text-accent-foreground`). The social variant has no web
  /// counterpart and hovers as the outline one does.
  factory _ButtonPalette.of(PanelColors c, PanelButtonVariant variant) {
    final ring = c.ring.withValues(alpha: 0.4);
    switch (variant) {
      case PanelButtonVariant.primary:
        return _ButtonPalette(
          fill: c.primary,
          hoverFill: _fade(c.primary, 0.9),
          border: c.primary,
          foreground: c.primaryForeground,
          hoverForeground: c.primaryForeground,
          shadow: true,
          spinnerTrack: _fade(c.primaryForeground, 0.32),
          focusRing: ring,
        );
      case PanelButtonVariant.secondary:
        return _ButtonPalette(
          fill: c.secondary,
          hoverFill: _fade(c.secondary, 0.8),
          border: _clear,
          foreground: c.secondaryForeground,
          hoverForeground: c.secondaryForeground,
          shadow: false,
          spinnerTrack: _fade(c.secondaryForeground, 0.24),
          focusRing: ring,
        );
      case PanelButtonVariant.outline:
        return _ButtonPalette(
          fill: c.popover,
          hoverFill: c.accent,
          border: c.input,
          foreground: c.foreground,
          hoverForeground: c.accentForeground,
          shadow: true,
          spinnerTrack: c.muted,
          focusRing: ring,
        );
      case PanelButtonVariant.ghost:
        return _ButtonPalette(
          fill: _clear,
          hoverFill: c.accent,
          border: _clear,
          foreground: c.foreground,
          hoverForeground: c.accentForeground,
          shadow: false,
          spinnerTrack: c.muted,
          focusRing: ring,
        );
      case PanelButtonVariant.destructive:
        return _ButtonPalette(
          fill: c.destructive,
          hoverFill: _fade(c.destructive, 0.9),
          border: c.destructive,
          foreground: c.destructiveSolidForeground,
          hoverForeground: c.destructiveSolidForeground,
          shadow: true,
          spinnerTrack: _fade(c.destructiveSolidForeground, 0.32),
          focusRing: c.destructive.withValues(alpha: 0.4),
        );
      case PanelButtonVariant.social:
        return _ButtonPalette(
          fill: c.card,
          hoverFill: c.accent,
          border: c.input,
          foreground: c.foreground,
          hoverForeground: c.accentForeground,
          shadow: true,
          spinnerTrack: c.muted,
          focusRing: ring,
        );
    }
  }

  final Color fill;
  final Color hoverFill;
  final Color border;
  final Color foreground;
  final Color hoverForeground;

  /// Whether it casts `shadow-sm`.
  final bool shadow;

  /// The faint ring under the loading spinner's arc.
  final Color spinnerTrack;

  /// The keyboard focus ring: `ring-ring/40`, or `ring-destructive/40`.
  final Color focusRing;

  _ButtonInk ink({required bool hovered}) => hovered
      ? (fill: hoverFill, content: hoverForeground)
      : (fill: fill, content: foreground);

  /// Tailwind's `/90`: the colour at a share of its own alpha, so a token
  /// that is already translucent stays proportionally so.
  static Color _fade(Color color, double factor) =>
      color.withValues(alpha: color.a * factor);
}

/// The drawn button: its box, fill, border and shadow, and the colour its
/// content takes, crossing to the hover colours over 150ms.
class _ButtonSurface extends StatelessWidget {
  const _ButtonSurface({
    required this.ink,
    required this.pressedFill,
    required this.innerRing,
    required this.border,
    required this.shadow,
    required this.radius,
    required this.constraints,
    required this.padding,
    required this.labelStyle,
    required this.iconSize,
    required this.stretch,
    required this.child,
  });

  final _ButtonInk ink;

  /// Replaces the fill without a transition, for a joined segment held down.
  final Color? pressedFill;

  /// A focus ring drawn inside the box, for a joined segment the group clips.
  final Color? innerRing;

  final Color border;
  final List<BoxShadow>? shadow;
  final BorderRadius radius;
  final BoxConstraints constraints;
  final EdgeInsets padding;

  /// The label style, without its colour, which comes from [ink].
  final TextStyle labelStyle;

  final double iconSize;
  final bool stretch;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Widget surface = TweenAnimationBuilder<_ButtonInk>(
      tween: _ButtonInkTween(end: ink),
      duration: _hoverDuration,
      curve: _hoverCurve,
      child: Center(
        widthFactor: stretch ? null : 1,
        heightFactor: 1,
        child: child,
      ),
      builder: (context, ink, child) => Container(
        constraints: constraints,
        padding: padding,
        decoration: BoxDecoration(
          color: pressedFill ?? ink.fill,
          borderRadius: radius,
          border: Border.all(color: border),
          boxShadow: shadow,
        ),
        foregroundDecoration: innerRing == null
            ? null
            : BoxDecoration(
                border: Border.all(color: innerRing!, width: _focusRingWidth),
              ),
        child: IconTheme(
          data: IconThemeData(color: ink.content, size: iconSize),
          child: DefaultTextStyle(
            style: labelStyle.copyWith(color: ink.content),
            textAlign: TextAlign.center,
            child: child!,
          ),
        ),
      ),
    );
    if (!stretch) return surface;
    return SizedBox(width: double.infinity, child: surface);
  }
}

class _ButtonGroupInherited extends InheritedWidget {
  const _ButtonGroupInherited({required this.scope, required super.child});

  final PanelButtonGroupScope scope;

  @override
  bool updateShouldNotify(_ButtonGroupInherited oldWidget) =>
      scope != oldWidget.scope;
}
