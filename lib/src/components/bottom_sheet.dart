import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/overlay_capture.dart';
import '../foundation/overlay_scrim.dart';
import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// How far a release has to carry the sheet down to dismiss it.
const double _dismissDistance = 120;

/// How fast a downward flick has to be to dismiss the sheet whatever the
/// distance.
const double _dismissVelocity = 800;

/// Above its resting place the sheet takes a third of each move.
const double _rubberBand = 3;

/// The sheet's padding: `px-5 pt-2`, and at least 16pt at the bottom.
const double _paddingX = 20;
const double _paddingTop = 8;
const double _paddingBottom = 16;

/// How far below the status bar a docked sheet stops at its tallest.
const double _topClearance = 8;

/// How far a floating sheet stands in from the sides (`mx-4`) and up from
/// the bottom.
const double _detachedMargin = 16;
const double _detachedGap = 24;

/// The widest a sheet grows. PanelUI's native sheet spans the screen; its web
/// package caps a floating sheet at `max-w-lg` and a docked one at
/// `max-w-2xl`, which keeps a sheet a sheet on a tablet or a desktop.
const double _detachedMaxWidth = 512;
const double _dockedMaxWidth = 672;

/// Where the close button sits in the sheet: `top-3 end-4`.
const double _closeTop = 12;
const double _closeEnd = 16;

/// The tolerance a sheet's spring settles to, the one `springTo` uses.
const Tolerance _settled = Tolerance(distance: 0.0005, velocity: 0.005);

const Set<PointerDeviceKind> _touchDevices = {
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};

const Set<PointerDeviceKind> _pointerDevices = {
  ..._touchDevices,
  PointerDeviceKind.mouse,
};

/// Where a flick would come to rest if it kept decelerating at Apple's
/// default rate. Distance alone makes the sheet heavy: a short fast flick
/// down is unmistakably a dismissal.
double _project(double velocity) {
  const decelerationRate = 0.998;
  return velocity / 1000 * decelerationRate / (1 - decelerationRate);
}

/// How tall a bottom sheet opens.
enum PanelBottomSheetSize {
  /// As tall as its content, for a sheet that is a handful of rows. It stops
  /// short of the status bar, and a [PanelBottomSheetBody] in it scrolls once
  /// the content is taller than that.
  auto(null),

  /// Half the screen, for content that has to be given the room rather than
  /// allowed to ask for it.
  half(0.5),

  /// 94% of the screen: as tall as the screen allows while leaving a strip of
  /// the app showing above it, which is what says the sheet is laid over it.
  full(0.94);

  const PanelBottomSheetSize(this.fraction);

  /// The share of the screen the sheet aims for, or null to fit its content.
  final double? fraction;
}

