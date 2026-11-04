import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/anchored_overlay.dart';
import '../foundation/panel_hit_slop.dart';
import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';
import 'bottom_sheet.dart';
import 'input.dart';

/// Where a [PanelSelect] shows its options. Which is right depends on what
/// surrounds the trigger rather than on what the options are.
enum PanelSelectPresentation {
  /// A bottom sheet. The default: best for a long list, or on a small screen
  /// where an anchored panel would cover the thing being chosen for.
  sheet,

  /// The list expands in the layout below the trigger, and everything below
  /// moves down. Right inside a settings list, where that reads as the row
  /// growing; wrong anywhere the shift is jarring.
  inline,

  /// The list floats over the page anchored to the trigger, and above it
  /// when there is no room below. Nothing else on the screen moves.
  ///
  /// It keeps to the safe area and clear of an open keyboard, where PanelUI
  /// measures the room against the whole window: a list under the home
  /// indicator or the keyboard is a list whose last rows cannot be pressed.
  overlay,
}

/// How big a [PanelSelect]'s trigger is: its height, padding, text and
/// chevron. The options it opens are one size, however compact the field.
///
/// PanelUI pads the trigger around one line of its text, inside a 1pt
/// border: `md` is `py-3.5` around `text-base`'s 24pt line, 14 + 24 + 14 + 2.
enum PanelSelectSize {
  /// 30pt tall, 13px text: `px-2.5 py-1.5`, `gap-2`, a 12pt chevron.
  xs(30, 10, 8, 13, 12),

  /// 42pt tall, 14px text: `px-3 py-2.5`, `gap-2`, a 14pt chevron.
  sm(42, 12, 8, 14, 14),

  /// 54pt tall, 16px text: `px-4 py-3.5`, `gap-3`, a 16pt chevron. The
  /// default.
  md(54, 16, 12, 16, 16),

  /// 62pt tall, 18px text: `px-4 py-4`, `gap-3`, an 18pt chevron.
  lg(62, 16, 12, 18, 18),

  /// 70pt tall, 18px text: `px-5 py-5`, `gap-3`, a 20pt chevron.
  xl(70, 20, 12, 18, 20);

  const PanelSelectSize(
    this.height,
    this.horizontalPadding,
    this.gap,
    this.fontSize,
    this.chevronSize,
  );

  /// The field's height, border included.
  final double height;

  /// The inset of the text and the chevron from the field's sides.
  final double horizontalPadding;

  /// The gap between the text and the chevron.
  final double gap;

  /// The size of the chosen label and the placeholder.
  final double fontSize;

  /// The size of the chevron.
  final double chevronSize;
}

/// One entry in a [PanelSelect]'s list: a [PanelSelectOption], a
/// [PanelSelectGroup] of options under a heading, or a [PanelSelectSeparator].
sealed class PanelSelectEntry<T> {
  const PanelSelectEntry();
}

/// A value the select can take, and the label it is shown by.
class PanelSelectOption<T> extends PanelSelectEntry<T> {
  /// Creates an option.
  const PanelSelectOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  /// The value [PanelSelect.onChanged] reports when this option is chosen.
  final T value;

  /// What the option and, once it is chosen, the trigger show. The filter
  /// of a searchable select matches on it.
  final String label;

  /// Whether the option can be chosen. A disabled option stays in the list,
  /// dimmed, because an option that vanishes reads as one that never existed.
  final bool enabled;
}

/// A titled run of options. Purely a way of arranging the list: the select
/// still reports one flat value, and a filter that empties the group drops
/// its heading with it.
class PanelSelectGroup<T> extends PanelSelectEntry<T> {
  /// Creates a group.
  const PanelSelectGroup({required this.options, this.label});

  /// The options in the group.
  final List<PanelSelectOption<T>> options;

  /// A heading over the options, announced as a header.
  final String? label;
}

