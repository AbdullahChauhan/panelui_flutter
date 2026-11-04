import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Widens the area that takes a press around [child] without changing its
/// layout: React Native's `hitSlop`.
///
/// A press that lands in the slop is handed to [child] as though it had landed
/// on the child's nearest edge, so a gesture detector inside fires for a finger
/// that only just missed. Events still carry their true position, so a slider
/// reading where the finger is sees the real point.
///
/// As in React Native, the slop reaches only as far as the ancestors' own
/// bounds: a parent never asks a child about a point outside itself.
///
/// Internal to the selection components; not exported from the package.
class SelectionHitSlop extends SingleChildRenderObjectWidget {
  /// Widens [child]'s target by [slop] on each side.
  const SelectionHitSlop({super.key, required this.slop, super.child});

  /// How far the target reaches past each edge.
  final EdgeInsets slop;

  @override
  RenderSelectionHitSlop createRenderObject(BuildContext context) =>
      RenderSelectionHitSlop(slop);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSelectionHitSlop renderObject,
  ) {
    renderObject.slop = slop;
  }
}

/// The render object behind [SelectionHitSlop].
class RenderSelectionHitSlop extends RenderProxyBox {
  /// Creates a render object that widens its child's target by [slop].
  RenderSelectionHitSlop(this.slop);

  /// How far the target reaches past each edge. Changing it needs neither a
  /// layout nor a paint: it is read at the next hit test.
  EdgeInsets slop;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!slop.inflateRect(Offset.zero & size).contains(position)) return false;
    // `Size.contains` excludes the far edges, so stay just inside them.
    final inside = Offset(
      position.dx.clamp(0.0, size.width > 0 ? size.width - 0.001 : 0.0),
      position.dy.clamp(0.0, size.height > 0 ? size.height - 0.001 : 0.0),
    );
    if (hitTestChildren(result, position: inside) || hitTestSelf(inside)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
