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
  }) : assert(itemsBeforeCollapse >= 0),
       assert(itemsAfterCollapse >= 0);

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

  /// The crumbs to draw: all of them, or the two ends of a long trail with
  /// an ellipsis between. The middle folds only when hiding it shortens the
  /// row: keeping all but one crumb and adding an ellipsis saves nothing.
  List<Widget> get _sequence {
    final max = maxItems;
    final count = children.length;
    if (max == null ||
        count <= max ||
        itemsBeforeCollapse + itemsAfterCollapse >= count) {
      return children;
    }
    return [
      ...children.take(itemsBeforeCollapse),
      _BreadcrumbEllipsis(onPressed: onEllipsisPressed),
      ...children.skip(count - itemsAfterCollapse),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final muted = theme.colors.mutedForeground;
    final sequence = _sequence;
    // Hidden from screen readers: the order of the crumbs already says how
    // they nest.
    final gap = ExcludeSemantics(
      child: IconTheme(
        data: IconThemeData(color: muted, size: _iconSize),
        child: DefaultTextStyle(
          style: _crumbStyle(theme, size, color: muted),
          child: separator ?? const PanelIcon(PanelIcons.chevronRight),
        ),
      ),
    );

    // A labelled navigation landmark holding a list of crumbs, the shape of
    // PanelUI's labelled trail around its `list`.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.navigation,
      label: semanticLabel,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.list,
        child: _BreadcrumbScope(
          size: size,
          child: Wrap(
            spacing: _gap,
            runSpacing: _gap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < sequence.length; i++)
                Semantics(
                  container: true,
                  explicitChildNodes: true,
                  role: SemanticsRole.listItem,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: _gap,
                    children: [if (i > 0) gap, sequence[i]],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A crumb you can go back to: an ancestor of the current page.
///
/// It is muted, so the current page, which is not a link, reads as the
/// emphasised end of the trail, and it dims to 60% while pressed rather than
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
      pressOpacity: _linkPressOpacity,
      isButton: false,
      semanticLabel: semanticLabel,
      focusRingRadius: BorderRadius.circular(theme.radii.sm),
      link: true,
      child: IconTheme(
        data: IconThemeData(color: color, size: _iconSize),
        child: DefaultTextStyle(
          style: _crumbStyle(theme, size, color: color),
          child: child,
        ),
      ),
    );
  }
}

/// The last crumb: the page you are on.
///
/// Not a link, since you cannot go where you already are. It is drawn in the
/// full foreground so the trail resolves to it. PanelUI marks it with
/// `aria-current="page"`, which Flutter's semantics has no flag for, so it is
/// announced as the selected crumb instead.
class PanelBreadcrumbPage extends StatelessWidget {
  /// Creates the current-page crumb.
  const PanelBreadcrumbPage({super.key, required this.child});

  /// The label, usually a [Text].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final size = _BreadcrumbScope.sizeOf(context);
    final color = theme.colors.foreground;
    return Semantics(
      container: true,
      selected: true,
      child: IconTheme(
        data: IconThemeData(color: color, size: _iconSize),
        child: DefaultTextStyle(
          style: _crumbStyle(
            theme,
            size,
            color: color,
            weight: FontWeight.w500,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The gap between a crumb and the separators either side of it, and between
/// the rows of a wrapped trail (`gap-1.5`).
const double _gap = 6;

/// The separator chevron's size, and the size an icon in a crumb defaults to.
const double _iconSize = 14;

/// How far a link dims while pressed.
const double _linkPressOpacity = 0.6;

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

/// Stands in for the crumbs a collapsed trail hides: an ellipsis in a box
/// 20pt tall with 2pt either side (`h-5 px-0.5`). Labelled, so the collapse
/// is not silent to a screen reader, and pressed down to 92% when it opens a
/// menu.
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
