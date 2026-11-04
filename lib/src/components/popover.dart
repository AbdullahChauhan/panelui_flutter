import 'package:flutter/widgets.dart';

import '../foundation/anchored_overlay.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_theme_data.dart';
import '../theme/panel_typography.dart';

/// Which side of its trigger a [PanelPopover] (or a `PanelMenu`, which is one)
/// prefers. It flips to the opposite side when the preferred one has less
/// room.
enum PanelPopoverPlacement {
  /// Above the trigger.
  top,

  /// Below the trigger. The default.
  bottom,

  /// Before the trigger in reading order: the left in a left-to-right layout.
  start,

  /// After the trigger in reading order.
  end,
}

/// Where a [PanelPopover] lines up along its trigger's other axis.
enum PanelPopoverAlign {
  /// Leading edges line up (top edges beside the trigger).
  start,

  /// Centred on the trigger. The default.
  center,

  /// Trailing edges line up (bottom edges beside the trigger).
  end,
}

/// Opens and closes a [PanelPopover] (or a `PanelMenu`, which is one).
///
/// Hand one to the popover to control it from outside, or use the one its
/// `builder` receives to wire up the trigger:
///
/// ```dart
/// PanelPopover(
///   builder: (context, controller) => PanelButton(
///     onPressed: controller.toggle,
///     child: const Text('Options'),
///   ),
///   children: const [PanelPopoverTitle(child: Text('Export'))],
/// )
/// ```
class PanelPopoverController extends ChangeNotifier {
  /// Creates a controller, closed unless [initiallyOpen].
  PanelPopoverController({bool initiallyOpen = false})
    : _isOpen = initiallyOpen;

  bool _isOpen;

  /// Whether the panel is open.
  bool get isOpen => _isOpen;

  /// Opens the panel.
  void open() => _update(true);

  /// Closes the panel.
  void close() => _update(false);

  /// Opens the panel if it is closed, and closes it if it is open.
  void toggle() => isOpen ? close() : open();

  void _update(bool value) {
    if (value == _isOpen) return;
    _isOpen = value;
    notifyListeners();
  }
}

/// Builds the trigger of a [PanelPopover] or a `PanelMenu`, given the
/// controller that opens it.
typedef PanelPopoverTriggerBuilder =
    Widget Function(BuildContext context, PanelPopoverController controller);

/// The controller a [PanelPopover] hands out while its open state belongs to
/// the parent: a request to open or close goes to `onOpenChange` instead of
/// changing anything itself.
class _RequestController extends PanelPopoverController {
  _RequestController(this._state);

  final _PanelPopoverState _state;

  @override
  bool get isOpen => _state.widget.isOpen ?? false;

  @override
  void open() {
    if (!isOpen) _state.widget.onOpenChange?.call(true);
  }

  @override
  void close() {
    if (isOpen) _state.widget.onOpenChange?.call(false);
  }
}

/// PanelUI's popover entrance: a 120ms fade beside `withSpring(1, { damping:
/// 18, stiffness: 250, mass: 0.6 })`, from 94% scale and 8pt towards the
/// trigger. The exit is a 120ms fade.
const AnchoredMotion _popoverMotion = AnchoredMotion(
  enter: Duration(milliseconds: 120),
  exit: Duration(milliseconds: 120),
  spring: PanelSprings.dialog,
  shift: 8,
  scaleFrom: 0.94,
);

/// The side of the arrow's square before it is turned 45°.
const double _arrowSize = 12;

/// PanelUI's popover dim, `bg-black/30`.
const Color _scrimColor = Color(0x4D000000);

