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

  /// A toast arriving. Heavy (Reanimated's default spring with its mass set
  /// to 3), so it settles without a visible overshoot over its short travel.
  static const SpringDescription toastEnter = SpringDescription(
    mass: 3,
    stiffness: 900,
    damping: 120,
  );

  /// A toast deck reshuffling after an arrival or a dismissal. Slower and
  /// softer than a drag's spring: the cards behind are not what the reader is
  /// acting on, and a stack that snaps draws the eye to the wrong thing.
  static final SpringDescription stack =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 350),
        bounce: 0.1,
      );

  /// A bottom sheet arriving, or snapping back after a drag: one spring, as
  /// both are the same surface at the same weight.
  ///
  /// PanelUI gives it in Apple's designer parameters (420ms, damping ratio
  /// 0.9). A little under critically damped, so it settles without a bounce:
  /// a sheet that overshoots reads as light, and a sheet is not light.
  static final SpringDescription sheet =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 420),
        bounce: 0.1,
      );

  /// A bottom sheet leaving: critically damped, because a spring allowed to
  /// overshoot past the bottom flashes a gap under the sheet on its way out.
  static final SpringDescription sheetExit =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 380),
      );

  /// A swipeable tab strip settling, whether it was thrown or a trigger was
  /// pressed.
  static const SpringDescription strip = SpringDescription(
    mass: 0.6,
    stiffness: 240,
    damping: 22,
  );

  /// A tooltip settling in from 90% scale.
  static const SpringDescription tooltip = SpringDescription(
    mass: 0.5,
    stiffness: 300,
    damping: 20,
  );

  /// A measured fill (a progress bar, a meter) settling onto a new value.
  /// Callers clamp it to the span of the move: the number is the information,
  /// and an overshoot past it would misreport it.
  static const SpringDescription fill = SpringDescription(
    mass: 0.6,
    stiffness: 180,
    damping: 20,
  );

  /// A slider thumb springing onto its resting step after a drag, a press on
  /// the track or a key. The drag itself follows the finger 1:1.
  static const SpringDescription snap = SpringDescription(
    mass: 0.6,
    stiffness: 220,
    damping: 18,
  );

  /// A slider knob settling between its idle and held sizes.
  static const SpringDescription knob = SpringDescription(
    mass: 0.5,
    stiffness: 200,
    damping: 15,
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
