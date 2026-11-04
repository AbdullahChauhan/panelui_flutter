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
  /// 32pt targets with 12px numbers, still pressed like 44pt ones: a press
  /// up to 6pt outside a target reaches it.
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
    final labelled = widget.variant == PanelPaginationVariant.simple;

    Widget arrow(int step) => _PaginationArrow(
      step: step,
      size: size,
      label: step < 0 ? widget.previousLabel : widget.nextLabel,
      labelled: labelled,
      enabled: enabled && page + step >= 1 && page + step <= count,
      onPressed: () => _goTo(page + step),
    );

    final controls = <Widget>[
      if (widget.showControls) arrow(-1),
      if (widget.variant == PanelPaginationVariant.numbers)
        for (final entry in panelPaginationRange(
          count: count,
          page: page,
          siblings: widget.siblings,
          boundaries: widget.boundaries,
        ))
          switch (entry) {
            PanelPaginationPage(:final number) => _PaginationPageTarget(
              number: number,
              size: size,
              current: number == page,
              enabled: enabled,
              onPressed: () => _goTo(number),
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
        _PaginationSummary(page: page, count: count, size: size),
      if (widget.showControls) arrow(1),
    ];

    // A run too wide for its space keeps its leading edge and is clipped at
    // the trailing one, which at least looks deliberate; a centred row that
    // overflowed would hang off both ends.
    final run = UnconstrainedBox(
      constrainedAxis: Axis.vertical,
      alignment: AlignmentDirectional.centerStart,
      clipBehavior: Clip.hardEdge,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // `gap-1`, and `gap-0.5` small.
        spacing: size == PanelPaginationSize.sm ? 2 : 4,
        children: controls,
      ),
    );

    final leading = widget.leading;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.navigation,
      label: widget.semanticLabel,
      child: leading == null
          ? Center(heightFactor: 1, child: run)
          : _LeadingRow(
              leading: _PaginationScope(
                page: page,
                size: size,
                child: DefaultTextStyle(
                  style: _mutedStyle(theme, size),
                  child: leading,
                ),
              ),
              run: run,
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

  /// `1–20 of 240`, or `None` for an empty set, or nothing until both
  /// [pageSize] and [total] are known.
  String _span(int page) {
    final rows = pageSize;
    final all = total;
    if (rows == null || all == null) return '';
    if (all <= 0) return 'None';
    final from = (page - 1) * rows + 1;
    // The last page is nearly always short; counting a full one past the end
    // is the classic off-by-a-page-size.
    final to = math.min(page * rows, all);
    return '$from–$to of $all';
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final scope = context
        .dependOnInheritedWidgetOfExactType<_PaginationScope>();
    final style = _mutedStyle(theme, scope?.size ?? PanelPaginationSize.md);
    final custom = child;
    return Semantics(
      container: true,
      child: custom != null
          ? DefaultTextStyle(style: style, child: custom)
          : Text(_span(page ?? scope?.page ?? 1), style: style),
    );
  }
}

List<int> _range(int start, int end) =>
    end < start ? const [] : [for (var i = start; i <= end; i++) i];

/// The side of a target: 44pt (`h-11 min-w-11`), or 32pt (`h-8 min-w-8`)
/// small.
double _targetExtent(PanelPaginationSize size) =>
    size == PanelPaginationSize.sm ? 32 : 44;

/// The size of an arrow or an ellipsis glyph.
double _glyphSize(PanelPaginationSize size) =>
    size == PanelPaginationSize.sm ? 16 : 20;

/// What the small size gives back outside its paint: exactly the difference
/// between its 32pt targets and the 44pt a finger reliably hits. Like
/// PanelUI's, it reaches only as far as the row's own bounds, so in practice
/// it takes presses in the gaps between targets.
const EdgeInsets _smallHitSlop = EdgeInsets.all(6);

EdgeInsets? _hitSlop(PanelPaginationSize size) =>
    size == PanelPaginationSize.sm ? _smallHitSlop : null;

/// A dead target's opacity (`opacity-[0.4]`).
const double _disabledOpacity = 0.4;

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

/// The row with leading content: the content on the leading edge and the
/// run on the trailing one, 12pt apart at the least (`justify-between
/// gap-3`).
///
/// The run is laid out first, bounded by the row's width so that it clips
/// rather than overflows, and the content takes what is left. A row hands an
/// unflexed child unbounded width, so the bound is read from the
/// constraints.
class _LeadingRow extends StatelessWidget {
  const _LeadingRow({required this.leading, required this.run});

  final Widget leading;
  final Widget run;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 12,
        children: [
          Flexible(child: leading),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: run,
          ),
        ],
      ),
    );
  }
}

