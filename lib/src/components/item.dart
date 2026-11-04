import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';
import 'separator.dart';

/// The surface of a [PanelItem].
enum PanelItemVariant {
  /// No fill and no border: a row in a list. PanelUI's `default`.
  plain,

  /// A hairline border.
  outline,

  /// A tinted fill.
  muted,
}

/// How dense a [PanelItem] is. Its media, title and description follow it.
enum PanelItemSize {
  /// 16pt padding, a 16px title. The default.
  md,

  /// 12pt padding, a 14px title.
  sm,

  /// 8pt padding and gaps, a 14px title.
  xs,
}

/// How a [PanelItemMedia] frames its child.
enum PanelItemMediaVariant {
  /// No box, for an avatar or anything that styles itself. PanelUI's
  /// `default`.
  plain,

  /// A rounded, bordered tile sized for an icon.
  icon,

  /// A rounded, clipped frame for an image or a thumbnail.
  image,
}

/// A row of content: media on one side, a title and a description in the
/// middle, actions on the other side.
///
/// ```dart
/// PanelItem(
///   variant: PanelItemVariant.outline,
///   media: const PanelItemMedia(
///     variant: PanelItemMediaVariant.icon,
///     child: PanelIcon(PanelIcons.receipt),
///   ),
///   title: const Text('Invoice.pdf'),
///   description: const Text('2.4 MB · Updated yesterday'),
///   actions: [
///     PanelButton(size: PanelButtonSize.sm, onPressed: open, child: const Text('Open')),
///   ],
/// )
/// ```
///
/// It is the shape almost every list already has (a settings row, a file in
/// a picker, a member of a team), so it exists once rather than being
/// rebuilt per screen with slightly different padding.
///
/// Horizontal (the default), the parts sit side by side and the text takes
/// the remaining width, keeping the actions at the trailing edge. Vertical,
/// they stack into a card, which is what a carousel wants and what [header]
/// and [footer] need. A vertical item fills the width it is given, so give
/// it one.
///
/// With [onPressed] the whole item is pressable, and shrinks a little while
/// pressed; without it the item is a static row and is not announced as a
/// button.
class PanelItem extends StatelessWidget {
  /// Creates an item.
  const PanelItem({
    super.key,
    this.media,
    this.title,
    this.description,
    this.actions = const [],
    this.header,
    this.footer,
    this.variant = PanelItemVariant.plain,
    this.size = PanelItemSize.md,
    this.orientation = Axis.horizontal,
    this.enabled = true,
    this.onPressed,
    this.onLongPress,
    this.semanticLabel,
  });

  /// The leading slot: a [PanelItemMedia] tile, or an avatar passed through.
  final Widget? media;

  /// The title: medium weight, in the foreground colour.
  final Widget? title;

  /// A muted line under the title.
  final Widget? description;

  /// The trailing slot: buttons, a chevron, a switch, 6pt apart. An icon
  /// here is drawn at 16pt in the muted colour unless it says otherwise.
  final List<Widget> actions;

  /// A full-width strip above the content, such as a [PanelItemHeader]. For
  /// a vertical item.
  final Widget? header;

  /// A full-width strip below the content, such as a [PanelItemFooter]. For
  /// a vertical item.
  final Widget? footer;

  /// The surface.
  final PanelItemVariant variant;

  /// The density.
  final PanelItemSize size;

  /// Side by side ([Axis.horizontal]) or stacked into a card.
  final Axis orientation;

  /// Whether the item is enabled. A disabled item is dimmed and, if
  /// pressable, ignores presses.
  final bool enabled;

  /// Called when the item is pressed. Null makes a static row.
  final VoidCallback? onPressed;

  /// Called when the item is long-pressed.
  final VoidCallback? onLongPress;

  /// An accessible name for a pressable item.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    // `p-4`, `p-3`, and `gap-2 p-2`; the gap is `gap-3` otherwise.
    final (double padding, double gap) = switch (size) {
      PanelItemSize.md => (16, 12),
      PanelItemSize.sm => (12, 12),
      PanelItemSize.xs => (8, 8),
    };
    final media = this.media;
    final text = title == null && description == null
        ? null
        : _ItemText(size: size, title: title, description: description);
    // `gap-1.5`, with an icon in PanelUI's default 16pt grey.
    final actionRow = actions.isEmpty
        ? null
        : IconTheme(
            data: IconThemeData(color: c.mutedForeground, size: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: actions,
            ),
          );

    final Widget body = orientation == Axis.horizontal
        ? Row(
            spacing: gap,
            children: [
              ?media,
              // The text takes the remaining width, so the actions stay
              // pinned to the trailing edge.
              if (text != null) Expanded(child: text),
              ?actionRow,
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: [
              ?header,
              if (media != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: media,
                ),
              ?text,
              if (actionRow != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: actionRow,
                ),
              ?footer,
            ],
          );

    final radius = BorderRadius.circular(theme.radii.xl);
    final item = _ItemScope(
      size: size,
      child: Opacity(
        opacity: enabled ? 1 : _disabledOpacity,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: variant == PanelItemVariant.muted ? c.muted : null,
            border: variant == PanelItemVariant.outline
                ? Border.all(color: c.border)
                : null,
            borderRadius: radius,
          ),
          child: body,
        ),
      ),
    );

    if (onPressed == null && onLongPress == null) {
      return Semantics(
        container: true,
        enabled: enabled ? null : false,
        child: item,
      );
    }
    return PanelPressable(
      onPressed: onPressed,
      onLongPress: onLongPress,
      enabled: enabled,
      semanticLabel: semanticLabel,
      focusRingRadius: radius,
      child: item,
    );
  }
}

