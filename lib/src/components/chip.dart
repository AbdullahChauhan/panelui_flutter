import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_focus_ring.dart';
import '../foundation/panel_hit_slop.dart';
import '../foundation/panel_hover_fade.dart';
import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_color_mix.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_tokens.dart';
import '../theme/panel_typography.dart';

/// How a [PanelChip] is coloured at rest.
enum PanelChipVariant {
  /// A quiet neutral fill, the resting tag. PanelUI's `default`.
  neutral,

  /// The `primary` fill, for the one chip that leads.
  primary,

  /// Just a hairline: the lightest a chip gets while still being a shape.
  outline,

  /// A tinted success fill with success text.
  success,

  /// A tinted warning fill with warning text.
  warning,

  /// A tinted info fill with info text.
  info,

  /// A tinted destructive fill with destructive text.
  destructive,
}

/// How big a [PanelChip] is.
enum PanelChipSize {
  /// 20pt tall, 11px text.
  xs,

  /// 24pt tall, 12px text.
  sm,

  /// 28pt tall, 14px text. The default.
  md,

  /// 36pt tall, 16px text.
  lg,

  /// 44pt tall, 16px text.
  xl,
}

/// A compact, interactive token: the filter in a filter bar, the tag on a
/// photo, the removable recipient in a "To:" field.
///
/// ```dart
/// const PanelChip(child: Text('Design'))
/// PanelChip(
///   selected: on,
///   onPressed: () => setState(() => on = !on),
///   child: const Text('Available'),
/// )
/// PanelChip(
///   variant: PanelChipVariant.outline,
///   onClose: () => remove('Ada'),
///   child: const Text('Ada'),
/// )
/// ```
///
/// Where a badge only shows, a chip can be pressed ([onPressed]), marked as
/// [selected], or removed ([onClose]). The ✕ is a target of its own nested
/// inside the pill, so removing a chip never also presses it; it also answers
/// Backspace and Delete while it has focus.
///
/// A chip with neither [onPressed] nor [selected] is a static tag: it does not
/// shrink under a finger or take focus, so it does not invite a tap. Icons
/// passed as [leading] are drawn in the label's colour and at its size.
class PanelChip extends StatelessWidget {
  /// Creates a chip.
  const PanelChip({
    super.key,
    required this.child,
    this.variant = PanelChipVariant.neutral,
    this.size = PanelChipSize.md,
    this.selected,
    this.enabled = true,
    this.leading,
    this.onPressed,
    this.onClose,
    this.closeLabel = 'Remove',
    this.haptics = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// The label, usually a [Text].
  final Widget child;

  /// The resting colours.
  final PanelChipVariant variant;

  /// The size.
  final PanelChipSize size;

  /// The filter "on" state, a loud accent surface that wins over [variant],
  /// so any chip can be a filter without picking a second colour. Setting it,
  /// even to false, makes the chip a toggle and announces it as one; pair it
  /// with [onPressed] to flip it.
  final bool? selected;

  /// Whether the chip and its ✕ accept presses. A disabled chip is drawn at
  /// 56% opacity.
  final bool enabled;

  /// A leading icon or avatar, before the label.
  final Widget? leading;

  /// Called when the chip is pressed.
  final VoidCallback? onPressed;

  /// Shows a trailing ✕ and calls this when it is pressed.
  final VoidCallback? onClose;

  /// What a screen reader calls the ✕.
  final String closeLabel;

  /// A selection tick of the haptic engine when the chip is pressed or
  /// removed.
  final bool haptics;

  /// The accessible name, when the label is not text.
  final String? semanticLabel;

  /// An optional focus node for the chip.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  void _press() {
    if (haptics) HapticFeedback.selectionClick();
    onPressed?.call();
  }

  void _close() {
    if (haptics) HapticFeedback.selectionClick();
    onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _chipMetrics[size]!;
    final palette = _paletteOf(
      PanelTheme.of(context).colors,
      variant,
      selected: selected ?? false,
    );
    final close = onClose == null
        ? null
        : _ChipClose(
            metrics: metrics,
            color: palette.foreground,
            label: closeLabel,
            onPressed: enabled ? _close : null,
          );
    // A name replaces the label rather than repeating it, and leaves the ✕
    // to be read as the button it is.
    final label = semanticLabel == null
        ? child
        : Semantics(label: semanticLabel, excludeSemantics: true, child: child);

    Widget pill({bool hovered = false, bool focused = false}) => _ChipPill(
      metrics: metrics,
      palette: palette,
      hovered: hovered,
      focused: focused,
      leading: leading,
      label: label,
      close: close,
    );

    return Align(
      // PanelUI's `self-start`: a chip keeps its own size in a column that
      // stretches.
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Opacity(
        opacity: enabled ? 1 : _disabledOpacity,
        child: onPressed != null || selected != null
            ? PanelPressable(
                onPressed: enabled ? _press : null,
                selected: selected,
                focusNode: focusNode,
                autofocus: autofocus,
                builder: (context, state) =>
                    pill(hovered: state.hovered, focused: state.focused),
              )
            : pill(),
      ),
    );
  }
}

/// PanelUI's `opacity-[0.56]` on a disabled chip.
const double _disabledOpacity = 0.56;

/// How long the pill takes to tint under the pointer: the web package's
/// `duration-200`.
const Duration _hoverDuration = Duration(milliseconds: 200);

class _ChipMetrics {
  const _ChipMetrics({
    required this.height,
    required this.gap,
    required this.padding,
    required this.labelStep,
    required this.fontSize,
    required this.close,
    required this.closeIcon,
  });

