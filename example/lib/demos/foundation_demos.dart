import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../gallery/gallery.dart';

/// Demos for the foundation the components share.
final List<GalleryDemo> foundationDemos = [
  GalleryDemo(
    id: 'icons',
    title: 'Icons',
    description:
        "PanelUI's glyphs, the same HugeIcons drawings, painted directly. "
        'They take their colour and size from the IconTheme around them.',
    builder: (_) => const _IconsDemo(),
  ),
];

class _IconsDemo extends StatelessWidget {
  const _IconsDemo();

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: [
        for (final MapEntry(key: name, value: icon) in PanelIcons.all.entries)
          SizedBox(
            width: 96,
            child: Column(
              spacing: 6,
              children: [
                Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colors.surface,
                    borderRadius: BorderRadius.circular(theme.radii.lg),
                  ),
                  child: PanelIcon(icon, size: 20, semanticLabel: name),
                ),
                PanelText(
                  name,
                  size: PanelTextSize.xs,
                  muted: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
