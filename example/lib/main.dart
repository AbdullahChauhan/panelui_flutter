import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import 'demos/registry.dart';
import 'gallery/gallery.dart';

/// Opens on the page in the URL fragment (`#/button`). On the web,
/// `?family=moon&mode=dark` picks the theme, so any state can be linked to.
void main() {
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
    ),
  );
}

class GalleryApp extends StatefulWidget {
  const GalleryApp({
    super.key,
    this.initialFamily = PanelThemeFamily.panel,
    this.initialMode = ThemeMode.system,
  });

  final PanelThemeFamily initialFamily;
  final ThemeMode initialMode;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  late PanelThemeFamily _family = widget.initialFamily;
  late ThemeMode _mode = widget.initialMode;

  // Inter, the face PanelUI's own documentation is set in.
  static const _typography = PanelTypography(fontFamily: 'Inter');

  ThemeData _material(PanelThemeData theme) =>
      theme.copyWith(typography: _typography).toMaterialTheme();

  // Pages swap in place, as in a documentation site: no slide between them.
  static Route<void> _route(String? name) {
    final page = galleryPages[(name ?? '/').replaceFirst('/', '')];
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: page == null ? '/' : '/${page.id}'),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => GalleryShell(page: page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GalleryScope(
      family: _family,
      onFamilyChanged: (family) => setState(() => _family = family),
      mode: _mode,
      onModeChanged: (mode) => setState(() => _mode = mode),
      child: MaterialApp(
        title: 'PanelUI for Flutter',
        debugShowCheckedModeBanner: false,
        theme: _material(_family.light),
        darkTheme: _material(_family.dark),
        themeMode: _mode,
        onGenerateRoute: (settings) => _route(settings.name),
        // One route, not the stack of its path's prefixes.
        onGenerateInitialRoutes: (name) => [_route(name)],
      ),
    );
  }
}

void _open(BuildContext context, String? pageId) =>
    Navigator.of(context).pushReplacementNamed('/${pageId ?? ''}');

/// The frame around every page: a sidebar beside it on a wide screen, a top
/// bar above it on a narrow one.
class GalleryShell extends StatelessWidget {
  const GalleryShell({super.key, this.page});