/// A hairline between runs of options (PanelUI's web `Select.Separator`).
class PanelSelectSeparator<T> extends PanelSelectEntry<T> {
  /// Creates a separator.
  const PanelSelectSeparator();
}

/// PanelUI's options fade in over 140ms and out over 120ms, floating or in
/// place.
const AnchoredMotion _listMotion = AnchoredMotion(
  enter: Duration(milliseconds: 140),
  exit: Duration(milliseconds: 120),
);

/// The chevron turns over in 160ms as the options open and close.
const Duration _chevronDuration = Duration(milliseconds: 160);

/// What the `xs` trigger is short of a 44pt target, above and below. The
/// field is as wide as its container, so there is nothing to add at the
/// sides.
const EdgeInsets _xsHitSlop = EdgeInsets.symmetric(vertical: 7);

/// How tall a sheet's list grows before it scrolls, PanelUI's `max-h-96`,
/// when the sheet sizes itself to its options.
const double _sheetListMaxHeight = 384;

/// The opacity of a disabled option, PanelUI's `opacity-[0.64]`.
const double _disabledOptionOpacity = 0.64;

/// A field that opens a list of options, one of which is chosen.
///
/// The trigger is drawn like a [PanelInput] (outline and filled variants,
/// label, description and error), so a select in a form beside a text field
/// reads as the same family of control; its sizes are PanelUI's select's
/// own. A tick marks the chosen option. Where the options appear is
/// [presentation]: a bottom sheet by default, expanded in place, or floating
/// over the page.
///
/// ```dart
/// PanelSelect<String>(
///   label: 'Status',
///   value: status,
///   onChanged: (value) => setState(() => status = value),
///   options: const [
///     PanelSelectOption(value: 'draft', label: 'Draft'),
///     PanelSelectOption(value: 'review', label: 'In review'),
///     PanelSelectOption(value: 'shipped', label: 'Shipped', enabled: false),
///   ],
/// )
/// ```
///
/// Past a couple of dozen options, scrolling stops being a way of finding
/// anything: [searchable] puts a filter above the list, matching any part of
/// an option's label. It is not focused on open, which on a phone would throw
/// the keyboard over the list being looked at.
///
/// From the keyboard, Enter, Space or the arrow keys open it; the arrows,
/// Home and End move through the options, typing jumps to one by its first
/// letters, Enter chooses, and Escape closes it. A null [onChanged] disables
/// it.
class PanelSelect<T> extends StatefulWidget {
  /// Creates a select.
  const PanelSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Select an option',
    this.label,
    this.description,
    this.errorMessage,
    this.isInvalid = false,
    this.isRequired = false,
    this.variant = PanelInputVariant.outline,
    this.size = PanelSelectSize.md,
    this.presentation = PanelSelectPresentation.sheet,
    this.title,
    this.sheetSize = PanelBottomSheetSize.auto,
    this.searchable = false,
    this.searchPlaceholder = 'Search',
    this.emptyMessage = 'No matches',
    this.menuWidth,
    this.menuFitsContent = false,
    this.offset = 8,
    this.onOpenChange,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The options, optionally grouped and separated.
  final List<PanelSelectEntry<T>> options;

  /// The chosen value, or null to show [placeholder].
  final T? value;

  /// Called with the value of the option chosen. Null disables the select.
  final ValueChanged<T>? onChanged;

  /// Shown on the trigger while nothing is chosen.
  final String placeholder;

  /// The label above the field.
  final String? label;

  /// A muted line under the field.
  final String? description;

  /// An error under the field, replacing [description]. Setting it also
  /// marks the field invalid.
  final String? errorMessage;

  /// Draws the field in its error colours without a message.
  final bool isInvalid;

  /// Marks the label as required.
  final bool isRequired;

  /// Outline or filled, as on [PanelInput].
  final PanelInputVariant variant;

  /// The trigger's size. The options are one size whatever the trigger's.
  final PanelSelectSize size;

