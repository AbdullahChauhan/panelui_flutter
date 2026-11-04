import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// The springs PanelUI animates with.
///
/// PanelUI runs its motion on Reanimated, whose springs are parameterised by
/// mass, stiffness and damping exactly as Flutter's [SpringDescription] is, so
/// these are the same physical springs rather than approximations of them.
abstract final class PanelSprings {
  /// Release of a pressed control back to rest.
  static const SpringDescription press = SpringDescription(
    mass: 0.4,
    stiffness: 300,
    damping: 20,
  );

  /// A switch thumb crossing its track.
  static const SpringDescription toggle = SpringDescription(
    mass: 0.5,
    stiffness: 250,
    damping: 18,
  );

  /// A checkbox fill or a radio dot arriving.
  static const SpringDescription check = SpringDescription(
    mass: 0.5,
    stiffness: 300,
    damping: 15,
  );

  /// A selection indicator sliding between tabs or segments.
  static const SpringDescription indicator = SpringDescription(
    mass: 0.7,
    stiffness: 300,
    damping: 24,
  );

  /// A dialog zooming in.
  static const SpringDescription dialog = SpringDescription(
    mass: 0.6,
    stiffness: 250,
    damping: 18,
  );

  /// A toast settling into place.
  static const SpringDescription toast = SpringDescription(
    mass: 0.6,
    stiffness: 260,
    damping: 20,
  );
}

/// The fixed durations PanelUI uses alongside its springs.
abstract final class PanelDurations {
  /// The press-in half of press feedback.
  static const Duration pressIn = Duration(milliseconds: 80);

  /// A form field's border crossing to its focused colour.
  static const Duration focus = Duration(milliseconds: 150);

  /// A scrim or an overlay fading in.
  static const Duration fadeIn = Duration(milliseconds: 150);

  /// A scrim or an overlay fading out.
  static const Duration fadeOut = Duration(milliseconds: 120);

  /// A checkbox or radio emptying.
  static const Duration uncheck = Duration(milliseconds: 120);
}

/// Reanimated's default `withTiming` easing, used for every timed animation.
const Curve panelEase = Curves.easeInOutQuad;

/// Spring-driven animation on an [AnimationController].
extension PanelAnimationControllerX on AnimationController {
  /// Animates towards [target] with [spring], carrying the current velocity
  /// so an interrupted animation turns around smoothly.
  ///
  /// Use an unbounded controller for a spring that overshoots; a bounded one
  /// clamps the overshoot away.
  TickerFuture springTo(double target, SpringDescription spring) {
    final simulation = SpringSimulation(
      spring,
      value,
      target,
      velocity,
      tolerance: const Tolerance(distance: 0.0005, velocity: 0.005),
      snapToEnd: true,
    );
    return animateWith(simulation);
  }
}

/// Whether the platform asked for reduced motion.
bool panelReduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
