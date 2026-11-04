import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_tokens.dart';
import '../theme/panel_typography.dart';

/// How big a [PanelCheckbox] is.
///
/// The box, its tick and the text beside it change together. The row does
/// not: it stays at least 48pt tall at every size, because that is the touch
/// target, and a smaller box is no reason for a smaller one.
enum PanelCheckboxSize {
  /// A 14pt box with 12px text.
  xs,

  /// A 16pt box with 13px text.
  sm,

  /// A 20pt box with 14px text, the default.
  md,

  /// A 24pt box with 16px text.
  lg,

  /// A 28pt box with 18px text.
  xl,
}

/// Whether the checkbox or the whole surface is the target.
enum PanelCheckboxVariant {
  /// A box with an optional label beside it. PanelUI's `default`.
  plain,

  /// A bordered card that is pressed as a whole, with the box at its end.
  /// For pickable options, where the box confirms the choice rather than
  /// inviting it.
  card,
}

/// A checkbox, with an optional label and description beside it.
///
/// The fill springs in from 60% scale when checked and fades out over 120ms
/// when not. [indeterminate] draws a dash for a box that governs a partly
/// checked group; pressing it reports `true`, turning the whole group on.
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

  /// Draws a dash instead of a tick, for a box governing a partly checked
  /// group, and announces the box as mixed. It overrides [value] for what is
  /// drawn.
  final bool indeterminate;

  /// Text beside the box; pressing it toggles too. It is also the box's name
  /// for screen readers.
  final String? label;

  /// A secondary line under the label, announced as the box's hint.
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
  /// The dash and the tick share one fill, so the box is on for either; what
  /// changes between them is the glyph.
  bool get _on => widget.value || widget.indeterminate;

  // Unbounded so the spring's overshoot is drawn rather than clamped away.
  late final AnimationController _progress = AnimationController.unbounded(
    vsync: this,
    value: _on ? 1 : 0,
  );
  late final Animation<double> _scale = _progress.drive(
    Tween(begin: 0.6, end: 1),
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

  // An indeterminate box resolves upward: the press turns the group on.
  void _toggle() =>
      widget.onChanged?.call(widget.indeterminate ? true : !widget.value);

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final m = _metrics[widget.size]!;
    final enabled = widget.onChanged != null;
    final card = widget.variant == PanelCheckboxVariant.card;
    final name = widget.semanticLabel ?? widget.label;

    final text = widget.label == null && widget.description == null
        ? null
        : _CheckboxText(
            label: widget.label,
            description: widget.description,
            labelStyle: card
                ? theme.typography.style(
                    PanelTextSize.base,
                    weight: FontWeight.w500,
                    color: c.foreground,
                  )
                : m.label.resolve(theme.typography, c.foreground),
            descriptionStyle: theme.typography.style(
              m.description,
              color: c.mutedForeground,
            ),
          );

    return PanelPressable(
      onPressed: enabled ? _toggle : null,
      // PanelUI draws a checkbox on a plain Pressable: no press shrink.
      pressScale: 1,
      isButton: false,
      checked: widget.indeterminate ? null : widget.value,
      mixed: widget.indeterminate ? true : null,
      semanticLabel: name,
      // Without a name the row's own text is read, description and all.
      semanticHint: name == null ? null : widget.description,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      builder: (context, state) {
        final box = _CheckboxBox(
          dimension: m.box,
          radius: _boxRadius(widget.size, theme.radii),
          glyph: m.glyph,
          indeterminate: widget.indeterminate,
          progress: _progress,
          scale: _scale,
          hovered: state.hovered,
          focused: state.focused,
        );
        return Opacity(
          opacity: enabled ? 1 : 0.5,
          child: card
              ? _CheckboxCard(on: _on, box: box, text: text)
              : _CheckboxRow(
                  gap: m.gap,
                  // A description makes the row two lines tall: the box lines
                  // up with the label rather than the middle of the block.
                  alignTop: widget.description != null,
                  box: box,
                  text: text,
                ),
        );
      },
    );
  }
}

/// A Tailwind text class: a step on the type scale (`text-sm`), or a bare
/// size (`text-[13px]`) that keeps the font's own line height.
@immutable
class _TextClass {
  const _TextClass.step(PanelTextSize this.step) : bare = null;
  const _TextClass.bare(double this.bare) : step = null;

  final PanelTextSize? step;
  final double? bare;

  TextStyle resolve(PanelTypography typography, Color color) {
    final step = this.step;
    return step != null
        ? typography.style(step, color: color)
        : typography.sized(bare!, color: color);
  }
}

@immutable
class _CheckboxMetrics {
  const _CheckboxMetrics({
    required this.box,
    required this.glyph,
    required this.gap,
    required this.label,
    required this.description,
  });

  /// The box's side.
  final double box;

  /// The tick and the dash, sized to leave the same share of the box around
  /// them at every size.
  final double glyph;

  /// Between the box and the text.
  final double gap;

  final _TextClass label;
  final PanelTextSize description;
}

