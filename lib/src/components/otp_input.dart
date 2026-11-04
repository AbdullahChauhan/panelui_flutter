import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/material.dart'
    show InputDecoration, Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// How big a [PanelOtpInput]'s cells are.
enum PanelOtpInputSize {
  /// 36 × 40 cells.
  sm(36, 40, PanelTextSize.base, 20, 8),

  /// 44 × 48 cells, the default.
  md(44, 48, PanelTextSize.lg, 24, 10),

  /// 48 × 56 cells.
  lg(48, 56, PanelTextSize.xl, 28, 12);

  const PanelOtpInputSize(
    this.cellWidth,
    this.cellHeight,
    this.text,
    this.caretHeight,
    this.separatorWidth,
  );

  /// Cell width.
  final double cellWidth;

  /// Cell height.
  final double cellHeight;

  /// Size of the typed characters.
  final PanelTextSize text;

  /// Height of the blinking caret.
  final double caretHeight;

  /// Width of the dash between groups.
  final double separatorWidth;
}

/// A one-time-code field drawn as a row of separate cells.
///
/// A code is read and typed one character at a time, and a single text box
/// hides how many are left. So the value is spread across [length] cells and
/// a caret blinks in the one about to be filled. Underneath there is still one
/// real text field, because the keyboard, autofill (it offers the SMS code)
/// and paste all belong to a real field and fight a row of separate ones.
///
/// The cell awaiting input takes the focus colour over 150ms, and each
/// character zooms in as it lands, so a fast type or a one-tap autofill reads
/// as the code arriving rather than the row redrawing. With reduced motion
/// the characters appear at once and the caret holds steady.
///
/// ```dart
/// PanelOtpInput(onCompleted: verify, semanticLabel: 'Verification code')
/// const PanelOtpInput(length: 4, mask: true, groupEvery: 2)
/// ```
class PanelOtpInput extends StatefulWidget {
  /// Creates a code field.
  const PanelOtpInput({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.numeric = true,
    this.mask = false,
    this.placeholder,
    this.groupEvery = 0,
    this.size = PanelOtpInputSize.md,
    this.enabled = true,
    this.isInvalid = false,
    this.errorMessage,
    this.autofocus = false,
    this.semanticLabel,
  }) : assert(length > 0);

  /// How many characters the code has.
  final int length;

  /// Holds the code. One is created if null. A code set on it from outside
  /// is trimmed to what the field accepts, as typing would have been.
  final TextEditingController? controller;

  /// Controls focus. One is created if null.
  final FocusNode? focusNode;

  /// Called on every edit, with the code so far.
  final ValueChanged<String>? onChanged;

  /// Called once, the moment an edit fills the last cell: the moment to
  /// submit. A code set from outside does not call it.
  final ValueChanged<String>? onCompleted;

  /// Accept digits only and ask for the number pad. Otherwise any character
  /// goes, on the ordinary keyboard.
  final bool numeric;

  /// Draw each filled character as a dot, like a passcode.
  final bool mask;

  /// A single character shown, dimmed, in every cell still waiting for input.
  final String? placeholder;

  /// Draw a dash between groups of this many cells: 3 gives `xxx – xxx`.
  final int groupEvery;

  /// The cell size.
  final PanelOtpInputSize size;

  /// Whether the field accepts input.
  final bool enabled;

  /// Tint the cells in the error colour, and announce the code as invalid.
  final bool isInvalid;

  /// An error under the field. Setting it also marks the field invalid.
  final String? errorMessage;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// The field's name for screen readers, such as "Verification code".
  final String? semanticLabel;

  @override
  State<PanelOtpInput> createState() => _PanelOtpInputState();
}

class _PanelOtpInputState extends State<PanelOtpInput> {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  /// The code as the latest change left it, and as it was before that change.
  /// An edit completes the code when it fills the last cell of a code that
  /// was not already full, so the call comes once, on the way to full.
  String _code = '';
  String _codeBefore = '';

