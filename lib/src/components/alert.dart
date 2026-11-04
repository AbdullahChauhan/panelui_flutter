import 'package:flutter/widgets.dart';

import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_tokens.dart';
import '../theme/panel_typography.dart';

/// The status an alert reports.
enum PanelAlertVariant {
  /// A neutral note on the surface fill.
  neutral,

  /// Something worth knowing.
  info,

  /// Something went right.
  success,

  /// Something needs attention.
  warning,

  /// Something went wrong.
  destructive,
}

/// A status message with a leading status icon.
///
/// The icon and its colour come from [variant], so a success alert cannot
/// end up with a warning icon. Pass [icon] to replace it, or set [showIcon]
/// to false to drop it.
///
/// ```dart
/// const PanelAlert(
///   variant: PanelAlertVariant.success,
///   title: Text('Payment received'),
///   description: Text('Your invoice has been sent to your inbox.'),
/// )
/// ```
class PanelAlert extends StatelessWidget {
  /// Creates an alert.
  const PanelAlert({
    super.key,
    this.variant = PanelAlertVariant.neutral,
    this.title,
    this.description,
    this.icon,
    this.showIcon = true,
    this.trailing,
  });

  /// The status.
  final PanelAlertVariant variant;

  /// A short summary, in the status colour.
  final Widget? title;

  /// Detail under the title, muted.
  final Widget? description;

  /// Replaces the status icon.
  final Widget? icon;

  /// Whether to show the status icon.
  final bool showIcon;

  /// An action at the end, such as a close button.
  final Widget? trailing;

  (Color fill, Color border, Color tone, PanelIconData glyph) _palette(
    PanelColors c,
  ) {
    switch (variant) {
      case PanelAlertVariant.neutral:
        return (c.surface, c.border, c.mutedForeground, PanelIcons.info);
      case PanelAlertVariant.info:
        return (
          c.infoSoft,
          c.info.withValues(alpha: 0.32),
          c.infoForeground,
          PanelIcons.info,
        );
      case PanelAlertVariant.success:
        return (
          c.successSoft,
          c.success.withValues(alpha: 0.32),
          c.successForeground,
          PanelIcons.checkCircle,
        );
      case PanelAlertVariant.warning:
        return (
          c.warningSoft,
          c.warning.withValues(alpha: 0.32),
          c.warningForeground,
          PanelIcons.alertTriangle,
        );
      case PanelAlertVariant.destructive:
        return (
          c.destructiveSoft,
          c.destructive.withValues(alpha: 0.32),
          c.destructiveForeground,
          PanelIcons.alertTriangle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final (fill, border, tone, glyph) = _palette(c);
    final titleColor = variant == PanelAlertVariant.neutral
        ? c.cardForeground
        : tone;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(theme.radii.xl),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            if (showIcon)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: IconTheme(
                  data: IconThemeData(color: tone, size: 18),
                  child: icon ?? PanelIcon(glyph),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  if (title != null)
                    DefaultTextStyle(
                      style: theme.typography.style(
                        PanelTextSize.sm,
                        weight: FontWeight.w500,
                        color: titleColor,
                      ),
                      child: title!,
                    ),
                  if (description != null)
                    DefaultTextStyle(
                      style: theme.typography.style(
                        PanelTextSize.sm,
                        color: c.mutedForeground,
                      ),
                      child: description!,
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