/// Shows a sheet that rises from the bottom of the screen, and returns the
/// value it is popped with.
///
/// The sheet springs up from below the screen (420ms, damping ratio 0.9) and
/// the scrim behind it darkens in step with how far up it is, while also
/// running its own fade in. It can be dragged: released past 120pt, or
/// flicked down faster than 800pt/s (or far enough that the flick would carry
/// it past 120pt), it leaves at the speed it was let go, on a spring that
/// stops dead at the bottom; otherwise it springs back with a knock. Dragged
/// up it resists, staying within a few points of rest. With a mouse it is
/// dragged by its handle and its [PanelBottomSheetHeader], so the content
/// stays free for selecting.
///
/// ```dart
/// showPanelBottomSheet<void>(
///   context,
///   builder: (context) => const Column(
///     mainAxisSize: MainAxisSize.min,
///     crossAxisAlignment: CrossAxisAlignment.stretch,
///     children: [
///       PanelBottomSheetHeader(
///         title: Text('Choose a country'),
///         description: Text('The list scrolls under the heading.'),
///       ),
///       PanelBottomSheetBody(children: [/* rows */]),
///     ],
///   ),
/// );
/// ```
///
/// What [builder] returns is laid out under the handle with the room the
/// [size] leaves, so a `Column` in it should usually be
/// `mainAxisSize: MainAxisSize.min`. Put a [PanelBottomSheetBody] in that
/// column for content that scrolls: pulling down on it while it is at its top
/// drags the sheet instead.
///
/// [isDismissible] false locks the sheet: no tap on the scrim, no drag, no
/// Escape and no back button, so only the sheet's own controls close it (the
/// close button still does). [detached] floats the sheet clear of the edges
/// with all four corners rounded. [blur] frosts the screen behind it. The
/// sheet keeps clear of the status bar and pads its bottom for the home
/// indicator. It also rides above the keyboard, which PanelUI leaves to the
/// sheet's content. Under reduced motion it fades instead of sliding.
Future<T?> showPanelBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  PanelBottomSheetSize size = PanelBottomSheetSize.auto,
  bool isDismissible = true,
  bool showClose = true,
  bool showHandle = true,
  bool detached = false,
  bool blur = false,
  String? barrierLabel,
  String closeLabel = 'Close',
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  bool? requestFocus,
  TraversalEdgeBehavior? traversalEdgeBehavior,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final wrap = panelCaptureThemes(context, navigator.context);
  return navigator.push<T>(
    PanelBottomSheetRoute<T>(
      builder: (context) => wrap(builder(context)),
      size: size,
      isDismissible: isDismissible,
      showClose: showClose,
      showHandle: showHandle,
      detached: detached,
      blur: blur,
      barrierLabel: barrierLabel,
      closeLabel: closeLabel,
      settings: routeSettings,
      requestFocus: requestFocus,
      traversalEdgeBehavior: traversalEdgeBehavior,
    ),
  );
}

/// The route [showPanelBottomSheet] pushes, for code that pushes routes
/// itself.
///
/// Its transition is driven by springs rather than a fixed duration, and the
/// sheet's position, the scrim and the drag all derive from the same values,
/// so the backdrop can never disagree with where the sheet is.
class PanelBottomSheetRoute<T> extends PopupRoute<T> {
  /// Creates a bottom sheet route.
  PanelBottomSheetRoute({
    required this.builder,
    this.size = PanelBottomSheetSize.auto,
    this.isDismissible = true,
    this.showClose = true,
    this.showHandle = true,
    this.detached = false,
    this.blur = false,
    String? barrierLabel,
    this.closeLabel = 'Close',
    super.settings,
    super.requestFocus,
    super.traversalEdgeBehavior,
    super.directionalTraversalEdgeBehavior,
  }) : _barrierLabel = barrierLabel;

  /// Builds the sheet's content.
  final WidgetBuilder builder;

  /// How tall the sheet opens.
  final PanelBottomSheetSize size;

  /// Whether a tap on the scrim, a drag, Escape or the back button can close
  /// the sheet. When false, only the sheet's own controls can.
  final bool isDismissible;

  /// Whether to draw a round close button in the top trailing corner.
  final bool showClose;

  /// Whether to draw the drag handle at the top. A sheet that can be dragged
  /// should say so; turn it off when the content draws its own.
  final bool showHandle;

  /// Float the sheet clear of the screen's edges instead of docking it to the
  /// bottom, so it reads as a card laid over the app rather than a drawer.
  final bool detached;

  /// Frost the screen behind instead of dimming it.
  final bool blur;

  /// The close button's accessible name.
  final String closeLabel;

  final String? _barrierLabel;

  /// The drag's offset from rest in logical pixels, downward positive. Kept
  /// apart from [animation] because above rest the sheet rubber-bands, and
  /// a route's animation cannot go past 1.
  late final AnimationController _drag;

  /// Everything that moves the sheet: the route's animation and the drag.
  late final Listenable _motion = Listenable.merge([animation!, _drag]);

  /// The distance the sheet travels on and off the screen: the height of the
  /// navigator's overlay, as last laid out.
  double _travel = 0;

  /// The velocity a drag handed over when it dismissed the sheet, in units of
  /// [animation] per second.
  double? _handoverVelocity;

  @override
  bool get barrierDismissible => isDismissible;

