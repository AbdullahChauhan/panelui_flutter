import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// How big a [PanelAvatar] is.
enum PanelAvatarSize {
  /// 32pt across, 12px initials.
  sm(32, PanelTextSize.xs),

  /// 40pt across, 14px initials. The default.
  md(40, PanelTextSize.sm),

  /// 56pt across, 18px initials.
  lg(56, PanelTextSize.lg),

  /// 80pt across, 24px initials.
  xl(80, PanelTextSize.xxl);

  const PanelAvatarSize(this.diameter, this.textSize);

  /// The width and height.
  final double diameter;

  /// The step the initials are set in.
  final PanelTextSize textSize;
}

/// How much of each avatar the next one in a [PanelAvatarGroup] covers, as a
/// share of its diameter. A third is enough for the faces to read as one
/// group and still leaves the widest part of every face visible.
const double _overlapRatio = 0.32;

/// A person as a picture, with their initials when there is no picture.
///
/// ```dart
/// PanelAvatar(image: NetworkImage(user.photoUrl), fallback: 'KA')
/// const PanelAvatar(fallback: 'KA', size: PanelAvatarSize.lg)
/// PanelAvatar(
///   fallback: 'EF',
///   badge: const PanelBadge.dot(variant: PanelBadgeVariant.success),
/// )
/// ```
///
/// The initials show when [image] is null or fails to load. The fill behind
/// them is opaque rather than a translucent tint, so in a [PanelAvatarGroup]
/// a face never lets the one underneath show through it.
class PanelAvatar extends StatelessWidget {
  /// Creates an avatar.
  const PanelAvatar({
    super.key,
    this.image,
    this.fallback,
    this.size,
    this.badge,
    this.semanticLabel,
  });

  /// The picture, drawn to cover the circle. Null, or one that fails to load,
  /// shows [fallback].
  final ImageProvider? image;

  /// The text shown without a picture, usually initials ("KA"). Defaults to
  /// "?".
  final String? fallback;

  /// The size. Defaults to the enclosing [PanelAvatarGroup]'s, then md.
  final PanelAvatarSize? size;

  /// An overlay pinned to the top trailing corner, such as an unread count
  /// (`PanelBadge.count`) or a presence dot (`PanelBadge.dot`). It is ringed
  /// in the page background, so it separates from the picture whatever the
  /// avatar sits on.
  final Widget? badge;

  /// What a screen reader calls the avatar. Defaults to [fallback].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final group = _AvatarGroupScope.maybeOf(context);
    final resolved = size ?? group?.size ?? PanelAvatarSize.md;
    // In a group each face is ringed in the page background, so it separates
    // from the face underneath whatever surface the stack sits on.
    final ringed = group != null;

    final initials = Center(
      child: Text(
        fallback ?? '?',
        maxLines: 1,
        textAlign: TextAlign.center,
        style: theme.typography.style(
          resolved.textSize,
          weight: FontWeight.w500,
          color: c.mutedForeground,
        ),
      ),
    );

    final picture = image;
    final face = picture == null
        ? initials
        // Rounded itself rather than only clipped by the ring around it, so
        // no corner of the photo shows between the ring and the circle.
        : ClipOval(
            child: Image(
              image: picture,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => initials,
            ),
          );

    Widget avatar = Container(
      width: resolved.diameter,
      height: resolved.diameter,
      decoration: BoxDecoration(
        color: c.surfaceSecondary,
        shape: BoxShape.circle,
        border: ringed
            ? Border.all(color: c.background, width: 2)
            : Border.all(color: c.border),
      ),
      child: face,
    );

    final label = semanticLabel ?? fallback;
    avatar = Semantics(
      container: label != null,
      image: true,
      label: label,
      excludeSemantics: true,
      child: avatar,
    );

