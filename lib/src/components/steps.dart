import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';
import 'spinner.dart';

/// Where a step stands. Worked out from its position against the stepper's
/// value, so the states stay mutually exclusive and in order.
enum _StepState { inactive, active, completed, loading }

/// What each state is called when a screen reader reaches the step.
const Map<_StepState, String> _stateWords = {
  _StepState.completed: 'completed',
  _StepState.active: 'current step',
  _StepState.loading: 'in progress',
  _StepState.inactive: 'not started',
};

/// A stepper for a multi-step flow: a row or column of numbered stops, each
/// completed, current, not started or loading.
///
/// ```dart
/// PanelSteps(
///   value: step,
///   onChanged: (s) => setState(() => step = s),
///   children: const [
///     PanelStep(title: Text('Account')),
///     PanelStep(title: Text('Profile')),
///     PanelStep(title: Text('Billing')),
///   ],
/// )
/// ```
///
/// A [PanelStep] works its state out from its own position against [value]
/// rather than being told it, so there is no way to write two current steps,
/// or to mark step four done while step three is pending. Steps does not own
/// your flow: it reflects whichever step your app says is current.
///
/// The connectors are the stepper's job: each step draws the one to the
/// next, filled once the step is complete, and the last draws none. In a
/// horizontal stepper every step but the last shares out the row, so its
/// connector reaches the next.
///
/// With [onChanged] the steps can be pressed to select them; without it the
/// stepper is read-only.
class PanelSteps extends StatefulWidget {
  /// Creates a stepper.
  const PanelSteps({
    super.key,
    required this.children,
    this.value,
    this.initialValue = 0,
    this.onChanged,
    this.orientation = Axis.horizontal,
    this.showSeparators = true,
  });

  /// The steps, usually [PanelStep]s.
  final List<Widget> children;

  /// The current step, zero-based. When null the stepper keeps its own,
  /// starting from [initialValue].
  final int? value;

  /// The current step at first, when [value] is null.
  final int initialValue;

  /// Called with the step that was pressed. Null makes the steps read-only.
  final ValueChanged<int>? onChanged;

  /// Whether the steps run across or down.
  final Axis orientation;

  /// Whether each step draws a connector to the next.
  final bool showSeparators;

  @override
  State<PanelSteps> createState() => _PanelStepsState();
}

class _PanelStepsState extends State<PanelSteps> {
  late int _internal = widget.initialValue;

  int get _value => widget.value ?? _internal;

  void _select(int step) {
    if (widget.value == null) setState(() => _internal = step);
    widget.onChanged?.call(step);
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.orientation == Axis.horizontal;
    // Counted here rather than registered by each step, so the connectors
    // and the "2 of 3" announcements are right on the first frame.
    final total = widget.children.whereType<PanelStep>().length;
    var position = -1;
    final items = <Widget>[];
    for (final child in widget.children) {
      if (child is! PanelStep) {
        items.add(child);
        continue;
      }
      position++;
      final last = position == total - 1;
      Widget item = _StepPosition(
        position: position,
        total: total,
        child: child,
      );
      if (horizontal && widget.showSeparators && !last) {
        item = Expanded(child: item);
      }
      items.add(
        KeyedSubtree(
          key: child.key == null ? null : ValueKey<Key>(child.key!),
          child: item,
        ),
      );
    }

    return _StepsScope(
      current: _value,
      select: widget.onChanged == null ? null : _select,
      orientation: widget.orientation,
      showSeparators: widget.showSeparators,
      child: horizontal
          ? Row(children: items)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items,
            ),
    );
  }
}

class _StepsScope extends InheritedWidget {
  const _StepsScope({
    required this.current,
    required this.select,
    required this.orientation,
    required this.showSeparators,
    required super.child,
  });

  final int current;
  final ValueChanged<int>? select;
  final Axis orientation;
  final bool showSeparators;

  static _StepsScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_StepsScope>();
    if (scope == null) {
      throw FlutterError('PanelStep must be used inside a PanelSteps.');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(_StepsScope oldWidget) =>
      current != oldWidget.current ||
      select != oldWidget.select ||
      orientation != oldWidget.orientation ||
      showSeparators != oldWidget.showSeparators;
}

/// Where a step sits among its siblings: the position in the row as
/// rendered, which the connector and the announcement need, and which is
/// not necessarily the author's own numbering in [PanelStep.step].
class _StepPosition extends InheritedWidget {
  const _StepPosition({
    required this.position,
    required this.total,
    required super.child,
  });

  final int position;
  final int total;

