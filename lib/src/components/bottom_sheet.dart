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

/// One spring for the whole surface: the sheet arriving and the sheet
/// snapping back after a drag are the same object at the same weight.
///
/// PanelUI gives it in Apple's two designer parameters (420ms, damping ratio
/// 0.9), which map onto a physical spring the way SwiftUI's do. A little
/// under critically damped, so it settles without a bounce: a sheet that
/// overshoots reads as light, and a sheet is not light. Slower than a small
/// state change, because it is a large surface travelling most of the screen.
final SpringDescription _sheetSpring = SpringDescription.withDurationAndBounce(
  duration: const Duration(milliseconds: 420),
  bounce: 0.1,
);

/// Leaving: critically damped and clamped, because a spring allowed to
/// overshoot past the bottom flashes a gap under the sheet on its way back.
final SpringDescription _exitSpring = SpringDescription.withDurationAndBounce(
  duration: const Duration(milliseconds: 380),
);

/// How far a release has to carry the sheet down to dismiss it.
const double _dismissDistance = 120;

/// How fast a downward flick has to be to dismiss whatever the distance.
const double _dismissVelocity = 800;

/// Where a flick would come to rest if it kept decelerating at Apple's
/// default rate. Distance alone makes the sheet heavy: a short fast flick
/// down is unmistakably a dismissal.
double _project(double velocity) {
  const decelerationRate = 0.998;
  return velocity / 1000 * decelerationRate / (1 - decelerationRate);
}

/// The timed fade that replaces the travel under reduced motion.
const Duration _reducedFade = Duration(milliseconds: 150);

const Tolerance _tolerance = Tolerance(distance: 0.0005, velocity: 0.005);

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

bool _reduceMotionAt(BuildContext context) =>
    context
        .getInheritedWidgetOfExactType<MediaQuery>()
        ?.data
        .disableAnimations ??
    false;

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
/// The sheet springs up from below the screen, and the scrim behind it
/// darkens in step with how far up it is. It can be dragged: released past
/// 120pt, or flicked down faster than 800pt/s (or far enough that the flick
/// would carry it past 120pt), it leaves at the speed it was let go;
/// otherwise it springs back. With a mouse it is dragged by its handle and
/// its [PanelBottomSheetHeader], so the content stays free for selecting.
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
/// sheet keeps clear of the status bar and the keyboard, and pads its bottom
/// for the home indicator. Under reduced motion it fades instead of sliding.
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

  // Only used under reduced motion; otherwise springs drive the transition.
  @override
  Duration get transitionDuration => _reducedFade;

  @override
  Duration get reverseTransitionDuration => _reducedFade;

  // A sheet that the scrim cannot close is not closed by the back button
  // either: only its own controls close it.
  @override
  RoutePopDisposition get popDisposition =>
      isDismissible ? super.popDisposition : RoutePopDisposition.doNotPop;

  bool get _reduceMotion =>
      navigator != null && _reduceMotionAt(navigator!.context);

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
    if (forward) {
      return SpringSimulation(
        _sheetSpring,
        controller.value,
        1,
        velocity,
        tolerance: _tolerance,
        snapToEnd: true,
      );
    }
    return _ClampedAtTarget(
      SpringSimulation(
        _exitSpring,
        controller.value,
        0,
        velocity,
        tolerance: _tolerance,
        snapToEnd: true,
      ),
      target: 0,
    );
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

  /// A drag released past the threshold: the route's own exit takes over
  /// from where the finger let go, carrying its speed.
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

  /// How far in the scrim is: the share of the screen the sheet has risen,
  /// so dragging the sheet halfway down lightens the screen by half.
  double _scrimProgress(double travel, bool reduceMotion) {
    final presence = animation!.value.clamp(0.0, 1.0);
    final drag = travel > 0 ? _drag.value / travel : 0.0;
    if (reduceMotion) {
      return panelEase.transform(presence) * (1 - drag.clamp(0.0, 1.0));
    }
    return (presence - drag).clamp(0.0, 1.0);
  }

  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final reduceMotion = panelReduceMotion(context);
            return AnimatedBuilder(
              animation: Listenable.merge([animation!, _drag]),
              builder: (context, _) => PanelOverlayScrim(
                progress: _scrimProgress(constraints.maxHeight, reduceMotion),
                blur: blur,
              ),
            );
          },
        ),
        barrier,
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
      child: _PanelBottomSheetFrame(route: this),
    );
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

/// What the parts of a sheet need from the sheet around them.
class _SheetScope extends InheritedWidget {
  const _SheetScope({
    required this.frame,
    required this.sized,
    required super.child,
  });

  final _PanelBottomSheetFrameState frame;

