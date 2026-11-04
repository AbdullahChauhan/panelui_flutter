import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/anchored_overlay.dart';
import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';
import 'popover.dart';

/// How a [PanelMenuItem] is coloured.
enum PanelMenuItemVariant {
  /// An ordinary row. PanelUI's `default`.
  plain,

  /// A row for an action that removes something: red text and a red-tinted
  /// press, so it is not read past at a glance.
  destructive,
}

/// What marks the chosen [PanelMenuRadioItem].
enum PanelMenuRadioIndicator {
  /// A tick. The default.
  check,

  /// A small filled dot, quieter beside a list of nouns.
  dot,
}

/// The side of the column every row's leading glyph sits in.
const double _indicatorSize = 18;

/// The start padding of a row with no glyph that still lines up with the
/// rows that have one: the row's own 10, the column and the 10 gap after it.
const double _insetStart = 38;

/// The menu's padding, PanelUI's `p-1.5`: the row gutter, so a pressed
/// row's fill runs to the panel's inner edge and reads as part of it.
const double _panelPadding = 6;

/// The gap between rows on the panel itself, PanelUI's `gap-0.5`.
const double _rowGap = 2;

/// The gap between rows inside the panel's scroller, which takes the
/// popover's `gap-1.5` in PanelUI rather than the menu's own.
const double _scrolledRowGap = 6;

/// How faded a disabled row is, PanelUI's `opacity-[0.45]`.
const double _disabledOpacity = 0.45;

/// How long a row takes to light up under a finger, and to let go again.
const Duration _pressIn = Duration(milliseconds: 90);
const Duration _pressOut = Duration(milliseconds: 160);

/// How far a pressed row shrinks: enough to feel, not enough to see move.
const double _pressScale = 0.98;

/// The list of things you can do to something.
///
/// It is not a select: a select's rows are values, and its trigger shows the
/// one chosen; a menu's rows are verbs (rename, duplicate, delete), and its
/// trigger goes on saying the same thing afterwards.
///
/// ```dart
/// PanelMenu(
///   align: PanelPopoverAlign.start,
///   width: 224,
///   builder: (context, controller) => PanelButton(
///     variant: PanelButtonVariant.outline,
///     onPressed: controller.toggle,
///     child: const Text('Options'),
///   ),
///   children: [
///     PanelMenuItem(
///       leading: const PanelIcon(PanelIcons.pencil),
///       shortcut: '⌘R',
///       onSelected: rename,
///       child: const Text('Rename'),
///     ),
///     const PanelMenuSeparator(),
///     PanelMenuItem(
///       variant: PanelMenuItemVariant.destructive,
///       leading: const PanelIcon(PanelIcons.trash),
///       onSelected: delete,
///       child: const Text('Delete'),
///     ),
///   ],
/// )
/// ```
///
/// The panel is a [PanelPopover] underneath, so it is measured, flipped and
/// kept on screen the same way, and takes the same placement and size
/// options; [presentation] moves the same rows into a bottom sheet. Its
/// surface is the `overlay` token, drawn as a layer behind the rows that
/// [background] can replace.
///
/// A row runs its action and closes the menu. Arrow keys, Home and End move
/// between rows, Enter or Space runs one, and Escape or Tab closes the menu.
/// A row under the pointer or the keyboard is lit as in PanelUI's web menu.
/// Submenus ([PanelMenuSub]) expand in place rather than flying out sideways,
/// which a finger cannot follow.
class PanelMenu extends StatelessWidget {
  /// Creates a menu.
  const PanelMenu({
    super.key,
    required this.builder,
    required this.children,
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
    this.scrollable = true,
    this.background,
    this.haptics = false,
    this.dismissible = true,
    this.scrim = false,
    this.blur = false,
    this.semanticLabel,
    this.closeLabel = 'Close',
  });

  /// Builds the trigger, given the controller that opens the menu.
  final PanelPopoverTriggerBuilder builder;

  /// The rows: [PanelMenuItem], [PanelMenuCheckboxItem],
  /// [PanelMenuRadioGroup], [PanelMenuSub], [PanelMenuLabel] and
  /// [PanelMenuSeparator].
  final List<Widget> children;

  /// Controls the open state from outside.
  final PanelPopoverController? controller;

  /// Whether the menu is open, for a menu whose parent owns the state.
  final bool? isOpen;

