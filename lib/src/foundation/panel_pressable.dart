import 'dart:ui' show SemanticsRole;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_motion.dart';
import 'panel_hit_slop.dart';
import '../theme/panel_theme.dart';

/// The interaction state a [PanelPressable] hands to its builder.
@immutable
class PanelPressState {
  /// Creates a state snapshot.
  const PanelPressState({
    this.pressed = false,
    this.hovered = false,
    this.focused = false,
    this.enabled = true,
  });

  /// A pointer is down on the control.
  final bool pressed;

  /// A mouse is over the control.
  final bool hovered;

  /// The control has keyboard focus and should show it.
  final bool focused;

  /// The control accepts input.
  final bool enabled;
}

/// Builds a pressable's content from its interaction state.
typedef PanelPressableBuilder =
    Widget Function(BuildContext context, PanelPressState state);

/// The shared base of every interactive PanelUI component.
///
/// While pressed, the content shrinks to [pressScale] (0.97 by default) over
/// 80ms, and on release it springs back. That small give is PanelUI's press
/// feedback in place of a ripple, and it stays off when the platform asks for
/// reduced motion.
///
/// It also does what a control needs on the web and desktop: it takes keyboard
/// focus, activates on Enter and Space, reports hover, and draws a focus ring
/// (when [focusRingRadius] is set) only when focus arrived from the keyboard.
class PanelPressable extends StatefulWidget {
  /// Creates a pressable. Give it a [child], or a [builder] to style the
  /// content by its state.
  const PanelPressable({
    super.key,
    this.onPressed,
    this.onLongPress,
    this.child,
    this.builder,
    this.enabled = true,
    this.pressScale = 0.97,
    this.pressOpacity = 1,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.semanticLabel,
    this.semanticHint,
    this.isButton = true,
    this.toggled,
    this.checked,
    this.mixed,
    this.selected,
    this.inMutuallyExclusiveGroup,
    this.expanded,
    this.semanticValue,
    this.semanticRole,
    this.hitSlop,
    this.focusRingRadius,
    this.focusRingColor,
    this.behavior = HitTestBehavior.opaque,
  }) : assert(child != null || builder != null, 'Pass a child or a builder.');

  /// Called on tap, and on Enter or Space while focused.
  final VoidCallback? onPressed;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// The content.
  final Widget? child;

  /// Builds the content from the interaction state. Takes precedence over
  /// [child].
  final PanelPressableBuilder? builder;

  /// Whether the control accepts input. A control with no callbacks is
  /// disabled whatever this says.
  final bool enabled;

  /// Scale applied while pressed. 1 turns it off.
  final double pressScale;

  /// Opacity applied while pressed, as a fraction of full. 1 turns it off.
  final double pressOpacity;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// The cursor over the control. Defaults to a pointer while enabled.
  final MouseCursor? mouseCursor;

  /// The accessible name. When set it replaces the content's own text for
  /// screen readers, so the two are not both read.
  final String? semanticLabel;

  /// An accessible hint describing the result of activating.
  final String? semanticHint;

  /// Whether screen readers announce this as a button.
  final bool isButton;

  /// Announced on/off state, for a switch.
  final bool? toggled;

  /// Announced checked state, for a checkbox or a radio.
  final bool? checked;

  /// Announced mixed state, for a checkbox governing a partly checked group.
  final bool? mixed;

  /// Announced selected state, for a tab or a segment.
  final bool? selected;

  /// Whether the control is one of a set where only one can be chosen.
  final bool? inMutuallyExclusiveGroup;

  /// Announced expanded or collapsed state, for a disclosure trigger.
  final bool? expanded;

  /// An announced value, such as "step 2 of 3" or the chosen option.
  final String? semanticValue;

  /// The control's role, for the roles a flag cannot express (a tab).
  final SemanticsRole? semanticRole;

  /// Room around the control that also takes a press, without changing its
  /// layout: PanelUI's `hitSlop`, for controls drawn smaller than a finger.
  /// It reaches only as far as the parent's own bounds.
  final EdgeInsets? hitSlop;

  /// The shape of the keyboard focus ring. Null draws no ring.
  final BorderRadius? focusRingRadius;

  /// The ring colour. Defaults to the theme's `ring` token at 40%.
  final Color? focusRingColor;

  /// How the gesture detector hit-tests.
  final HitTestBehavior behavior;

  @override
  State<PanelPressable> createState() => _PanelPressableState();
}