  /// Where the options appear: a sheet (the default), in place, or floating.
  final PanelSelectPresentation presentation;

  /// A heading over the options in the sheet. [PanelSelectPresentation.sheet]
  /// only.
  final String? title;

  /// How tall the sheet opens: sized to the options (the default), which
  /// scrolls once they pass 384pt, or a fixed half or nearly all of the
  /// screen, which the list fills. [PanelSelectPresentation.sheet] only.
  final PanelBottomSheetSize sheetSize;

  /// Puts a filter above the options, matching case-insensitively on any
  /// part of their labels. A group the filter empties is dropped, heading
  /// and all.
  final bool searchable;

  /// The filter's placeholder, which also names it for screen readers.
  final String searchPlaceholder;

  /// Shown in place of the list when the filter matches nothing.
  final String emptyMessage;

  /// A fixed width for the floating list. Null makes it as wide as the
  /// trigger, or with [menuFitsContent] as wide as its longest option.
  /// [PanelSelectPresentation.overlay] only.
  final double? menuWidth;

  /// Sizes the floating list to its longest option, never narrower than the
  /// trigger (PanelUI's `contentWidth="content"`).
  /// [PanelSelectPresentation.overlay] only.
  final bool menuFitsContent;

  /// The gap between the trigger and the floating list.
  /// [PanelSelectPresentation.overlay] only.
  final double offset;

  /// Called when the options open or close.
  final ValueChanged<bool>? onOpenChange;

  /// The trigger's focus node. One is created if null.
  final FocusNode? focusNode;

  /// Whether the trigger takes focus when first built.
  final bool autofocus;

  /// The accessible name, when there is no [label].
  final String? semanticLabel;

  @override
  State<PanelSelect<T>> createState() => _PanelSelectState<T>();
}

