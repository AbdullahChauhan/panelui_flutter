import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
/// scaffold, the way an app would host it. [reduceMotion] turns on the
/// platform's reduced-motion setting for everything below.
Widget wrap(
  Widget child, {
  PanelThemeData theme = PanelThemeData.panelLight,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    theme: theme.toMaterialTheme(),
    builder: reduceMotion
        ? (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: app!,
          )
        : null,
    home: Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

/// Whether the primary focus is [finder]'s widget or inside it.
bool focusIsWithin(WidgetTester tester, Finder finder) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  final target = tester.element(finder);
  if (context == target) return true;
  var found = false;
  context.visitAncestorElements((element) {
    if (element == target) found = true;
    return !found;
  });
  return found;
}
