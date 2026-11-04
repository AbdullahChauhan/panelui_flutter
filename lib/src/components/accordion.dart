import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// How a [PanelAccordion] is drawn.
enum PanelAccordionVariant {
  /// Sections on the page, divided by hairlines. PanelUI's `default`.
  plain,

  /// The sections inside one bordered, rounded surface.
  surface,

  /// Each section its own bordered card, 10pt apart.
  separated,

  /// Each section its own bordered outline, with no fill.
  bordered,

  /// No dividers and no inset: the text lines up with the content around it.
  ghost,
}

/// Whether opening a section of a [PanelAccordion] closes the others.
enum PanelAccordionSelectionMode {
  /// At most one section is open; opening another closes it.
  single,

  /// Any number of sections can be open at once.
  multiple,
}

/// How a [PanelCollapsible] is drawn.
enum PanelCollapsibleVariant {
  /// On the page, with a small inset. PanelUI's `default`.
  plain,

  /// Inside a bordered, rounded surface.
  surface,

  /// No inset: the text lines up with the content around it.
  ghost,
}

/// Collapsible sections, each a header that shows and hides its body.
///
/// ```dart
/// PanelAccordion<String>(
///   initialValue: const {'shipping'},
///   children: const [
///     PanelAccordionItem(
///       value: 'shipping',
///       title: Text('How long does shipping take?'),
///       child: Text('Standard delivery arrives in three to five working days.'),
///     ),
///     PanelAccordionItem(
///       value: 'returns',
///       title: Text('What is your returns policy?'),
///       child: Text('Send anything back within 30 days for a full refund.'),
///     ),
///   ],
/// )
/// ```
///
/// A closed section costs nothing, because its body is not built. That is
/// the right default and the wrong one for a body with state in it, such as
/// a half-filled form: set [keepMounted] (or [PanelAccordionItem.keepMounted])
/// and a closed body is hidden instead, keeping everything inside where it
/// was left.
///
/// A section opens by growing to its new height over 200ms while its chevron
/// turns. With reduced motion it arrives at its new height without
/// travelling there: the disclosure still happens, the movement is what goes.
class PanelAccordion<T> extends StatefulWidget {
  /// Creates an accordion.
  const PanelAccordion({
    super.key,
    required this.children,
    this.variant = PanelAccordionVariant.plain,
    this.selectionMode = PanelAccordionSelectionMode.single,
    this.value,
    this.initialValue = const {},
    this.onChanged,
    this.showSeparators = true,
    this.keepMounted = false,
  });

  /// The sections, usually [PanelAccordionItem]s.
  final List<Widget> children;

  /// How the accordion is drawn.
  final PanelAccordionVariant variant;

  /// Whether opening one section closes the others.
  final PanelAccordionSelectionMode selectionMode;

  /// The open sections, by [PanelAccordionItem.value]. In single mode it
  /// holds at most one. When null the accordion keeps its own, starting from
  /// [initialValue].
  final Set<T>? value;

  /// The sections open at first, when [value] is null.
  final Set<T> initialValue;

  /// Called with the open sections after a header is pressed.
  final ValueChanged<Set<T>>? onChanged;

  /// Whether hairlines divide the sections, in the variants that draw them
  /// (plain and surface).
  final bool showSeparators;

  /// Keep every body built while its section is closed, so state inside it
  /// survives being collapsed.
  final bool keepMounted;

  @override
  State<PanelAccordion<T>> createState() => _PanelAccordionState<T>();
}

class _PanelAccordionState<T> extends State<PanelAccordion<T>> {
  late Set<T> _internal = {...widget.initialValue};

  Set<T> get _expanded => widget.value ?? _internal;

