import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../foundation/overlay_capture.dart';
import '../foundation/panel_decoration.dart';
import '../foundation/panel_focus_ring.dart';
import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';
import 'button.dart';

/// How far a toast travels on entry and on exit.
const double _enterOffset = 100;

/// The departure: the way it came, a little quicker, on an ease-out, so the
/// first frames of the exit already move.
const Duration _exitDuration = Duration(milliseconds: 240);
const Curve _exitCurve = Cubic(0.23, 1, 0.32, 1);

/// Scale of a toast while a finger is on it, reached over 120ms.
const double _pressScale = 0.995;
const Duration _pressDuration = Duration(milliseconds: 120);

/// How far a finger travels before a swipe takes the touch, PanelUI's
/// `activeOffsetY([-12, 12])`: a press on the action or the close button
/// under it is cancelled from then on.
const double _swipeSlop = 12;

/// Drag distance past which a release dismisses.
const double _dismissDistance = 50;

/// Fling speed past which a release dismisses regardless of distance.
const double _dismissVelocity = 500;

/// How far a toast can be dragged away from its edge before it stops moving,
/// and over how much travel it gets there.
const double _rubberBandLimit = 40;
const double _rubberBandTravel = 400;

/// Reanimated's default decay rate (0.998 per millisecond), per second.
final double _decayDrag = math.pow(0.998, 1000).toDouble();

/// The newest toasts at each edge; the one behind them fades out rather
/// than stacking off-screen.
const int _maxVisible = 3;

/// How far each toast behind the front one peeks out.
const double _stackOffset = 10;

/// Scale of the toast one step back in the deck.
const double _stackScaleStep = 0.97;

/// The gap between toasts when the deck is spread into a list.
const double _spreadGap = 10;

/// The spread, PanelUI's web transition for it.
const Duration _spreadDuration = Duration(milliseconds: 450);
const Curve _spreadCurve = Cubic(0.22, 1, 0.36, 1);

/// From 640pt wide (Tailwind's `sm`) a toast stands 24pt in from the screen's
/// edges and is at most 360pt wide, as on PanelUI's web. Narrower, it spans
/// the screen less 16pt each side, as PanelUI's native toasts do.
const double _wideScreen = 640;
const double _wideMargin = 24;
const double _wideMaxWidth = 360;
const double _margin = 16;

/// The status a toast reports.
enum PanelToastVariant {
  /// PanelUI's `default`: a neutral note in the popover's own colours.
  neutral,

  /// Something worth knowing.
  info,

  /// Something went right.
  success,

  /// Something needs attention.
  warning,

  /// Something went wrong.
  destructive,
}

/// Where on the screen toasts gather. Each position keeps a deck of its own.
///
/// PanelUI's native toasts gather at the top or the bottom, across the
/// screen less a 16pt margin, so on a phone the start, the centre and the
/// end of an edge are the same place. The corners come from its web package:
/// from 640pt wide a toast is at most 360pt, with a 24pt margin, and the
/// three differ.
enum PanelToastPosition {
  /// The top edge, centred.
  top(true, 0),

  /// The top edge, at the start: the left in a left-to-right app.
  topStart(true, -1),

  /// The top edge, at the end: the right in a left-to-right app.
  topEnd(true, 1),

  /// The bottom edge, centred. The default.
  bottom(false, 0),

  /// The bottom edge, at the start.
  bottomStart(false, -1),

  /// The bottom edge, at the end.
  bottomEnd(false, 1);

  const PanelToastPosition(this._top, this._x);

  final bool _top;
  final double _x;
}

/// Builds a toast's content for [showPanelToast]. [toast] closes it.
typedef PanelToastBuilder =
    Widget Function(BuildContext context, PanelToastHandle toast);

