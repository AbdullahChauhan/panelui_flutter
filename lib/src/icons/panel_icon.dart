import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

/// A stroked 24×24 glyph and how PanelUI draws it.
@immutable
class PanelIconData {
  /// Wraps HugeIcons glyph data.
  const PanelIconData(
    this.svg, {
    this.mirrorInRtl = false,
    this.strokeWidth = 2,
    this.fillable = false,
  });

  /// The glyph, in the format the `hugeicons` package publishes.
  final List<List<dynamic>> svg;

  /// Whether the glyph means a horizontal direction and so turns around in a
  /// right-to-left layout. A chevron does; a magnifier does not.
  final bool mirrorInRtl;

  /// The stroke width. PanelUI draws at 2 rather than the set's 1.5, because
  /// the glyphs are drawn at 24 and used at 14–20, where 1.5 thins away.
  final double strokeWidth;

  /// Whether the glyph has a solid form (a star, a heart).
  final bool fillable;
}

/// Draws a [PanelIconData].
///
/// The colour and size come from the nearest [IconTheme] unless given, which
/// is how a button paints the icon inside it in the colour of its label.
class PanelIcon extends StatelessWidget {
  /// Draws [icon].
  const PanelIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
    this.semanticLabel,
  });

  /// Draws a raw HugeIcons glyph, such as `HugeIcons.strokeRoundedHome01`.
  PanelIcon.svg(
    List<List<dynamic>> svg, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
    this.semanticLabel,
  }) : icon = PanelIconData(svg);

  /// The glyph.
  final PanelIconData icon;

  /// Size in logical pixels. Defaults to the [IconTheme] size.
  final double? size;

  /// Colour. Defaults to the [IconTheme] colour.
  final Color? color;

  /// Overrides [PanelIconData.strokeWidth].
  final double? strokeWidth;

  /// Announced by screen readers. Without one the icon is decorative and
  /// hidden from them.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    Widget glyph = HugeIcon(
      icon: icon.svg,
      size: size ?? iconTheme.size ?? 16,
      color: color ?? iconTheme.color,
      strokeWidth: strokeWidth ?? icon.strokeWidth,
    );
    if (icon.mirrorInRtl &&
        Directionality.maybeOf(context) == TextDirection.rtl) {
      glyph = Transform.flip(flipX: true, child: glyph);
    }
    if (semanticLabel == null) return ExcludeSemantics(child: glyph);
    return Semantics(label: semanticLabel, image: true, child: glyph);
  }
}
