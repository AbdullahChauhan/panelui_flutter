// The machinery shared by PanelUI's anchored popups: Tooltip, Popover, Menu
// and Select.
//
// PanelUI measures the trigger in window coordinates when it is pressed, lets
// the panel lay out once off-screen to learn its size, and then reconciles the
// two against the safe area: a flip to pick the side, a clamp to slide the
// panel back on screen. Flutter can do all of that inside one layout pass, so
// there is no measuring frame here. The trigger's rectangle comes from
// [OverlayPortal.overlayChildLayoutBuilder], and a render object lays the
// panel out, places it with PanelUI's own rules, and paints its entrance and
// its arrow.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_motion.dart';

/// The side of its anchor a panel prefers, in reading terms: [start] is the
/// left in a left-to-right layout and the right in a right-to-left one.
enum AnchorPlacement {
  /// Above the anchor.
  top,

  /// Below the anchor.
  bottom,

  /// Before the anchor in reading order.
  start,

  /// After the anchor in reading order.
  end,
}

/// Where a panel lines up along its anchor's other axis.
///
/// Above or below the anchor, [start] lines up the leading edges (the left in
/// a left-to-right layout). Beside it, [start] lines up the top edges.
enum AnchorAlign {
  /// Leading or top edges line up.
  start,

  /// Centred on the anchor.
  center,

  /// Trailing or bottom edges line up.
  end,
}

/// A physical side of the anchor, once placement has been resolved against the
/// text direction and, if it had to be, flipped.
enum AnchorSide {
  /// Above the anchor.
  top,

  /// Below the anchor.
  bottom,

  /// To the left of the anchor.
  left,

  /// To the right of the anchor.
  right;

  /// The side across the anchor from this one.
  AnchorSide get opposite => switch (this) {
    AnchorSide.top => AnchorSide.bottom,
    AnchorSide.bottom => AnchorSide.top,
    AnchorSide.left => AnchorSide.right,
    AnchorSide.right => AnchorSide.left,
  };

  /// Whether the panel sits above or below the anchor.
  bool get isVertical => this == AnchorSide.top || this == AnchorSide.bottom;

  /// The physical side [placement] means in [direction].
  static AnchorSide resolve(
    AnchorPlacement placement,
    TextDirection direction,
  ) {
    final rtl = direction == TextDirection.rtl;
    return switch (placement) {
      AnchorPlacement.top => AnchorSide.top,
      AnchorPlacement.bottom => AnchorSide.bottom,
      AnchorPlacement.start => rtl ? AnchorSide.right : AnchorSide.left,
      AnchorPlacement.end => rtl ? AnchorSide.left : AnchorSide.right,
    };
  }
}

/// Where a panel landed: its top-left corner, the side it ended up on, and
/// where along the facing edge the anchor's centre is (for the arrow).
@immutable
class AnchoredGeometry {
  /// Creates a resolved placement.
  const AnchoredGeometry({
    required this.offset,
    required this.side,
    required this.arrowOffset,
  });

  /// The panel's top-left corner, in the coordinates of the bounds.
  final Offset offset;

  /// The side of the anchor the panel is on after any flip.
  final AnchorSide side;

  /// The anchor's centre along the panel's facing edge, measured from the
  /// panel's left (above or below) or top (beside), kept off the corners.
  final double arrowOffset;

  @override
  String toString() =>
      'AnchoredGeometry($offset, ${side.name}, arrow: $arrowOffset)';
}

/// Clamps like PanelUI's `clamp`: when [max] is below [min] (a panel larger
/// than the room it has), the start edge wins, which keeps the beginning of
/// the panel readable.
double _clamp(double value, double min, double max) =>
    math.max(min, math.min(value, math.max(min, max)));

/// PanelUI's `place()`, shared by its Popover and Tooltip.
///
/// Two passes, in this order: the flip picks a side and fires only when the
/// preferred one genuinely has less room than its opposite; the clamp then
/// slides the panel along the other axis to keep it on screen. Clamping first
/// would let a panel be nudged inside the bounds and so look like it fits,
/// hiding the fact that the wrong side was chosen.
///
/// [align] and [alignOffset] are physical here: start is the left or the top.
/// [arrowInset] keeps [AnchoredGeometry.arrowOffset] that far from the
/// panel's corners.
AnchoredGeometry placeBesideAnchor({
  required Rect anchor,
  required Size size,
  required AnchorSide side,
  required Rect bounds,
  AnchorAlign align = AnchorAlign.center,
  double offset = 0,
  double alignOffset = 0,
  double arrowInset = 0,
}) {
  double roomOn(AnchorSide s) => switch (s) {
    AnchorSide.bottom => bounds.bottom - (anchor.bottom + offset),
    AnchorSide.top => anchor.top - offset - bounds.top,
    AnchorSide.right => bounds.right - (anchor.right + offset),
    AnchorSide.left => anchor.left - offset - bounds.left,
  };

  final needed = side.isVertical ? size.height : size.width;
  final resolved = roomOn(side) < needed && roomOn(side.opposite) > roomOn(side)
      ? side.opposite
      : side;

  if (resolved.isVertical) {
    final top = resolved == AnchorSide.bottom
        ? anchor.bottom + offset
        : anchor.top - size.height - offset;
    final left = switch (align) {
      AnchorAlign.start => anchor.left + alignOffset,
      AnchorAlign.end => anchor.right - size.width + alignOffset,
      AnchorAlign.center => anchor.center.dx - size.width / 2 + alignOffset,
    };
    final clampedLeft = _clamp(left, bounds.left, bounds.right - size.width);
    return AnchoredGeometry(
      offset: Offset(
        clampedLeft,
        _clamp(top, bounds.top, bounds.bottom - size.height),
      ),
      side: resolved,
      arrowOffset: _clamp(
        anchor.center.dx - clampedLeft,
        arrowInset,
        size.width - arrowInset,
      ),
    );
  }

  final left = resolved == AnchorSide.right
      ? anchor.right + offset
      : anchor.left - size.width - offset;
  final top = switch (align) {
    AnchorAlign.start => anchor.top + alignOffset,
    AnchorAlign.end => anchor.bottom - size.height + alignOffset,
    AnchorAlign.center => anchor.center.dy - size.height / 2 + alignOffset,
  };
  final clampedTop = _clamp(top, bounds.top, bounds.bottom - size.height);
  return AnchoredGeometry(
    offset: Offset(
      _clamp(left, bounds.left, bounds.right - size.width),
      clampedTop,
    ),
    side: resolved,
    arrowOffset: _clamp(
      anchor.center.dy - clampedTop,
      arrowInset,
      size.height - arrowInset,
    ),
  );
}

