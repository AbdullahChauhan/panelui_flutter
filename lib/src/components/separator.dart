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
/// A vertical separator takes its length from its parent, so put it in a row
/// with a height (an [IntrinsicHeight], or a fixed one) or pass [length].
///
/// A [label] breaks a horizontal rule around centred content, such as the
/// "or" between two ways to sign in. A vertical separator ignores it.
class PanelSeparator extends StatelessWidget {
  /// Creates a separator.
  const PanelSeparator({
    super.key,
    this.orientation = Axis.horizontal,
    this.thickness = 1,
    this.length,
    this.label,
    this.decorative = true,
  });

  /// Which way the rule runs.
  final Axis orientation;

  /// The rule's thickness. PanelUI's `thick` variant is 4.
  final double thickness;

  /// A fixed length. Null fills the space the parent gives.
  final double? length;

  /// Content sitting in a break in a horizontal rule.
  final Widget? label;

  /// Whether the separator is only visual. A decorative one is skipped by
  /// screen readers. A labelled separator is always read.
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final color = theme.colors.border;

    if (orientation == Axis.horizontal && label != null) {
      final rule = Expanded(
        child: Container(height: thickness, color: color),
      );
      return Row(
        spacing: 12,
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

    final Widget line = orientation == Axis.horizontal
        ? Container(
            width: length ?? double.infinity,
            height: thickness,
            color: color,
          )
        : Container(width: thickness, height: length, color: color);
    if (decorative) return ExcludeSemantics(child: line);
    return Semantics(container: true, child: line);
  }
}
