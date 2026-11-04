import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// A content surface: a bordered, rounded card on the `card` fill.
///
/// The padding lives on the parts and none of it on the card, so media that
/// should reach the card's own corners needs nothing but [clipBehavior].
///
/// ```dart
/// PanelCard(
///   children: [
///     const PanelCardHeader(
///       title: Text('Create project'),
///       description: Text('Deploy your new project in one click.'),
///     ),
///     PanelCardContent(child: PanelInput(label: 'Name')),
///     PanelCardFooter(children: [PanelButton(onPressed: deploy, child: const Text('Deploy'))]),
///   ],
/// )
/// ```
class PanelCard extends StatelessWidget {
  /// Creates a card from its parts.
  const PanelCard({
    super.key,
    required this.children,
    this.clipBehavior = Clip.none,
    this.width,
  });

  /// The parts, laid out top to bottom.
  final List<Widget> children;

  /// How the content is clipped to the rounded corners.
  final Clip clipBehavior;

  /// An optional fixed width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return Container(
      width: width,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(theme.radii.xxl),
        border: Border.all(color: theme.colors.border),
        boxShadow: theme.shadows.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// The top of a card: a title and a description, 24pt from every edge.
class PanelCardHeader extends StatelessWidget {
  /// Creates a header.
  const PanelCardHeader({
    super.key,
    this.title,
    this.description,
    this.trailing,
    this.children = const [],
  });

  /// The title, styled as [PanelCardTitle].
  final Widget? title;

  /// The description, styled as [PanelCardDescription].
  final Widget? description;

  /// An action at the end of the header row, such as a menu button.
  final Widget? trailing;

  /// More content under the description.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        if (title != null) PanelCardTitle(child: title!),
        if (description != null) PanelCardDescription(child: description!),
        ...children,
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(24),
      child: trailing == null
          ? column
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Expanded(child: column),
                trailing!,
              ],
            ),
    );
  }
}

/// A card's title: large, semibold, tightly leaded.
class PanelCardTitle extends StatelessWidget {
  /// Styles [child] as a card title.
  const PanelCardTitle({super.key, required this.child});

  /// The title, usually a [Text].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return DefaultTextStyle(
      style: theme.typography
          .style(
            PanelTextSize.lg,
            weight: FontWeight.w600,
            color: theme.colors.cardForeground,
          )
          .copyWith(height: 1.25),
      child: child,
    );
  }
}

/// A card's description: small and muted.
class PanelCardDescription extends StatelessWidget {
  /// Styles [child] as a card description.
  const PanelCardDescription({super.key, required this.child});

  /// The description, usually a [Text].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return DefaultTextStyle(
      style: theme.typography.style(
        PanelTextSize.sm,
        color: theme.colors.mutedForeground,
      ),
      child: child,
    );
  }
}

/// The body of a card, padded to line up with the header above it.
class PanelCardContent extends StatelessWidget {
  /// Pads [child] as card content.
  const PanelCardContent({super.key, required this.child});

  /// The content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: DefaultTextStyle(
        style: theme.typography.style(
          PanelTextSize.sm,
          color: theme.colors.cardForeground,
        ),
        child: child,
      ),
    );
  }
}

/// Whether a card footer draws a surface of its own.
enum PanelCardFooterVariant {
  /// Part of the card: same fill, padding continuing from the content above.
  plain,

  /// A band set into the card, a step darker with a rule across the top, for
  /// a footer that is what somebody does with the card.
  panel,
}

/// A row of actions at the bottom of a card.
class PanelCardFooter extends StatelessWidget {
  /// Creates a footer.
  const PanelCardFooter({
    super.key,
    required this.children,
    this.variant = PanelCardFooterVariant.plain,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  /// The actions.
  final List<Widget> children;

  /// Plain or panel.
  final PanelCardFooterVariant variant;

  /// How the actions are distributed along the row.
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final row = Row(
      mainAxisAlignment: mainAxisAlignment,
      spacing: 8,
      children: children,
    );
    if (variant == PanelCardFooterVariant.plain) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: row,
      );
    }
    final radius = Radius.circular(theme.radii.xxl);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colors.inset,
        borderRadius: BorderRadius.only(
          bottomLeft: radius,
          bottomRight: radius,
        ),
        border: Border(top: BorderSide(color: theme.colors.border)),
      ),
      child: row,
    );
  }
}
