import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../foundation/selection_hit_slop.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';

/// How a [PanelToggleButton] looks at rest. Selected, every variant takes the
/// same filled accent surface.
enum PanelToggleButtonVariant {
  /// A soft fill at rest, so the control is visible before it is touched.
  /// PanelUI's `default`.
  secondary,

  /// Nothing at rest, for a dense toolbar where six fills would be noise.
  ghost,
}

/// How big a [PanelToggleButton] is: the same five heights as `PanelButton`,
/// so a toggle and a button side by side in a toolbar are one row.
enum PanelToggleButtonSize {
  /// 28pt tall, 12px text.
  xs,

  /// 36pt tall, 14px text.
  sm,

  /// 44pt tall, 16px text. The default.
  md,

  /// 48pt tall, 18px text.
  lg,

  /// 56pt tall, 18px text.
  xl,
}

/// How a [PanelToggleButtonGroup] treats its buttons.
enum PanelToggleSelectionMode {
  /// An either-or choice: picking one clears the last, and pressing the
  /// chosen one again clears it, because a filter that cannot be turned off
  /// is a trap.
  single,

  /// A set of independent marks, any number on at once: bold and italic.
  multiple,
}

class _ToggleMetrics {
  const _ToggleMetrics(
    this.height,
    this.padding,
    this.gap,
    this.fontSize,
    this.iconSize,
  );

  final double height;
  final double padding;
  final double gap;
  final double fontSize;
  final double iconSize;
}

const _toggleMetrics = {
  PanelToggleButtonSize.xs: _ToggleMetrics(28, 8, 4, 12, 14),
  PanelToggleButtonSize.sm: _ToggleMetrics(36, 10, 6, 14, 16),
  PanelToggleButtonSize.md: _ToggleMetrics(44, 16, 8, 16, 18),
  PanelToggleButtonSize.lg: _ToggleMetrics(48, 24, 8, 18, 20),
  PanelToggleButtonSize.xl: _ToggleMetrics(56, 32, 8, 18, 20),
};

/// What an xs toggle is short of a 44pt target on each side.
const _xsHitSlop = 8.0;

