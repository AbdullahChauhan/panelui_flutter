import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_tokens.dart';
import '../theme/panel_typography.dart';

/// Whether the options of a [PanelRadioGroup] are rows or cards.
enum PanelRadioVariant {
  /// A disc with its label beside it, the classic radio row. PanelUI's `dot`.
  plain,

  /// A bordered card that is pressed as a whole, with a description under the
  /// label and the disc at its trailing edge. For a plan picker or a settings
  /// choice where the disc confirms rather than invites. The same treatment
  /// as `PanelCheckboxVariant.card`, so a form mixing single and multiple
  /// choice reads as one family.
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
    return RadioGroup<T>(
      groupValue: value,
      onChanged: _handleChanged,
      child: _RadioScope<T>(
        value: value,
        onChanged: onChanged,
        variant: variant,
        size: size,
        child: _layout(),
      ),
    );
  }

  Widget _layout() {
    final card = variant == PanelRadioVariant.card;
    if (orientation == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        // A row is only as wide as its label, so the space beside it is not
        // part of the target; a card is the target, so it takes the width.
        crossAxisAlignment: card
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        spacing: _stackGap,
        children: children,
      );
    }
    if (!card) {
      // Wrapping, not scrolling: a choice that runs off the edge is a choice
      // nobody knows is there.
      return Wrap(spacing: _rowGap, runSpacing: _stackGap, children: children);
    }
    // Cards share the row rather than each taking the line, and stand as
    // tall as the tallest of them, which needs their heights up front.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _rowGap,
        children: [for (final child in children) Expanded(child: child)],
      ),
    );
  }
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

  /// A secondary line under the label, drawn by the card variant. As in
  /// PanelUI, a plain row is the disc and its label alone. Screen readers
  /// hear it as a hint when the option is named by [label].
  final String? description;

  /// Content shown in place of [label], styled as the label would be. Give
  /// it a [semanticLabel] when it is not plain text.
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

/// The gap between stacked options, and between wrapped lines of them.
const double _stackGap = 12;

/// The gap between options laid along a row.
const double _rowGap = 20;

/// PanelUI's `min-h-12 min-w-12`: the touch target, at every size.
const BoxConstraints _target = BoxConstraints(minHeight: 48, minWidth: 48);

/// PanelUI's `opacity-50` on a disabled option.
const double _disabledOpacity = 0.5;

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

  /// Between the disc and the label of a plain row. A card keeps 12.
  final double gap;

  /// A plain row's label. A card's is always 16px medium.
  final _Type label;

  /// A card's description.
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