/// Shows a toast, a short notification that leaves on its own, and returns
/// a handle to close it early.
///
/// ```dart
/// showPanelToast(
///   context,
///   variant: PanelToastVariant.success,
///   title: const Text('Deployment complete'),
///   description: const Text('panelui.dev is live on production.'),
///   action: PanelToastAction(onPressed: openSite, child: const Text('View')),
/// );
/// ```
///
/// Toasts are drawn in an entry of the root [Overlay], the one the app's
/// navigator creates, so nothing has to be added to the app: any context
/// under a `MaterialApp` (or another app with a navigator) can raise one, and
/// they stay above routes pushed later, dialogs and sheets included. They
/// keep clear of the safe area and of the keyboard, which PanelUI's would
/// sit under.
///
/// Toasts at the same [position] stack into a deck, the newest in front and
/// up to two more peeking out behind it, a step smaller each. Hovering the
/// deck with a mouse, or moving focus into it, spreads it into a list and
/// pauses every toast's timer until the pointer leaves, as on PanelUI's web.
/// A toast is swiped away toward its own edge; dragged the other way it
/// resists, staying within a few points of its place, and returns. It
/// arrives on a heavy spring from 100pt off and leaves the way it came,
/// fading; under reduced motion it only fades.
///
/// It closes itself after [duration] (four seconds by default), or stays
/// until it is closed when [duration] is [Duration.zero]. The timers pause
/// while the app is in the background. [title] and [description] are
/// usually [Text]s; [variant] picks the status colour and icon, which [icon]
/// replaces and [showIcon] removes. [action] is usually a
/// [PanelToastAction], which closes the toast when pressed. The close button
/// is shown when [closable] is true, and by default only when there is no
/// [action]. [builder] draws the whole toast instead, usually as a
/// [PanelToast], while the deck still manages it.
PanelToastHandle showPanelToast(
  BuildContext context, {
  Widget? title,
  Widget? description,
  PanelToastVariant variant = PanelToastVariant.neutral,
  PanelToastPosition position = PanelToastPosition.bottom,
  Widget? icon,
  bool showIcon = true,
  Widget? action,
  bool? closable,
  Duration duration = const Duration(seconds: 4),
  PanelToastBuilder? builder,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final wrap = panelCaptureThemes(context, overlay.context);
  return _ToastHost.of(overlay)._show(
    position: position,
    duration: duration,
    builder: (context, toast) => wrap(
      builder != null
          ? builder(context, toast)
          : PanelToast(
              variant: variant,
              title: title,
              description: description,
              icon: icon,
              showIcon: showIcon,
              action: action,
              onClose: (closable ?? action == null) ? toast.hide : null,
            ),
    ),
  );
}

/// Closes every toast raised in the overlay that [context] shows toasts in.
void hideAllPanelToasts(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _ToastHost._hosts[overlay]?._hideAll();
}

/// One toast raised with [showPanelToast].
class PanelToastHandle {
  PanelToastHandle._({
    required _ToastHost host,
    required this.position,
    required Duration duration,
    required PanelToastBuilder builder,
  }) : _host = host,
       _duration = duration,
       _remaining = duration,
       _builder = builder;

  final _ToastHost _host;
  final Duration _duration;
  final PanelToastBuilder _builder;
  final Completer<void> _closed = Completer<void>();

  /// What is left of the countdown, and the timer running it down.
  Duration _remaining;
  Timer? _timer;
  Stopwatch? _running;

  /// Where the toast is shown.
  final PanelToastPosition position;

  /// Whether the toast is still up.
  bool get isShowing => !_closed.isCompleted;

  /// Completes when the toast is closed: by its timer, a swipe, its close
  /// button, its action, or [hide].
  Future<void> get closed => _closed.future;

  /// Closes the toast. Does nothing if it has already closed.
  void hide() => _host._hide(this);

  /// The toast whose content [context] is in, or null outside a toast.
  static PanelToastHandle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ToastScope>()?.toast;

  void _startCountdown() {
    if (_duration <= Duration.zero || _timer != null || !isShowing) return;
    _running = Stopwatch()..start();
    _timer = Timer(_remaining, hide);
  }

  void _pauseCountdown() {
    final timer = _timer;
    if (timer == null) return;
    timer.cancel();
    _timer = null;
    _remaining -= _running!.elapsed;
    if (_remaining < Duration.zero) _remaining = Duration.zero;
    _running = null;
  }

  void _finish() {
    _timer?.cancel();
    _timer = null;
    _running = null;
    if (!_closed.isCompleted) _closed.complete();
  }
}

/// A toast's surface: a status icon, a title and a description, and an
/// action or a close button at the end, on the popover fill with a border in
/// the status colour and PanelUI's `shadow-lg`.
///
/// [showPanelToast] builds one from its arguments. Build one yourself for a
/// custom toast, or to show one in place.
///
/// ```dart
/// PanelToast(
///   variant: PanelToastVariant.success,
///   title: const Text('Changes saved'),
///   description: const Text('Your profile is up to date.'),
///   onClose: () {},
/// )
/// ```
///
/// Screen readers announce it politely as it appears, without moving focus:
/// it is the polite live region PanelUI asks for. PanelUI also gives it the
/// alert role, which Flutter does not allow on a live region.
class PanelToast extends StatelessWidget {
  /// Creates a toast surface.
  const PanelToast({
    super.key,
    this.variant = PanelToastVariant.neutral,
    this.title,
    this.description,
    this.icon,
    this.showIcon = true,
    this.action,
    this.onClose,
    this.closeLabel = 'Dismiss notification',
  });

  /// The status, which picks the border, the title colour and the icon.
  final PanelToastVariant variant;

  /// The title line, usually a [Text]: small, medium weight, in the status
  /// colour.
  final Widget? title;

  /// A line under the title, usually a [Text]: small and muted.
  final Widget? description;

  /// Replaces the status icon.
  final Widget? icon;

  /// Whether to show the status icon.
  final bool showIcon;

  /// A control at the end, usually a [PanelToastAction].
  final Widget? action;

  /// Called by the close button. Null leaves the button out.
  final VoidCallback? onClose;

  /// The close button's accessible name.
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    // The border at 32% of the status colour, and the icon and the title in
    // its foreground; the neutral toast keeps the popover's own colours.
    final (border, tone, titleColor, glyph) = switch (variant) {
      PanelToastVariant.neutral => (
        c.border,
        c.mutedForeground,
        c.popoverForeground,
        PanelIcons.info,
      ),
      PanelToastVariant.info => (
        c.info.withValues(alpha: 0.32),
        c.infoForeground,
        c.infoForeground,
        PanelIcons.info,
      ),
      PanelToastVariant.success => (
        c.success.withValues(alpha: 0.32),
        c.successForeground,
        c.successForeground,
        PanelIcons.checkCircle,
      ),
      PanelToastVariant.warning => (
        c.warning.withValues(alpha: 0.32),
        c.warningForeground,
        c.warningForeground,
        PanelIcons.alertTriangle,
      ),
      PanelToastVariant.destructive => (
        c.destructive.withValues(alpha: 0.32),
        c.destructiveForeground,
        c.destructiveForeground,
        PanelIcons.alertTriangle,
      ),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        // `rounded-2xl border px-4 py-3.5 shadow-lg`.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: PanelBoxDecoration(
          color: c.popover,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(theme.radii.xxl),
          boxShadow: theme.shadows.lg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            if (showIcon)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: IconTheme(
                  data: IconThemeData(color: tone, size: 18),
                  child: icon ?? PanelIcon(glyph),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  if (title != null)
                    DefaultTextStyle(
                      style: theme.typography.style(
                        PanelTextSize.sm,
                        weight: FontWeight.w500,
                        color: titleColor,
                      ),
                      child: title!,
                    ),
                  if (description != null)
                    DefaultTextStyle(
                      style: theme.typography.style(
                        PanelTextSize.sm,
                        color: c.mutedForeground,
                      ),
                      child: description!,
                    ),
                ],
              ),
            ),
            ?action,
            if (onClose != null)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: _ToastCloseButton(
                  label: closeLabel,
                  onPressed: onClose!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The action at a toast's end: a small secondary button that closes its
/// toast once [onPressed] has run.
class PanelToastAction extends StatelessWidget {
  /// Creates a toast action.
  const PanelToastAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = PanelButtonVariant.secondary,
    this.size = PanelButtonSize.sm,
  });

  /// Called when the action is pressed, before the toast closes. Null
  /// disables it.
  final VoidCallback? onPressed;

  /// The label, usually a [Text].
  final Widget child;

  /// The button's look. Secondary reads on the popover surface.
  final PanelButtonVariant variant;

  /// The button's size.
  final PanelButtonSize size;

  @override
  Widget build(BuildContext context) {
    final toast = PanelToastHandle.maybeOf(context);
    final pressed = onPressed;
    return PanelButton(
      variant: variant,
      size: size,
      onPressed: pressed == null
          ? null
          : () {
              pressed();
              toast?.hide();
            },
      child: child,
    );
  }
}

