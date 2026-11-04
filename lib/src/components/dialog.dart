import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';

import '../foundation/overlay_capture.dart';
import '../foundation/overlay_scrim.dart';
import '../foundation/panel_decoration.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// The space between the dialog and the edges of the screen, `p-6`.
const double _screenMargin = 24;

/// The padding inside a dialog, `p-5`. A panel footer bleeds back out through
/// exactly this much, so the two move together.
const double _dialogPadding = 20;

/// The gap between the parts of a dialog, `gap-1.5`.
const double _gap = 6;

/// How far a plain footer sits below the content, on top of the gap: `mt-4`.
const double _plainFooterMargin = 16;

/// How far a panel footer sits below the content, on top of the gap: `mt-5`.
const double _panelFooterMargin = 20;

/// A panel footer's padding above and below its buttons.
const double _panelFooterPaddingY = 16;

/// The gap between the footer's buttons, `gap-2`.
const double _actionGap = 8;

/// The dialog's layer fading in and out, `FadeIn.duration(150)` and
/// `FadeOut.duration(150)`. The scrim and the dialog both sit in it.
const Duration _layerFade = Duration(milliseconds: 150);

/// The dialog's own fade-out, `FadeOut.duration(120)`
/// ([PanelDurations.fadeOut]), as the stretch of the layer's fade-out it
/// takes up.
final Curve _boxExit = Interval(
  1 - PanelDurations.fadeOut.inMicroseconds / _layerFade.inMicroseconds,
  1,
  curve: panelEase,
);

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