  /// The page shown. Null shows the overview.
  final GalleryPage? page;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = page == null
                ? const _Overview()
                : _PageView(page: page!);
            if (constraints.maxWidth >= 960) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 264, child: _Sidebar(current: page?.id)),
                  const PanelSeparator(orientation: Axis.vertical),
                  Expanded(child: content),
                ],
              );
            }
            return Column(
              children: [
                _TopBar(page: page),
                const PanelSeparator(),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Row(
                spacing: 8,
                children: const [
                  Expanded(child: _Brand()),
                  _ModeToggle(),
                ],
              ),
              const _FamilyPicker(),
            ],
          ),
        ),
        Expanded(
          child: PanelScrollFade(
            size: 24,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                _NavList(
                  current: current,
                  onSelect: (id) => _open(context, id),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.page});

  final GalleryPage? page;

  void _showNavigation(BuildContext context) {
    showPanelBottomSheet<void>(
      context,
      size: PanelBottomSheetSize.full,
      builder: (sheetContext) => Column(
        children: [
          const PanelBottomSheetHeader(title: Text('Components')),
          Expanded(
            child: PanelBottomSheetBody(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              spacing: 16,
              children: [
                const _FamilyPicker(),
                _NavList(
                  current: page?.id,
                  onSelect: (id) {
                    Navigator.of(sheetContext).pop();
                    _open(context, id);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        spacing: 4,
        children: [
          PanelButton(
            size: PanelButtonSize.icon,
            variant: PanelButtonVariant.ghost,
            semanticLabel: 'Components',
            onPressed: () => _showNavigation(context),
            child: const PanelIcon(PanelIcons.menu),
          ),
          const Expanded(child: _Brand()),
          const _ModeToggle(),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context, null),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            PanelText(
              'PanelUI for Flutter',
              size: PanelTextSize.base,
              weight: FontWeight.w600,
            ),
            PanelBadge(
              size: PanelBadgeSize.sm,
              variant: PanelBadgeVariant.secondary,
              child: Text('unofficial'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel, Moon or Grass: the three segments share the width.
class _FamilyPicker extends StatelessWidget {
  const _FamilyPicker();

  @override
  Widget build(BuildContext context) {
    final scope = GalleryScope.of(context);
    final brightness = PanelTheme.of(context).brightness;
    return PanelButtonGroup(
      size: PanelButtonSize.xs,
      variant: PanelButtonVariant.ghost,
      fullWidth: true,
      children: [
        for (final family in PanelThemeFamily.values)
          PanelButton(
            variant: family == scope.family
                ? PanelButtonVariant.secondary
                : null,
            leading: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: family.resolve(brightness).colors.primary,
                shape: BoxShape.circle,
              ),
            ),
            onPressed: () => scope.onFamilyChanged(family),
            child: Text(family.name),
          ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context) {
    final scope = GalleryScope.of(context);
    final dark = PanelTheme.of(context).isDark;
    return PanelButton(
      size: PanelButtonSize.xs,
      variant: PanelButtonVariant.outline,
      semanticLabel: dark ? 'Use the light theme' : 'Use the dark theme',
      onPressed: () =>
          scope.onModeChanged(dark ? ThemeMode.light : ThemeMode.dark),
      child: PanelIcon(dark ? PanelIcons.sun : PanelIcons.moon, size: 14),
    );
  }
}

/// The categories and their pages, the current one marked.
class _NavList extends StatelessWidget {
  const _NavList({required this.current, required this.onSelect});

  final String? current;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        _NavItem(
          title: 'Overview',
          selected: current == null,
          onPressed: () => onSelect(null),
        ),
        for (final category in galleryCategories)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 2,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                child: PanelText(
                  category.title.toUpperCase(),
                  size: PanelTextSize.xs,
                  weight: FontWeight.w500,
                  muted: true,
                  style: const TextStyle(letterSpacing: 0.6),
                ),
              ),
              for (final page in category.pages)
                _NavItem(
                  title: page.title,
                  selected: page.id == current,
                  onPressed: () => onSelect(page.id),
                ),
            ],
          ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.title,
    required this.selected,
    required this.onPressed,
  });

  final String title;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final radius = BorderRadius.circular(theme.radii.md);
    return PanelPressable(
      onPressed: onPressed,
      pressScale: 1,
      selected: selected,
      focusRingRadius: radius,
      builder: (context, state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected || state.hovered || state.pressed
              ? c.accent
              : const Color(0x00000000),
          borderRadius: radius,
        ),
        child: PanelText(
          title,
          size: PanelTextSize.sm,
          weight: selected ? FontWeight.w500 : FontWeight.w400,
          color: selected || state.hovered ? c.foreground : c.mutedForeground,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// A component's page: its title, then each demo in a preview well.
class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final GalleryPage page;

  @override
  Widget build(BuildContext context) {
    final demos = page.demos;
    final single = demos.length == 1;
    return _Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            PanelText.h3(page.title),
            if (single) PanelText(demos.single.description, muted: true),
          ],
        ),
        for (final demo in demos)
          GallerySection(demo: demo, showTitle: !single),
      ],
    );
  }
}

/// The landing page: what this is, then every component by category.
class _Overview extends StatelessWidget {
  const _Overview();

  @override
  Widget build(BuildContext context) {
    final count = galleryCategories.fold<int>(
      0,
      (sum, category) => sum + category.pages.length,
    );
    return _Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            const PanelText.h2('PanelUI for Flutter'),
            PanelText.lead(
              'An unofficial port of PanelUI: its tokens, its three theme '
              'families and its motion, in Flutter. $count pages of '
              'components to press, drag and tab through. Switch the theme '
              'family and the brightness from the controls at any time.',
            ),
          ],
        ),
        for (final category in galleryCategories)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              PanelText.h5(category.title),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 560 ? 2 : 1;
                  final width =
                      (constraints.maxWidth - 12 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final page in category.pages)
                        SizedBox(
                          width: width,
                          child: PanelItem(
                            variant: PanelItemVariant.outline,
                            title: Text(page.title),
                            description: Text(
                              page.demos.first.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => _open(context, page.id),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}

/// A centred, scrolling column of page content.
class _Column extends StatelessWidget {
  const _Column({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 40,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