class _PanelSelectState<T> extends State<PanelSelect<T>>
    with SingleTickerProviderStateMixin {
  bool _open = false;

  /// Whether the trigger had keyboard focus when the options last opened.
  bool _openedFromKeyboard = false;

  late final AnimationController _chevron = AnimationController(
    vsync: this,
    duration: _chevronDuration,
  );
  late final Animation<double> _chevronTurns = _chevron.drive(
    Tween<double>(begin: 0, end: 0.5),
  );

  /// Has focus while the options do: the field's border answers to it, so it
  /// turns to the ring colour while the options are showing, as PanelUI's
  /// web select's does, and not merely because the trigger was last pressed.
  final FocusNode _optionsFocus = FocusNode(debugLabel: 'PanelSelect options');

  FocusNode? _ownTrigger;
  FocusNode get _trigger =>
      widget.focusNode ?? (_ownTrigger ??= FocusNode(debugLabel: 'Select'));

  late final PopupSheetPresenter _sheet = PopupSheetPresenter(
    onDismissed: () => _setOpen(false),
  );

  bool get _enabled => widget.onChanged != null;

  @override
  void didUpdateWidget(PanelSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _open) {
      _setOpen(false);
    } else {
      _syncSheet();
    }
  }

  @override
  void dispose() {
    _sheet.dispose();
    _chevron.dispose();
    _optionsFocus.dispose();
    _ownTrigger?.dispose();
    super.dispose();
  }

  void _setOpen(bool open) {
    if (open == _open) return;
    if (open) {
      _openedFromKeyboard =
          _trigger.hasFocus &&
          FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    } else if (widget.presentation == PanelSelectPresentation.inline &&
        _optionsFocus.hasFocus) {
      // The options are about to leave the layout; focus goes back to the
      // field rather than nowhere.
      _trigger.requestFocus();
    }
    setState(() => _open = open);
    if (panelReduceMotion(context)) {
      _chevron.value = open ? 1 : 0;
    } else if (open) {
      _chevron.animateTo(1, curve: panelEase);
    } else {
      _chevron.animateBack(0, curve: panelEase);
    }
    _syncSheet();
    widget.onOpenChange?.call(open);
  }

  void _toggle() => _setOpen(!_open);

  void _close() => _setOpen(false);

  void _choose(T value) {
    widget.onChanged?.call(value);
    _close();
  }

  /// Puts the sheet up, refreshes it or takes it down, to match the select.
  void _syncSheet() {
    _sheet.sync(
      context,
      open: widget.presentation == PanelSelectPresentation.sheet && _open,
      body: () => _options(PanelSelectPresentation.sheet),
      route: (builder) =>
          PanelBottomSheetRoute<void>(builder: builder, size: widget.sheetSize),
    );
  }

  KeyEventResult _handleTriggerKey(FocusNode node, KeyEvent event) {
    if (!_trigger.hasPrimaryFocus || !_enabled || _open) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.arrowUp)) {
      _setOpen(true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleInlineKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The options, wired to this select, laid out for [presentation].
  Widget _options(PanelSelectPresentation presentation) {
    Widget options = Focus(
      focusNode: _optionsFocus,
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      child: _SelectList<T>(
        entries: widget.options,
        value: widget.value,
        onChoose: _choose,
        presentation: presentation,
        searchable: widget.searchable,
        searchPlaceholder: widget.searchPlaceholder,
        emptyMessage: widget.emptyMessage,
        title: widget.title,
        sizedSheet: widget.sheetSize != PanelBottomSheetSize.auto,
        fitsContent: widget.menuFitsContent && widget.menuWidth == null,
        semanticLabel: widget.label ?? widget.semanticLabel,
      ),
    );
    // The floating list is told these by its overlay.
    if (presentation != PanelSelectPresentation.overlay) {
      options = AnchoredOverlayScope(
        openedFromKeyboard: _openedFromKeyboard,
        dismiss: _close,
        child: options,
      );
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    String? chosen;
    for (final option in _optionsIn(widget.options)) {
      if (option.value == widget.value) {
        chosen = option.label;
        break;
      }
    }

    Widget field = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _handleTriggerKey,
      child: _SelectTrigger(
        size: widget.size,
        text: chosen ?? widget.placeholder,
        isPlaceholder: chosen == null,
        open: _open,
        chevronTurns: _chevronTurns,
        focusNode: _trigger,
        autofocus: widget.autofocus,
        onPressed: _enabled ? _toggle : null,
        semanticLabel: widget.label ?? widget.semanticLabel,
      ),
    );
    if (widget.presentation == PanelSelectPresentation.overlay) {
      field = AnchoredOverlay(
        open: _open,
        onDismiss: _close,
        motion: _listMotion,
        // The trigger here is the field's inside; its border is 1pt out.
        anchorOutset: 1,
        position: AnchoredPosition(
          dropdown: true,
          // PanelUI's list keeps to the screen, not to a margin inside it.
          margin: 0,
          offset: widget.offset,
          width: widget.menuWidth,
          matchAnchorWidth: widget.menuWidth == null && !widget.menuFitsContent,
          atLeastAnchorWidth: widget.menuFitsContent,
        ),
        panel: _options(PanelSelectPresentation.overlay),
        child: field,
      );
    }
    // The frame draws the field's 1pt border around the trigger. In PanelUI
    // the border belongs to the pressable, so a press on it counts.
    field = PanelHitSlop(slop: const EdgeInsets.all(1), child: field);

    Widget select = PanelFieldFrame(
      focusNode: _optionsFocus,
      label: widget.label,
      description: widget.description,
      errorMessage: widget.errorMessage,
      isInvalid: widget.isInvalid,
      isRequired: widget.isRequired,
      enabled: _enabled,
      variant: widget.variant,
      height: widget.size.height,
      child: field,
    );
    if (widget.size == PanelSelectSize.xs) {
      select = PanelHitSlop(slop: _xsHitSlop, child: select);
    }
    if (widget.presentation == PanelSelectPresentation.inline) {
      select = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          select,
          _InlineOptions(
            open: _open,
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              includeSemantics: false,
              onKeyEvent: _handleInlineKey,
              child: _options(PanelSelectPresentation.inline),
            ),
          ),
        ],
      );
    }
    return select;
  }
}

