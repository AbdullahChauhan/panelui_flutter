import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';

import '../foundation/overlay_capture.dart';
import '../foundation/overlay_scrim.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// The padding inside a [PanelDialog], `p-5`. A panel footer bleeds back out
/// through exactly this much, so the two move together.
const double _dialogPadding = 20;

/// The scrim's fade in each direction. PanelUI fades the dialog's layer in
/// over 150ms and out over 150ms; the box itself leaves faster, over the
/// first 120ms of that.
const Duration _scrimFade = Duration(milliseconds: 150);

/// The box's own fade-out, [PanelDurations.fadeOut] (120ms), as the part of
/// the 150ms reverse transition it occupies.
final Curve _contentExit = Interval(
  1 - PanelDurations.fadeOut.inMicroseconds / _scrimFade.inMicroseconds,
  1,
  curve: panelEase,
);

/// Shows a dialog over the app and returns the value it is popped with.
///
/// The screen behind fades to a 50% dim over 150ms (or frosts, with [blur]),
/// and the dialog zooms in from nothing on a spring (damping 18, stiffness
/// 250, mass 0.6) that lands with a slight overshoot. It leaves with a fade.
/// Under reduced motion the zoom is dropped and only the fades remain.
///
/// ```dart
/// final delete = await showPanelDialog<bool>(
///   context,
///   builder: (context) => PanelDialog(
///     title: const Text('Delete project?'),
///     description: const Text('This action cannot be undone.'),
///     actions: [
///       PanelButton(
///         variant: PanelButtonVariant.ghost,
///         size: PanelButtonSize.sm,
///         onPressed: () => Navigator.pop(context, false),
///         child: const Text('Cancel'),
///       ),
///       PanelButton(
///         variant: PanelButtonVariant.destructive,
///         size: PanelButtonSize.sm,
///         onPressed: () => Navigator.pop(context, true),
///         child: const Text('Delete'),
///       ),
///     ],
///   ),
/// );
/// ```
///
/// A tap on the scrim, Escape and the system back button close it with a
/// null result, unless [barrierDismissible] is false, in which case only the
/// dialog's own controls can. Focus moves into the dialog, stays there while
/// it is open, and returns to where it was when it closes.
///
/// [barrierLabel] names the scrim for screen readers ("Close dialog" by
/// default). The dialog is pushed on the root navigator unless
/// [useRootNavigator] is false.
Future<T?> showPanelDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool blur = false,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  bool? requestFocus,
  TraversalEdgeBehavior? traversalEdgeBehavior,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final wrap = panelCaptureThemes(context, navigator.context);
  return navigator.push<T>(
    PanelDialogRoute<T>(
      builder: (context) => wrap(builder(context)),
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      blur: blur,
      settings: routeSettings,
      anchorPoint: anchorPoint,
      requestFocus: requestFocus,
      traversalEdgeBehavior: traversalEdgeBehavior,
    ),
  );
}

/// The route [showPanelDialog] pushes, for code that pushes routes itself.
///
/// It centres what [builder] returns, at least 24pt from the screen's edges
/// and clear of the keyboard, draws the scrim behind it, and runs PanelUI's
/// entrance and exit.
class PanelDialogRoute<T> extends PopupRoute<T> {
  /// Creates a dialog route.
  PanelDialogRoute({
    required this.builder,
    bool barrierDismissible = true,
    String? barrierLabel,
    this.blur = false,
    this.anchorPoint,
    super.settings,
    super.requestFocus,
    super.traversalEdgeBehavior,
    super.directionalTraversalEdgeBehavior,
  }) : _barrierDismissible = barrierDismissible,
       _barrierLabel = barrierLabel;

  /// Builds the dialog, usually a [PanelDialog].
  final WidgetBuilder builder;

  /// Frost the screen behind instead of dimming it.
  final bool blur;

  /// Which side of a display feature (a hinge or a fold) the dialog opens on.
  final Offset? anchorPoint;

  final bool _barrierDismissible;
  final String? _barrierLabel;

  /// Whether a tap on the scrim, Escape or the back button closes the
  /// dialog. When false, only the dialog's own controls can.
  @override
  bool get barrierDismissible => _barrierDismissible;

  /// The scrim's accessible name, "Close dialog" unless given.
  @override
  String get barrierLabel => _barrierLabel ?? 'Close dialog';

