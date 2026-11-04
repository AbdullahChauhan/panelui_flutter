import '../gallery/gallery.dart';
import 'display_demos.dart';
import 'form_demos.dart';
import 'foundation_demos.dart';
import 'navigation_demos.dart';
import 'overlay_demos.dart';
import 'popup_demos.dart';
import 'selection_demos.dart';

/// Every demo, by id.
final Map<String, GalleryDemo> galleryDemos = {
  for (final demo in [
    ...foundationDemos,
    ...displayDemos,
    ...formDemos,
    ...selectionDemos,
    ...navigationDemos,
    ...overlayDemos,
    ...popupDemos,
  ])
    demo.id: demo,
};

/// A page of the gallery: one component, or a pair best seen together.
class GalleryPage {
  const GalleryPage(this.id, this.demoIds, {String? title}) : _title = title;

  /// The page's address: `#/<id>`.
  final String id;

  /// The demos on the page, in order.
  final List<String> demoIds;

  final String? _title;

  /// The page title; a single-demo page takes its demo's.
  String get title => _title ?? galleryDemos[demoIds.first]!.title;

  /// The demos themselves.
  List<GalleryDemo> get demos => [for (final id in demoIds) galleryDemos[id]!];
}

/// A sidebar section. The groups are PanelUI's own categories.
class GalleryCategory {
  const GalleryCategory(this.title, this.pages);

  final String title;
  final List<GalleryPage> pages;
}

const List<GalleryCategory> galleryCategories = [
  GalleryCategory('Foundations', [
    GalleryPage('icons', ['icons']),
    GalleryPage('typography', ['typography']),
  ]),
  GalleryCategory('Actions', [
    GalleryPage('button', ['button']),
    GalleryPage('button-group', ['button-group']),
    GalleryPage('chip', ['chip']),
    GalleryPage('menu', ['menu']),
    GalleryPage('toggle-button', ['toggle-button']),
  ]),
  GalleryCategory('Forms', [
    GalleryPage('input', ['input']),
    GalleryPage('switch-checkbox', ['switch-checkbox']),
    GalleryPage('radio-group', ['radio-group']),
    GalleryPage('select', ['select']),
    GalleryPage('slider', ['slider']),
    GalleryPage('field', ['field']),
    GalleryPage('otp-number', ['otp-number']),
    GalleryPage('theme-selector', ['theme-selector']),
  ]),
  GalleryCategory('Feedback', [
    GalleryPage('alert', ['alert']),
    GalleryPage('badge', ['badge']),
    GalleryPage('empty-state', ['empty-state']),
    GalleryPage('meter', ['meter']),
    GalleryPage('progress', ['progress']),
    GalleryPage('loading', ['loading']),
  ]),
  GalleryCategory('Overlays', [
    GalleryPage('dialog', ['dialog']),
    GalleryPage('bottom-sheet', ['bottom-sheet']),
    GalleryPage('toast', ['toast']),
    GalleryPage('popover', ['popover']),
    GalleryPage('tooltip', ['tooltip']),
  ]),
  GalleryCategory('Navigation', [
    GalleryPage('tabs', [
      'tabs',
      'tabs-sizes',
      'tabs-scrollable',
      'tabs-expanding',
    ], title: 'Tabs'),
    GalleryPage('breadcrumb', ['breadcrumb']),
    GalleryPage('pagination', ['pagination']),
    GalleryPage('steps', ['steps']),
  ]),
  GalleryCategory('Layout', [
    GalleryPage('accordion', [
      'accordion',
      'collapsible',
    ], title: 'Accordion and Collapsible'),
    GalleryPage('card', ['card']),
    GalleryPage('item', ['item']),
    GalleryPage('surface', ['surface']),
  ]),
  GalleryCategory('Media', [
    GalleryPage('avatar', ['avatar']),
  ]),
];

/// Every page, by id.
final Map<String, GalleryPage> galleryPages = {
  for (final category in galleryCategories)
    for (final page in category.pages) page.id: page,
};