/// The close button at a toast's end: a 14pt cross in the muted foreground,
/// in a ghost icon button made 24pt round (`h-6 w-6 rounded-full`) whose
/// target reaches 2pt further, as an icon button's does in PanelUI. Like a
/// button it shrinks a little while pressed.
///
/// Hover and focus follow PanelUI's web toast: hovered, the circle takes the
/// `accent` fill and the cross the foreground, at once; focused, it takes a
/// 2pt ring.
class _ToastCloseButton extends StatelessWidget {
  const _ToastCloseButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = PanelTheme.of(context).colors;
    return PanelPressable(
      onPressed: onPressed,
      hitSlop: const EdgeInsets.all(2),
      semanticLabel: label,
      focusRingRadius: BorderRadius.circular(12),
      // The web close button's `ring-2 ring-ring`.
      focusRingStyle: PanelFocusRingStyle.tight,
      builder: (context, state) => Container(
        width: 24,
        height: 24,
        // Centred, so the glyph keeps its own size inside the circle.
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: state.hovered ? c.accent : null,
          shape: BoxShape.circle,
        ),
        child: PanelIcon(
          PanelIcons.x,
          size: 14,
          color: state.hovered ? c.foreground : c.mutedForeground,
        ),
      ),
    );
  }
}

class _ToastScope extends InheritedWidget {
  const _ToastScope({required this.toast, required super.child});

  final PanelToastHandle toast;

  @override
  bool updateShouldNotify(_ToastScope oldWidget) => toast != oldWidget.toast;
}