  /// The scrim's accessible name, "Close sheet" unless given.
  @override
  String get barrierLabel => _barrierLabel ?? 'Close sheet';

  // The scrim is drawn by buildModalBarrier, following the sheet.
  @override
  Color? get barrierColor => null;

  // Used only under reduced motion, where the sheet fades for 150ms in place
  // of the travel; otherwise springs drive the transition.
  @override
  Duration get transitionDuration => PanelDurations.fadeIn;

  @override
  Duration get reverseTransitionDuration => PanelDurations.fadeIn;

  // A sheet that the scrim cannot close is not closed by the back button
  // either: only its own controls close it.
  @override
  RoutePopDisposition get popDisposition =>
      isDismissible ? super.popDisposition : RoutePopDisposition.doNotPop;

  /// Whether the platform asked for reduced motion, read where the route
  /// lives without depending on it.
  bool get _reduceMotion =>
      navigator?.context
          .getInheritedWidgetOfExactType<MediaQuery>()
          ?.data
          .disableAnimations ??
      false;

  @override
  void install() {
    _drag = AnimationController.unbounded(vsync: navigator!);
    super.install();
  }

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  @override
  Simulation? createSimulation({required bool forward}) {
    if (_reduceMotion) return null;
    final controller = this.controller!;
    final velocity = _handoverVelocity ?? controller.velocity;
    _handoverVelocity = null;
    final spring = SpringSimulation(
      forward ? PanelSprings.sheet : PanelSprings.sheetExit,
      controller.value,
      forward ? 1 : 0,
      velocity,
      tolerance: _settled,
      snapToEnd: true,
    );
    // Leaving, it stops at the bottom rather than overshooting it, which
    // would flash a gap under the sheet on its way out
    // (`overshootClamping`).
    return forward ? spring : _ClampedAtTarget(spring, target: 0);
  }

  /// Closes the sheet from one of its own controls, whether or not the
  /// reader can dismiss it.
  void _close() {
    final navigator = this.navigator;
    if (navigator == null || !isActive) return;
    if (isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(this);
    }
  }

  /// Takes over a sheet that is still rising when a finger takes hold of it:
  /// the rest of its travel becomes part of the drag, so it stops under the
  /// finger rather than going on rising, as PanelUI's single position does
  /// when its pan takes it over.
  void _catchRise() {
    final controller = this.controller!;
    if (_reduceMotion ||
        _travel <= 0 ||
        controller.status != AnimationStatus.forward) {
      return;
    }
    _drag.value += (1 - controller.value) * _travel;
    controller.value = 1;
  }

  /// A drag released to dismiss: the route's own exit takes over from where
  /// the finger let go, carrying its speed.
  void _dismissFromDrag(double velocity) {
    if (!isCurrent) return;
    if (!_reduceMotion && _travel > 0) {
      final controller = this.controller!;
      final offset = _drag.value.clamp(0.0, _travel);
      _drag.value = 0;
      controller.value = (controller.value - offset / _travel).clamp(0.0, 1.0);
      _handoverVelocity = -velocity / _travel;
    }
    navigator!.pop();
  }

  /// The opacity of the layer the scrim sits in: the share of the screen the
  /// sheet has risen, so dragging it halfway down lightens the screen behind
  /// it by half. Under reduced motion the sheet arrives already at rest, so
  /// the scrim's own fade carries the arrival, and the layer fades only as
  /// the sheet leaves.
  double _scrimOpacity(bool reduceMotion) {
    final route = animation!;
    final double risen;
    if (!reduceMotion) {
      risen = route.value;
    } else if (route.status == AnimationStatus.reverse) {
      risen = panelEase.transform(route.value);
    } else {
      risen = 1;
    }
    return risen - (_travel > 0 ? _drag.value / _travel : 0.0);
  }

  @override
  Widget buildModalBarrier() {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => PanelOverlayScrim(
            opacity: _scrimOpacity(panelReduceMotion(context)),
            blur: blur,
          ),
        ),
        super.buildModalBarrier(),
      ],
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: _SheetFrame(route: this),
    );
  }
}

