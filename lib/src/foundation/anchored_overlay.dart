// The machinery shared by PanelUI's popups: Tooltip, Popover, Menu and
// Select.
//
// PanelUI measures the trigger in window coordinates when it is pressed, lets
// the panel lay out once off-screen to learn its size, and then reconciles the
// two against the safe area: a flip to pick the side, a clamp to slide the
// panel back on screen. Flutter can do all of that inside one layout pass, so
// there is no measuring frame here. The trigger's rectangle comes from
// [OverlayPortal.overlayChildLayoutBuilder], and a render object lays the
// panel out, places it with PanelUI's own rules, and paints its entrance and
// its arrow without rebuilding anything on an animation tick.
//
// The same four popups also share the keyboard handling of a popup list
// ([PopupListNavigation], [TypeAheadBuffer]) and the presentation of a popup
// as a bottom sheet instead of an anchored panel ([PopupSheetPresenter]).
//
// Internal to the components; not exported from the package.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_motion.dart';
import 'overlay_capture.dart';
import 'overlay_scrim.dart';

// ---------------------------------------------------------------------------
// Placement vocabulary
// ---------------------------------------------------------------------------

/// The side of its anchor a panel prefers, in reading terms: [start] is the
/// left in a left-to-right layout and the right in a right-to-left one.
///
/// PanelUI names the sides physically (`left`, `right`); they are directional
/// here, as Flutter's own insets and alignments are, so a layout mirrored for
/// a right-to-left language mirrors its popups with it.
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

// ---------------------------------------------------------------------------
// What a popup asks of the overlay
// ---------------------------------------------------------------------------

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
    this.atLeastAnchorWidth = false,
    this.minWidth,
    this.maxHeight,
    this.dropdown = false,
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

  /// Never make the panel narrower than the anchor, while letting it grow
  /// past it for wider content.
  final bool atLeastAnchorWidth;

  /// A floor for the panel's width. Never wins past the room there is.
  final double? minWidth;

  /// A ceiling for the panel's height, always clamped to the room inside the
  /// safe area.
  final double? maxHeight;

  /// Place the panel the way PanelUI's Select places its floating list:
  /// below the trigger, start-aligned, capped to the room on that side, and
  /// above only when there is too little room below (see [dropdownRoom]).
  final bool dropdown;

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
      other.atLeastAnchorWidth == atLeastAnchorWidth &&
      other.minWidth == minWidth &&
      other.maxHeight == maxHeight &&
      other.dropdown == dropdown &&
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
    atLeastAnchorWidth,
    minWidth,
    maxHeight,
    dropdown,
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

// ---------------------------------------------------------------------------
// The overlay
// ---------------------------------------------------------------------------

/// PanelUI's `Scrim` fades a dim in and out over 150ms.
const Duration _dimFade = Duration(milliseconds: 150);

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
    this.barrierLabel,
    this.scrimColor,
    this.blur = false,
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

  /// Announces the [modal] catcher to screen readers as a button of this
  /// name that closes the panel. Null keeps it out of their way.
  final String? barrierLabel;

  /// A dim drawn behind the panel, faded in and out with it.
  final Color? scrimColor;

  /// Frost the screen behind the panel instead of dimming it. Wins over
  /// [scrimColor], since the frost carries a dim of its own.
  final bool blur;

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

/// What the panel inside an [AnchoredOverlay] can ask of it.
class AnchoredOverlayScope extends InheritedWidget {
  /// Provides [openedFromKeyboard] and [dismiss] to the panel.
  const AnchoredOverlayScope({
    super.key,
    required this.openedFromKeyboard,
    required this.dismiss,
    required super.child,
  });

  /// Whether the popup was opened while its trigger had keyboard focus, in
  /// which case a list puts focus on a row at once, as a native menu does.
  final bool openedFromKeyboard;

  /// Asks the popup to close, as an outside tap or Escape would.
  final VoidCallback dismiss;

  /// The scope around [context], if it is inside a popup.
  static AnchoredOverlayScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AnchoredOverlayScope>();