  final double height;
  final double gap;
  final double padding;

  /// The label's step on the type scale, or null for a bare `text-[11px]`,
  /// which keeps the font's own line height.
  final PanelTextSize? labelStep;

  /// The label's size, which a leading icon is drawn at too.
  final double fontSize;

  /// The ✕ target, a circle as tall as this.
  final double close;

  /// The ✕ glyph, scaled with the pill so it never looks stranded.
  final double closeIcon;

  TextStyle labelStyle(PanelTypography typography, Color color) {
    final step = labelStep;
    return step == null
        ? typography.sized(fontSize, weight: FontWeight.w500, color: color)
        : typography.style(step, weight: FontWeight.w500, color: color);
  }
}

const _chipMetrics = {
  PanelChipSize.xs: _ChipMetrics(
    height: 20,
    gap: 2,
    padding: 6,
    labelStep: null,
    fontSize: 11,
    close: 14,
    closeIcon: 9,
  ),
  PanelChipSize.sm: _ChipMetrics(
    height: 24,
    gap: 4,
    padding: 8,
    labelStep: PanelTextSize.xs,
    fontSize: 12,
    close: 16,
    closeIcon: 11,
  ),
  PanelChipSize.md: _ChipMetrics(
    height: 28,
    gap: 6,
    padding: 10,
    labelStep: PanelTextSize.sm,
    fontSize: 14,
    close: 20,
    closeIcon: 13,
  ),
  PanelChipSize.lg: _ChipMetrics(
    height: 36,
    gap: 8,
    padding: 14,
    labelStep: PanelTextSize.base,
    fontSize: 16,
    close: 24,
    closeIcon: 15,
  ),
  PanelChipSize.xl: _ChipMetrics(
    height: 44,
    gap: 8,
    padding: 16,
    labelStep: PanelTextSize.base,
    fontSize: 16,
    close: 28,
    closeIcon: 17,
  ),
};

/// A chip's colours: its fill at rest and under a hovering pointer, its edge,
/// and the colour of its label, icons and ✕.
typedef _ChipPalette = ({
  Color fill,
  Color hoverFill,
  Color border,
  Color foreground,
});

_ChipPalette _paletteOf(
  PanelColors c,
  PanelChipVariant variant, {
  required bool selected,
}) {
  const clear = Color(0x00000000);
  final (fill, border, foreground) = selected
      ? (c.accent, _fade(c.primary, 0.24), c.accentForeground)
      : switch (variant) {
          PanelChipVariant.neutral => (
            c.secondary,
            clear,
            c.secondaryForeground,
          ),
          PanelChipVariant.primary => (c.primary, clear, c.primaryForeground),
          PanelChipVariant.outline => (clear, c.border, c.foreground),
          PanelChipVariant.success => (
            c.successSubtle,
            clear,
            c.successForeground,
          ),
          PanelChipVariant.warning => (
            c.warningSubtle,
            clear,
            c.warningForeground,
          ),
          PanelChipVariant.info => (c.infoSubtle, clear, c.infoForeground),
          PanelChipVariant.destructive => (
            c.destructiveSubtle,
            clear,
            c.destructiveForeground,
          ),
        };
  return (
    fill: fill,
    // The web package's hover, `bg-muted/60`, laid over the resting fill. A
    // selected chip keeps its fill, as the web's pressed state outranks it.
    hoverFill: selected ? fill : Color.alphaBlend(_fade(c.muted, 0.6), fill),
    border: border,
    foreground: foreground,
  );
}

/// The pill: an optional leading icon, the label and the ✕, on the fill.
class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.metrics,
    required this.palette,
    required this.hovered,
    required this.focused,
    required this.leading,
    required this.label,
    required this.close,
  });

  final _ChipMetrics metrics;
  final _ChipPalette palette;
  final bool hovered;
  final bool focused;
  final Widget? leading;
  final Widget label;
  final Widget? close;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final radius = BorderRadius.circular(metrics.height / 2);
    final pill = PanelHoverFade(
      hovered: hovered,
      duration: _hoverDuration,
      builder: (context, hover, content) => Container(
        height: metrics.height,
        // The ✕ hugs the end edge: PanelUI trims the end padding to 4 and
        // pulls the ✕ out by the same 4.
        padding: EdgeInsetsDirectional.only(
          start: metrics.padding,
          end: close == null ? metrics.padding : 0,
        ),
        decoration: BoxDecoration(
          color: panelLerpColor(palette.fill, palette.hoverFill, hover),
          border: Border.all(color: palette.border),
          borderRadius: radius,
        ),
        child: content,
      ),
      child: IconTheme(
        data: IconThemeData(color: palette.foreground, size: metrics.fontSize),
        child: DefaultTextStyle(
          style: metrics.labelStyle(theme.typography, palette.foreground),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: metrics.gap,
            children: [
              ?leading,
              Flexible(child: label),
              ?close,
            ],
          ),
        ),
      ),
    );
    return PanelFocusRing(
      visible: focused,
      borderRadius: radius,
      style: PanelFocusRingStyle.offset,
      child: pill,
    );
  }
}