    final overlay = badge;
    if (overlay == null) return avatar;
    // The face clips to its circle, which would cut a corner badge in half,
    // so the badge hangs off an unclipped stack around it.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        PositionedDirectional(
          top: -4,
          end: -4,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: c.background, width: 2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: overlay,
          ),
        ),
      ],
    );
  }
}

class _AvatarGroupScope extends InheritedWidget {
  const _AvatarGroupScope({required this.size, required super.child});

  final PanelAvatarSize size;

  static _AvatarGroupScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AvatarGroupScope>();

  @override
  bool updateShouldNotify(_AvatarGroupScope oldWidget) =>
      size != oldWidget.size;
}

/// A row of avatars, each sliding under the one before it, with the people
/// who did not fit counted at the end.
///
/// ```dart
/// PanelAvatarGroup(
///   max: 3,
///   total: members.length,
///   children: [
///     for (final m in members)
///       PanelAvatar(image: NetworkImage(m.photo), fallback: m.initials),
///   ],
/// )
/// ```
///
/// The first face is on top, and screen readers meet the faces in order with
/// the count last. Each face is ringed in the page background so it separates
/// from the one underneath.
class PanelAvatarGroup extends StatelessWidget {
  /// Creates a stack of avatars.
  const PanelAvatarGroup({
    super.key,
    required this.children,
    this.size = PanelAvatarSize.md,
    this.max,
    this.total,
    this.overlap,
  });

  /// The faces, usually [PanelAvatar]s.
  final List<Widget> children;

  /// The size of every avatar in the stack. An avatar's own size still wins.
  final PanelAvatarSize size;

  /// How many faces to show; the rest are counted into a trailing "+N". It
  /// caps the faces, not the row: three of five people shows three avatars and
  /// a "+2". A cap below one is no cap.
  final int? max;

  /// How many people there are, when [children] are only the first few of
  /// them: three faces out of forty read "+37". A total below the number of
  /// faces is stale and ignored.
  final int? total;

  /// How far each avatar slides under the one before it. Defaults to a third
  /// of the diameter; clamped so it can close the stack up entirely but never
  /// open it into a gap.
  final double? overlap;

  /// How many faces show and how many are counted, for [count] people.
  static ({int visible, int overflow}) countOf(
    int count, {
    int? max,
    int? total,
  }) {
    final people = math.max(count, 0);
    final capped = max != null && max >= 1 ? math.min(max, people) : people;
    final population = total != null ? math.max(total, people) : people;
    return (visible: capped, overflow: math.max(population - capped, 0));
  }

  /// How far one avatar of [size] slides under its neighbour.
  static double overlapOf(PanelAvatarSize size, [double? overlap]) {
    final diameter = size.diameter;
    if (overlap == null || !overlap.isFinite) {
      return (diameter * _overlapRatio).roundToDouble();
    }
    return overlap.clamp(0.0, diameter);
  }

  @override
  Widget build(BuildContext context) {
    final (:visible, :overflow) = countOf(
      children.length,
      max: max,
      total: total,
    );
    final faces = <Widget>[
      for (var i = 0; i < visible; i++) children[i],
      if (overflow > 0)
        PanelAvatar(fallback: '+$overflow', semanticLabel: '$overflow more'),
    ];

    return _AvatarGroupScope(
      size: size,
      child: Semantics(
        container: true,
        role: SemanticsRole.list,
        child: _AvatarStack(
          overlap: overlapOf(size, overlap),
          children: [
            for (var i = 0; i < faces.length; i++)
              Semantics(
                container: true,
                role: SemanticsRole.listItem,
                sortKey: OrdinalSortKey(i.toDouble()),
                child: faces[i],
              ),
          ],
        ),
      ),
    );
  }
}

/// Lays its children out in a row, each overlapping the one before it by
/// [overlap], and paints them so the first is on top.
class _AvatarStack extends MultiChildRenderObjectWidget {
  const _AvatarStack({required this.overlap, required super.children});

  final double overlap;

