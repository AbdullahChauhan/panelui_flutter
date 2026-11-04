import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';
import 'label.dart';

/// The layout and validation-state kit a form control composes into.
///
/// PanelUI's own controls already carry a label, a description and an error,
/// so most fields need no wrapper. [PanelField] is for what does not fit that
/// shape: a control with its label beside it (a switch in a settings list),
/// or a control that has no label of its own.
///
/// Horizontally, the title, description and control are merged into one
/// accessibility node, so a screen reader announces "Marketing emails,
/// product updates at most weekly, switch, on" as one thing.
///
/// ```dart
/// PanelField(
///   orientation: Axis.horizontal,
///   title: 'Marketing emails',
///   description: 'Product updates, at most weekly.',
///   child: PanelSwitch(value: on, onChanged: (v) => setState(() => on = v)),
/// )
/// ```
class PanelField extends StatelessWidget {
  /// Creates a field around [child].
  const PanelField({
    super.key,
    required this.child,
    this.orientation = Axis.vertical,
    this.label,
    this.title,
    this.description,
    this.errors = const [],
    this.isInvalid = false,
    this.isDisabled = false,
    this.isRequired = false,
  });

  /// The control.
  final Widget child;

  /// Vertical puts the label above the control; horizontal puts the title
  /// and description beside it.
  final Axis orientation;

  /// A form label, styled as [PanelLabel].
  final String? label;

  /// A title for a horizontal row: 16px, medium.
  final String? title;

  /// A muted line explaining the field.
  final String? description;

  /// Validation messages. Duplicates are dropped; one shows as a line, more
  /// than one as a bulleted list. Any message marks the field invalid.
  final List<String> errors;

  /// Draws the label in its error colour without a message.
  final bool isInvalid;

  /// Dims the field to 64% opacity.
  final bool isDisabled;

  /// Marks the label as required.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final invalid = isInvalid || errors.isNotEmpty;

    final labelWidget = label == null
        ? null
        : PanelLabel(
            label!,
            isRequired: isRequired,
            isInvalid: invalid,
            isDisabled: isDisabled,
          );
    final titleWidget = title == null
        ? null
        : Text(
            title!,
            style: theme.typography.style(
              PanelTextSize.base,
              weight: FontWeight.w500,
              color: c.foreground,
            ),
          );
    final descriptionWidget = description == null
        ? null
        : Text(
            description!,
            style: theme.typography.style(
              PanelTextSize.sm,
              color: c.mutedForeground,
            ),
          );
    final errorWidget = errors.isEmpty ? null : PanelFieldError(errors: errors);

    Widget field;
    if (orientation == Axis.horizontal) {
      field = MergeSemantics(
        child: Row(
          spacing: 16,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  ?labelWidget,
                  ?titleWidget,
                  ?descriptionWidget,
                  ?errorWidget,
                ],
              ),
            ),
            child,
          ],
        ),
      );
    } else {
      field = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (labelWidget != null || titleWidget != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: labelWidget ?? titleWidget,
            ),
          child,
          ?descriptionWidget,
          ?errorWidget,
        ],
      );
    }
    return Opacity(opacity: isDisabled ? 0.64 : 1, child: field);
  }
}

/// Validation messages for a field, announced as they appear.
class PanelFieldError extends StatelessWidget {
  /// Creates an error list.
  const PanelFieldError({super.key, required this.errors});

  /// The messages. Duplicates are dropped.
  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final style = theme.typography.style(
      PanelTextSize.sm,
      color: theme.colors.destructive,
    );
    final messages = <String>[];
    for (final e in errors) {
      if (e.isNotEmpty && !messages.contains(e)) messages.add(e);
    }
    if (messages.isEmpty) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      container: true,
      child: messages.length == 1
          ? Text(messages.single, style: style)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                for (final message in messages)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Text('•', style: style),
                      Expanded(child: Text(message, style: style)),
                    ],
                  ),
              ],
            ),
    );
  }
}

/// A group of related fields under a legend.
class PanelFieldSet extends StatelessWidget {
  /// Creates a field set.
  const PanelFieldSet({
    super.key,
    required this.children,
    this.legend,
    this.legendStyle = PanelFieldLegendStyle.legend,
  });

  /// The fields.
  final List<Widget> children;

  /// The group's heading.
  final String? legend;

  /// Whether the legend reads as a section heading or as a field label.
  final PanelFieldLegendStyle legendStyle;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final heading = legendStyle == PanelFieldLegendStyle.legend;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (legend != null)
            Semantics(
              header: true,
              child: Text(
                legend!,
                style: theme.typography.style(
                  heading ? PanelTextSize.base : PanelTextSize.sm,
                  weight: heading ? FontWeight.w600 : FontWeight.w500,
                  color: theme.colors.foreground,
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

/// How a [PanelFieldSet]'s legend is set.
enum PanelFieldLegendStyle {
  /// A section heading: 16px, semibold.
  legend,

  /// A field label: 14px, medium.
  label,
}