class _PanelRadioItemState<T> extends State<PanelRadioItem<T>>
    with SingleTickerProviderStateMixin, RadioClient<T> {
  /// How far the dot is in, 0 to 1; the spring overshoots past 1.
  late final AnimationController _dot = AnimationController.unbounded(
    vsync: this,
  );
  late _RadioScope<T> _scope;
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
  bool get enabled => widget.enabled && _scope.onChanged != null;

  bool get _isSelected => _scope.value == widget.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = _RadioScope.of<T>(context);
    registry = RadioGroup.maybeOf<T>(context);
    _syncDot();
  }

  @override
  void didUpdateWidget(PanelRadioItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDot();
  }

  @override
  void dispose() {
    registry = null;
    _ownFocusNode?.dispose();
    _dot.dispose();
    super.dispose();
  }

  /// Springs the dot in on selection and fades it out over 120ms when the
  /// option is left. On the first build, and under reduced motion, it is
  /// simply there or not.
  void _syncDot() {
    final selected = _isSelected;
    if (selected == _selected) return;
    final first = _selected == null;
    _selected = selected;
    if (first || panelReduceMotion(context)) {
      _dot.value = selected ? 1 : 0;
    } else if (selected) {
      _dot.springTo(1, PanelSprings.check);
    } else {
      _dot.animateTo(0, duration: PanelDurations.uncheck, curve: panelEase);
    }
  }

  void _choose() {
    if (!_isSelected) _scope.onChanged?.call(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final metrics = _radioMetrics[_scope.size]!;
    final card = _scope.variant == PanelRadioVariant.card;
    final selected = _isSelected;
    final enabled = this.enabled;

    final labelStyle = card
        ? theme.typography.style(
            PanelTextSize.base,
            weight: FontWeight.w500,
            color: theme.colors.foreground,
          )
        : metrics.label.resolve(
            theme.typography,
            color: theme.colors.foreground,
          );
    final label = widget.label != null
        ? Text(widget.label!, style: labelStyle)
        : (widget.child == null
              ? null
              : DefaultTextStyle(style: labelStyle, child: widget.child!));

    final semanticLabel = widget.semanticLabel ?? widget.label;
    return PanelPressable(
      onPressed: enabled ? _choose : null,
      // PanelUI draws an option on a plain Pressable: no press shrink.
      pressScale: 1,
      isButton: false,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: semanticLabel,
      // A name replaces the card's text for screen readers; the description
      // stays reachable as a hint rather than going unread.
      semanticHint: card && semanticLabel != null ? widget.description : null,
      focusNode: focusNode,
      autofocus: widget.autofocus,
      builder: (context, state) {
        final disc = widget.hideIndicator
            ? null
            : _RadioDisc(
                metrics: metrics,
                dot: _dot,
                // The web package lights a row's disc on hover and rings it
                // on focus. A card is lit and ringed as a whole instead.
                hovered: state.hovered && !selected && !card,
                focused: state.focused && !card,
              );
        return Opacity(
          opacity: enabled ? 1 : _disabledOpacity,
          child: card
              ? _RadioCard(
                  label: label,
                  description: widget.description == null
                      ? null
                      : Text(
                          widget.description!,
                          style: metrics.description.resolve(
                            theme.typography,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                  disc: disc,
                  selected: selected,
                  hovered: state.hovered,
                  focused: state.focused,
                )
              : _RadioRow(
                  gap: metrics.gap,
                  label: label,
                  disc: disc,
                  focused: state.focused && disc == null,
                ),
        );
      },
    );
  }
}

/// A plain option: the disc, then its label, in a row as wide as they are and
/// at least 48pt tall.
class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.gap,
    required this.label,
    required this.disc,
    required this.focused,
  });

  final double gap;
  final Widget? label;
  final Widget? disc;

  /// Whether to ring the whole row, which only a row without a disc does.
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: _target,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: gap,
          children: [
            ?disc,
            if (label != null) Flexible(child: label!),
          ],
        ),
      ),
    );
    if (!focused) return row;
    final theme = PanelTheme.of(context);
    return _withFocusRing(
      row,
      theme.colors,
      BorderRadius.circular(theme.radii.md),
    );
  }
}

/// A card option: its label and description, then the disc at the trailing
/// edge. Chosen, it takes a primary edge and the accent fill.
class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.label,
    required this.description,
    required this.disc,
    required this.selected,
    required this.hovered,
    required this.focused,
  });

  final Widget? label;
  final Widget? description;
  final Widget? disc;
  final bool selected;
  final bool hovered;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final radius = BorderRadius.circular(theme.radii.xl);
    final Color border;
    if (selected) {
      border = c.primary;
    } else if (hovered) {
      // The web package's card hover.
      border = _mixOklab(c.border, c.foreground, 0.18);
    } else {
      border = c.border;
    }
    // PanelUI's card: `p-4`, `gap-3` before the disc, `gap-1` in the text.
    final card = Container(
      constraints: _target,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // PanelUI swaps the card fill for the accent tint outright, so the
        // tint is laid over whatever the card sits on.
        color: selected ? c.accent : c.card,
        border: Border.all(color: border),
        borderRadius: radius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [?label, ?description],
            ),
          ),
          ?disc,
        ],
      ),
    );
    return focused ? _withFocusRing(card, c, radius) : card;
  }
}