/// The ✕: a target of its own inside the pill, drawn in the chip's colour at
/// 70%, and full strength on a faint disc while a pointer is over it.
class _ChipClose extends StatelessWidget {
  const _ChipClose({
    required this.metrics,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  final _ChipMetrics metrics;
  final Color color;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(metrics.close / 2);
    void remove() => onPressed?.call();
    return PanelHitSlop(
      // A small pill leaves little room for the ✕; the slop gives the finger
      // the target the pixels do not. Outside the key bindings, whose focus
      // scope is a box of its own that would turn a press in the slop away.
      slop: const EdgeInsets.all(8),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.backspace): remove,
          const SingleActivator(LogicalKeyboardKey.delete): remove,
        },
        child: PanelPressable(
          onPressed: onPressed,
          // A plain Pressable in PanelUI: no press shrink.
          pressScale: 1,
          semanticLabel: label,
          builder: (context, state) {
            final mark = Container(
              width: metrics.close,
              height: metrics.close,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // The web package's hover, in the chip's own colour so it shows
                // on every fill.
                color: state.hovered ? _fade(color, 0.1) : null,
                shape: BoxShape.circle,
              ),
              child: Opacity(
                opacity: state.hovered ? 1 : 0.7,
                child: PanelIcon(
                  PanelIcons.x,
                  size: metrics.closeIcon,
                  color: color,
                ),
              ),
            );
            return state.focused
                ? PanelFocusRing(
                    visible: true,
                    borderRadius: radius,
                    style: PanelFocusRingStyle.tight,
                    child: mark,
                  )
                : mark;
          },
        ),
      ),
    );
  }
}

Color _fade(Color color, double factor) =>
    color.withValues(alpha: color.a * factor);
