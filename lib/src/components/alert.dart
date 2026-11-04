import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_tokens.dart';
import '../theme/panel_typography.dart';

/// The status an alert reports.
enum PanelAlertVariant {
  /// A neutral note on the surface fill: PanelUI's `default`.
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
/// to false to drop it. Screen readers are told it is an alert.
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

  /// Replaces the status icon. It takes the status colour and an 18pt size
  /// unless it is given its own.
  final Widget? icon;

  /// Whether to show the status icon.
  final bool showIcon;

  /// An action at the end, such as a close button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final palette = _AlertPalette.of(theme.colors, variant);
    return Semantics(
      container: true,
      role: SemanticsRole.alert,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.fill,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(theme.radii.xl),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            if (showIcon)
              Padding(
                // PanelUI's `pt-px`, which sets the glyph on the title's line.
                padding: const EdgeInsets.only(top: 1),
                child: IconTheme(
                  data: IconThemeData(color: palette.tone, size: _iconSize),
                  child: icon ?? PanelIcon(palette.glyph),
                ),
              ),
            Expanded(
              child: _AlertText(
                title: title,
                description: description,
                titleColor: palette.title,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// The size `Alert.Indicator` draws its status icon at.
const double _iconSize = 18;

/// The colours and glyph one variant resolves to in the current theme.
class _AlertPalette {
  const _AlertPalette({
    required this.fill,
    required this.border,
    required this.tone,
    required this.title,
    required this.glyph,
  });

  factory _AlertPalette.of(PanelColors c, PanelAlertVariant variant) =>
      switch (variant) {
        PanelAlertVariant.neutral => _AlertPalette(
          fill: c.surface,
          border: c.border,
          tone: c.mutedForeground,
          title: c.cardForeground,
          glyph: PanelIcons.info,
        ),
        PanelAlertVariant.info => _AlertPalette.status(
          c.infoSoft,
          c.info,
          c.infoForeground,
          PanelIcons.info,
        ),
        PanelAlertVariant.success => _AlertPalette.status(
          c.successSoft,
          c.success,
          c.successForeground,
          PanelIcons.checkCircle,
        ),
        PanelAlertVariant.warning => _AlertPalette.status(
          c.warningSoft,
          c.warning,
          c.warningForeground,
          PanelIcons.alertTriangle,
        ),
        PanelAlertVariant.destructive => _AlertPalette.status(
          c.destructiveSoft,
          c.destructive,
          c.destructiveForeground,
          PanelIcons.alertTriangle,
        ),
      };

  /// A status variant: the `-soft` fill, a `/32` border in the status colour,
  /// and the icon and title in its foreground.
  _AlertPalette.status(this.fill, Color status, Color foreground, this.glyph)
    : border = status.withValues(alpha: 0.32),
      tone = foreground,
      title = foreground;

  final Color fill;
  final Color border;

  /// The icon's colour.
  final Color tone;

  final Color title;
  final PanelIconData glyph;
}

/// The title over the description, each in its slot's style.
class _AlertText extends StatelessWidget {
  const _AlertText({
    required this.title,
    required this.description,
    required this.titleColor,
  });

  final Widget? title;
  final Widget? description;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    return Column(
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
              color: theme.colors.mutedForeground,
            ),
            child: description!,
          ),
      ],
    );
  }
}