/// Every option in [entries], in order, out of their groups.
Iterable<PanelSelectOption<T>> _optionsIn<T>(
  List<PanelSelectEntry<T>> entries,
) sync* {
  for (final entry in entries) {
    switch (entry) {
      case PanelSelectOption<T>():
        yield entry;
      case PanelSelectGroup<T>(:final options):
        yield* options;
      case PanelSelectSeparator<T>():
        break;
    }
  }
}

/// The field's inside: the chosen label or the placeholder, and a chevron
/// that turns over while the options are showing.
///
/// PanelUI's trigger is a plain pressable, so it does not shrink when
/// pressed. Its hover tint and focus ring are PanelUI's web select's.
class _SelectTrigger extends StatelessWidget {
  const _SelectTrigger({
    required this.size,
    required this.text,
    required this.isPlaceholder,
    required this.open,
    required this.chevronTurns,
    required this.focusNode,
    required this.autofocus,
    required this.onPressed,
    required this.semanticLabel,
  });

  final PanelSelectSize size;
  final String text;
  final bool isPlaceholder;
  final bool open;
  final Animation<double> chevronTurns;
  final FocusNode focusNode;
  final bool autofocus;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    // The field's radius, less the border this sits inside.
    final radius = BorderRadius.circular(math.max(0, theme.radii.lg - 1));
    final style = isPlaceholder
        ? theme.typography.sized(size.fontSize, color: c.mutedForeground)
        : theme.typography.sized(
            size.fontSize,
            weight: FontWeight.w500,
            color: c.foreground,
          );

