import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_theme_data.dart';
import '../theme/panel_typography.dart';

/// How a [PanelTabsList] marks the selected tab.
enum PanelTabsVariant {
  /// A raised chip travelling inside a recessed track, for switching what a
  /// panel shows. The default.
  segmented,

  /// A rule under the selected tab, on a hairline that gives the other tabs a
  /// baseline. For the sections of a page rather than a control.
  underline,

  /// A filled chip on the page, with the selected label inverted against it.
  pill,

  /// A row of icon pills, only the selected one open wide enough to show its
  /// label. Every tab draws its own pill, so there is no indicator to slide:
  /// the shape that moves is the open tab, widening to let its label out and
  /// closing again behind it. Give every trigger an `icon`; a closed tab has
  /// nothing else to be recognised by.
  expanding,
}

/// How big the triggers of a [PanelTabsList] and their labels are.
///
/// `xs` and `sm` are for a tab set inside something else, such as a card or a
/// toolbar; `lg` and `xl` are for one that is the main navigation of a
/// screen. Icons and badges you pass keep their own size.
enum PanelTabsSize {
  /// 12px labels.
  xs,

  /// 13px labels.
  sm,

  /// 14px labels, the default.
  md,

  /// 16px labels.
  lg,

  /// 18px labels.
  xl,
}

/// A set of tabs: a row of triggers and the panel of the selected one.
///
/// ```dart
/// PanelTabs<String>(
///   initialValue: 'account',
///   children: [
///     PanelTabsList(
///       children: [
///         PanelTabsTrigger(value: 'account', child: Text('Account')),
///         PanelTabsTrigger(value: 'team', badge: PanelBadge.count(3), child: Text('Team')),
///       ],
///     ),
///     PanelTabsContent(value: 'account', child: AccountForm()),
///     PanelTabsContent(value: 'team', child: TeamList()),
///   ],
/// )
/// ```
///
/// The selected tab is marked by one indicator that slides between the
/// triggers on a spring, rather than by a style on each trigger, so a switch
/// two tabs away reads as one movement instead of two states swapping.
///
/// [children] are laid out top to bottom, 12pt apart, and usually hold one
/// [PanelTabsList] and a [PanelTabsContent] per tab. Only the selected panel
/// is built unless [keepMounted] is set.
///
/// With [swipeable], the panels sit side by side in a strip and dragging
/// sideways on them moves between tabs as well. Given a height (an
/// `Expanded`, a `SizedBox`), the strip fills it; without one it is as tall
/// as its tallest panel, so switching does not change the tab set's height.
class PanelTabs<T> extends StatefulWidget {
  /// Creates a tab set.
  const PanelTabs({
    super.key,
    required this.children,
    this.value,
    this.initialValue,
    this.onChanged,
    this.variant = PanelTabsVariant.segmented,
    this.size = PanelTabsSize.md,
    this.keepMounted = false,
    this.swipeable = false,
    this.animated = true,
  });

  /// The list, the panels, and anything else, top to bottom.
  final List<Widget> children;

  /// The selected tab. When null the tab set keeps its own selection,
  /// starting from [initialValue].
  final T? value;

  /// The tab selected first, when [value] is null.
  final T? initialValue;

  /// Called with the tab that was pressed or swiped to.
  final ValueChanged<T>? onChanged;

  /// How the selected tab is marked.
  final PanelTabsVariant variant;

  /// How big the triggers and their labels are.
  final PanelTabsSize size;

  /// Build every panel up front and keep each one built while it is hidden,
  /// so a scroll position or a half-filled form survives switching away.
  /// Hidden panels are offstage: not painted, not hit, not announced, and
  /// their animations paused.
  final bool keepMounted;

  /// Move between tabs by dragging sideways on the panels as well as by
  /// pressing the triggers. Off by default, because a panel may hold
  /// something that already wants a horizontal drag, such as a carousel or a
  /// slider.
  ///
  /// It lays the panels out side by side, so the panel on each side of the
  /// selected one is built (a frame later) before you swipe to it.
  final bool swipeable;

  /// Whether the indicator, the strip and an expanding tab's label move. The
  /// platform's reduced-motion setting is honoured without this; turn it off
  /// for a screen already animating something more important.
  final bool animated;

  @override
  State<PanelTabs<T>> createState() => _PanelTabsState<T>();
}

class _PanelTabsState<T> extends State<PanelTabs<T>> {
  late T? _internal = widget.initialValue;

  T? get _value => widget.value ?? _internal;

  void _select(Object? next) {
    final value = next as T;
    if (widget.value == null) setState(() => _internal = value);
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    final panels = widget.swipeable
        ? <PanelTabsContent<Object?>>[
            for (final child in widget.children)
              if (child is PanelTabsContent) child,
          ]
        : const <PanelTabsContent<Object?>>[];
    final paged = panels.isNotEmpty;

    // The gap goes only between children that take up room, as a gap does in
    // a flex column: an unselected panel is not built, and a kept one is out
    // of the layout.
    final items = <Widget>[];
    var shown = false;
    for (final child in widget.children) {
      if (paged && child is PanelTabsContent) continue;
      final visible = child is! PanelTabsContent || child.value == value;
      items.add(
        Padding(
          key: child.key == null ? null : ValueKey<Key>(child.key!),
          padding: EdgeInsets.only(top: visible && shown ? _tabSetGap : 0),
          child: child,
        ),
      );
      if (visible) shown = true;
    }

    return _TabsScope(
      value: value,
      select: _select,
      variant: widget.variant,
      size: widget.size,
      keepMounted: widget.keepMounted,
      animated: widget.animated,
      child: paged
          ? _PagedColumn(
              pager: Padding(
                padding: EdgeInsets.only(top: shown ? _tabSetGap : 0),
                child: _TabsPager(
                  panels: panels,
                  value: value,
                  select: _select,
                  keepMounted: widget.keepMounted,
                  animated: widget.animated,
                ),
              ),
              children: items,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            ),
    );
  }
}

/// The row of triggers in a [PanelTabs], with the indicator that slides to
/// the selected one.
///
/// In a fixed row (the default) the triggers share the width equally. With
/// [scrollable] they keep their natural widths inside a horizontal scroller
/// instead, for more tabs than fit, and the row scrolls the selected one
/// into view whenever the selection changes.
///
/// The indicator measures the triggers as they are laid out, so its first
/// frame is already in place, and every move after that springs both its
/// position and its width.
class PanelTabsList extends StatefulWidget {
  /// Creates a tab list.
  const PanelTabsList({
    super.key,
    required this.children,
    this.scrollable = false,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.indicatorColor,
    this.indicatorThickness = 2,
    this.semanticLabel,
  });

  /// The [PanelTabsTrigger]s.
  final List<Widget> children;

  /// Lay the triggers out at their natural widths in a horizontal scroller
  /// instead of splitting the row between them, for more tabs than fit.
  final bool scrollable;

  /// Where triggers that keep their natural widths sit when the row is wider
  /// than they are, as in the `expanding` variant. Equal shares fill the row.
  final MainAxisAlignment mainAxisAlignment;

