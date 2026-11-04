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

  /// A row for an action that removes something: red text, a red icon and a
  /// red-tinted press, so it is not read past at a glance.
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
/// options. Its surface is the `overlay` token, drawn as a layer behind the
/// rows that [background] can replace.
///
/// A row runs its action and closes the menu. Arrow keys, Home and End move
/// between rows, Enter or Space runs one, and Escape or Tab closes the menu.
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
    this.semanticLabel,
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

  /// The preferred side of the trigger.
  final PanelPopoverPlacement placement;

  /// Where the panel lines up along the trigger's other axis.
  final PanelPopoverAlign align;

  /// The gap between the trigger and the panel.
  final double offset;

  /// A nudge along the alignment axis.
  final double alignOffset;

  /// A fixed width. Null sizes the menu to its widest row.
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
  final Widget? background;

  /// Ticks the haptic engine as a row is chosen.
  final bool haptics;

  /// Whether a tap outside, Escape and the back gesture close the menu.
  final bool dismissible;

  /// Dims the screen behind the menu.
  final bool scrim;

  /// Announced as the menu's name when it opens.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return PanelPopover(
      builder: builder,
      controller: controller,
      isOpen: isOpen,
      onOpenChange: onOpenChange,
      initiallyOpen: initiallyOpen,
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
      semanticLabel: semanticLabel,
      unstyled: true,
      children: [
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

/// The menu's own surface: a rounded `overlay` layer behind a column of rows,
/// 6pt in from its edge so a pressed row's fill reads as part of the panel.
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

    // The rows are 6pt apart inside the scroller and 2pt apart without one,
    // which is how PanelUI's menu lays them out (the scroller's content view
    // carries the popover's `gap-1.5`, the bare panel the menu's `gap-0.5`).
    Widget rows = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: scrollable ? 6 : 2,
      children: children,
    );
    rows = ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false, overscroll: false),
      child: SingleChildScrollView(
        physics: scrollable
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: rows,
      ),
    );
    rows = PopupListNavigation(
      onTab: () => PanelPopover.maybeOf(context)?.close(),
      child: rows,
    );
    if (children.isNotEmpty) {
      rows = Semantics(
        role: SemanticsRole.menu,
        explicitChildNodes: true,
        child: rows,
      );
    }
    rows = _MenuScope(haptics: haptics, child: rows);

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
            Padding(padding: const EdgeInsets.all(6), child: rows),
          ],
        ),
      ),
    );
  }
}

class _MenuScope extends InheritedWidget {
  const _MenuScope({required this.haptics, required super.child});

  final bool haptics;

  static bool hapticsOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_MenuScope>()?.haptics ?? false;

  @override
  bool updateShouldNotify(_MenuScope oldWidget) => haptics != oldWidget.haptics;
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
  /// in the muted colour (red on a destructive row).
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
      destructive: variant == PanelMenuItemVariant.destructive,
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
      leading: value ? const _MenuCheck() : const SizedBox.shrink(),
      description: description,
      shortcut: shortcut,
      trailing: trailing,
      destructive: variant == PanelMenuItemVariant.destructive,
      closeOnSelect: closeOnSelect,
      role: SemanticsRole.menuItemCheckbox,
      checked: value,
      semanticLabel: semanticLabel,
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

  /// The items.
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
      leading: selected
          ? (indicator == PanelMenuRadioIndicator.dot
                ? const _MenuDot()
                : const _MenuCheck())
          : const SizedBox.shrink(),
      description: description,
      shortcut: shortcut,
      trailing: trailing,
      destructive: false,
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

  // PanelUI turns the chevron over 180ms and opens the rows over 200ms.
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
    _animate();
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
    final theme = PanelTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final open = _open;

    final chevron = AnimatedBuilder(
      animation: _chevron,
      builder: (context, child) => Transform.rotate(
        // A quarter turn takes the chevron from along the line of text to
        // pointing down into the rows; under RTL it starts the other way.
        angle: _chevron.value * (rtl ? -1 : 1) * 1.5707963267948966,
        child: child,
      ),
      child: PanelIcon(
        PanelIcons.chevronRight,
        size: 16,
        color: theme.colors.mutedForeground,
      ),
    );