  void _toggle(Object? item) {
    final value = item as T;
    final expanded = _expanded;
    final open = expanded.contains(value);
    final Set<T> next;
    if (widget.selectionMode == PanelAccordionSelectionMode.single) {
      next = open ? <T>{} : {value};
    } else {
      next = open ? ({...expanded}..remove(value)) : {...expanded, value};
    }
    if (widget.value == null) setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final variant = widget.variant;
    final divided =
        widget.showSeparators &&
        (variant == PanelAccordionVariant.plain ||
            variant == PanelAccordionVariant.surface);

    final items = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      items.add(widget.children[i]);
      if (divided && i < widget.children.length - 1) {
        items.add(
          ExcludeSemantics(
            child: Container(
              height: 1,
              margin: variant == PanelAccordionVariant.surface
                  ? const EdgeInsets.symmetric(horizontal: _boxedInset)
                  : null,
              color: c.border,
            ),
          ),
        );
      }
    }

    Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: variant == PanelAccordionVariant.separated ? _separatedGap : 0,
      children: items,
    );
    if (variant == PanelAccordionVariant.surface) {
      column = Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(theme.radii.xxl),
        ),
        child: column,
      );
    }

    return _AccordionScope(
      expanded: Set<Object?>.of(_expanded),
      toggle: _toggle,
      variant: variant,
      keepMounted: widget.keepMounted,
      child: column,
    );
  }
}

/// One section of a [PanelAccordion]: a header that toggles it and the body
/// it shows.
///
/// [title] is styled as PanelUI's `Accordion.Title` and can hold anything
/// (a badge, a price, a second line); [child] is the body, whose text is
/// small and muted.
class PanelAccordionItem<T> extends StatelessWidget {
  /// Creates a section.
  const PanelAccordionItem({
    super.key,
    required this.value,
    required this.title,
    required this.child,
    this.indicator,
    this.showIndicator = true,
    this.enabled = true,
    this.keepMounted,
    this.semanticLabel,
  });

  /// Identifies this section in the accordion's value.
  final T value;

  /// The header's title.
  final Widget title;

  /// The body.
  final Widget child;

  /// Replaces the chevron. It still turns half a circle while open.
  final Widget? indicator;

  /// Whether to draw the chevron.
  final bool showIndicator;

  /// Whether the header opens and closes the section.
  final bool enabled;

  /// Keep the body built while closed. Overrides
  /// [PanelAccordion.keepMounted], either way round.
  final bool? keepMounted;

  /// An accessible name for the header, when [title] is not text.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scope = _AccordionScope.of(context);
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final open = scope.expanded.contains(value);
    final variant = scope.variant;
    final inset = switch (variant) {
      PanelAccordionVariant.plain => _plainInset,
      PanelAccordionVariant.ghost => 0.0,
      PanelAccordionVariant.surface ||
      PanelAccordionVariant.separated ||
      PanelAccordionVariant.bordered => _boxedInset,
    };
    final reduce = panelReduceMotion(context);
    final keep = keepMounted ?? scope.keepMounted;

    final body = _DisclosureBody(inset: inset, child: child);
    // Opening swaps the body in and closing swaps it out at once, and the
    // section's height travels between the two, clipping what does not fit
    // yet: PanelUI's layout transition on the item.
    final content = AnimatedSize(
      duration: reduce ? Duration.zero : _disclosureDuration,
      curve: panelEase,
      alignment: Alignment.topCenter,
      child: keep
          ? Visibility(visible: open, maintainState: true, child: body)
          : open
          ? body
          : const SizedBox(width: double.infinity),
    );

    Widget section = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DisclosureTrigger(
          open: open,
          enabled: enabled,
          inset: inset,
          indicator: indicator,
          showIndicator: showIndicator,
          semanticLabel: semanticLabel,
          onPressed: () => scope.toggle(value),
          title: title,
        ),
        content,
      ],
    );

    switch (variant) {
      case PanelAccordionVariant.separated:
        section = Container(
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(theme.radii.xl),
          ),
          child: section,
        );
      case PanelAccordionVariant.bordered:
        section = Container(
          margin: const EdgeInsets.only(bottom: _borderedGap),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(theme.radii.xl),
          ),
          child: section,
        );
      case PanelAccordionVariant.plain:
      case PanelAccordionVariant.surface:
      case PanelAccordionVariant.ghost:
        break;
    }
    return section;
  }
}

