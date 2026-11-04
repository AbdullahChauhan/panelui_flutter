import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

/// A stroked 24×24 glyph and how PanelUI draws it.
@immutable
class PanelIconData {
  /// Wraps HugeIcons glyph data.
  const PanelIconData(
    this.svg, {
    this.mirrorInRtl = false,
    this.strokeWidth = 2,
    this.fillable = false,
    this.size = 16,
  });

  /// The glyph, in the format the `hugeicons` package publishes: a list of
  /// `[tag, attributes]` pairs on a 24×24 board.
  final List<List<dynamic>> svg;

  /// Whether the glyph means a horizontal direction and so turns around in a
  /// right-to-left layout. A chevron does; a magnifier does not.
  final bool mirrorInRtl;

  /// The stroke width. PanelUI draws at 2 rather than the set's 1.5, because
  /// the glyphs are drawn at 24 and used at 14–20, where 1.5 thins away.
  final double strokeWidth;

  /// Whether the glyph has a solid form (a star, a heart).
  final bool fillable;

  /// PanelUI's default size for the glyph, used when neither the icon nor an
  /// enclosing [IconTheme] sets one: 16 for most, 20 for the status glyphs.
  final double size;
}

/// Draws a [PanelIconData].
///
/// The colour and size come from the nearest [IconTheme] unless given, which
/// is how a button paints the icon inside it in the colour of its label.
///
/// Glyphs are parsed into paths once and painted directly, so an icon is
/// there on its first frame and costs a path draw rather than an SVG decode.
class PanelIcon extends StatelessWidget {
  /// Draws [icon].
  const PanelIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
    this.filled = false,
    this.semanticLabel,
  });

  /// Draws a raw HugeIcons glyph, such as `HugeIcons.strokeRoundedHome01`.
  PanelIcon.svg(
    List<List<dynamic>> svg, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
    this.filled = false,
    this.semanticLabel,
  }) : icon = PanelIconData(svg);

  /// The glyph.
  final PanelIconData icon;

  /// Size in logical pixels. Defaults to the enclosing [IconTheme]'s size if
  /// it sets one, then to the glyph's own [PanelIconData.size].
  final double? size;

  /// Colour. Defaults to the [IconTheme] colour.
  final Color? color;

  /// Overrides [PanelIconData.strokeWidth].
  final double? strokeWidth;

  /// Fills a [PanelIconData.fillable] glyph, for the "on" state of a star or a
  /// heart. Ignored for other glyphs.
  final bool filled;

  /// Announced by screen readers. Without one the icon is decorative and
  /// hidden from them.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    // IconTheme.of fills in Flutter's 24pt fallback; only a size an enclosing
    // theme actually sets should beat the glyph's own.
    final themedSize = context
        .dependOnInheritedWidgetOfExactType<IconTheme>()
        ?.data
        .size;
    final dimension = size ?? themedSize ?? icon.size;
    var paint = color ?? iconTheme.color ?? const Color(0xFF000000);
    final opacity = iconTheme.opacity ?? 1;
    if (opacity < 1) paint = paint.withValues(alpha: paint.a * opacity);

    Widget glyph = CustomPaint(
      size: Size.square(dimension),
      painter: _GlyphPainter(
        glyph: _Glyph.of(icon.svg),
        color: paint,
        strokeWidth: strokeWidth ?? icon.strokeWidth,
        filled: filled && icon.fillable,
      ),
    );
    if (icon.mirrorInRtl &&
        Directionality.maybeOf(context) == TextDirection.rtl) {
      glyph = Transform.flip(flipX: true, child: glyph);
    }
    if (semanticLabel == null) return ExcludeSemantics(child: glyph);
    return Semantics(label: semanticLabel, image: true, child: glyph);
  }
}

/// One stroke of a glyph.
class _Stroke {
  const _Stroke(this.path, this.cap, this.join);

  final Path path;
  final StrokeCap cap;
  final StrokeJoin join;
}

/// A glyph parsed into paths, cached against its (usually const) data.
class _Glyph {
  _Glyph._(this.strokes);

  final List<_Stroke> strokes;

  static final Expando<_Glyph> _cache = Expando('PanelIcon glyphs');

  static _Glyph of(List<List<dynamic>> svg) =>
      _cache[svg] ??= _Glyph._([for (final e in svg) ?_parse(e)]);

  static _Stroke? _parse(List<dynamic> element) {
    final tag = element[0] as String;
    final attributes = (element[1] as Map).cast<String, Object?>();
    Path? path;
    if (tag == 'path') {
      final writer = _PathWriter();
      writeSvgPathDataToPath(attributes['d'] as String?, writer);
      path = writer.path;
    } else if (tag == 'circle') {
      path = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(
              _number(attributes['cx']),
              _number(attributes['cy']),
            ),
            radius: _number(attributes['r']),
          ),
        );
    }
    if (path == null) return null;
    final transform = attributes['transform'] as String?;
    if (transform != null) path = path.transform(_matrix(transform));
    return _Stroke(
      path,
      switch (attributes['strokeLinecap']) {
        'round' => StrokeCap.round,
        'square' => StrokeCap.square,
        _ => StrokeCap.butt,
      },
      switch (attributes['strokeLinejoin']) {
        'round' => StrokeJoin.round,
        'bevel' => StrokeJoin.bevel,
        _ => StrokeJoin.miter,
      },
    );
  }

  static double _number(Object? value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  /// An SVG `matrix(a b c d e f)` as a column-major 4×4 matrix.
  static Float64List _matrix(String transform) {
    final values = RegExp(
      r'-?[\d.]+(?:e-?\d+)?',
    ).allMatches(transform).map((m) => double.parse(m[0]!)).toList();
    if (!transform.trimLeft().startsWith('matrix') || values.length != 6) {
      return Float64List.fromList(const [
        1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, //
      ]);
    }
    final [a, b, c, d, e, f] = values;
    return Float64List.fromList([
      a,
      b,
      0,
      0,
      c,
      d,
      0,
      0,
      0,
      0,
      1,
      0,
      e,
      f,
      0,
      1,
    ]);
  }
}

class _PathWriter extends PathProxy {
  final Path path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({
    required this.glyph,
    required this.color,
    required this.strokeWidth,
    required this.filled,
  });

  final _Glyph glyph;
  final Color color;
  final double strokeWidth;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    // The glyphs are drawn on a 24×24 board; the stroke scales with them.
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    for (final stroke in glyph.strokes) {
      if (filled) {
        canvas.drawPath(stroke.path, paint..style = PaintingStyle.fill);
      }
      canvas.drawPath(
        stroke.path,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = stroke.cap
          ..strokeJoin = stroke.join,
      );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      !identical(oldDelegate.glyph, glyph) ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.filled != filled;
}
