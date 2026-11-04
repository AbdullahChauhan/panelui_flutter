import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';

/// How big a [PanelSwitch] is.
enum PanelSwitchSize {
  /// A 32 × 20 track.
  xs(32, 20, 12),

  /// A 40 × 24 track.
  sm(40, 24, 16),

  /// A 48 × 28 track, the default.
  md(48, 28, 20),

  /// A 56 × 32 track.
  lg(56, 32, 24),

  /// A 64 × 36 track.
  xl(64, 36, 28);

  const PanelSwitchSize(this.width, this.height, this.thumb);

  /// Track width.
  final double width;

  /// Track height.
  final double height;

  /// Thumb diameter.
  final double thumb;

  /// How far the thumb travels: the width left once the thumb, 3pt of
  /// padding and a 1pt border on either side are taken out.
  double get travel => width - thumb - 8;
}

/// An on/off switch.
///
/// The thumb springs across the track while the `primary` fill fades in
/// beneath it, both on one animation, so a flip never rebuilds more than the
/// switch itself.
///
/// ```dart
/// PanelSwitch(value: wifi, onChanged: (v) => setState(() => wifi = v))
/// ```
class PanelSwitch extends StatefulWidget {
  /// Creates a switch.
  const PanelSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = PanelSwitchSize.md,
    this.semanticLabel,
    this.haptics = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the new value. Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// The size.
  final PanelSwitchSize size;

  /// The accessible name.
  final String? semanticLabel;

  /// Tick the haptic engine on each flip.
  final bool haptics;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  @override
  State<PanelSwitch> createState() => _PanelSwitchState();
}

class _PanelSwitchState extends State<PanelSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController.unbounded(
    vsync: this,
    value: widget.value ? 1 : 0,
  );

  @override
  void didUpdateWidget(PanelSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    final target = widget.value ? 1.0 : 0.0;
    if (panelReduceMotion(context)) {
      _progress.value = target;
    } else {
      _progress.springTo(target, PanelSprings.toggle);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.haptics) HapticFeedback.selectionClick();
    widget.onChanged?.call(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final size = widget.size;
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final track = AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final t = _progress.value;
        return Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: c.input,
            borderRadius: BorderRadius.circular(size.height / 2),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(size.height / 2),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4 + (rtl ? (1 - t) : t) * size.travel,
                child: Container(
                  width: size.thumb,
                  height: size.thumb,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                    boxShadow: theme.shadows.sm,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return PanelPressable(
      onPressed: enabled ? _toggle : null,
      pressScale: 1,
      isButton: false,
      toggled: widget.value,
      semanticLabel: widget.semanticLabel,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      focusRingRadius: BorderRadius.circular(size.height / 2),
      child: Opacity(opacity: enabled ? 1 : 0.5, child: track),
    );
  }
}
