import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/material.dart'
    show InputDecoration, Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_hit_slop.dart';
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

  /// Height, and the width of the − and + buttons.
  final double height;

  /// Size of the digits. It comes without a paired line height, so the line
  /// box is the font's own and the number centres on the axis the − and the +
  /// sit on.
  final double fontSize;

  /// Size of the − and + glyphs, which scale with their target.
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
///
/// It is controlled, as Flutter's own controls are: [value] is shown snapped
/// and clamped, and every change is reported to [onChanged].
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
    this.editable = true,
    this.variant = PanelInputVariant.outline,
    this.size = PanelNumberInputSize.md,
    this.placeholder,
    this.formatValue,
    this.haptics = false,
    this.focusNode,
    this.textInputAction,
  }) : assert(step > 0);

  /// The current value.
  final double value;

  /// Called with each new value. Null disables the input.
  final ValueChanged<double>? onChanged;

  /// The smallest value. The − button disables here.
  final double min;

  /// The largest value. The + button disables here.
  final double max;

  /// The nudge per press, and the granularity the value snaps to. Its
  /// decimals are the ones the value keeps.
  final double step;

  /// The label above the control, and the field's name for screen readers.
  final String? label;

  /// A muted line under the control.
  final String? description;

  /// An error under the control, replacing [description].
  final String? errorMessage;

  /// Draws the control in its error colours.
  final bool isInvalid;

  /// Marks the field required: an asterisk on the label, and the state
  /// announced with the field.
  final bool isRequired;

  /// Whether the number can be typed. When false the middle is display-only
  /// and the buttons are the way to change it.
  final bool editable;

  /// Outline or filled.
  final PanelInputVariant variant;

  /// The size.
  final PanelNumberInputSize size;

  /// Hint text while the field is empty.
  final String? placeholder;

  /// Formats the value for display: units, currency, grouping. Typing still
  /// reads a bare number back. Defaults to the number as it is, which is
  /// already rounded to [step]'s decimals.
  final String Function(double value)? formatValue;

  /// Tick the haptic engine on each step.
  final bool haptics;

  /// Controls the field's focus. One is created if null.
  final FocusNode? focusNode;

  /// The keyboard's action button.
  final TextInputAction? textInputAction;

  @override
  State<PanelNumberInput> createState() => _PanelNumberInputState();
}

class _PanelNumberInputState extends State<PanelNumberInput> {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  /// What the field shows: while focused, whatever is being typed; otherwise
  /// the formatted value.
  late final TextEditingController _text = TextEditingController(
    text: _format(_value),
  );

  /// The value a held button steps from. It runs ahead of [_value] while a
  /// hold repeats faster than the parent rebuilds, so a step never strides
  /// off a stale number.
  late double _live = _value;

  Timer? _delay;
  Timer? _repeat;

  /// Whether the press under way already stepped on its way down, so the tap
  /// that ends it does not step again.
  bool _pointerStepped = false;

  bool get _enabled => widget.onChanged != null;

