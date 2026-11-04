import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/anchored_overlay.dart';
import '../foundation/panel_decoration.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// Which side of its trigger a [PanelTooltip] prefers. It flips to the
/// opposite side when the preferred one has less room.
///
/// The sides beside the trigger are named by reading order rather than
/// PanelUI's `left` and `right`, so a right-to-left layout mirrors them.
enum PanelTooltipPlacement {
  /// Above the trigger. The default.
  top,

  /// Below the trigger.
  bottom,

  /// Before the trigger in reading order: the left in a left-to-right layout.
  start,

  /// After the trigger in reading order.
  end,
}

/// Where a [PanelTooltip] lines up along its trigger's other axis.
enum PanelTooltipAlign {
  /// Leading edges line up (top edges beside the trigger).
  start,

  /// Centred on the trigger. The default.
  center,

  /// Trailing edges line up (bottom edges beside the trigger).
  end,
}

/// Which colours a [PanelTooltip] draws from.
enum PanelTooltipVariant {
  /// The default: the `foreground` token as a fill with `background` text, so
  /// a label over the page reads as a different layer rather than as another
  /// panel of it.
  inverted,

  /// The popover's surface, border and text, for a tooltip carrying a heading
  /// and a sentence, where the inversion stops reading as a whisper and starts
  /// reading as a panel with the wrong colours.
  surface,
}

/// The gesture that opens a [PanelTooltip] by hand. A mouse also opens it by
/// hovering, and the keyboard by focusing the trigger, either way.
enum PanelTooltipOpenOn {
  /// A long press, the platform's own "tell me more" gesture. The default,
  /// because it does not steal a tappable control's own press.
  longPress,

  /// A tap or a click, which toggles the label as well as pressing the
  /// trigger.
  press,
}

/// PanelUI's tooltip settle: `withSpring(1, { damping: 20, stiffness: 300,
/// mass: 0.5 })` beside a 100ms fade, from 90% scale and 6pt towards the
/// trigger. The exit is a 100ms fade.
const AnchoredMotion _tooltipMotion = AnchoredMotion(
  enter: Duration(milliseconds: 100),
  exit: Duration(milliseconds: 100),
  spring: PanelSprings.tooltip,
  shift: 6,
  scaleFrom: 0.9,
);

/// The side of the arrow's square before it is turned 45°.
const double _arrowSize = 10;

/// How long a hovered label waits after the mouse leaves, so it survives the
/// pointer crossing the gap onto the label itself.
const Duration _hoverExitDelay = Duration(milliseconds: 100);

/// A small label that names the thing under the pointer or the finger.
///
/// A popover is a panel you open and deal with; a tooltip is a whisper. It
/// carries a word or two about what a control does, appears without taking the
/// screen, and goes away on its own after [duration].
///
/// ```dart
/// PanelTooltip(
///   message: 'Copy link',
///   child: PanelButton(
///     size: PanelButtonSize.icon,
///     variant: PanelButtonVariant.ghost,
///     onPressed: copy,
///     child: const PanelIcon(PanelIcons.link),
///   ),
/// )
/// ```
///
/// On touch there is no hover, so the gesture is a long press by default,
/// with [PanelTooltipOpenOn.press] for a tap instead, as in PanelUI. A mouse
/// also opens it by hovering the trigger for [hoverDelay], and keyboard focus
/// opens it at once; those two keep it up for as long as the pointer or the
/// focus stays.
///
/// A tap anywhere else, or Escape, closes it. Unlike PanelUI's full-screen
/// catcher, that tap still reaches whatever it landed on: a label shown
/// because a pointer passed over a control must not cost the next click.
///
/// Placement is a preference: `top` means above if above fits. The label is
/// flipped to the other side when it has less room there, and slid along the
/// trigger to stay 12pt inside the safe area.
///
/// [message] is also given to screen readers as the trigger's tooltip, so an
/// icon-only control is announced with it without the label being opened. To
/// carry it, the trigger's semantics are merged into one node, so the trigger
/// should be a single control.
class PanelTooltip extends StatefulWidget {
  /// Creates a tooltip for [child].
  const PanelTooltip({
    super.key,
    required this.child,
    this.message,
    this.content,
    this.placement = PanelTooltipPlacement.top,
    this.align = PanelTooltipAlign.center,
    this.offset = 6,
    this.alignOffset = 0,
    this.variant = PanelTooltipVariant.inverted,
    this.showArrow = false,
    this.openOn = PanelTooltipOpenOn.longPress,
    this.duration = const Duration(milliseconds: 1500),
    this.hoverDelay = const Duration(milliseconds: 500),
    this.width,
    this.matchTriggerWidth = false,
    this.minWidth,
    this.maxHeight,
    this.scrollable = false,
    this.padding,
    this.isOpen,
    this.onOpenChange,
  }) : assert(
         message != null || content != null,
         'Give the tooltip a message or content.',
       );

