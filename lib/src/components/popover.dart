import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../foundation/anchored_overlay.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';
import 'bottom_sheet.dart';

/// Which side of its trigger a [PanelPopover] (or a `PanelMenu`, which is one)
/// prefers. It flips to the opposite side when the preferred one has less
/// room.
///
/// The sides beside the trigger are named by reading order rather than
/// PanelUI's `left` and `right`, so a right-to-left layout mirrors them.
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

/// How a [PanelPopover] (or a `PanelMenu`) presents its content.
enum PanelPopoverPresentation {
  /// A panel anchored to the trigger. The default.
  popover,

  /// A draggable bottom sheet: better on a small screen, or when the content
  /// is a form rather than a menu. Placement, alignment, the arrow and the
  /// backdrop do not apply to a sheet.
  bottomSheet,
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

/// PanelUI's popover entrance: a 120ms fade beside `withSpring(1, { damping:
/// 18, stiffness: 250, mass: 0.6 })` (the dialog's spring), from 94% scale
/// and 8pt towards the trigger. The exit is a 120ms fade.
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

/// The gap between an anchored panel's children, PanelUI's `gap-1.5`.
const double _panelSpacing = 6;

/// How far a sheet's content starts below its top: PanelUI's room for the
/// close button floating over the sheet's top-end corner, which nothing in
/// the flow is pushed out of the way of.
const double _sheetCloseClearance = 24;

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
/// `PanelPopover.of(context).close()`. With [presentation] set to
/// [PanelPopoverPresentation.bottomSheet] the same content opens in a sheet.
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
    this.presentation = PanelPopoverPresentation.popover,
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
    this.spacing,
    this.showArrow = false,
    this.dismissible = true,
    this.scrim = false,
    this.blur = false,
    this.unstyled = false,
    this.background,
    this.semanticLabel,
    this.closeLabel = 'Close',
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

  /// An anchored panel (the default) or a bottom sheet.
  final PanelPopoverPresentation presentation;

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
  /// area. In a sheet, content sized to itself is centred.
  final double? width;

  /// Make the panel exactly as wide as the trigger, so the two read as one
  /// control. Pair it with [minWidth] for a trigger that may be narrow. In a
  /// sheet, the content spans the sheet.
  final bool matchTriggerWidth;

  /// A floor for the panel's width. Never wins past the room there is.
  final double? minWidth;

  /// A ceiling for the panel's height, always clamped to the room inside the
  /// safe area.
  final double? maxHeight;

  /// Scroll the content when it is taller than the panel can be. Worth
  /// turning on for a list of unknown length.
  final bool scrollable;

  /// The space inside the panel. Defaults to 16 all round, or none when
  /// [unstyled].
  final EdgeInsetsGeometry? padding;

  /// The gap between [children]. Defaults to 6 in the anchored panel and to
  /// none in a sheet, where PanelUI lays them out without one.
  final double? spacing;

  /// Draws a small arrow pointing at the trigger's centre (PanelUI's
  /// `Popover.Arrow`).
  final bool showArrow;

  /// Whether a tap outside, Escape and the back gesture close the panel.
  final bool dismissible;

  /// Dims the screen behind the panel. Off by default: a popover is a panel
  /// beside something, and dimming says the rest has stopped being available.
  final bool scrim;

  /// Frosts the screen behind the panel instead of dimming it, so the panel
  /// reads as the only thing to deal with. Wins over [scrim], since the frost
  /// carries a dim of its own.
  final bool blur;

  /// Drops the panel's surface (fill, border, padding, shadow) and keeps its
  /// position, size and behaviour, for content that draws its own. The rest
  /// is clipped to the panel's rounded shape, as in PanelUI, except a single
  /// child with no [background] that does not scroll: that is placed as it
  /// is, so a shadow it draws around itself is not cut off.
  final bool unstyled;

  /// A layer drawn inside the panel behind its content and outside its
  /// scroller, so a surface does not scroll away with the rows on it. Pair
  /// it with [unstyled] to own the panel's look.
  final Widget? background;

  /// Announced as the panel's name when it opens.
  final String? semanticLabel;

