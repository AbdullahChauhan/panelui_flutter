import '../gallery/gallery.dart';
import 'core_demos.dart';
import 'navigation_demos.dart';
import 'overlay_demos.dart';
import 'popup_demos.dart';
import 'selection_demos.dart';

/// Every demo in the gallery, in display order.
final List<GalleryDemo> galleryDemos = [
  ...coreDemos,
  ...selectionDemos,
  ...navigationDemos,
  ...overlayDemos,
  ...popupDemos,
];