  /// The trigger.
  final Widget child;

  /// The label's text. Also the trigger's semantic tooltip.
  final String? message;

  /// Rich content in place of [message], such as a [PanelTooltipTitle] over a
  /// [PanelTooltipDescription]. Text inside it takes the label's style.
  final Widget? content;

  /// The preferred side.
  final PanelTooltipPlacement placement;

  /// Where the label lines up along the trigger's other axis.
  final PanelTooltipAlign align;

  /// The gap between the trigger and the label.
  final double offset;

  /// A nudge along the alignment axis.
  final double alignOffset;

  /// Inverted (the default) or surface colours.
  final PanelTooltipVariant variant;

  /// Draws a small arrow pointing at the trigger's centre (PanelUI's
  /// `Tooltip.Arrow`). It stays on the trigger after a flip or a clamp.
  final bool showArrow;

  /// How touch opens the label.
  final PanelTooltipOpenOn openOn;

  /// How long a label opened by touch, or by [isOpen], stays up before it
  /// hides itself. [Duration.zero] keeps it until a tap outside, the trigger
  /// again or Escape. A label opened by hover or focus stays while the
  /// pointer or focus does.
  final Duration duration;

  /// How long a mouse rests on the trigger before the label shows. Moving
  /// from one tooltip's trigger to another's shows the next at once.
  final Duration hoverDelay;

  /// A fixed width. Null sizes the label to its content; [double.infinity]
  /// spans the safe area. Worth setting for anything longer than a label.
  final double? width;

  /// Make the label exactly as wide as the trigger.
  final bool matchTriggerWidth;

  /// A floor for the label's width.
  final double? minWidth;

  /// A ceiling for the label's height, always clamped to the room inside the
  /// safe area.
  final double? maxHeight;

  /// Scroll the content when it is taller than [maxHeight].
  final bool scrollable;

  /// The space inside the label. Defaults to 10 by 6.
  final EdgeInsetsGeometry? padding;

  /// Whether the label is showing, for a controlled tooltip. Null lets the
  /// tooltip manage it.
  final bool? isOpen;

  /// Called when the tooltip opens or closes itself.
  final ValueChanged<bool>? onOpenChange;

  @override
  State<PanelTooltip> createState() => _PanelTooltipState();
}

/// Why a tooltip is showing, which decides what hides it.
enum _OpenReason { hover, focus, touch, programmatic }

class _PanelTooltipState extends State<PanelTooltip> {
  /// Tooltips on screen, so a newly hovered one can take over at once.
  static final Set<_PanelTooltipState> _visible = <_PanelTooltipState>{};

  bool _internalOpen = false;
  bool _wasOpen = false;
  _OpenReason? _reason;
  Timer? _showTimer;
  Timer? _hideTimer;
  Timer? _autoHideTimer;
  LongPressGestureRecognizer? _longPress;
  int? _tapPointer;
  Offset _tapPosition = Offset.zero;
  Duration _tapTime = Duration.zero;
  bool _hoveringTrigger = false;
  bool _hoveringPanel = false;

