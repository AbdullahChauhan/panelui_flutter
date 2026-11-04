import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_decoration.dart';
import '../foundation/panel_focus_ring.dart';
import '../foundation/panel_pressable.dart';
import '../theme/panel_color_mix.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';

/// How big a [PanelSwitch] is.
///
/// Each track is its thumb plus 3pt of padding and a 1pt border on either
/// side, and about twice as wide as it is tall.
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

  /// How far the thumb travels: what is left of the track's width once the
  /// thumb, the padding and the border on either side are taken out.
  double get travel => width - thumb - 2 * (_padding + _border);

  /// Room around the track that also takes a press, so the target reaches
  /// 48pt on both axes without the switch standing 48pt tall in every row.
  /// From `md` up the track is already 48pt wide, which is why only the two
  /// smallest have horizontal room.
  EdgeInsets get hitSlop => switch (this) {
    xs => const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    sm => const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
    md => const EdgeInsets.symmetric(vertical: 10),
    lg => const EdgeInsets.symmetric(vertical: 8),
    xl => const EdgeInsets.symmetric(vertical: 6),
  };
}

/// An on/off switch.
///
/// The thumb springs across the track while the `primary` fill fades in
/// beneath it, both on one animation, so a flip rebuilds nothing but the
/// thumb's offset.
///
/// ```dart
/// PanelSwitch(value: wifi, onChanged: (v) => setState(() => wifi = v))
/// ```
///
/// PanelUI's `native` mode, which hands the control to the platform, is
/// Flutter's own `Switch.adaptive`.
class PanelSwitch extends StatefulWidget {
  /// Creates a switch.
  const PanelSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = PanelSwitchSize.md,
    this.semanticLabel,
    this.semanticHint,
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

  /// An accessible hint, such as what the setting does.
  final String? semanticHint;

  /// Tick the haptic engine on each flip: a toggle you feel click rather than
  /// one that only slides.
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
  // Unbounded so the spring's overshoot is drawn rather than clamped away.
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
    final enabled = widget.onChanged != null;
    return PanelPressable(
      onPressed: enabled ? _toggle : null,
      // PanelUI draws a switch on a plain Pressable: no press shrink.
      pressScale: 1,
      isButton: false,
      toggled: widget.value,
      semanticLabel: widget.semanticLabel,
      semanticHint: widget.semanticHint,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      hitSlop: widget.size.hitSlop,
      builder: (context, state) => Opacity(
        opacity: enabled ? 1 : 0.5,
        child: _SwitchTrack(
          size: widget.size,
          progress: _progress,
          hovered: state.hovered,
          focused: state.focused,
        ),
      ),
    );
  }
}

/// The track's border: transparent, so the track colour rings the fill.
const double _border = 1;

/// The space between the track's border and the thumb (`p-[3px]`).
const double _padding = 3;

/// The track, its fill and the thumb, drawn at [progress] from off (0) to on
/// (1).
class _SwitchTrack extends StatelessWidget {
  const _SwitchTrack({
    required this.size,
    required this.progress,
    required this.hovered,
    required this.focused,
  });

  final PanelSwitchSize size;
  final Animation<double> progress;
  final bool hovered;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final pill = BorderRadius.circular(size.height / 2);
    // The track is laid out mirrored in a right-to-left row, but an offset is
    // not, so "on" would otherwise still be on the right.
    final direction = Directionality.of(context) == TextDirection.rtl ? -1 : 1;

    final thumb = Container(
      width: size.thumb,
      height: size.thumb,
      decoration: PanelBoxDecoration(
        // PanelUI's `bg-white`: the thumb is white in every theme.
        color: const Color(0xFFFFFFFF),
        shape: BoxShape.circle,
        boxShadow: theme.shadows.sm,
      ),
    );

    final Widget track = Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(_border),
      decoration: BoxDecoration(
        // The web package's hover: the track darkens 8% of the way towards
        // the foreground.
        color: hovered ? c.input.mixOklab(c.foreground, 0.08) : c.input,
        borderRadius: pill,
      ),
      child: Stack(
        children: [
          // Inside the transparent border, so the track colour rings it.
          Positioned.fill(
            child: FadeTransition(
              opacity: progress,
              child: DecoratedBox(
                decoration: BoxDecoration(color: c.primary, borderRadius: pill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(_padding),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, child) => Transform.translate(
                  offset: Offset(direction * progress.value * size.travel, 0),
                  child: child,
                ),
                child: thumb,
              ),
            ),
          ),
        ],
      ),
    );
    // The web package's `ring-2 ring-ring ring-offset-2`.
    return PanelFocusRing(
      visible: focused,
      borderRadius: pill,
      style: PanelFocusRingStyle.offset,
      child: track,
    );
  }
}