  @override
  _RenderAvatarStack createRenderObject(BuildContext context) =>
      _RenderAvatarStack(
        overlap: overlap,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAvatarStack renderObject,
  ) {
    renderObject
      ..overlap = overlap
      ..textDirection = Directionality.of(context);
  }
}

class _AvatarStackParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderAvatarStack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _AvatarStackParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _AvatarStackParentData> {
  _RenderAvatarStack({
    required double overlap,
    required TextDirection textDirection,
  }) : _overlap = overlap,
       _textDirection = textDirection;

  double _overlap;
  set overlap(double value) {
    if (value == _overlap) return;
    _overlap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _AvatarStackParentData) {
      child.parentData = _AvatarStackParentData();
    }
  }

  /// Where each child starts along the row, from the start edge.
  List<double> _starts(List<double> widths) {
    final starts = <double>[];
    var x = 0.0;
    for (var i = 0; i < widths.length; i++) {
      if (i > 0) x += math.max(widths[i - 1] - _overlap, 0);
      starts.add(x);
    }
    return starts;
  }

  double _extent(List<double> widths) {
    if (widths.isEmpty) return 0;
    return _starts(widths).last + widths.last;
  }

  List<Size> _childSizes(
    BoxConstraints constraints,
    Size Function(RenderBox child, BoxConstraints constraints) measure,
  ) {
    final childConstraints = BoxConstraints(maxHeight: constraints.maxHeight);
    final sizes = <Size>[];
    var child = firstChild;
    while (child != null) {
      sizes.add(measure(child, childConstraints));
      child = childAfter(child);
    }
    return sizes;
  }

  Size _sizeFor(BoxConstraints constraints, List<Size> sizes) {
    final width = _extent([for (final s in sizes) s.width]);
    final height = sizes.fold(0.0, (h, s) => math.max(h, s.height));
    return constraints.constrain(Size(width, height));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final sizes = _childSizes(
      constraints,
      (child, childConstraints) => child.getDryLayout(childConstraints),
    );
    return _sizeFor(constraints, sizes);
  }

  @override
  void performLayout() {
    final sizes = _childSizes(constraints, (child, childConstraints) {
      child.layout(childConstraints, parentUsesSize: true);
      return child.size;
    });
    size = _sizeFor(constraints, sizes);
    final starts = _starts([for (final s in sizes) s.width]);
    var i = 0;
    var child = firstChild;
    while (child != null) {
      final childSize = sizes[i];
      final x = _textDirection == TextDirection.ltr
          ? starts[i]
          : size.width - starts[i] - childSize.width;
      (child.parentData! as _AvatarStackParentData).offset = Offset(
        x,
        (size.height - childSize.height) / 2,
      );
      child = childAfter(child);
      i++;
    }
  }

  double _intrinsicWidth(double Function(RenderBox child) measure) {
    final widths = <double>[];
    var child = firstChild;
    while (child != null) {
      widths.add(measure(child));
      child = childAfter(child);
    }
    return _extent(widths);
  }

  double _intrinsicHeight(double Function(RenderBox child) measure) {
    var height = 0.0;
    var child = firstChild;
    while (child != null) {
      height = math.max(height, measure(child));
      child = childAfter(child);
    }
    return height;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _intrinsicHeight((child) => child.getMinIntrinsicHeight(double.infinity));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _intrinsicHeight((child) => child.getMaxIntrinsicHeight(double.infinity));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) {
    // The first face is on top, so the row is painted from its far end back.
    var child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as _AvatarStackParentData;
      context.paintChild(child, parentData.offset + offset);
      child = parentData.previousSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // The reverse of the paint order: the face on top answers first.
    var child = firstChild;
    while (child != null) {
      final current = child;
      final parentData = current.parentData! as _AvatarStackParentData;
      final hit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (result, transformed) =>
            current.hitTest(result, position: transformed),
      );
      if (hit) return true;
      child = parentData.nextSibling;
    }
    return false;
  }
}
