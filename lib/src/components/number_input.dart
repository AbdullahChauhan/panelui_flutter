import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart'
    show InputDecoration, Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../icons/panel_icon.dart';
import '../icons/panel_icons.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';
import 'input.dart' show PanelInputVariant;
import 'label.dart';

/// How big a [PanelNumberInput] is.
enum PanelNumberInputSize {
  /// 40pt tall, 14px digits.
  sm(40, 14, 16),

  /// 48pt tall, 16px digits. The default.
  md(48, 16, 18),

  /// 56pt tall, 16px digits.
  lg(56, 16, 20);

  const PanelNumberInputSize(this.height, this.fontSize, this.iconSize);

  /// Height; the − and + buttons are squares of it.
  final double height;

  /// Size of the digits.
  final double fontSize;

  /// Size of the − and + glyphs.
  final double iconSize;
}

/// A number stepped by two buttons or typed by hand.
///
/// Past a handful of steps, nudging is worse than typing, so it keeps both: a
/// − and a + at the ends, and an editable field in the middle, reconciled
/// through one clamped, step-snapped number. Holding a button repeats after
/// 400ms and then every 80ms, and stops on its own at a bound.
///
/// Typing may be briefly invalid (empty, a lone `-`, a trailing `.`), because
/// clamping every keystroke fights a person mid-number. The text is committed
/// when the field loses focus or is submitted, and falls back to the last
/// good value when it cannot be read as a number.
///
/// ```dart
/// PanelNumberInput(
///   label: 'Quantity',
///   value: qty,
///   min: 1,
///   max: 10,
///   onChanged: (v) => setState(() => qty = v),
/// )
/// ```
class PanelNumberInput extends StatefulWidget {
  /// Creates a number input.
  const PanelNumberInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = double.negativeInfinity,
    this.max = double.infinity,
    this.step = 1,
    this.label,
    this.description,
    this.errorMessage,
    this.isInvalid = false,
    this.isRequired = false,
    this.variant = PanelInputVariant.outline,
    this.size = PanelNumberInputSize.md,
    this.placeholder,
    this.formatValue,
    this.haptics = false,
  }) : assert(step > 0);

  /// The current value.
  final double value;

  /// Called with each new value. Null disables the input.
  final ValueChanged<double>? onChanged;

  /// The smallest value.
  final double min;

  /// The largest value.
  final double max;

  /// The increment, which also sets how many decimals are kept.
  final double step;

  /// The label above the control.
  final String? label;

  /// A muted line under the control.
  final String? description;

  /// An error under the control, replacing [description].
  final String? errorMessage;

  /// Draws the control in its error colours.
  final bool isInvalid;

  /// Marks the label as required.
  final bool isRequired;

  /// Outline or filled.
  final PanelInputVariant variant;

  /// The size.
  final PanelNumberInputSize size;

  /// Hint text while the field is empty.
  final String? placeholder;

  /// Formats the value for display. Defaults to the step's precision.
  final String Function(double value)? formatValue;

  /// Tick the haptic engine on each step.
  final bool haptics;

  @override
  State<PanelNumberInput> createState() => _PanelNumberInputState();
}

class _PanelNumberInputState extends State<PanelNumberInput> {
  late final TextEditingController _text = TextEditingController(
    text: _format(widget.value),
  );
  final FocusNode _focus = FocusNode();
  Timer? _delay;
  Timer? _repeat;
  late double _live = widget.value;
  bool _pointerStepped = false;

  bool get _enabled => widget.onChanged != null;

  int get _precision {
    final text = widget.step.toString();
    final dot = text.indexOf('.');
    if (dot < 0 || text.endsWith('.0')) return 0;
    return math.min(15, text.length - dot - 1);
  }

  String _format(double value) {
    if (widget.formatValue != null) return widget.formatValue!(value);
    return value.toStringAsFixed(_precision);
  }