/// Shows a dialog over the app and returns the value it is popped with.
///
/// The dialog and the scrim behind it fade in over 150ms, the scrim also
/// running its own fade inside that one, to a 50% dim (or a frost, with
/// [blur]). The dialog zooms in from nothing on a spring (damping 18,
/// stiffness 250, mass 0.6) that lands with a slight overshoot. It leaves
/// with a fade: the layer over 150ms, the dialog itself over the first 120ms
/// of that.
///
/// Under reduced motion the zoom is dropped and the fades remain, as
/// PanelUI's toast and sheet keep theirs: a dialog that appears with no
/// transition at all is a jump-cut, and it is travel and scale that the
/// setting is about.
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
/// It centres what [builder] returns 24pt clear of the screen's edges, as
/// PanelUI does, draws the scrim behind it, and runs PanelUI's entrance and
/// exit. It also keeps the dialog clear of the keyboard, which PanelUI leaves
/// to the app: a dialog with a field in it would otherwise have its buttons
/// under the keyboard while the field is being typed in.
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

  // The scrim is drawn by buildModalBarrier, with PanelUI's own fades.
  @override
  Color? get barrierColor => null;

  @override
  Duration get transitionDuration => _layerFade;

  @override
  Duration get reverseTransitionDuration => _layerFade;

  // A dialog that the scrim cannot close is not closed by the back button
  // either: it is there to be answered.
  @override
  RoutePopDisposition get popDisposition =>
      barrierDismissible ? super.popDisposition : RoutePopDisposition.doNotPop;

  /// The opacity of the layer the scrim sits in. Leaving, the scrim also
  /// fades itself out over the same 150ms inside that layer, so it goes at
  /// the square of the layer's fade. (Coming in, its own fade is the
  /// scrim's to run.)
  double _scrimOpacity() {
    final fade = animation!;
    final layer = panelEase.transform(fade.value);
    return fade.status == AnimationStatus.reverse ? layer * layer : layer;
  }

  @override
  Widget buildModalBarrier() {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: animation!,
          builder: (context, _) =>
              PanelOverlayScrim(opacity: _scrimOpacity(), blur: blur),
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
    final theme = PanelTheme.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: DisplayFeatureSubScreen(
        anchorPoint: anchorPoint,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _screenMargin,
            _screenMargin,
            _screenMargin,
            _screenMargin + keyboard,
          ),
          child: Center(
            child: _DialogTransition(
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
    );
  }
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
/// heading and the actions, which stay put; PanelUI's dialog would run off
/// the screen instead.
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
    Widget dialog = Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: PanelBoxDecoration(
        color: c.popover,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(theme.radii.xxl),
        boxShadow: theme.shadows.lg,
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: c.foreground),
        // In a route the dialog has a height to keep within, and its body
        // gives way and scrolls; laid out in a scrolling page it is as tall
        // as it is.
        child: LayoutBuilder(
          builder: (context, constraints) => _DialogLayout(
            bounded: constraints.hasBoundedHeight,
            title: title,
            description: description,
            body: child,
            actions: actions,
            footerVariant: footerVariant,
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

/// The dialog's own motion inside the route's: a fade that matches the
/// layer's, a spring zoom in from nothing (`ZoomIn` with PanelUI's dialog
/// spring), and a quicker fade out.
class _DialogTransition extends StatefulWidget {
  const _DialogTransition({required this.animation, required this.child});

  /// The route's animation: the layer's 150ms fade.
  final Animation<double> animation;
  final Widget child;

  @override
  State<_DialogTransition> createState() => _DialogTransitionState();
}

class _DialogTransitionState extends State<_DialogTransition>
    with SingleTickerProviderStateMixin {
  // Unbounded, so the spring's overshoot past full size survives.
  late final AnimationController _zoom = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  late Listenable _ticks = Listenable.merge([widget.animation, _zoom]);
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
  void didUpdateWidget(_DialogTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      _ticks = Listenable.merge([widget.animation, _zoom]);
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
      animation: _ticks,
      // Its own layer, so the zoom moves a finished picture of the dialog
      // rather than repainting it on every frame.
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final route = widget.animation;
        var opacity = panelEase.transform(route.value);
        if (route.status == AnimationStatus.reverse) {
          opacity *= _boxExit.transform(route.value);
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

/// The inside of a dialog: the heading, the body and the footer.
class _DialogLayout extends StatelessWidget {
  const _DialogLayout({
    required this.bounded,
    required this.title,
    required this.description,
    required this.body,
    required this.actions,
    required this.footerVariant,
  });

  /// Whether there is a height to keep within, so the body has to scroll.
  final bool bounded;
  final Widget? title;
  final Widget? description;
  final Widget? body;
  final List<Widget> actions;
  final PanelDialogFooterVariant footerVariant;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final panel =
        actions.isNotEmpty && footerVariant == PanelDialogFooterVariant.panel;

    Widget? content = body;
    if (content != null) {
      content = DefaultTextStyle(
        style: theme.typography.style(
          PanelTextSize.base,
          color: theme.colors.foreground,
        ),
        child: content,
      );
      if (bounded) {
        content = Flexible(child: SingleChildScrollView(child: content));
      }
    }

    final column = Padding(
      // A panel footer reaches the bottom edge itself, in place of the padding.
      padding: EdgeInsets.fromLTRB(
        _dialogPadding,
        _dialogPadding,
        _dialogPadding,
        panel ? 0 : _dialogPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _gap,
        children: [
          if (title != null) PanelDialogTitle(child: title!),
          if (description != null) PanelDialogDescription(child: description!),
          ?content,
          if (actions.isNotEmpty && !panel)
            Padding(
              padding: const EdgeInsets.only(top: _plainFooterMargin),
              child: _DialogActions(actions: actions),
            ),
        ],
      ),
    );
    if (!panel) return column;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bounded) Flexible(child: column) else column,
        _DialogFooterBand(child: _DialogActions(actions: actions)),
      ],
    );
  }
}

/// The footer's buttons: a row at the end, `flex-row justify-end gap-2`.
///
/// Where the labels cannot fit across (a narrow screen, a large text size)
/// they stack instead, which a flex row in PanelUI would not do: there they
/// would run out of the dialog.
class _DialogActions extends StatelessWidget {
  const _DialogActions({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return OverflowBar(
      alignment: MainAxisAlignment.end,
      spacing: _actionGap,
      overflowSpacing: _actionGap,
      overflowAlignment: OverflowBarAlignment.end,
      children: actions,
    );
  }
}

/// A panel footer: a band in the `inset` tint with a rule across the top,
/// bled out through the dialog's padding to its edges and bottom corners
/// (`mt-5 rounded-b-2xl border-t border-border bg-inset`, 16pt above and
/// below the buttons).
class _DialogFooterBand extends StatelessWidget {
  const _DialogFooterBand({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final corner = Radius.circular(theme.radii.xxl);
    return Container(
      margin: const EdgeInsets.only(top: _gap + _panelFooterMargin),
      padding: const EdgeInsets.symmetric(
        horizontal: _dialogPadding,
        vertical: _panelFooterPaddingY,
      ),
      decoration: BoxDecoration(
        color: theme.colors.inset,
        border: Border(top: BorderSide(color: theme.colors.border)),
        borderRadius: BorderRadius.only(
          bottomLeft: corner,
          bottomRight: corner,
        ),
      ),
      child: child,
    );
  }
}