/// A panel anchored to the thing that opened it.
///
/// A dialog takes the screen and asks to be dealt with; a popover stays next
/// to its trigger and keeps the context around it visible.
///
/// ```dart
/// PanelPopover(
///   align: PanelPopoverAlign.end,
///   builder: (context, controller) => PanelButton(
///     variant: PanelButtonVariant.outline,
///     onPressed: controller.toggle,
///     child: const Text('Export'),
///   ),
///   children: const [
///     PanelPopoverTitle(child: Text('Export')),
///     PanelPopoverDescription(child: Text('Choose a format.')),
///   ],
/// )
/// ```
///
/// Placement is a preference, not a promise: [placement] `bottom` means below
/// if below fits. A panel that would run off the bottom flips above the
/// trigger, one that would run off the side slides back inside, and the panel
/// is capped at the room inside the safe area so none of it falls off screen.
///
/// It closes on a tap outside, Escape and the back gesture (unless not
/// [dismissible]). Focus moves into the panel while it is open and returns to
/// the trigger afterwards. Content can close it with
/// `PanelPopover.of(context).close()`.
///
/// The open state is the popover's own unless a [controller] or [isOpen] is
/// given; [onOpenChange] reports every change either way.
class PanelPopover extends StatefulWidget {
  /// Creates a popover.
  const PanelPopover({
    super.key,
    required this.builder,
    this.children = const [],
    this.controller,
    this.isOpen,
    this.onOpenChange,
    this.initiallyOpen = false,
    this.placement = PanelPopoverPlacement.bottom,
    this.align = PanelPopoverAlign.center,
    this.offset = 8,
    this.alignOffset = 0,
    this.width,
    this.matchTriggerWidth = false,
    this.minWidth,
    this.maxHeight,
    this.scrollable = false,
    this.padding,
    this.spacing = 6,
    this.showArrow = false,
    this.dismissible = true,
    this.scrim = false,
    this.unstyled = false,
    this.semanticLabel,
  }) : assert(
         controller == null || isOpen == null,
         'Control the popover with a controller or with isOpen, not both.',
       );

  /// Builds the trigger, given the controller that opens the panel. It is
  /// announced as expanded or collapsed, and so is merged into one semantics
  /// node: build a single control, such as a `PanelButton`.
  final PanelPopoverTriggerBuilder builder;

  /// The panel's content, laid out top to bottom [spacing] apart and
  /// stretched to the panel's width.
  final List<Widget> children;

  /// Controls the open state from outside.
  final PanelPopoverController? controller;

  /// Whether the panel is open, for a popover whose parent owns the state.
  /// Requests to change it go to [onOpenChange].
  final bool? isOpen;

  /// Called whenever the panel opens or closes, or asks to.
  final ValueChanged<bool>? onOpenChange;

  /// Whether an uncontrolled popover starts open.
  final bool initiallyOpen;

  /// The preferred side of the trigger.
  final PanelPopoverPlacement placement;

  /// Where the panel lines up along the trigger's other axis.
  final PanelPopoverAlign align;

  /// The gap between the trigger and the panel.
  final double offset;

  /// A nudge along the alignment axis.
  final double alignOffset;

  /// A fixed width. Null sizes the panel to its content (which then has to be
  /// able to report its intrinsic width); [double.infinity] spans the safe
  /// area.
  final double? width;

  /// Make the panel exactly as wide as the trigger, so the two read as one
  /// control. Pair it with [minWidth] for a trigger that may be narrow.
  final bool matchTriggerWidth;

  /// A floor for the panel's width. Never wins past the room there is.
  final double? minWidth;

  /// A ceiling for the panel's height, always clamped to the room inside the
  /// safe area.
  final double? maxHeight;

  /// Scroll the content when it is taller than the panel can be. Worth
  /// turning on for a list of unknown length.
  final bool scrollable;

  /// The space inside the panel. Defaults to 16 all round.
  final EdgeInsetsGeometry? padding;

  /// The gap between [children].
  final double spacing;

  /// Draws a small arrow pointing at the trigger's centre (PanelUI's
  /// `Popover.Arrow`).
  final bool showArrow;

  /// Whether a tap outside, Escape and the back gesture close the panel.
  final bool dismissible;

  /// Dims the screen behind the panel. Off by default: a popover is a panel
  /// beside something, and dimming says the rest has stopped being available.
  final bool scrim;

  /// Drops the panel's surface (fill, border, radius, padding, shadow) and
  /// keeps only its position, size and behaviour, for content that draws its
  /// own. A single child is placed as it is.
  final bool unstyled;

  /// Announced as the panel's name when it opens.
  final String? semanticLabel;

  /// The controller of the nearest popover, from inside its trigger or its
  /// content, or null outside one.
  static PanelPopoverController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PopoverScope>()?.controller;

  /// The controller of the nearest popover, for content that closes it.
  static PanelPopoverController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No PanelPopover above this context.');
    return controller!;
  }

  @override
  State<PanelPopover> createState() => _PanelPopoverState();
}

class _PanelPopoverState extends State<PanelPopover> {
  PanelPopoverController? _owned;
  late final _RequestController _request = _RequestController(this);
  PanelPopoverController? _listening;

  PanelPopoverController get _controller {
    if (widget.isOpen != null) return _request;
    return widget.controller ??
        (_owned ??= PanelPopoverController(
          initiallyOpen: widget.initiallyOpen,
        ));
  }

  bool get _open => widget.isOpen ?? _controller.isOpen;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(PanelPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscribe();
  }