/// One section whose header shows and hides its body.
///
/// ```dart
/// PanelCollapsible(
///   variant: PanelCollapsibleVariant.surface,
///   title: const Text('Delivery options'),
///   child: const Text('Anything, of any height.'),
/// )
/// ```
///
/// It looks like a one-section [PanelAccordion] and differs in what happens
/// to the body when it closes: this keeps the body built and animates its
/// height and opacity over 200ms, so what is inside survives being closed (a
/// part-filled form, a scroll position). Reach for [PanelAccordion] when
/// sections are mutually exclusive, or the body is expensive and rarely
/// opened.
///
/// A closed body is hidden from screen readers and from keyboard focus as
/// well as from the eye. With reduced motion it snaps between its states.
class PanelCollapsible extends StatefulWidget {
  /// Creates a collapsible section.
  const PanelCollapsible({
    super.key,
    required this.title,
    required this.child,
    this.open,
    this.initiallyOpen = false,
    this.onOpenChanged,
    this.variant = PanelCollapsibleVariant.plain,
    this.enabled = true,
    this.indicator,
    this.showIndicator = true,
    this.semanticLabel,
  });

  /// The header's title.
  final Widget title;

  /// The body.
  final Widget child;

  /// Whether the body is showing. When null the section keeps its own state,
  /// starting from [initiallyOpen].
  final bool? open;

  /// Whether the body shows at first, when [open] is null.
  final bool initiallyOpen;

  /// Called with the new state when the header is pressed.
  final ValueChanged<bool>? onOpenChanged;

  /// How the section is drawn.
  final PanelCollapsibleVariant variant;

  /// Whether the header opens and closes the section.
  final bool enabled;

  /// Replaces the chevron. It still turns half a circle while open.
  final Widget? indicator;

  /// Whether to draw the chevron.
  final bool showIndicator;

  /// An accessible name for the header, when [title] is not text.
  final String? semanticLabel;

  @override
  State<PanelCollapsible> createState() => _PanelCollapsibleState();
}

class _PanelCollapsibleState extends State<PanelCollapsible>
    with SingleTickerProviderStateMixin {
  late bool _internal = widget.initiallyOpen;

  bool get _open => widget.open ?? _internal;

  // The first frame is not a transition: a body that starts open is open.
  late double _target = _open ? 1 : 0;
  late final AnimationController _progress = AnimationController(
    vsync: this,
    value: _target,
  );

  @override
  void didUpdateWidget(PanelCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animate();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _animate() {
    final target = _open ? 1.0 : 0.0;
    if (target == _target) return;
    _target = target;
    if (panelReduceMotion(context)) {
      _progress.value = target;
    } else {
      _progress.animateTo(
        target,
        duration: _disclosureDuration,
        curve: panelEase,
      );
    }
  }

  void _toggle() {
    final next = !_open;
    if (widget.open == null) {
      setState(() => _internal = next);
      _animate();
    }
    widget.onOpenChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final open = _open;
    final inset = switch (widget.variant) {
      PanelCollapsibleVariant.plain => _plainInset,
      PanelCollapsibleVariant.surface => _boxedInset,
      PanelCollapsibleVariant.ghost => 0.0,
    };

    final body = AnimatedBuilder(
      animation: _progress,
      child: ExcludeSemantics(
        excluding: !open,
        child: ExcludeFocus(
          excluding: !open,
          child: _DisclosureBody(inset: inset, child: widget.child),
        ),
      ),
      builder: (context, child) {
        final t = _progress.value;
        return ClipRect(
          // Cut only while the height is: once open, the body draws as it
          // would anywhere else, and a focus ring at its edge is not lost.
          clipBehavior: t < 1 ? Clip.hardEdge : Clip.none,
          child: Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: t,
            // The body keeps the section's full width while its height is
            // cut, as PanelUI's measured content does.
            child: SizedBox(
              width: double.infinity,
              child: Opacity(opacity: t, child: child),
            ),
          ),
        );
      },
    );

    Widget section = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DisclosureTrigger(
          open: open,
          enabled: widget.enabled,
          inset: inset,
          indicator: widget.indicator,
          showIndicator: widget.showIndicator,
          semanticLabel: widget.semanticLabel,
          onPressed: _toggle,
          title: widget.title,
        ),
        body,
      ],
    );

    if (widget.variant == PanelCollapsibleVariant.surface) {
      section = Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(theme.radii.xxl),
        ),
        child: section,
      );
    }
    return section;
  }
}

