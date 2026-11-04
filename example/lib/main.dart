import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import 'demos/registry.dart';
import 'gallery/gallery.dart';

void main() {
  // On the web, `?family=moon&mode=dark&demo=button` opens the gallery in
  // that state, which is how the screenshots in the README are taken.
  final query = Uri.base.queryParameters;
  runApp(
    GalleryApp(
      initialFamily: PanelThemeFamily.values.firstWhere(
        (f) => f.id == query['family'],
        orElse: () => PanelThemeFamily.panel,
      ),
      initialMode: switch (query['mode']) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      },
      onlyDemo: query['demo'],
    ),
  );
}

class GalleryApp extends StatefulWidget {
  const GalleryApp({
    super.key,
    this.initialFamily = PanelThemeFamily.panel,
    this.initialMode = ThemeMode.system,
    this.onlyDemo,
  });

  final PanelThemeFamily initialFamily;
  final ThemeMode initialMode;
  final String? onlyDemo;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  late PanelThemeFamily _family = widget.initialFamily;
  late ThemeMode _mode = widget.initialMode;

  static const _typography = PanelTypography(fontFamily: 'Inter');

  ThemeData _material(PanelThemeData theme) =>
      theme.copyWith(typography: _typography).toMaterialTheme();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PanelUI for Flutter',
      debugShowCheckedModeBanner: false,
      theme: _material(_family.light),
      darkTheme: _material(_family.dark),
      themeMode: _mode,
      home: GalleryHome(
        family: _family,
        onFamilyChanged: (family) => setState(() => _family = family),
        onToggleBrightness: (dark) =>
            setState(() => _mode = dark ? ThemeMode.light : ThemeMode.dark),
        onlyDemo: widget.onlyDemo,
      ),
    );
  }
}

class GalleryHome extends StatelessWidget {
  const GalleryHome({
    super.key,
    required this.family,
    required this.onFamilyChanged,
    required this.onToggleBrightness,
    this.onlyDemo,
  });

  final PanelThemeFamily family;
  final ValueChanged<PanelThemeFamily> onFamilyChanged;
  final ValueChanged<bool> onToggleBrightness;
  final String? onlyDemo;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final demos = onlyDemo == null
        ? galleryDemos
        : galleryDemos.where((d) => d.id == onlyDemo).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 48,
                  children: [
                    _Header(
                      family: family,
                      dark: theme.isDark,
                      onFamilyChanged: onFamilyChanged,
                      onToggleBrightness: () =>
                          onToggleBrightness(theme.isDark),
                    ),
                    for (final demo in demos) GallerySection(demo: demo),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.family,
    required this.dark,
    required this.onFamilyChanged,
    required this.onToggleBrightness,
  });

  final PanelThemeFamily family;
  final bool dark;
  final ValueChanged<PanelThemeFamily> onFamilyChanged;
  final VoidCallback onToggleBrightness;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Row(
          spacing: 8,
          children: [
            const PanelText(
              'PanelUI for Flutter',
              size: PanelTextSize.xxl,
              weight: FontWeight.w600,
            ),
            const PanelBadge(
              variant: PanelBadgeVariant.secondary,
              child: Text('unofficial port'),
            ),
          ],
        ),
        PanelText(
          'The PanelUI design system for Flutter: ${galleryDemos.length} '
          'demos across three theme families, each in light and dark.',
          muted: true,
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PanelButtonGroup(
              size: PanelButtonSize.sm,
              variant: PanelButtonVariant.ghost,
              children: [
                for (final f in PanelThemeFamily.values)
                  PanelButton(
                    variant: f == family ? PanelButtonVariant.secondary : null,
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: f
                            .resolve(dark ? Brightness.dark : Brightness.light)
                            .colors
                            .primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onPressed: () => onFamilyChanged(f),
                    child: Text(f.name),
                  ),
              ],
            ),
            PanelButton(
              size: PanelButtonSize.sm,
              variant: PanelButtonVariant.outline,
              semanticLabel: dark ? 'Use light theme' : 'Use dark theme',
              leading: PanelIcon(dark ? PanelIcons.sun : PanelIcons.moon),
              onPressed: onToggleBrightness,
              child: Text(dark ? 'Light' : 'Dark'),
            ),
          ],
        ),
      ],
    );
  }
}
