import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// A quotation, set off by a rule along its leading edge.
///
/// ```dart
/// const PanelBlockquote(child: Text('Make it work, then make it right.'))
/// ```
class PanelBlockquote extends StatelessWidget {
  /// Creates a blockquote.
  const PanelBlockquote({super.key, required this.child, this.italic = true});

  /// The quotation, usually a [Text].
  final Widget child;

  /// Whether the quotation is set in italics.
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 16),
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: theme.colors.border, width: 2),
        ),
      ),
      child: DefaultTextStyle(
        style: theme.typography
            .style(PanelTextSize.base, color: theme.colors.foreground)
            .copyWith(fontStyle: italic ? FontStyle.italic : FontStyle.normal),
        child: child,
      ),
    );
  }
}

/// Inline code on a muted chip, in the monospace face.
///
/// ```dart
/// const PanelCode('flutter pub add panelui_flutter')
/// ```
class PanelCode extends StatelessWidget {
  /// Creates a code chip.
  const PanelCode(this.code, {super.key, this.muted = false});

  /// The code.
  final String code;

  /// Draws the code in the muted text colour.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: c.muted,
        borderRadius: BorderRadius.circular(theme.radii.md),
      ),
      child: Text(
        code,
        style: theme.typography.mono(
          PanelTextSize.sm,
          color: muted ? c.mutedForeground : c.foreground,
        ),
      ),
    );
  }
}

/// A bulleted or numbered list.
///
/// The bullet is drawn as a dot rather than set as a "•" character, whose
/// size and baseline vary from font to font.
///
/// ```dart
/// const PanelList(items: [Text('Tokens'), Text('Components'), Text('Gallery')])
/// ```
class PanelList extends StatelessWidget {
  /// Creates a list.
  const PanelList({super.key, required this.items, this.ordered = false});

  /// The items, usually [Text]s.
  final List<Widget> items;

  /// Number the items instead of bulleting them.
  final bool ordered;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final body = theme.typography.style(
      PanelTextSize.base,
      color: c.foreground,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              if (ordered)
                Text(
                  '${i + 1}.',
                  style: body.copyWith(color: c.mutedForeground),
                )
              else
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: c.mutedForeground,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: DefaultTextStyle(style: body, child: items[i]),
              ),
            ],
          ),
      ],
    );
  }
}
