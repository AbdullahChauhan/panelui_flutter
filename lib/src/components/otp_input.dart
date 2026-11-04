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
/// ```dart
/// PanelOtpInput(onCompleted: verify)
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
    this.semanticLabel = 'Verification code',
  }) : assert(length > 0);

  /// How many characters the code has.
  final int length;

  /// Holds the code. One is created if null.
  final TextEditingController? controller;

  /// Controls focus. One is created if null.
  final FocusNode? focusNode;

  /// Called on every change, with the code so far.
  final ValueChanged<String>? onChanged;

  /// Called once, the moment the last cell is filled.
  final ValueChanged<String>? onCompleted;

  /// Accept digits only and ask for the number pad.
  final bool numeric;

  /// Draw each filled character as a dot, like a passcode.
  final bool mask;

  /// A single character shown, dimmed, in every empty cell.
  final String? placeholder;

  /// Draw a dash between groups of this many cells: 3 gives `xxx – xxx`.
  final int groupEvery;

  /// The cell size.
  final PanelOtpInputSize size;

  /// Whether the field accepts input.
  final bool enabled;

  /// Tint the cells in the error colour.
  final bool isInvalid;

  /// An error under the field. Setting it also marks the field invalid.
  final String? errorMessage;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// The field's name for screen readers.
  final String semanticLabel;

  @override
  State<PanelOtpInput> createState() => _PanelOtpInputState();
}

class _PanelOtpInputState extends State<PanelOtpInput> {
  TextEditingController? _ownController;
  FocusNode? _ownFocusNode;
  bool _completed = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleValue);
    _focusNode.addListener(_handleFocus);
    _completed = _controller.text.length >= widget.length;
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
  }

  @override
  void dispose() {
    _controller.removeListener(_handleValue);
    _focusNode.removeListener(_handleFocus);
    _ownController?.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocus() => setState(() {});

  void _handleValue() {
    final value = _controller.text;
    final full = value.length >= widget.length;
    // Fire on the transition to full, not on every event that leaves it full.
    if (full && !_completed) {
      _completed = true;
      widget.onCompleted?.call(value);
    } else if (!full) {
      _completed = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final size = widget.size;
    final value = _controller.text;
    final invalid = widget.isInvalid || widget.errorMessage != null;
    final focused = _focusNode.hasFocus;
    final activeIndex = value.length.clamp(0, widget.length - 1);

    final cells = <Widget>[];
    for (var i = 0; i < widget.length; i++) {
      if (i > 0) cells.add(const SizedBox(width: 8));
      cells.add(
        _OtpCell(
          char: i < value.length ? value[i] : '',
          lit: focused && i == activeIndex,
          mask: widget.mask,
          placeholder: widget.placeholder,
          invalid: invalid,
          size: size,
        ),
      );
      final groupEnds =
          widget.groupEvery > 0 &&
          (i + 1) % widget.groupEvery == 0 &&
          i < widget.length - 1;
      if (groupEnds) {
        cells
          ..add(const SizedBox(width: 8))
          ..add(
            Container(
              width: size.separatorWidth,
              height: 2,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
      }
    }

    final field = Material(
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
            : TextInputType.visiblePassword,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          if (widget.numeric) FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(widget.length),
        ],
        onChanged: widget.onChanged,
        style: const TextStyle(color: Color(0x00000000), fontSize: 1),
        decoration: const InputDecoration.collapsed(hintText: null),
      ),
    );

    final row = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      child: Stack(
        children: [
          ExcludeSemantics(
            child: Row(mainAxisSize: MainAxisSize.min, children: cells),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Semantics(
                label: widget.semanticLabel,
                child: Opacity(
                  opacity: 0,
                  alwaysIncludeSemantics: true,
                  child: field,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Opacity(opacity: widget.enabled ? 1 : 0.64, child: row),
        if (widget.errorMessage != null)
          Semantics(
            liveRegion: true,
            child: Text(
              widget.errorMessage!,
              style: theme.typography.style(
                PanelTextSize.sm,
                color: c.destructive,
              ),
            ),
          ),
      ],
    );
  }
}

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
              duration: const Duration(milliseconds: 140),
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.scale(scale: t, child: child),
              ),
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

class _Caret extends StatefulWidget {
  const _Caret({required this.height, required this.steady});

  final double height;
  final bool steady;

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  // On for 560ms, then fading out over 560ms: a cursor at rest.
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1120),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.steady) _blink.repeat();
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = PanelTheme.of(context).colors.foreground;
    final bar = Container(
      width: 2,
      height: widget.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
    if (widget.steady) return bar;
    return AnimatedBuilder(
      animation: _blink,
      builder: (context, child) {
        final t = _blink.value;
        final opacity = t < 0.5 ? 1.0 : 1 - panelEase.transform((t - 0.5) * 2);
        return Opacity(opacity: opacity, child: child);
      },
      child: bar,
    );
  }
}