  /// Called whenever the menu opens or closes, or asks to.
  final ValueChanged<bool>? onOpenChange;

  /// Whether an uncontrolled menu starts open.
  final bool initiallyOpen;

  /// A panel anchored to the trigger (the default), or the same rows in a
  /// bottom sheet, which is better on a small screen than a panel floating
  /// over the thing being acted on.
  final PanelPopoverPresentation presentation;

  /// The preferred side of the trigger.
  final PanelPopoverPlacement placement;

  /// Where the panel lines up along the trigger's other axis.
  final PanelPopoverAlign align;

  /// The gap between the trigger and the panel.
  final double offset;

  /// A nudge along the alignment axis.
  final double alignOffset;

  /// A fixed width. Null sizes the menu to its widest row (centred, in a
  /// sheet).
  final double? width;

  /// Make the menu exactly as wide as the trigger.
  final bool matchTriggerWidth;

  /// A floor for the menu's width.
  final double? minWidth;

  /// A ceiling for the menu's height, always clamped to the room inside the
  /// safe area.
  final double? maxHeight;

  /// Scroll the rows when there are more than fit. On by default, unlike a
  /// popover: a menu's length is usually a map over data, and a row that
  /// cannot be reached may as well not exist.
  final bool scrollable;

  /// What the panel is made of, drawn behind the rows and outside the
  /// scroller (PanelUI's `Menu.Background`). Defaults to the `overlay` token.
  /// A sheet is its own surface, so it does not draw one.
  final Widget? background;

  /// Ticks the haptic engine as a row is chosen.
  final bool haptics;

  /// Whether a tap outside, Escape and the back gesture close the menu.
  final bool dismissible;

  /// Dims the screen behind the menu.
  final bool scrim;

  /// Frosts the screen behind the menu instead of dimming it.
  final bool blur;

  /// Announced as the menu's name when it opens.
  final String? semanticLabel;

  /// What screen readers call the way out of the menu: the layer behind it,
  /// or a sheet's close button.
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final sheet = presentation == PanelPopoverPresentation.bottomSheet;
    return PanelPopover(
      builder: builder,
      controller: controller,
      isOpen: isOpen,
      onOpenChange: onOpenChange,
      initiallyOpen: initiallyOpen,
      presentation: presentation,
      placement: placement,
      align: align,
      offset: offset,
      alignOffset: alignOffset,
      width: width,
      matchTriggerWidth: matchTriggerWidth,
      minWidth: minWidth,
      maxHeight: maxHeight,
      dismissible: dismissible,
      scrim: scrim,
      blur: blur,
      semanticLabel: semanticLabel,
      closeLabel: closeLabel,
      // The menu draws its own surface: its corners are rounder than a
      // popover's, and its shadow has to fall outside the clip that keeps
      // the background inside them.
      unstyled: true,
      children: [
        if (sheet)
          // In a sheet the rows sit on the sheet's own surface, `gap-0.5`
          // apart inside the menu's `p-1.5`, as PanelUI lays them out there.
          Padding(
            padding: const EdgeInsets.all(_panelPadding),
            child: _MenuRows(
              gap: _rowGap,
              haptics: haptics,
              children: children,
            ),
          )
        else
          _MenuPanel(
            scrollable: scrollable,
            background: background,
            haptics: haptics,
            children: children,
          ),
      ],
    );
  }
}

/// The anchored menu's surface: a rounded `overlay` layer behind a column of
/// rows, with PanelUI's `shadow-lg` falling outside it.
class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.scrollable,
    required this.background,
    required this.haptics,
    required this.children,
  });

  final bool scrollable;
  final Widget? background;
  final bool haptics;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final radius = BorderRadius.circular(theme.radii.xxxl);
    final rows = ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false, overscroll: false),
      child: SingleChildScrollView(
        physics: scrollable
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: _MenuRows(
          gap: scrollable ? _scrolledRowGap : _rowGap,
          haptics: haptics,
          children: children,
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: theme.shadows.lg,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: background ?? ColoredBox(color: theme.colors.overlay),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(_panelPadding), child: rows),
          ],
        ),
      ),
    );
  }
}

/// The rows of a menu, wherever it is presented: a column [gap] apart that
/// is announced as a menu and moved through with the arrow keys.
class _MenuRows extends StatelessWidget {
  const _MenuRows({
    required this.gap,
    required this.haptics,
    required this.children,
  });

