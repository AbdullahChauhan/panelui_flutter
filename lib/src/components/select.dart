import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/anchored_overlay.dart';
import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_theme_data.dart';
import '../theme/panel_typography.dart';
import 'input.dart';

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

  /// What the option and, once it is chosen, the trigger show.
  final String label;

  /// Whether the option can be chosen. A disabled option stays in the list,
  /// dimmed, because an option that vanishes reads as one that never existed.
  final bool enabled;
}

/// A titled run of options. Purely a way of arranging the list: the select
/// still reports one flat value.
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

/// What the trigger's size changes, from PanelUI's Select: its padding, the
/// gap before the chevron, the text and the chevron. Heights come from
/// [PanelInputSize], so a select lines up with a text field of the same size.
class _SelectMetrics {
  const _SelectMetrics(this.padding, this.gap, this.fontSize, this.chevron);

  final double padding;
  final double gap;
  final double fontSize;
  final double chevron;
}

const Map<PanelInputSize, _SelectMetrics> _selectMetrics = {
  PanelInputSize.xs: _SelectMetrics(10, 8, 13, 12),
  PanelInputSize.sm: _SelectMetrics(12, 8, 14, 14),
  PanelInputSize.md: _SelectMetrics(16, 12, 16, 16),
  PanelInputSize.lg: _SelectMetrics(16, 12, 18, 18),
  PanelInputSize.xl: _SelectMetrics(20, 12, 18, 20),
};

/// PanelUI's floating list: a 140ms fade in and a 120ms fade out.
const AnchoredMotion _selectMotion = AnchoredMotion(
  enter: Duration(milliseconds: 140),
  exit: Duration(milliseconds: 120),
);

/// The chevron turns over in 160ms as the list opens and closes.
const Duration _chevronDuration = Duration(milliseconds: 160);