    return PanelPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      pressScale: 1,
      // Announced as the field's name, its value and whether it is open.
      semanticLabel: semanticLabel,
      semanticValue: text,
      expanded: open,
      // `focus-visible:ring-[3px] focus-visible:ring-ring/30`.
      focusRingRadius: radius,
      focusRingColor: c.ring.withValues(alpha: c.ring.a * 0.3),
      builder: (context, state) => AnimatedContainer(
        // `hover:bg-accent/40`, eased over Tailwind's default 150ms
        // `cubic-bezier(0.4, 0, 0.2, 1)`.
        duration: const Duration(milliseconds: 150),
        curve: Curves.fastOutSlowIn,
        padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
        decoration: BoxDecoration(
          borderRadius: radius,
          color: state.hovered && !open
              ? c.accent.withValues(alpha: c.accent.a * 0.4)
              : null,
        ),
        child: Row(
          spacing: size.gap,
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  text,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            RotationTransition(
              turns: chevronTurns,
              child: PanelIcon(
                PanelIcons.chevronDown,
                size: size.chevronSize,
                color: c.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The options, laid out for one presentation, with the search field above
/// them when the select is searchable. It owns the filter's text, which goes
/// with it when the options close, so a select reopens unfiltered.
class _SelectList<T> extends StatefulWidget {
  const _SelectList({
    required this.entries,
    required this.value,
    required this.onChoose,
    required this.presentation,
    required this.searchable,
    required this.searchPlaceholder,
    required this.emptyMessage,
    required this.title,
    required this.sizedSheet,
    required this.fitsContent,
    required this.semanticLabel,
  });

  final List<PanelSelectEntry<T>> entries;
  final T? value;
  final ValueChanged<T> onChoose;
  final PanelSelectPresentation presentation;
  final bool searchable;
  final String searchPlaceholder;
  final String emptyMessage;
  final String? title;
  final bool sizedSheet;
  final bool fitsContent;
  final String? semanticLabel;

  @override
  State<_SelectList<T>> createState() => _SelectListState<T>();
}

class _SelectListState<T> extends State<_SelectList<T>> {
  final TextEditingController _query = TextEditingController();
  final TypeAheadBuffer _typeAhead = TypeAheadBuffer();

  /// One per option, by its place among all the options, so a row keeps its
  /// node (and its focus) while the filter hides the others.
  final List<FocusNode> _nodes = [];

  @override
  void dispose() {
    _query.dispose();
    _typeAhead.dispose();
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _node(int index) {
    while (_nodes.length <= index) {
      _nodes.add(FocusNode(debugLabel: 'Select option ${_nodes.length}'));
    }
    return _nodes[index];
  }

  /// What the filter matches against: the query, trimmed and lower-cased.
  String get _needle => _query.text.trim().toLowerCase();

  bool _shows(PanelSelectOption<T> option, String needle) =>
      needle.isEmpty || option.label.toLowerCase().contains(needle);

  /// Opened from the keyboard, focus starts on the chosen option.
  FocusNode? _initialFocus() {
    var index = 0;
    for (final option in _optionsIn(widget.entries)) {
      if (option.enabled && option.value == widget.value) return _node(index);
      index++;
    }
    return null;
  }

  bool _handleTypeAhead(String character) {
    final needle = _needle;
    final shown = <(int, PanelSelectOption<T>)>[];
    var index = 0;
    for (final option in _optionsIn(widget.entries)) {
      if (_shows(option, needle)) shown.add((index, option));
      index++;
    }
    final found = _typeAhead.find(
      character,
      [for (final (_, option) in shown) option.label],
      current: shown.indexWhere((entry) => _node(entry.$1).hasPrimaryFocus),
      enabled: (i) => shown[i].$2.enabled,
    );
    if (found == null) return false;
    FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
      _node(shown[found].$1),
      alignment: 0.5,
    );
    return true;
  }

  /// The rows the filter leaves, groups rebuilt around what survives in them
  /// and dropped when that is nothing, and how many options that is.
  (List<Widget>, int) _rows(String needle) {
    final rows = <Widget>[];
    var index = 0;
    var shown = 0;
    Widget? row(PanelSelectOption<T> option) {
      final i = index++;
      if (!_shows(option, needle)) return null;
      shown++;
      return _SelectOptionRow(
        key: ValueKey<int>(i),
        label: option.label,
        selected: option.value == widget.value,
        focusNode: _node(i),
        onPressed: option.enabled ? () => widget.onChoose(option.value) : null,
      );
    }

    for (final entry in widget.entries) {
      switch (entry) {
        case PanelSelectOption<T>():
          final option = row(entry);
          if (option != null) rows.add(option);
        case PanelSelectGroup<T>(:final options, :final label):
          final kept = [for (final option in options) ?row(option)];
          if (kept.isNotEmpty) rows.add(_SelectGroup(label: label, rows: kept));
        case PanelSelectSeparator<T>():
          rows.add(const _SelectSeparator());
      }
    }
    return (rows, shown);
  }

  @override
  Widget build(BuildContext context) {
    final needle = _needle;
    final (rows, shown) = _rows(needle);
    final presentation = widget.presentation;

    Widget list;
    if (shown == 0 && needle.isNotEmpty) {
      list = _SelectEmpty(widget.emptyMessage);
    } else {
      list = PopupListNavigation(
        initialFocus: _initialFocus,
        // Tab leaves a floating list, as it leaves a menu.
        onTab: presentation == PanelSelectPresentation.overlay
            ? AnchoredOverlayScope.maybeOf(context)?.dismiss
            : null,
        onTypeAhead: _handleTypeAhead,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // A sheet spaces its options `gap-1`; a list box does not.
          spacing: presentation == PanelSelectPresentation.sheet ? 4 : 0,
          children: rows,
        ),
      );
      if (shown > 0) {
        list = Semantics(
          role: SemanticsRole.menu,
          explicitChildNodes: true,
          child: list,
        );
      }
    }

    final search = widget.searchable
        ? _SelectSearch(
            controller: _query,
            placeholder: widget.searchPlaceholder,
            onChanged: (_) => setState(() {}),
          )
        : null;

    return switch (presentation) {
      PanelSelectPresentation.overlay => _floating(search, list),
      PanelSelectPresentation.inline => _SelectListBox(
        floating: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [?search, list],
        ),
      ),
      PanelSelectPresentation.sheet => _inSheet(search, list),
    };
  }

  /// The floating list: the search field stays put above a scroller that
  /// takes whatever height the overlay leaves.
  Widget _floating(Widget? search, Widget list) {
    Widget box = _SelectListBox(
      floating: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?search,
          Flexible(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false, overscroll: false),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: list,
              ),
            ),
          ),
        ],
      ),
    );
    // Sized to its longest option, the box needs that option's width before
    // the stretched column can lay the others out to it.
    if (widget.fitsContent) box = IntrinsicWidth(child: box);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: widget.semanticLabel != null,
      label: widget.semanticLabel,
      child: box,
    );
  }

  /// The sheet's body: a title, the search field and the options, which
  /// scroll in the sheet's own scroller so a pull at their top drags the
  /// sheet. A sheet sized to its options stops them at 384pt.
  Widget _inSheet(Widget? search, Widget list) {
    final theme = PanelTheme.of(context);
    final title = widget.title;
    Widget body = PanelBottomSheetBody(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      children: [list],
    );
    if (!widget.sizedSheet) {
      body = Flexible(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _sheetListMaxHeight),
          child: Column(mainAxisSize: MainAxisSize.min, children: [body]),
        ),
      );
    }
    return Semantics(
      namesRoute: title == null && widget.semanticLabel != null,
      label: title == null ? widget.semanticLabel : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Semantics(
                header: true,
                namesRoute: true,
                child: Text(
                  title,
                  style: theme.typography.style(
                    PanelTextSize.lg,
                    weight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
              ),
            ),
          if (search != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: search,
            ),
          body,
        ],
      ),
    );
  }
}

