import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// Text naming a form field.
///
/// ```dart
/// const PanelLabel('Email', isRequired: true)
/// ```
///
/// [isInvalid] and [isDisabled] change how the label looks and what screen
/// readers are told about it together, so the two cannot drift apart. The
/// asterisk [isRequired] adds is for the eye and is not read out: mark the
/// field itself as required, which is what a screen reader announces.
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

  /// Dims the label to 64% opacity, greys the asterisk and announces the
  /// label as disabled.
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
      opacity: isDisabled ? _disabledOpacity : 1,
      child: Semantics(
        container: true,
        enabled: !isDisabled,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _asteriskGap,
          children: [
            Flexible(child: Text(text, style: style)),
            if (isRequired)
              ExcludeSemantics(
                child: Text(
                  '*',
                  style: style.copyWith(
                    color: isDisabled ? c.mutedForeground : c.destructive,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// PanelUI's `opacity-[0.64]` on a disabled label.
const double _disabledOpacity = 0.64;

/// PanelUI's `gap-1` between the text and the asterisk.
const double _asteriskGap = 4;