const _metrics = {
  PanelCheckboxSize.xs: _CheckboxMetrics(
    box: 14,
    glyph: 8,
    gap: 8,
    label: _TextClass.step(PanelTextSize.xs),
    description: PanelTextSize.xs,
  ),
  PanelCheckboxSize.sm: _CheckboxMetrics(
    box: 16,
    glyph: 10,
    gap: 8,
    label: _TextClass.bare(13),
    description: PanelTextSize.xs,
  ),
  PanelCheckboxSize.md: _CheckboxMetrics(
    box: 20,
    glyph: 12,
    gap: 10,
    label: _TextClass.step(PanelTextSize.sm),
    description: PanelTextSize.sm,
  ),
  PanelCheckboxSize.lg: _CheckboxMetrics(
    box: 24,
    glyph: 14,
    gap: 12,
    label: _TextClass.step(PanelTextSize.base),
    description: PanelTextSize.sm,
  ),
  PanelCheckboxSize.xl: _CheckboxMetrics(
    box: 28,
    glyph: 16,
    gap: 12,
    label: _TextClass.step(PanelTextSize.lg),
    description: PanelTextSize.base,
  ),
};

/// The least a checkbox's row or card measures on either axis
/// (`min-h-12 min-w-12`): the touch target, whatever the size of the box.
const double _target = 48;

/// The box's corners: `rounded-sm` for the two small boxes, `rounded-lg` for
/// the largest, `rounded-md` between.
double _boxRadius(PanelCheckboxSize size, PanelRadii radii) => switch (size) {
  PanelCheckboxSize.xs || PanelCheckboxSize.sm => radii.sm,
  PanelCheckboxSize.md || PanelCheckboxSize.lg => radii.md,
  PanelCheckboxSize.xl => radii.lg,
};

/// The web package's keyboard focus ring (`ring-2 ring-ring ring-offset-2`):
/// 2pt of [color] standing 2pt clear of the control. The gap is left
/// see-through rather than painted in the page colour.
Border _focusRing(Color color) => Border.all(
  color: color,
  width: 2,
  // Outside the edge and past the gap: from 2pt to 4pt out.
  strokeAlign: 3,
);

/// The box, with its fill and glyph.
class _CheckboxBox extends StatelessWidget {
  const _CheckboxBox({
    required this.dimension,
    required this.radius,
    required this.glyph,
    required this.indeterminate,
    required this.progress,
    required this.scale,
    required this.hovered,
    required this.focused,
  });

  final double dimension;
  final double radius;
  final double glyph;
  final bool indeterminate;
  final Animation<double> progress;
  final Animation<double> scale;
  final bool hovered;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final c = PanelTheme.of(context).colors;
    final shape = BorderRadius.circular(radius);
    Widget box = Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: shape,
        border: Border.all(
          // The web package's hover: the edge darkens a quarter of the way
          // towards the foreground.
          color: hovered ? Color.lerp(c.input, c.foreground, 0.25)! : c.input,
        ),
      ),
      // The fill sits inside the border, as PanelUI's `absolute inset-0` fill
      // does, so the box keeps its edge when checked.
      child: ScaleTransition(
        scale: scale,
        child: FadeTransition(
          opacity: progress,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.primary, borderRadius: shape),
            child: PanelIcon(
              indeterminate ? PanelIcons.minus : PanelIcons.check,
              size: glyph,
              color: c.primaryForeground,
            ),
          ),
        ),
      ),
    );
    if (focused) {
      box = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: shape,
          border: _focusRing(c.ring),
        ),
        child: box,
      );
    }
    return box;
  }
}

/// The label and the description under it.
class _CheckboxText extends StatelessWidget {
  const _CheckboxText({
    required this.label,
    required this.description,
    required this.labelStyle,
    required this.descriptionStyle,
  });

  final String? label;
  final String? description;
  final TextStyle labelStyle;
  final TextStyle descriptionStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        if (label != null) Text(label!, style: labelStyle),
        if (description != null) Text(description!, style: descriptionStyle),
      ],
    );
  }
}

/// The plain checkbox: the box with its text beside it, in a row at least
/// 48pt square.
///
/// The row takes the width it is given when it is made to fill one, as
/// PanelUI's does, and otherwise shrinks to its content.
class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.gap,
    required this.alignTop,
    required this.box,
    required this.text,
  });

  final double gap;
  final bool alignTop;
  final Widget box;
  final Widget? text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _target, minWidth: _target),
      child: Align(
        alignment: alignTop
            ? AlignmentDirectional.topStart
            : AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignTop
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          spacing: gap,
          children: [
            box,
            if (text != null) Flexible(child: text!),
          ],
        ),
      ),
    );
  }
}

/// The card checkbox: the text first and the box at the top of the far end,
/// on a card that takes the primary edge and the accent fill when on.
class _CheckboxCard extends StatelessWidget {
  const _CheckboxCard({
    required this.on,
    required this.box,
    required this.text,
  });

  final bool on;
  final Widget box;
  final Widget? text;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: _target, minWidth: _target),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: on ? c.accent : c.card,
        border: Border.all(color: on ? c.primary : c.border),
        borderRadius: BorderRadius.circular(theme.radii.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          if (text != null) Expanded(child: text!),
          box,
        ],
      ),
    );
  }
}
