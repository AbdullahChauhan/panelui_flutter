import 'package:flutter/material.dart';

import 'panel_theme_data.dart';

/// Provides a [PanelThemeData] to the components below it.
///
/// Most apps do not need this widget: pass
/// `PanelThemeData.panelLight.toMaterialTheme()` as the `MaterialApp` theme
/// and every component finds its theme there. Use [PanelTheme] to theme a
/// subtree differently, or in an app without a Material theme.
class PanelTheme extends StatelessWidget {
  /// Applies [data] to [child].
  const PanelTheme({super.key, required this.data, required this.child});

  /// The theme for this subtree.
  final PanelThemeData data;

  /// The subtree.
  final Widget child;

  /// The nearest theme: an enclosing [PanelTheme], then the extension on the
  /// Material [Theme], then the Panel family in the platform's brightness.
  static PanelThemeData of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_PanelThemeScope>();
    if (scope != null) return scope.data;
    final extension = Theme.of(context).extension<PanelThemeData>();
    if (extension != null) return extension;
    final brightness =
        MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light;
    return brightness == Brightness.dark
        ? PanelThemeData.panelDark
        : PanelThemeData.panelLight;
  }

  @override
  Widget build(BuildContext context) {
    return _PanelThemeScope(
      data: data,
      child: IconTheme.merge(
        data: IconThemeData(color: data.colors.foreground),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: data.colors.foreground,
            fontFamily: data.typography.fontFamily,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PanelThemeScope extends InheritedWidget {
  const _PanelThemeScope({required this.data, required super.child});

  final PanelThemeData data;

  @override
  bool updateShouldNotify(_PanelThemeScope oldWidget) => data != oldWidget.data;
}

/// Animates between themes when [data] changes, so a switch from light to
/// dark crossfades every token instead of snapping.
class AnimatedPanelTheme extends ImplicitlyAnimatedWidget {
  /// Animates [child]'s theme to [data].
  const AnimatedPanelTheme({
    super.key,
    required this.data,
    required this.child,
    super.curve = Curves.easeInOut,
    super.duration = const Duration(milliseconds: 250),
    super.onEnd,
  });

  /// The target theme.
  final PanelThemeData data;

  /// The subtree.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedPanelTheme> createState() =>
      _AnimatedPanelThemeState();
}

class _AnimatedPanelThemeState
    extends AnimatedWidgetBaseState<AnimatedPanelTheme> {
  _PanelThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data =
        visitor(
              _data,
              widget.data,
              (dynamic value) =>
                  _PanelThemeDataTween(begin: value as PanelThemeData),
            )
            as _PanelThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) {
    return PanelTheme(data: _data!.evaluate(animation), child: widget.child);
  }
}

class _PanelThemeDataTween extends Tween<PanelThemeData> {
  _PanelThemeDataTween({super.begin});

  @override
  PanelThemeData lerp(double t) => begin!.lerp(end, t);
}

/// Shorthand for [PanelTheme.of].
extension PanelThemeContext on BuildContext {
  /// The nearest [PanelThemeData].
  PanelThemeData get panelTheme => PanelTheme.of(this);
}