    final rows = AnimatedBuilder(
      animation: _expand,
      builder: (context, child) {
        final t = _expand.value;
        if (t <= 0) return const SizedBox.shrink();
        return ClipRect(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: t,
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
        );
      },
      child: ExcludeFocus(
        excluding: !open,
        child: IgnorePointer(
          ignoring: !open,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, top: 6),
            child: Container(
              padding: const EdgeInsetsDirectional.only(start: 4),
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: theme.colors.border),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: widget.children,
              ),
            ),
          ),
        ),
      ),
    );

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
            trailing: chevron,
            destructive: false,
            closeOnSelect: false,
            role: SemanticsRole.menuItem,
            expanded: open,
          ),
          rows,
        ],
      ),
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

class _MenuCheck extends StatelessWidget {
  const _MenuCheck();

  @override
  Widget build(BuildContext context) => PanelIcon(
    PanelIcons.check,
    size: 16,
    strokeWidth: 2,
    color: PanelTheme.of(context).colors.popoverForeground,
  );
}

class _MenuDot extends StatelessWidget {
  const _MenuDot();

  @override
  Widget build(BuildContext context) {
    // The size of PanelUI's filled CircleIcon at 8: its r=10 circle in a 24
    // box, plus the stroke, is a 7⅓pt dot.
    return Container(
      width: 22 / 3,
      height: 22 / 3,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PanelTheme.of(context).colors.popoverForeground,
      ),
    );
  }
}

/// The shape every menu row shares.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.onPressed,
    required this.destructive,
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
  final bool destructive;
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
    if (_MenuScope.hapticsOf(context)) HapticFeedback.selectionClick();
    onPressed?.call();
    if (closeOnSelect) PanelPopover.maybeOf(context)?.close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final enabled = onPressed != null;
    final labelColor = destructive ? c.destructive : c.overlayForeground;
    final iconColor = destructive ? c.destructive : c.mutedForeground;
    final muted = theme.typography.style(
      PanelTextSize.sm,
      color: c.mutedForeground,
    );

    final content = Padding(
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
                  data: IconThemeData(color: iconColor, size: 16),
                  child: leading!,
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
                if (description != null) Text(description!, style: muted),
              ],
            ),
          ),
          if (shortcut != null)
            Text(
              shortcut!,
              style: theme.typography
                  .style(PanelTextSize.xs, color: c.mutedForeground)
                  .copyWith(letterSpacing: 1.2),
            ),
          ?trailing,
        ],
      ),
    );

    final radius = BorderRadius.circular(theme.radii.xxl);
    final fill = destructive ? c.destructiveSubtle : c.accent;
    Widget row = PanelPressable(
      focusNode: focusNode,
      onPressed: enabled ? () => _activate(context) : null,
      pressScale: 1,
      checked: checked,
      inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
      semanticLabel: semanticLabel,
      // No ring: as in PanelUI's web menu, a focused row is lit instead.
      builder: (context, state) => _MenuRowFill(
        pressed: state.pressed,
        highlighted: state.hovered || state.focused,
        fill: fill,
        radius: radius,
        child: content,
      ),
    );
    row = MergeSemantics(
      child: Semantics(role: role, expanded: expanded, child: row),
    );
    return Opacity(opacity: enabled ? 1 : 0.45, child: row);
  }
}

/// The pressed state of a row, animated rather than switched.
///
/// Swapping a fill in and out in one frame reads as a flash on a row this
/// size; this fades it in over 90ms and back out over 160ms, and carries a
/// slight shrink with it. A hovered or keyboard-focused row is lit at once,
/// as PanelUI's web menu highlights a row.
class _MenuRowFill extends StatefulWidget {
  const _MenuRowFill({
    required this.pressed,
    required this.highlighted,
    required this.fill,
    required this.radius,
    required this.child,
  });

  final bool pressed;
  final bool highlighted;
  final Color fill;
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
        final fill = widget.highlighted ? 1.0 : t.clamp(0.0, 1.0);
        Widget row = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.radius,
            color: fill == 0
                ? null
                : widget.fill.withValues(alpha: widget.fill.a * fill),
          ),
          child: child,
        );
        if (t != 0) {
          row = Transform.scale(scale: 1 - (1 - _pressScale) * t, child: row);
        }
        return row;
      },
    );
  }
}