/// A fixed heading above a sheet's body: a title and a description.
///
/// It reserves the top trailing corner for the close button, and it stays
/// put while a [PanelBottomSheetBody] scrolls under it, so the sheet still
/// says what it is once the list has moved. A mouse can drag the sheet by it.
class PanelBottomSheetHeader extends StatelessWidget {
  /// Creates a sheet header.
  const PanelBottomSheetHeader({
    super.key,
    this.title,
    this.description,
    this.children = const [],
  });

  /// The heading, large and semibold. It names the sheet for screen readers.
  final Widget? title;

  /// A line under the title, small and muted.
  final Widget? description;

  /// More content under the description.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final header = Padding(
      // Clear of the close button in the corner: `pe-12 pb-3`.
      padding: const EdgeInsetsDirectional.only(end: 48, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (title != null)
            Semantics(
              container: true,
              namesRoute: true,
              child: DefaultTextStyle(
                style: theme.typography.style(
                  PanelTextSize.lg,
                  weight: FontWeight.w600,
                  color: c.foreground,
                ),
                child: title!,
              ),
            ),
          if (description != null)
            DefaultTextStyle(
              style: theme.typography.style(
                PanelTextSize.sm,
                color: c.mutedForeground,
              ),
              child: description!,
            ),
          ...children,
        ],
      ),
    );
    return _SheetScope.maybeOf(context)?.frame.wrapMouseDrag(header) ?? header;
  }
}

/// The scrolling part of a sheet.
///
/// Place it in the sheet's column, where it takes its share of the height
/// itself: in a sheet with a [PanelBottomSheetSize] other than auto it fills
/// what the header and footer leave; in an auto sheet it is as tall as its
/// content and scrolls once the sheet has grown as tall as the screen
/// allows. An [Expanded] or a [Flexible] written around it takes that over.
///
/// It reports where it is scrolled to, which is what lets the sheet and the
/// list share a drag: pull down on the list at its top and the sheet comes
/// with you, push the sheet back up and the list takes the rest of the
/// stroke, pull down anywhere else and the list scrolls.
class PanelBottomSheetBody extends StatefulWidget {
  /// Creates a sheet body.
  const PanelBottomSheetBody({
    super.key,
    required this.children,
    this.spacing = 0,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  /// The content, laid out top to bottom.
  final List<Widget> children;

  /// The gap between [children].
  final double spacing;

  /// Space around the content, inside the scrolling area.
  final EdgeInsetsGeometry padding;

  /// How the list scrolls. Defaults to the platform's.
  final ScrollPhysics? physics;

  @override
  State<PanelBottomSheetBody> createState() => _PanelBottomSheetBodyState();
}

class _PanelBottomSheetBodyState extends State<PanelBottomSheetBody> {
  final _SheetScrollController _controller = _SheetScrollController();
  _SheetFrameState? _frame;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final frame = _SheetScope.maybeOf(context)?.frame;
    if (frame == _frame) return;
    _frame?._unregisterBody();
    frame?._registerBody();
    _frame = frame;
    _controller.frame = frame;
  }

  @override
  void dispose() {
    _frame?._unregisterBody();
    _controller.dispose();
    super.dispose();
  }

  /// Whether the caller wrapped the body in an [Expanded] or a [Flexible] of
  /// their own, which already gives it its share of the column.
  bool get _wrapped {
    var wrapped = false;
    context.visitAncestorElements((parent) {
      wrapped = parent.widget is Flexible;
      return false;
    });
    return wrapped;
  }

  @override
  Widget build(BuildContext context) {
    final scroll = ScrollConfiguration(
      // PanelUI's body draws no scroll indicator and no overscroll effect: at
      // the top a pull moves the sheet, and the effect would draw the content
      // stretching inside a sheet that is already moving.
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false, overscroll: false),
      child: SingleChildScrollView(
        controller: _controller,
        physics: widget.physics,
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: widget.spacing,
          children: widget.children,
        ),
      ),
    );
    if (_wrapped) return scroll;
    final sized = _SheetScope.maybeOf(context)?.sized ?? false;
    return sized ? Expanded(child: scroll) : Flexible(child: scroll);
  }
}