  /// Recolours the indicator: the chip in `segmented` and `pill`, the rule
  /// in `underline`. Pair it with [PanelTabsTrigger.activeLabelColor] so the
  /// label stays readable on it. `expanding` has no indicator; recolour its
  /// open pill with [PanelTabsTrigger.activeColor].
  final Color? indicatorColor;

  /// The thickness of the `underline` variant's rule.
  final double indicatorThickness;

  /// An accessible name for the row.
  final String? semanticLabel;

  @override
  State<PanelTabsList> createState() => _PanelTabsListState();
}

class _PanelTabsListState extends State<PanelTabsList>
    with TickerProviderStateMixin {
  late final AnimationController _indicatorLeft = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _indicatorWidth =
      AnimationController.unbounded(vsync: this);
  late final Listenable _indicatorMoved = Listenable.merge([
    _indicatorLeft,
    _indicatorWidth,
  ]);
  final _TabsRowGeometry _geometry = _TabsRowGeometry();
  final ScrollController _scroll = ScrollController();

  _TabsScope? _scope;
  bool _reduceMotion = false;
  bool _rtl = false;

  /// Whether the indicator has been placed once. Its first placement snaps:
  /// there is nothing to animate from.
  bool _placed = false;

  /// Where the indicator was last sent.
  Rect? _target;

  /// The selection and offset the scroller was last brought to.
  ({Object? value, double offset})? _scrolled;

  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _geometry.onLayout = _handleLayout;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final previous = _scope?.value;
    final scope = _scope = _TabsScope.of(context, 'PanelTabsList');
    _reduceMotion = panelReduceMotion(context);
    if (previous != scope.value) {
      // A press is answered at once, from the triggers as they were laid out
      // last frame. The end of the frame corrects the indicator if the row
      // has moved since, and brings the selection into view.
      if (_placed) _syncIndicator();
      _scheduleSync();
    }
  }

  @override
  void dispose() {
    _geometry.onLayout = null;
    _indicatorLeft.dispose();
    _indicatorWidth.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Where the selected trigger was laid out, or null before the row has
  /// been laid out or while no trigger is selected.
  Rect? get _selectedRect {
    final value = _scope?.value;
    final rects = _geometry.rects;
    final children = widget.children;
    for (var i = 0; i < children.length && i < rects.length; i++) {
      final child = children[i];
      if (child is PanelTabsTrigger && child.value == value) return rects[i];
    }
    return null;
  }

  /// Where the indicator is drawn: wherever it has been animated to once it
  /// has been placed, and on the selected trigger itself before that, so the
  /// first frame is already right.
  _IndicatorSpan? _indicatorSpan() {
    if (_placed) {
      return (
        left: _indicatorLeft.value,
        width: math.max(0.0, _indicatorWidth.value),
      );
    }
    final rect = _selectedRect;
    return rect == null ? null : (left: rect.left, width: rect.width);
  }

  /// Where the scroller puts the selected tab: a little in from the leading
  /// edge rather than flush against it, so it does not read as the last tab
  /// in the row.
  double _scrollOffsetFor(Rect rect) {
    final start = _rtl ? _geometry.size.width - rect.right : rect.left;
    return math.max(start - _scrollLeadIn, 0);
  }

  bool _sameSpan(Rect? a, Rect b) =>
      a != null && a.left == b.left && a.width == b.width;

  /// Runs during the row's layout, so anything that moves waits for the end
  /// of the frame.
  void _handleLayout() {
    if (_syncScheduled) return;
    final scope = _scope;
    final rect = _selectedRect;
    if (scope == null || rect == null) return;
    final indicatorStale =
        scope.variant != PanelTabsVariant.expanding &&
        (!_placed || !_sameSpan(_target, rect));
    final scrolled = _scrolled;
    final scrollStale =
        widget.scrollable &&
        (scrolled == null ||
            scrolled.value != scope.value ||
            scrolled.offset != _scrollOffsetFor(rect));
    if (indicatorStale || scrollStale) _scheduleSync();
  }

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      _syncIndicator();
      _syncScroll();
    });
  }

  void _syncIndicator() {
    final rect = _selectedRect;
    final scope = _scope;
    if (rect == null || scope == null) return;
    if (scope.variant == PanelTabsVariant.expanding) return;
    if (!_placed || !scope.animated || _reduceMotion) {
      _indicatorLeft.value = rect.left;
      _indicatorWidth.value = rect.width;
      _placed = true;
    } else if (!_sameSpan(_target, rect)) {
      _indicatorLeft.springTo(rect.left, PanelSprings.indicator);
      _indicatorWidth.springTo(rect.width, PanelSprings.indicator);
    }
    _target = rect;
  }

  void _syncScroll() {
    final value = _scope?.value;
    final rect = _selectedRect;
    if (!widget.scrollable || rect == null || !_scroll.hasClients) return;
    final offset = _scrollOffsetFor(rect);
    final scrolled = _scrolled;
    if (scrolled != null &&
        scrolled.value == value &&
        scrolled.offset == offset) {
      return;
    }
    final position = _scroll.position;
    final target = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    // The first placement has nowhere to travel from: animating it is a row
    // that visibly slides into place as the screen appears. The scroll is
    // not one of the animations `animated: false` turns off, as in PanelUI.
    if (scrolled == null || _reduceMotion) {
      position.jumpTo(target);
    } else {
      position.animateTo(
        target,
        duration: _scrollIntoViewDuration,
        curve: panelEase,
      );
    }
    _scrolled = (value: value, offset: offset);
  }

  /// The indicator for [variant]: a raised chip inside the segmented track,
  /// a rule on the underline's hairline, or a filled pill.
  _IndicatorPainter _indicatorPainter(
    PanelTabsVariant variant,
    PanelThemeData theme,
  ) {
    final c = theme.colors;
    final segmented = variant == PanelTabsVariant.segmented;
    return _IndicatorPainter(
      span: _indicatorSpan,
      repaint: _indicatorMoved,
      underline: variant == PanelTabsVariant.underline,
      color:
          widget.indicatorColor ??
          switch (variant) {
            PanelTabsVariant.segmented => c.popover,
            PanelTabsVariant.underline => c.foreground,
            _ => c.primary,
          },
      inset: segmented ? _trackPadding : 0,
      cornerRadius: segmented ? theme.radii.md : null,
      shadows: segmented ? theme.shadows.sm : const [],
      thickness: widget.indicatorThickness,
    );
  }

  /// What the row is drawn on: the recessed track of `segmented`, or the
  /// hairline of `underline`, which takes its own pixel of layout as a CSS
  /// border does.
  BoxDecoration? _trackDecoration(
    PanelTabsVariant variant,
    PanelThemeData theme,
  ) => switch (variant) {
    PanelTabsVariant.segmented => BoxDecoration(
      color: theme.colors.muted,
      borderRadius: BorderRadius.circular(theme.radii.lg),
    ),
    PanelTabsVariant.underline => BoxDecoration(
      border: Border(bottom: BorderSide(color: theme.colors.border)),
    ),
    PanelTabsVariant.pill || PanelTabsVariant.expanding => null,
  };

  @override
  Widget build(BuildContext context) {
    final variant = _scope!.variant;
    final theme = PanelTheme.of(context);
    _rtl = Directionality.of(context) == TextDirection.rtl;

    Widget row = _TabsRow(
      fit: !widget.scrollable && variant != PanelTabsVariant.expanding,
      gap: switch (variant) {
        PanelTabsVariant.segmented => 0,
        PanelTabsVariant.underline || PanelTabsVariant.pill => 4,
        PanelTabsVariant.expanding => 6,
      },
      padding: variant == PanelTabsVariant.segmented
          ? const EdgeInsets.all(_trackPadding)
          : EdgeInsets.zero,
      alignment: widget.mainAxisAlignment,
      geometry: _geometry,
      children: widget.children,
    );
    if (variant != PanelTabsVariant.expanding) {
      row = RepaintBoundary(
        child: CustomPaint(
          painter: _indicatorPainter(variant, theme),
          // Its own layer, so the indicator moving under the labels does not
          // repaint them.
          child: RepaintBoundary(child: row),
        ),
      );
    }
    final track = _trackDecoration(variant, theme);
    if (track != null) row = Container(decoration: track, child: row);

    final allTriggers =
        widget.children.isNotEmpty &&
        widget.children.every((child) => child is PanelTabsTrigger);
    row = Semantics(
      container: true,
      explicitChildNodes: true,
      role: allTriggers ? SemanticsRole.tabBar : null,
      label: widget.semanticLabel,
      child: row,
    );

    if (widget.scrollable) {
      // No scrollbar, as in PanelUI: the row is the indicator of its own
      // overflow, and a bar under a row of tabs reads as a second underline.
      row = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          child: row,
        ),
      );
    }

    return _TabsListScope(scrollable: widget.scrollable, child: row);
  }
}