  final double gap;
  final bool haptics;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    Widget rows = PopupListNavigation(
      onTab: () => PanelPopover.maybeOf(context)?.close(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: children,
      ),
    );
    if (children.isNotEmpty) {
      rows = Semantics(
        role: SemanticsRole.menu,
        explicitChildNodes: true,
        child: rows,
      );
    }
    return _MenuScope(haptics: haptics, gap: gap, child: rows);
  }
}

/// What a row needs from the menu around it.
class _MenuScope extends InheritedWidget {
  const _MenuScope({
    required this.haptics,
    required this.gap,
    required super.child,
  });

  /// Whether choosing a row ticks the haptic engine.
  final bool haptics;

  /// The gap between the menu's rows, which a submenu also leaves between
  /// its trigger and the rows it reveals.
  final double gap;

  static _MenuScope? _of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_MenuScope>();

  @override
  bool updateShouldNotify(_MenuScope oldWidget) =>
      haptics != oldWidget.haptics || gap != oldWidget.gap;
}

/// One row of a menu: an action.
///
/// It runs [onSelected] and closes the menu (unless [closeOnSelect] is
/// false). A null [onSelected] disables the row, which is drawn at 45%
/// opacity and skipped by the arrow keys.
class PanelMenuItem extends StatelessWidget {
  /// Creates a row.
  const PanelMenuItem({
    super.key,
    required this.child,
    this.onSelected,
    this.leading,
    this.description,
    this.shortcut,
    this.trailing,
    this.variant = PanelMenuItemVariant.plain,
    this.inset = false,
    this.closeOnSelect = true,
    this.semanticLabel,
  });

  /// The label, usually a [Text].
  final Widget child;

  /// Called when the row is chosen. Null disables it.
  final VoidCallback? onSelected;

  /// A glyph in the leading column, such as a [PanelIcon]. It is drawn at 16
  /// in the muted colour, and takes the label's colour while the row is lit.
  final Widget? leading;

  /// A second, muted line under the label, for a row whose effect needs a
  /// sentence.
  final String? description;

  /// A keyboard or gesture shortcut shown at the end of the row. It only shows
  /// it: wire the keys up where the action lives.
  final String? shortcut;

  /// Content pinned to the end of the row, after the shortcut, such as a
  /// badge.
  final Widget? trailing;

  /// Plain or destructive.
  final PanelMenuItemVariant variant;

  /// Line the label up with rows that have a [leading] glyph, without
  /// drawing one.
  final bool inset;

  /// Close the menu once the row has run.
  final bool closeOnSelect;

  /// The accessible name, when the label is not text.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return _MenuRow(
      label: child,
      onPressed: onSelected,
      leading: leading,
      reserveLeading: inset,
      description: description,
      shortcut: shortcut,
      trailing: trailing,
      variant: variant,
      closeOnSelect: closeOnSelect,
      role: SemanticsRole.menuItem,
      semanticLabel: semanticLabel,
    );
  }
}

/// A menu row that carries a state instead of running an action, with a tick
/// in the leading column while [value] is true.
///
/// It keeps the menu open by default, the opposite of [PanelMenuItem]: a set
/// of toggles is nearly always set more than one at a time.
class PanelMenuCheckboxItem extends StatelessWidget {
  /// Creates a checkable row.
  const PanelMenuCheckboxItem({
    super.key,
    required this.value,
    required this.onChanged,
    required this.child,
    this.description,
    this.shortcut,
    this.trailing,
    this.variant = PanelMenuItemVariant.plain,
    this.closeOnSelect = false,
    this.semanticLabel,
  });

  /// Whether the row is checked.
  final bool value;

  /// Called with the new value. Null disables the row.
  final ValueChanged<bool>? onChanged;

  /// The label, usually a [Text].
  final Widget child;

  /// A second, muted line under the label.
  final String? description;

  /// A shortcut shown at the end of the row.
  final String? shortcut;

  /// Content pinned to the end of the row.
  final Widget? trailing;

  /// Plain or destructive.
  final PanelMenuItemVariant variant;

  /// Close the menu once the row has been toggled.
  final bool closeOnSelect;