/// The leading slot of a [PanelItem]: an icon tile, a thumbnail frame, or
/// nothing at all around an avatar.
///
/// Its size follows the item's [PanelItem.size] unless [size] says
/// otherwise: an icon tile is 40, 32 or 24pt, an image frame 48, 40 or 32pt.
/// An icon in a tile is drawn in the muted colour at 18, 16 or 12pt unless
/// it says otherwise, the sizes PanelUI's own rows give theirs.
class PanelItemMedia extends StatelessWidget {
  /// Creates a media slot.
  const PanelItemMedia({
    super.key,
    required this.child,
    this.variant = PanelItemMediaVariant.plain,
    this.size,
  });

  /// The icon, image or avatar.
  final Widget child;

  /// How the child is framed.
  final PanelItemMediaVariant variant;

  /// Overrides the item's size.
  final PanelItemSize? size;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final resolved = size ?? _ItemScope.sizeOf(context);
    final radius = BorderRadius.circular(theme.radii.lg);
    switch (variant) {
      case PanelItemMediaVariant.plain:
        return child;
      case PanelItemMediaVariant.icon:
        final (double extent, double iconSize) = switch (resolved) {
          PanelItemSize.md => (40, 18),
          PanelItemSize.sm => (32, 16),
          PanelItemSize.xs => (24, 12),
        };
        return Container(
          width: extent,
          height: extent,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.muted,
            border: Border.all(color: c.border),
            borderRadius: radius,
          ),
          child: IconTheme(
            data: IconThemeData(color: c.mutedForeground, size: iconSize),
            child: child,
          ),
        );
      case PanelItemMediaVariant.image:
        final extent = switch (resolved) {
          PanelItemSize.md => 48.0,
          PanelItemSize.sm => 40.0,
          PanelItemSize.xs => 32.0,
        };
        return Container(
          width: extent,
          height: extent,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: c.muted, borderRadius: radius),
          child: child,
        );
    }
  }
}

/// A full-width strip above a vertical [PanelItem]'s content: an eyebrow
/// label, a badge row. Its children are spread to the two ends, 8pt apart at
/// the least.
class PanelItemHeader extends StatelessWidget {
  /// Creates a header strip.
  const PanelItemHeader({super.key, required this.children});

  /// The strip's content.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 8,
      children: children,
    );
  }
}

/// A full-width strip below a vertical [PanelItem]'s content, such as a
/// price or a row of buttons, 8pt apart.
class PanelItemFooter extends StatelessWidget {
  /// Creates a footer strip.
  const PanelItemFooter({super.key, required this.children});

  /// The strip's content.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(spacing: 8, children: children);
  }
}

/// A run of [PanelItem]s.
///
/// Vertical (the default), the items stack: the settings-list shape, with
/// hairlines between them when [separated]. Horizontal, they run across,
/// stretched to one height and 12pt apart; put it in a horizontal scroller
/// and give each item [Axis.vertical] so every entry reads as a card.
class PanelItemGroup extends StatelessWidget {
  /// Creates a group.
  const PanelItemGroup({
    super.key,
    required this.children,
    this.orientation = Axis.vertical,
    this.separated = false,
  });

  /// The items.
  final List<Widget> children;

  /// Whether the items run down or across.
  final Axis orientation;

  /// Draw a hairline between neighbouring items.
  final bool separated;

  @override
  Widget build(BuildContext context) {
    final vertical = orientation == Axis.vertical;
    final items = [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0 && separated)
          PanelSeparator(
            orientation: vertical ? Axis.horizontal : Axis.vertical,
          ),
        children[i],
      ],
    ];
    final Widget run = vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items,
          )
        // Stretched to the tallest item (`items-stretch`), which a row with
        // no height of its own learns only by asking its items: hence the
        // intrinsic pass.
        : IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: items,
            ),
          );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.list,
      child: run,
    );
  }
}

/// A disabled item's opacity (`opacity-[0.64]`).
const double _disabledOpacity = 0.64;

/// What the parts of an item read from it.
class _ItemScope extends InheritedWidget {
  const _ItemScope({required this.size, required super.child});

  final PanelItemSize size;

  static PanelItemSize sizeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ItemScope>()?.size ??
      PanelItemSize.md;

  @override
  bool updateShouldNotify(_ItemScope oldWidget) => size != oldWidget.size;
}

/// An item's title and the muted line under it, 2pt apart (`gap-0.5`): a
/// 16px title over a 14px line, or 14px over 12px in the smaller sizes.
class _ItemText extends StatelessWidget {
  const _ItemText({
    required this.size,
    required this.title,
    required this.description,
  });

  final PanelItemSize size;
  final Widget? title;
  final Widget? description;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final md = size == PanelItemSize.md;
    final title = this.title;
    final description = this.description;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        if (title != null)
          DefaultTextStyle(
            style: theme.typography.style(
              md ? PanelTextSize.base : PanelTextSize.sm,
              weight: FontWeight.w500,
              color: c.foreground,
            ),
            child: title,
          ),
        if (description != null)
          DefaultTextStyle(
            style: theme.typography.style(
              md ? PanelTextSize.sm : PanelTextSize.xs,
              color: c.mutedForeground,
            ),
            child: description,
          ),
      ],
    );
  }
}
