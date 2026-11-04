import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
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

/// A swipe past this share of a panel's width changes tab on release.
const double _swipeDistanceRatio = 0.25;

/// …or past this speed, however short it was, in points per second.
const double _swipeVelocity = 500;

/// How much of the finger's travel the strip follows past either end.
const double _swipeResistanceAtEnd = 0.16;

/// The gap between an expanding tab's icon and its label, which is part of
/// what opens.
const double _labelGap = 6;

/// How long an expanding tab takes to open its label, and the one before it
/// to close. A curve rather than a spring: this animates a width, and a
/// spring's overshoot would slide the last letter in, out and in again.
const Duration _expandDuration = Duration(milliseconds: 260);
const Curve _expandCurve = Cubic(0.2, 0, 0, 1);

/// The label's colour change, as PanelUI's web tabs `transition-colors`.
const Duration _labelColorDuration = Duration(milliseconds: 200);

/// Vertical padding of a trigger, by variant and then by size.
const Map<PanelTabsVariant, List<double>> _triggerPadding = {
  PanelTabsVariant.segmented: [2, 4, 6, 8, 10],
  PanelTabsVariant.underline: [6, 8, 10, 12, 14],
  PanelTabsVariant.pill: [4, 6, 8, 10, 12],
  PanelTabsVariant.expanding: [6, 8, 10, 12, 14],
};

/// Horizontal padding of an expanding pill.
double _expandingPadding(PanelTabsSize size, bool scrollable) {
  switch (size) {
    case PanelTabsSize.xs:
      return 10;
    case PanelTabsSize.sm:
      return 12;
    case PanelTabsSize.md:
      // PanelUI's scroller padding (`px-4`) wins over the pill's own at the
      // one size with no padding of its own in the compound table.
      return scrollable ? 16 : 14;
    case PanelTabsSize.lg:
      return 16;
    case PanelTabsSize.xl:
      return 20;
  }
}

TextStyle _labelStyle(PanelTypography type, PanelTabsSize size, Color color) {
  const weight = FontWeight.w500;
  switch (size) {
    case PanelTabsSize.xs:
      return type.style(PanelTextSize.xs, weight: weight, color: color);
    case PanelTabsSize.sm:
      return type.sized(13, weight: weight, color: color);
    case PanelTabsSize.md:
      return type.style(PanelTextSize.sm, weight: weight, color: color);
    case PanelTabsSize.lg:
      return type.style(PanelTextSize.base, weight: weight, color: color);
    case PanelTabsSize.xl:
      return type.style(PanelTextSize.lg, weight: weight, color: color);
  }
}

Color _fade(Color color, double factor) =>
    color.withValues(alpha: color.a * factor);