/// The room a dropdown list gets on one side of its trigger, from PanelUI's
/// Select: what is left between the trigger and that edge of [bounds], less
/// [offset] (counted twice below the trigger, as the source does), and never
/// under [minHeight] so a cramped viewport scrolls the list rather than
/// collapsing it.
double dropdownRoom({
  required Rect anchor,
  required Rect bounds,
  required AnchorSide side,
  required double offset,
  double minHeight = 160,
}) {
  final space = side == AnchorSide.bottom
      ? bounds.bottom - anchor.bottom - offset
      : anchor.top - bounds.top;
  return math.max(space - offset, minHeight);
}

/// Whether a dropdown list of [height] flips above its trigger: only when it
/// is taller than the space below, which after the cap above happens only when
/// there is less than the minimum height down there.
bool dropdownFlips({
  required Rect anchor,
  required Rect bounds,
  required double height,
  required double offset,
}) {
  final spaceBelow = bounds.bottom - anchor.bottom - offset;
  return height > spaceBelow;
}

/// How an anchored panel is sized and placed.
@immutable
class AnchoredPosition {
  /// Creates a placement.
  const AnchoredPosition({
    this.placement = AnchorPlacement.bottom,
    this.align = AnchorAlign.center,
    this.offset = 8,
    this.alignOffset = 0,
    this.margin = 12,
    this.width,
    this.matchAnchorWidth = false,
    this.minWidth,
    this.maxHeight,
    this.dropdown = false,
    this.dropdownMinHeight = 160,
    this.arrowInset = 0,
  });

  /// The preferred side, flipped when it does not fit.
  final AnchorPlacement placement;

  /// Where the panel lines up along the anchor's other axis.
  final AnchorAlign align;

  /// The gap between the anchor and the panel.
  final double offset;

  /// A nudge along the alignment axis, towards the end in reading order (or
  /// downwards beside the anchor).
  final double alignOffset;

  /// The smallest gap kept between the panel and the edge of the safe area.
  final double margin;

  /// A fixed width. Null sizes the panel to its content; infinity spans the
  /// safe area.
  final double? width;

  /// Make the panel exactly as wide as the anchor. Overrides [width].
  final bool matchAnchorWidth;

  /// A floor for the panel's width. Never wins past the room there is.
  final double? minWidth;

  /// A ceiling for the panel's height, always clamped to the room inside the
  /// safe area.
  final double? maxHeight;

  /// Place the panel the way PanelUI's Select places its list: below the
  /// trigger, start-aligned, capped to the room on that side, and above only
  /// when there is less than [dropdownMinHeight] below.
  final bool dropdown;

  /// The smallest height a [dropdown] list is given before it scrolls.
  final double dropdownMinHeight;

  /// How far the arrow is kept from the panel's corners.
  final double arrowInset;

  @override
  bool operator ==(Object other) =>
      other is AnchoredPosition &&
      other.placement == placement &&
      other.align == align &&
      other.offset == offset &&
      other.alignOffset == alignOffset &&
      other.margin == margin &&
      other.width == width &&
      other.matchAnchorWidth == matchAnchorWidth &&
      other.minWidth == minWidth &&
      other.maxHeight == maxHeight &&
      other.dropdown == dropdown &&
      other.dropdownMinHeight == dropdownMinHeight &&
      other.arrowInset == arrowInset;

  @override
  int get hashCode => Object.hash(
    placement,
    align,
    offset,
    alignOffset,
    margin,
    width,
    matchAnchorWidth,
    minWidth,
    maxHeight,
    dropdown,
    dropdownMinHeight,
    arrowInset,
  );
}

/// The entrance and exit of an anchored panel.
///
/// PanelUI drives two values: an opacity on a timing curve and a "settle" on a
/// spring, which takes the panel from [scaleFrom] and [shift] points towards
/// the anchor to rest, so it appears to unfold from the trigger rather than
/// fade in over it. The exit is a plain fade.
@immutable
class AnchoredMotion {
  /// Creates a motion spec.
  const AnchoredMotion({
    required this.enter,
    required this.exit,
    this.spring,
    this.shift = 0,
    this.scaleFrom = 1,
  });