  @override
  void initState() {
    super.initState();
    _code = _codeBefore = _sanitize(_controller.text);
    _controller.addListener(_handleValue);
    _focusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(PanelOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_handleValue);
      _controller.addListener(_handleValue);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_handleFocus);
      _focusNode.addListener(_handleFocus);
    }
    if (oldWidget.controller != widget.controller ||
        oldWidget.length != widget.length ||
        oldWidget.numeric != widget.numeric) {
      _code = _codeBefore = _sanitize(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleValue);
    _focusNode.removeListener(_handleFocus);
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  /// [raw] cut down to what the field holds: digits only when [numeric], and
  /// no more than [length] characters.
  String _sanitize(String raw) {
    final filtered = widget.numeric ? raw.replaceAll(_nonDigit, '') : raw;
    return filtered.characters.take(widget.length).toString();
  }

  void _handleFocus() => setState(() {});

  void _handleValue() {
    final value = _controller.value;
    final code = _sanitize(value.text);
    // Set from outside with more than the field holds: trim it, and this
    // listener runs again with the trimmed code. A word still being composed
    // is left to the field, which trims it once it is committed.
    if (code != value.text && !value.composing.isValid) {
      _controller.value = TextEditingValue(
        text: code,
        selection: TextSelection.collapsed(offset: code.length),
      );
      return;
    }
    final changed = code != _code;
    _codeBefore = _code;
    _code = code;
    if (changed) setState(() {});
  }

  // The field notifies its controller before it reports the edit, so by now
  // [_codeBefore] is the code this edit started from.
  void _handleChanged(String code) {
    widget.onChanged?.call(code);
    final full = code.characters.length == widget.length;
    if (full && _codeBefore.characters.length < widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final invalid = widget.isInvalid || widget.errorMessage != null;
    final focused = _focusNode.hasFocus;
    final characters = _code.characters.toList();
    final activeIndex = characters.length.clamp(0, widget.length - 1);

    final cells = <Widget>[];
    for (var i = 0; i < widget.length; i++) {
      if (i > 0) cells.add(const SizedBox(width: _cellGap));
      cells.add(
        _OtpCell(
          char: i < characters.length ? characters[i] : '',
          lit: focused && i == activeIndex,
          mask: widget.mask,
          placeholder: widget.placeholder,
          invalid: invalid,
          size: widget.size,
        ),
      );
      final groupEnds =
          widget.groupEvery > 0 &&
          (i + 1) % widget.groupEvery == 0 &&
          i < widget.length - 1;
      if (groupEnds) {
        cells
          ..add(const SizedBox(width: _cellGap))
          ..add(_GroupSeparator(width: widget.size.separatorWidth));
      }
    }

    // The real field: one transparent input laid over the whole row. It owns
    // the code, the keyboard, autofill and paste; the cells are drawn from it.
    final field = Semantics(
      label: widget.semanticLabel,
      validationResult: invalid
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          showCursor: false,
          enableInteractiveSelection: false,
          keyboardType: widget.numeric
              ? TextInputType.number
              : TextInputType.text,
          // The field is invisible, so a correction or a suggestion would
          // change the code where nobody can see it happen.
          autocorrect: false,
          enableSuggestions: false,
          // The platform's one-time-code affordances: iOS offers the SMS code
          // above the keyboard, Android offers to fill it in.
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            if (widget.numeric) FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.length),
          ],
          onChanged: _handleChanged,
          style: const TextStyle(color: Color(0x00000000), fontSize: 1),
          decoration: const InputDecoration.collapsed(hintText: null),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Opacity(
          opacity: widget.enabled ? 1 : 0.64,
          // The row is one target: a press anywhere focuses the field, so the
          // platform never sees the seams between the cells.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled ? _focusNode.requestFocus : null,
            child: Stack(
              children: [
                ExcludeSemantics(
                  child: Row(mainAxisSize: MainAxisSize.min, children: cells),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0,
                      alwaysIncludeSemantics: true,
                      child: field,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.errorMessage != null)
          Text(
            widget.errorMessage!,
            style: theme.typography.style(
              PanelTextSize.sm,
              color: c.destructive,
            ),
          ),
      ],
    );
  }
}

/// The space between two cells, and between a cell and a group's dash
/// (`ms-2`).
const double _cellGap = 8;

/// How long the caret stays lit, and then how long it takes to fade: on for
/// as long as it is off reads as a cursor at rest.
const Duration _caretPhase = Duration(milliseconds: 560);

/// How long a character takes to zoom into its cell.
const Duration _landDuration = Duration(milliseconds: 140);

final RegExp _nonDigit = RegExp('[^0-9]');

/// One cell: its border, which crosses to the focus (or error) colour and
/// thickens to 2pt while the cell awaits input, and what it holds — a
/// character, the caret, the placeholder or nothing.
class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.char,
    required this.lit,
    required this.mask,
    required this.placeholder,
    required this.invalid,
    required this.size,
  });

  final String char;
  final bool lit;
  final bool mask;
  final String? placeholder;
  final bool invalid;
  final PanelOtpInputSize size;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final reduced = panelReduceMotion(context);
    final active = invalid ? c.destructive : c.ring;
    // An invalid code tints every cell: the error is about the value, not
    // about where the caret is.
    final idle = invalid ? active : c.input;
    final textStyle = theme.typography.style(size.text, color: c.foreground);

    Widget? content;
    if (char.isNotEmpty) {
      final glyph = Text(mask ? '•' : char, style: textStyle);
      content = reduced
          ? glyph
          : TweenAnimationBuilder<double>(
              // Keyed by the character, so a new one replays the entrance.
              key: ValueKey(char),
              tween: Tween(begin: 0, end: 1),
              duration: _landDuration,
              curve: panelEase,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: glyph,
            );
    } else if (lit) {
      content = _Caret(height: size.caretHeight, steady: reduced);
    } else if (placeholder != null) {
      content = Text(
        placeholder!,
        style: textStyle.copyWith(color: c.mutedForeground),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(end: lit ? 1 : 0),
      duration: reduced ? Duration.zero : PanelDurations.focus,
      curve: panelEase,
      builder: (context, t, child) => Container(
        width: size.cellWidth,
        height: size.cellHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: BorderRadius.circular(theme.radii.lg),
          border: Border.all(
            color: Color.lerp(idle, active, t)!,
            // A ring only on the active cell; the rest keep their hairline.
            width: 1 + t,
          ),
        ),
        child: child,
      ),
      child: content,
    );
  }
}

/// The dash between two groups of cells.
class _GroupSeparator extends StatelessWidget {
  const _GroupSeparator({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        color: PanelTheme.of(context).colors.border,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// The caret in the cell awaiting input: lit for [_caretPhase], then fading
/// out over the same time, over and over.
class _Caret extends StatefulWidget {
  const _Caret({required this.height, required this.steady});

  final double height;

  /// Holds the caret lit instead of blinking, for reduced motion.
  final bool steady;

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: _caretPhase * 2,
  );
  late final Animation<double> _opacity = _blink.drive(
    TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1), weight: 1),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: panelEase)),
        weight: 1,
      ),
    ]),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.steady) _blink.repeat();
  }

  @override
  void didUpdateWidget(_Caret oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.steady == oldWidget.steady) return;
    if (widget.steady) {
      _blink.value = 0;
    } else {
      _blink.repeat();
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Blinks for as long as the cell waits, so it repaints on its own.
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: 2,
          height: widget.height,
          decoration: BoxDecoration(
            color: PanelTheme.of(context).colors.foreground,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