  /// The accessible name, when the label is not text.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return _MenuRow(
      label: child,
      onPressed: onChanged == null ? null : () => onChanged(!value),
      // An empty column rather than none, so the label does not step
      // sideways as the tick comes and goes.
      leading: value
          ? const _MenuIndicator(PanelMenuRadioIndicator.check)
          : const SizedBox.shrink(),
      description: description,
      shortcut: shortcut,
      trailing: trailing,
      variant: variant,
      closeOnSelect: closeOnSelect,
      role: SemanticsRole.menuItemCheckbox,
      checked: value,
      semanticLabel: semanticLabel,
    );
  }
}

/// A run of [PanelMenuRadioItem]s of which one is chosen.
class PanelMenuRadioGroup<T> extends StatelessWidget {
  /// Creates a radio group.
  const PanelMenuRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
  });

  /// The value of the chosen item.
  final T? value;

  /// Called with the value of the item chosen. Null disables the group.
  final ValueChanged<T>? onChanged;

  /// The items. PanelUI's group is a plain view, so they sit with no gap
  /// between them, whatever the menu's own.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _RadioScope<T>(
      value: value,
      onChanged: onChanged,
      child: Semantics(
        role: SemanticsRole.radioGroup,
        explicitChildNodes: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _RadioScope<T> extends InheritedWidget {
  const _RadioScope({
    required this.value,
    required this.onChanged,
    required super.child,
  });

  final T? value;
  final ValueChanged<T>? onChanged;

  @override
  bool updateShouldNotify(_RadioScope<T> oldWidget) =>
      value != oldWidget.value || onChanged != oldWidget.onChanged;
}

/// One option inside a [PanelMenuRadioGroup], marked while it is the group's
/// value. It closes the menu when chosen, unless [closeOnSelect] is false.
class PanelMenuRadioItem<T> extends StatelessWidget {
  /// Creates a radio row.
  const PanelMenuRadioItem({
    super.key,
    required this.value,
    required this.child,
    this.indicator = PanelMenuRadioIndicator.check,
    this.enabled = true,
    this.description,
    this.shortcut,
    this.trailing,
    this.variant = PanelMenuItemVariant.plain,
    this.closeOnSelect = true,
    this.semanticLabel,
  });

  /// The value this row stands for.
  final T value;

  /// The label, usually a [Text].
  final Widget child;

  /// A tick or a dot.
  final PanelMenuRadioIndicator indicator;

  /// Whether the row can be chosen.
  final bool enabled;

  /// A second, muted line under the label.
  final String? description;

  /// A shortcut shown at the end of the row.
  final String? shortcut;

  /// Content pinned to the end of the row.
  final Widget? trailing;

  /// Plain or destructive.
  final PanelMenuItemVariant variant;

  /// Close the menu once the row has been chosen.
  final bool closeOnSelect;

  /// The accessible name, when the label is not text.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final group = context.dependOnInheritedWidgetOfExactType<_RadioScope<T>>();
    assert(
      group != null,
      'A PanelMenuRadioItem<$T> must be inside a PanelMenuRadioGroup<$T>.',
    );
    final selected = group?.value == value;
    final onChanged = group?.onChanged;
    return _MenuRow(
      label: child,
      onPressed: enabled && onChanged != null ? () => onChanged(value) : null,
      // Held open when unmarked, so the options stay in one column as the
      // choice moves between them.
      leading: selected ? _MenuIndicator(indicator) : const SizedBox.shrink(),
      description: description,
      shortcut: shortcut,
      trailing: trailing,
      variant: variant,
      closeOnSelect: closeOnSelect,
      role: SemanticsRole.menuItemRadio,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: semanticLabel,
    );
  }
}

/// A row that opens a submenu in place, and the rows it reveals.
///
/// The rows expand downwards into the panel, indented and ruled along their
/// leading edge, rather than flying out in a second panel: a finger has no
/// path across to one, and a second panel is usually what pushes a menu off
/// the edge of a phone. The chevron points along the reading direction while
/// closed and turns to point down once open.
///
/// The arrow key pointing along the reading direction opens it and moves into
/// its rows; the one pointing back closes it.
class PanelMenuSub extends StatefulWidget {
  /// Creates a submenu.
  const PanelMenuSub({
    super.key,
    required this.child,
    required this.children,
    this.leading,
    this.description,
    this.enabled = true,
    this.inset = false,
    this.initiallyOpen = false,
    this.isOpen,
    this.onOpenChange,
  });

  /// The trigger row's label, usually a [Text].
  final Widget child;

  /// The rows revealed when open.
  final List<Widget> children;