  /// How long the panel takes to fade in.
  final Duration enter;

  /// How long the panel takes to fade out.
  final Duration exit;

  /// The settle spring. Null fades the panel without moving it.
  final SpringDescription? spring;

  /// How far towards the anchor the panel starts.
  final double shift;

  /// The scale the panel starts at.
  final double scaleFrom;
}

/// A small square rotated into a diamond, half buried under the panel so only
/// its point shows, pointing at the anchor's centre.
@immutable
class AnchoredArrow {
  /// Creates an arrow.
  const AnchoredArrow({
    required this.size,
    required this.color,
    this.borderColor,
    this.borderWidth = 0,
    this.radius = 0,
    this.inset = 0,
  });

  /// The side of the square before it is rotated.
  final double size;

  /// The fill, the same as the panel's.
  final Color color;

  /// Drawn along the two edges that face away from the panel, so the arrow's
  /// outline continues the panel's border.
  final Color? borderColor;

  /// The width of [borderColor].
  final double borderWidth;

  /// Rounds the square's corners.
  final double radius;

  /// How far inside the panel's edge the diamond's centre sits: the width of
  /// the panel's border, as React Native measures absolute children from
  /// inside the border.
  final double inset;

  @override
  bool operator ==(Object other) =>
      other is AnchoredArrow &&
      other.size == size &&
      other.color == color &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.radius == radius &&
      other.inset == inset;

  @override
  int get hashCode =>
      Object.hash(size, color, borderColor, borderWidth, radius, inset);
}

/// What the panel inside an [AnchoredOverlay] can ask of it.
class AnchoredOverlayScope extends InheritedWidget {
  /// Provides [openedFromKeyboard] and [dismiss] to the panel.
  const AnchoredOverlayScope({
    super.key,
    required this.openedFromKeyboard,
    required this.dismiss,
    required super.child,
  });

  /// Whether the popup was opened while the trigger had keyboard focus, in
  /// which case a list highlights its first row, as a native menu does.
  final bool openedFromKeyboard;

  /// Asks the popup to close, as an outside tap or Escape would.
  final VoidCallback dismiss;

  /// The scope around [context], if it is inside an anchored panel.
  static AnchoredOverlayScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AnchoredOverlayScope>();

  @override
  bool updateShouldNotify(AnchoredOverlayScope oldWidget) =>
      openedFromKeyboard != oldWidget.openedFromKeyboard ||
      dismiss != oldWidget.dismiss;
}

/// Shows [panel] in the root [Overlay], anchored to [child].
///
/// [open] drives it: the panel fades and settles in when it turns true and
/// fades out before it is removed when it turns false. While open, a [modal]
/// overlay lays a transparent catcher over the screen that closes it on a tap
/// outside, and Escape and the system back gesture close it too; each of
/// those calls [onDismiss], and the owner decides by setting [open].
///
/// With [takesFocus], focus moves into the panel when it opens (parked on the
/// panel itself, unless something inside asks for it) and returns to the
/// trigger when it closes.
class AnchoredOverlay extends StatefulWidget {
  /// Anchors [panel] to [child].
  const AnchoredOverlay({
    super.key,
    required this.open,
    required this.panel,
    required this.child,
    this.position = const AnchoredPosition(),
    this.motion = const AnchoredMotion(
      enter: PanelDurations.fadeIn,
      exit: PanelDurations.fadeOut,
    ),
    this.arrow,
    this.onDismiss,
    this.modal = true,
    this.scrimColor,
    this.takesFocus = true,
    this.tapRegionGroupId,
    this.onTapOutside,
    this.onPanelHoverChanged,
    this.anchorOutset = 0,
  });

  /// Whether the panel is showing.
  final bool open;

  /// The panel, including its own surface.
  final Widget panel;

  /// The trigger the panel is anchored to.
  final Widget child;

  /// How the panel is sized and placed.
  final AnchoredPosition position;

  /// The entrance and exit.
  final AnchoredMotion motion;

  /// The arrow, if the panel points at its anchor.
  final AnchoredArrow? arrow;

  /// Called on a tap outside, Escape or the back gesture. Null makes the
  /// panel ignore all three.
  final VoidCallback? onDismiss;

  /// Whether a transparent catcher covers the screen behind the panel while
  /// it is open, so a tap outside closes it instead of reaching what is
  /// underneath.
  final bool modal;

  /// A dim drawn behind the panel, faded in and out with it.
  final Color? scrimColor;

  /// Whether focus moves into the panel while it is open.
  final bool takesFocus;

  /// Puts the trigger and the panel in one [TapRegion] group, for a popup
  /// that is not [modal] and handles outside taps itself.
  final Object? tapRegionGroupId;

  /// Called on a pointer down outside both the trigger and the panel, when
  /// [tapRegionGroupId] is set and the panel is open. The tap still reaches
  /// whatever it landed on.
  final VoidCallback? onTapOutside;

  /// Called as a mouse enters and leaves the panel.
  final ValueChanged<bool>? onPanelHoverChanged;

  /// Grows the anchor's rectangle on every side, for a trigger whose visible
  /// edge (a border) lies outside the widget the panel is anchored to.
  final double anchorOutset;

  @override
  State<AnchoredOverlay> createState() => _AnchoredOverlayState();
}

