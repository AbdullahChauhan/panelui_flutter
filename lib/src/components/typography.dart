import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// A quotation, set off by a rule along its leading edge.
///
/// The rule is on the start side, so it moves to the right in a right-to-left
/// layout without the quote having to know.
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
/// The chip keeps to the width of its code at the start of its parent, as
/// PanelUI's `self-start` does, rather than stretching into a bar.
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
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
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
      ),
    );
  }
}

/// A bulleted or numbered list, announced as a list of items.
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
    return Semantics(
      container: true,
      role: SemanticsRole.list,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          for (var i = 0; i < items.length; i++)
            Semantics(
              container: true,
              role: SemanticsRole.listItem,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  if (ordered)
                    Text(
                      '${i + 1}.',
                      style: body.copyWith(color: c.mutedForeground),
                    )
                  else
                    const _Bullet(),
                  Expanded(
                    child: DefaultTextStyle(style: body, child: items[i]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A list item's dot, centred on the first line of body text.
class _Bullet extends StatelessWidget {
  const _Bullet();

  /// PanelUI's `size-1.5`.
  static const double _size = 6;

  /// PanelUI's `mt-2.5`, which sets the dot against the first 24pt line.
  static const double _top = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      margin: const EdgeInsets.only(top: _top),
      decoration: BoxDecoration(
        color: PanelTheme.of(context).colors.mutedForeground,
        shape: BoxShape.circle,
      ),
    );
  }
}
