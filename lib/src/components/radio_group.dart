import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// Whether the options of a [PanelRadioGroup] are rows or cards.
enum PanelRadioVariant {
  /// A disc with its label beside it, the classic radio row. PanelUI's `dot`.
  plain,

  /// A bordered card that is pressed as a whole, with the disc at its
  /// trailing edge. For a plan picker or a settings choice where each option
  /// carries a description and the disc confirms rather than invites. The
  /// same treatment as `PanelCheckboxVariant.card`, so a form mixing single
  /// and multiple choice reads as one family.
  card,
}

/// How big the discs and labels of a [PanelRadioGroup] are.
///
/// Set on the group rather than per option, because options of different
/// sizes read as though one of them matters more. A row keeps a 48pt touch
/// target at every size.
enum PanelRadioSize {
  /// A 14pt disc with 12px text.
  xs,

  /// A 16pt disc with 13px text.
  sm,

  /// A 20pt disc with 14px text, the default.
  md,

  /// A 24pt disc with 16px text.
  lg,

  /// A 28pt disc with 18px text.
  xl,
}

/// A Tailwind text class: a step on the type scale, or a bare
/// `text-[13px]` that keeps the font's own line height.
@immutable
class _Type {
  const _Type.step(PanelTextSize this.step) : bare = null;
  const _Type.bare(double this.bare) : step = null;

  final PanelTextSize? step;
  final double? bare;

  TextStyle resolve(PanelTypography typography, {required Color color}) {
    final step = this.step;
    return step != null
        ? typography.style(step, color: color)
        : typography.sized(bare!, color: color);
  }
}

class _RadioMetrics {
  const _RadioMetrics({
    required this.disc,
    required this.dot,
    required this.gap,
    required this.label,
    required this.description,
  });

  final double disc;

  /// Half the disc it sits in, at every size.
  final double dot;
  final double gap;
  final _Type label;
  final _Type description;
}

// The same steps as the checkbox, so the two line up in one form.
const _radioMetrics = {
  PanelRadioSize.xs: _RadioMetrics(
    disc: 14,
    dot: 6,
    gap: 8,
    label: _Type.step(PanelTextSize.xs),
    description: _Type.bare(11),
  ),
  PanelRadioSize.sm: _RadioMetrics(
    disc: 16,
    dot: 8,
    gap: 8,
    label: _Type.bare(13),
    description: _Type.step(PanelTextSize.xs),
  ),
  PanelRadioSize.md: _RadioMetrics(
    disc: 20,
    dot: 10,
    gap: 10,
    label: _Type.step(PanelTextSize.sm),
    description: _Type.step(PanelTextSize.xs),
  ),
  PanelRadioSize.lg: _RadioMetrics(
    disc: 24,
    dot: 12,
    gap: 12,
    label: _Type.step(PanelTextSize.base),
    description: _Type.step(PanelTextSize.sm),
  ),
  PanelRadioSize.xl: _RadioMetrics(
    disc: 28,
    dot: 14,
    gap: 12,
    label: _Type.step(PanelTextSize.lg),
    description: _Type.step(PanelTextSize.sm),
  ),
};