  /// A glyph in the trigger row's leading column.
  final Widget? leading;

  /// A second, muted line under the trigger row's label.
  final String? description;

  /// Whether the submenu can be opened.
  final bool enabled;

  /// Line the trigger row up with rows that have a glyph.
  final bool inset;

  /// Whether an uncontrolled submenu starts open.
  final bool initiallyOpen;

  /// Whether the submenu is open, for one whose parent owns the state.
  final bool? isOpen;

  /// Called when the submenu opens or closes, or asks to.
  final ValueChanged<bool>? onOpenChange;

  @override
  State<PanelMenuSub> createState() => _PanelMenuSubState();
}

class _PanelMenuSubState extends State<PanelMenuSub>
    with TickerProviderStateMixin {
  late bool _internalOpen = widget.initiallyOpen;
  final FocusNode _triggerNode = FocusNode(debugLabel: 'PanelMenuSub');

  bool get _open => widget.isOpen ?? _internalOpen;

  /// PanelUI turns the chevron over 180ms and opens the rows over 200ms.
  late final AnimationController _chevron = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: _open ? 1 : 0,
  );
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: _open ? 1 : 0,
  );

  @override
  void didUpdateWidget(PanelMenuSub oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) _animate();
  }

  @override
  void dispose() {
    _chevron.dispose();
    _expand.dispose();
    _triggerNode.dispose();
    super.dispose();
  }

  void _animate() {
    final target = _open ? 1.0 : 0.0;
    if (panelReduceMotion(context)) {
      _chevron.value = target;
      _expand.value = target;
    } else {
      _chevron.animateTo(target, curve: panelEase);
      _expand.animateTo(target, curve: panelEase);
    }
  }

  void _setOpen(bool value) {
    if (value == _open) return;
    if (widget.isOpen == null) {
      setState(() => _internalOpen = value);
      _animate();
    }
    widget.onOpenChange?.call(value);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final back = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == forward && _triggerNode.hasPrimaryFocus) {
      if (!_open) {
        _setOpen(true);
      } else {
        FocusTraversalGroup.maybeOf(context)?.next(_triggerNode);
      }
      return KeyEventResult.handled;
    }
    if (key == back && _open) {
      _triggerNode.requestFocus();
      _setOpen(false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final open = _open;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _handleKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MenuRow(
            label: widget.child,
            focusNode: _triggerNode,
            onPressed: widget.enabled ? () => _setOpen(!open) : null,
            leading: widget.leading,
            reserveLeading: widget.inset,
            description: widget.description,
            trailing: _SubChevron(turn: _chevron),
            variant: PanelMenuItemVariant.plain,
            closeOnSelect: false,
            role: SemanticsRole.menuItem,
            expanded: open,
          ),
          // PanelUI's trigger row and its rows are separate items in the
          // menu's column, so the menu's gap falls between them, and again
          // after them, even while the rows are folded away to nothing.
          SizedBox(height: _MenuScope._of(context)?.gap ?? _scrolledRowGap),
          _SubRows(expand: _expand, open: open, children: widget.children),
        ],
      ),
    );
  }
}

/// A submenu's chevron: along the line of text while closed, turned a
/// quarter to point down into the rows once open. Under right-to-left the
/// glyph mirrors itself and the turn runs the other way, so the two compose.
class _SubChevron extends StatelessWidget {
  const _SubChevron({required this.turn});

  /// From 0, closed, to 1, open.
  final Animation<double> turn;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return RotationTransition(
      turns: turn.drive(Tween<double>(begin: 0, end: rtl ? -0.25 : 0.25)),
      child: PanelIcon(
        PanelIcons.chevronRight,
        size: 16,
        strokeWidth: 2,
        color: PanelTheme.of(context).colors.mutedForeground,
      ),
    );
  }
}

/// The rows a submenu reveals, opening in place: indented and ruled along
/// their leading edge (PanelUI's `ms-4 gap-0.5 border-s border-border
/// ps-1`), so they read as belonging to the row above.
///
/// The height follows the rows' natural height rather than a layout pass of
/// its own, so the menu settles at the size the rows actually are.
class _SubRows extends StatelessWidget {
  const _SubRows({
    required this.expand,
    required this.open,
    required this.children,
  });