/// Springs [controller] to [target] starting at [velocity] rather than at the
/// controller's own, for a strip released by a finger that was moving it.
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
    final List<PanelTabsContent<Object?>> panels = widget.swipeable
        ? [
            for (final child in widget.children)
              if (child is PanelTabsContent) child,
          ]
        : const [];
    final paged = panels.isNotEmpty;

    // The 12pt gap goes only between children that take up room, as a gap
    // does in PanelUI's flex column: an unselected panel is not there at all,
    // and a kept one is out of the layout.
    final items = <Widget>[];
    var shown = false;
    for (final child in widget.children) {
      if (paged && child is PanelTabsContent) continue;
      final visible = child is! PanelTabsContent || child.value == value;
      items.add(
        Padding(
          key: child.key == null ? null : ValueKey<Key>(child.key!),
          padding: EdgeInsets.only(top: visible && shown ? 12 : 0),
          child: child,
        ),
      );
      if (visible) shown = true;
    }

    Widget body;
    if (paged) {
      final pager = Padding(
        padding: EdgeInsets.only(top: shown ? 12 : 0),
        child: _TabsPager(
          panels: panels,
          value: value,
          select: _select,
          keepMounted: widget.keepMounted,
          animated: widget.animated,
        ),
      );
      body = LayoutBuilder(
        builder: (context, constraints) {
          final fill = constraints.hasBoundedHeight;
          return Column(
            mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...items,
              Flexible(flex: fill ? 1 : 0, fit: FlexFit.tight, child: pager),
            ],
          );
        },
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      );
    }

    return _TabsScope(
      value: value,
      select: _select,
      variant: widget.variant,
      size: widget.size,
      keepMounted: widget.keepMounted,
      animated: widget.animated,
      child: body,
    );
  }
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
  late final AnimationController _x = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _w = AnimationController.unbounded(
    vsync: this,
  );
  late final Listenable _repaint = Listenable.merge([_x, _w]);
  final _TabsRowGeometry _geometry = _TabsRowGeometry();
  final ScrollController _scroll = ScrollController();

  _TabsScope? _scope;
  bool _reduceMotion = false;
  bool _rtl = false;

  /// Whether the indicator has been placed once. Its first placement snaps:
  /// there is nothing to animate from.
  bool _initialized = false;

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
    _scope = _TabsScope.of(context, 'PanelTabsList');
    _reduceMotion = panelReduceMotion(context);
    if (previous != _scope!.value) {
      // A press is answered at once, from the triggers as they were measured
      // last frame. The scroller follows at the end of the frame, which also
      // corrects the indicator if the row has moved since.
      if (_initialized) _syncIndicator();
      _scheduleSync();
    }
  }

  @override
  void dispose() {
    _geometry.onLayout = null;
    _x.dispose();
    _w.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _still => !(_scope?.animated ?? true) || _reduceMotion;

  Rect? get _selectedRect {
    final scope = _scope;
    if (scope == null) return null;
    final rects = _geometry.rects;
    final children = widget.children;
    for (var i = 0; i < children.length && i < rects.length; i++) {
      final child = children[i];
      if (child is PanelTabsTrigger && child.value == scope.value) {
        return rects[i];
      }
    }
    return null;
  }

  /// Where the indicator is drawn: the animated position once it has been
  /// placed, the selected trigger itself before that.
  ({double left, double width})? get _indicatorSpan {
    if (_initialized) return (left: _x.value, width: math.max(0.0, _w.value));
    final rect = _selectedRect;
    if (rect == null) return null;
    return (left: rect.left, width: rect.width);
  }

  bool _sameSpan(Rect? a, Rect b) =>
      a != null && a.left == b.left && a.width == b.width;

  /// Where the selected tab should sit in the scroller: a little in from the
  /// edge rather than flush against it, so it does not read as the last tab.
  double _scrollOffsetFor(Rect rect) {
    final inset = _scope?.variant == PanelTabsVariant.segmented ? 4.0 : 0.0;
    final start = _rtl ? _geometry.size.width - rect.right : rect.left;
    return math.max(start + inset - 24, 0);
  }

  /// Runs during the row's layout: anything that moves is left to the end of
  /// the frame.
  void _handleLayout() {
    if (_syncScheduled) return;
    final scope = _scope;
    final rect = _selectedRect;
    if (scope == null || rect == null) return;
    final indicatorStale =
        scope.variant != PanelTabsVariant.expanding &&
        (!_initialized || !_sameSpan(_target, rect));
    final scrollStale =
        widget.scrollable &&
        (_scrolled == null ||
            _scrolled!.value != scope.value ||
            _scrolled!.offset != _scrollOffsetFor(rect));
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
    final scope = _scope;
    final rect = _selectedRect;
    if (scope == null ||
        rect == null ||
        scope.variant == PanelTabsVariant.expanding) {
      return;
    }
    if (!_initialized || _still) {
      _x.value = rect.left;
      _w.value = rect.width;
      _initialized = true;
    } else if (!_sameSpan(_target, rect)) {
      _x.springTo(rect.left, PanelSprings.indicator);
      _w.springTo(rect.width, PanelSprings.indicator);
    }
    _target = rect;
  }

  void _syncScroll() {
    final scope = _scope;
    final rect = _selectedRect;
    if (scope == null || rect == null) return;
    if (widget.scrollable && _scroll.hasClients) {
      final offset = _scrollOffsetFor(rect);
      final scrolled = _scrolled;
      if (scrolled == null ||
          scrolled.value != scope.value ||
          scrolled.offset != offset) {
        final position = _scroll.position;
        final target = offset.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        // The first placement has nowhere to travel from: animating it is a
        // row that visibly slides into place as the screen appears.
        if (scrolled == null || _still) {
          position.jumpTo(target);
        } else {
          position.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: panelEase,
          );
        }
        _scrolled = (value: scope.value, offset: offset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope!;
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final variant = scope.variant;
    final expanding = variant == PanelTabsVariant.expanding;
    _rtl = Directionality.of(context) == TextDirection.rtl;

    Widget row = _TabsRow(
      fit: !widget.scrollable && !expanding,
      gap: switch (variant) {
        PanelTabsVariant.segmented => 0,
        PanelTabsVariant.underline => 4,
        PanelTabsVariant.pill => 4,
        PanelTabsVariant.expanding => 6,
      },
      // A trigger at its natural width gets PanelUI's `px-4` here, so a row
      // that cannot share its width out still has room around each label.
      extraWidth: expanding ? 0 : 32,
      alignment: widget.mainAxisAlignment,
      geometry: _geometry,
      children: widget.children,
    );

    if (!expanding) {
      row = CustomPaint(
        painter: _IndicatorPainter(
          list: this,
          repaint: _repaint,
          underline: variant == PanelTabsVariant.underline,
          color:
              widget.indicatorColor ??
              switch (variant) {
                PanelTabsVariant.segmented => c.popover,
                PanelTabsVariant.underline => c.foreground,
                _ => c.primary,
              },
          cornerRadius: variant == PanelTabsVariant.segmented
              ? theme.radii.md
              : null,
          shadows: variant == PanelTabsVariant.segmented
              ? theme.shadows.sm
              : const [],
          thickness: widget.indicatorThickness,
        ),
        child: row,
      );
    }

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

    switch (variant) {
      case PanelTabsVariant.segmented:
        row = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.muted,
            borderRadius: BorderRadius.circular(theme.radii.lg),
          ),
          child: row,
        );
      case PanelTabsVariant.underline:
        row = Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: row,
        );
      case PanelTabsVariant.pill:
      case PanelTabsVariant.expanding:
        break;
    }

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

/// Paints the indicator under the triggers, at the span the list hands it.
class _IndicatorPainter extends CustomPainter {
  _IndicatorPainter({
    required this.list,
    required Listenable repaint,
    required this.underline,
    required this.color,
    required this.cornerRadius,
    required this.shadows,
    required this.thickness,
  }) : super(repaint: repaint);

  final _PanelTabsListState list;
  final bool underline;
  final Color color;

  /// Null rounds the ends fully.
  final double? cornerRadius;
  final List<BoxShadow> shadows;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final span = list._indicatorSpan;
    if (span == null) return;
    // The rule sits on the list's hairline: its bottom edge is the bottom of
    // the 1pt border under this row, as PanelUI's `-bottom-px h-0.5`.
    final rect = underline
        ? Rect.fromLTWH(
            span.left,
            size.height + 1 - thickness,
            span.width,
            thickness,
          )
        : Rect.fromLTWH(span.left, 0, span.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cornerRadius ?? rect.height / 2),
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
      oldDelegate.list != list ||
      oldDelegate.underline != underline ||
      oldDelegate.color != color ||
      oldDelegate.cornerRadius != cornerRadius ||
      !listEquals(oldDelegate.shadows, shadows) ||
      oldDelegate.thickness != thickness;
}

/// One tab in a [PanelTabsList].
///
/// [child] is the label, usually a [Text], styled for the list's size and
/// coloured by the selection: muted until it is selected (or hovered, with a
/// mouse). [icon] sits before it and takes the label's colour; [badge], a
/// count or a dot, sits after it.
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
    if (scope.variant == PanelTabsVariant.expanding) {
      return _ExpandingTrigger(
        active: active,
        enabled: enabled,
        icon: icon,
        badge: badge,
        size: scope.size,
        animated: scope.animated,
        scrollable: _TabsListScope.scrollableOf(context),
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
    final reduce = panelReduceMotion(context);
    final vertical = _triggerPadding[variant]![scope.size.index];
    final radius = BorderRadius.circular(pill ? 999 : theme.radii.md);
    const clear = Color(0x00000000);

    return PanelPressable(
      onPressed: enabled ? () => scope.select(value) : null,
      pressScale: 1,
      isButton: false,
      selected: active,
      semanticLabel: semanticLabel,
      focusRingRadius: radius,
      builder: (context, state) {
        final Color color;
        if (active) {
          color =
              activeLabelColor ?? (pill ? c.primaryForeground : c.foreground);
        } else if (state.hovered && labelColor == null) {
          color = c.foreground;
        } else {
          color = labelColor ?? c.mutedForeground;
        }

        Widget content = TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: reduce ? Duration.zero : _labelColorDuration,
          curve: Curves.fastOutSlowIn,
          builder: (context, value, _) {
            final resolved = value ?? color;
            return IconTheme(
              data: IconThemeData(color: resolved, size: 16),
              child: DefaultTextStyle(
                style: _labelStyle(theme.typography, scope.size, resolved),
                textAlign: TextAlign.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    ?icon,
                    Flexible(child: child),
                    ?badge,
                  ],
                ),
              ),
            );
          },
        );

        content = Padding(
          padding: EdgeInsets.symmetric(vertical: vertical),
          child: Center(heightFactor: 1, child: content),
        );

        final hoverDuration = reduce
            ? Duration.zero
            : const Duration(milliseconds: 150);
        if (variant == PanelTabsVariant.underline) {
          // The web package's hover fill, inside the row and clear of the
          // rule.
          content = Stack(
            // Passed through, so a trigger given more than its natural width
            // (PanelUI's `px-4` in a scroller) still centres its label.
            fit: StackFit.passthrough,
            children: [
              Positioned(
                left: 2,
                right: 2,
                top: 6,
                bottom: 6,
                child: AnimatedContainer(
                  duration: hoverDuration,
                  decoration: BoxDecoration(
                    color: state.hovered ? _fade(c.muted, 0.7) : clear,
                    borderRadius: BorderRadius.circular(theme.radii.md),
                  ),
                ),
              ),
              content,
            ],
          );
        } else if (pill) {
          content = AnimatedContainer(
            duration: reduce ? Duration.zero : _labelColorDuration,
            decoration: BoxDecoration(
              color: !active && state.hovered ? c.muted : clear,
              borderRadius: radius,
            ),
            child: content,
          );
        }

        return Opacity(
          opacity: enabled ? 1 : 0.44,
          child: Semantics(role: SemanticsRole.tab, child: content),
        );
      },
    );
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
    final color = widget.active
        ? widget.activeLabelColor ?? c.foreground
        : widget.labelColor ?? c.mutedForeground;
    final vertical =
        _triggerPadding[PanelTabsVariant.expanding]![widget.size.index];
    final horizontal = _expandingPadding(widget.size, widget.scrollable);
    final pill = BorderRadius.circular(999);

    final label = Padding(
      padding: const EdgeInsetsDirectional.only(start: _labelGap),
      child: DefaultTextStyle(
        style: _labelStyle(theme.typography, widget.size, color),
        maxLines: 1,
        softWrap: false,
        child: widget.child,
      ),
    );

    // The box opens to the label's own width, so the text never reflows on
    // its way in or out; the text fades in behind the width rather than
    // ahead of it, so it arrives instead of being wiped on.
    final reveal = AnimatedBuilder(
      animation: _open,
      child: label,
      builder: (context, label) {
        final t = _open.value;
        return ClipRect(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: math.max(0.0, t),
            heightFactor: 1,
            child: Opacity(
              opacity: ((t - 0.35) / 0.55).clamp(0.0, 1.0),
              alwaysIncludeSemantics: true,
              child: label,
            ),
          ),
        );
      },
    );

    return PanelPressable(
      onPressed: widget.enabled ? widget.onPressed : null,
      pressScale: 1,
      isButton: false,
      selected: widget.active,
      semanticLabel: widget.semanticLabel,
      focusRingRadius: pill,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.44,
        child: Semantics(
          role: SemanticsRole.tab,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontal,
              vertical: vertical,
            ),
            decoration: BoxDecoration(
              color: widget.active
                  ? widget.activeColor ?? c.surfaceTertiary
                  : c.muted,
              borderRadius: pill,
            ),
            child: IconTheme(
              data: IconThemeData(color: color, size: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [?widget.icon, reveal, ?widget.badge],
              ),
            ),
          ),
        ),
      ),
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