/// One tab in a [PanelTabsList].
///
/// [child] is the label, usually a [Text], styled for the list's size and
/// coloured by the selection: muted until it is selected, or hovered with a
/// mouse. [icon] sits before it and [badge], a count or a dot, after it.
///
/// An icon keeps the muted colour PanelUI's icons are drawn in by default,
/// selected or not; give it a colour of its own to change that.
///
/// In the two smallest sizes a press up to 12pt (`xs`) or 8pt (`sm`) above or
/// below a trigger still reaches it, as far as the list's own bounds allow:
/// the row is drawn smaller than a finger, not pressed smaller.
class PanelTabsTrigger<T> extends StatelessWidget {
  /// Creates a trigger.
  const PanelTabsTrigger({
    super.key,
    required this.value,
    required this.child,
    this.icon,
    this.badge,
    this.enabled = true,
    this.labelColor,
    this.activeLabelColor,
    this.activeColor,
    this.semanticLabel,
  });

  /// Which tab this is. Matches a [PanelTabsContent.value].
  final T value;

  /// The label.
  final Widget child;

  /// Content before the label, usually a [PanelIcon]. Required in practice
  /// by the `expanding` variant, where it is all a closed tab shows.
  final Widget? icon;

  /// Content after the label: a count, a dot, a status.
  final Widget? badge;

  /// Whether the tab can be selected. A disabled tab is dimmed and announced
  /// as disabled.
  final bool enabled;

  /// The label's colour while the tab is not selected.
  final Color? labelColor;

  /// The label's colour while the tab is selected. Set it with
  /// [PanelTabsList.indicatorColor] so the text stays readable on the new
  /// indicator.
  final Color? activeLabelColor;

  /// In the `expanding` variant, the fill of the open pill. Defaults to the
  /// `surfaceTertiary` token, a step further from the page than the closed
  /// pills.
  final Color? activeColor;

  /// An accessible name, for a label that is not text.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scope = _TabsScope.of(context, 'PanelTabsTrigger');
    final active = scope.value == value;
    final scrollable = _TabsListScope.scrollableOf(context);
    if (scope.variant == PanelTabsVariant.expanding) {
      return _ExpandingTrigger(
        active: active,
        enabled: enabled,
        icon: icon,
        badge: badge,
        size: scope.size,
        animated: scope.animated,
        scrollable: scrollable,
        labelColor: labelColor,
        activeLabelColor: activeLabelColor,
        activeColor: activeColor,
        semanticLabel: semanticLabel,
        onPressed: () => scope.select(value),
        child: child,
      );
    }

    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final variant = scope.variant;
    final pill = variant == PanelTabsVariant.pill;
    final shape = pill ? _roundedFull : BorderRadius.circular(theme.radii.md);

