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

  /// How the content is clipped to the rounded corners, inside the border
  /// as PanelUI's `overflow-hidden` clips.
  final Clip clipBehavior;

  /// An optional fixed width.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final radius = theme.radii.xxl;
    Widget parts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    if (clipBehavior != Clip.none) {
      // The border's inner edge: media clipped to the outer one would paint
      // over the border where the corners curve.
      parts = ClipRRect(
        borderRadius: BorderRadius.circular(radius - _borderWidth),
        clipBehavior: clipBehavior,
        child: parts,
      );
    }
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: theme.colors.border),
        boxShadow: theme.shadows.sm,
      ),
      child: parts,
    );
  }
}

/// The top of a card: a title and a description, 24pt from every edge, with
/// an optional action held in its top trailing corner.
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

  /// A control for the whole card, such as a menu button, held in the
  /// header's top trailing corner while the title and description wrap
  /// beside it (the web card's `Card.Action`).
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
              spacing: _actionGap,
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
          .copyWith(height: 1.25), // leading-tight
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
///
/// Bare text in it reads as PanelUI's `Text` does by default: body size, in
/// the card's foreground colour.
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
          PanelTextSize.base,
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

/// The width of the card's border: `Border.all`'s default hairline.
const double _borderWidth = 1;

/// The web card's `gap-x-4` between the heading and its action.
const double _actionGap = 16;