  bool get _open => widget.isOpen ?? _internalOpen;

  @override
  void initState() {
    super.initState();
    if (widget.isOpen ?? false) _reason = _OpenReason.programmatic;
    _syncOpen();
  }

  @override
  void didUpdateWidget(PanelTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen && (widget.isOpen ?? false)) {
      _reason ??= _OpenReason.programmatic;
    }
    _syncOpen();
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _autoHideTimer?.cancel();
    _longPress?.dispose();
    _visible.remove(this);
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  /// Asks for the label to show or hide, through [PanelTooltip.onOpenChange]
  /// when it is controlled.
  void _setOpen(bool value, [_OpenReason reason = _OpenReason.programmatic]) {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    if (value == _open) return;
    if (value) {
      _reason = reason;
      for (final other in _visible.toList()) {
        if (other != this) other._setOpen(false);
      }
    }
    if (widget.isOpen == null) {
      setState(() => _internalOpen = value);
      _syncOpen();
    }
    widget.onOpenChange?.call(value);
  }

  /// Reacts to the label actually showing or hiding, however that came about.
  void _syncOpen() {
    final open = _open;
    if (open == _wasOpen) return;
    _wasOpen = open;
    _autoHideTimer?.cancel();
    if (open) {
      _visible.add(this);
      HardwareKeyboard.instance.addHandler(_handleKey);
      _armAutoHide();
      final message = widget.message;
      if (message != null) unawaited(SemanticsService.tooltip(message));
    } else {
      _visible.remove(this);
      HardwareKeyboard.instance.removeHandler(_handleKey);
      _reason = null;
    }
  }