  @override
  bool updateShouldNotify(AnchoredOverlayScope oldWidget) =>
      openedFromKeyboard != oldWidget.openedFromKeyboard ||
      dismiss != oldWidget.dismiss;
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
    ..addStatusListener((_) => _finishHideOnceFaded());
  late final AnimationController _settle = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _scrim = AnimationController(vsync: this)
    ..addStatusListener((_) => _finishHideOnceFaded());
  final FocusScopeNode _panelScope = FocusScopeNode(
    debugLabel: 'AnchoredOverlay panel',
  );
  final FocusNode _trigger = FocusNode(debugLabel: 'AnchoredOverlay trigger');

  /// Whether the first open state has been acted on. It needs the media
  /// query (for reduced motion), so it waits for [didChangeDependencies].
  bool _started = false;

  /// Whether the overlay is showing or about to: open, or fading out.
  bool _visible = false;

  /// Whether the exit fade is running.
  bool _closing = false;

  /// Whether the trigger had keyboard focus when the popup last opened.
  bool _openedFromKeyboard = false;

  bool _portalSyncScheduled = false;

  /// Bumped on every fresh open, so the panel is built anew each time and a
  /// stale focus request from an earlier open is ignored.
  int _generation = 0;

  bool get _interactive => widget.open && !_closing;

  /// Whether the open panel answers the system back gesture.
  bool get _takesBack => widget.takesFocus && widget.onDismiss != null;

