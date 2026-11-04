import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../foundation/panel_hit_slop.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_tokens.dart';

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

class _ChipMetrics {
  const _ChipMetrics({
    required this.height,
    required this.gap,
    required this.padding,
    required this.fontSize,
    required this.close,
    required this.closeIcon,
  });

  final double height;
  final double gap;
  final double padding;
  final double fontSize;

  /// The ✕ target, a circle as tall as this.
  final double close;

  /// The ✕ glyph, scaled with the pill so it never looks stranded.
  final double closeIcon;
}

const _chipMetrics = {
  PanelChipSize.xs: _ChipMetrics(
    height: 20,
    gap: 2,
    padding: 6,
    fontSize: 11,
    close: 14,
    closeIcon: 9,
  ),
  PanelChipSize.sm: _ChipMetrics(
    height: 24,
    gap: 4,
    padding: 8,
    fontSize: 12,
    close: 16,
    closeIcon: 11,
  ),
  PanelChipSize.md: _ChipMetrics(
    height: 28,
    gap: 6,
    padding: 10,
    fontSize: 14,
    close: 20,
    closeIcon: 13,
  ),
  PanelChipSize.lg: _ChipMetrics(
    height: 36,
    gap: 8,
    padding: 14,
    fontSize: 16,
    close: 24,
    closeIcon: 15,
  ),
  PanelChipSize.xl: _ChipMetrics(
    height: 44,
    gap: 8,
    padding: 16,
    fontSize: 16,
    close: 28,
    closeIcon: 17,
  ),
};

Color _fade(Color color, double factor) =>
    color.withValues(alpha: color.a * factor);

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
/// passed as [leading] take the colour of the label.
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

  (Color fill, Color border, Color foreground) _palette(PanelColors c) {
    const clear = Color(0x00000000);
    if (selected ?? false) {
      return (c.accent, c.primary.withValues(alpha: 0.24), c.accentForeground);
    }
    switch (variant) {
      case PanelChipVariant.neutral:
        return (c.secondary, clear, c.secondaryForeground);
      case PanelChipVariant.primary:
        return (c.primary, clear, c.primaryForeground);
      case PanelChipVariant.outline:
        return (clear, c.border, c.foreground);
      case PanelChipVariant.success:
        return (c.successSubtle, clear, c.successForeground);
      case PanelChipVariant.warning:
        return (c.warningSubtle, clear, c.warningForeground);
      case PanelChipVariant.info:
        return (c.infoSubtle, clear, c.infoForeground);
      case PanelChipVariant.destructive:
        return (c.destructiveSubtle, clear, c.destructiveForeground);
    }
  }

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
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final m = _chipMetrics[size]!;
    final (fill, border, foreground) = _palette(c);
    final isToggle = selected != null;
    final pressable = onPressed != null || isToggle;
    final closable = onClose != null;
    final radius = BorderRadius.circular(m.height / 2);
    final labelStyle = theme.typography.sized(
      m.fontSize,
      weight: FontWeight.w500,
      color: foreground,
    );

    // The web package's hover: a primary fill lightens as a button's does,
    // the neutral one thins, and the rest take the accent tint over them.
    final Color hoverFill;
    if (selected ?? false) {
      hoverFill = Color.alphaBlend(c.accent, fill);
    } else if (variant == PanelChipVariant.primary) {
      hoverFill = _fade(fill, 0.9);
    } else if (variant == PanelChipVariant.neutral) {
      hoverFill = _fade(fill, 0.8);
    } else {
      hoverFill = Color.alphaBlend(c.accent, fill);
    }

    Widget? close;
    if (closable) {
      close = PanelHitSlop(
        // A small pill leaves little room for the ✕; the slop gives the
        // finger the target the pixels do not.
        slop: const EdgeInsets.all(8),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.backspace): () {
              if (enabled) _close();
            },
            const SingleActivator(LogicalKeyboardKey.delete): () {
              if (enabled) _close();
            },
          },
          child: PanelPressable(
            onPressed: enabled ? _close : null,
            pressScale: 1,
            semanticLabel: closeLabel,
            focusRingRadius: BorderRadius.circular(m.close / 2),
            // The web package's hover: a faint disc behind the ✕, which
            // comes up to full strength.
            builder: (context, state) => Container(
              width: m.close,
              height: m.close,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: state.hovered
                    ? foreground.withValues(alpha: foreground.a * 0.1)
                    : null,
                shape: BoxShape.circle,
              ),
              child: Opacity(
                opacity: state.hovered ? 1 : 0.7,
                child: PanelIcon(
                  PanelIcons.x,
                  size: m.closeIcon,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget pill(bool hovered) => Container(
      height: m.height,
      // The ✕ hugs the end edge: PanelUI trims the end padding to 4 and pulls
      // the ✕ out by the same 4.
      padding: EdgeInsetsDirectional.only(
        start: m.padding,
        end: closable ? 0 : m.padding,
      ),
      decoration: BoxDecoration(
        color: hovered ? hoverFill : fill,
        border: Border.all(color: border),
        borderRadius: radius,
      ),
      child: IconTheme(
        data: IconThemeData(color: foreground, size: m.fontSize),
        child: DefaultTextStyle(
          style: labelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: m.gap,
            children: [
              ?leading,
              // An explicit name replaces the label rather than repeating it.
              Flexible(
                child: semanticLabel == null
                    ? child
                    : ExcludeSemantics(child: child),
              ),
              ?close,
            ],
          ),
        ),
      ),
    );

    Widget chip;
    if (pressable) {
      chip = PanelPressable(
        onPressed: enabled ? _press : null,
        selected: isToggle ? selected : null,
        semanticLabel: semanticLabel,
        focusNode: focusNode,
        autofocus: autofocus,
        focusRingRadius: radius,
        builder: (context, state) => pill(state.hovered),
      );
    } else {
      chip = pill(false);
      if (semanticLabel != null) {
        chip = Semantics(label: semanticLabel, child: chip);
      }
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Opacity(opacity: enabled ? 1 : 0.56, child: chip),
    );
  }
}