  /// A tooltip is not a thing you deal with, so it hides itself after
  /// [PanelTooltip.duration]; one held up by a resting pointer or by focus
  /// waits for those instead.
  void _armAutoHide() {
    _autoHideTimer?.cancel();
    final reason = _reason ?? _OpenReason.programmatic;
    if (widget.duration > Duration.zero &&
        reason != _OpenReason.hover &&
        reason != _OpenReason.focus) {
      _autoHideTimer = Timer(widget.duration, () => _setOpen(false));
    }
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _open) {
      _setOpen(false);
    }
    return false;
  }

  void _handleTriggerEnter(PointerEnterEvent event) {
    _hoveringTrigger = true;
    _hideTimer?.cancel();
    if (_open) return;
    // Moving between neighbouring triggers hands the label over at once.
    final handOver = _visible.any((other) => other != this);
    if (handOver || widget.hoverDelay == Duration.zero) {
      _setOpen(true, _OpenReason.hover);
    } else {
      _showTimer?.cancel();
      _showTimer = Timer(
        widget.hoverDelay,
        () => _setOpen(true, _OpenReason.hover),
      );
    }
  }

  void _handleTriggerExit(PointerExitEvent event) {
    _hoveringTrigger = false;
    _showTimer?.cancel();
    _scheduleHoverHide();
  }

  void _handlePanelHover(bool hovering) {
    _hoveringPanel = hovering;
    if (hovering) {
      _hideTimer?.cancel();
    } else {
      _scheduleHoverHide();
    }
  }

  void _scheduleHoverHide() {
    if (!_open || _reason != _OpenReason.hover) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(_hoverExitDelay, () {
      if (!_hoveringTrigger && !_hoveringPanel) _setOpen(false);
    });
  }

  void _handleFocusChange(bool focused) {
    if (focused) {
      if (FocusManager.instance.highlightMode ==
          FocusHighlightMode.traditional) {
        _setOpen(true, _OpenReason.focus);
      }
    } else if (_reason == _OpenReason.focus) {
      _setOpen(false);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _showTimer?.cancel();
    if (event.kind == PointerDeviceKind.mouse &&
        widget.openOn == PanelTooltipOpenOn.longPress) {
      // A click on a hovered control puts its label away. A tooltip that
      // opens on press toggles on a click instead, below.
      if (_open) _setOpen(false);
      return;
    }
    switch (widget.openOn) {
      case PanelTooltipOpenOn.longPress:
        if (_open) _setOpen(false);
        final recognizer = _longPress ??= LongPressGestureRecognizer(
          debugOwner: this,
        )..onLongPress = _handleLongPress;
        recognizer.addPointer(event);
      case PanelTooltipOpenOn.press:
        _tapPointer = event.pointer;
        _tapPosition = event.position;
        _tapTime = event.timeStamp;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _tapPointer) return;
    _tapPointer = null;
    final moved = (event.position - _tapPosition).distance > kTouchSlop;
    final held = event.timeStamp - _tapTime > kLongPressTimeout;
    if (moved || held) return;
    if (_open && _reason == _OpenReason.hover) {
      // Hovering showed it a moment before the click that asks for it: the
      // click keeps it up, as a press would have opened it, rather than
      // putting away what the reader is reaching for.
      _hideTimer?.cancel();
      _reason = _OpenReason.touch;
      _armAutoHide();
      return;
    }
    _setOpen(!_open, _OpenReason.touch);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _tapPointer) _tapPointer = null;
  }

  void _handleLongPress() => _setOpen(true, _OpenReason.touch);

  void _handleTapOutside() {
    if (_open) _setOpen(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final inverted = widget.variant == PanelTooltipVariant.inverted;

    Widget trigger = widget.child;
    final message = widget.message;
    if (message != null) {
      trigger = MergeSemantics(
        child: Semantics(tooltip: message, child: trigger),
      );
    }
    trigger = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: _handleFocusChange,
      child: MouseRegion(
        onEnter: _handleTriggerEnter,
        onExit: _handleTriggerExit,
        child: Listener(
          onPointerDown: _handlePointerDown,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: trigger,
        ),
      ),
    );

    return AnchoredOverlay(
      open: _open,
      modal: false,
      takesFocus: false,
      tapRegionGroupId: this,
      onTapOutside: _handleTapOutside,
      onPanelHoverChanged: _handlePanelHover,
      motion: _tooltipMotion,
      position: AnchoredPosition(
        placement: switch (widget.placement) {
          PanelTooltipPlacement.top => AnchorPlacement.top,
          PanelTooltipPlacement.bottom => AnchorPlacement.bottom,
          PanelTooltipPlacement.start => AnchorPlacement.start,
          PanelTooltipPlacement.end => AnchorPlacement.end,
        },
        align: switch (widget.align) {
          PanelTooltipAlign.start => AnchorAlign.start,
          PanelTooltipAlign.center => AnchorAlign.center,
          PanelTooltipAlign.end => AnchorAlign.end,
        },
        offset: widget.offset,
        alignOffset: widget.alignOffset,
        width: widget.width,
        matchAnchorWidth: widget.matchTriggerWidth,
        minWidth: widget.minWidth,
        maxHeight: widget.maxHeight,
        arrowInset: _arrowSize,
      ),
      arrow: widget.showArrow
          ? AnchoredArrow(
              size: _arrowSize,
              // The panel's fill alone, `rounded-[1px]`: PanelUI gives the
              // surface arrow the border's colour but no border width, so
              // its point carries no outline.
              color: inverted ? theme.colors.foreground : theme.colors.popover,
              radius: 1,
              // Centred on the inside of a surface label's border, as React
              // Native measures an absolute child.
              inset: inverted ? 0 : 1,
            )
          : null,
      panel: _TooltipPanel(
        variant: widget.variant,
        padding: widget.padding,
        scrollable: widget.scrollable,
        // The message already reaches screen readers through the trigger, so
        // the label itself would only be read twice.
        excludeSemantics: widget.message != null,
        child: widget.content ?? Text(widget.message!),
      ),
      child: trigger,
    );
  }
}

