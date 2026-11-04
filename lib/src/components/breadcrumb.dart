import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_theme_data.dart';
import '../theme/panel_typography.dart';

/// How dense a [PanelBreadcrumb] is.
enum PanelBreadcrumbSize {
  /// 12px crumbs, for a dense header bar.
  sm,

  /// 14px crumbs, the default.
  md,
}

/// The trail of where you are in a hierarchy: links back up the tree, ending
/// in the page you are on.
///
/// ```dart
/// PanelBreadcrumb(
///   children: [
///     PanelBreadcrumbLink(onPressed: goHome, child: const Text('Home')),
///     PanelBreadcrumbLink(onPressed: goProjects, child: const Text('Projects')),
///     const PanelBreadcrumbPage(child: Text('PanelUI')),
///   ],
/// )
/// ```
///
/// The separators are the trail's job, not yours: a chevron goes between
/// every pair of crumbs and none at the ends. Change the glyph once with
/// [separator] and every gap follows.
///
/// A deep trail does not wrap into a paragraph on a narrow screen: with
/// [maxItems] it keeps the first [itemsBeforeCollapse] and last
/// [itemsAfterCollapse] crumbs and folds the middle into an ellipsis, which
/// [onEllipsisPressed] turns into the handle for a menu of the hidden steps.
class PanelBreadcrumb extends StatelessWidget {
  /// Creates a breadcrumb trail.
  const PanelBreadcrumb({
    super.key,
    required this.children,
    this.size = PanelBreadcrumbSize.md,
    this.separator,
    this.maxItems,
    this.itemsBeforeCollapse = 1,
    this.itemsAfterCollapse = 1,
    this.onEllipsisPressed,
    this.semanticLabel = 'Breadcrumb',
  });

  /// The crumbs, usually [PanelBreadcrumbLink]s ending in a
  /// [PanelBreadcrumbPage].
  final List<Widget> children;

  /// Text density for every crumb.
  final PanelBreadcrumbSize size;

  /// The glyph between crumbs. Defaults to a chevron; a [Text] such as `'/'`
  /// is styled as a muted crumb.
  final Widget? separator;

  /// Collapse the trail once it holds more crumbs than this.
  final int? maxItems;

  /// How many leading crumbs survive a collapse.
  final int itemsBeforeCollapse;

  /// How many trailing crumbs survive a collapse.
  final int itemsAfterCollapse;

  /// Makes the collapsed ellipsis pressable. Without it the ellipsis is a
  /// static marker.
  final VoidCallback? onEllipsisPressed;

  /// The trail's accessible name.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final crumbs = children;

    // Fold the middle only when hiding something shortens the row: keeping
    // all but one crumb and adding an ellipsis saves nothing.
    var sequence = <Widget>[...crumbs];
    final max = maxItems;
    if (max != null &&
        crumbs.length > max &&
        itemsBeforeCollapse + itemsAfterCollapse < crumbs.length) {
      final head = crumbs.take(
        itemsBeforeCollapse < 0 ? 0 : itemsBeforeCollapse,
      );
      final tail = itemsAfterCollapse > 0
          ? crumbs.sublist(crumbs.length - itemsAfterCollapse)
          : const <Widget>[];
      sequence = [
        ...head,
        _BreadcrumbEllipsis(onPressed: onEllipsisPressed),
        ...tail,
      ];
    }

    final separatorStyle = _crumbStyle(
      theme,
      size,
      color: theme.colors.mutedForeground,
    );
    final gap = ExcludeSemantics(
      child: IconTheme(
        data: IconThemeData(color: theme.colors.mutedForeground, size: 14),
        child: DefaultTextStyle(
          style: separatorStyle,
          child: separator ?? const PanelIcon(PanelIcons.chevronRight),
        ),
      ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.navigation,
      label: semanticLabel,
      child: _BreadcrumbScope(
        size: size,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < sequence.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [if (i > 0) gap, sequence[i]],
              ),
          ],
        ),
      ),
    );
  }
}

TextStyle _crumbStyle(
  PanelThemeData theme,
  PanelBreadcrumbSize size, {
  required Color color,
  FontWeight weight = FontWeight.w400,
}) => theme.typography.style(
  size == PanelBreadcrumbSize.sm ? PanelTextSize.xs : PanelTextSize.sm,
  weight: weight,
  color: color,
);

class _BreadcrumbScope extends InheritedWidget {
  const _BreadcrumbScope({required this.size, required super.child});

  final PanelBreadcrumbSize size;

  static PanelBreadcrumbSize sizeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BreadcrumbScope>()?.size ??
      PanelBreadcrumbSize.md;

  @override
  bool updateShouldNotify(_BreadcrumbScope oldWidget) => size != oldWidget.size;
}

/// A crumb you can go back to: an ancestor of the current page.
///
/// It is muted, so the current page, which is not a link, reads as the
/// emphasised end of the trail, and it dims while pressed rather than
/// shrinking. A null [onPressed] leaves it as text that cannot be pressed.
class PanelBreadcrumbLink extends StatelessWidget {
  /// Creates a link crumb.
  const PanelBreadcrumbLink({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
  });

  /// The label, usually a [Text].
  final Widget child;

  /// Called when the crumb is pressed.
  final VoidCallback? onPressed;

  /// An accessible name, for a label that is not text.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final size = _BreadcrumbScope.sizeOf(context);
    final color = theme.colors.mutedForeground;
    return PanelPressable(
      onPressed: onPressed,
      pressScale: 1,
      pressOpacity: 0.6,
      isButton: false,
      semanticLabel: semanticLabel,
      focusRingRadius: BorderRadius.circular(theme.radii.sm),
      child: Semantics(
        link: true,
        child: IconTheme(
          data: IconThemeData(color: color, size: 14),
          child: DefaultTextStyle(
            style: _crumbStyle(theme, size, color: color),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The last crumb: the page you are on.
///
/// Not a link, since you cannot go where you already are. It is drawn in the
/// full foreground so the trail resolves to it, and announced as the selected
/// (current) crumb.
class PanelBreadcrumbPage extends StatelessWidget {
  /// Creates the current-page crumb.
  const PanelBreadcrumbPage({super.key, required this.child});

  /// The label, usually a [Text].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final size = _BreadcrumbScope.sizeOf(context);
    return Semantics(
      container: true,
      selected: true,
      child: IconTheme(
        data: IconThemeData(color: theme.colors.foreground, size: 14),
        child: DefaultTextStyle(
          style: _crumbStyle(
            theme,
            size,
            color: theme.colors.foreground,
            weight: FontWeight.w500,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Stands in for the crumbs a collapsed trail hides. Labelled, so the
/// collapse is not silent to a screen reader.
class _BreadcrumbEllipsis extends StatelessWidget {
  const _BreadcrumbEllipsis({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final glyph = SizedBox(
      height: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Center(
          widthFactor: 1,
          child: PanelIcon(
            PanelIcons.ellipsis,
            size: 16,
            color: theme.colors.mutedForeground,
          ),
        ),
      ),
    );
    if (onPressed == null) {
      return Semantics(container: true, label: 'More', child: glyph);
    }
    return PanelPressable(
      onPressed: onPressed,
      pressScale: 0.92,
      semanticLabel: 'Show more',
      focusRingRadius: BorderRadius.circular(theme.radii.sm),
      child: glyph,
    );
  }
}