  /// Whether the sheet has a height of its own for a body to fill.
  final bool sized;

  static _SheetScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetScope>();

  @override
  bool updateShouldNotify(_SheetScope oldWidget) =>
      frame != oldWidget.frame || sized != oldWidget.sized;
}

class _PanelBottomSheetFrame extends StatefulWidget {
  const _PanelBottomSheetFrame({required this.route});

  final PanelBottomSheetRoute<dynamic> route;

  @override
  State<_PanelBottomSheetFrame> createState() => _PanelBottomSheetFrameState();
}

class _PanelBottomSheetFrameState extends State<_PanelBottomSheetFrame> {
  PanelBottomSheetRoute<dynamic> get _route => widget.route;
  AnimationController get _drag => _route._drag;

  /// The drag's offset before the rubber band above rest is applied.
  double _raw = 0;

  /// Scrolling bodies in the sheet. With one, an upward drag at rest is a
  /// scroll, so the sheet stays where it is instead of rubber-banding.
  int _bodies = 0;

  bool get _canDrag => _route.isDismissible && _route.isCurrent;

  /// How far below rest the sheet has been dragged.
  double get _offset => _drag.value;

  void _registerBody() => _bodies++;

  void _unregisterBody() => _bodies--;

  /// Takes over the drag offset, catching the sheet if it is springing back.
  void _beginDrag() {
    _drag.stop();
    final value = _drag.value;
    _raw = value >= 0 ? value : value * 3;
  }

  /// Moves the sheet by [delta], downward positive, and returns the part of
  /// an upward stroke it could not take because it is back at rest, which
  /// belongs to the list underneath.
  double _moveBy(double delta) {
    _raw += delta;
    if (_raw <= 0 && _bodies > 0) {
      final leftover = _raw;
      _raw = 0;
      _drag.value = 0;
      return leftover;
    }
    // Above its resting place the sheet rubber-bands, at a third.
    _drag.value = _raw > 0 ? _raw : _raw / 3;
    return 0;
  }

  /// Settles a drag released at [velocity], downward positive: it leaves,
  /// or it springs back carrying the speed it was let go at.
  void _release(double velocity) {
    final offset = _drag.value;
    // Velocity decides as much as distance does, and the exit is handed it
    // rather than only consulting it.
    final projected = offset + _project(velocity);
    if (_canDrag &&
        offset >= 0 &&
        (projected > _dismissDistance || velocity > _dismissVelocity)) {
      _route._dismissFromDrag(velocity);
      return;
    }
    // A drag that never moved the sheet is not the sheet's to settle.
    if (offset == 0) return;
    if (!mounted || panelReduceMotion(context)) {
      _drag.value = 0;
    } else {
      _drag.animateWith(
        SpringSimulation(
          _sheetSpring,
          offset,
          0,
          velocity,
          tolerance: _tolerance,
          snapToEnd: true,
        ),
      );
    }
    // It caught rather than went: a knock at the moment it commits to staying.
    HapticFeedback.mediumImpact();
  }

