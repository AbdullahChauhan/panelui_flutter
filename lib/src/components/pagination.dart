import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_theme_data.dart';
import '../theme/panel_typography.dart';

/// Which presentation a [PanelPagination] draws.
enum PanelPaginationVariant {
  /// The full run of page numbers, with the middle folded into ellipses.
  numbers,

  /// The two arrows with `3 / 12` between them. Digits and a slash, so there
  /// is no sentence to translate.
  compact,

  /// Labelled Previous and Next, for a flow you walk rather than jump around
  /// in: a wizard, an article, a set of onboarding cards.
  simple,
}

/// How big the targets of a [PanelPagination] are.
enum PanelPaginationSize {
  /// 32pt targets with 12px numbers.
  sm,

  /// 44pt targets with 14px numbers, the default.
  md,
}

/// One entry in a pagination run: a page, or a gap folded into an ellipsis.
///
/// Returned by [panelPaginationRange].
sealed class PanelPaginationEntry {
  const PanelPaginationEntry();
}

/// A page number in a pagination run.
final class PanelPaginationPage extends PanelPaginationEntry {
  /// A page, numbered from 1.
  const PanelPaginationPage(this.number);

  /// The page's number, from 1.
  final int number;

  @override
  bool operator ==(Object other) =>
      other is PanelPaginationPage && other.number == number;

  @override
  int get hashCode => number.hashCode;

  @override
  String toString() => '$number';
}

/// A gap in a pagination run, shown as an ellipsis.
final class PanelPaginationGap extends PanelPaginationEntry {
  /// A gap; [towardsStart] is true for the one nearer page 1.
  const PanelPaginationGap({required this.towardsStart});

  /// Whether the gap runs towards page 1 rather than towards the last page.
  final bool towardsStart;

  @override
  bool operator ==(Object other) =>
      other is PanelPaginationGap && other.towardsStart == towardsStart;

  @override
  int get hashCode => towardsStart.hashCode;

  @override
  String toString() => towardsStart ? 'start-ellipsis' : 'end-ellipsis';
}

List<int> _range(int start, int end) =>
    end < start ? const [] : [for (var i = start; i <= end; i++) i];

/// Which page numbers a [PanelPagination] draws, and where the gaps go.
///
/// The run is a fixed width rather than a sliding window: the same number of
/// targets whichever page you are on, so the row does not reflow under the
/// finger and the arrow you were aiming at stays put. [boundaries] pins the
/// ends, [siblings] pads either side of the current page, and a gap of
/// exactly one page is drawn as that page, since an ellipsis hiding a single
/// number is longer than the number.
///
/// Exposed so a control of your own can draw the same run.
List<PanelPaginationEntry> panelPaginationRange({
  required int count,
  required int page,
  int siblings = 1,
  int boundaries = 1,
}) {
  final startPages = _range(1, math.min(boundaries, count));
  final endPages = _range(
    math.max(count - boundaries + 1, boundaries + 1),
    count,
  );

  final siblingsStart = math.max(
    math.min(page - siblings, count - boundaries - siblings * 2 - 1),
    boundaries + 2,
  );
  final siblingsEnd = math.min(
    math.max(page + siblings, boundaries + siblings * 2 + 2),
    endPages.isNotEmpty ? endPages.first - 2 : count - 1,
  );

  return [
    for (final p in startPages) PanelPaginationPage(p),
    if (siblingsStart > boundaries + 2)
      const PanelPaginationGap(towardsStart: true)
    else if (boundaries + 1 < count - boundaries)
      PanelPaginationPage(boundaries + 1),
    for (final p in _range(siblingsStart, siblingsEnd)) PanelPaginationPage(p),
    if (siblingsEnd < count - boundaries - 1)
      const PanelPaginationGap(towardsStart: false)
    else if (count - boundaries > boundaries)
      PanelPaginationPage(count - boundaries),
    for (final p in endPages) PanelPaginationPage(p),
  ];
}