/// A button that stays down.
///
/// A button does something and springs back; a toggle button *is* something
/// afterwards. So the selected state is the loud one, a filled accent surface
/// with a faint primary edge, and the resting state is quiet.
///
/// ```dart
/// PanelToggleButton(
///   value: liked,
///   onChanged: (v) => setState(() => liked = v),
///   leading: const PanelIcon(PanelIcons.heart),
///   child: const Text('Like'),
/// )
/// ```
///
/// Inside a [PanelToggleButtonGroup] the group owns the state: give each
/// button an [id], which is what the group reports, and leave [value] and
/// [onChanged] unset. Text and icons inside take the colour that reads
/// against the fill, muted at rest and full strength when selected.
class PanelToggleButton extends StatelessWidget {
  /// Creates a toggle button.
  const PanelToggleButton({
    super.key,
    this.value = false,
    this.onChanged,
    this.id,
    this.child,
    this.leading,
    this.trailing,
    this.variant,
    this.size,
    this.iconOnly = false,
    this.enabled = true,
    this.haptics,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether the button is down. Ignored inside a group, which owns it.
  final bool value;

  /// Called with the new state. Null disables a button outside a group.
  final ValueChanged<bool>? onChanged;

  /// Identifies the button within a [PanelToggleButtonGroup], and is what the
  /// group's value holds while it is down. Required there.
  final Object? id;

  /// The label, usually a [Text].
  final Widget? child;

  /// Content before the label, such as an icon.
  final Widget? leading;

  /// Content after the label.
  final Widget? trailing;

  /// The look at rest. Defaults to the group's, then secondary.
  final PanelToggleButtonVariant? variant;

  /// The size. Defaults to the group's, then md.
  final PanelToggleButtonSize? size;

  /// Square, with no horizontal padding, for a lone icon. Give it a
  /// [semanticLabel].
  final bool iconOnly;

  /// Whether the button accepts presses. A disabled button is drawn at 64%
  /// opacity.
  final bool enabled;

  /// A selection tick of the haptic engine on each press. Defaults to the
  /// group's, then off.
  final bool? haptics;

  /// The accessible name, for a button whose content is not text.
  final String? semanticLabel;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final group = _ToggleGroupScope.maybeOf(context);
    final ident = id;
    assert(
      group == null || ident == null || group.accepts(ident),
      'PanelToggleButton.id $ident is not a ${group.valueType}, the value '
      'type of the PanelToggleButtonGroup around it.',
    );
    final grouped = group != null && ident != null;
    final selected = grouped ? group.isSelected(ident) : value;
    final isEnabled =
        enabled &&
        (group?.enabled ?? true) &&
        (grouped ? group.enabled : onChanged != null);
    final resolvedVariant =
        variant ?? group?.variant ?? PanelToggleButtonVariant.secondary;
    final resolvedSize = size ?? group?.size ?? PanelToggleButtonSize.md;
    final tick = haptics ?? group?.haptics ?? false;
    final m = _toggleMetrics[resolvedSize]!;
    final ghost = resolvedVariant == PanelToggleButtonVariant.ghost;
    final radius = BorderRadius.circular(
      resolvedSize == PanelToggleButtonSize.xs
          ? theme.radii.md
          : theme.radii.lg,
    );
    final duration = panelReduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 150);

    void press() {
      // A tick per press, not per resolved change: a single-choice group
      // flips two buttons on every pick, and one tick is the honest count.
      if (tick) HapticFeedback.selectionClick();
      if (grouped) {
        group.toggle(ident);
      } else {
        onChanged?.call(!value);
      }
    }

    Widget button = PanelPressable(
      onPressed: isEnabled ? press : null,
      // `checked` is what a screen reader reads as on or off: the selected
      // state is the point of the control, so it is not left to the colour.
      checked: selected,
      inMutuallyExclusiveGroup: grouped && group.single ? true : null,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
      focusRingRadius: radius,
      builder: (context, state) {
        const clear = Color(0x00000000);
        final hovered = state.hovered && !selected;
        final Color fill;
        if (selected) {
          fill = c.accent;
        } else if (hovered) {
          // The web package's hover: a ghost takes the accent tint and the
          // soft fill thins, as Button's do.
          fill = ghost
              ? c.accent
              : c.secondary.withValues(alpha: c.secondary.a * 0.8);
        } else {
          fill = ghost ? clear : c.secondary;
        }
        final Color foreground;
        if (selected) {
          foreground = c.accentForeground;
        } else {
          foreground = hovered ? c.foreground : c.mutedForeground;
        }
        final labelStyle = theme.typography.sized(
          m.fontSize,
          weight: FontWeight.w500,
          color: foreground,
        );
        final content = IconTheme(
          data: IconThemeData(color: foreground, size: m.iconSize),
          child: DefaultTextStyle(
            style: labelStyle,
            textAlign: TextAlign.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: m.gap,
              children: [
                ?leading,
                if (child != null)
                  Flexible(
                    child: semanticLabel == null
                        ? child!
                        : ExcludeSemantics(child: child),
                  ),
                ?trailing,
              ],
            ),
          ),
        );
        return Opacity(
          opacity: isEnabled ? 1 : 0.64,
          // Only the colours cross over; a change of size lands at once.
          child: SizedBox(
            height: m.height,
            width: iconOnly ? m.height : null,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(
                  color: selected
                      ? c.primary.withValues(alpha: c.primary.a * 0.24)
                      : clear,
                ),
                borderRadius: radius,
              ),
              child: Padding(
                padding: iconOnly
                    ? EdgeInsets.zero
                    : EdgeInsets.symmetric(horizontal: m.padding),
                child: Center(
                  widthFactor: iconOnly ? null : 1,
                  heightFactor: 1,
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );

    // A 28pt toggle standing alone is given the rest of a 44pt target. Not
    // inside a group, where the slop would reach into its neighbours.
    if (group == null && resolvedSize == PanelToggleButtonSize.xs) {
      button = SelectionHitSlop(
        slop: const EdgeInsets.all(_xsHitSlop),
        child: button,
      );
    }
    return button;
  }
}

class _ToggleGroupScope extends InheritedWidget {
  const _ToggleGroupScope({
    required this.selection,
    required this.valueType,
    required this.accepts,
    required this.isSelected,
    required this.toggle,
    required this.enabled,
    required this.single,
    required this.variant,
    required this.size,
    required this.haptics,
    required super.child,
  });

  final List<Object?> selection;
  final Type valueType;
  final bool Function(Object id) accepts;
  final bool Function(Object id) isSelected;
  final void Function(Object id) toggle;
  final bool enabled;
  final bool single;
  final PanelToggleButtonVariant? variant;
  final PanelToggleButtonSize? size;
  final bool? haptics;

  static _ToggleGroupScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ToggleGroupScope>();

  @override
  bool updateShouldNotify(_ToggleGroupScope oldWidget) =>
      !listEquals(selection, oldWidget.selection) ||
      enabled != oldWidget.enabled ||
      single != oldWidget.single ||
      variant != oldWidget.variant ||
      size != oldWidget.size ||
      haptics != oldWidget.haptics ||
      toggle != oldWidget.toggle;
}

/// A set of [PanelToggleButton]s whose state it holds as one list of ids.
///
/// ```dart
/// PanelToggleButtonGroup<String>(
///   value: marks,
///   onChanged: (v) => setState(() => marks = v),
///   variant: PanelToggleButtonVariant.ghost,
///   children: const [
///     PanelToggleButton(id: 'bold', iconOnly: true, semanticLabel: 'Bold',
///         child: PanelIcon(PanelIcons.bold)),
///     PanelToggleButton(id: 'italic', iconOnly: true, semanticLabel: 'Italic',
///         child: PanelIcon(PanelIcons.italic)),
///   ],
/// )
/// ```
///
/// [PanelToggleSelectionMode.multiple] is a toolbar of independent marks;
/// [PanelToggleSelectionMode.single] an either-or choice, announced as a
/// radio group. [variant], [size] and [haptics] fill in for any button that
/// did not set its own.
class PanelToggleButtonGroup<T extends Object> extends StatelessWidget {
  /// Creates a group of toggle buttons.
  const PanelToggleButtonGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.selectionMode = PanelToggleSelectionMode.multiple,
    this.variant,
    this.size,
    this.haptics,
  });

  /// The ids of the buttons that are down, in the order they went down.
  final List<T> value;

  /// Called with the new list. Null disables every button in the group.
  final ValueChanged<List<T>>? onChanged;

  /// The buttons.
  final List<Widget> children;

  /// One at a time, or any number.
  final PanelToggleSelectionMode selectionMode;

  /// The default look for the buttons.
  final PanelToggleButtonVariant? variant;

  /// The default size for the buttons.
  final PanelToggleButtonSize? size;

  /// The default for the buttons' haptic tick.
  final bool? haptics;

  void _toggle(Object id) {
    if (id is! T) return;
    final has = value.contains(id);
    final List<T> next;
    if (selectionMode == PanelToggleSelectionMode.single) {
      next = has ? <T>[] : <T>[id];
    } else {
      next = has
          ? [
              for (final item in value)
                if (item != id) item,
            ]
          : [...value, id];
    }
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final single = selectionMode == PanelToggleSelectionMode.single;
    return _ToggleGroupScope(
      selection: value,
      valueType: T,
      accepts: (id) => id is T,
      isSelected: (id) => id is T && value.contains(id),
      toggle: _toggle,
      enabled: onChanged != null,
      single: single,
      variant: variant,
      size: size,
      haptics: haptics,
      // An either-or choice is read out as a radio group; a set of marks as
      // the buttons it is.
      child: Semantics(
        container: true,
        role: single ? SemanticsRole.radioGroup : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: children,
        ),
      ),
    );
  }
}
