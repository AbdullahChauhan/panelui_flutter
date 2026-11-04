import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';
import 'spinner.dart';

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
/// connector reaches the next; PanelUI leaves that `flex-1` to the caller.
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
    final number = step ?? placement?.position ?? 0;
    final current = scope.current;
    final spinning = loading && number == current;
    final state = completed || number < current
        ? _StepState.completed
        : number == current
        ? (spinning ? _StepState.loading : _StepState.active)
        : _StepState.inactive;

    final hasText = title != null || description != null;
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: _triggerGap,
      children: [
        _StepIndicator(
          state: state,
          number: number,
          spinning: spinning,
          custom: indicator,
        ),
        if (hasText)
          Flexible(
            child: _StepText(title: title, description: description),
          ),
      ],
    );
    content = Opacity(opacity: enabled ? 1 : _disabledOpacity, child: content);

    // Said as a value rather than a label: the label is the step's own text
    // (its number and title), and a value is read after it.
    final position = placement == null
        ? state.words
        : 'step ${placement.position + 1} of ${placement.total}, '
              '${state.words}';

    final select = scope.select;
    final Widget trigger = select == null
        ? Semantics(
            container: true,
            label: semanticLabel,
            value: position,
            enabled: enabled ? null : false,
            child: content,
          )
        : PanelPressable(
            onPressed: enabled ? () => select(number) : null,
            pressScale: 1,
            selected: state == _StepState.active,
            semanticValue: position,
            semanticLabel: semanticLabel,
            focusRingRadius: hasText
                ? BorderRadius.circular(theme.radii.md)
                : BorderRadius.circular(_indicatorSize / 2),
            child: content,
          );

    final last = placement == null || placement.position == placement.total - 1;
    if (!scope.showSeparators || last) return trigger;
    final connector = _StepConnector(
      orientation: scope.orientation,
      filled: state == _StepState.completed,
    );
    return scope.orientation == Axis.horizontal
        ? Row(
            children: [
              trigger,
              Expanded(child: connector),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [trigger, connector],
          );
  }
}

/// Where a step stands. Worked out from its position against the stepper's
/// value, so the states stay mutually exclusive and in order.
enum _StepState {
  inactive('not started'),
  active('current step'),
  completed('completed'),
  loading('in progress');

  const _StepState(this.words);

  /// What the state is called when a screen reader reaches the step.
  final String words;
}

/// The circle's diameter (`h-7 w-7`).
const double _indicatorSize = 28;

/// The gap between the circle and the step's text (`gap-3`).
const double _triggerGap = 12;

/// A disabled step's opacity (`opacity-[0.64]`).
const double _disabledOpacity = 0.64;

/// A connector's thickness (`h-0.5` across, `w-0.5` down).
const double _connectorThickness = 2;

/// A vertical connector's length (`h-8`), and how far in from the leading
/// edge it runs (`ms-3.5`): down the middle of the circle above it.
const double _verticalConnectorLength = 32;
const double _verticalConnectorInset = 14;

/// The check in a completed circle.
const double _checkSize = 14;

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

/// The circle: the step's number, a check once completed, or a spinner
/// while loading.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.state,
    required this.number,
    required this.spinning,
    required this.custom,
  });

  final _StepState state;
  final int number;

  /// Whether the step is loading while current. The spinner takes the
  /// circle even from a step forced complete, as in PanelUI, which asks
  /// about it before the check.
  final bool spinning;
  final Widget? custom;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final filled = state == _StepState.active || state == _StepState.completed;
    final foreground = filled ? c.primaryForeground : c.mutedForeground;

    return Container(
      width: _indicatorSize,
      height: _indicatorSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? c.primary : c.muted,
        shape: BoxShape.circle,
      ),
      child: IconTheme(
        data: IconThemeData(color: foreground, size: _checkSize),
        child: DefaultTextStyle(
          style: theme.typography.style(
            PanelTextSize.xs,
            weight: FontWeight.w500,
            color: foreground,
          ),
          child:
              custom ??
              (spinning
                  ? const PanelSpinner(size: PanelSpinnerSize.sm)
                  : state == _StepState.completed
                  ? const PanelIcon(PanelIcons.check)
                  // Zero-based underneath, read as 1, 2, 3.
                  : Text('${number + 1}')),
        ),
      ),
    );
  }
}

/// A step's title and the muted line under it.
class _StepText extends StatelessWidget {
  const _StepText({required this.title, required this.description});

  final Widget? title;
  final Widget? description;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final title = this.title;
    final description = this.description;
    return Column(
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
            child: title,
          ),
        if (description != null)
          DefaultTextStyle(
            style: theme.typography.style(
              PanelTextSize.sm,
              color: c.mutedForeground,
            ),
            child: description,
          ),
      ],
    );
  }
}

/// The line from a step to the next, filled once the step is complete.
/// Hidden from screen readers, which hear each step's state instead.
class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.orientation, required this.filled});

  final Axis orientation;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = PanelTheme.of(context).colors;
    final line = ColoredBox(color: filled ? c.primary : c.muted);
    return ExcludeSemantics(
      child: orientation == Axis.horizontal
          ? SizedBox(height: _connectorThickness, child: line)
          : Padding(
              padding: const EdgeInsetsDirectional.only(
                start: _verticalConnectorInset,
              ),
              child: SizedBox(
                width: _connectorThickness,
                height: _verticalConnectorLength,
                child: line,
              ),
            ),
    );
  }
}