class _PanelPressableState extends State<PanelPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled =>
      widget.enabled &&
      (widget.onPressed != null || widget.onLongPress != null);

  bool get _animates =>
      !panelReduceMotion(context) &&
      (widget.pressScale != 1 || widget.pressOpacity != 1);

  @override
  void didUpdateWidget(PanelPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && (_pressed || _hovered)) {
      _pressed = false;
      _hovered = false;
      _press.value = 0;
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _handleDown(TapDownDetails details) {
    setState(() => _pressed = true);
    if (_animates) {
      _press.animateTo(1, duration: PanelDurations.pressIn, curve: panelEase);
    }
  }

  void _handleUp() {
    if (!mounted) return;
    // A pressable disabled mid-press (a stepper reaching its bound) has its
    // tap cancelled while the tree rebuilds; settle the state after the frame
    // rather than marking it dirty in the middle of a build.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _handleUp());
      return;
    }
    setState(() => _pressed = false);
    if (_animates) {
      _press.springTo(0, PanelSprings.press);
    } else {
      _press.value = 0;
    }
  }

  void _activateFromKeyboard() {
    if (!_enabled) return;
    widget.onPressed?.call();
    if (!_animates) return;
    _press
        .animateTo(1, duration: PanelDurations.pressIn, curve: panelEase)
        .whenCompleteOrCancel(() {
          if (mounted) _press.springTo(0, PanelSprings.press);
        });
  }

  @override
  Widget build(BuildContext context) {
    final state = PanelPressState(
      pressed: _pressed,
      hovered: _hovered,
      focused: _focused,
      enabled: _enabled,
    );
    Widget content = widget.builder?.call(context, state) ?? widget.child!;

    content = AnimatedBuilder(
      animation: _press,
      child: content,
      builder: (context, child) {
        final t = _press.value;
        var result = child!;
        if (widget.pressScale != 1 && t != 0) {
          result = Transform.scale(
            scale: 1 + t * (widget.pressScale - 1),
            child: result,
          );
        }
        if (widget.pressOpacity != 1 && t != 0) {
          result = Opacity(
            opacity: (1 + t * (widget.pressOpacity - 1)).clamp(0.0, 1.0),
            child: result,
          );
        }
        return result;
      },
    );

    final ringRadius = widget.focusRingRadius;
    if (ringRadius != null && _focused) {
      final ring =
          widget.focusRingColor ??
          PanelTheme.of(context).colors.ring.withValues(alpha: 0.4);
      content = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: ringRadius,
          border: Border.all(
            color: ring,
            width: 3,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: content,
      );
    }

    // A label names the control in place of its content, the way PanelUI's
    // accessibilityLabel does; without this the visible text would be read
    // after it a second time. Only the content is excluded, so the focus
    // handling below still marks the node focusable.
    if (widget.semanticLabel != null) {
      content = ExcludeSemantics(child: content);
    }

    final enabled = _enabled;
    // Outermost, so the layers below see a press in the slop as one inside
    // them: each of them would otherwise reject it at its own edge.
    return _withHitSlop(
      Semantics(
        container: true,
        button: widget.isButton,
        enabled: enabled,
        toggled: widget.toggled,
        checked: widget.checked,
        mixed: widget.mixed,
        selected: widget.selected,
        inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
        expanded: widget.expanded,
        value: widget.semanticValue,
        role: widget.semanticRole,
        label: widget.semanticLabel,
        hint: widget.semanticHint,
        onTap: enabled && widget.onPressed != null ? widget.onPressed : null,
        onLongPress: enabled && widget.onLongPress != null
            ? widget.onLongPress
            : null,
        child: FocusableActionDetector(
          enabled: enabled,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          mouseCursor:
              widget.mouseCursor ??
              (enabled ? SystemMouseCursors.click : MouseCursor.defer),
          onShowFocusHighlight: (value) {
            if (_focused != value) setState(() => _focused = value);
          },
          onShowHoverHighlight: (value) {
            if (_hovered != value) setState(() => _hovered = value);
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activateFromKeyboard();
                return null;
              },
            ),
            ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
              onInvoke: (_) {
                _activateFromKeyboard();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: widget.behavior,
            excludeFromSemantics: true,
            onTapDown: enabled ? _handleDown : null,
            onTapUp: enabled ? (_) => _handleUp() : null,
            onTapCancel: enabled ? _handleUp : null,
            onTap: enabled ? widget.onPressed : null,
            onLongPress: enabled ? widget.onLongPress : null,
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _withHitSlop(Widget child) {
    final slop = widget.hitSlop;
    if (slop == null || slop == EdgeInsets.zero) return child;
    return PanelHitSlop(slop: slop, child: child);
  }
}
