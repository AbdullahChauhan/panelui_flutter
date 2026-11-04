import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';

/// Carries the themes in force at [from] over to an overlay that will be
/// built under [to], usually a navigator's or an overlay's context.
///
/// An overlay is built far from where it was asked for, so a subtree themed
/// on its own (a `PanelTheme` around one section of a screen) would
/// otherwise open a dialog in the app's theme rather than its own. Only what
/// lies between the two contexts is carried, so an overlay opened under the
/// app's own theme keeps following it when that theme changes.
///
/// Internal to the overlay components; not exported from the package.
Widget Function(Widget child) panelCaptureThemes(
  BuildContext from,
  BuildContext to,
) {
  final captured = InheritedTheme.capture(from: from, to: to);
  final local = from.findAncestorWidgetOfExactType<PanelTheme>();
  final host = to.findAncestorWidgetOfExactType<PanelTheme>();
  final carry = local != null && !identical(local, host);
  return (child) =>
      captured.wrap(carry ? PanelTheme(data: local.data, child: child) : child);
}