/// One choice from a set.
///
/// The group owns the value and hands each [PanelRadioItem] its selected
/// state, so an item is a thin pressable that reports its own value up and
/// reads the selection back down. Pressing the chosen option again does
/// nothing: a radio is never cleared by its own press.
///
/// ```dart
/// PanelRadioGroup<String>(
///   value: plan,
///   onChanged: (v) => setState(() => plan = v),
///   variant: PanelRadioVariant.card,
///   children: const [
///     PanelRadioItem(value: 'pro', label: 'Pro', description: 'For growing teams'),
///     PanelRadioItem(value: 'max', label: 'Max', description: 'Everything, uncapped'),
///   ],
/// )
/// ```
///
/// The group is one stop for Tab, which lands on the chosen option; inside
/// it the arrow keys move the choice from one option to the next, as a
/// native radio group does. That keyboard handling and the `radioGroup`
/// semantics role come from Flutter's own [RadioGroup].
class PanelRadioGroup<T> extends StatelessWidget {
  /// Creates a radio group.
  const PanelRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.variant = PanelRadioVariant.plain,
    this.size = PanelRadioSize.md,
    this.orientation = Axis.vertical,
  });

  /// The chosen value, or null when nothing is chosen yet.
  final T? value;

  /// Called with the value of the option pressed. Null disables the group.
  final ValueChanged<T>? onChanged;

  /// The options, usually [PanelRadioItem]s of the same type.
  final List<Widget> children;

  /// Rows or cards, for every option.
  final PanelRadioVariant variant;

  /// The size of every option's disc and text.
  final PanelRadioSize size;

  /// [Axis.vertical] stacks the options 12pt apart. [Axis.horizontal] lays
  /// them along a row that wraps, for two or three short choices where a
  /// stacked list wastes the width; cards in a row share it equally.
  final Axis orientation;

  void _handleChanged(T? next) {
    if (next is T && next != value) onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final card = variant == PanelRadioVariant.card;
    final Widget layout;
    if (orientation == Axis.horizontal) {
      layout = card
          // Cards share the row rather than each taking the line, and stand
          // as tall as the tallest of them.
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: [
                  for (final child in children) Expanded(child: child),
                ],
              ),
            )
          // Wrapping, not scrolling: a choice that runs off the edge is a
          // choice nobody knows is there.
          : Wrap(
              spacing: 20,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: children,
            );
    } else {
      layout = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: card
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        spacing: 12,
        children: children,
      );
    }

    return RadioGroup<T>(
      groupValue: value,
      onChanged: _handleChanged,
      child: _RadioScope<T>(
        value: value,
        onChanged: onChanged,
        variant: variant,
        size: size,
        child: layout,
      ),
    );
  }
}

class _RadioScope<T> extends InheritedWidget {
  const _RadioScope({
    required this.value,
    required this.onChanged,
    required this.variant,
    required this.size,
    required super.child,
  });

  final T? value;
  final ValueChanged<T>? onChanged;
  final PanelRadioVariant variant;
  final PanelRadioSize size;

  static _RadioScope<T> of<T>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_RadioScope<T>>();
    if (scope == null) {
      throw FlutterError(
        'PanelRadioItem<$T> must be placed inside a PanelRadioGroup<$T>.\n'
        'The item reads its selected state from the nearest group whose '
        'value type is exactly $T.',
      );
    }
    return scope;
  }

  @override
  bool updateShouldNotify(_RadioScope<T> oldWidget) =>
      value != oldWidget.value ||
      onChanged != oldWidget.onChanged ||
      variant != oldWidget.variant ||
      size != oldWidget.size;
}