  /// What screen readers call the way out: the layer behind the panel that
  /// closes it, or a sheet's close button. PanelUI's "Close" by default.
  final String closeLabel;

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
  late final PopupSheetPresenter _sheet = PopupSheetPresenter(
    onDismissed: () => _controller.close(),
  );

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSheet();
  }

  @override
  void didUpdateWidget(PanelPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscribe();
    _syncSheet();
  }

  @override
  void dispose() {
    _listening?.removeListener(_handleChange);
    _sheet.dispose();
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
    _syncSheet();
    widget.onOpenChange?.call(controller.isOpen);
  }

  /// Puts the sheet up, refreshes it or takes it down, to match the popover.
  void _syncSheet() {
    _sheet.sync(
      context,
      open:
          widget.presentation == PanelPopoverPresentation.bottomSheet && _open,
      body: () => _PopoverSheetBody(popover: widget, controller: _controller),
      route: (builder) => PanelBottomSheetRoute<void>(
        builder: builder,
        isDismissible: widget.dismissible,
        closeLabel: widget.closeLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final open = _open;
    final trigger = MergeSemantics(
      child: Semantics(
        expanded: open,
        child: widget.builder(context, controller),
      ),
    );
    if (widget.presentation == PanelPopoverPresentation.bottomSheet) {
      return _PopoverScope(controller: controller, child: trigger);
    }

    final theme = PanelTheme.of(context);
    return _PopoverScope(
      controller: controller,
      child: AnchoredOverlay(
        open: open,
        onDismiss: widget.dismissible ? controller.close : null,
        barrierLabel: widget.closeLabel,
        motion: _popoverMotion,
        scrimColor: widget.scrim ? _scrimColor : null,
        blur: widget.blur,
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
        arrow: widget.showArrow
            ? AnchoredArrow(
                size: _arrowSize,
                color: theme.colors.popover,
                borderColor: theme.colors.border,
                borderWidth: 1,
                // Centred on the inside of the panel's border, as React
                // Native measures an absolute child; unstyled has none.
                inset: widget.unstyled ? 0 : 1,
              )
            : null,
        panel: _PopoverPanel(popover: widget),
        child: trigger,
      ),
    );
  }
}

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

class _PopoverScope extends InheritedWidget {
  const _PopoverScope({required this.controller, required super.child});

  final PanelPopoverController controller;

  @override
  bool updateShouldNotify(_PopoverScope oldWidget) =>
      controller != oldWidget.controller;
}

/// The anchored panel: PanelUI's `rounded-2xl border border-border
/// bg-popover p-4 shadow-lg`, its children `gap-1.5` apart.
class _PopoverPanel extends StatelessWidget {
  const _PopoverPanel({required this.popover});

  final PanelPopover popover;

  /// Content that draws its own surface, placed as it is.
  bool get _bare =>
      popover.unstyled &&
      popover.children.length == 1 &&
      !popover.scrollable &&
      popover.background == null;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final radius = theme.radii.xxl;
    Widget panel;
    if (_bare) {
      panel = popover.children.single;
    } else if (popover.unstyled) {
      panel = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _content(context),
      );
    } else {
      panel = _content(context);
      // Clipped, as PanelUI's panel is, only when something could reach past
      // its rounded corners: rows scrolling under them, or a background.
      // The clip follows the inside of the 1pt border, which stays whole.
      if (popover.scrollable || popover.background != null) {
        panel = ClipRRect(
          borderRadius: BorderRadius.circular(math.max(0, radius - 1)),
          child: panel,
        );
      }
      panel = DecoratedBox(
        decoration: BoxDecoration(
          color: c.popover,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: theme.shadows.lg,
        ),
        child: Padding(padding: const EdgeInsets.all(1), child: panel),
      );
    }
    panel = _PopoverContentStyle(child: panel);
    // Sized to its content, the panel needs its widest child's width before
    // a stretched column can lay the others out to it.
    if (popover.width == null && !popover.matchTriggerWidth) {
      panel = IntrinsicWidth(child: panel);
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: popover.semanticLabel != null,
      label: popover.semanticLabel,
      child: panel,
    );
  }

  /// The children in a column, inside a scroller even when the panel does
  /// not scroll, so content taller than the room there is is cut off at the
  /// panel's edge rather than overflowing it; and the background behind.
  Widget _content(BuildContext context) {
    Widget content = Padding(
      padding:
          popover.padding ??
          (popover.unstyled ? EdgeInsets.zero : const EdgeInsets.all(16)),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(scrollbars: false, overscroll: false),
        child: SingleChildScrollView(
          physics: popover.scrollable
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: popover.spacing ?? _panelSpacing,
            children: popover.children,
          ),
        ),
      ),
    );
    final background = popover.background;
    if (background != null) {
      content = Stack(
        children: [
          Positioned.fill(child: background),
          content,
        ],
      );
    }
    return content;
  }
}

/// The content of a popover presented as a bottom sheet: PanelUI's sheet
/// body, which starts below the close button, centres content sized to
/// itself and spans the sheet for a trigger-wide or full-width popover. It
/// scrolls when it is taller than the sheet can be.
class _PopoverSheetBody extends StatelessWidget {
  const _PopoverSheetBody({required this.popover, required this.controller});

  final PanelPopover popover;
  final PanelPopoverController controller;

  @override
  Widget build(BuildContext context) {
    final width = popover.width;
    final fitsContent = width == null && !popover.matchTriggerWidth;
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: popover.spacing ?? 0,
      children: popover.children,
    );
    final minWidth = popover.minWidth;
    if (minWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: content,
      );
    }
    if (fitsContent) {
      content = Center(child: IntrinsicWidth(child: content));
    } else if (width != null && width.isFinite) {
      content = Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(width: width, child: content),
      );
    }
    return _PopoverScope(
      controller: controller,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        namesRoute: popover.semanticLabel != null,
        label: popover.semanticLabel,
        child: _PopoverContentStyle(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PanelBottomSheetBody(
                padding: const EdgeInsets.only(top: _sheetCloseClearance),
                children: [content],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How bare content in a popover is drawn, anchored or in a sheet: PanelUI
/// wraps bare text in its Text primitive, base size in the foreground, and an
/// icon dropped in follows the text at PanelUI's default icon size.
class _PopoverContentStyle extends StatelessWidget {
  const _PopoverContentStyle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final foreground = theme.colors.foreground;
    return DefaultTextStyle(
      style: theme.typography.style(PanelTextSize.base, color: foreground),
      child: IconTheme.merge(
        data: IconThemeData(color: foreground, size: 16),
        child: child,
      ),
    );
  }
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