  double _normalize(double value) {
    final base = widget.min.isFinite ? widget.min : 0.0;
    final snapped = ((value - base) / widget.step).round() * widget.step + base;
    final factor = math.pow(10, _precision);
    final rounded = (snapped * factor).round() / factor;
    return rounded.clamp(widget.min, widget.max).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(PanelNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    _live = widget.value;
    // While focused the field shows what is being typed, not the value.
    if (!_focus.hasFocus) _text.text = _format(widget.value);
  }

  @override
  void dispose() {
    _stopRepeat();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final parsed = double.tryParse(_text.text.trim());
    final next = parsed == null ? widget.value : _normalize(parsed);
    _text.text = _format(next);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  /// Moves one step in [direction]. Returns whether another step is possible.
  bool _stepBy(int direction) {
    final next = _normalize(_live + direction * widget.step);
    if (next == _live) return false;
    _live = next;
    if (widget.haptics) HapticFeedback.selectionClick();
    widget.onChanged?.call(next);
    return direction < 0 ? next > widget.min : next < widget.max;
  }

  void _startRepeat(int direction) {
    _stopRepeat();
    if (!_stepBy(direction)) return;
    _delay = Timer(const Duration(milliseconds: 400), () {
      _repeat = Timer.periodic(const Duration(milliseconds: 80), (_) {
        if (!mounted || !_stepBy(direction)) _stopRepeat();
      });
    });
  }

  void _endPointer() {
    _stopRepeat();
    // The tap callback runs after this, in the same event; clear the flag
    // once it has had its chance, so a cancelled tap does not leave it set.
    scheduleMicrotask(() => _pointerStepped = false);
  }

  void _stopRepeat() {
    _delay?.cancel();
    _repeat?.cancel();
    _delay = null;
    _repeat = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final size = widget.size;
    final invalid = widget.isInvalid || widget.errorMessage != null;
    final atMin = widget.value <= widget.min;
    final atMax = widget.value >= widget.max;
    final noun = widget.label ?? 'value';

    Widget stepper(int direction, bool atBound) {
      final enabled = _enabled && !atBound;
      return Listener(
        onPointerDown: enabled
            ? (_) {
                _pointerStepped = true;
                _startRepeat(direction);
              }
            : null,
        onPointerUp: (_) => _endPointer(),
        onPointerCancel: (_) => _endPointer(),
        child: PanelPressable(
          // A pointer steps on the way down, through the listener above, so a
          // hold can repeat. The tap that follows must not step again; this
          // callback is for keyboard and screen-reader activation.
          onPressed: enabled
              ? () {
                  if (_pointerStepped) {
                    _pointerStepped = false;
                    return;
                  }
                  _stepBy(direction);
                }
              : null,
          pressOpacity: 0.6,
          semanticLabel: '${direction < 0 ? 'Decrease' : 'Increase'} $noun',
          child: Opacity(
            opacity: atBound ? 0.4 : 1,
            child: SizedBox.square(
              dimension: size.height - 2,
              child: Center(
                child: PanelIcon(
                  direction < 0 ? PanelIcons.minus : PanelIcons.plus,
                  size: size.iconSize,
                  color: c.foreground,
                  // The same weight at both ends, or they read as different
                  // glyphs.
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final style = theme.typography
        .sized(size.fontSize, weight: FontWeight.w500, color: c.foreground)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    final field = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _text,
        focusNode: _focus,
        enabled: _enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(
          decimal: _precision > 0,
          signed: widget.min < 0,
        ),
        onSubmitted: (_) => _commit(),
        onTap: () => _text.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _text.text.length,
        ),
        style: style,
        cursorColor: c.foreground,
        decoration: InputDecoration.collapsed(
          hintText: widget.placeholder,
          hintStyle: style.copyWith(color: c.mutedForeground),
        ),
      ),
    );

    final control = Container(
      height: size.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.variant == PanelInputVariant.outline
            ? c.background
            : c.muted,
        borderRadius: BorderRadius.circular(theme.radii.lg),
        border: Border.all(
          color: invalid
              ? c.destructive
              : widget.variant == PanelInputVariant.outline
              ? c.input
              : const Color(0x00000000),
        ),
      ),
      child: Row(
        children: [
          stepper(-1, atMin),
          Expanded(
            child: Semantics(
              label: widget.label,
              value: _format(widget.value),
              child: field,
            ),
          ),
          stepper(1, atMax),
        ],
      ),
    );

    final message = widget.errorMessage ?? widget.description;
    return Opacity(
      opacity: _enabled ? 1 : 0.64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          if (widget.label != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PanelLabel(
                widget.label!,
                isRequired: widget.isRequired,
                isInvalid: invalid,
              ),
            ),
          control,
          if (message != null)
            Text(
              message,
              style: theme.typography.style(
                PanelTextSize.sm,
                color: widget.errorMessage != null
                    ? c.destructive
                    : c.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }
}