/// A field that opens a list of options, one of which is chosen.
///
/// The trigger is drawn like a [PanelInput] (the same sizes, outline and
/// filled variants, label, description and error), so a select in a form
/// beside a text field reads as the same family of control. The list floats
/// over the page anchored to the trigger, as wide as it, below it, and above
/// it only when there is not room for a short list below; a long list
/// scrolls. A tick marks the chosen option.
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
/// From the keyboard, Enter, Space or the arrow keys open it; the arrows,
/// Home and End move through the options, typing jumps to one by its first
/// letters, Enter chooses, and Escape or Tab closes it. A null [onChanged]
/// disables it.
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
    this.size = PanelInputSize.md,
    this.menuWidth,
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

  /// The trigger's size. The options in the list are one size whatever the
  /// trigger's.
  final PanelInputSize size;

  /// A fixed width for the list. Null makes it as wide as the trigger.
  final double? menuWidth;

  /// The gap between the trigger and the list.
  final double offset;

  /// Called when the list opens or closes.
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
  late final AnimationController _chevron = AnimationController(
    vsync: this,
    duration: _chevronDuration,
  );
  late final Animation<double> _chevronTurns = Tween<double>(
    begin: 0,
    end: 0.5,
  ).animate(_chevron);

  /// Holds focus while it is anywhere in the trigger or the list, which is
  /// what the field's border answers to.
  final FocusNode _group = FocusNode(
    debugLabel: 'PanelSelect',
    canRequestFocus: false,
    skipTraversal: true,
  );
  FocusNode? _ownTrigger;
  FocusNode get _trigger =>
      widget.focusNode ?? (_ownTrigger ??= FocusNode(debugLabel: 'Select'));

  final List<FocusNode> _optionNodes = [];
  final TypeAheadBuffer _typeAhead = TypeAheadBuffer();

  List<PanelSelectOption<T>> get _flatOptions => [
    for (final entry in widget.options)
      ...switch (entry) {
        PanelSelectOption<T>() => [entry],
        PanelSelectGroup<T>(:final options) => options,
        PanelSelectSeparator<T>() => const [],
      },
  ];

  bool get _enabled => widget.onChanged != null;

  @override
  void didUpdateWidget(PanelSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _open) _setOpen(false);
  }

  @override
  void dispose() {
    _chevron.dispose();
    _group.dispose();
    _ownTrigger?.dispose();
    for (final node in _optionNodes) {
      node.dispose();
    }
    _typeAhead.dispose();
    super.dispose();
  }

  FocusNode _optionNode(int index) {
    while (_optionNodes.length <= index) {
      _optionNodes.add(
        FocusNode(debugLabel: 'Select option ${_optionNodes.length}'),
      );
    }
    return _optionNodes[index];
  }

  void _setOpen(bool value) {
    if (value == _open) return;
    setState(() => _open = value);
    if (panelReduceMotion(context)) {
      _chevron.value = value ? 1 : 0;
    } else if (value) {
      _chevron.animateTo(1, curve: panelEase);
    } else {
      _chevron.animateBack(0, curve: panelEase);
    }
    // A prefix left behind would be waiting the next time the list opens.
    if (!value) _typeAhead.clear();
    widget.onOpenChange?.call(value);
  }

  void _toggle() => _setOpen(!_open);

  void _choose(T value) {
    widget.onChanged?.call(value);
    _setOpen(false);
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

  FocusNode? _initialFocus() {
    final options = _flatOptions;
    for (var i = 0; i < options.length; i++) {
      if (options[i].enabled && options[i].value == widget.value) {
        return _optionNode(i);
      }
    }
    return null;
  }

  bool _handleTypeAhead(String character) {
    final options = _flatOptions;
    final current = _optionNodes.indexWhere((node) => node.hasPrimaryFocus);
    final index = _typeAhead.find(
      character,
      [for (final option in options) option.label],
      current: current,
      enabled: (i) => options[i].enabled,
    );
    if (index == null) return false;
    FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
      _optionNode(index),
      alignment: 0.5,
    );
    return true;
  }

  Widget _buildList(PanelThemeData theme) {
    final c = theme.colors;
    final rows = <Widget>[];
    var index = 0;

    Widget option(PanelSelectOption<T> option) {
      final i = index++;
      return _SelectOptionRow(
        key: ValueKey<int>(i),
        label: option.label,
        selected: option.value == widget.value,
        focusNode: _optionNode(i),
        onPressed: option.enabled ? () => _choose(option.value) : null,
      );
    }

    for (final entry in widget.options) {
      switch (entry) {
        case PanelSelectOption<T>():
          rows.add(option(entry));
        case PanelSelectGroup<T>(:final options, :final label):
          rows.add(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                if (label != null) _SelectGroupLabel(label),
                for (final o in options) option(o),
              ],
            ),
          );
        case PanelSelectSeparator<T>():
          rows.add(
            ExcludeSemantics(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: c.border,
              ),
            ),
          );
      }
    }

    Widget list = ScrollConfiguration(
      behavior: ScrollConfiguration.of(
        context,
      ).copyWith(scrollbars: false, overscroll: false),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
    list = PopupListNavigation(
      initialFocus: _initialFocus,
      onTab: () => _setOpen(false),
      onTypeAhead: _handleTypeAhead,
      child: list,
    );
    if (index > 0) {
      list = Semantics(
        role: SemanticsRole.menu,
        explicitChildNodes: true,
        child: list,
      );
    }
    final name = widget.label ?? widget.semanticLabel;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: name != null,
      label: name,
      child: Container(
        padding: const EdgeInsets.all(8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.popover,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(theme.radii.xl),
          boxShadow: theme.shadows.lg,
        ),
        child: list,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final metrics = _selectMetrics[widget.size]!;
    final enabled = _enabled;

    PanelSelectOption<T>? chosen;
    for (final option in _flatOptions) {
      if (option.value == widget.value) {
        chosen = option;
        break;
      }
    }
    final text = chosen?.label ?? widget.placeholder;
    final textStyle = chosen == null
        ? theme.typography.sized(metrics.fontSize, color: c.mutedForeground)
        : theme.typography.sized(
            metrics.fontSize,
            weight: FontWeight.w500,
            color: c.foreground,
          );
    final innerRadius = BorderRadius.circular(
      (theme.radii.lg - 1).clamp(0.0, double.infinity),
    );

    Widget trigger = PanelPressable(
      focusNode: _trigger,
      autofocus: widget.autofocus,
      onPressed: enabled ? _toggle : null,
      pressScale: 1,
      semanticLabel: widget.label ?? widget.semanticLabel,
      // PanelUI's web select: `focus-visible:ring-[3px] ring-ring/30`.
      focusRingRadius: innerRadius,
      focusRingColor: c.ring.withValues(alpha: c.ring.a * 0.3),
      builder: (context, state) {
        // PanelUI's web select tints the field on hover.
        final hover = state.hovered && !_open;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: metrics.padding),
          decoration: BoxDecoration(
            borderRadius: innerRadius,
            color: hover ? c.accent.withValues(alpha: c.accent.a * 0.4) : null,
          ),
          child: Row(
            spacing: metrics.gap,
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    text,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              RotationTransition(
                turns: _chevronTurns,
                child: PanelIcon(
                  PanelIcons.chevronDown,
                  size: metrics.chevron,
                  color: c.mutedForeground,
                ),
              ),
            ],
          ),
        );
      },
    );
    // Announced as the field's name, its value and whether the list is open.
    trigger = MergeSemantics(
      child: Semantics(value: text, expanded: _open, child: trigger),
    );

    return Focus(
      focusNode: _group,
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _handleTriggerKey,
      child: PanelFieldFrame(
        focusNode: _group,
        label: widget.label,
        description: widget.description,
        errorMessage: widget.errorMessage,
        isInvalid: widget.isInvalid,
        isRequired: widget.isRequired,
        enabled: enabled,
        variant: widget.variant,
        height: widget.size.height,
        child: AnchoredOverlay(
          open: _open,
          onDismiss: () => _setOpen(false),
          motion: _selectMotion,
          // The trigger here is the field's inside; its border is 1pt out.
          anchorOutset: 1,
          position: AnchoredPosition(
            dropdown: true,
            margin: 0,
            offset: widget.offset,
            width: widget.menuWidth,
            matchAnchorWidth: widget.menuWidth == null,
          ),
          panel: _buildList(theme),
          child: trigger,
        ),
      ),
    );
  }
}

/// One option in the list: its label and, when chosen, a tick.
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
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(theme.radii.lg);
    Widget row = PanelPressable(
      focusNode: focusNode,
      onPressed: onPressed,
      pressScale: 1,
      selected: selected,
      builder: (context, state) {
        // The chosen option sits on the accent fill, and so does the one
        // under the pointer or the keyboard, as on PanelUI's web select.
        final lit = selected || state.hovered || state.focused || state.pressed;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: lit ? c.accent : null,
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
                    color: c.foreground,
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
    );
    row = MergeSemantics(
      child: Semantics(role: SemanticsRole.menuItem, child: row),
    );
    return Opacity(opacity: enabled ? 1 : 0.64, child: row);
  }
}

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
              .copyWith(letterSpacing: 0.3),
        ),
      ),
    );
  }
}