/// Moving through a result set one page at a time.
///
/// ```dart
/// PanelPagination(count: 12, page: page, onChanged: (p) => setState(() => page = p))
/// ```
///
/// It owns the arithmetic and nothing else: given how many pages there are
/// and which one you are on, it works out which numbers to show, where the
/// gaps fall and which controls are dead at the ends. It never fetches and
/// never slices, because the data is yours.
///
/// An ellipsis is a button, not punctuation: tapping one jumps [pageJump]
/// pages towards the end it is on. A change ticks the selection haptic.
///
/// Given [leading] content (a [PanelPaginationStatus], say), the controls
/// move to the trailing end of the row; otherwise they are centred. A run
/// too wide for its space keeps its start and is clipped at its end.
class PanelPagination extends StatefulWidget {
  /// Creates a pagination row.
  const PanelPagination({
    super.key,
    required this.count,
    this.page,
    this.initialPage = 1,
    this.onChanged,
    this.variant = PanelPaginationVariant.numbers,
    this.size = PanelPaginationSize.md,
    this.siblings = 1,
    this.boundaries = 1,
    this.showControls = true,
    this.pageJump = 5,
    this.enabled = true,
    this.leading,
    this.semanticLabel = 'Pagination',
    this.previousLabel = 'Previous',
    this.nextLabel = 'Next',
  }) : assert(count >= 0);

  /// How many pages there are. Pages are numbered from 1, so this is also
  /// the last page's number.
  final int count;

  /// The page being shown. When null the row keeps its own page, starting
  /// from [initialPage].
  final int? page;

  /// The page to start on, when [page] is null.
  final int initialPage;

  /// Called with the page that was asked for, already clamped to [count].
  final ValueChanged<int>? onChanged;

  /// Which presentation to draw.
  final PanelPaginationVariant variant;

  /// How big the targets are.
  final PanelPaginationSize size;

  /// How many pages to keep either side of the current one.
  final int siblings;

  /// How many pages to keep pinned at each end of the run.
  final int boundaries;

  /// Show the previous and next arrows. Turn them off only where something
  /// else moves the page, such as a swipe.
  final bool showControls;

  /// How far tapping an ellipsis jumps.
  final int pageJump;

  /// Whether the row responds. A disabled row is dimmed, for a page that is
  /// still loading.
  final bool enabled;

  /// Content on the leading edge of the row, such as a
  /// [PanelPaginationStatus].
  final Widget? leading;

  /// The row's accessible name.
  final String semanticLabel;

  /// The previous arrow's label: announced, and written beside the arrow in
  /// the simple variant.
  final String previousLabel;

  /// The next arrow's label: announced, and written beside the arrow in the
  /// simple variant.
  final String nextLabel;

  @override
  State<PanelPagination> createState() => _PanelPaginationState();
}

class _PanelPaginationState extends State<PanelPagination> {
  late int _internal = widget.initialPage;

  /// Clamped on the way out as well as in: [PanelPagination.count] can shrink
  /// under a controlled page, and a page past the end would light nothing
  /// and disable both arrows at once.
  int get _page =>
      math.min(math.max(widget.page ?? _internal, 1), widget.count);