class _AnchoredOverlayState extends State<AnchoredOverlay>
    with TickerProviderStateMixin {
  /// Open popups that take the back gesture, most recently opened last. Every
  /// [PopScope] on a route hears a back press, so a popup opened from inside
  /// another (a select in a popover) checks it is the top one before closing,
  /// and one press closes one popup.
  static final List<_AnchoredOverlayState> _backStack = [];

  final OverlayPortalController _portal = OverlayPortalController(
    debugLabel: 'AnchoredOverlay',
  );
  late final AnimationController _appear = AnimationController(vsync: this)
    ..addStatusListener(_handleAppearStatus);
  late final AnimationController _settle = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _scrim = AnimationController(vsync: this);
  final FocusScopeNode _popupScope = FocusScopeNode(
    debugLabel: 'AnchoredOverlay panel',
  );
  final FocusNode _trigger = FocusNode(
    debugLabel: 'AnchoredOverlay trigger',
    canRequestFocus: false,
    skipTraversal: true,
  );

  bool _started = false;

  /// Whether the overlay is showing or about to: open, or fading out.
  bool _visible = false;

  /// Whether the exit fade is running.
  bool _closing = false;
  bool _fromKeyboard = false;
  bool _portalSyncScheduled = false;

  /// Bumped on every fresh open, so the panel is built anew each time and a
  /// stale focus request from an earlier open is ignored.
  int _generation = 0;

  bool get _interactive => widget.open && !_closing;

  /// Whether the open panel answers the system back gesture.
  bool get _takesBack => widget.takesFocus && widget.onDismiss != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (widget.open) _show();
    }
  }

  @override
  void didUpdateWidget(AnchoredOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      widget.open ? _show() : _hide();
    }
  }

  @override
  void dispose() {
    _backStack.remove(this);
    _appear.dispose();
    _settle.dispose();
    _scrim.dispose();
    _popupScope.dispose();
    _trigger.dispose();
    super.dispose();
  }

  void _show() {
    final reduce = panelReduceMotion(context);
    _fromKeyboard =
        _trigger.hasFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (!_visible) {
      _generation++;
      _appear.value = 0;
      _settle.value = widget.motion.spring == null ? 1 : 0;
      _scrim.value = 0;
    }
    _visible = true;
    _closing = false;
    _backStack.remove(this);
    if (_takesBack) _backStack.add(this);
    if (reduce) {
      _appear.value = 1;
      _settle.value = 1;
      _scrim.value = 1;
    } else {
      _appear.animateTo(1, duration: widget.motion.enter, curve: panelEase);
      final spring = widget.motion.spring;
      if (spring == null) {
        _settle.value = 1;
      } else if (_settle.value != 1) {
        _settle.springTo(1, spring);
      }
      if (widget.scrimColor != null) {
        _scrim.animateTo(1, duration: _scrimFadeIn, curve: panelEase);
      }
    }
    _syncPortal();
    if (widget.takesFocus) _scheduleFocus();
    if (mounted) setState(() {});
  }

  void _hide() {
    if (!_visible || _closing) return;
    _closing = true;
    _backStack.remove(this);
    _restoreFocus();
    if (panelReduceMotion(context)) {
      _finishHide();
      return;
    }
    _appear.animateBack(0, duration: widget.motion.exit, curve: panelEase);
    if (widget.scrimColor != null) {
      _scrim.animateBack(0, duration: _scrimFadeOut, curve: panelEase);
    }
    setState(() {});
  }

  void _handleAppearStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _closing) _finishHide();
  }

  void _finishHide() {
    _closing = false;
    _visible = false;
    _appear.stop();
    _scrim.stop();
    _settle.stop();
    _appear.value = 0;
    _scrim.value = 0;
    _settle.value = 0;
    _syncPortal();
    if (mounted) setState(() {});
  }

  /// Shows or hides the portal to match [_visible]. The portal cannot be
  /// shown or hidden while widgets are building, which is when an `open`
  /// change arrives, so it then waits for the end of the frame; the panel
  /// spends that frame at zero opacity anyway.
  void _syncPortal() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase != SchedulerPhase.persistentCallbacks) {
      _applyPortal();
      return;
    }
    if (_portalSyncScheduled) return;
    _portalSyncScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _portalSyncScheduled = false;
      if (mounted) _applyPortal();
    }, debugLabel: 'AnchoredOverlay.portal');
  }

  void _applyPortal() {
    if (_visible && !_portal.isShowing) {
      _portal.show();
    } else if (!_visible && _portal.isShowing) {
      _portal.hide();
    }
  }

  /// Parks focus on the panel once it is on screen, so Escape and Tab reach
  /// it, unless something inside asked for focus first.
  void _scheduleFocus() {
    final generation = _generation;
    var attempts = 0;
    void focus() {
      if (!mounted || !_interactive || generation != _generation) return;
      if (!_portal.isShowing || _popupScope.context == null) {
        // Not built yet: try again at the end of the next frame or two.
        if (++attempts > 3) return;
        SchedulerBinding.instance.addPostFrameCallback(
          (_) => focus(),
          debugLabel: 'AnchoredOverlay.focus',
        );
        return;
      }
      if (!_popupScope.hasFocus) _popupScope.requestScopeFocus();
    }

    SchedulerBinding.instance.addPostFrameCallback(
      (_) => focus(),
      debugLabel: 'AnchoredOverlay.focus',
    );
  }

  void _restoreFocus() {
    if (!widget.takesFocus || !_popupScope.hasFocus) return;
    FocusNode? target;
    for (final node in _trigger.traversalDescendants) {
      target = node;
      break;
    }
    if (target != null) {
      target.requestFocus();
    } else {
      _popupScope.unfocus(
        disposition: UnfocusDisposition.previouslyFocusedChild,
      );
    }
  }

  void _dismiss() {
    if (_interactive) widget.onDismiss?.call();
  }

  KeyEventResult _handlePanelKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        widget.onDismiss != null) {
      _dismiss();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Rect _bounds(BuildContext context, Size overlaySize) {
    final overlayContext = Overlay.maybeOf(context, rootOverlay: true)?.context;
    final media =
        overlayContext?.getInheritedWidgetOfExactType<MediaQuery>()?.data ??
        MediaQueryData.fromView(View.of(context));
    final padding = media.padding;
    final bottom = math.max(padding.bottom, media.viewInsets.bottom);
    final margin = widget.position.margin;
    return Rect.fromLTRB(
      padding.left + margin,
      padding.top + margin,
      math.max(
        padding.left + margin,
        overlaySize.width - padding.right - margin,
      ),
      math.max(padding.top + margin, overlaySize.height - bottom - margin),
    );
  }

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo info) {
    final transform = info.childPaintTransform;
    if (transform.determinant() == 0) return const SizedBox.shrink();
    var anchor = MatrixUtils.transformRect(
      transform,
      Offset.zero & info.childSize,
    );
    if (widget.anchorOutset != 0) anchor = anchor.inflate(widget.anchorOutset);
    final interactive = _interactive;

    Widget panel = AnchoredOverlayScope(
      openedFromKeyboard: _fromKeyboard,
      dismiss: _dismiss,
      child: KeyedSubtree(key: ValueKey(_generation), child: widget.panel),
    );
    final hover = widget.onPanelHoverChanged;
    if (hover != null) {
      panel = MouseRegion(
        onEnter: (_) => hover(true),
        onExit: (_) => hover(false),
        child: panel,
      );
    }
    if (widget.tapRegionGroupId != null) {
      panel = TapRegion(groupId: widget.tapRegionGroupId, child: panel);
    }
    if (widget.takesFocus) {
      panel = FocusScope(
        node: _popupScope,
        onKeyEvent: _handlePanelKey,
        child: panel,
      );
    }
    panel = ExcludeFocus(
      excluding: !interactive,
      child: IgnorePointer(ignoring: !interactive, child: panel),
    );

    Widget overlay = Stack(
      children: [
        if (widget.scrimColor != null)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _scrim,
                child: ColoredBox(color: widget.scrimColor!),
              ),
            ),
          ),
        if (widget.modal && interactive)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: _dismiss,
              onSecondaryTap: _dismiss,
            ),
          ),
        Positioned.fill(
          child: _AnchoredPanelLayout(
            anchor: anchor,
            bounds: _bounds(context, info.overlaySize),
            position: widget.position,
            textDirection: Directionality.of(context),
            appear: _appear,
            settle: _settle,
            shift: widget.motion.shift,
            scaleFrom: widget.motion.scaleFrom,
            arrow: widget.arrow,
            child: panel,
          ),
        ),
      ],
    );

    if (interactive && _takesBack) {
      overlay = PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _backStack.isNotEmpty && _backStack.last == this) {
            _dismiss();
          }
        },
        child: overlay,
      );
    }
    return SelectionContainer.maybeOf(context) == null
        ? overlay
        : SelectionContainer.disabled(child: overlay);
  }

  @override
  Widget build(BuildContext context) {
    Widget trigger = Focus(
      focusNode: _trigger,
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      child: widget.child,
    );
    if (widget.tapRegionGroupId != null) {
      trigger = TapRegion(
        groupId: widget.tapRegionGroupId,
        enabled: widget.open,
        onTapOutside: widget.onTapOutside == null
            ? null
            : (_) => widget.onTapOutside!(),
        child: trigger,
      );
    }
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: _buildOverlay,
      child: trigger,
    );
  }
}