/// The toast queue of one overlay, and the overlay entry that draws it.
///
/// The entry is inserted with the first toast and removed once the last one
/// has finished leaving, so an app without toasts carries nothing.
class _ToastHost extends ChangeNotifier {
  _ToastHost(this.overlay);

  static final Expando<_ToastHost> _hosts = Expando<_ToastHost>('PanelToast');

  static _ToastHost of(OverlayState overlay) =>
      _hosts[overlay] ??= _ToastHost(overlay);

  final OverlayState overlay;

  /// The toasts that are up, oldest first.
  final List<PanelToastHandle> items = [];

  OverlayEntry? _entry;
  AppLifecycleListener? _lifecycle;

  /// Why the countdowns are paused: the app is out of sight, or a deck is
  /// spread open.
  final Set<Object> _pauses = {};

  static const Object _background = Object();

  PanelToastHandle _show({
    required PanelToastPosition position,
    required Duration duration,
    required PanelToastBuilder builder,
  }) {
    _attach();
    final toast = PanelToastHandle._(
      host: this,
      position: position,
      duration: duration,
      builder: builder,
    );
    items.add(toast);
    if (_pauses.isEmpty) toast._startCountdown();
    notifyListeners();
    return toast;
  }

  void _hide(PanelToastHandle toast) {
    if (!items.remove(toast)) return;
    toast._finish();
    notifyListeners();
  }

  void _hideAll() {
    if (items.isEmpty) return;
    for (final toast in items) {
      toast._finish();
    }
    items.clear();
    notifyListeners();
  }

  void _setPaused(Object reason, bool paused) {
    final was = _pauses.isNotEmpty;
    if (paused) {
      _pauses.add(reason);
    } else {
      _pauses.remove(reason);
    }
    final now = _pauses.isNotEmpty;
    if (was == now) return;
    for (final toast in items) {
      if (now) {
        toast._pauseCountdown();
      } else {
        toast._startCountdown();
      }
    }
  }

  /// Pauses on the states that mean nobody can see the toast. An unknown
  /// state counts as visible, so a toast raised before the platform has said
  /// is not parked with nothing coming to restart it.
  void _syncLifecycle(AppLifecycleState? state) => _setPaused(
    _background,
    state != null && state != AppLifecycleState.resumed,
  );

  void _attach() {
    _lifecycle ??= AppLifecycleListener(onStateChange: _syncLifecycle);
    _syncLifecycle(SchedulerBinding.instance.lifecycleState);
    if (_entry != null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastLayer(host: this, entry: entry),
    );
    _entry = entry;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // Raised mid-build: the overlay cannot take an entry until it is done.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_entry != entry) return;
        if (overlay.mounted) {
          overlay.insert(entry);
        } else {
          _teardown();
        }
      });
    } else {
      overlay.insert(entry);
    }
  }

  /// The layer has nothing left on screen. Removes the entry if nothing new
  /// has arrived meanwhile.
  void _layerIdle() {
    if (items.isNotEmpty) return;
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    _pauses.clear();
    void remove() {
      if (entry.mounted) entry.remove();
      entry.dispose();
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => remove());
    } else {
      remove();
    }
  }

  /// The overlay has gone: stop every countdown and forget the entry.
  void _teardown() {
    for (final toast in items) {
      toast._finish();
    }
    items.clear();
    _lifecycle?.dispose();
    _lifecycle = null;
    _pauses.clear();
    _entry = null;
  }
}

/// A toast on screen: live, or leaving.
class _Slot {
  _Slot(this.toast);

  final PanelToastHandle toast;
  bool leaving = false;
}

/// The overlay entry's content: one deck per position in use.
class _ToastLayer extends StatefulWidget {
  const _ToastLayer({required this.host, required this.entry});

  final _ToastHost host;

  /// The entry this layer is drawn in.
  final OverlayEntry entry;

  @override
  State<_ToastLayer> createState() => _ToastLayerState();
}

class _ToastLayerState extends State<_ToastLayer> {
  final List<_Slot> _slots = [];

  _ToastHost get _host => widget.host;

  @override
  void initState() {
    super.initState();
    _host.addListener(_handleChange);
    _reconcile();
  }

  @override
  void dispose() {
    _host.removeListener(_handleChange);
    // Still the host's entry, so the host did not take it away: the overlay
    // itself is going.
    if (identical(_host._entry, widget.entry)) _host._teardown();
    super.dispose();
  }