/// The surface the options sit on, floating or in place: PanelUI's
/// `rounded-xl border border-border bg-popover p-2`, with `shadow-lg` over
/// the page and `shadow-sm` in it.
class _SelectListBox extends StatelessWidget {
  const _SelectListBox({required this.floating, required this.child});

  final bool floating;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    return Container(
      padding: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.popover,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(theme.radii.xl),
        boxShadow: floating ? theme.shadows.lg : theme.shadows.sm,
      ),
      child: child,
    );
  }
}

/// The filter above the options: PanelUI's filled small input with an 18pt
/// magnifier, `pb-2` above the list.
class _SelectSearch extends StatelessWidget {
  const _SelectSearch({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PanelInput(
        controller: controller,
        variant: PanelInputVariant.filled,
        size: PanelInputSize.sm,
        placeholder: placeholder,
        leading: PanelIcon(
          PanelIcons.search,
          size: 18,
          color: PanelTheme.of(context).colors.mutedForeground,
        ),
        autocorrect: false,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
      ),
    );
  }
}

/// What stands in for the list when the filter matches nothing: PanelUI's
/// `px-3 py-6 text-center text-sm text-muted-foreground`.
class _SelectEmpty extends StatelessWidget {
  const _SelectEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.typography.style(
          PanelTextSize.sm,
          color: theme.colors.mutedForeground,
        ),
      ),
    );
  }
}