    return PanelPressable(
      onPressed: enabled ? () => scope.select(value) : null,
      pressScale: 1,
      isButton: false,
      semanticRole: SemanticsRole.tab,
      selected: active,
      semanticLabel: semanticLabel,
      hitSlop: _triggerHitSlop(scope.size),
      focusRingRadius: shape,
      builder: (context, state) {
        final color = active
            ? activeLabelColor ?? (pill ? c.primaryForeground : c.foreground)
            : labelColor ?? (state.hovered ? c.foreground : c.mutedForeground);
        return Opacity(
          opacity: enabled ? 1 : _disabledOpacity,
          child: _HoverFill(
            variant: variant,
            active: active,
            hovered: state.hovered,
            shape: shape,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: scrollable ? _scrollerTriggerPaddingX : 0,
                vertical: _triggerPaddingY(variant, scope.size),
              ),
              child: Center(
                heightFactor: 1,
                child: _TriggerContent(
                  color: color,
                  size: scope.size,
                  icon: icon,
                  badge: badge,
                  label: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The panel shown while its tab is selected.
///
/// It arrives with a 150ms fade. Unless the tab set keeps its panels, a
/// panel is built only while selected, so whatever is inside starts afresh
/// each time it is shown.
class PanelTabsContent<T> extends StatefulWidget {
  /// Creates a panel.
  const PanelTabsContent({super.key, required this.value, required this.child});

  /// The tab this panel belongs to. Matches a [PanelTabsTrigger.value].
  final T value;

  /// The panel's content.
  final Widget child;

  @override
  State<PanelTabsContent<T>> createState() => _PanelTabsContentState<T>();
}

class _PanelTabsContentState<T> extends State<PanelTabsContent<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: PanelDurations.fadeIn,
    value: 1,
  );
  bool _wasShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update(_TabsScope.of(context, 'PanelTabsContent'));
  }

  @override
  void didUpdateWidget(PanelTabsContent<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final scope = context.getInheritedWidgetOfExactType<_TabsScope>();
    if (scope != null) _update(scope);
  }

  /// Fades the panel in when it is genuinely arriving: not one that was kept,
  /// which is already there, and not one in a swipeable strip, which slides.
  void _update(_TabsScope scope) {
    final inStrip = context.getInheritedWidgetOfExactType<_PagerSlot>() != null;
    final shown = scope.value == widget.value && !inStrip;
    if (shown && !_wasShown) {
      if (!scope.keepMounted && scope.animated && !panelReduceMotion(context)) {
        _fade.forward(from: 0);
      } else {
        _fade.value = 1;
      }
    }
    _wasShown = shown;
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _TabsScope.of(context, 'PanelTabsContent');
    final slot = context.dependOnInheritedWidgetOfExactType<_PagerSlot>();
    Widget panel = Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.tabPanel,
      child: widget.child,
    );

    // In a strip a panel does no hiding and no moving: the strip positions
    // it, and all that is left is to stay out of the way while off screen.
    if (slot != null) {
      return ExcludeSemantics(
        excluding: !slot.active,
        child: ExcludeFocus(excluding: !slot.active, child: panel),
      );
    }

    final active = scope.value == widget.value;
    if (!active && !scope.keepMounted) return const SizedBox.shrink();
    panel = FadeTransition(opacity: _fade, child: panel);
    if (scope.keepMounted) {
      panel = Visibility(visible: active, maintainState: true, child: panel);
    }
    return panel;
  }
}

/// The gap between the children of a tab set (`gap-3`).
const double _tabSetGap = 12;

/// The segmented track's padding around its triggers (`p-1`).
const double _trackPadding = 4;

/// A trigger's horizontal padding in a scroller (`px-4`), where it keeps its
/// natural width rather than taking a share of the row.
const double _scrollerTriggerPaddingX = 16;

/// The gap between a trigger's icon, label and badge (`gap-1.5`), and the
/// gap an expanding tab opens between its icon and its label.
const double _contentGap = 6;

/// The size icons in a trigger are drawn at unless they say otherwise, the
/// size PanelUI's icons default to.
const double _iconSize = 16;

/// A disabled trigger's opacity (`opacity-[0.44]`).
const double _disabledOpacity = 0.44;

/// Tailwind's `rounded-full`: a radius past any height, which a rounded
/// rectangle draws as a stadium.
const BorderRadius _roundedFull = BorderRadius.all(Radius.circular(999));

/// How far in from the leading edge the scroller brings the selected tab.
const double _scrollLeadIn = 24;

/// How long the scroller takes to bring the selected tab into view, the
/// length of a platform's own animated scroll.
const Duration _scrollIntoViewDuration = Duration(milliseconds: 300);

/// The label's colour change, as PanelUI's web tabs ease it
/// (`transition-colors duration-200`). The native tabs switch it at once;
/// one easing on every platform keeps a hover and a selection alike.
const Duration _labelColorDuration = Duration(milliseconds: 200);

/// The underline hover plate's fade (`before:transition-colors`, Tailwind's
/// default 150ms).
const Duration _underlineHoverDuration = Duration(milliseconds: 150);

/// Tailwind's default transition easing, `cubic-bezier(0.4, 0, 0.2, 1)`.
const Curve _webEase = Curves.fastOutSlowIn;

/// Where the underline hover plate sits inside its trigger (`inset-x-0.5
/// inset-y-1.5`): inside the row and clear of the rule.
const EdgeInsets _underlineHoverInset = EdgeInsets.symmetric(
  horizontal: 2,
  vertical: 6,
);

/// How much the underline hover plate keeps of the muted colour
/// (`bg-muted/70`).
const double _underlineHoverAlpha = 0.7;

/// How long an expanding tab takes to open its label, and the one before it
/// to close. A curve rather than a spring: this animates a width, and a
/// spring's overshoot would slide the last letter in, out and in again.
const Duration _expandDuration = Duration(milliseconds: 260);
const Curve _expandCurve = Cubic(0.2, 0, 0, 1);

/// The stretch of an expanding tab's opening over which its label fades in:
/// behind the width rather than ahead of it, so the text arrives instead of
/// being wiped on.
const double _revealFrom = 0.35;
const double _revealTo = 0.9;

/// Room after an expanding tab's label. PanelUI measures the label and gives
/// it two points over (`LABEL_SLACK`), so an open pill carries that much
/// past its text.
const double _labelSlack = 2;

/// A swipe activates once the finger has travelled this far sideways, and
/// gives up if it travels [_swipeFailY] up or down first. The window between
/// them lets a swipe start inside a vertically scrolling panel without
/// either gesture stealing the other.
const double _swipeActivateX = 12;
const double _swipeFailY = 8;

/// A swipe past this share of a panel's width changes tab on release.
const double _swipeDistanceRatio = 0.25;

/// …or past this speed, however short it was, in points per second.
const double _swipeVelocity = 500;

/// How much of the finger's travel the strip follows past either end, where
/// there is no further panel to bring on.
const double _swipeResistanceAtEnd = 0.16;

/// A trigger's vertical padding. Each variant has its own at `md` (`py-1.5`,
/// `py-2.5`, `py-2` and `py-2.5`), and each size either side of `md` adds or
/// takes away half a Tailwind step, as PanelUI's compound variants do.
double _triggerPaddingY(PanelTabsVariant variant, PanelTabsSize size) {
  final md = switch (variant) {
    PanelTabsVariant.segmented => 6.0,
    PanelTabsVariant.underline || PanelTabsVariant.expanding => 10.0,
    PanelTabsVariant.pill => 8.0,
  };
  return md + (size.index - PanelTabsSize.md.index) * 2;
}

/// An expanding pill's horizontal padding. In a scroller, PanelUI's `px-4`
/// replaces the `md` pill's own `px-3.5`; every other size sets its own in
/// the compound variants, which come later and win.
double _expandingPaddingX(PanelTabsSize size, {required bool scrollable}) =>
    switch (size) {
      PanelTabsSize.xs => 10,
      PanelTabsSize.sm => 12,
      PanelTabsSize.md => scrollable ? _scrollerTriggerPaddingX : 14,
      PanelTabsSize.lg => 16,
      PanelTabsSize.xl => 20,
    };

/// Room above and below a trigger of the two smallest sizes, so a row drawn
/// 20 or 24pt tall is still pressed like a taller one. Vertical only: the
/// triggers sit edge to edge, and slop to the side would take a neighbour's
/// presses.
EdgeInsets? _triggerHitSlop(PanelTabsSize size) => switch (size) {
  PanelTabsSize.xs => const EdgeInsets.symmetric(vertical: 12),
  PanelTabsSize.sm => const EdgeInsets.symmetric(vertical: 8),
  _ => null,
};

TextStyle _labelStyle(PanelTypography type, PanelTabsSize size, Color color) {
  const weight = FontWeight.w500;
  final step = switch (size) {
    PanelTabsSize.xs => PanelTextSize.xs,
    // `text-[13px]`, a size with no paired line height.
    PanelTabsSize.sm => null,
    PanelTabsSize.md => PanelTextSize.sm,
    PanelTabsSize.lg => PanelTextSize.base,
    PanelTabsSize.xl => PanelTextSize.lg,
  };
  return step == null
      ? type.sized(13, weight: weight, color: color)
      : type.style(step, weight: weight, color: color);
}

/// Springs [controller] to [target] from [velocity] rather than from the
/// controller's own: a drag sets the strip's value directly, so it has none
/// to carry, and a throw has to keep the finger's speed.
TickerFuture _springFrom(
  AnimationController controller,
  double target,
  double velocity,
) {
  return controller.animateWith(
    SpringSimulation(
      PanelSprings.strip,
      controller.value,
      target,
      velocity,
      tolerance: const Tolerance(distance: 0.0005, velocity: 0.005),
      snapToEnd: true,
    ),
  );
}

class _TabsScope extends InheritedWidget {
  const _TabsScope({
    required this.value,
    required this.select,
    required this.variant,
    required this.size,
    required this.keepMounted,
    required this.animated,
    required super.child,
  });

  final Object? value;
  final ValueChanged<Object?> select;
  final PanelTabsVariant variant;
  final PanelTabsSize size;
  final bool keepMounted;
  final bool animated;

  static _TabsScope of(BuildContext context, String part) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TabsScope>();
    if (scope == null) {
      throw FlutterError('$part must be used inside a PanelTabs.');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(_TabsScope oldWidget) =>
      value != oldWidget.value ||
      select != oldWidget.select ||
      variant != oldWidget.variant ||
      size != oldWidget.size ||
      keepMounted != oldWidget.keepMounted ||
      animated != oldWidget.animated;
}

/// Whether the triggers below sit in a scroller, published by their list so
/// a trigger's width and the row it is measured in agree in the same frame.
class _TabsListScope extends InheritedWidget {
  const _TabsListScope({required this.scrollable, required super.child});

  final bool scrollable;

  static bool scrollableOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_TabsListScope>()
          ?.scrollable ??
      false;

  @override
  bool updateShouldNotify(_TabsListScope oldWidget) =>
      scrollable != oldWidget.scrollable;
}

/// A tab set's column when its panels are in a strip. The strip fills a
/// height the tab set is given and is as tall as its tallest panel when it
/// is given none, which is a question only the incoming constraints answer.
class _PagedColumn extends StatelessWidget {
  const _PagedColumn({required this.children, required this.pager});

  final List<Widget> children;
  final Widget pager;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fill = constraints.hasBoundedHeight;
        return Column(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...children,
            // Always a Flexible, so the strip keeps its state when the
            // height it is offered comes and goes.
            Flexible(flex: fill ? 1 : 0, fit: FlexFit.tight, child: pager),
          ],
        );
      },
    );
  }
}