  final Animation<double> expand;
  final bool open;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = ExcludeFocus(
      excluding: !open,
      child: IgnorePointer(
        ignoring: !open,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 16),
          // A container adds its border's width to the padding, as React
          // Native puts padding inside a border.
          child: Container(
            padding: const EdgeInsetsDirectional.only(start: 4),
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(color: PanelTheme.of(context).colors.border),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: _rowGap,
              children: children,
            ),
          ),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: expand,
      child: rows,
      builder: (context, child) {
        final t = expand.value;
        // Folded away, the rows are not built at all.
        if (t <= 0) return const SizedBox.shrink();
        return ClipRect(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: t,
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
        );
      },
    );
  }
}

/// A heading over a run of rows: small, medium, muted and uppercase.
class PanelMenuLabel extends StatelessWidget {
  /// Creates a heading.
  const PanelMenuLabel(this.text, {super.key, this.inset = false});

  /// The heading, shown uppercase.
  final String text;

  /// Line the text up with rows that have a glyph.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        inset ? _insetStart : 12,
        8,
        12,
        4,
      ),
      child: Semantics(
        header: true,
        label: text,
        excludeSemantics: true,
        child: Text(
          text.toUpperCase(),
          style: theme.typography
              .style(
                PanelTextSize.xs,
                weight: FontWeight.w500,
                color: theme.colors.mutedForeground,
              )
              // `tracking-wide`: 0.025em.
              .copyWith(letterSpacing: 0.3),
        ),
      ),
    );
  }
}

/// A hairline between two runs of menu rows.
class PanelMenuSeparator extends StatelessWidget {
  /// Creates a separator.
  const PanelMenuSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: PanelTheme.of(context).colors.border,
      ),
    );
  }
}

/// The tick of a checked row, or the tick or dot of a chosen radio row:
/// PanelUI's `CheckIcon` at 16, or its filled `CircleIcon` at 8, both at a
/// 2pt stroke in the `popover-foreground` token.
class _MenuIndicator extends StatelessWidget {
  const _MenuIndicator(this.kind);

  final PanelMenuRadioIndicator kind;

  @override
  Widget build(BuildContext context) {
    final color = PanelTheme.of(context).colors.popoverForeground;
    return switch (kind) {
      PanelMenuRadioIndicator.check => PanelIcon(
        PanelIcons.check,
        size: 16,
        strokeWidth: 2,
        color: color,
      ),
      // A filled circle rather than a round box, so the dot and the tick are
      // drawn the same way and read as the same size.
      PanelMenuRadioIndicator.dot => PanelIcon(
        PanelIcons.circle,
        size: 8,
        strokeWidth: 2,
        filled: true,
        color: color,
      ),
    };
  }
}

/// The shape every menu row shares.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.onPressed,
    required this.variant,
    required this.closeOnSelect,
    required this.role,
    this.leading,
    this.reserveLeading = false,
    this.description,
    this.shortcut,
    this.trailing,
    this.focusNode,
    this.checked,
    this.inMutuallyExclusiveGroup,
    this.expanded,
    this.semanticLabel,
  });

  final Widget label;
  final VoidCallback? onPressed;
  final PanelMenuItemVariant variant;
  final bool closeOnSelect;
  final SemanticsRole role;
  final Widget? leading;
  final bool reserveLeading;
  final String? description;
  final String? shortcut;
  final Widget? trailing;
  final FocusNode? focusNode;
  final bool? checked;
  final bool? inMutuallyExclusiveGroup;
  final bool? expanded;
  final String? semanticLabel;

  void _activate(BuildContext context) {
    if (_MenuScope._of(context)?.haptics ?? false) {
      HapticFeedback.selectionClick();
    }
    onPressed?.call();
    if (closeOnSelect) PanelPopover.maybeOf(context)?.close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final destructive = variant == PanelMenuItemVariant.destructive;
    final radius = BorderRadius.circular(theme.radii.xxl);
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : _disabledOpacity,
      child: PanelPressable(
        focusNode: focusNode,
        onPressed: enabled ? () => _activate(context) : null,
        pressScale: 1,
        semanticRole: role,
        checked: checked,
        inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
        expanded: expanded,
        semanticLabel: semanticLabel,
        // No ring: as in PanelUI's web menu, a focused row is lit instead.
        builder: (context, state) {
          final lit = state.hovered || state.focused;
          return _MenuRowFill(
            pressed: state.pressed,
            lit: lit,
            // A finger's press fades in PanelUI's native fill; the pointer
            // and keyboard highlight is its web package's.
            pressFill: destructive ? c.destructiveSubtle : c.accent,
            litFill: destructive
                ? c.destructive.withValues(alpha: c.destructive.a * 0.1)
                : c.accent,
            radius: radius,
            child: _MenuRowContent(
              label: label,
              leading: leading,
              reserveLeading: reserveLeading,
              description: description,
              shortcut: shortcut,
              trailing: trailing,
              labelColor: destructive
                  ? c.destructive
                  : (lit ? c.accentForeground : c.overlayForeground),
              lit: lit,
            ),
          );
        },
      ),
    );
  }
}