/// The square-ish target every page number and arrow is drawn in: at least
/// as wide as it is tall, 4pt of padding either side unless [paddingX] says
/// otherwise, filled with the primary colour when [current].
class _PaginationTarget extends StatelessWidget {
  const _PaginationTarget({
    required this.size,
    required this.enabled,
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
    this.current,
    this.paddingX = 4,
  });

  final PanelPaginationSize size;
  final bool enabled;

  /// Whether this is the page you are on, announced as its selected state.
  /// Null for an arrow, which has no such state.
  final bool? current;
  final String semanticLabel;
  final double paddingX;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final extent = _targetExtent(size);
    final radius = BorderRadius.circular(theme.radii.lg);
    return PanelPressable(
      onPressed: enabled ? onPressed : null,
      semanticLabel: semanticLabel,
      // The page you are on is announced as selected, so it is spoken as
      // state rather than only painted.
      selected: current,
      hitSlop: _hitSlop(size),
      focusRingRadius: radius,
      child: Opacity(
        opacity: enabled ? 1 : _disabledOpacity,
        child: Container(
          height: extent,
          constraints: BoxConstraints(minWidth: extent),
          padding: EdgeInsets.symmetric(horizontal: paddingX),
          decoration: current ?? false
              ? BoxDecoration(color: theme.colors.primary, borderRadius: radius)
              : null,
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    );
  }
}

/// A page number, announced as "Page 3" and as selected while it is the
/// page you are on.
class _PaginationPageTarget extends StatelessWidget {
  const _PaginationPageTarget({
    required this.number,
    required this.size,
    required this.current,
    required this.enabled,
    required this.onPressed,
  });

  final int number;
  final PanelPaginationSize size;
  final bool current;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    return _PaginationTarget(
      size: size,
      enabled: enabled,
      current: current,
      semanticLabel: 'Page $number',
      onPressed: onPressed,
      child: Text(
        '$number',
        style: _labelStyle(
          theme,
          size,
          current ? c.primaryForeground : c.foreground,
        ),
      ),
    );
  }
}

/// The previous or next arrow: the same button pointed the other way, with
/// its word written beside it when [labelled].
///
/// The chevrons turn around in a right-to-left row, where the previous page
/// is to the right. PanelUI swaps its chevrons for that as well as mirroring
/// them, which turns them back to face each other; here they turn once.
class _PaginationArrow extends StatelessWidget {
  const _PaginationArrow({
    required this.step,
    required this.size,
    required this.label,
    required this.labelled,
    required this.enabled,
    required this.onPressed,
  });

  /// -1 for previous, 1 for next.
  final int step;
  final PanelPaginationSize size;
  final String label;
  final bool labelled;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final foreground = theme.colors.foreground;
    final previous = step < 0;
    final glyph = PanelIcon(
      previous ? PanelIcons.chevronLeft : PanelIcons.chevronRight,
      size: _glyphSize(size),
      color: foreground,
    );
    final word = labelled
        ? Text(label, style: _labelStyle(theme, size, foreground))
        : null;
    return _PaginationTarget(
      size: size,
      enabled: enabled,
      semanticLabel: label,
      // A labelled arrow is a wider button (`px-3`, `px-2` small).
      paddingX: labelled ? (size == PanelPaginationSize.sm ? 8 : 12) : 4,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: previous ? [glyph, ?word] : [?word, glyph],
      ),
    );
  }
}

/// `3 / 12`: where you are, in the space the two arrows leave between them,
/// and read out as "Page 3 of 12". Digits and a slash rather than the
/// sentence, which a phone has no room for and which would need translating.
class _PaginationSummary extends StatelessWidget {
  const _PaginationSummary({
    required this.page,
    required this.count,
    required this.size,
  });

  final int page;
  final int count;
  final PanelPaginationSize size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Page $page of $count',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$page / $count',
            style: _mutedStyle(PanelTheme.of(context), size),
          ),
        ),
      ),
    );
  }
}

/// The gap in the run, and a way across it: a press jumps [jump] pages
/// towards the end the gap is on.
///
/// It keeps its full opacity in a disabled row, as PanelUI's does: its glyph
/// is muted already, and only the targets dim.
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
    return PanelPressable(
      onPressed: enabled ? onPressed : null,
      semanticLabel: towardsStart ? 'Back $jump pages' : 'Forward $jump pages',
      hitSlop: _hitSlop(size),
      focusRingRadius: BorderRadius.circular(theme.radii.lg),
      child: SizedBox.square(
        dimension: _targetExtent(size),
        child: Center(
          child: PanelIcon(
            PanelIcons.ellipsis,
            size: _glyphSize(size),
            color: theme.colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