/// A trigger's icon, label and badge, with the label coloured for its state.
class _TriggerContent extends StatelessWidget {
  const _TriggerContent({
    required this.color,
    required this.size,
    required this.icon,
    required this.badge,
    required this.label,
  });

  final Color color;
  final PanelTabsSize size;
  final Widget? icon;
  final Widget? badge;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return IconTheme(
      data: IconThemeData(color: theme.colors.mutedForeground, size: _iconSize),
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: panelReduceMotion(context)
            ? Duration.zero
            : _labelColorDuration,
        curve: _webEase,
        builder: (context, color, row) => DefaultTextStyle(
          style: _labelStyle(theme.typography, size, color!),
          textAlign: TextAlign.center,
          child: row!,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _contentGap,
          children: [
            ?icon,
            Flexible(child: label),
            ?badge,
          ],
        ),
      ),
    );
  }
}

/// The web package's hover fill behind a trigger: a muted plate inside an
/// underline row, clear of its rule, and a muted pill behind an unselected
/// pill. A segmented trigger has none.
class _HoverFill extends StatelessWidget {
  const _HoverFill({
    required this.variant,
    required this.active,
    required this.hovered,
    required this.shape,
    required this.child,
  });

  final PanelTabsVariant variant;
  final bool active;
  final bool hovered;
  final BorderRadius shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final muted = theme.colors.muted;
    final clear = muted.withValues(alpha: 0);
    final reduce = panelReduceMotion(context);
    switch (variant) {
      case PanelTabsVariant.underline:
        return Stack(
          // Passed through, so a trigger stretched past its label keeps its
          // size and still centres it.
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: Padding(
                padding: _underlineHoverInset,
                child: AnimatedContainer(
                  duration: reduce ? Duration.zero : _underlineHoverDuration,
                  curve: _webEase,
                  decoration: BoxDecoration(
                    color: hovered
                        ? muted.withValues(
                            alpha: muted.a * _underlineHoverAlpha,
                          )
                        : clear,
                    borderRadius: BorderRadius.circular(theme.radii.md),
                  ),
                ),
              ),
            ),
            child,
          ],
        );
      case PanelTabsVariant.pill:
        return AnimatedContainer(
          duration: reduce ? Duration.zero : _labelColorDuration,
          curve: _webEase,
          decoration: BoxDecoration(
            color: hovered && !active ? muted : clear,
            borderRadius: shape,
          ),
          child: child,
        );
      case PanelTabsVariant.segmented:
      case PanelTabsVariant.expanding:
        return child;
    }
  }
}

/// A tab that is an icon until it is selected, and then an icon and its
/// label.
///
/// The label is never removed, only closed over: a screen reader walking a
/// row of icons still has something to read, and a label that is always
/// there has a width to open from.
class _ExpandingTrigger extends StatefulWidget {
  const _ExpandingTrigger({
    required this.active,
    required this.enabled,
    required this.icon,
    required this.badge,
    required this.size,
    required this.animated,
    required this.scrollable,
    required this.labelColor,
    required this.activeLabelColor,
    required this.activeColor,
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
  });

  final bool active;
  final bool enabled;
  final Widget? icon;
  final Widget? badge;
  final PanelTabsSize size;
  final bool animated;
  final bool scrollable;
  final Color? labelColor;
  final Color? activeLabelColor;
  final Color? activeColor;
  final String? semanticLabel;
  final VoidCallback onPressed;
  final Widget child;

  @override
  State<_ExpandingTrigger> createState() => _ExpandingTriggerState();
}

class _ExpandingTriggerState extends State<_ExpandingTrigger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    value: widget.active ? 1 : 0,
  );

  @override
  void didUpdateWidget(_ExpandingTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    final target = widget.active ? 1.0 : 0.0;
    if (!widget.animated || panelReduceMotion(context)) {
      _open.value = target;
    } else {
      _open.animateTo(target, duration: _expandDuration, curve: _expandCurve);
    }
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final labelColor = widget.active
        ? widget.activeLabelColor ?? c.foreground
        : widget.labelColor ?? c.mutedForeground;

    return PanelPressable(
      onPressed: widget.enabled ? widget.onPressed : null,
      pressScale: 1,
      isButton: false,
      semanticRole: SemanticsRole.tab,
      selected: widget.active,
      semanticLabel: widget.semanticLabel,
      focusRingRadius: _roundedFull,
      child: Opacity(
        opacity: widget.enabled ? 1 : _disabledOpacity,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _expandingPaddingX(
              widget.size,
              scrollable: widget.scrollable,
            ),
            vertical: _triggerPaddingY(PanelTabsVariant.expanding, widget.size),
          ),
          decoration: BoxDecoration(
            color: widget.active
                ? widget.activeColor ?? c.surfaceTertiary
                : c.muted,
            borderRadius: _roundedFull,
          ),
          child: IconTheme(
            data: IconThemeData(color: c.mutedForeground, size: _iconSize),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?widget.icon,
                _LabelReveal(
                  open: _open,
                  child: DefaultTextStyle(
                    style: _labelStyle(
                      theme.typography,
                      widget.size,
                      labelColor,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    child: widget.child,
                  ),
                ),
                ?widget.badge,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An expanding tab's label, opened to [open] of its width.
///
/// The box opens to the label's own width, so the text never reflows on its
/// way in or out.
class _LabelReveal extends StatelessWidget {
  const _LabelReveal({required this.open, required this.child});

  final Animation<double> open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: open,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: _contentGap,
          end: _labelSlack,
        ),
        child: child,
      ),
      builder: (context, label) {
        final t = open.value;
        return ClipRect(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: t,
            child: Opacity(
              opacity: ((t - _revealFrom) / (_revealTo - _revealFrom)).clamp(
                0.0,
                1.0,
              ),
              // Read out while closed: a tab announced as an unlabelled icon
              // is a tab nobody can choose.
              alwaysIncludeSemantics: true,
              child: label,
            ),
          ),
        );
      },
    );
  }
}