  bool get _hasScrim => widget.blur || widget.scrimColor != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.open) _show();
  }

  @override
  void didUpdateWidget(AnchoredOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) widget.open ? _show() : _hide();
  }

  @override
  void dispose() {
    _backStack.remove(this);
    _appear.dispose();
    _settle.dispose();
    _scrim.dispose();
    _panelScope.dispose();
    _trigger.dispose();
    super.dispose();
  }

  void _show() {
    _openedFromKeyboard =
        _trigger.hasFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (!_visible) {
      // A fresh open, rather than one that catches a panel on its way out.
      _generation++;
      _appear.value = 0;
      _settle.value = widget.motion.spring == null ? 1 : 0;
      _scrim.value = 0;
    }
    _visible = true;
    _closing = false;
    _backStack.remove(this);
    if (_takesBack) _backStack.add(this);
    _animateIn();
    _syncPortal();
    if (widget.takesFocus) _scheduleFocus();
  }

  void _animateIn() {
    if (panelReduceMotion(context)) {
      _appear.value = 1;
      _settle.value = 1;
      _scrim.value = _hasScrim ? 1 : 0;
      return;
    }
    _appear.animateTo(1, duration: widget.motion.enter, curve: panelEase);
    final spring = widget.motion.spring;
    if (spring != null && _settle.value != 1) _settle.springTo(1, spring);
    if (_hasScrim) {
      if (widget.blur) {
        // The frost fades itself in when it mounts (PanelOverlayScrim); the
        // layer around it only has to be there, and to fade it out again.
        _scrim.value = 1;
      } else {
        _scrim.animateTo(1, duration: _dimFade, curve: panelEase);
      }
    }
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
    if (_hasScrim) _scrim.animateBack(0, duration: _dimFade, curve: panelEase);
    // A panel closed before it had faded in at all has nothing to fade.
    _finishHideOnceFaded();
  }

  /// Takes the overlay down once the panel and its backdrop have both faded,
  /// so a backdrop slower than the panel is not cut off.
  void _finishHideOnceFaded() {
    if (_closing && _appear.isDismissed && _scrim.isDismissed) _finishHide();
  }

  void _finishHide() {
    _closing = false;
    _visible = false;
    _appear.value = 0;
    _scrim.value = 0;
    _settle
      ..stop()
      ..value = 0;
    _syncPortal();
  }

  /// Shows or hides the portal to match [_visible]. The portal cannot be
  /// shown or hidden while widgets are building, which is when an `open`
  /// change arrives, so it then waits for the end of the frame; the panel
  /// spends that frame at zero opacity anyway.
  void _syncPortal() {
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
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
  ///
  /// The panel is built a frame after the portal is shown, and the portal
  /// itself may wait a frame (see [_syncPortal]), so this looks again at the
  /// end of each of the next few frames until the panel is there.
  void _scheduleFocus() {
    final generation = _generation;
    var attempts = 0;
    void focus() {
      if (!mounted || !_interactive || generation != _generation) return;
      if (_portal.isShowing && _panelScope.context != null) {
        if (!_panelScope.hasFocus) _panelScope.requestScopeFocus();
        return;
      }
      if (++attempts > 3) return;
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => focus(),
        debugLabel: 'AnchoredOverlay.focus',
      );
    }

    SchedulerBinding.instance.addPostFrameCallback(
      (_) => focus(),
      debugLabel: 'AnchoredOverlay.focus',
    );
  }

  void _restoreFocus() {
    if (!widget.takesFocus || !_panelScope.hasFocus) return;
    final trigger = _trigger.traversalDescendants.firstOrNull;
    if (trigger != null) {
      trigger.requestFocus();
    } else {
      _panelScope.unfocus(
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

  /// The safe area of the root overlay, less [AnchoredPosition.margin], and
  /// clear of the keyboard when it is up.
  Rect _bounds(BuildContext context, Size overlaySize) {
    final overlayContext = Overlay.maybeOf(context, rootOverlay: true)?.context;
    final media =
        overlayContext?.getInheritedWidgetOfExactType<MediaQuery>()?.data ??
        MediaQueryData.fromView(View.of(context));
    final padding = media.padding;
    final bottom = math.max(padding.bottom, media.viewInsets.bottom);
    final margin = widget.position.margin;
    final left = padding.left + margin;
    final top = padding.top + margin;
    return Rect.fromLTRB(
      left,
      top,
      math.max(left, overlaySize.width - padding.right - margin),
      math.max(top, overlaySize.height - bottom - margin),
    );
  }

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo info) {
    final transform = info.childPaintTransform;
    // A trigger scaled to nothing has nowhere to anchor a panel.
    if (transform.determinant() == 0) return const SizedBox.shrink();
    final anchor = MatrixUtils.transformRect(
      transform,
      Offset.zero & info.childSize,
    ).inflate(widget.anchorOutset);
    final interactive = _interactive;

    Widget overlay = Stack(
      children: [
        ?_buildScrim(),
        if (widget.modal)
          Positioned.fill(
            // Stays in the tree while the panel fades out, taking no taps,
            // so the panel keeps its place among these children and is not
            // built afresh (losing its scroll and its focus) as it leaves.
            child: IgnorePointer(
              ignoring: !interactive,
              child: _buildCatcher(),
            ),
          ),
        Positioned.fill(
          key: const ValueKey<String>('panel'),
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
            child: _buildPanel(interactive),
          ),
        ),
      ],
    );

    overlay = PopScope(
      // While the panel is up, a back gesture closes it instead of the
      // screen. Always in the tree, for the same reason as the catcher.
      canPop: !(interactive && _takesBack),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _backStack.isNotEmpty && _backStack.last == this) {
          _dismiss();
        }
      },
      child: overlay,
    );
    return SelectionContainer.maybeOf(context) == null
        ? overlay
        : SelectionContainer.disabled(child: overlay);
  }

  /// The transparent layer that closes the panel on a tap outside it,
  /// announced as [AnchoredOverlay.barrierLabel] when it has one.
  Widget _buildCatcher() {
    final catcher = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: _dismiss,
      onSecondaryTap: _dismiss,
    );
    final label = widget.barrierLabel;
    if (label == null || widget.onDismiss == null) return catcher;
    return Semantics(
      button: true,
      label: label,
      onTap: _dismiss,
      child: catcher,
    );
  }

  Widget? _buildScrim() {
    if (widget.blur) {
      return Positioned.fill(
        child: AnimatedBuilder(
          animation: _scrim,
          builder: (context, _) =>
              PanelOverlayScrim(opacity: _scrim.value, blur: true),
        ),
      );
    }
    final color = widget.scrimColor;
    if (color == null) return null;
    return Positioned.fill(
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _scrim,
          child: ColoredBox(color: color),
        ),
      ),
    );
  }

  Widget _buildPanel(bool interactive) {
    Widget panel = AnchoredOverlayScope(
      openedFromKeyboard: _openedFromKeyboard,
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
        node: _panelScope,
        onKeyEvent: _handlePanelKey,
        child: panel,
      );
    }
    // A panel on its way out is already gone as far as input is concerned.
    return ExcludeFocus(
      excluding: !interactive,
      child: IgnorePointer(ignoring: !interactive, child: panel),
    );
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
    final group = widget.tapRegionGroupId;
    final onTapOutside = widget.onTapOutside;
    if (group != null) {
      trigger = TapRegion(
        groupId: group,
        enabled: widget.open,
        onTapOutside: onTapOutside == null ? null : (_) => onTapOutside(),
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

// ---------------------------------------------------------------------------
// Laying out and painting the panel
// ---------------------------------------------------------------------------

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
/// The entrance is applied as layers on each tick, so an animating panel is
/// repainted but never rebuilt or laid out again. The arrow is painted here
/// rather than by the panel because where it goes is only known once the
/// panel has been placed; painting it in the same pass keeps it on the
/// trigger after a flip or a clamp, with no frame of lag.
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

  /// Where layout put the panel, the side it ended up on and where the
  /// anchor's centre falls along its facing edge.
  Offset _childOffset = Offset.zero;
  AnchorSide _side = AnchorSide.bottom;
  double _arrowOffset = 0;

  bool _usedOpacityLayer = false;
  final LayerHandle<OpacityLayer> _opacityLayer = LayerHandle<OpacityLayer>();
  final LayerHandle<TransformLayer> _transformLayer =
      LayerHandle<TransformLayer>();

  /// Whether the panel is part-way through a fade, and so drawn through an
  /// opacity layer.
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
    final p = _position;
    final available = math.max(0.0, _bounds.width);

    var requested = p.matchAnchorWidth ? _anchor.width : p.width;
    if (requested != null && requested.isInfinite) requested = available;
    final floor = math.max(
      p.minWidth ?? 0,
      p.atLeastAnchorWidth ? _anchor.width : 0.0,
    );
    // The floor never wins past the room there is: a panel wider than the
    // screen is worse than a cramped one.
    final double? fixed = requested == null
        ? null
        : math.min(math.max(requested, floor), available);
    final minWidth = fixed ?? math.min(floor, available);
    final maxWidth = fixed ?? available;

    if (p.dropdown) {
      _layoutDropdown(child, minWidth, maxWidth);
    } else {
      _layoutBeside(child, minWidth, maxWidth);
    }
  }

  /// PanelUI's popover and tooltip: the panel is capped at the room inside
  /// the bounds, so the clamp always has a solution, then flipped and
  /// clamped by [placeBesideAnchor].
  void _layoutBeside(RenderBox child, double minWidth, double maxWidth) {
    final p = _position;
    final room = math.max(0.0, _bounds.height);
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
    if (_textDirection == TextDirection.rtl && side.isVertical) {
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
      bounds: _bounds,
      arrowInset: p.arrowInset,
    );
    _childOffset = geometry.offset;
    _side = geometry.side;
    _arrowOffset = geometry.arrowOffset;
  }

  /// PanelUI's select list: laid out below the trigger first, and laid out
  /// again above it only if it turned out taller than the room below.
  void _layoutDropdown(RenderBox child, double minWidth, double maxWidth) {
    final p = _position;
    BoxConstraints constraintsFor(AnchorSide side) => BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      maxHeight: math.min(
        dropdownRoom(
          anchor: _anchor,
          bounds: _bounds,
          side: side,
          offset: p.offset,
        ),
        p.maxHeight ?? double.infinity,
      ),
    );

    var side = AnchorSide.bottom;
    child.layout(constraintsFor(side), parentUsesSize: true);
    if (dropdownFlips(
      anchor: _anchor,
      bounds: _bounds,
      height: child.size.height,
      offset: p.offset,
    )) {
      side = AnchorSide.top;
      child.layout(constraintsFor(side), parentUsesSize: true);
    }
    final size = child.size;
    final top = side == AnchorSide.bottom
        ? _anchor.bottom + p.offset
        : _anchor.top - p.offset - size.height;
    final left = _textDirection == TextDirection.rtl
        ? _anchor.right - size.width
        : _anchor.left;
    _childOffset = Offset(
      _clamp(left, _bounds.left, _bounds.right - size.width),
      top,
    );
    _side = side;
    _arrowOffset = size.width / 2;
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
      ..rotate(math.pi / 4)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(-half, -half, half, half),
          Radius.circular(arrow.radius),
        ),
        Paint()..color = arrow.color,
      );
    final borderColor = arrow.borderColor;
    if (borderColor != null && arrow.borderWidth > 0) {
      canvas.drawPath(
        _arrowOutline(half, arrow.borderWidth),
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = arrow.borderWidth,
      );
    }
    canvas.restore();
  }

  /// The two edges of the arrow's square that face away from the panel, in
  /// the square's own frame before its 45° turn: its top and left edges for a
  /// panel below the anchor, and so on round. The other two lie over the
  /// panel and would show as a seam across it. Each stroke runs inside the
  /// square, as a React Native border does.
  Path _arrowOutline(double half, double width) {
    final near = -half + width / 2;
    final far = half - width / 2;
    return switch (_side) {
      AnchorSide.bottom =>
        Path()
          ..moveTo(near, half)
          ..lineTo(near, near)
          ..lineTo(half, near),
      AnchorSide.top =>
        Path()
          ..moveTo(-half, far)
          ..lineTo(far, far)
          ..lineTo(far, -half),
      AnchorSide.right =>
        Path()
          ..moveTo(near, -half)
          ..lineTo(near, far)
          ..lineTo(half, far),
      AnchorSide.left =>
        Path()
          ..moveTo(-half, near)
          ..lineTo(far, near)
          ..lineTo(far, half),
    };
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

// ---------------------------------------------------------------------------
// Geometry
// ---------------------------------------------------------------------------

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

/// The least height PanelUI's Select gives its floating list, however little
/// room there is: a cramped viewport scrolls the list rather than collapsing
/// it.
const double _dropdownMinHeight = 160;

/// The room a dropdown list gets on one side of its trigger, from PanelUI's
/// Select: what is left between the trigger and that edge of [bounds], less
/// [offset] (counted twice below the trigger, as the source does), and never
/// under 160.
double dropdownRoom({
  required Rect anchor,
  required Rect bounds,
  required AnchorSide side,
  required double offset,
}) {
  final space = side == AnchorSide.bottom
      ? bounds.bottom - anchor.bottom - offset
      : anchor.top - bounds.top;
  return math.max(space - offset, _dropdownMinHeight);
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

/// Clamps like PanelUI's `clamp`: when [max] is below [min] (a panel larger
/// than the room it has), the start edge wins, which keeps the beginning of
/// the panel readable.
double _clamp(double value, double min, double max) =>
    math.max(min, math.min(value, math.max(min, max)));

// ---------------------------------------------------------------------------
// Presenting a popup as a bottom sheet
// ---------------------------------------------------------------------------

/// Keeps a route, usually a bottom sheet, on screen while a popup that
/// presents itself through one is open.
///
/// A route is built far from the popup that opened it, so it cannot simply
/// rebuild with it: a menu row toggled in a sheet would keep showing the old
/// state. [sync] hands the route the popup's latest content instead, which
/// reaches it at the end of the frame that produced it, since one part of
/// the tree cannot rebuild another mid-build. The route shows [content] as
/// its body.
///
/// The navigator is only touched outside a build, so the popup can call
/// [sync] and [dismiss] from wherever its open state changes. A route the
/// reader closed themselves (a drag, the scrim, the back gesture) is reported
/// through [onDismissed].
class PopupSheetPresenter {
  /// Creates a presenter that reports a reader's dismissal to [onDismissed].
  PopupSheetPresenter({required this.onDismissed});

  /// Called when the route is closed from inside it rather than by
  /// [dismiss].
  final VoidCallback onDismissed;

  final ValueNotifier<Widget> _content = ValueNotifier<Widget>(
    const SizedBox.shrink(),
  );
  ModalRoute<void>? _route;
  bool _disposed = false;

  /// The route's body: whatever [present] or [update] last gave.
  late final Widget content = ValueListenableBuilder<Widget>(
    valueListenable: _content,
    builder: (context, content, _) => content,
  );

  /// Brings the route in line with the popup at [context]: puts one up while
  /// [open], made by [route] around the builder it is to show and carrying
  /// the themes in force at [context]; refreshes it with [body] while it
  /// stays up; and takes it down once not [open].
  void sync(
    BuildContext context, {
    required bool open,
    required Widget Function() body,
    required ModalRoute<void> Function(WidgetBuilder builder) route,
  }) {
    if (!open) {
      dismiss();
    } else if (_route != null) {
      final latest = body();
      _afterBuild(() {
        if (!_disposed) _content.value = latest;
      });
    } else {
      final navigator = Navigator.of(context, rootNavigator: true);
      final themed = panelCaptureThemes(context, navigator.context);
      _present(navigator, route((context) => themed(content)), body());
    }
  }

  void _present(NavigatorState navigator, ModalRoute<void> route, Widget body) {
    _route = route;
    _content.value = body;
    _afterBuild(() {
      if (!identical(_route, route) || !navigator.mounted) return;
      unawaited(
        navigator.push(route).whenComplete(() {
          if (!identical(_route, route)) return;
          _route = null;
          if (!_disposed) onDismissed();
        }),
      );
    });
  }

  /// Takes the route down: with its exit animation if it is on top, at once
  /// if something has been pushed over it.
  void dismiss() {
    final route = _route;
    if (route == null) return;
    _route = null;
    _afterBuild(() {
      final navigator = route.navigator;
      if (navigator == null || !route.isActive) return;
      if (route.isCurrent) {
        navigator.pop();
      } else {
        navigator.removeRoute(route);
      }
    });
  }

  /// Takes down any route still up and releases the content.
  void dispose() {
    dismiss();
    _disposed = true;
    _content.dispose();
  }

  static void _afterBuild(VoidCallback action) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => action());
    } else {
      action();
    }
  }
}