  // The scrim is drawn by buildModalBarrier, with PanelUI's own curve.
  @override
  Color? get barrierColor => null;

  @override
  Duration get transitionDuration => _scrimFade;

  @override
  Duration get reverseTransitionDuration => _scrimFade;

  // A dialog that the scrim cannot close is not closed by the back button
  // either: it is there to be answered.
  @override
  RoutePopDisposition get popDisposition =>
      barrierDismissible ? super.popDisposition : RoutePopDisposition.doNotPop;

  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    final fade = animation!;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: fade,
          builder: (context, _) => PanelOverlayScrim(
            progress: panelEase.transform(fade.value.clamp(0.0, 1.0)),
            blur: blur,
          ),
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
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final theme = PanelTheme.of(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: DisplayFeatureSubScreen(
        anchorPoint: anchorPoint,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: SafeArea(
            minimum: const EdgeInsets.all(24),
            child: Center(
              child: _PanelDialogTransition(
                animation: animation,
                // Draws nothing: it is there so Material widgets placed in a
                // dialog find the ancestor they need.
                child: Material(
                  type: MaterialType.transparency,
                  child: DefaultTextStyle(
                    style: theme.typography.style(
                      PanelTextSize.base,
                      color: theme.colors.foreground,
                    ),
                    child: Builder(builder: builder),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dialog's own motion: a fade that matches the scrim's, a spring zoom
/// in from nothing, and a quicker fade out.
class _PanelDialogTransition extends StatefulWidget {
  const _PanelDialogTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_PanelDialogTransition> createState() => _PanelDialogTransitionState();
}

class _PanelDialogTransitionState extends State<_PanelDialogTransition>
    with SingleTickerProviderStateMixin {
  // Unbounded, so the spring's overshoot past full size survives.
  late final AnimationController _zoom = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // A route added without a transition (restored, say) arrives at rest.
    final entering = widget.animation.status == AnimationStatus.forward;
    if (entering && !panelReduceMotion(context)) {
      _zoom.value = 0;
      _zoom.springTo(1, PanelSprings.dialog);
    }
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _zoom]),
      child: widget.child,
      builder: (context, child) {
        final value = widget.animation.value;
        var opacity = panelEase.transform(value.clamp(0.0, 1.0));
        if (widget.animation.status == AnimationStatus.reverse) {
          opacity *= _contentExit.transform(value.clamp(0.0, 1.0));
        }
        return Opacity(
          opacity: opacity,
          alwaysIncludeSemantics: true,
          child: Transform.scale(scale: _zoom.value, child: child),
        );
      },
    );
  }
}

/// Whether a dialog's footer draws a surface of its own.
enum PanelDialogFooterVariant {
  /// Part of the dialog: the same fill, under the content with a gap above.
  plain,

  /// A band set into the dialog: a rule across the top, a step darker, out
  /// to the dialog's edges and bottom corners. It separates what the dialog
  /// says from what you can do about it, which is worth it on a dialog with
  /// a form in it, where the buttons are otherwise one more row of fields.
  panel,
}

/// The box a dialog is drawn in: a title, a description, a body and a row of
/// actions, on the `popover` surface with a border and PanelUI's `shadow-lg`.
///
/// ```dart
/// PanelDialog(
///   title: const Text('Edit profile'),
///   description: const Text("Make changes here. Save when you're done."),
///   footerVariant: PanelDialogFooterVariant.panel,
///   actions: [cancelButton, saveButton],
///   child: Column(children: [nameField, usernameField]),
/// )
/// ```
///
/// It fills the width it is given up to [maxWidth] (`max-w-sm`, 384pt). When
/// the content is taller than the room there is, [child] scrolls between the
/// heading and the actions, which stay put.
class PanelDialog extends StatelessWidget {
  /// Creates a dialog box.
  const PanelDialog({
    super.key,
    this.title,
    this.description,
    this.child,
    this.actions = const [],
    this.footerVariant = PanelDialogFooterVariant.plain,
    this.maxWidth = 384,
    this.semanticLabel,
  });

  /// The heading, styled as [PanelDialogTitle]. It names the dialog for
  /// screen readers.
  final Widget? title;

  /// A sentence under the title, styled as [PanelDialogDescription].
  final Widget? description;

  /// The body, such as a form.
  final Widget? child;

  /// The buttons, laid out in a row at the end of the footer, or stacked
  /// when they cannot fit across.
  final List<Widget> actions;

  /// Plain or panel.
  final PanelDialogFooterVariant footerVariant;

  /// The widest the dialog grows.
  final double maxWidth;

  /// Names the dialog for screen readers when it has no [title].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final panelFooter =
        actions.isNotEmpty && footerVariant == PanelDialogFooterVariant.panel;
    final radius = theme.radii.xxl;

    // A row at the end, as in PanelUI. Where the labels cannot fit across
    // (a narrow screen, a large text size) the actions stack instead of
    // overflowing.
    final row = OverflowBar(
      alignment: MainAxisAlignment.end,
      spacing: 8,
      overflowSpacing: 8,
      overflowAlignment: OverflowBarAlignment.end,
      children: actions,
    );

    Widget dialog = LayoutBuilder(
      builder: (context, constraints) {
        // Inside a route the dialog has a height to stay within, and the body
        // gives way; laid out in a scrolling page it is as tall as it is.
        final bounded = constraints.hasBoundedHeight;
        Widget? body = child;
        if (body != null) {
          body = DefaultTextStyle(
            style: theme.typography.style(
              PanelTextSize.base,
              color: c.foreground,
            ),
            child: body,
          );
          if (bounded) {
            body = Flexible(child: SingleChildScrollView(child: body));
          }
        }

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            if (title != null) PanelDialogTitle(child: title!),
            if (description != null)
              PanelDialogDescription(child: description!),
            ?body,
            if (actions.isNotEmpty && !panelFooter)
              Padding(padding: const EdgeInsets.only(top: 16), child: row),
          ],
        );

        final padded = Padding(
          padding: EdgeInsets.fromLTRB(
            _dialogPadding,
            _dialogPadding,
            _dialogPadding,
            panelFooter ? 0 : _dialogPadding,
          ),
          child: content,
        );
        if (!panelFooter) return padded;

        // The band's corners follow the inside of the dialog's border, so the
        // tint does not paint over the hairline where the two curves meet.
        final inner = Radius.circular((radius - 1).clamp(0.0, radius));
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bounded) Flexible(child: padded) else padded,
            Container(
              // `gap-1.5` from the content, then `mt-5`.
              margin: const EdgeInsets.only(top: 6 + 20),
              padding: const EdgeInsets.symmetric(
                horizontal: _dialogPadding,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: c.inset,
                border: Border(top: BorderSide(color: c.border)),
                borderRadius: BorderRadius.only(
                  bottomLeft: inner,
                  bottomRight: inner,
                ),
              ),
              child: row,
            ),
          ],
        );
      },
    );

    dialog = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.popover,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: theme.shadows.lg,
          ),
          child: Padding(
            // The border's own width, which a CSS border-box sits inside.
            padding: const EdgeInsets.all(1),
            child: IconTheme.merge(
              data: IconThemeData(color: c.foreground),
              child: dialog,
            ),
          ),
        ),
      ),
    );

    if (semanticLabel != null) {
      dialog = Semantics(
        namesRoute: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: dialog,
      );
    }
    return dialog;
  }
}

/// A dialog's title: large and semibold. It names the dialog's route, so a
/// screen reader announces it when the dialog opens.
class PanelDialogTitle extends StatelessWidget {
  /// Styles [child] as a dialog title.
  const PanelDialogTitle({super.key, required this.child});

  /// The title, usually a [Text].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return Semantics(
      container: true,
      header: true,
      namesRoute: true,
      child: DefaultTextStyle(
        style: theme.typography.style(
          PanelTextSize.lg,
          weight: FontWeight.w600,
          color: theme.colors.popoverForeground,
        ),
        child: child,
      ),
    );
  }
}

/// A dialog's description: small and muted.
class PanelDialogDescription extends StatelessWidget {
  /// Styles [child] as a dialog description.
  const PanelDialogDescription({super.key, required this.child});

  /// The description, usually a [Text].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return DefaultTextStyle(
      style: theme.typography.style(
        PanelTextSize.sm,
        color: theme.colors.mutedForeground,
      ),
      child: child,
    );
  }
}