/// A row of controls pinned below a sheet's body, for whatever the sheet is
/// asking to be decided. Outside the body, so it stays reachable however far
/// the content scrolls.
class PanelBottomSheetFooter extends StatelessWidget {
  /// Creates a sheet footer.
  const PanelBottomSheetFooter({
    super.key,
    required this.children,
    this.direction = Axis.vertical,
  });

  /// The controls.
  final List<Widget> children;

  /// Stacked full width (the default), or side by side. Side by side, wrap
  /// the controls in [Expanded] to share the width.
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    final c = PanelTheme.of(context).colors;
    final vertical = direction == Axis.vertical;
    return Container(
      // `gap-2 border-t border-border pt-3`.
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Flex(
        direction: direction,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: vertical
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        spacing: 8,
        children: children,
      ),
    );
  }
}

/// What the parts of a sheet need from the sheet around them.
class _SheetScope extends InheritedWidget {
  const _SheetScope({
    required this.frame,
    required this.sized,
    required super.child,
  });

  final _SheetFrameState frame;

  /// Whether the sheet has a height of its own for a body to fill.
  final bool sized;

  static _SheetScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetScope>();

  @override
  bool updateShouldNotify(_SheetScope oldWidget) =>
      frame != oldWidget.frame || sized != oldWidget.sized;
}

/// The route's page: the sheet laid out at the bottom of the screen, and the
/// drag that moves it.
class _SheetFrame extends StatefulWidget {
  const _SheetFrame({required this.route});

  final PanelBottomSheetRoute<dynamic> route;

  @override
  State<_SheetFrame> createState() => _SheetFrameState();
}

class _SheetFrameState extends State<_SheetFrame> {
  PanelBottomSheetRoute<dynamic> get _route => widget.route;
  AnimationController get _drag => _route._drag;

  /// What the route's builder returns, built once: the frame rebuilds as the
  /// keyboard moves, and the content has no reason to.
  late final Widget _content = Builder(builder: _route.builder);

  /// Scrolling bodies in the sheet. With one, an upward drag at rest is a
  /// scroll, so the sheet stays where it is instead of rubber-banding.
  int _bodies = 0;

  bool get _canDrag => _route.isDismissible && _route.isCurrent;

  /// How far below rest the sheet has been dragged.
  double get _offset => _drag.value;

  void _registerBody() => _bodies++;

  void _unregisterBody() => _bodies--;

  /// Takes hold of the sheet where it is, catching it if it is settling or
  /// still rising.
  void _beginDrag() {
    if (!_canDrag) return;
    _drag.stop();
    _route._catchRise();
  }

  /// Moves the sheet by [delta], downward positive, and returns the part of
  /// an upward move it could not take because it is back at rest, which
  /// belongs to the list underneath.
  ///
  /// Each move is added to where the sheet is, and above its resting place
  /// the result is cut to a third: PanelUI's rubber band, which compounds
  /// over the moves, so the sheet stays within a few points of rest however
  /// far the finger goes.
  double _moveBy(double delta) {
    final next = _drag.value + delta;
    if (next <= 0 && _bodies > 0) {
      // With a list in the sheet an upward drag is a scroll: lifting the
      // sheet as the list began to move would read as the sheet taking a
      // drag that was meant for the list.
      _drag.value = 0;
      return next;
    }
    _drag.value = next > 0 ? next : next / _rubberBand;
    return 0;
  }

  /// Settles a drag released at [velocity], downward positive: it leaves,
  /// or it springs back carrying the speed it was let go at.
  void _release(double velocity) {
    final offset = _drag.value;
    // Velocity decides as much as distance does, and the exit is handed it
    // rather than only consulting it.
    if (_canDrag &&
        (offset + _project(velocity) > _dismissDistance ||
            velocity > _dismissVelocity)) {
      _route._dismissFromDrag(velocity);
      return;
    }
    // A drag that never moved the sheet is not the sheet's to settle.
    if (offset == 0) return;
    if (panelReduceMotion(context)) {
      _drag.value = 0;
    } else {
      _drag.animateWith(
        SpringSimulation(
          PanelSprings.sheet,
          offset,
          0,
          velocity,
          tolerance: _settled,
          snapToEnd: true,
        ),
      );
    }
    // It caught rather than went: a knock at the moment it commits to staying.
    HapticFeedback.mediumImpact();
  }