  void _handleChange() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _handleChange());
      return;
    }
    setState(_reconcile);
  }

  /// The newest few live toasts at each position, the ones drawn.
  Set<_Slot> _onScreen() {
    final shown = <_Slot>{};
    for (final position in PanelToastPosition.values) {
      final live = [
        for (final slot in _slots)
          if (!slot.leaving && slot.toast.position == position) slot,
      ];
      shown.addAll(live.skip(math.max(0, live.length - (_maxVisible + 1))));
    }
    return shown;
  }

  void _reconcile() {
    final live = _host.items.toSet();
    final shown = _onScreen();
    final dropped = <_Slot>{};
    for (final slot in _slots) {
      if (slot.leaving || live.contains(slot.toast)) continue;
      // One that was off the deck has nothing to animate out.
      if (shown.contains(slot)) {
        slot.leaving = true;
      } else {
        dropped.add(slot);
      }
    }
    _slots.removeWhere(dropped.contains);
    final present = {for (final slot in _slots) slot.toast};
    for (final toast in _host.items) {
      if (!present.contains(toast)) _slots.add(_Slot(toast));
    }
    if (_slots.isEmpty) _host._layerIdle();
  }

  void _handleLeft(_Slot slot) {
    if (!mounted) return;
    setState(() => _slots.remove(slot));
    if (_slots.isEmpty) _host._layerIdle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final decks = <Widget>[
      for (final position in PanelToastPosition.values)
        if (_slots.any((slot) => slot.toast.position == position))
          _ToastDeck(
            key: ValueKey<PanelToastPosition>(position),
            position: position,
            host: _host,
            slots: [
              for (final slot in _slots)
                if (slot.toast.position == position) slot,
            ],
            onLeft: _handleLeft,
          ),
    ];
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: theme.typography.style(
          PanelTextSize.base,
          color: theme.colors.foreground,
        ),
        child: Stack(fit: StackFit.expand, children: decks),
      ),
    );
  }
}

/// The toasts at one position: pinned to the same edge, overlapping like a
/// deck of cards, or spread into a list while hovered or focused.
class _ToastDeck extends StatefulWidget {
  const _ToastDeck({
    super.key,
    required this.position,
    required this.host,
    required this.slots,
    required this.onLeft,
  });

  final PanelToastPosition position;
  final _ToastHost host;

  /// Oldest first, leaving ones included.
  final List<_Slot> slots;
  final ValueChanged<_Slot> onLeft;

  @override
  State<_ToastDeck> createState() => _ToastDeckState();
}

class _ToastDeckState extends State<_ToastDeck>
    with SingleTickerProviderStateMixin {
  /// How far the deck is spread, run the way the web package's CSS
  /// transition runs it: each change sets off afresh from wherever the deck
  /// is, over 450ms on the same ease-out, whether it is opening or gathering.
  late final AnimationController _spreadClock = AnimationController(
    vsync: this,
    duration: _spreadDuration,
  );
  late final CurvedAnimation _spreadEased = CurvedAnimation(
    parent: _spreadClock,
    curve: _spreadCurve,
  );
  final Tween<double> _spreadRange = Tween<double>(begin: 0, end: 0);
  late final Animation<double> _spread = _spreadRange.animate(_spreadEased);

  /// Natural heights, by toast.
  final Map<PanelToastHandle, double> _heights = {};
  double? _lastFrontHeight;

  final Set<PanelToastHandle> _hovered = {};
  bool _focused = false;

  bool get _expanded => _hovered.isNotEmpty || _focused;

  @override
  void didUpdateWidget(_ToastDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    final present = {for (final slot in widget.slots) slot.toast};
    _heights.removeWhere((toast, _) => !present.contains(toast));
    final hovered = _hovered.length;
    _hovered.removeWhere((toast) => !present.contains(toast));
    if (_hovered.length != hovered) _syncExpansion();
  }

  @override
  void dispose() {
    widget.host._setPaused(this, false);
    _spreadEased.dispose();
    _spreadClock.dispose();
    super.dispose();
  }

  void _syncExpansion() {
    final expanded = _expanded;
    widget.host._setPaused(this, expanded);
    final target = expanded ? 1.0 : 0.0;
    if (_spreadRange.end == target) return;
    _spreadRange
      ..begin = _spread.value
      ..end = target;
    if (panelReduceMotion(context)) {
      _spreadClock.value = 1;
    } else {
      _spreadClock.forward(from: 0);
    }
  }

  void _handleHover(PanelToastHandle toast, bool hovered) {
    if (!mounted) return;
    final changed = hovered ? _hovered.add(toast) : _hovered.remove(toast);
    if (changed) _syncExpansion();
  }

  void _handleFocus(bool focused) {
    if (!mounted || _focused == focused) return;
    _focused = focused;
    _syncExpansion();
  }

  void _handleHeight(PanelToastHandle toast, double height) {
    if (!mounted || _heights[toast] == height) return;
    setState(() => _heights[toast] = height);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final position = widget.position;
    final top = position._top;

    final wide = size.width >= _wideScreen;
    final margin = wide ? _wideMargin : _margin;
    final room = math.max(0.0, size.width - 2 * margin);
    final width = wide ? math.min(room, _wideMaxWidth) : room;
    final x =
        margin + (room - width) * ((rtl ? -position._x : position._x) + 1) / 2;
    // The edge the deck hangs from, clear of the safe area and the keyboard.
    final anchor = top
        ? padding.top + margin
        : padding.bottom + keyboard + margin;

    final live = [
      for (final slot in widget.slots)
        if (!slot.leaving) slot,
    ];
    final shown = live.sublist(math.max(0, live.length - (_maxVisible + 1)));
    final total = shown.length;
    final frontHeight = shown.isEmpty
        ? _lastFrontHeight
        : _heights[shown.last.toast] ?? _lastFrontHeight;
    _lastFrontHeight = frontHeight;

    final children = <Widget>[];
    for (final slot in widget.slots) {
      final index = shown.indexOf(slot);
      if (!slot.leaving && index < 0) continue;
      // Spread, a card sits past every card in front of it.
      var spreadOffset = 0.0;
      for (var j = index + 1; index >= 0 && j < total; j++) {
        spreadOffset += (_heights[shown[j].toast] ?? 0) + _spreadGap;
      }
      children.add(
        Positioned(
          key: ObjectKey(slot.toast),
          left: x,
          width: width,
          top: top ? anchor : null,
          bottom: top ? null : anchor,
          child: _ToastSlot(
            toast: slot.toast,
            top: top,
            depth: index < 0 ? 0 : total - 1 - index,
            frontHeight: frontHeight,
            spreadOffset: spreadOffset,
            expansion: _spread,
            leaving: slot.leaving,
            onHeight: (height) => _handleHeight(slot.toast, height),
            onHover: (hovered) => _handleHover(slot.toast, hovered),
            onLeft: () => widget.onLeft(slot),
          ),
        ),
      );
    }

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _handleFocus,
      child: Stack(fit: StackFit.expand, children: children),
    );
  }
}

