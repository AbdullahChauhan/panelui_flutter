import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// A hairline between pieces of content.
///
/// ```dart
/// const PanelSeparator()
/// const PanelSeparator(orientation: Axis.vertical)
/// const PanelSeparator(label: Text('or continue with'))
/// ```
///
/// A rule spans the room its parent gives it along its length. A vertical one
/// in a row needs that row to have a height (an [IntrinsicHeight], a fixed
/// height, or a stretching parent), or a [length].
///
/// A [label] breaks a horizontal rule around centred content, such as the
/// "or" between two ways to sign in. A vertical separator ignores it: a
/// stacked word is not a divider.
class PanelSeparator extends StatelessWidget {
  /// Creates a separator.
  const PanelSeparator({
    super.key,
    this.orientation = Axis.horizontal,
    this.thickness = thin,
    this.length,
    this.label,
    this.decorative = true,
  });

  /// PanelUI's `thin` variant, the default.
  static const double thin = 1;

  /// PanelUI's `thick` variant.
  static const double thick = 4;

  /// Which way the rule runs.
  final Axis orientation;

  /// The rule's thickness: [thin], [thick], or any other width.
  final double thickness;

  /// A fixed length. Null spans the room the parent gives.
  final double? length;

  /// Content sitting in a break in a horizontal rule. Text in it is set small
  /// and muted.
  final Widget? label;

  /// Whether the separator is only visual, and so skipped by screen readers.
  /// Set it false where the split itself carries meaning, such as between
  /// two groups of menu items. A labelled separator is always read: its label
  /// is content.
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final color = theme.colors.border;

    if (orientation == Axis.horizontal && label != null) {
      // The two rules flank the label; only the label is read.
      final rule = Expanded(
        child: Container(height: thickness, color: color),
      );
      return Row(
        spacing: _labelGap,
        children: [
          rule,
          DefaultTextStyle(
            style: theme.typography.style(
              PanelTextSize.xs,
              color: theme.colors.mutedForeground,
            ),
            child: label!,
          ),
          rule,
        ],
      );
    }

    // A Container with no child spans the room its parent gives along the
    // unsized axis, and collapses where that room is unbounded rather than
    // asking for an infinite length.
    final Widget line = orientation == Axis.horizontal
        ? Container(width: length, height: thickness, color: color)
        : Container(width: thickness, height: length, color: color);
    if (decorative) return ExcludeSemantics(child: line);
    return Semantics(container: true, child: line);
  }
}

/// PanelUI's `gap-3` between a label and the rules on either side of it.
const double _labelGap = 12;