/// Marks a panel as sitting in a swipeable strip, and whether it is the one
/// in view.
class _PagerSlot extends InheritedWidget {
  const _PagerSlot({super.key, required this.active, required super.child});

  final bool active;

  @override
  bool updateShouldNotify(_PagerSlot oldWidget) => active != oldWidget.active;
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

  double get _sign => _rtl ? -1 : 1;

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
    _travel += details.primaryDelta ?? details.delta.dx;
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onHorizontalDragCancel: _handleDragCancel,
      child: _PagerStrip(
        position: _position,
        onWidth: (width) => _width = width,
        children: [
          for (var i = 0; i < widget.panels.length; i++)
            _PagerSlot(
              key: ValueKey<Object?>(widget.panels[i].value),
              active: i == _active,
              child: _reached.contains(i)
                  ? widget.panels[i]
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
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
    var height = constraints.minHeight;
    if (constraints.hasTightHeight) {
      height = constraints.maxHeight;
    } else {
      final loose = BoxConstraints(
        minWidth: width,
        maxWidth: width,
        maxHeight: constraints.maxHeight,
      );
      var child = firstChild;
      while (child != null) {
        final measured = dry
            ? child.getDryLayout(loose)
            : (child..layout(loose, parentUsesSize: true)).size;
        height = math.max(height, measured.height);
        child = childAfter(child);
      }
      height = constraints.constrainHeight(height);
    }
    if (!dry) {
      // Stretched to the tallest with a minimum, not a tight height, so a
      // panel whose content grows still makes the strip grow with it.
      final stretched = constraints.hasTightHeight
          ? BoxConstraints.tightFor(width: width, height: height)
          : BoxConstraints(minWidth: width, maxWidth: width, minHeight: height);
      var child = firstChild;
      while (child != null) {
        child.layout(stretched, parentUsesSize: !constraints.hasTightHeight);
        child = childAfter(child);
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

  @override
  double computeMinIntrinsicHeight(double width) {
    var height = 0.0;
    var child = firstChild;
    while (child != null) {
      height = math.max(height, child.getMinIntrinsicHeight(width));
      child = childAfter(child);
    }
    return height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    var height = 0.0;
    var child = firstChild;
    while (child != null) {
      height = math.max(height, child.getMaxIntrinsicHeight(width));
      child = childAfter(child);
    }
    return height;
  }

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

/// Where the row last laid its triggers out, shared between the row's render
/// object (which writes it) and the list (which reads it).
class _TabsRowGeometry {
  List<Rect> rects = const [];
  Size size = Size.zero;
  VoidCallback? onLayout;
}

class _TabsRowParentData extends ContainerBoxParentData<RenderBox> {}

/// A row of triggers: equal shares of a bounded width when [fit], natural
/// widths plus [extraWidth] otherwise, every trigger as tall as the tallest.
/// It records where each trigger landed for the indicator.
class _TabsRow extends MultiChildRenderObjectWidget {
  const _TabsRow({
    required this.fit,
    required this.gap,
    required this.extraWidth,
    required this.alignment,
    required this.geometry,
    required super.children,
  });

  final bool fit;
  final double gap;
  final double extraWidth;
  final MainAxisAlignment alignment;
  final _TabsRowGeometry geometry;

  @override
  _RenderTabsRow createRenderObject(BuildContext context) => _RenderTabsRow(
    fit: fit,
    gap: gap,
    extraWidth: extraWidth,
    alignment: alignment,
    geometry: geometry,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderTabsRow renderObject) {
    renderObject
      ..fit = fit
      ..gap = gap
      ..extraWidth = extraWidth
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
    required double extraWidth,
    required MainAxisAlignment alignment,
    required _TabsRowGeometry geometry,
    required TextDirection textDirection,
  }) : _fit = fit,
       _gap = gap,
       _extraWidth = extraWidth,
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

  double get extraWidth => _extraWidth;
  double _extraWidth;
  set extraWidth(double value) {
    if (value == _extraWidth) return;
    _extraWidth = value;
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

  List<RenderBox> get _children {
    final children = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      children.add(child);
      child = childAfter(child);
    }
    return children;
  }

  double _intrinsicWidth(double Function(RenderBox child) measure) {
    final children = _children;
    if (children.isEmpty) return 0;
    final gaps = gap * (children.length - 1);
    if (fit) {
      var widest = 0.0;
      for (final child in children) {
        widest = math.max(widest, measure(child));
      }
      return widest * children.length + gaps;
    }
    var total = gaps;
    for (final child in children) {
      total += measure(child) + extraWidth;
    }
    return total;
  }

  double _intrinsicHeight(
    double width,
    double Function(RenderBox child, double width) measure,
  ) {
    final children = _children;
    if (children.isEmpty) return 0;
    var share = double.infinity;
    if (fit && width.isFinite) {
      share = math.max(
        0.0,
        (width - gap * (children.length - 1)) / children.length,
      );
    }
    var tallest = 0.0;
    for (final child in children) {
      tallest = math.max(tallest, measure(child, share));
    }
    return tallest;
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

  ({Size size, List<Rect> rects}) _layout(
    BoxConstraints constraints, {
    required bool dry,
  }) {
    final children = _children;
    if (children.isEmpty) {
      return (size: constraints.smallest, rects: const <Rect>[]);
    }
    final count = children.length;
    final gaps = gap * (count - 1);
    final widths = List<double>.filled(count, 0);
    var tallest = 0.0;

    Size measure(RenderBox child, BoxConstraints childConstraints) {
      if (dry) return child.getDryLayout(childConstraints);
      child.layout(childConstraints, parentUsesSize: true);
      return child.size;
    }

    if (fit && constraints.hasBoundedWidth) {
      final share = math.max(0.0, (constraints.maxWidth - gaps) / count);
      for (var i = 0; i < count; i++) {
        final measured = measure(
          children[i],
          BoxConstraints.tightFor(width: share),
        );
        widths[i] = share;
        tallest = math.max(tallest, measured.height);
      }
    } else {
      for (var i = 0; i < count; i++) {
        final measured = measure(children[i], const BoxConstraints());
        widths[i] = measured.width + extraWidth;
        tallest = math.max(tallest, measured.height);
      }
    }

    // Every trigger as tall as the tallest, as a flex row stretches them.
    //
    // A minimum rather than a tight size, and with the size used: a trigger
    // laid out tight becomes a relayout boundary, and one that then changes
    // its own size (an expanding label opening) would never tell the row.
    final height = constraints.constrainHeight(tallest);
    if (!dry) {
      for (var i = 0; i < count; i++) {
        children[i].layout(
          BoxConstraints(
            minWidth: widths[i],
            maxWidth: fit && constraints.hasBoundedWidth
                ? widths[i]
                : double.infinity,
            minHeight: height,
          ),
          parentUsesSize: true,
        );
      }
    }

    final content = widths.fold<double>(gaps, (sum, w) => sum + w);
    final width = constraints.constrainWidth(content);
    final free = math.max(0.0, width - content);
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
    var x = lead;
    for (var i = 0; i < count; i++) {
      final w = widths[i];
      rects.add(Rect.fromLTWH(rtl ? width - x - w : x, 0, w, height));
      x += w + between;
    }
    return (size: Size(width, height), rects: rects);
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