/// Where the indicator is drawn along the row.
typedef _IndicatorSpan = ({double left, double width});

/// Paints the indicator under the triggers, at the span the list hands it.
class _IndicatorPainter extends CustomPainter {
  _IndicatorPainter({
    required this.span,
    required Listenable repaint,
    required this.underline,
    required this.color,
    required this.inset,
    required this.cornerRadius,
    required this.shadows,
    required this.thickness,
  }) : super(repaint: repaint);

  final _IndicatorSpan? Function() span;
  final bool underline;
  final Color color;

  /// How far the chip stays from the row's top and bottom edges: the track's
  /// padding in `segmented`.
  final double inset;

  /// Null rounds the ends fully.
  final double? cornerRadius;
  final List<BoxShadow> shadows;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final span = this.span();
    if (span == null) return;
    final rect = underline
        // The rule's bottom edge is the bottom of the list's 1pt hairline
        // under this row (`-bottom-px`), so it sits on the line.
        ? Rect.fromLTWH(
            span.left,
            size.height + 1 - thickness,
            span.width,
            thickness,
          )
        : Rect.fromLTRB(
            span.left,
            inset,
            span.left + span.width,
            size.height - inset,
          );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cornerRadius ?? rect.shortestSide / 2),
    );
    for (final shadow in shadows) {
      canvas.drawRRect(
        rrect.shift(shadow.offset).inflate(shadow.spreadRadius),
        shadow.toPaint(),
      );
    }
    canvas.drawRRect(rrect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_IndicatorPainter oldDelegate) =>
      oldDelegate.span != span ||
      oldDelegate.underline != underline ||
      oldDelegate.color != color ||
      oldDelegate.inset != inset ||
      oldDelegate.cornerRadius != cornerRadius ||
      !listEquals(oldDelegate.shadows, shadows) ||
      oldDelegate.thickness != thickness;
}

/// Where the row last laid its triggers out, shared between the row's render
/// object (which writes it) and the list (which reads it).
class _TabsRowGeometry {
  List<Rect> rects = const [];
  Size size = Size.zero;
  VoidCallback? onLayout;
}

class _TabsRowParentData extends ContainerBoxParentData<RenderBox> {}

/// A row of triggers inside [padding]: equal shares of a bounded width when
/// [fit], natural widths otherwise, every trigger as tall as the tallest. It
/// records where each trigger landed for the indicator.
///
/// The padding is the row's own rather than a wrapper's, so a trigger's hit
/// slop reaches into it, as it reaches into PanelUI's padded list.
class _TabsRow extends MultiChildRenderObjectWidget {
  const _TabsRow({
    required this.fit,
    required this.gap,
    required this.padding,
    required this.alignment,
    required this.geometry,
    required super.children,
  });

  final bool fit;
  final double gap;
  final EdgeInsets padding;
  final MainAxisAlignment alignment;
  final _TabsRowGeometry geometry;

  @override
  _RenderTabsRow createRenderObject(BuildContext context) => _RenderTabsRow(
    fit: fit,
    gap: gap,
    padding: padding,
    alignment: alignment,
    geometry: geometry,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderTabsRow renderObject) {
    renderObject
      ..fit = fit
      ..gap = gap
      ..padding = padding
      ..alignment = alignment
      ..geometry = geometry
      ..textDirection = Directionality.of(context);
  }
}

class _RenderTabsRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TabsRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TabsRowParentData> {
  _RenderTabsRow({
    required bool fit,
    required double gap,
    required EdgeInsets padding,
    required MainAxisAlignment alignment,
    required _TabsRowGeometry geometry,
    required TextDirection textDirection,
  }) : _fit = fit,
       _gap = gap,
       _padding = padding,
       _alignment = alignment,
       _geometry = geometry,
       _textDirection = textDirection;

  bool get fit => _fit;
  bool _fit;
  set fit(bool value) {
    if (value == _fit) return;
    _fit = value;
    markNeedsLayout();
  }

