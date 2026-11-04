import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// Text naming a form field.
///
/// [isRequired], [isInvalid] and [isDisabled] change both how the label looks
/// and what it says, so the two cannot drift apart.
///
/// ```dart
/// const PanelLabel('Email', isRequired: true)
/// ```
class PanelLabel extends StatelessWidget {
  /// Creates a label.
  const PanelLabel(
    this.text, {
    super.key,
    this.isRequired = false,
    this.isInvalid = false,
    this.isDisabled = false,
  });

  /// The label text.
  final String text;

  /// Appends an asterisk marking the field as required.
  final bool isRequired;

  /// Recolours the label to signal a validation error.
  final bool isInvalid;

  /// Dims the label to 64% opacity.
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final style = theme.typography.style(
      PanelTextSize.sm,
      weight: FontWeight.w500,
      color: isInvalid ? c.destructive : c.foreground,
    );
    return Opacity(
      opacity: isDisabled ? 0.64 : 1,
      child: Semantics(
        container: true,
        label: isRequired ? '$text, required' : text,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Flexible(child: Text(text, style: style)),
            if (isRequired)
              Text(
                '*',
                style: style.copyWith(
                  color: isDisabled ? c.mutedForeground : c.destructive,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