  void _handleDragStart(DragStartDetails details) => _beginDrag();

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_canDrag) _moveBy(details.primaryDelta ?? 0);
  }

  void _handleDragEnd(DragEndDetails details) =>
      _release(details.primaryVelocity ?? 0);

  /// Makes [child] a place the sheet can be dragged by: by touch over the
  /// whole sheet, and by a mouse ([mouse]) over the handle and the header, so
  /// the rest stays free for selecting, as on PanelUI's web.
  Widget _dragArea({required Widget child, bool mouse = false}) {
    if (!_route.isDismissible) return child;
    final settings = MediaQuery.maybeGestureSettingsOf(context);
    return RawGestureDetector(
      behavior: mouse ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      // A drag is not a scroll, and should not be offered as one.
      excludeFromSemantics: true,
      gestures: {
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(
                supportedDevices: mouse ? _pointerDevices : _touchDevices,
                debugOwner: this,
              ),
              (recognizer) => recognizer
                // The platform's slop rather than PanelUI's 12pt, so a list
                // in the sheet, which waits for the same slop and sits
                // deeper, keeps winning its own drags.
                ..gestureSettings = settings
                // The whole of the finger's travel, slop included, as with
                // PanelUI's pan: the point the sheet was taken by stays under
                // the finger.
                ..dragStartBehavior = DragStartBehavior.down
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                // Also called when a drag in progress is cancelled. A touch
                // that never became a drag (a tap) leaves a settling sheet be.
                ..onEnd = _handleDragEnd,
            ),
      },
      child: child,
    );
  }

  /// Wraps a part of the sheet so a mouse can drag the sheet by it, as the
  /// handle and the header can.
  Widget wrapMouseDrag(Widget child) => _dragArea(child: child, mouse: true);

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final reduceMotion = panelReduceMotion(context);
    final topInset = MediaQuery.viewPaddingOf(context).top;
    // Drops to zero under the keyboard, which covers the home indicator.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final detached = route.detached;
    // On Android the bottom inset can be the three-button navigation bar,
    // whose buttons have to stay reachable, so a floating sheet sits 12pt
    // above it (PanelUI's `max(insets.bottom + 12, 24)`). On iOS it floats
    // over the home indicator, which only takes a swipe.
    final detachedGap = defaultTargetPlatform == TargetPlatform.android
        ? math.max(bottomInset + 12, _detachedGap)
        : _detachedGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        route._travel = screenHeight;
        // Clamped clear of the status bar and the keyboard, so the content
        // is never under either when the sheet is at its tallest.
        final cap = math.max(
          0.0,
          screenHeight -
              keyboard -
              topInset -
              (detached ? detachedGap : _topClearance),
        );
        final fraction = route.size.fraction;
        final height = fraction == null
            ? null
            : math.min(screenHeight * fraction, cap);

        final sheet = _SheetScope(
          frame: this,
          sized: height != null,
          child: _SheetSurface(
            detached: detached,
            height: height,
            maxHeight: cap,
            // A floating sheet's own margin already clears the system bar, so
            // it takes plain padding rather than stacking the inset on top.
            bottomPadding: detached
                ? _paddingBottom
                : math.max(bottomInset, _paddingBottom),
            handle: route.showHandle
                ? wrapMouseDrag(const _SheetHandle())
                : null,
            close: route.showClose
                ? _SheetCloseButton(
                    label: route.closeLabel,
                    onPressed: route._close,
                  )
                : null,
            child: _content,
          ),
        );

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              left: detached ? _detachedMargin : 0,
              right: detached ? _detachedMargin : 0,
              bottom: keyboard + (detached ? detachedGap : 0),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: detached ? _detachedMaxWidth : _dockedMaxWidth,
              ),
              child: _SheetMotion(
                route: route,
                travel: screenHeight,
                reduceMotion: reduceMotion,
                child: _dragArea(child: sheet),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Moves the sheet with its route and its drag: up from below the screen and
/// back down, or under reduced motion a fade where it rests, plus however far
/// a finger has taken it.
class _SheetMotion extends StatelessWidget {
  const _SheetMotion({
    required this.route,
    required this.travel,
    required this.reduceMotion,
    required this.child,
  });

  final PanelBottomSheetRoute<dynamic> route;

  /// How far below rest the sheet starts and ends: the screen's height.
  final double travel;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: route._motion,
      // Its own layer, so the sheet moves as a finished picture rather than
      // being repainted on every frame of a drag or a spring.
      child: RepaintBoundary(child: child),
      builder: (context, child) {
        final presence = route.animation!.value.clamp(0.0, 1.0);
        final rise = reduceMotion ? 0.0 : (1 - presence) * travel;
        // The fade is always in the tree, so the sheet is not rebuilt if the
        // setting changes while it is open.
        return Opacity(
          opacity: reduceMotion ? panelEase.transform(presence) : 1,
          alwaysIncludeSemantics: true,
          child: Transform.translate(
            offset: Offset(0, rise + route._drag.value),
            child: child,
          ),
        );
      },
    );
  }
}