const Duration _scrimFadeIn = Duration(milliseconds: 150);
const Duration _scrimFadeOut = Duration(milliseconds: 150);

class _AnchoredPanelLayout extends SingleChildRenderObjectWidget {
  const _AnchoredPanelLayout({
    required this.anchor,
    required this.bounds,
    required this.position,
    required this.textDirection,
    required this.appear,
    required this.settle,
    required this.shift,
    required this.scaleFrom,
    required this.arrow,
    required super.child,
  });

  final Rect anchor;
  final Rect bounds;
  final AnchoredPosition position;
  final TextDirection textDirection;
  final Animation<double> appear;
  final Animation<double> settle;
  final double shift;
  final double scaleFrom;
  final AnchoredArrow? arrow;

  @override
  _RenderAnchoredPanel createRenderObject(BuildContext context) =>
      _RenderAnchoredPanel(
        anchor: anchor,
        bounds: bounds,
        position: position,
        textDirection: textDirection,
        appear: appear,
        settle: settle,
        shift: shift,
        scaleFrom: scaleFrom,
        arrow: arrow,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAnchoredPanel renderObject,
  ) {
    renderObject
      ..anchor = anchor
      ..bounds = bounds
      ..position = position
      ..textDirection = textDirection
      ..appear = appear
      ..settle = settle
      ..shift = shift
      ..scaleFrom = scaleFrom
      ..arrow = arrow;
  }
}

