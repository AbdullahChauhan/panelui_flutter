import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A [BoxDecoration] that casts its shadows the way CSS casts `box-shadow`:
/// only outside the box.
///
/// Flutter draws a box's shadows under the whole box. An opaque fill covers
/// them there, but a translucent one shows them through: an outline button's
/// 6% hover tint comes out a heavy grey. PanelUI's shadows are CSS shadows, so
/// every shadowed box in this package is drawn with this decoration,
/// [PanelShapeDecoration] or [paintPanelShadows].
class PanelBoxDecoration extends BoxDecoration {
  /// Creates a decoration. The arguments are [BoxDecoration]'s.
  const PanelBoxDecoration({
    super.color,
    super.image,
    super.border,
    super.borderRadius,
    super.boxShadow,
    super.gradient,
    super.backgroundBlendMode,
    super.shape,
  });

  /// [decoration], with its shadows cast as CSS casts them.
  PanelBoxDecoration.of(BoxDecoration decoration)
    : this(
        color: decoration.color,
        image: decoration.image,
        border: decoration.border,
        borderRadius: decoration.borderRadius,
        boxShadow: decoration.boxShadow,
        gradient: decoration.gradient,
        backgroundBlendMode: decoration.backgroundBlendMode,
        shape: decoration.shape,
      );

  @override
  PanelBoxDecoration copyWith({
    Color? color,
    DecorationImage? image,
    BoxBorder? border,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
    BlendMode? backgroundBlendMode,
    BoxShape? shape,
  }) => PanelBoxDecoration.of(
    super.copyWith(
      color: color,
      image: image,
      border: border,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      gradient: gradient,
      backgroundBlendMode: backgroundBlendMode,
      shape: shape,
    ),
  );

  // The frames of an animation (an AnimatedContainer's) cast them so too.
  @override
  PanelBoxDecoration? lerpFrom(Decoration? a, double t) =>
      _kept(super.lerpFrom(a, t));

  @override
  PanelBoxDecoration? lerpTo(Decoration? b, double t) =>
      _kept(super.lerpTo(b, t));

  static PanelBoxDecoration? _kept(BoxDecoration? decoration) =>
      decoration == null ? null : PanelBoxDecoration.of(decoration);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      boxShadow?.isNotEmpty ?? false
      ? _PanelBoxPainter(this, onChanged)
      : super.createBoxPainter(onChanged);
}

class _PanelBoxPainter extends BoxPainter {
  _PanelBoxPainter(this._decoration, VoidCallback? onChanged)
    : _body = _decoration
          .copyWith(boxShadow: const [])
          .createBoxPainter(onChanged),
      super(onChanged);

  final PanelBoxDecoration _decoration;

  /// Everything but the shadows, painted as a [BoxDecoration] paints it.
  final BoxPainter _body;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final decoration = _decoration;
    final rect = offset & configuration.size!;
    final RRect box;
    if (decoration.shape == BoxShape.circle) {
      final radius = Radius.circular(rect.shortestSide / 2);
      box = RRect.fromRectAndRadius(
        Rect.fromCircle(center: rect.center, radius: radius.x),
        radius,
      );
    } else {
      box = (decoration.borderRadius ?? BorderRadius.zero)
          .resolve(configuration.textDirection)
          .toRRect(rect);
    }
    paintPanelShadows(
      canvas,
      box,
      decoration.boxShadow!,
      opaque:
          decoration.color?.a == 1 &&
          decoration.gradient == null &&
          decoration.backgroundBlendMode == null,
    );
    _body.paint(canvas, offset, configuration);
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }
}

/// A [ShapeDecoration] that casts its shadows the way CSS casts
/// `box-shadow`, only outside the shape: the [PanelBoxDecoration] for a shape
/// a [BoxDecoration] cannot draw, such as iOS's continuous corners.
class PanelShapeDecoration extends ShapeDecoration {
  /// Creates a decoration. The arguments are [ShapeDecoration]'s.
  const PanelShapeDecoration({
    super.color,
    super.image,
    super.gradient,
    super.shadows,
    required super.shape,
  });

  // The frames of an animation cast them so too.
  @override
  PanelShapeDecoration? lerpFrom(Decoration? a, double t) =>
      _kept(super.lerpFrom(a, t));

  @override
  PanelShapeDecoration? lerpTo(Decoration? b, double t) =>
      _kept(super.lerpTo(b, t));

  static PanelShapeDecoration? _kept(ShapeDecoration? decoration) =>
      decoration == null
      ? null
      : PanelShapeDecoration(
          color: decoration.color,
          image: decoration.image,
          gradient: decoration.gradient,
          shadows: decoration.shadows,
          shape: decoration.shape,
        );

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      shadows?.isNotEmpty ?? false
      ? _PanelShapePainter(this, onChanged)
      : super.createBoxPainter(onChanged);
}

class _PanelShapePainter extends BoxPainter {
  _PanelShapePainter(this._decoration, VoidCallback? onChanged)
    : _body = ShapeDecoration(
        color: _decoration.color,
        image: _decoration.image,
        gradient: _decoration.gradient,
        shape: _decoration.shape,
      ).createBoxPainter(onChanged),
      super(onChanged);

  final PanelShapeDecoration _decoration;

  /// Everything but the shadows, painted as a [ShapeDecoration] paints it.
  final BoxPainter _body;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final shape = _decoration.shape;
    final direction = configuration.textDirection;
    final shadows = _decoration.shadows!;
    final opaque = _decoration.color?.a == 1;
    if (!opaque) {
      canvas.save();
      _clipOutside(
        canvas,
        shape.getOuterPath(rect, textDirection: direction),
        shadows,
      );
    }
    for (final shadow in shadows) {
      canvas.drawPath(
        shape.getOuterPath(
          rect.shift(shadow.offset).inflate(shadow.spreadRadius),
          textDirection: direction,
        ),
        shadow.toPaint(),
      );
    }
    if (!opaque) canvas.restore();
    _body.paint(canvas, offset, configuration);
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }
}

/// Paints the [shadows] that [box] casts, the way CSS paints `box-shadow`:
/// each one the box's shape, moved by its offset and grown by its spread,
/// and none of it inside the box. For a painter that draws a box of its own,
/// before it draws the box.
///
/// [opaque] says the box's fill will cover its inside anyway, which saves a
/// clip.
void paintPanelShadows(
  Canvas canvas,
  RRect box,
  List<BoxShadow> shadows, {
  bool opaque = false,
}) {
  if (shadows.isEmpty) return;
  if (!opaque) {
    canvas.save();
    _clipOutside(canvas, Path()..addRRect(box), shadows);
  }
  for (final shadow in shadows) {
    canvas.drawRRect(
      box.shift(shadow.offset).inflate(shadow.spreadRadius),
      shadow.toPaint(),
    );
  }
  if (!opaque) canvas.restore();
}

/// Clips [canvas] to the band around [outline] that [shadows] can reach.
void _clipOutside(Canvas canvas, Path outline, List<BoxShadow> shadows) {
  var reach = 0.0;
  for (final shadow in shadows) {
    // A blur has faded out three standard deviations from its edge.
    reach = math.max(
      reach,
      shadow.offset.distance + shadow.spreadRadius + 3 * shadow.blurSigma,
    );
  }
  canvas.clipPath(
    Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(outline.getBounds().inflate(reach + 1))
      ..addPath(outline, Offset.zero),
  );
}
