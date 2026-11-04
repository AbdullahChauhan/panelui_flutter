import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_theme_data.dart';
import '../theme/panel_typography.dart';

/// How big a [PanelCheckbox] is.
enum PanelCheckboxSize {
  /// A 14pt box.
  xs,

  /// A 16pt box.
  sm,

  /// A 20pt box, the default.
  md,

  /// A 24pt box.
  lg,

  /// A 28pt box.
  xl,
}

/// Whether the checkbox or the whole surface is the target.
enum PanelCheckboxVariant {
  /// A box with an optional label beside it.
  plain,

  /// A bordered card that is pressed as a whole, with the box at its end.
  /// For pickable options where the box confirms rather than invites.
  card,
}

class _CheckboxMetrics {
  const _CheckboxMetrics(
    this.box,
    this.glyph,
    this.gap,
    this.label,
    this.description,
  );

  final double box;
  final double glyph;
  final double gap;
  final double label;
  final PanelTextSize description;
}

const _checkboxMetrics = {
  PanelCheckboxSize.xs: _CheckboxMetrics(14, 8, 8, 12, PanelTextSize.xs),
  PanelCheckboxSize.sm: _CheckboxMetrics(16, 10, 8, 13, PanelTextSize.xs),
  PanelCheckboxSize.md: _CheckboxMetrics(20, 12, 10, 14, PanelTextSize.sm),
  PanelCheckboxSize.lg: _CheckboxMetrics(24, 14, 12, 16, PanelTextSize.sm),
  PanelCheckboxSize.xl: _CheckboxMetrics(28, 16, 12, 18, PanelTextSize.base),
};

/// A checkbox, with an optional label and description beside it.
///
/// The fill springs in from 60% scale when checked and fades out when not.
/// [indeterminate] draws a dash for a box governing a partly checked group;
/// pressing it reports `true`, turning the whole group on.
///
/// ```dart
/// PanelCheckbox(
///   value: accepted,
///   onChanged: (v) => setState(() => accepted = v),
///   label: 'Accept terms and conditions',
/// )
/// ```
class PanelCheckbox extends StatefulWidget {
  /// Creates a checkbox.
  const PanelCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.indeterminate = false,
    this.label,
    this.description,
    this.size = PanelCheckboxSize.md,
    this.variant = PanelCheckboxVariant.plain,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether the box is checked.
  final bool value;

  /// Called with the new value. Null disables the checkbox.
  final ValueChanged<bool>? onChanged;

  /// Draws a dash instead of a tick, for a partly checked group.
  final bool indeterminate;

  /// Text beside the box; pressing it toggles too.
  final String? label;

  /// A secondary line under the label.
  final String? description;

  /// The size.
  final PanelCheckboxSize size;

  /// Plain or card.
  final PanelCheckboxVariant variant;

  /// The accessible name, when [label] is not enough.
  final String? semanticLabel;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  @override
  State<PanelCheckbox> createState() => _PanelCheckboxState();
}

class _PanelCheckboxState extends State<PanelCheckbox>
    with SingleTickerProviderStateMixin {
  bool get _on => widget.value || widget.indeterminate;

  late final AnimationController _progress = AnimationController.unbounded(
    vsync: this,
    value: _on ? 1 : 0,
  );

  @override
  void didUpdateWidget(PanelCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasOn = oldWidget.value || oldWidget.indeterminate;
    if (wasOn == _on) return;
    if (panelReduceMotion(context)) {
      _progress.value = _on ? 1 : 0;
    } else if (_on) {
      _progress.springTo(1, PanelSprings.check);
    } else {
      _progress.animateTo(
        0,
        duration: PanelDurations.uncheck,
        curve: panelEase,
      );
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _toggle() =>
      widget.onChanged?.call(widget.indeterminate ? true : !widget.value);

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final m = _checkboxMetrics[widget.size]!;
    final enabled = widget.onChanged != null;
    final card = widget.variant == PanelCheckboxVariant.card;
    final boxRadius = _boxRadius(theme);

    final box = Container(
      width: m.box,
      height: m.box,
      decoration: BoxDecoration(
        color: c.background,
        border: Border.all(color: c.input),
        borderRadius: BorderRadius.circular(boxRadius),
      ),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final t = _progress.value;
          if (t <= 0) return const SizedBox.shrink();
          return Transform.scale(
            scale: 0.6 + t * 0.4,
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: OverflowBox(
                maxWidth: m.box,
                maxHeight: m.box,
                child: Container(
                  width: m.box,
                  height: m.box,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(boxRadius),
                  ),
                  child: PanelIcon(
                    widget.indeterminate ? PanelIcons.minus : PanelIcons.check,
                    size: m.glyph,
                    color: c.primaryForeground,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    final hasText = widget.label != null || widget.description != null;
    final text = hasText
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: theme.typography
                      .sized(
                        card ? 16 : m.label,
                        weight: card ? FontWeight.w500 : FontWeight.w400,
                        color: c.foreground,
                      )
                      .copyWith(height: card ? 1.5 : 20 / m.label),
                ),
              if (widget.description != null)
                Text(
                  widget.description!,
                  style: theme.typography.style(
                    m.description,
                    color: c.mutedForeground,
                  ),
                ),
            ],
          )
        : null;

    final twoLines = widget.description != null;
    Widget row = Row(
      mainAxisSize: card ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: twoLines || card
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      spacing: card ? 12 : m.gap,
      children: card
          ? [if (text != null) Expanded(child: text), box]
          : [
              Padding(
                padding: EdgeInsets.only(
                  top: twoLines ? (20 - m.box).clamp(0, 20) / 2 : 0,
                ),
                child: box,
              ),
              if (text != null) Flexible(child: text),
            ],
    );

    if (card) {
      row = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _on ? Color.alphaBlend(c.accent, c.card) : c.card,
          border: Border.all(color: _on ? c.primary : c.border),
          borderRadius: BorderRadius.circular(theme.radii.xl),
        ),
        child: row,
      );
    } else {
      row = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: row,
        ),
      );
    }

    return PanelPressable(
      onPressed: enabled ? _toggle : null,
      pressScale: card ? 0.98 : 1,
      isButton: false,
      checked: widget.indeterminate ? null : widget.value,
      mixed: widget.indeterminate ? true : null,
      semanticLabel: widget.semanticLabel ?? widget.label,
      semanticHint: widget.description,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      focusRingRadius: BorderRadius.circular(card ? theme.radii.xl : boxRadius),
      child: Opacity(opacity: enabled ? 1 : 0.5, child: row),
    );
  }

  double _boxRadius(PanelThemeData theme) {
    switch (widget.size) {
      case PanelCheckboxSize.xs:
      case PanelCheckboxSize.sm:
        return theme.radii.sm;
      case PanelCheckboxSize.md:
      case PanelCheckboxSize.lg:
        return theme.radii.md;
      case PanelCheckboxSize.xl:
        return theme.radii.lg;
    }
  }
}