/// The disc, and the dot that springs into it.
class _RadioDisc extends StatelessWidget {
  const _RadioDisc({
    required this.metrics,
    required this.dot,
    required this.hovered,
    required this.focused,
  });

  final _RadioMetrics metrics;

  /// How far the dot is in. It drives the dot's scale and its opacity, so
  /// the dot repaints on each tick without a rebuild.
  final Animation<double> dot;

  final bool hovered;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final c = PanelTheme.of(context).colors;
    final disc = Container(
      width: metrics.disc,
      height: metrics.disc,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.background,
        shape: BoxShape.circle,
        border: Border.all(
          // The web package's hover: the ring a quarter of the way to the
          // foreground.
          color: hovered ? _mixOklab(c.input, c.foreground, 0.25) : c.input,
        ),
      ),
      child: FadeTransition(
        opacity: dot,
        child: ScaleTransition(
          scale: dot,
          child: SizedBox.square(
            dimension: metrics.dot,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
    if (!focused) return disc;
    return _withFocusRing(disc, c, BorderRadius.circular(metrics.disc / 2));
  }
}

/// Rings [child] the way the web package marks keyboard focus on a radio and
/// a radio card (`ring-2 ring-ring ring-offset-2 ring-offset-background`): a
/// 2pt band in the `ring` colour, held 2pt off the control by a band of the
/// page background.
Widget _withFocusRing(Widget child, PanelColors colors, BorderRadius radius) {
  BoxDecoration band(Color color, double strokeAlign) => BoxDecoration(
    borderRadius: radius,
    border: Border.all(color: color, width: 2, strokeAlign: strokeAlign),
  );
  return DecoratedBox(
    position: DecorationPosition.foreground,
    // A stroke aligned at 3 runs from 2pt to 4pt outside the edge.
    decoration: band(colors.ring, 3),
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: band(colors.background, BorderSide.strokeAlignOutside),
      child: child,
    ),
  );
}

/// CSS's `color-mix(in oklab, a, b t)`: [b] mixed into [a] by [t], in Oklab
/// with premultiplied alpha, which is how the web package writes its hover
/// borders. A plain RGB lerp of a translucent token comes out darker.
Color _mixOklab(Color a, Color b, double t) {
  final alpha = a.a * (1 - t) + b.a * t;
  if (alpha <= 0) return const Color(0x00000000);
  // Premultiplied: each colour counts for as much as it is opaque.
  final wa = a.a * (1 - t) / alpha;
  final wb = b.a * t / alpha;
  final (l1, a1, b1) = _toOklab(a);
  final (l2, a2, b2) = _toOklab(b);
  return _fromOklab(
    l1 * wa + l2 * wb,
    a1 * wa + a2 * wb,
    b1 * wa + b2 * wb,
    alpha,
  );
}

/// [color] in Oklab, after Björn Ottosson's reference conversion.
(double, double, double) _toOklab(Color color) {
  double linear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double cbrt(double x) => math.pow(x, 1 / 3).toDouble();
  final r = linear(color.r);
  final g = linear(color.g);
  final b = linear(color.b);
  final l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return (
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  );
}

/// The sRGB colour at Oklab ([lightness], [a], [b]), with [alpha].
Color _fromOklab(double lightness, double a, double b, double alpha) {
  double cube(double x) => x * x * x;
  double encode(double c) =>
      (c <= 0.0031308 ? 12.92 * c : 1.055 * math.pow(c, 1 / 2.4) - 0.055).clamp(
        0.0,
        1.0,
      );
  final l = cube(lightness + 0.3963377774 * a + 0.2158037573 * b);
  final m = cube(lightness - 0.1055613458 * a - 0.0638541728 * b);
  final s = cube(lightness - 0.0894841775 * a - 1.2914855480 * b);
  return Color.from(
    alpha: alpha,
    red: encode(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    green: encode(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    blue: encode(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s),
  );
}