  @override
  void dispose() {
    _listening?.removeListener(_handleChange);
    _owned?.dispose();
    _request.dispose();
    super.dispose();
  }

  void _subscribe() {
    final target = widget.isOpen != null ? null : _controller;
    if (target == _listening) return;
    _listening?.removeListener(_handleChange);
    _listening = target;
    _listening?.addListener(_handleChange);
  }

  void _handleChange() {
    final controller = _listening;
    if (controller == null) return;
    setState(() {});
    widget.onOpenChange?.call(controller.isOpen);
  }

  Widget _buildPanel(PanelThemeData theme) {
    final c = theme.colors;
    final children = widget.children;
    Widget panel;
    if (widget.unstyled && children.length == 1) {
      panel = children.single;
    } else {
      panel = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: widget.unstyled ? 0 : widget.spacing,
        children: children,
      );
    }
    if (!widget.unstyled) {
      // A scroller even when the panel does not scroll, so content taller
      // than the room there is is cut off at the panel's edge rather than
      // overflowing it.
      panel = ScrollConfiguration(
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(scrollbars: false, overscroll: false),
        child: SingleChildScrollView(
          physics: widget.scrollable
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: panel,
        ),
      );
      panel = DefaultTextStyle(
        style: theme.typography.style(
          PanelTextSize.base,
          color: c.popoverForeground,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: c.popoverForeground, size: 16),
          child: panel,
        ),
      );
      panel = Container(
        padding: widget.padding ?? const EdgeInsets.all(16),
        clipBehavior: widget.scrollable ? Clip.antiAlias : Clip.none,
        decoration: BoxDecoration(
          color: c.popover,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(theme.radii.xxl),
          boxShadow: theme.shadows.lg,
        ),
        child: panel,
      );
    }
    if (widget.width == null && !widget.matchTriggerWidth) {
      panel = IntrinsicWidth(child: panel);
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: widget.semanticLabel != null,
      label: widget.semanticLabel,
      child: panel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final controller = _controller;
    final open = _open;
    final trigger = MergeSemantics(
      child: Semantics(
        expanded: open,
        child: widget.builder(context, controller),
      ),
    );

    return _PopoverScope(
      controller: controller,
      child: AnchoredOverlay(
        open: open,
        onDismiss: widget.dismissible ? controller.close : null,
        motion: _popoverMotion,
        scrimColor: widget.scrim ? _scrimColor : null,
        position: AnchoredPosition(
          placement: switch (widget.placement) {
            PanelPopoverPlacement.top => AnchorPlacement.top,
            PanelPopoverPlacement.bottom => AnchorPlacement.bottom,
            PanelPopoverPlacement.start => AnchorPlacement.start,
            PanelPopoverPlacement.end => AnchorPlacement.end,
          },
          align: switch (widget.align) {
            PanelPopoverAlign.start => AnchorAlign.start,
            PanelPopoverAlign.center => AnchorAlign.center,
            PanelPopoverAlign.end => AnchorAlign.end,
          },
          offset: widget.offset,
          alignOffset: widget.alignOffset,
          width: widget.width,
          matchAnchorWidth: widget.matchTriggerWidth,
          minWidth: widget.minWidth,
          maxHeight: widget.maxHeight,
          arrowInset: _arrowSize,
        ),
        arrow: widget.showArrow && !widget.unstyled
            ? AnchoredArrow(
                size: _arrowSize,
                color: theme.colors.popover,
                borderColor: theme.colors.border,
                borderWidth: 1,
                inset: 1,
              )
            : null,
        panel: _buildPanel(theme),
        child: trigger,
      ),
    );
  }
}

class _PopoverScope extends InheritedWidget {
  const _PopoverScope({required this.controller, required super.child});

  final PanelPopoverController controller;

  @override
  bool updateShouldNotify(_PopoverScope oldWidget) =>
      controller != oldWidget.controller;
}

/// A popover's heading: base size, semibold.
class PanelPopoverTitle extends StatelessWidget {
  /// Styles [child] as a popover title.
  const PanelPopoverTitle({super.key, required this.child});

  /// The title, usually a [Text].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return Semantics(
      header: true,
      child: DefaultTextStyle(
        style: theme.typography.style(
          PanelTextSize.base,
          weight: FontWeight.w600,
          color: theme.colors.popoverForeground,
        ),
        child: child,
      ),
    );
  }
}

/// A popover's supporting text: small and muted.
class PanelPopoverDescription extends StatelessWidget {
  /// Styles [child] as a popover description.
  const PanelPopoverDescription({super.key, required this.child});

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