/// Where a toast is drawn on one frame: its vertical offset from its place
/// in the deck, its scale about the height `pivot`, its opacity, and how much
/// of it shows from the side away from its edge (null when all of it does).
typedef _Pose = ({
  double dy,
  double scale,
  double pivot,
  double opacity,
  double? visible,
});

/// One toast in a deck, and everything that moves it.
class _ToastSlot extends StatefulWidget {
  const _ToastSlot({
    required this.toast,
    required this.top,
    required this.depth,
    required this.frontHeight,
    required this.spreadOffset,
    required this.expansion,
    required this.leaving,
    required this.onHeight,
    required this.onHover,
    required this.onLeft,
  });

  final PanelToastHandle toast;

  /// Pinned to the top edge rather than the bottom.
  final bool top;

  /// How far back in the deck: 0 is the front.
  final int depth;

  /// The front toast's height, which every card in the deck takes so the
  /// ones behind read as a uniform stack rather than a ragged pile.
  final double? frontHeight;

  /// How far from the edge it sits when the deck is spread.
  final double spreadOffset;

  /// How far the deck is spread, from 0 to 1.
  final Animation<double> expansion;

  /// Whether it is on its way out.
  final bool leaving;

  final ValueChanged<double> onHeight;
  final ValueChanged<bool> onHover;
  final VoidCallback onLeft;

  @override
  State<_ToastSlot> createState() => _ToastSlotState();
}

