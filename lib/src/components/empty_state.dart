import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// Whether an empty state stands alone or sits inside content.
enum PanelEmptyStateVariant {
  /// No frame of its own; centred in the space it is given.
  plain,

  /// A self-contained bordered block on the card fill.
  card,
}

/// How big an empty state is.
enum PanelEmptyStateSize {
  /// Compact, for a panel or a list inside a page.
  sm,

  /// The default.
  md,

  /// Large, for a whole screen.
  lg,
}

/// The placeholder shown when a list or a view has nothing in it.
///
/// [icon] is framed in a small card with two ghost cards fanned out behind
/// it; [media] (an illustration, an image) is shown as-is.
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

  /// An icon, framed with fanned ghost cards.
  final Widget? icon;

  /// Media shown without a frame. Ignored when [icon] is set.
  final Widget? media;

  /// The headline.
  final Widget? title;

  /// A line or two of explanation.
  final Widget? description;

  /// What to do about it, usually a button or two.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final (
      EdgeInsets padding,
      double gap,
      PanelTextSize titleSize,
      PanelTextSize bodySize,
      double frame,
    ) = switch (size) {
      PanelEmptyStateSize.sm => (
        const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        16.0,
        PanelTextSize.base,
        PanelTextSize.sm,
        32.0,
      ),
      PanelEmptyStateSize.md => (
        const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        24.0,
        PanelTextSize.xl,
        PanelTextSize.sm,
        36.0,
      ),
      PanelEmptyStateSize.lg => (
        const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        24.0,
        PanelTextSize.xxl,
        PanelTextSize.base,
        44.0,
      ),
    };

    Widget? mediaWidget;
    if (icon != null) {
      Widget ghost(double turn, double dx) => Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.rotate(
          angle: turn,
          child: Transform.scale(
            scale: 0.9,
            child: _frame(theme.radii.md, c.border, c.card, frame, null),
          ),
        ),
      );
      mediaWidget = Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(child: ghost(-10 * math.pi / 180, -8)),
          ExcludeSemantics(child: ghost(10 * math.pi / 180, 8)),
          _frame(
            theme.radii.md,
            c.border,
            c.card,
            frame,
            IconTheme(
              data: IconThemeData(color: c.foreground, size: frame * 0.5),
              child: icon!,
            ),
          ),
        ],
      );
    } else if (media != null) {
      mediaWidget = media;
    }

    final header = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 384),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (mediaWidget != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: mediaWidget,
            ),
          if (title != null)
            DefaultTextStyle(
              style: theme.typography.style(
                titleSize,
                weight: FontWeight.w600,
                color: c.foreground,
              ),
              textAlign: TextAlign.center,
              child: title!,
            ),
          if (description != null)
            DefaultTextStyle(
              style: theme.typography.style(bodySize, color: c.mutedForeground),
              textAlign: TextAlign.center,
              child: description!,
            ),
        ],
      ),
    );

    final body = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: gap,
        children: [
          header,
          if (action != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: action,
            ),
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
      child: Center(child: body),
    );
  }

  static Widget _frame(
    double radius,
    Color border,
    Color fill,
    double size,
    Widget? child,
  ) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}