  /// Makes [child] a handle the sheet can be dragged by, with [mouse] taking
  /// part as well as touch.
  Widget _dragArea({required Widget child, bool mouse = false}) {
    if (!_route.isDismissible) return child;
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
                ..onStart = (_) {
                  if (_canDrag) _beginDrag();
                }
                ..onUpdate = (details) {
                  if (_canDrag) _moveBy(details.primaryDelta ?? 0);
                }
                // Also called when a drag in progress is cancelled. A touch
                // that never became a drag (a tap) leaves a settling sheet be.
                ..onEnd = (details) {
                  _release(details.primaryVelocity ?? 0);
                },
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
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final reduceMotion = panelReduceMotion(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    // Drops to zero under the keyboard, which covers the home indicator.
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final detached = route.detached;

    // On Android the bottom inset can be the three-button navigation bar,
    // whose buttons have to stay reachable, so a floating sheet sits above it.
    // On iOS it floats over the home indicator, which only takes a swipe.
    final detachedGap = defaultTargetPlatform == TargetPlatform.android
        ? math.max(safeBottom + 12, 24.0)
        : 24.0;

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
              viewPadding.top -
              (detached ? detachedGap : 8),
        );
        final fraction = route.size.fraction;
        final sizedHeight = fraction == null
            ? null
            : math.min(screenHeight * fraction, cap);
        final radius = Radius.circular(theme.radii.xxxl);
        final side = BorderSide(color: c.border);

        final content = Column(
          mainAxisSize: sizedHeight == null
              ? MainAxisSize.min
              : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (route.showHandle)
              wrapMouseDrag(
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
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
                ),
              ),
            Flexible(child: Builder(builder: route.builder)),
          ],
        );

        Widget sheet = Container(
          constraints: sizedHeight == null
              ? BoxConstraints(maxHeight: cap)
              : BoxConstraints.tightFor(height: sizedHeight),
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
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  route.showHandle ? 0 : 8,
                  20,
                  detached ? 16 : math.max(safeBottom, 16),
                ),
                child: content,
              ),
              // Last, so it is drawn and hit-tested above any content that
              // reaches the corner.
              if (route.showClose)
                PositionedDirectional(
                  top: 12 - 8,
                  end: 16 - 8,
                  child: _SheetCloseButton(
                    label: route.closeLabel,
                    onPressed: route._close,
                  ),
                ),
            ],
          ),
        );

        sheet = _SheetScope(
          frame: this,
          sized: sizedHeight != null,
          child: Material(
            type: MaterialType.transparency,
            child: DefaultTextStyle(
              style: theme.typography.style(
                PanelTextSize.base,
                color: c.foreground,
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: c.foreground),
                child: sheet,
              ),
            ),
          ),
        );

        sheet = _dragArea(child: sheet);

        sheet = AnimatedBuilder(
          animation: Listenable.merge([route.animation!, _drag]),
          child: sheet,
          builder: (context, child) {
            final presence = route.animation!.value.clamp(0.0, 1.0);
            final travel = reduceMotion ? 0.0 : (1 - presence) * screenHeight;
            // Under reduced motion the sheet fades where it rests instead of
            // travelling; the fade is always in the tree so the sheet is not
            // rebuilt if the setting changes while it is open.
            return Opacity(
              opacity: reduceMotion ? panelEase.transform(presence) : 1,
              alwaysIncludeSemantics: true,
              child: Transform.translate(
                offset: Offset(0, travel + _drag.value),
                child: child,
              ),
            );
          },
        );

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              left: detached ? 16 : 0,
              right: detached ? 16 : 0,
              bottom: keyboard + (detached ? detachedGap : 0),
            ),
            child: ConstrainedBox(
              // Wide screens keep a sheet a sheet: PanelUI's web package caps a
              // floating one at max-w-lg and a docked one at max-w-2xl.
              constraints: BoxConstraints(maxWidth: detached ? 512 : 672),
              child: sheet,
            ),
          ),
        );
      },
    );
  }
}

/// The round close button in a sheet's top trailing corner: 32pt to the eye,
/// 48pt to the finger.
class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = PanelTheme.of(context).colors;
    return PanelPressable(
      onPressed: onPressed,
      pressScale: 1,
      pressOpacity: 0.7,
      semanticLabel: label,
      builder: (context, state) {
        final active = state.hovered;
        return SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: 32,
              height: 32,
              // Centred, so the glyph keeps its own size inside the circle.
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? c.foreground.withValues(alpha: 0.1) : c.muted,
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
                color: active ? c.foreground : c.mutedForeground,
              ),
            ),
          ),
        );
      },
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
      padding: const EdgeInsetsDirectional.only(end: 48, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (title != null)
            Semantics(
              container: true,
              header: true,
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

/// The scrolling part of a sheet. Place it directly in the sheet's column.
///
/// In a sheet with a [PanelBottomSheetSize] other than auto it fills what the
/// header and footer leave; in an auto sheet it is as tall as its content and
/// scrolls once the sheet has grown as tall as the screen allows.
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
  _PanelBottomSheetFrameState? _frame;

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

  @override
  Widget build(BuildContext context) {
    final sized = _SheetScope.maybeOf(context)?.sized ?? false;
    final scroll = ScrollConfiguration(
      // At the top a pull moves the sheet, and an overscroll effect would draw
      // the content stretching inside a sheet that is already moving.
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
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
    return sized ? Expanded(child: scroll) : Flexible(child: scroll);
  }
}

class _SheetScrollController extends ScrollController {
  _PanelBottomSheetFrameState? frame;

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

  /// Whether the sheet has the current drag, and so its release.
  bool _sheetHasDrag = false;

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    _sheetHasDrag = false;
    final sheet = controller.frame;
    if (sheet != null && sheet._canDrag) sheet._beginDrag();
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
      _sheetHasDrag = true;
      final leftover = sheet._moveBy(delta);
      if (leftover < 0) {
        // Back at rest: the rest of the stroke is the list's again.
        _sheetHasDrag = false;
        super.applyUserOffset(leftover);
      }
      return;
    }
    super.applyUserOffset(delta);
  }

  @override
  void goBallistic(double velocity) {
    if (_sheetHasDrag) {
      _sheetHasDrag = false;
      // A scroll velocity is positive for a finger moving up.
      controller.frame?._release(-velocity);
      super.goBallistic(0);
      return;
    }
    super.goBallistic(velocity);
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