class _ToastSlotState extends State<_ToastSlot> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _exit = AnimationController(vsync: this);
  late final AnimationController _drag = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: _pressDuration,
  );
  late final AnimationController _depth = AnimationController.unbounded(
    vsync: this,
    value: widget.depth.toDouble(),
  );
  late final AnimationController _spreadOffset = AnimationController.unbounded(
    vsync: this,
    value: widget.spreadOffset,
  );
  late Listenable _ticks = _merged();

  /// The toast's own content, built once: the deck rebuilds its slots as
  /// heights arrive and toasts come and go, and none of that changes it.
  late final Widget _card = _buildCard();

  double? _height;
  double? _frozenFrontHeight;
  bool _reduceMotion = false;
  bool _started = false;

  /// +1 when the toast's edge is below it, -1 when above.
  double get _edge => widget.top ? -1 : 1;

  Listenable _merged() => Listenable.merge([
    _enter,
    _exit,
    _drag,
    _press,
    _depth,
    _spreadOffset,
    widget.expansion,
  ]);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = panelReduceMotion(context);
    if (_started) return;
    _started = true;
    if (_reduceMotion) {
      // The fade stays: a toast with no transition at all is a jump-cut, and
      // its arrival still has to be noticed.
      _enter.animateTo(1, duration: PanelDurations.fadeIn, curve: panelEase);
    } else {
      _enter.springTo(1, PanelSprings.toastEnter);
    }
  }

  @override
  void didUpdateWidget(_ToastSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expansion != oldWidget.expansion) _ticks = _merged();
    if (widget.leaving && !oldWidget.leaving) {
      _frozenFrontHeight = oldWidget.frontHeight;
      _leave();
    }
    if (widget.leaving) return;
    if (widget.depth != oldWidget.depth) _settleDepth(widget.depth);
    if (widget.spreadOffset != oldWidget.spreadOffset) {
      // It only shows while the deck is spread, which is the web package's
      // behaviour, so it moves on the web's transition rather than a spring.
      if (_reduceMotion) {
        _spreadOffset.value = widget.spreadOffset;
      } else {
        _spreadOffset.animateTo(
          widget.spreadOffset,
          duration: _spreadDuration,
          curve: _spreadCurve,
        );
      }
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    _drag.dispose();
    _press.dispose();
    _depth.dispose();
    _spreadOffset.dispose();
    super.dispose();
  }

  /// Moves the toast to [depth] in the deck on PanelUI's stack spring, or
  /// straight there under reduced motion.
  void _settleDepth(int depth) {
    if (_reduceMotion) {
      _depth.value = depth.toDouble();
    } else {
      _depth.springTo(depth.toDouble(), PanelSprings.stack);
    }
  }

  void _leave() {
    _press.value = 0;
    _exit.duration = _reduceMotion ? PanelDurations.fadeOut : _exitDuration;
    _exit.forward().whenComplete(() {
      if (mounted) widget.onLeft();
    });
  }

  void _handleHeight(double height) {
    if (!mounted) return;
    if (_height != height) setState(() => _height = height);
    widget.onHeight(height);
  }

  void _pressTo(double target) {
    if (_reduceMotion || widget.leaving) return;
    _press.animateTo(target, curve: panelEase);
  }

  /// Takes hold of the toast where it is, catching it if it is springing
  /// back.
  void _handleDragStart(DragStartDetails details) => _drag.stop();

  void _handleDragUpdate(DragUpdateDetails details) {
    final next = _drag.value + (details.primaryDelta ?? 0);
    // Toward the edge it follows the finger. Away from it, it rubber-bands
    // so it never detaches from where it belongs: PanelUI cuts each new
    // position to a tenth (40pt at most), which compounds over the moves and
    // holds the toast within a few points of its place.
    _drag.value = next * _edge > 0
        ? next
        : -_edge *
              math.min(next.abs(), _rubberBandTravel) /
              _rubberBandTravel *
              _rubberBandLimit;
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    _pressTo(0);
    final towardEdge = _drag.value * _edge > 0;
    final dismiss =
        towardEdge &&
        (_drag.value.abs() > _dismissDistance ||
            velocity.abs() > _dismissVelocity);
    if (dismiss) {
      if (!_reduceMotion) {
        // Carry the flick's momentum instead of stopping dead, clamped so it
        // can only continue toward the edge.
        _drag.animateWith(
          ClampedSimulation(
            FrictionSimulation(_decayDrag, _drag.value, velocity * 1.5),
            xMin: _edge > 0 ? 0 : double.negativeInfinity,
            xMax: _edge > 0 ? double.infinity : 0,
          ),
        );
      }
      widget.toast.hide();
    } else if (_reduceMotion) {
      _drag.value = 0;
    } else {
      _drag.springTo(0, PanelSprings.toast);
    }
  }

  Widget _buildCard() {
    final toast = widget.toast;
    Widget card = _ToastScope(
      toast: toast,
      child: Builder(builder: (context) => toast._builder(context, toast)),
    );
    card = _MeasureHeight(onHeight: _handleHeight, child: card);
    // How Flutter offers a swipe to a screen reader, which cannot make one.
    card = Semantics(container: true, onDismiss: toast.hide, child: card);
    card = RawGestureDetector(
      excludeFromSemantics: true,
      gestures: {
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(debugOwner: this),
              (recognizer) => recognizer
                ..gestureSettings = const DeviceGestureSettings(
                  touchSlop: _swipeSlop,
                )
                // The whole of the finger's travel, slop included, as with
                // PanelUI's pan.
                ..dragStartBehavior = DragStartBehavior.down
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd,
            ),
      },
      child: card,
    );
    card = Listener(
      onPointerDown: (_) => _pressTo(1),
      onPointerUp: (_) => _pressTo(0),
      onPointerCancel: (_) => _pressTo(0),
      child: card,
    );
    // Its own layer, so the deck moves a finished picture of the card.
    return RepaintBoundary(child: card);
  }

  /// Where the card is drawn on this frame.
  _Pose _pose() {
    final edge = _edge;
    final spread = widget.expansion.value;
    final depth = _depth.value;
    final height = _height;
    final front =
        (widget.leaving ? _frozenFrontHeight : widget.frontHeight) ?? height;
    final known = height != null && front != null;

    // Collapsed, a card shows the front card's height of itself, the far
    // side of that box stepped back from the edge by its depth. Spread, it
    // shows all of itself at its place in the list.
    final collapsedShift =
        (known ? edge * (height - front) : 0) -
        edge * _stackOffset * math.max(depth, 0);
    var dy = lerpDouble(collapsedShift, -edge * _spreadOffset.value, spread)!;
    final collapsedScale = 1 - (1 - _stackScaleStep) * math.max(depth, 0);
    var scale = lerpDouble(collapsedScale, 1, spread)!;
    // Anything past the newest three fades out rather than piling up.
    var opacity = (_maxVisible - depth).clamp(0.0, 1.0);

    if (_reduceMotion) {
      opacity *= _enter.value.clamp(0.0, 1.0);
    } else {
      dy += (1 - _enter.value) * _enterOffset * edge;
    }
    final exit = _exit.value;
    if (exit > 0) {
      if (_reduceMotion) {
        opacity *= 1 - panelEase.transform(exit);
      } else {
        final t = _exitCurve.transform(exit);
        opacity *= 1 - t;
        dy += t * _enterOffset * edge;
        scale *= 1 - (1 - _stackScaleStep) * t;
      }
    }
    dy += _drag.value;
    scale *= 1 - (1 - _pressScale) * _press.value;

    final visible = known ? lerpDouble(front, height, spread)! : null;
    // The centre of the part that shows, which is what the deck scales. A
    // bottom deck's card sits under the bridge above it.
    final centre = known
        ? (widget.top
              ? lerpDouble(height - front / 2, height / 2, spread)!
              : lerpDouble(front / 2, height / 2, spread)!)
        : (height ?? 0) / 2;
    return (
      dy: dy,
      scale: scale,
      pivot: centre + (widget.top ? 0 : _spreadGap),
      opacity: opacity.clamp(0.0, 1.0),
      visible: visible != null && visible < height! - 0.5 ? visible : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = widget.top;
    return AnimatedBuilder(
      animation: _ticks,
      child: _card,
      builder: (context, child) {
        final pose = _pose();
        // Always in the tree, so the card under it is never remounted (and a
        // drag on it never dropped) as it starts or stops being clipped.
        Widget result = ClipRect(
          clipper: _VisibleBox(
            extent: pose.visible ?? double.infinity,
            fromTop: !top,
          ),
          clipBehavior: pose.visible == null ? Clip.none : Clip.hardEdge,
          child: child,
        );
        // A bridge over the gap to the next card, so moving the pointer
        // across a spread deck does not gather it. It lets taps through.
        result = MouseRegion(
          hitTestBehavior: HitTestBehavior.translucent,
          onEnter: (_) => widget.onHover(true),
          onExit: (_) => widget.onHover(false),
          child: Padding(
            padding: top
                ? const EdgeInsets.only(bottom: _spreadGap)
                : const EdgeInsets.only(top: _spreadGap),
            child: result,
          ),
        );
        return IgnorePointer(
          ignoring: widget.leaving || pose.opacity < 0.01,
          child: Opacity(
            opacity: pose.opacity,
            child: Transform.translate(
              offset: Offset(0, pose.dy),
              child: Transform(
                alignment: Alignment.topCenter,
                origin: Offset(0, pose.pivot),
                transform: Matrix4.diagonal3Values(pose.scale, pose.scale, 1),
                child: result,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Clips a card behind the front one to the part of it that shows, leaving
/// room around the other three sides for its shadow.
class _VisibleBox extends CustomClipper<Rect> {
  const _VisibleBox({required this.extent, required this.fromTop});

  /// How much of the card shows.
  final double extent;

  /// Measured from the card's top (a bottom deck, where the top peeks out)
  /// rather than from its bottom.
  final bool fromTop;

  static const double _shadowRoom = 48;

  @override
  Rect getClip(Size size) => fromTop
      ? Rect.fromLTRB(
          -_shadowRoom,
          -_shadowRoom,
          size.width + _shadowRoom,
          extent,
        )
      : Rect.fromLTRB(
          -_shadowRoom,
          size.height - extent,
          size.width + _shadowRoom,
          size.height + _shadowRoom,
        );

  @override
  bool shouldReclip(_VisibleBox oldClipper) =>
      extent != oldClipper.extent || fromTop != oldClipper.fromTop;
}

/// Reports its child's height after layout, which the deck needs to stack
/// the cards behind the front one.
class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({required this.onHeight, super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureHeight(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasureHeight renderObject,
  ) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderMeasureHeight extends RenderProxyBox {
  _RenderMeasureHeight(this.onHeight);

  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _reported) return;
    _reported = height;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeight(height);
    });
  }
}