/// The label itself: PanelUI's `rounded-lg px-2.5 py-1.5 shadow-md`, in the
/// variant's fill, with its text `text-sm font-medium` in the variant's ink.
class _TooltipPanel extends StatelessWidget {
  const _TooltipPanel({
    required this.variant,
    required this.padding,
    required this.scrollable,
    required this.excludeSemantics,
    required this.child,
  });

  final PanelTooltipVariant variant;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final bool excludeSemantics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final inverted = variant == PanelTooltipVariant.inverted;
    final ink = inverted ? c.background : c.popoverForeground;

    // A scroller even when the label does not scroll: the content then sizes
    // to itself however it is written (a column that would fill the height
    // it is offered stays as tall as its children), and anything taller than
    // the room there is is cut off at the label's edge.
    final body = ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false, overscroll: false),
      child: SingleChildScrollView(
        physics: scrollable
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: _TooltipVariantScope(
          variant: variant,
          child: DefaultTextStyle(
            style: theme.typography.style(
              PanelTextSize.sm,
              weight: FontWeight.w500,
              color: ink,
            ),
            // Icons follow the text, at PanelUI's default icon size.
            child: IconTheme.merge(
              data: IconThemeData(color: ink, size: 16),
              child: child,
            ),
          ),
        ),
      ),
    );

    final panel = Container(
      // A container adds its border's width to the padding, as React Native
      // puts padding inside a border.
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      clipBehavior: scrollable ? Clip.antiAlias : Clip.none,
      decoration: PanelBoxDecoration(
        color: inverted ? c.foreground : c.popover,
        borderRadius: BorderRadius.circular(theme.radii.lg),
        border: inverted ? null : Border.all(color: c.border),
        boxShadow: theme.shadows.md,
      ),
      child: body,
    );
    return excludeSemantics
        ? ExcludeSemantics(child: panel)
        : Semantics(container: true, child: panel);
  }
}

class _TooltipVariantScope extends InheritedWidget {
  const _TooltipVariantScope({required this.variant, required super.child});

  final PanelTooltipVariant variant;

  static PanelTooltipVariant of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_TooltipVariantScope>()
          ?.variant ??
      PanelTooltipVariant.inverted;

  @override
  bool updateShouldNotify(_TooltipVariantScope oldWidget) =>
      variant != oldWidget.variant;
}

/// A heading inside a [PanelTooltip]'s content: small and semibold, in the
/// tooltip's text colour, and announced as a header.
class PanelTooltipTitle extends StatelessWidget {
  /// Styles [child] as a tooltip title.
  const PanelTooltipTitle({super.key, required this.child});

  /// The title, usually a [Text].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final inverted =
        _TooltipVariantScope.of(context) == PanelTooltipVariant.inverted;
    return Semantics(
      header: true,
      child: DefaultTextStyle(
        style: theme.typography.style(
          PanelTextSize.sm,
          weight: FontWeight.w600,
          color: inverted ? c.background : c.popoverForeground,
        ),
        child: child,
      ),
    );
  }
}

/// The sentence under a [PanelTooltipTitle], in the tooltip's secondary
/// colour: the inverted text at 70%, or the muted token on a surface tooltip.
class PanelTooltipDescription extends StatelessWidget {
  /// Styles [child] as a tooltip description.
  const PanelTooltipDescription({super.key, required this.child});

  /// The description, usually a [Text].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final inverted =
        _TooltipVariantScope.of(context) == PanelTooltipVariant.inverted;
    return DefaultTextStyle(
      style: theme.typography.style(
        PanelTextSize.sm,
        color: inverted
            ? c.background.withValues(alpha: c.background.a * 0.7)
            : c.mutedForeground,
      ),
      child: child,
    );
  }
}