/// The sheet itself: the popover surface with a border and `shadow-lg`,
/// docked with its top corners rounded or floating with all four, holding
/// the handle, the content and the close button.
class _SheetSurface extends StatelessWidget {
  const _SheetSurface({
    required this.detached,
    required this.height,
    required this.maxHeight,
    required this.bottomPadding,
    required this.handle,
    required this.close,
    required this.child,
  });

  final bool detached;

  /// A sized sheet's height, or null to fit the content up to [maxHeight].
  final double? height;
  final double maxHeight;
  final double bottomPadding;
  final Widget? handle;
  final Widget? close;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final radius = Radius.circular(theme.radii.xxxl);
    final side = BorderSide(color: c.border);
    return Container(
      constraints: height == null
          ? BoxConstraints(maxHeight: maxHeight)
          : BoxConstraints.tightFor(height: height),
      decoration: BoxDecoration(
        color: c.popover,
        // Docked, the bottom edge is not a real edge, and a line along it
        // would be a rule through the middle of nothing.
        border: detached
            ? Border.fromBorderSide(side)
            : Border(top: side, left: side, right: side),
        borderRadius: detached
            ? BorderRadius.all(radius)
            : BorderRadius.vertical(top: radius),
        boxShadow: theme.shadows.lg,
      ),
      // Draws nothing: it is there so Material widgets placed in a sheet find
      // the ancestor they need.
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: theme.typography.style(
            PanelTextSize.base,
            color: c.foreground,
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: c.foreground),
            child: Stack(
              children: [
                Padding(
                  // The handle takes the top padding into itself, so a mouse
                  // has the whole strip to take hold of.
                  padding: EdgeInsets.fromLTRB(
                    _paddingX,
                    handle == null ? _paddingTop : 0,
                    _paddingX,
                    bottomPadding,
                  ),
                  child: Column(
                    mainAxisSize: height == null
                        ? MainAxisSize.min
                        : MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ?handle,
                      Flexible(child: child),
                    ],
                  ),
                ),
                // Last, so it is drawn and hit-tested above any content that
                // reaches the corner.
                if (close != null)
                  PositionedDirectional(
                    top: _closeTop,
                    end: _closeEnd,
                    child: close!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The drag handle: a 40×4 pill in the muted foreground at 30%
/// (`h-1 w-10 rounded-full bg-muted-foreground/30`), under the sheet's 8pt
/// top padding and 12pt above the content (`mb-3`).
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final c = PanelTheme.of(context).colors;
    return Padding(
      padding: const EdgeInsets.only(top: _paddingTop, bottom: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: c.mutedForeground.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// The round close button in a sheet's top trailing corner: a 16pt cross in
/// a 32pt circle in the `muted` fill (`h-8 w-8 rounded-full bg-muted`), whose
/// target reaches 8pt further all round (`hitSlop={8}`).
///
/// It is a plain `Pressable` in PanelUI, so a press dims it to 70% at once
/// (`active:opacity-70`) rather than shrinking it. Hover and focus follow
/// PanelUI's web package: hovered, the circle turns the foreground at 10% and
/// the cross the foreground, over 150ms; focused, it takes a 2pt ring.
class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = PanelTheme.of(context).colors;
    // `transition-[background-color,color] duration-150` on Tailwind's
    // default ease, and none under reduced motion.
    final hoverDuration = panelReduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 150);
    return PanelPressable(
      onPressed: onPressed,
      pressScale: 1,
      hitSlop: const EdgeInsets.all(8),
      semanticLabel: label,
      builder: (context, state) => Opacity(
        opacity: state.pressed ? 0.7 : 1,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: state.hovered ? 1 : 0),
          duration: hoverDuration,
          curve: Curves.fastOutSlowIn,
          builder: (context, hover, _) => Container(
            width: 32,
            height: 32,
            // Centred, so the glyph keeps its own size inside the circle.
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.lerp(
                c.muted,
                c.foreground.withValues(alpha: 0.1),
                hover,
              ),
              shape: BoxShape.circle,
              border: state.focused
                  ? Border.all(
                      color: c.ring,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    )
                  : null,
            ),
            child: PanelIcon(
              PanelIcons.x,
              size: 16,
              color: Color.lerp(c.mutedForeground, c.foreground, hover),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetScrollController extends ScrollController {
  _SheetFrameState? frame;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _SheetScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      controller: this,
    );
  }
}

/// A list position that hands the drag to the sheet when the list has
/// nothing left to scroll, and takes it back when the sheet is at rest.
class _SheetScrollPosition extends ScrollPositionWithSingleContext {
  _SheetScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    required this.controller,
  });

  final _SheetScrollController controller;

  /// Whether a drag on the list is under way. Its release settles the sheet
  /// if the drag has moved it.
  bool _dragging = false;

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    _dragging = true;
    controller.frame?._beginDrag();
    return super.drag(details, dragCancelCallback);
  }

  @override
  void applyUserOffset(double delta) {
    final sheet = controller.frame;
    // A positive delta is the finger moving down. The list keeps the drag
    // until it is at its top (or caught mid-bounce above it); then the
    // sheet takes over and the list holds where it is.
    if (sheet != null &&
        sheet._canDrag &&
        (sheet._offset > 0 || (delta > 0 && pixels <= minScrollExtent))) {
      final leftover = sheet._moveBy(delta);
      // Back at rest: the rest of the stroke is the list's again.
      if (leftover < 0) super.applyUserOffset(leftover);
      return;
    }
    super.applyUserOffset(delta);
  }

  @override
  void goBallistic(double velocity) {
    final sheet = controller.frame;
    if (_dragging) {
      _dragging = false;
      if (sheet != null && sheet._offset != 0) {
        // A scroll velocity is positive for a finger moving up.
        sheet._release(-velocity);
        super.goBallistic(0);
        return;
      }
    }
    super.goBallistic(velocity);
  }
}

/// A spring that stops the moment it reaches its target instead of
/// overshooting and coming back: Reanimated's `overshootClamping`.
class _ClampedAtTarget extends Simulation {
  _ClampedAtTarget(this._inner, {required double target})
    : _target = target,
      _fromBelow = _inner.x(0) < target,
      super(tolerance: _inner.tolerance);

  final Simulation _inner;
  final double _target;
  final bool _fromBelow;

  bool _past(double x) => _fromBelow ? x >= _target : x <= _target;

  @override
  double x(double time) {
    final value = _inner.x(time);
    return _past(value) ? _target : value;
  }

  @override
  double dx(double time) => _past(_inner.x(time)) ? 0 : _inner.dx(time);

  @override
  bool isDone(double time) => _past(_inner.x(time)) || _inner.isDone(time);
}
