import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// Whether an empty state stands alone or sits inside content.
enum PanelEmptyStateVariant {
  /// No frame of its own; it fills the space it is given and centres in it:
  /// PanelUI's `default`, for a whole screen or a flex slot.
  plain,

  /// A self-contained bordered block on the card fill, sized to its content,
  /// for an empty state that sits inside content rather than owning a screen.
  card,
}

/// How big an empty state is.
enum PanelEmptyStateSize {
  /// Compact, for a panel or a list inside a page.
  sm,

  /// PanelUI's `default`.
  md,

  /// Large, for a whole screen.
  lg,
}

/// The placeholder shown when a list or a view has nothing in it.
///
/// [icon] is framed in a small card with two ghost cards fanned out behind
/// it; [media] (an illustration, an image) is shown without a frame.
///
/// ```dart
/// PanelEmptyState(
///   icon: const PanelIcon(PanelIcons.folder),
///   title: const Text('No projects yet'),
///   description: const Text('Create a project to get started.'),
///   action: PanelButton(onPressed: create, child: const Text('New project')),
/// )
/// ```
class PanelEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const PanelEmptyState({
    super.key,
    this.variant = PanelEmptyStateVariant.plain,
    this.size = PanelEmptyStateSize.md,
    this.icon,
    this.media,
    this.title,
    this.description,
    this.action,
  });

  /// Frame or no frame.
  final PanelEmptyStateVariant variant;

  /// Scales the padding, media and text together.
  final PanelEmptyStateSize size;

  /// An icon, framed with fanned ghost cards. It is drawn in the muted
  /// foreground at half the frame unless it is given a colour and a size.
  final Widget? icon;

  /// Media shown without a frame, centred in at least the room the icon
  /// frame takes. Ignored when [icon] is set.
  final Widget? media;

  /// The headline.
  final Widget? title;

  /// A line or two of explanation.
  final Widget? description;

  /// What to do about it, usually a button or two, no wider than the text.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final metrics = _EmptyStateMetrics.of(size);
    final body = Padding(
      padding: metrics.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: metrics.gap,
        children: [
          ConstrainedBox(
            constraints: _column,
            child: _Header(
              metrics: metrics,
              icon: icon,
              media: media,
              title: title,
              description: description,
            ),
          ),
          if (action != null)
            ConstrainedBox(constraints: _column, child: action),
        ],
      ),
    );

    if (variant == PanelEmptyStateVariant.plain) {
      return SizedBox(
        width: double.infinity,
        child: Center(child: body),
      );
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(theme.radii.xxl),
        border: Border.all(color: c.border),
      ),
      child: Center(heightFactor: 1, child: body),
    );
  }
}

/// Tailwind's `max-w-sm`: the header and the actions keep to a readable
/// column however wide the empty state is.
const BoxConstraints _column = BoxConstraints(maxWidth: 384);

/// One size of a [PanelEmptyState], from PanelUI's `size` variants and its
/// media's.
class _EmptyStateMetrics {
  const _EmptyStateMetrics({
    required this.padding,
    required this.gap,
    required this.title,
    required this.description,
    required this.media,
  });

  static _EmptyStateMetrics of(PanelEmptyStateSize size) => switch (size) {
    PanelEmptyStateSize.sm => const _EmptyStateMetrics(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      gap: 16,
      title: PanelTextSize.base,
      description: PanelTextSize.sm,
      media: 32,
    ),
    PanelEmptyStateSize.md => const _EmptyStateMetrics(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      gap: 24,
      title: PanelTextSize.xl,
      description: PanelTextSize.sm,
      media: 36,
    ),
    PanelEmptyStateSize.lg => const _EmptyStateMetrics(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      gap: 24,
      title: PanelTextSize.xxl,
      description: PanelTextSize.base,
      media: 44,
    ),
  };

  final EdgeInsets padding;

  /// The space between the header and the action.
  final double gap;

  final PanelTextSize title;
  final PanelTextSize description;

  /// The side of the icon's frame.
  final double media;
}

/// The media, title and description, centred in one column.
class _Header extends StatelessWidget {
  const _Header({
    required this.metrics,
    required this.icon,
    required this.media,
    required this.title,
    required this.description,
  });

  final _EmptyStateMetrics metrics;
  final Widget? icon;
  final Widget? media;
  final Widget? title;
  final Widget? description;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final Widget? visual = icon != null
        ? _IconMedia(frame: metrics.media, icon: icon!)
        : media == null
        ? null
        // PanelUI's unframed media still sits in the frame's square.
        : ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: metrics.media,
              minHeight: metrics.media,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: media),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        if (visual != null)
          Padding(padding: const EdgeInsets.only(bottom: 16), child: visual),
        if (title != null)
          DefaultTextStyle(
            style: theme.typography.style(
              metrics.title,
              weight: FontWeight.w600,
              color: c.foreground,
            ),
            textAlign: TextAlign.center,
            child: title!,
          ),
        if (description != null)
          DefaultTextStyle(
            style: theme.typography.style(
              metrics.description,
              color: c.mutedForeground,
            ),
            textAlign: TextAlign.center,
            child: description!,
          ),
      ],
    );
  }
}

/// An icon in a small card, with two ghost cards fanned out behind it.
class _IconMedia extends StatelessWidget {
  const _IconMedia({required this.frame, required this.icon});

  /// The side of each card.
  final double frame;

  final Widget icon;

  /// How far each ghost card turns away from the one in front.
  static const double _fan = 10 * math.pi / 180;

  /// How far each ghost card slides out to its side.
  static const double _spread = 8;

  /// How much smaller a ghost card is than the one in front.
  static const double _ghostScale = 0.9;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final card = BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(theme.radii.md),
      border: Border.all(color: c.border),
    );
    Widget ghost(int side) => Transform.translate(
      offset: Offset(side * _spread, 0),
      child: Transform.rotate(
        angle: side * _fan,
        child: Transform.scale(
          scale: _ghostScale,
          child: SizedBox.square(
            dimension: frame,
            child: DecoratedBox(decoration: card),
          ),
        ),
      ),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(child: ghost(-1)),
        ExcludeSemantics(child: ghost(1)),
        Container(
          width: frame,
          height: frame,
          alignment: Alignment.center,
          decoration: card,
          // PanelUI leaves the glyph its own grey and draws it at the size
          // its demos pass: 16 in the 32pt frame, 18 in the 36pt one.
          child: IconTheme(
            data: IconThemeData(color: c.mutedForeground, size: frame / 2),
            child: icon,
          ),
        ),
      ],
    );
  }
}