/// One option of a [PanelRadioGroup].
///
/// The disc's dot springs in from nothing when the option is chosen and fades
/// out over 120ms when it is left. In the plain variant the disc sits before
/// the label; in the card variant the text comes first and the disc sits at
/// the trailing edge.
class PanelRadioItem<T> extends StatefulWidget {
  /// Creates an option.
  const PanelRadioItem({
    super.key,
    required this.value,
    this.label,
    this.description,
    this.child,
    this.enabled = true,
    this.hideIndicator = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// What the group's value becomes when this option is chosen.
  final T value;

  /// The option's text. Pressing it chooses the option too.
  final String? label;

  /// A secondary line under the label, most at home in the card variant.
  final String? description;

  /// Content shown in place of [label], styled as the label would be.
  final Widget? child;

  /// Whether this option can be chosen. The whole group is disabled by a null
  /// [PanelRadioGroup.onChanged].
  final bool enabled;

  /// Hides the disc, for a card whose selected fill is enough.
  final bool hideIndicator;

  /// The accessible name, when [label] is missing or not enough.
  final String? semanticLabel;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  @override
  State<PanelRadioItem<T>> createState() => _PanelRadioItemState<T>();
}

class _PanelRadioItemState<T> extends State<PanelRadioItem<T>>
    with SingleTickerProviderStateMixin, RadioClient<T> {
  late final AnimationController _progress = AnimationController.unbounded(
    vsync: this,
  );
  _RadioScope<T>? _scope;
  bool? _selected;
  FocusNode? _ownFocusNode;

  @override
  FocusNode get focusNode =>
      widget.focusNode ??
      (_ownFocusNode ??= FocusNode(debugLabel: 'PanelRadioItem'));

  @override
  T get radioValue => widget.value;

  @override
  bool get tristate => false;

  @override
  bool get enabled => widget.enabled && _scope?.onChanged != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = _RadioScope.of<T>(context);
    registry = RadioGroup.maybeOf<T>(context);
    _syncSelection();
  }

  @override
  void didUpdateWidget(PanelRadioItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelection();
  }

  @override
  void dispose() {
    registry = null;
    _ownFocusNode?.dispose();
    _progress.dispose();
    super.dispose();
  }

  void _syncSelection() {
    final selected = _scope!.value == widget.value;
    if (selected == _selected) return;
    final first = _selected == null;
    _selected = selected;
    if (first || panelReduceMotion(context)) {
      _progress.value = selected ? 1 : 0;
    } else if (selected) {
      _progress.springTo(1, PanelSprings.check);
    } else {
      _progress.animateTo(
        0,
        duration: PanelDurations.uncheck,
        curve: panelEase,
      );
    }
  }

  void _choose() {
    final scope = _scope;
    if (scope == null || scope.value == widget.value) return;
    scope.onChanged?.call(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final scope = _RadioScope.of<T>(context);
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final m = _radioMetrics[scope.size]!;
    final card = scope.variant == PanelRadioVariant.card;
    final selected = scope.value == widget.value;
    final isEnabled = enabled;
    final reduced = panelReduceMotion(context);

    final labelStyle = card
        ? theme.typography.style(
            PanelTextSize.base,
            weight: FontWeight.w500,
            color: c.foreground,
          )
        : m.label.resolve(theme.typography, color: c.foreground);
    final descriptionStyle = m.description.resolve(
      theme.typography,
      color: c.mutedForeground,
    );

    Widget? label;
    if (widget.label != null) {
      label = Text(widget.label!, style: labelStyle);
    } else if (widget.child != null) {
      label = DefaultTextStyle(style: labelStyle, child: widget.child!);
    }
    final description = widget.description == null
        ? null
        : Text(widget.description!, style: descriptionStyle);
    final text = label == null && description == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [?label, ?description],
          );

    Widget disc(bool hovered) => Container(
      width: m.disc,
      height: m.disc,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.background,
        shape: BoxShape.circle,
        border: Border.all(
          // The web package's hover: the ring darkens a quarter of the way
          // towards the foreground.
          color: hovered ? Color.lerp(c.input, c.foreground, 0.25)! : c.input,
        ),
      ),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final t = _progress.value;
          if (t <= 0) return const SizedBox.shrink();
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: t,
              child: Container(
                width: m.dot,
                height: m.dot,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );

    Widget visual(PanelPressState state) {
      final indicator = widget.hideIndicator
          ? null
          : disc(state.hovered && !card);
      if (card) {
        final Color border;
        if (selected) {
          border = c.primary;
        } else if (state.hovered) {
          border = Color.lerp(c.border, c.foreground, 0.18)!;
        } else {
          border = c.border;
        }
        return AnimatedContainer(
          duration: reduced ? Duration.zero : const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? Color.alphaBlend(c.accent, c.card) : c.card,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(theme.radii.xl),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(child: text ?? const SizedBox.shrink()),
              ?indicator,
            ],
          ),
        );
      }

      // With a description the disc lines up with the label's first line
      // rather than the middle of both.
      final twoLines = description != null && label != null;
      final lineHeight = (labelStyle.height ?? 1.2) * labelStyle.fontSize!;
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: twoLines
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            spacing: m.gap,
            children: [
              if (indicator != null)
                Padding(
                  padding: EdgeInsets.only(
                    top: twoLines
                        ? ((lineHeight - m.disc) / 2).clamp(0.0, lineHeight)
                        : 0,
                  ),
                  child: indicator,
                ),
              if (text != null) Flexible(child: text),
            ],
          ),
        ),
      );
    }

    final semanticLabel = widget.semanticLabel ?? widget.label;
    return PanelPressable(
      onPressed: isEnabled ? _choose : null,
      pressScale: 1,
      isButton: false,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: semanticLabel,
      // Without a name the row's own text is read, description and all.
      semanticHint: semanticLabel == null ? null : widget.description,
      focusNode: focusNode,
      autofocus: widget.autofocus,
      focusRingRadius: BorderRadius.circular(
        card ? theme.radii.xl : theme.radii.md,
      ),
      builder: (context, state) {
        final content = Opacity(
          opacity: isEnabled ? 1 : 0.5,
          child: visual(state),
        );
        // The text is already the option's name; reading it again from the
        // row would say everything twice.
        return semanticLabel == null
            ? content
            : ExcludeSemantics(child: content);
      },
    );
  }
}