  /// [PanelNumberInput.value] snapped and clamped, whatever the parent passed.
  double get _value =>
      _normalize(widget.value, widget.min, widget.max, widget.step);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(PanelNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_handleFocus);
      _focusNode.addListener(_handleFocus);
    }
    // A hold on a control that has just been disabled may never hear its
    // release.
    if (!_enabled) _stopRepeat();
    _live = _value;
    if (!_focusNode.hasFocus) _show(_value);
  }

  @override
  void dispose() {
    _stopRepeat();
    _focusNode.removeListener(_handleFocus);
    _ownFocusNode?.dispose();
    _text.dispose();
    super.dispose();
  }

  String _format(double value) =>
      widget.formatValue?.call(value) ?? _jsNumberString(value);

  void _show(double value) {
    final text = _format(value);
    if (_text.text == text) return;
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _handleFocus() {
    if (_focusNode.hasFocus) {
      // The whole number, ready to be typed over. A tap's own caret lands
      // before focus does, so this comes after it.
      _text.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _text.text.length,
      );
    } else {
      _commit();
    }
  }

  /// Reads what was typed and commits it, snapped and clamped. Text that
  /// cannot be read as a number falls back to the last good value rather than
  /// to a surprising 0.
  void _commit() {
    // Nothing typed since the value was shown or last committed: a submit is
    // followed by a blur, and a formatted value such as "1,000" would not
    // read back as itself.
    if (_text.text == _format(_live)) return;
    final typed = _parseLeadingNumber(_text.text);
    final next = typed == null
        ? _live
        : _normalize(typed, widget.min, widget.max, widget.step);
    _show(next);
    if (next == _live) return;
    _live = next;
    widget.onChanged?.call(next);
  }

  /// Moves one step in [direction] from the live value. Returns whether there
  /// is room for another.
  bool _stepBy(int direction) {
    final next = _normalize(
      _live + direction * widget.step,
      widget.min,
      widget.max,
      widget.step,
    );
    if (next == _live) return false;
    if (widget.haptics) HapticFeedback.selectionClick();
    _live = next;
    // A focused field otherwise keeps what was typed, and its blur would
    // commit that back over the step.
    if (_focusNode.hasFocus) _show(next);
    widget.onChanged?.call(next);
    return direction > 0 ? next < widget.max : next > widget.min;
  }

  /// Steps once now, then after [_repeatDelay] every [_repeatInterval] until
  /// the press ends or a bound is reached. The bound stops it without the
  /// release, which a button disabled under the finger may never deliver.
  void _startRepeat(int direction) {
    _stopRepeat();
    if (!_stepBy(direction)) return;
    _delay = Timer(_repeatDelay, () {
      _repeat = Timer.periodic(_repeatInterval, (_) {
        if (!_stepBy(direction)) _stopRepeat();
      });
    });
  }

  void _stopRepeat() {
    _delay?.cancel();
    _repeat?.cancel();
    _delay = null;
    _repeat = null;
  }

  void _handlePointerDown(int direction) {
    _pointerStepped = true;
    // A press steps from what was typed, if anything was.
    _commit();
    _startRepeat(direction);
  }

  void _handlePointerUp() {
    _stopRepeat();
    // The tap that ends this press is handled after this, in the same event;
    // clear the flag once it has had its chance, so a cancelled tap does not
    // leave it set.
    scheduleMicrotask(() => _pointerStepped = false);
  }

  void _handleActivate(int direction) {
    if (_pointerStepped) {
      _pointerStepped = false;
      return;
    }
    _commit();
    _stepBy(direction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final size = widget.size;
    final value = _value;
    final invalid = widget.isInvalid || widget.errorMessage != null;
    final outline = widget.variant == PanelInputVariant.outline;
    final noun = widget.label ?? 'value';

    Widget stepper(int direction) {
      final atBound = direction < 0 ? value <= widget.min : value >= widget.max;
      final enabled = _enabled && !atBound;
      return _StepButton(
        icon: direction < 0 ? PanelIcons.minus : PanelIcons.plus,
        semanticLabel: '${direction < 0 ? 'Decrease' : 'Increase'} $noun',
        width: size.height,
        iconSize: size.iconSize,
        atBound: atBound,
        onPointerDown: enabled ? () => _handlePointerDown(direction) : null,
        onPointerUp: _handlePointerUp,
        onActivate: enabled ? () => _handleActivate(direction) : null,
      );
    }

    final style = theme.typography
        .sized(size.fontSize, weight: FontWeight.w500, color: c.foreground)
        // Tabular figures, so a centred number does not shuffle sideways as
        // it counts.
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    final field = Semantics(
      label: widget.label,
      isRequired: widget.isRequired ? true : null,
      validationResult: invalid
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: _text,
          focusNode: _focusNode,
          enabled: _enabled,
          readOnly: !widget.editable,
          canRequestFocus: widget.editable,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.numberWithOptions(
            decimal: _precisionOf(widget.step) > 0,
            // With a minus key wherever a negative is allowed, which the
            // plain number pad would not offer.
            signed: widget.min < 0,
          ),
          textInputAction: widget.textInputAction,
          onSubmitted: (_) => _commit(),
          style: style,
          cursorColor: c.foreground,
          decoration: InputDecoration.collapsed(
            hintText: widget.placeholder,
            hintStyle: style.copyWith(color: c.mutedForeground),
            hintFadeDuration: Duration.zero,
          ),
        ),
      ),
    );

    final control = Container(
      height: size.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: outline ? c.background : c.muted,
        borderRadius: BorderRadius.circular(theme.radii.lg),
        border: Border.all(
          color: invalid
              ? c.destructive
              : outline
              ? c.input
              : const Color(0x00000000),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          stepper(-1),
          Expanded(
            child: Center(
              // The whole height between the buttons is the field's.
              child: PanelHitSlop(
                slop: EdgeInsets.symmetric(vertical: size.height),
                child: field,
              ),
            ),
          ),
          stepper(1),
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
                isDisabled: !_enabled,
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

/// Wait before a held button starts repeating: a tap must not trip it.
const Duration _repeatDelay = Duration(milliseconds: 400);

/// Between repeats once holding: fast enough to cover ground.
const Duration _repeatInterval = Duration(milliseconds: 80);

/// The − or the + at one end of the control.
///
/// A pointer steps on its way down, through a [Listener], so a hold can
/// repeat; the tap that follows is the pressable's, and [onActivate] serves
/// keys and screen readers.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.width,
    required this.iconSize,
    required this.atBound,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onActivate,
  });

  final PanelIconData icon;
  final String semanticLabel;
  final double width;
  final double iconSize;

  /// Dims the button: the value is at the bound it moves towards.
  final bool atBound;

  /// Starts stepping. Null when the button is disabled.
  final VoidCallback? onPointerDown;

  /// Ends a hold. Always set, so a button disabled under the finger still
  /// hears the release.
  final VoidCallback onPointerUp;

  /// Steps once. Null when the button is disabled.
  final VoidCallback? onActivate;

  @override
  Widget build(BuildContext context) {
    final down = onPointerDown;
    return Listener(
      onPointerDown: down == null ? null : (_) => down(),
      onPointerUp: (_) => onPointerUp(),
      onPointerCancel: (_) => onPointerUp(),
      child: PanelPressable(
        onPressed: onActivate,
        pressOpacity: 0.6,
        semanticLabel: semanticLabel,
        child: Opacity(
          opacity: atBound ? 0.4 : 1,
          child: SizedBox(
            width: width,
            child: Center(
              child: PanelIcon(
                icon,
                size: iconSize,
                color: PanelTheme.of(context).colors.foreground,
                // The same weight at both ends, or the two read as different
                // glyphs.
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// JavaScript numbers carry about fifteen reliable decimal digits, and so
/// does a [double].
const int _maxDecimalPrecision = 15;

/// The decimals [step] implies, before the reliable-digits ceiling, from how
/// it prints: `0.25` has two, `1e-7` seven.
int _requestedPrecision(double step) {
  if (!step.isFinite) return 0;
  final parts = _jsNumberString(step.abs()).split('e');
  final decimals = parts.first.split('.').elementAtOrNull(1)?.length ?? 0;
  final exponent = parts.length > 1 ? int.parse(parts[1]) : 0;
  return math.max(0, decimals - exponent);
}

/// The decimals a value stepped by [step] keeps.
int _precisionOf(double step) =>
    math.min(_maxDecimalPrecision, _requestedPrecision(step));

/// Snaps [value] to the nearest step from [min] (or from 0 when there is no
/// minimum), clears binary drift at the step's precision, and clamps it.
///
/// The drift is cleared at the minimum's precision too, where PanelUI uses
/// the step's alone: a minimum of 0.5 with a step of 1 would otherwise round
/// every value off its step, and the value shown would move on each render.
double _normalize(double value, double min, double max, double step) {
  final base = min.isFinite ? min : 0.0;
  final offset = (value - base) / step;
  final snapped = step.isFinite && offset.isFinite
      ? _jsRound(offset) * step + base
      : value;
  // A step finer than the reliable digits cannot be tidied at its own
  // precision: rounding at the ceiling would land on zero and take the value
  // with it. The snap has already put it on the step.
  if (_requestedPrecision(step) > _maxDecimalPrecision) {
    return _clamp(snapped, min, max);
  }
  final precision = math.max(_precisionOf(step), _precisionOf(base));
  final factor = math.pow(10, precision).toDouble();
  final scaled = snapped * factor;
  // A value too large to scale is tidied through its decimal form instead.
  final rounded = scaled.isFinite
      ? _jsRound(scaled) / factor
      : double.parse(snapped.toStringAsFixed(precision));
  return _clamp(rounded, min, max);
}

double _clamp(double value, double min, double max) =>
    math.min(math.max(value, min), max);

/// JavaScript's `Math.round`, which takes a half up towards positive infinity
/// where [double.roundToDouble] takes it away from zero: -2.5 is -2, not -3.
double _jsRound(double x) {
  final rounded = x.roundToDouble();
  return x - rounded == 0.5 ? rounded + 1 : rounded;
}

/// A number as JavaScript's `String()` writes it, which is how PanelUI shows
/// one: no `.0` on a whole number, and no sign on zero.
String _jsNumberString(double value) {
  if (value == 0) return '0';
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

/// The leading number in some text, as JavaScript's `parseFloat` reads it:
/// "12abc" is 12, " -.5" is -0.5, and "abc" or a lone "-" is nothing.
double? _parseLeadingNumber(String text) {
  final match = _leadingNumber.firstMatch(text.trimLeft());
  return match == null ? null : double.parse(match[0]!);
}

final RegExp _leadingNumber = RegExp(
  r'^[+-]?(?:Infinity|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)',
);