/// Lays the panel out against the anchor, places it with PanelUI's rules, and
/// paints it with its entrance (a fade, and a settle from a smaller scale and
/// a few points towards the anchor) and its arrow.
///
/// The arrow is painted here rather than by the panel because where it goes
/// is only known once the panel has been placed, which happens after the
/// panel has been laid out; painting it in the same pass keeps it on the
/// trigger even after a flip or a clamp, with no frame of lag.
class _RenderAnchoredPanel extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderAnchoredPanel({
    required Rect anchor,
    required Rect bounds,
    required AnchoredPosition position,
    required TextDirection textDirection,
    required Animation<double> appear,
    required Animation<double> settle,
    required double shift,
    required double scaleFrom,
    required AnchoredArrow? arrow,
  }) : _anchor = anchor,
       _bounds = bounds,
       _position = position,
       _textDirection = textDirection,
       _appear = appear,
       _settle = settle,
       _shift = shift,
       _scaleFrom = scaleFrom,
       _arrow = arrow;

  Rect get anchor => _anchor;
  Rect _anchor;
  set anchor(Rect value) {
    if (value == _anchor) return;
    _anchor = value;
    markNeedsLayout();
  }

  Rect get bounds => _bounds;
  Rect _bounds;
  set bounds(Rect value) {
    if (value == _bounds) return;
    _bounds = value;
    markNeedsLayout();
  }

  AnchoredPosition get position => _position;
  AnchoredPosition _position;
  set position(AnchoredPosition value) {
    if (value == _position) return;
    _position = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  Animation<double> get appear => _appear;
  Animation<double> _appear;
  set appear(Animation<double> value) {
    if (value == _appear) return;
    if (attached) _appear.removeListener(_handleAppear);
    _appear = value;
    if (attached) _appear.addListener(_handleAppear);
    _handleAppear();
  }

  Animation<double> get settle => _settle;
  Animation<double> _settle;
  set settle(Animation<double> value) {
    if (value == _settle) return;
    if (attached) _settle.removeListener(markNeedsPaint);
    _settle = value;
    if (attached) _settle.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  double get shift => _shift;
  double _shift;
  set shift(double value) {
    if (value == _shift) return;
    _shift = value;
    markNeedsPaint();
  }

  double get scaleFrom => _scaleFrom;
  double _scaleFrom;
  set scaleFrom(double value) {
    if (value == _scaleFrom) return;
    _scaleFrom = value;
    markNeedsPaint();
  }

  AnchoredArrow? get arrow => _arrow;
  AnchoredArrow? _arrow;
  set arrow(AnchoredArrow? value) {
    if (value == _arrow) return;
    _arrow = value;
    markNeedsPaint();
  }

  Offset _childOffset = Offset.zero;
  AnchorSide _side = AnchorSide.bottom;
  double _arrowOffset = 0;
  bool _usedOpacityLayer = false;

  final LayerHandle<OpacityLayer> _opacityLayer = LayerHandle<OpacityLayer>();
  final LayerHandle<TransformLayer> _transformLayer =
      LayerHandle<TransformLayer>();

  bool get _needsOpacityLayer {
    final value = _appear.value;
    return value > 0 && value < 1;
  }

  void _handleAppear() {
    final needs = _needsOpacityLayer;
    if (needs != _usedOpacityLayer) {
      _usedOpacityLayer = needs;
      markNeedsCompositingBitsUpdate();
    }
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _appear.addListener(_handleAppear);
    _settle.addListener(markNeedsPaint);
    _usedOpacityLayer = _needsOpacityLayer;
  }

  @override
  void detach() {
    _appear.removeListener(_handleAppear);
    _settle.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _opacityLayer.layer = null;
    _transformLayer.layer = null;
    super.dispose();
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _needsOpacityLayer;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) return;
    final rect = _bounds;
    final available = math.max(0.0, rect.width);
    final room = math.max(0.0, rect.height);
    final p = _position;

    var requested = p.matchAnchorWidth ? _anchor.width : p.width;
    if (requested != null && requested.isInfinite) requested = available;
    final double? fixed = requested == null
        ? null
        : math.min(math.max(requested, p.minWidth ?? 0), available);
    final minWidth = fixed ?? math.min(p.minWidth ?? 0, available);
    final maxWidth = fixed ?? available;
    final rtl = _textDirection == TextDirection.rtl;

    if (p.dropdown) {
      double capFor(AnchorSide side) {
        final cap = dropdownRoom(
          anchor: _anchor,
          bounds: rect,
          side: side,
          offset: p.offset,
          minHeight: p.dropdownMinHeight,
        );
        return math.min(cap, p.maxHeight ?? double.infinity);
      }

      BoxConstraints constraintsFor(AnchorSide side) => BoxConstraints(
        minWidth: minWidth,
        maxWidth: maxWidth,
        maxHeight: capFor(side),
      );

      child.layout(constraintsFor(AnchorSide.bottom), parentUsesSize: true);
      var side = AnchorSide.bottom;
      if (dropdownFlips(
        anchor: _anchor,
        bounds: rect,
        height: child.size.height,
        offset: p.offset,
      )) {
        side = AnchorSide.top;
        child.layout(constraintsFor(side), parentUsesSize: true);
      }
      final childSize = child.size;
      final top = side == AnchorSide.bottom
          ? _anchor.bottom + p.offset
          : _anchor.top - p.offset - childSize.height;
      final left = rtl ? _anchor.right - childSize.width : _anchor.left;
      _childOffset = Offset(
        _clamp(left, rect.left, rect.right - childSize.width),
        top,
      );
      _side = side;
      _arrowOffset = childSize.width / 2;
      return;
    }

    child.layout(
      BoxConstraints(
        minWidth: minWidth,
        maxWidth: maxWidth,
        maxHeight: math.min(p.maxHeight ?? room, room),
      ),
      parentUsesSize: true,
    );
    final side = AnchorSide.resolve(p.placement, _textDirection);
    var align = p.align;
    var alignOffset = p.alignOffset;
    if (rtl && side.isVertical) {
      // Reading order runs right to left, so the leading edge is the right.
      align = switch (align) {
        AnchorAlign.start => AnchorAlign.end,
        AnchorAlign.end => AnchorAlign.start,
        AnchorAlign.center => AnchorAlign.center,
      };
      alignOffset = -alignOffset;
    }
    final geometry = placeBesideAnchor(
      anchor: _anchor,
      size: child.size,
      side: side,
      align: align,
      offset: p.offset,
      alignOffset: alignOffset,
      bounds: rect,
      arrowInset: p.arrowInset,
    );
    _childOffset = geometry.offset;
    _side = geometry.side;
    _arrowOffset = geometry.arrowOffset;
  }

  /// Maps the panel's own coordinates to this box's, entrance included.
  Matrix4 _panelTransform() {
    final childSize = child?.size ?? Size.zero;
    final t = _settle.value;
    final scale = _scaleFrom + (1 - _scaleFrom) * t;
    final distance = _shift * (1 - t);
    // The panel starts a few points towards the anchor, on whichever side it
    // ended up, so it appears to grow out of the trigger.
    final shift = switch (_side) {
      AnchorSide.bottom => Offset(0, -distance),
      AnchorSide.top => Offset(0, distance),
      AnchorSide.right => Offset(-distance, 0),
      AnchorSide.left => Offset(distance, 0),
    };
    final origin = _childOffset + shift;
    final centre = childSize.center(Offset.zero);
    return Matrix4.identity()
      ..translateByDouble(origin.dx + centre.dx, origin.dy + centre.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-centre.dx, -centre.dy, 0, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    final opacity = _appear.value.clamp(0.0, 1.0);
    if (child == null || opacity <= 0) {
      _opacityLayer.layer = null;
      _transformLayer.layer = null;
      return;
    }
    final transform = _panelTransform();

    void paintPanel(PaintingContext context, Offset offset) {
      _transformLayer.layer = context.pushTransform(
        needsCompositing,
        offset,
        transform,
        (context, offset) {
          context.paintChild(child, offset);
          _paintArrow(context.canvas, offset, child.size);
        },
        oldLayer: _transformLayer.layer,
      );
    }

    if (opacity >= 1) {
      _opacityLayer.layer = null;
      paintPanel(context, offset);
    } else {
      _opacityLayer.layer = context.pushOpacity(
        offset,
        (opacity * 255).round(),
        paintPanel,
        oldLayer: _opacityLayer.layer,
      );
    }
  }

  void _paintArrow(Canvas canvas, Offset origin, Size panel) {
    final arrow = _arrow;
    if (arrow == null) return;
    // The arrow sits on the edge facing the anchor: a panel below the anchor
    // has its arrow on its top edge.
    final centre = switch (_side) {
      AnchorSide.bottom => Offset(_arrowOffset, arrow.inset),
      AnchorSide.top => Offset(_arrowOffset, panel.height - arrow.inset),
      AnchorSide.right => Offset(arrow.inset, _arrowOffset),
      AnchorSide.left => Offset(panel.width - arrow.inset, _arrowOffset),
    };
    final half = arrow.size / 2;
    canvas
      ..save()
      ..translate(origin.dx + centre.dx, origin.dy + centre.dy)
      ..rotate(math.pi / 4);
    final square = Rect.fromLTRB(-half, -half, half, half);
    canvas.drawRRect(
      RRect.fromRectAndRadius(square, Radius.circular(arrow.radius)),
      Paint()..color = arrow.color,
    );
    final borderColor = arrow.borderColor;
    if (borderColor != null && arrow.borderWidth > 0) {
      // Only the two edges facing away from the panel are drawn; the other two
      // lie over the panel and would show as a seam across it. In the square's
      // own frame, before the 45° turn, those are its top and left edges for a
      // panel below the anchor, and so on round.
      final i = arrow.borderWidth / 2;
      final a = -half + i;
      final b = half - i;
      final path = switch (_side) {
        AnchorSide.bottom =>
          Path()
            ..moveTo(a, half)
            ..lineTo(a, a)
            ..lineTo(half, a),
        AnchorSide.top =>
          Path()
            ..moveTo(-half, b)
            ..lineTo(b, b)
            ..lineTo(b, -half),
        AnchorSide.right =>
          Path()
            ..moveTo(a, -half)
            ..lineTo(a, b)
            ..lineTo(half, b),
        AnchorSide.left =>
          Path()
            ..moveTo(-half, a)
            ..lineTo(b, a)
            ..lineTo(b, half),
      };
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = arrow.borderWidth,
      );
    }
    canvas.restore();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || _appear.value <= 0) return false;
    return result.addWithPaintTransform(
      transform: _panelTransform(),
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_panelTransform());
  }
}