  @override
  bool updateShouldNotify(_StepPosition oldWidget) =>
      position != oldWidget.position || total != oldWidget.total;
}

/// One stop in a [PanelSteps]: a circle showing its number, a check once
/// completed or a spinner while loading, with an optional title and
/// description beside it.
///
/// A screen reader hears the step's position and state after its title, as
/// in "Payment, step 2 of 3, completed".
class PanelStep extends StatelessWidget {
  /// Creates a step.
  const PanelStep({
    super.key,
    this.step,
    this.title,
    this.description,
    this.indicator,
    this.completed = false,
    this.enabled = true,
    this.loading = false,
    this.semanticLabel,
  });

  /// This step's place in the flow, zero-based, compared against
  /// [PanelSteps.value]. Defaults to its position among the steps.
  final int? step;

  /// The title, small and medium weight.
  final Widget? title;

  /// A muted line under the title.
  final Widget? description;

  /// Replaces the number, check or spinner inside the circle.
  final Widget? indicator;

  /// Forces the completed state, whatever the current step.
  final bool completed;

  /// Whether the step can be selected. A disabled step is dimmed.
  final bool enabled;

  /// Shows a spinner in place of the number while this step is current.
  final bool loading;

  /// An accessible name, when [title] is not text.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scope = _StepsScope.of(context);
    final placement = context
        .dependOnInheritedWidgetOfExactType<_StepPosition>();
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final number = step ?? placement?.position ?? 0;
    final isLoading = loading && number == scope.current;
    final _StepState state;
    if (completed || number < scope.current) {
      state = _StepState.completed;
    } else if (number == scope.current) {
      state = isLoading ? _StepState.loading : _StepState.active;
    } else {
      state = _StepState.inactive;
    }
    final horizontal = scope.orientation == Axis.horizontal;
    final last = placement == null || placement.position == placement.total - 1;

    final hasText = title != null || description != null;
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        _StepIndicator(state: state, number: number, custom: indicator),
        if (hasText)
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  DefaultTextStyle(
                    style: theme.typography.style(
                      PanelTextSize.sm,
                      weight: FontWeight.w500,
                      color: c.foreground,
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
      ],
    );

    // Said as a value rather than a label: the label is the step's own
    // title, and a value is read after it.
    final words = _stateWords[state]!;
    final position = placement == null
        ? words
        : 'step ${placement.position + 1} of ${placement.total}, $words';
    content = Opacity(
      opacity: enabled ? 1 : 0.64,
      child: Semantics(value: position, child: content),
    );

    final select = scope.select;
    final Widget trigger;
    if (select != null) {
      trigger = PanelPressable(
        onPressed: enabled ? () => select(number) : null,
        pressScale: 1,
        selected: state == _StepState.active,
        semanticLabel: semanticLabel,
        focusRingRadius: BorderRadius.circular(hasText ? theme.radii.md : 14),
        child: content,
      );
    } else {
      trigger = Semantics(
        container: true,
        label: semanticLabel,
        enabled: enabled ? null : false,
        child: content,
      );
    }

    if (!scope.showSeparators || last) return trigger;

    final color = state == _StepState.completed ? c.primary : c.muted;
    if (horizontal) {
      return Row(
        children: [
          trigger,
          Expanded(
            child: ExcludeSemantics(child: Container(height: 2, color: color)),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        trigger,
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14),
            child: Container(width: 2, height: 32, color: color),
          ),
        ),
      ],
    );
  }
}

/// The 28pt circle: the step's number, a check once completed, or a spinner
/// while loading.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.state,
    required this.number,
    required this.custom,
  });

  final _StepState state;
  final int number;
  final Widget? custom;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final filled = state == _StepState.active || state == _StepState.completed;
    final foreground = filled ? c.primaryForeground : c.mutedForeground;

    final Widget glyph;
    if (custom != null) {
      glyph = custom!;
    } else if (state == _StepState.loading) {
      glyph = const PanelSpinner(size: PanelSpinnerSize.sm);
    } else if (state == _StepState.completed) {
      glyph = PanelIcon(PanelIcons.check, size: 14, color: foreground);
    } else {
      // Zero-based underneath, read as 1, 2, 3.
      glyph = ExcludeSemantics(
        child: Text(
          '${number + 1}',
          style: theme.typography.style(
            PanelTextSize.xs,
            weight: FontWeight.w500,
            color: foreground,
          ),
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? c.primary : c.muted,
        shape: BoxShape.circle,
      ),
      child: IconTheme(
        data: IconThemeData(color: foreground, size: 14),
        child: DefaultTextStyle(
          style: theme.typography.style(
            PanelTextSize.xs,
            weight: FontWeight.w500,
            color: foreground,
          ),
          child: glyph,
        ),
      ),
    );
  }
}