  double get gap => _gap;
  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  EdgeInsets get padding => _padding;
  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    if (value == _padding) return;
    _padding = value;
    markNeedsLayout();
  }

  MainAxisAlignment get alignment => _alignment;
  MainAxisAlignment _alignment;
  set alignment(MainAxisAlignment value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsLayout();
  }

  _TabsRowGeometry get geometry => _geometry;
  _TabsRowGeometry _geometry;
  set geometry(_TabsRowGeometry value) {
    if (identical(value, _geometry)) return;
    _geometry = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TabsRowParentData) {
      child.parentData = _TabsRowParentData();
    }
  }

  /// The share each trigger gets of [width] in a fixed row, or null when the
  /// triggers keep their natural widths.
  double? _shareOf(double width, int count) {
    if (!fit || !width.isFinite) return null;
    final inner = width - padding.horizontal - gap * (count - 1);
    return math.max(0.0, inner / count);
  }

  double _intrinsicWidth(double Function(RenderBox child) measure) {
    final children = getChildrenAsList();
    if (children.isEmpty) return padding.horizontal;
    final widths = children.map(measure);
    final content = fit
        ? widths.reduce(math.max) * children.length
        : widths.reduce((a, b) => a + b);
    return content + gap * (children.length - 1) + padding.horizontal;
  }

  double _intrinsicHeight(
    double width,
    double Function(RenderBox child, double width) measure,
  ) {
    final children = getChildrenAsList();
    final share = _shareOf(width, children.length) ?? double.infinity;
    var tallest = 0.0;
    for (final child in children) {
      tallest = math.max(tallest, measure(child, share));
    }
    return tallest + padding.vertical;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMaxIntrinsicWidth(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _intrinsicHeight(width, (child, w) => child.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _intrinsicHeight(width, (child, w) => child.getMaxIntrinsicHeight(w));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  /// Lays the triggers out (or, with [dry], only measures them) and works
  /// out where each one goes.
  ({Size size, List<Rect> rects}) _layout(
    BoxConstraints constraints, {
    required bool dry,
  }) {
    final children = getChildrenAsList();
    final count = children.length;
    if (count == 0) {
      return (
        size: constraints.constrain(Size(padding.horizontal, padding.vertical)),
        rects: const <Rect>[],
      );
    }
    final share = _shareOf(constraints.maxWidth, count);
    final natural = share == null
        ? const BoxConstraints()
        : BoxConstraints.tightFor(width: share);
    final sizes = [
      for (final child in children)
        dry
            ? child.getDryLayout(natural)
            : (child..layout(natural, parentUsesSize: true)).size,
    ];
    final tallest = sizes.fold(
      0.0,
      (most, size) => math.max(most, size.height),
    );
    final height = math.max(
      0.0,
      constraints.constrainHeight(tallest + padding.vertical) -
          padding.vertical,
    );

    // Every trigger as tall as the row, as a flex row stretches them. Only
    // the shorter ones are laid out again, with a minimum rather than a
    // tight height: a trigger laid out tight becomes a relayout boundary,
    // and one that then changes its own size (an expanding label opening)
    // would never tell the row.
    if (!dry) {
      for (var i = 0; i < count; i++) {
        if (sizes[i].height >= height) continue;
        children[i].layout(
          BoxConstraints(
            minWidth: sizes[i].width,
            maxWidth: share ?? double.infinity,
            minHeight: height,
          ),
          parentUsesSize: true,
        );
      }
    }

    final widths = [for (final size in sizes) share ?? size.width];
    final content =
        widths.reduce((a, b) => a + b) + gap * (count - 1) + padding.horizontal;
    final size = constraints.constrain(
      Size(content, height + padding.vertical),
    );
    final free = math.max(0.0, size.width - content);
    var lead = 0.0;
    var between = gap;
    switch (alignment) {
      case MainAxisAlignment.start:
        break;
      case MainAxisAlignment.end:
        lead = free;
      case MainAxisAlignment.center:
        lead = free / 2;
      case MainAxisAlignment.spaceBetween:
        if (count > 1) between += free / (count - 1);
      case MainAxisAlignment.spaceAround:
        lead = free / count / 2;
        between += free / count;
      case MainAxisAlignment.spaceEvenly:
        lead = free / (count + 1);
        between += free / (count + 1);
    }

    final rtl = textDirection == TextDirection.rtl;
    final rects = <Rect>[];
    var x = padding.left + lead;
    for (final width in widths) {
      final left = rtl ? size.width - x - width : x;
      rects.add(Rect.fromLTWH(left, padding.top, width, height));
      x += width + between;
    }
    return (size: size, rects: rects);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true).size;

  @override
  void performLayout() {
    final result = _layout(constraints, dry: false);
    size = result.size;
    var index = 0;
    var child = firstChild;
    while (child != null) {
      (child.parentData! as _TabsRowParentData).offset =
          result.rects[index].topLeft;
      index++;
      child = childAfter(child);
    }
    geometry
      ..rects = result.rects
      ..size = size;
    geometry.onLayout?.call();
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// The panels side by side, behind a window one panel wide.
///
/// Everything about the movement lives on one value, measured in panels
/// rather than points: a drag sets it, a press springs it, and it is the only
/// thing that says where the strip is.
class _TabsPager extends StatefulWidget {
  const _TabsPager({
    required this.panels,
    required this.value,
    required this.select,
    required this.keepMounted,
    required this.animated,
  });

  final List<PanelTabsContent<Object?>> panels;
  final Object? value;
  final ValueChanged<Object?> select;
  final bool keepMounted;
  final bool animated;

  @override
  State<_TabsPager> createState() => _TabsPagerState();
}

class _TabsPagerState extends State<_TabsPager>
    with SingleTickerProviderStateMixin {
  int _lastResolved = 0;
  late int _active = _resolve();
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: _active.toDouble(),
  );

  /// Which panels have been built. It only grows, so a tab is slow at most
  /// once.
  late final Set<int> _reached = {_active};

  /// The tab a swipe has already sprung the strip to, so the change it
  /// reports does not restart the movement from rest.
  int? _sprungTo;

  double _width = 0;
  bool _rtl = false;
  bool _dragging = false;
  double _start = 0;
  double _travel = 0;
  bool _neighboursScheduled = false;

  bool get _still => !widget.animated || panelReduceMotion(context);

  double get _sign => _rtl ? -1 : 1;

  /// The selected panel, or the last one that resolved: a value missing for
  /// a moment (a controlled parent part-way through an update) holds the
  /// panel that was there instead of springing to the first and back.
  int _resolve() {
    final index = widget.panels.indexWhere((p) => p.value == widget.value);
    if (index >= 0) {
      _lastResolved = index;
      return index;
    }
    return math.min(_lastResolved, widget.panels.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _scheduleNeighbours();
  }

  @override
  void didUpdateWidget(_TabsPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _active;
    _active = _resolve();
    _reached
      ..removeWhere((index) => index >= widget.panels.length)
      ..add(_active);
    if (_active != previous ||
        widget.panels.length != oldWidget.panels.length ||
        widget.keepMounted != oldWidget.keepMounted) {
      _scheduleNeighbours();
    }
    if (_active == previous) return;

    final already = _sprungTo;
    _sprungTo = null;
    if (already == _active) return;
    if (_still || _width == 0) {
      _position.value = _active.toDouble();
    } else {
      _position.springTo(_active.toDouble(), PanelSprings.strip);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  /// Builds the neighbours of the selected panel (or every panel, when they
  /// are kept) a frame after it, so the frame the tab set first appears on
  /// carries one panel's work and not three.
  void _scheduleNeighbours() {
    if (_neighboursScheduled) return;
    _neighboursScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _neighboursScheduled = false;
      if (!mounted) return;
      final count = widget.panels.length;
      final wanted = widget.keepMounted
          ? [for (var i = 0; i < count; i++) i]
          : [_active - 1, _active + 1].where((i) => i >= 0 && i < count);
      final missing = wanted.where((i) => !_reached.contains(i)).toList();
      if (missing.isNotEmpty) setState(() => _reached.addAll(missing));
    });
  }

  void _handleDragStart(DragStartDetails details) {
    // Rounded, so a drag begun while the last one is still settling starts
    // from the tab it is settling on.
    _dragging = true;
    _position.stop();
    _start = _position.value.roundToDouble();
    _travel = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragging || _width == 0) return;
    _travel += details.delta.dx;
    final last = widget.panels.length - 1;
    final raw = _start - (_travel * _sign) / _width;
    // Past either end there is no panel to bring on, so the strip gives a
    // little and then stops, rather than pulling a blank into view.
    if (raw < 0) {
      _position.value = raw * _swipeResistanceAtEnd;
    } else if (raw > last) {
      _position.value = last + (raw - last) * _swipeResistanceAtEnd;
    } else {
      _position.value = raw;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    if (_width == 0) return;
    final last = widget.panels.length - 1;
    final from = _start;
    final moved = _position.value - from;
    final velocity = details.velocity.pixelsPerSecond.dx;
    // Points per second become panels per second, the unit the spring that
    // finishes the movement works in.
    final speed = (-velocity * _sign) / _width;

    // Speed first: a flick back the way it came reads as a cancel however
    // far it had already got.
    var target = from;
    if (velocity.abs() > _swipeVelocity) {
      target = from + (speed > 0 ? 1 : -1);
    } else if (moved.abs() > _swipeDistanceRatio) {
      target = from + (moved > 0 ? 1 : -1);
    }
    target = target.clamp(0, last).toDouble();

    if (_still) {
      _position.value = target;
    } else {
      _springFrom(_position, target, speed);
    }
    final index = target.round();
    if (index != from.round()) {
      final next = widget.panels[index].value;
      if (next != widget.value) {
        _sprungTo = index;
        widget.select(next);
      }
    }
  }

  void _handleDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    if (_still) {
      _position.value = _start;
    } else {
      _position.springTo(_start, PanelSprings.strip);
    }
  }

  @override
  Widget build(BuildContext context) {
    _rtl = Directionality.of(context) == TextDirection.rtl;
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        _StripDragRecognizer:
            GestureRecognizerFactoryWithHandlers<_StripDragRecognizer>(
              () => _StripDragRecognizer(debugOwner: this),
              (recognizer) => recognizer
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd
                ..onCancel = _handleDragCancel,
            ),
      },
      child: _PagerStrip(
        position: _position,
        onWidth: (width) => _width = width,
        children: [
          for (var i = 0; i < widget.panels.length; i++)
            _PagerSlot(
              key: ValueKey<Object?>(widget.panels[i].value),
              active: i == _active,
              // Each panel its own layer, so moving the strip moves layers
              // rather than repainting what is on them.
              child: RepaintBoundary(
                child: _reached.contains(i)
                    ? widget.panels[i]
                    : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}

/// A sideways drag on the strip, with PanelUI's activation window: it takes
/// the gesture once the finger has travelled [_swipeActivateX] sideways, and
/// gives it up if the finger travels [_swipeFailY] up or down first, so a
/// vertical scroll in or around a panel keeps its drags.
class _StripDragRecognizer extends HorizontalDragGestureRecognizer {
  _StripDragRecognizer({super.debugOwner}) {
    // Even with nothing else wanting the pointer, the drag starts only past
    // the threshold, so a vertical drag can still give it up.
    onlyAcceptDragOnThreshold = true;
    // Reported from touch-down, so the strip catches up with the finger the
    // moment it takes the drag, as PanelUI's translation does.
    dragStartBehavior = DragStartBehavior.down;
  }

  final Map<int, double> _downY = {};
  bool _activated = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _downY[event.pointer] = event.position.dy;
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    if (globalDistanceMoved.abs() > _swipeActivateX) _activated = true;
    return _activated;
  }

  @override
  void handleEvent(PointerEvent event) {
    final downY = _downY[event.pointer];
    if (!_activated &&
        event is PointerMoveEvent &&
        downY != null &&
        (event.position.dy - downY).abs() > _swipeFailY) {
      // Gives the pointer up the way the arena would.
      rejectGesture(event.pointer);
      return;
    }
    super.handleEvent(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _activated = false;
    _downY.clear();
    super.didStopTrackingLastPointer(pointer);
  }
}

/// Marks a panel as sitting in a swipeable strip, and whether it is the one
/// in view.
class _PagerSlot extends InheritedWidget {
  const _PagerSlot({super.key, required this.active, required super.child});

  final bool active;

  @override
  bool updateShouldNotify(_PagerSlot oldWidget) => active != oldWidget.active;
}

class _StripParentData extends ContainerBoxParentData<RenderBox> {}

/// Lays every panel out one window wide and as tall as the tallest (or as
/// tall as the height it is given), and draws them side by side, shifted by
/// [position] panels.
class _PagerStrip extends MultiChildRenderObjectWidget {
  const _PagerStrip({
    required this.position,
    required this.onWidth,
    required super.children,
  });

  final Animation<double> position;
  final ValueChanged<double> onWidth;

  @override
  _RenderPagerStrip createRenderObject(BuildContext context) =>
      _RenderPagerStrip(
        position: position,
        onWidth: onWidth,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPagerStrip renderObject,
  ) {
    renderObject
      ..position = position
      ..onWidth = onWidth
      ..textDirection = Directionality.of(context);
  }
}

class _RenderPagerStrip extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StripParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StripParentData> {
  _RenderPagerStrip({
    required Animation<double> position,
    required this.onWidth,
    required TextDirection textDirection,
  }) : _position = position,
       _textDirection = textDirection;

  Animation<double> get position => _position;
  Animation<double> _position;
  set position(Animation<double> value) {
    if (value == _position) return;
    if (attached) _position.removeListener(_moved);
    _position = value;
    if (attached) _position.addListener(_moved);
    _moved();
  }

  ValueChanged<double> onWidth;

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    _moved();
  }

  final LayerHandle<ClipRectLayer> _clip = LayerHandle<ClipRectLayer>();

  /// The strip moves on every frame of a swipe; as its own repaint boundary
  /// that repaints nothing around it.
  @override
  bool get isRepaintBoundary => true;

  void _moved() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _position.addListener(_moved);
  }

  @override
  void detach() {
    _position.removeListener(_moved);
    super.detach();
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StripParentData) {
      child.parentData = _StripParentData();
    }
  }

  double _shift(int index) {
    final shift = (index - _position.value) * size.width;
    return _textDirection == TextDirection.rtl ? -shift : shift;
  }

  int _indexOf(RenderBox target) {
    var index = 0;
    var child = firstChild;
    while (child != null && child != target) {
      index++;
      child = childAfter(child);
    }
    return index;
  }

  double _windowWidth(BoxConstraints constraints) =>
      constraints.hasBoundedWidth ? constraints.maxWidth : constraints.minWidth;

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final width = _windowWidth(constraints);
    final children = getChildrenAsList();
    if (constraints.hasTightHeight) {
      final tight = BoxConstraints.tightFor(
        width: width,
        height: constraints.maxHeight,
      );
      if (!dry) {
        for (final child in children) {
          child.layout(tight);
        }
      }
      return constraints.constrain(Size(width, constraints.maxHeight));
    }

    final natural = BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: constraints.maxHeight,
    );
    final heights = [
      for (final child in children)
        dry
            ? child.getDryLayout(natural).height
            : (child..layout(natural, parentUsesSize: true)).size.height,
    ];
    final height = constraints.constrainHeight(
      heights.fold(constraints.minHeight, math.max),
    );
    // The shorter panels are stretched to the tallest with a minimum rather
    // than a tight height, so a panel whose content grows still makes the
    // strip grow with it.
    if (!dry) {
      for (var i = 0; i < children.length; i++) {
        if (heights[i] >= height) continue;
        children[i].layout(
          BoxConstraints(minWidth: width, maxWidth: width, minHeight: height),
          parentUsesSize: true,
        );
      }
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() {
    onWidth(_windowWidth(constraints));
    size = _layout(constraints, dry: false);
  }

  double _tallestIntrinsic(double Function(RenderBox child) measure) =>
      getChildrenAsList().map(measure).fold(0.0, math.max);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _tallestIntrinsic((child) => child.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _tallestIntrinsic((child) => child.getMaxIntrinsicHeight(width));

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      _paintPanels,
      oldLayer: _clip.layer,
    );
  }

  void _paintPanels(PaintingContext context, Offset offset) {
    var index = 0;
    var child = firstChild;
    while (child != null) {
      final dx = _shift(index);
      if (dx > -size.width && dx < size.width) {
        context.paintChild(child, offset + Offset(dx, 0));
      }
      index++;
      child = childAfter(child);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var index = childCount - 1;
    var child = lastChild;
    while (child != null) {
      final current = child;
      final hit = result.addWithPaintOffset(
        offset: Offset(_shift(index), 0),
        position: position,
        hitTest: (result, transformed) =>
            current.hitTest(result, position: transformed),
      );
      if (hit) return true;
      index--;
      child = childBefore(child);
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(_shift(_indexOf(child)), 0, 0, 1);
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) => Offset.zero & size;
}