/// Arrow keys, Home and End for a popup list of rows, which move focus from
/// row to row (skipping disabled ones, wrapping at the ends, and scrolling the
/// row into view), plus Tab and type-ahead hooks.
///
/// It also decides where focus starts: on [initialFocus] if it gives a node,
/// on the first row if the popup was opened from the keyboard, and otherwise
/// on the list itself, so no row is highlighted under a pointer that has not
/// moved yet but the arrow keys still work.
class PopupListNavigation extends StatefulWidget {
  /// Adds list navigation to the rows in [child].
  const PopupListNavigation({
    super.key,
    required this.child,
    this.initialFocus,
    this.onTab,
    this.onTypeAhead,
  });

  /// The rows.
  final Widget child;

  /// The row to focus when the popup opens, such as the selected option.
  final FocusNode? Function()? initialFocus;

  /// Called on Tab, which a menu treats as leaving it.
  final VoidCallback? onTab;

  /// Called with each printable character typed; returns whether it moved
  /// focus to a matching row.
  final bool Function(String character)? onTypeAhead;

  @override
  State<PopupListNavigation> createState() => _PopupListNavigationState();
}

class _PopupListNavigationState extends State<PopupListNavigation> {
  final FocusNode _node = FocusNode(
    debugLabel: 'PopupListNavigation',
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _focusInitial(),
      debugLabel: 'PopupListNavigation.focus',
    );
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  FocusTraversalPolicy get _policy =>
      FocusTraversalGroup.maybeOf(context) ?? ReadingOrderTraversalPolicy();