/// What a row shows: PanelUI's `px-2.5 py-2.5 gap-2.5` row of a leading
/// glyph, the label over its description, a shortcut and trailing content.
class _MenuRowContent extends StatelessWidget {
  const _MenuRowContent({
    required this.label,
    required this.leading,
    required this.reserveLeading,
    required this.description,
    required this.shortcut,
    required this.trailing,
    required this.labelColor,
    required this.lit,
  });

  final Widget label;
  final Widget? leading;
  final bool reserveLeading;
  final String? description;
  final String? shortcut;
  final Widget? trailing;
  final Color labelColor;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final leading = this.leading;
    final description = this.description;
    final shortcut = this.shortcut;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        leading == null && reserveLeading ? _insetStart : 10,
        10,
        10,
        10,
      ),
      child: Row(
        spacing: 10,
        children: [
          if (leading != null)
            SizedBox.square(
              dimension: _indicatorSize,
              child: Center(
                child: IconTheme.merge(
                  // A glyph is muted at rest (PanelUI's icons draw in a mid
                  // grey unless told otherwise) and takes the label's colour
                  // while the row is lit, as in the web package.
                  data: IconThemeData(
                    color: lit ? labelColor : c.mutedForeground,
                    size: 16,
                  ),
                  child: leading,
                ),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: theme.typography.style(
                    PanelTextSize.base,
                    weight: FontWeight.w500,
                    color: labelColor,
                  ),
                  child: label,
                ),
                if (description != null)
                  Text(
                    description,
                    style: theme.typography.style(
                      PanelTextSize.sm,
                      color: c.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          if (shortcut != null)
            Text(
              shortcut,
              style: theme.typography
                  .style(PanelTextSize.xs, color: c.mutedForeground)
                  // `tracking-widest`: 0.1em.
                  .copyWith(letterSpacing: 1.2),
            ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The pressed state of a row, animated rather than switched.
///
/// Swapping a fill in and out in one frame reads as a flash on a row this
/// size; this fades it in over 90ms and back out over 160ms, and carries a
/// slight shrink with it. A row lit by the pointer or the keyboard takes its
/// fill at once, as PanelUI's web menu highlights a row.
class _MenuRowFill extends StatefulWidget {
  const _MenuRowFill({
    required this.pressed,
    required this.lit,
    required this.pressFill,
    required this.litFill,
    required this.radius,
    required this.child,
  });

  final bool pressed;
  final bool lit;
  final Color pressFill;
  final Color litFill;
  final BorderRadius radius;
  final Widget child;

  @override
  State<_MenuRowFill> createState() => _MenuRowFillState();
}

class _MenuRowFillState extends State<_MenuRowFill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    value: widget.pressed ? 1 : 0,
  );

  @override
  void didUpdateWidget(_MenuRowFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pressed == oldWidget.pressed) return;
    if (panelReduceMotion(context)) {
      _press.value = widget.pressed ? 1 : 0;
    } else if (widget.pressed) {
      _press.animateTo(1, duration: _pressIn, curve: panelEase);
    } else {
      _press.animateBack(0, duration: _pressOut, curve: panelEase);
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _press,
      child: widget.child,
      builder: (context, child) {
        final t = _press.value;
        final Color? fill = widget.lit
            ? widget.litFill
            : (t == 0
                  ? null
                  : widget.pressFill.withValues(alpha: widget.pressFill.a * t));
        // Always in the tree, so a press does not rebuild the row under it.
        return Transform.scale(
          scale: 1 - (1 - _pressScale) * t,
          child: DecoratedBox(
            decoration: BoxDecoration(color: fill, borderRadius: widget.radius),
            child: child,
          ),
        );
      },
    );
  }
}
