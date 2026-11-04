import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// Text on PanelUI's type scale, in the theme's foreground colour.
///
/// ```dart
/// PanelText('Billing', size: PanelTextSize.lg, weight: FontWeight.w600)
/// PanelText('Updated 2 minutes ago', size: PanelTextSize.sm, muted: true)
/// ```
class PanelText extends StatelessWidget {
  /// Creates a run of text.
  const PanelText(
    this.data, {
    super.key,
    this.size = PanelTextSize.base,
    this.weight = FontWeight.w400,
    this.muted = false,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  });

  /// The text.
  final String data;

  /// The step on the type scale.
  final PanelTextSize size;

  /// The weight.
  final FontWeight weight;

  /// Draws in the `mutedForeground` token, for secondary text.
  final bool muted;

  /// Overrides the colour.
  final Color? color;

  /// Merged over the computed style.
  final TextStyle? style;

  /// Horizontal alignment.
  final TextAlign? textAlign;

  /// Maximum number of lines.
  final int? maxLines;

  /// How overflow is drawn.
  final TextOverflow? overflow;

  /// Whether to wrap at soft line breaks.
  final bool? softWrap;

  /// An alternative label for screen readers.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final base = theme.typography.style(
      size,
      weight: weight,
      color:
          color ??
          (muted ? theme.colors.mutedForeground : theme.colors.foreground),
    );
    return Text(
      data,
      style: style == null ? base : base.merge(style),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );
  }
}
