import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

/// Every built-in theme, for tests that check a component in each one.
const List<PanelThemeData> allThemes = [
  PanelThemeData.panelLight,
  PanelThemeData.panelDark,
  PanelThemeData.moonLight,
  PanelThemeData.moonDark,
  PanelThemeData.grassLight,
  PanelThemeData.grassDark,
];

/// Wraps [child] in a `MaterialApp` themed with [theme], centred on a
/// scaffold, the way an app would host it.
Widget wrap(Widget child, {PanelThemeData theme = PanelThemeData.panelLight}) {
  return MaterialApp(
    theme: theme.toMaterialTheme(),
    home: Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}