  void _goTo(int next) {
    final clamped = math.min(math.max(next, 1), widget.count);
    if (clamped == _page || !widget.enabled) return;
    // On the frame of the press rather than after the fetch: the tick is
    // what ties the feeling to the tap.
    HapticFeedback.selectionClick();
    if (widget.page == null) setState(() => _internal = clamped);
    widget.onChanged?.call(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final page = _page;
    final count = widget.count;
    final size = widget.size;
    final enabled = widget.enabled;
    final small = size == PanelPaginationSize.sm;

    Widget arrow(int step) {
      final target = page + step;
      final live = enabled && target >= 1 && target <= count;
      final word = step < 0 ? widget.previousLabel : widget.nextLabel;
      final labelled = widget.variant == PanelPaginationVariant.simple;
      final glyph = PanelIcon(
        step < 0 ? PanelIcons.chevronLeft : PanelIcons.chevronRight,
        size: small ? 16 : 20,
        color: theme.colors.foreground,
      );
      final text = Text(
        word,
        style: _labelStyle(theme, size, theme.colors.foreground),
      );
      return _PaginationTarget(
        size: size,
        enabled: live,
        semanticLabel: word,
        horizontalPadding: labelled ? (small ? 8 : 12) : 4,
        onPressed: () => _goTo(target),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: step < 0
              ? [glyph, if (labelled) text]
              : [if (labelled) text, glyph],
        ),
      );
    }

    final children = <Widget>[
      if (widget.showControls) arrow(-1),
      if (widget.variant == PanelPaginationVariant.numbers)
        for (final entry in panelPaginationRange(
          count: count,
          page: page,
          siblings: widget.siblings,
          boundaries: widget.boundaries,
        ))
          switch (entry) {
            PanelPaginationPage(:final number) => _PaginationTarget(
              size: size,
              enabled: enabled,
              current: number == page,
              selected: number == page,
              semanticLabel: 'Page $number',
              horizontalPadding: 4,
              onPressed: () => _goTo(number),
              child: Text(
                '$number',
                style: _labelStyle(
                  theme,
                  size,
                  number == page
                      ? theme.colors.primaryForeground
                      : theme.colors.foreground,
                ),
              ),
            ),
            PanelPaginationGap(:final towardsStart) => _PaginationEllipsis(
              size: size,
              enabled: enabled,
              towardsStart: towardsStart,
              jump: widget.pageJump,
              onPressed: () => _goTo(
                page + (towardsStart ? -widget.pageJump : widget.pageJump),
              ),
            ),
          },
      if (widget.variant == PanelPaginationVariant.compact)
        Semantics(
          container: true,
          label: 'Page $page of $count',
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('$page / $count', style: _mutedStyle(theme, size)),
            ),
          ),
        ),
      if (widget.showControls) arrow(1),
    ];

    // A run too wide for its space keeps its leading edge and is clipped at
    // the trailing one, which at least looks deliberate; a centred row that
    // overflowed would hang off both ends.
    final controls = UnconstrainedBox(
      constrainedAxis: Axis.vertical,
      alignment: AlignmentDirectional.centerStart,
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: small ? 2 : 4,
        children: children,
      ),
    );

    final leading = widget.leading;
    final Widget row = leading == null
        ? Center(heightFactor: 1, child: controls)
        : LayoutBuilder(
            builder: (context, constraints) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 12,
              children: [
                Flexible(
                  child: _PaginationScope(
                    page: page,
                    size: size,
                    child: DefaultTextStyle(
                      style: _mutedStyle(theme, size),
                      child: leading,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: controls,
                ),
              ],
            ),
          );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.navigation,
      label: widget.semanticLabel,
      child: row,
    );
  }
}

TextStyle _labelStyle(
  PanelThemeData theme,
  PanelPaginationSize size,
  Color color,
) => theme.typography
    .style(
      size == PanelPaginationSize.sm ? PanelTextSize.xs : PanelTextSize.sm,
      weight: FontWeight.w500,
      color: color,
    )
    .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

TextStyle _mutedStyle(PanelThemeData theme, PanelPaginationSize size) => theme
    .typography
    .style(
      size == PanelPaginationSize.sm ? PanelTextSize.xs : PanelTextSize.sm,
      color: theme.colors.mutedForeground,
    )
    .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// What a [PanelPaginationStatus] inside a [PanelPagination] reads.
class _PaginationScope extends InheritedWidget {
  const _PaginationScope({
    required this.page,
    required this.size,
    required super.child,
  });

  final int page;
  final PanelPaginationSize size;

