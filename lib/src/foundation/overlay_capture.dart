import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

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
  return (child) {
    final base = _OverlayBase(child: child);
    return captured.wrap(
      carry ? PanelTheme(data: local.data, child: base) : base,
    );
  };
}

/// Starts an overlay from PanelUI's base text (16pt in the foreground colour)
/// and a plain icon theme.
///
/// The capture above also carries the opener's `DefaultTextStyle` and
/// `IconTheme`, so without this a sheet opened from inside a card would set
/// its bare text at the card's 14pt.
class _OverlayBase extends StatelessWidget {
  const _OverlayBase({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return DefaultTextStyle(
      style: theme.typography.style(
        PanelTextSize.base,
        color: theme.colors.foreground,
      ),
      child: IconTheme(
        data: IconThemeData(color: theme.colors.foreground),
        child: child,
      ),
    );
  }
}