// ---------------------------------------------------------------------------
// Keyboard navigation of a popup list
// ---------------------------------------------------------------------------

/// Arrow keys, Home and End for a popup list of rows, which move focus from
/// row to row (skipping disabled ones, wrapping at the ends, and scrolling the
/// row into view when it is not), plus Tab and type-ahead hooks.
///
/// It also decides where focus starts. Opened from the keyboard, it goes to
/// [initialFocus] if that gives a node, or else to the first row, as a native
/// menu does. Opened by a pointer or a finger it goes to the list itself: no
/// row is lit under a pointer that has not moved, and the list opens at its
/// top as PanelUI's does, but the arrow keys still work.
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

  /// The row to focus when the popup opens from the keyboard, such as the
  /// selected option.
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
  final FocusNode _node = FocusNode(debugLabel: 'PopupListNavigation');

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

  void _focusInitial() {
    if (!mounted || _node.context == null) return;
    final fromKeyboard =
        AnchoredOverlayScope.maybeOf(context)?.openedFromKeyboard ?? false;
    if (!fromKeyboard) {
      _node.requestFocus();
      return;
    }
    final explicit = widget.initialFocus?.call();
    if (explicit != null && explicit.context != null) {
      _reveal(explicit, ScrollPositionAlignmentPolicy.explicit);
    } else {
      _reveal(
        _rows.firstOrNull,
        ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
  }

  /// The rows that can take focus, top to bottom. Disabled rows, and the rows
  /// of a closed submenu, are not among them.
  List<FocusNode> get _rows => _node.traversalDescendants.toList();

  void _reveal(FocusNode? row, ScrollPositionAlignmentPolicy policy) {
    if (row == null || row.context == null) return;
    FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
      row,
      // An explicit reveal centres the row; the others only scroll as far
      // as it takes to show it.
      alignment: 0.5,
      alignmentPolicy: policy,
    );
  }

  /// Moves focus [step] rows on from the focused one, wrapping round. With
  /// no row focused, down starts at the top and up at the bottom.
  void _move(int step) {
    final rows = _rows;
    if (rows.isEmpty) return;
    final current = rows.indexWhere((row) => row.hasPrimaryFocus);
    final next = current < 0
        ? (step > 0 ? 0 : rows.length - 1)
        : (current + step) % rows.length;
    _reveal(
      rows[next],
      step > 0
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (key == LogicalKeyboardKey.home) {
      _reveal(
        _rows.firstOrNull,
        ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    } else if (key == LogicalKeyboardKey.end) {
      _reveal(_rows.lastOrNull, ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
    } else if (key == LogicalKeyboardKey.tab && widget.onTab != null) {
      widget.onTab!();
    } else if (!_typeAhead(event)) {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  bool _typeAhead(KeyEvent event) {
    final typeAhead = widget.onTypeAhead;
    final character = event.character;
    final keyboard = HardwareKeyboard.instance;
    return typeAhead != null &&
        event is KeyDownEvent &&
        character != null &&
        character.trim().isNotEmpty &&
        !keyboard.isControlPressed &&
        !keyboard.isMetaPressed &&
        !keyboard.isAltPressed &&
        typeAhead(character);
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