  void _focusInitial() {
    if (!mounted || _node.context == null) return;
    final explicit = widget.initialFocus?.call();
    if (explicit != null && explicit.context != null) {
      _reveal(explicit, alignment: 0.5);
      return;
    }
    if (AnchoredOverlayScope.maybeOf(context)?.openedFromKeyboard ?? false) {
      final first = _first();
      if (first != null) {
        _reveal(first);
        return;
      }
    }
    _node.requestFocus();
  }

  FocusNode? _first() =>
      _policy.findFirstFocus(_node, ignoreCurrentFocus: true);

  FocusNode? _last() => _policy.findLastFocus(_node, ignoreCurrentFocus: true);

  void _reveal(FocusNode? node, {double alignment = 1}) {
    if (node == null || node.context == null) return;
    FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
      node,
      alignment: alignment,
    );
  }

  bool get _onRow {
    final focus = FocusManager.instance.primaryFocus;
    return focus != null && focus != _node && focus.ancestors.contains(_node);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final focus = FocusManager.instance.primaryFocus;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (_onRow && focus != null) {
        _policy.next(focus);
      } else {
        _reveal(_first());
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_onRow && focus != null) {
        _policy.previous(focus);
      } else {
        _reveal(_last(), alignment: 0);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _reveal(_first(), alignment: 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _reveal(_last());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab && widget.onTab != null) {
      widget.onTab!();
      return KeyEventResult.handled;
    }
    final typeAhead = widget.onTypeAhead;
    final character = event.character;
    final keyboard = HardwareKeyboard.instance;
    if (typeAhead != null &&
        event is KeyDownEvent &&
        character != null &&
        character.trim().isNotEmpty &&
        !keyboard.isControlPressed &&
        !keyboard.isMetaPressed &&
        !keyboard.isAltPressed &&
        typeAhead(character)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _handleKey,
      child: widget.child,
    );
  }
}

/// Finds the next row whose label starts with what has been typed, the way a
/// native list does: letters typed in quick succession build up a prefix, and
/// typing the same letter again moves on to the next row starting with it.
class TypeAheadBuffer {
  /// Creates a buffer that forgets what was typed after [timeout].
  TypeAheadBuffer({this.timeout = const Duration(milliseconds: 750)});

  /// How long a pause clears the prefix.
  final Duration timeout;

  String _prefix = '';
  Timer? _timer;

  /// What has been typed so far.
  String get prefix => _prefix;

  /// Adds [character] and returns the index into [labels] to move to, or
  /// null. [current] is the row that has focus now, or -1.
  int? find(
    String character,
    List<String> labels, {
    required int current,
    bool Function(int index)? enabled,
  }) {
    _timer?.cancel();
    _timer = Timer(timeout, clear);
    final typed = character.toLowerCase();
    _prefix += typed;
    final count = labels.length;
    if (count == 0) return null;
    // A run of one repeated letter cycles through the rows starting with it.
    final repeated =
        _prefix.length > 1 && _prefix.split('').every((c) => c == typed);
    final needle = repeated ? typed : _prefix;
    final start = repeated || _prefix.length == 1 ? current + 1 : current;
    for (var i = 0; i < count; i++) {
      final index = (start + i) % count;
      if (index < 0) continue;
      if (enabled != null && !enabled(index)) continue;
      if (labels[index].toLowerCase().startsWith(needle)) return index;
    }
    return null;
  }

  /// Forgets what was typed.
  void clear() {
    _timer?.cancel();
    _timer = null;
    _prefix = '';
  }

  /// Cancels the pending timeout.
  void dispose() => clear();
}