/// One option in the list: its label and, when chosen, a tick.
///
/// PanelUI's option is a plain pressable with no press state; the chosen one
/// sits on the accent fill. A row under the pointer or the keyboard is lit
/// as PanelUI's web select lights one, in the accent and its foreground.
class _SelectOptionRow extends StatelessWidget {
  const _SelectOptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.focusNode,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final radius = BorderRadius.circular(theme.radii.lg);
    return Opacity(
      opacity: onPressed == null ? _disabledOptionOpacity : 1,
      child: PanelPressable(
        focusNode: focusNode,
        onPressed: onPressed,
        pressScale: 1,
        selected: selected,
        semanticRole: SemanticsRole.menuItem,
        builder: (context, state) {
          final lit = state.hovered || state.focused;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected || lit ? c.accent : null,
              borderRadius: radius,
            ),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.typography.style(
                      PanelTextSize.base,
                      weight: FontWeight.w500,
                      color: lit ? c.accentForeground : c.foreground,
                    ),
                  ),
                ),
                SizedBox.square(
                  dimension: 20,
                  child: selected
                      ? Center(
                          child: PanelIcon(
                            PanelIcons.check,
                            size: 16,
                            color: c.mutedForeground,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A titled run of option rows, `gap-1` apart under the heading.
class _SelectGroup extends StatelessWidget {
  const _SelectGroup({required this.label, required this.rows});

  final String? label;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [if (label != null) _SelectGroupLabel(label), ...rows],
    );
  }
}

/// A group's heading: PanelUI's `px-3 pb-1 pt-2` around small, medium,
/// muted, uppercase text, announced as a header in its own case.
class _SelectGroupLabel extends StatelessWidget {
  const _SelectGroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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

/// A hairline between runs of options: the web select's `mx-2 my-1 h-px
/// bg-border`.
class _SelectSeparator extends StatelessWidget {
  const _SelectSeparator();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: PanelTheme.of(context).colors.border,
      ),
    );
  }
}

/// The options expanded in place, `mt-2` below the trigger.
///
/// They fade in over 140ms, taking their room at once. Closing, the layout
/// closes up at once too, and the list fades out over 120ms on top of what
/// moved up under it: what PanelUI's exit animation does to a view that has
/// already left the layout.
class _InlineOptions extends StatefulWidget {
  const _InlineOptions({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  State<_InlineOptions> createState() => _InlineOptionsState();
}

class _InlineOptionsState extends State<_InlineOptions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: widget.open ? 1 : 0,
  )..addStatusListener(_handleStatus);

  @override
  void didUpdateWidget(_InlineOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;
    if (panelReduceMotion(context)) {
      _fade.value = widget.open ? 1 : 0;
    } else if (widget.open) {
      _fade.animateTo(1, duration: _listMotion.enter, curve: panelEase);
    } else {
      _fade.animateBack(0, duration: _listMotion.exit, curve: panelEase);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  /// Drops the list once it has faded out.
  void _handleStatus(AnimationStatus status) {
    if (status.isDismissed && !widget.open) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.open;
    if (!open && _fade.isDismissed) return const SizedBox.shrink();
    return _TakesRoom(
      takesRoom: open,
      child: ExcludeFocus(
        excluding: !open,
        child: IgnorePointer(
          ignoring: !open,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FadeTransition(opacity: _fade, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Lays its child out at its natural size, and takes that much room in the
/// layout only while [takesRoom]; otherwise it takes none and draws the
/// child over whatever follows. Never hit: what does not take room is on
/// its way out.
class _TakesRoom extends SingleChildRenderObjectWidget {
  const _TakesRoom({required this.takesRoom, required super.child});

  final bool takesRoom;

  @override
  _RenderTakesRoom createRenderObject(BuildContext context) =>
      _RenderTakesRoom(takesRoom);

  @override
  void updateRenderObject(BuildContext context, _RenderTakesRoom renderObject) {
    renderObject.takesRoom = takesRoom;
  }
}

class _RenderTakesRoom extends RenderProxyBox {
  _RenderTakesRoom(this._takesRoom);

  bool get takesRoom => _takesRoom;
  bool _takesRoom;
  set takesRoom(bool value) {
    if (value == _takesRoom) return;
    _takesRoom = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints, parentUsesSize: true);
    size = _takesRoom
        ? child.size
        : constraints.constrain(Size(child.size.width, 0));
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      _takesRoom && super.hitTest(result, position: position);
}