/// How long a section takes to open or close, and its chevron to turn. One
/// duration for both, so the panel and the arrow that describes it finish
/// together.
const Duration _disclosureDuration = Duration(milliseconds: 200);

/// How far a header and its body sit in from the section's edges: `px-1` in
/// the plain variant, `px-4` inside a box.
const double _plainInset = 4;
const double _boxedInset = 16;

/// A header's vertical padding (`py-4`), the gap between its title and its
/// chevron (`gap-4`), and the chevron's size: PanelUI draws it at 18pt, in
/// the muted grey its icons default to.
const double _triggerPaddingY = 16;
const double _triggerGap = 16;
const double _chevronSize = 18;

/// The room under a body (`pb-4`).
const double _bodyPaddingBottom = 16;

/// The gap between separated sections (`gap-2.5`), and the margin under each
/// bordered one (`mb-2`).
const double _separatedGap = 10;
const double _borderedGap = 8;

class _AccordionScope extends InheritedWidget {
  const _AccordionScope({
    required this.expanded,
    required this.toggle,
    required this.variant,
    required this.keepMounted,
    required super.child,
  });

  final Set<Object?> expanded;
  final ValueChanged<Object?> toggle;
  final PanelAccordionVariant variant;
  final bool keepMounted;

  static _AccordionScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AccordionScope>();
    if (scope == null) {
      throw FlutterError(
        'PanelAccordionItem must be used inside a PanelAccordion.',
      );
    }
    return scope;
  }

  @override
  bool updateShouldNotify(_AccordionScope oldWidget) =>
      !setEquals(expanded, oldWidget.expanded) ||
      toggle != oldWidget.toggle ||
      variant != oldWidget.variant ||
      keepMounted != oldWidget.keepMounted;
}

/// The pressable header row shared by accordion sections and collapsibles:
/// a title that takes the width and a chevron that turns half a circle while
/// the section is open.
class _DisclosureTrigger extends StatelessWidget {
  const _DisclosureTrigger({
    required this.open,
    required this.enabled,
    required this.inset,
    required this.indicator,
    required this.showIndicator,
    required this.semanticLabel,
    required this.onPressed,
    required this.title,
  });

  final bool open;
  final bool enabled;
  final double inset;
  final Widget? indicator;
  final bool showIndicator;
  final String? semanticLabel;
  final VoidCallback onPressed;
  final Widget title;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final reduce = panelReduceMotion(context);

    return PanelPressable(
      onPressed: enabled ? onPressed : null,
      pressScale: 1,
      expanded: open,
      semanticLabel: semanticLabel,
      focusRingRadius: BorderRadius.circular(theme.radii.lg),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: inset,
          vertical: _triggerPaddingY,
        ),
        child: Row(
          spacing: _triggerGap,
          children: [
            Expanded(
              child: DefaultTextStyle(
                style: theme.typography.style(
                  PanelTextSize.base,
                  weight: FontWeight.w500,
                  color: c.foreground,
                ),
                child: title,
              ),
            ),
            if (showIndicator)
              ExcludeSemantics(
                child: AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: reduce ? Duration.zero : _disclosureDuration,
                  curve: panelEase,
                  child: IconTheme(
                    data: IconThemeData(
                      color: c.mutedForeground,
                      size: _chevronSize,
                    ),
                    child: indicator ?? const PanelIcon(PanelIcons.chevronDown),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A section's body: inset to line up with its header, 16pt clear of what
/// follows, its text small and muted.
class _DisclosureBody extends StatelessWidget {
  const _DisclosureBody({required this.inset, required this.child});

  final double inset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, 0, inset, _bodyPaddingBottom),
      child: DefaultTextStyle(
        style: theme.typography.style(
          PanelTextSize.sm,
          color: theme.colors.mutedForeground,
        ),
        child: child,
      ),
    );
  }
}