  @override
  bool updateShouldNotify(_PaginationScope oldWidget) =>
      page != oldWidget.page || size != oldWidget.size;
}

/// One pressable target: a page number or an arrow.
class _PaginationTarget extends StatelessWidget {
  const _PaginationTarget({
    required this.size,
    required this.enabled,
    required this.semanticLabel,
    required this.horizontalPadding,
    required this.onPressed,
    required this.child,
    this.current = false,
    this.selected,
  });

  final PanelPaginationSize size;
  final bool enabled;
  final bool current;

  /// Announced selected state: set on page numbers, left off the arrows.
  final bool? selected;
  final String semanticLabel;
  final double horizontalPadding;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final extent = size == PanelPaginationSize.sm ? 32.0 : 44.0;
    final radius = BorderRadius.circular(theme.radii.lg);
    return PanelPressable(
      onPressed: enabled ? onPressed : null,
      semanticLabel: semanticLabel,
      // The page you are on is announced as selected, so it is spoken as
      // state rather than only painted.
      selected: selected,
      focusRingRadius: radius,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: extent,
          constraints: BoxConstraints(minWidth: extent),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: current
              ? BoxDecoration(color: theme.colors.primary, borderRadius: radius)
              : null,
          child: Center(widthFactor: 1, child: ExcludeSemantics(child: child)),
        ),
      ),
    );
  }
}

/// The gap in the run, and a way across it.
class _PaginationEllipsis extends StatelessWidget {
  const _PaginationEllipsis({
    required this.size,
    required this.enabled,
    required this.towardsStart,
    required this.jump,
    required this.onPressed,
  });

  final PanelPaginationSize size;
  final bool enabled;
  final bool towardsStart;
  final int jump;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final small = size == PanelPaginationSize.sm;
    final extent = small ? 32.0 : 44.0;
    return PanelPressable(
      onPressed: enabled ? onPressed : null,
      semanticLabel: towardsStart ? 'Back $jump pages' : 'Forward $jump pages',
      focusRingRadius: BorderRadius.circular(theme.radii.lg),
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: SizedBox.square(
          dimension: extent,
          child: Center(
            child: PanelIcon(
              PanelIcons.ellipsis,
              size: small ? 16 : 20,
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// The line that says how much of the set you are looking at: `1–20 of 240`.
///
/// Worth having beside a table, because a page number alone does not say
/// how much is left. Inside a [PanelPagination] (as its `leading`) it reads
/// the current page from the row; [page] overrides that. Given a [child] it
/// shows that instead, for a set whose size is not known yet.
class PanelPaginationStatus extends StatelessWidget {
  /// Creates a status line.
  const PanelPaginationStatus({
    super.key,
    this.page,
    this.pageSize,
    this.total,
    this.child,
  });

  /// The page the span is counted from. Read from the enclosing
  /// [PanelPagination] when null.
  final int? page;

  /// How many rows a page holds.
  final int? pageSize;

  /// How many rows there are altogether.
  final int? total;

  /// Shown in place of the span.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final scope = context
        .dependOnInheritedWidgetOfExactType<_PaginationScope>();
    final size = scope?.size ?? PanelPaginationSize.md;
    final style = _mutedStyle(theme, size);
    final custom = child;
    if (custom != null) {
      return Semantics(
        container: true,
        child: DefaultTextStyle(style: style, child: custom),
      );
    }
    final current = page ?? scope?.page ?? 1;
    final rows = pageSize;
    final all = total;
    String text = '';
    if (rows != null && all != null) {
      if (all <= 0) {
        text = 'None';
      } else {
        final from = (current - 1) * rows + 1;
        // The last page is nearly always short; counting a full one past the
        // end is the classic off-by-a-page-size.
        final to = math.min(current * rows, all);
        text = '$from–$to of $all';
      }
    }
    return Semantics(container: true, child: Text(text, style: style));
  }
}
