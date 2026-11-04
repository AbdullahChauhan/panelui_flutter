import 'dart:math' as math;

import 'package:flutter/material.dart'
    show InputDecoration, Material, MaterialType, TextField;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../foundation/panel_hit_slop.dart';
import '../theme/panel_motion.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';
import 'label.dart';

/// Whether a field draws its own edge or sits as a tinted well.
enum PanelInputVariant {
  /// A bordered field on the background, for a field on the page.
  outline,

  /// A tinted fill, for a field inside a card or a sheet, where a second
  /// border beside the container's own would read as a seam.
  filled,
}

/// How big a [PanelInput] is: eight points a step, from 32 to 64.
///
/// `xs` is for a field inside something already compact, such as a table
/// cell or a toolbar; `xl` is for the one field a screen is about, such as a
/// search or an amount.
enum PanelInputSize {
  /// 32pt tall, 13px text.
  xs(32, 10, 13),

  /// 40pt tall, 14px text.
  sm(40, 12, 14),

  /// 48pt tall, 16px text. The default.
  md(48, 14, 16),

  /// 56pt tall, 16px text.
  lg(56, 16, 16),

  /// 64pt tall, 18px text.
  xl(64, 20, 18);

  const PanelInputSize(this.height, this.horizontalPadding, this.fontSize);

  /// Field height.
  final double height;

  /// Inset of the text, and of any leading or trailing content, from the
  /// field's edges.
  final double horizontalPadding;

  /// Text size. It comes without a paired line height, so the line box is the
  /// font's own and the text sits in the middle of a field of fixed height.
  final double fontSize;
}

/// A text field with a label above it and a description or an error below.
///
/// The border crosses to the focus colour over 150ms rather than snapping, so
/// the field reads as answering you rather than being redrawn.
///
/// ```dart
/// const PanelInput(label: 'Email', placeholder: 'you@example.com')
/// PanelInput(
///   label: 'Search',
///   leading: const PanelIcon(PanelIcons.search),
///   onChanged: search,
/// )
/// ```
///
/// [leading] and [trailing] sit inside the field, against its edges, and the
/// text is padded clear of them. Both stay pressable, so a clear button or a
/// show-password eye works as it is; the space around them is still the
/// field's, so a press that misses puts the caret in it. Content that is only
/// decoration should say so with [interactiveContent], which hands every press
/// to the field and hides the content from screen readers.
///
/// A focused field keeps itself clear of the software keyboard, as Flutter's
/// fields do, which is what PanelUI's `avoidKeyboard` adds to React Native.
///
/// Built on Material's [TextField] for selection, IME and autofill, so it
/// needs `MaterialLocalizations` above it, as any `MaterialApp` provides.
class PanelInput extends StatefulWidget {
  /// Creates a text field.
  const PanelInput({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.placeholder,
    this.description,
    this.errorMessage,
    this.isInvalid = false,
    this.isRequired = false,
    this.enabled = true,
    this.readOnly = false,
    this.variant = PanelInputVariant.outline,
    this.size = PanelInputSize.md,
    this.multiline = false,
    this.leading,
    this.trailing,
    this.interactiveContent = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
  }) : assert(!(multiline && obscureText), 'An obscured field holds one line.');

  /// Controls the text. One is created if null.
  final TextEditingController? controller;

  /// Controls focus. One is created if null.
  final FocusNode? focusNode;

  /// The label above the field, and the field's name for screen readers.
  final String? label;

  /// Hint text shown while the field is empty.
  final String? placeholder;

  /// A muted line under the field.
  final String? description;

  /// An error under the field, replacing [description]. Setting it also
  /// marks the field invalid.
  final String? errorMessage;

  /// Draws the field in its error colours without a message.
  final bool isInvalid;

  /// Marks the field required: an asterisk on the label, and the state
  /// announced with the field.
  final bool isRequired;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether the text can be selected but not changed.
  final bool readOnly;

  /// Outline or filled.
  final PanelInputVariant variant;

  /// The size.
  final PanelInputSize size;

  /// Lets the text run to several lines. The field starts 96pt tall and grows
  /// with its text, and the text and any leading or trailing content start at
  /// the top rather than floating in the middle of the box.
  final bool multiline;

  /// Content inside the field, before the text: usually an icon. It is drawn
  /// in the placeholder colour, quieter than the value, and the text is padded
  /// clear of it however wide it is.
  final Widget? leading;

  /// Content inside the field, after the text: an icon, a unit, a count or a
  /// button.
  final Widget? trailing;

  /// Whether [leading] and [trailing] take presses. Turn it off for content
  /// that is only decoration: every press then lands on the field, and the
  /// content is hidden from screen readers.
  final bool interactiveContent;

  /// Hides the text, for a password.
  final bool obscureText;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action button.
  final TextInputAction? textInputAction;

  /// Automatic capitalisation.
  final TextCapitalization textCapitalization;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Whether to autocorrect.
  final bool autocorrect;

  /// Whether to show suggestions.
  final bool enableSuggestions;

  /// The most characters allowed.
  final int? maxLength;

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Autofill hints.
  final Iterable<String>? autofillHints;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits.
  final ValueChanged<String>? onSubmitted;

  /// Called when editing completes.
  final VoidCallback? onEditingComplete;

  /// Called when the field is tapped.
  final VoidCallback? onTap;

  @override
  State<PanelInput> createState() => _PanelInputState();
}

class _PanelInputState extends State<PanelInput> {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void dispose() {
    _ownFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final size = widget.size;
    final multiline = widget.multiline;
    final pad = size.horizontalPadding;
    final style = theme.typography
        .sized(size.fontSize, color: c.foreground)
        .copyWith(height: multiline ? _multilineLeading : null);
    final field = _FieldSemantics(
      label: widget.label,
      isRequired: widget.isRequired,
      isInvalid: widget.isInvalid || widget.errorMessage != null,
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofocus: widget.autofocus,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          maxLength: widget.maxLength,
          maxLines: multiline ? null : 1,
          inputFormatters: widget.inputFormatters,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
          onTap: widget.onTap,
          style: style,
          cursorColor: c.foreground,
          buildCounter: _noCounter,
          decoration: _decoration(
            widget.placeholder,
            style: style.copyWith(color: c.mutedForeground),
            padding: EdgeInsetsDirectional.only(
              start: widget.leading == null ? pad : 0,
              end: widget.trailing == null ? pad : 0,
              top: multiline ? _multilinePadding : 0,
              bottom: multiline ? _multilinePadding : 0,
            ),
          ),
        ),
      ),
    );

    Widget content(Widget child, {required bool leading}) => _InputContent(
      leading: leading,
      padding: pad,
      multiline: multiline,
      interactive: widget.interactiveContent,
      child: child,
    );

    Widget row = _FieldRow(
      crossAxisAlignment: multiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (widget.leading != null) content(widget.leading!, leading: true),
        Expanded(
          child: PanelHitSlop(slop: _wholeRow, child: field),
        ),
        if (widget.trailing != null) content(widget.trailing!, leading: false),
      ],
    );
    if (multiline) {
      row = ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _multilineMinHeight - 2 * _border,
        ),
        child: row,
      );
    }

    return PanelFieldFrame(
      focusNode: _focusNode,
      label: widget.label,
      description: widget.description,
      errorMessage: widget.errorMessage,
      isInvalid: widget.isInvalid,
      isRequired: widget.isRequired,
      enabled: widget.enabled,
      variant: widget.variant,
      height: multiline ? null : size.height,
      focusRing: true,
      child: row,
    );
  }
}

/// A text field for several lines, sized in rows.
///
/// Its height comes from [rows] rather than from a fixed number, so it
/// composes with [size]: three rows of 14px text and three rows of 16px text
/// are different heights, and both are three rows. With [autoGrow] it starts
/// at [rows], grows a line at a time as it is written in, and scrolls once it
/// reaches [maxRows], which is what a composer wants.
///
/// ```dart
/// const PanelTextarea(label: 'Notes', placeholder: 'Anything we should know?')
/// const PanelTextarea(autoGrow: true, rows: 2, maxRows: 8, showCount: true, maxLength: 280)
/// ```
///
/// As in PanelUI, a [readOnly] textarea is dimmed as a disabled one is.
class PanelTextarea extends StatefulWidget {
  /// Creates a multi-line field.
  const PanelTextarea({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.placeholder,
    this.description,
    this.errorMessage,
    this.isInvalid = false,
    this.isRequired = false,
    this.enabled = true,
    this.readOnly = false,
    this.variant = PanelInputVariant.outline,
    this.size = PanelInputSize.md,
    this.rows = 4,
    this.autoGrow = false,
    this.maxRows = 10,
    this.showCount = false,
    this.maxLength,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.onChanged,
  }) : assert(rows > 0);

  /// Controls the text. One is created if null.
  final TextEditingController? controller;

  /// Controls focus. One is created if null.
  final FocusNode? focusNode;

  /// The label above the field, and the field's name for screen readers.
  final String? label;

  /// Hint text shown while the field is empty.
  final String? placeholder;

  /// A muted line under the field.
  final String? description;

  /// An error under the field, replacing [description]. Setting it also
  /// marks the field invalid.
  final String? errorMessage;

  /// Draws the field in its error colours without a message.
  final bool isInvalid;

  /// Marks the field required: an asterisk on the label, and the state
  /// announced with the field.
  final bool isRequired;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether the text can be selected but not changed.
  final bool readOnly;

  /// Outline or filled.
  final PanelInputVariant variant;

  /// The text size, line height and padding. The text size and horizontal
  /// padding are [PanelInput]'s at the same size, so a one-line field and a
  /// multi-line one stacked in a form share an edge.
  final PanelInputSize size;

  /// How many lines tall the field is before it scrolls or grows.
  final int rows;

  /// Grow with the text, a line at a time, up to [maxRows]; after that the
  /// field holds its height and scrolls.
  final bool autoGrow;

  /// The tallest [autoGrow] goes. Ignored without it, and never below [rows].
  final int maxRows;

  /// Shows how much of [maxLength] is used, under the field. It needs
  /// [maxLength]: a count with no limit to count towards says nothing.
  final bool showCount;

  /// The most characters allowed.
  final int? maxLength;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Automatic capitalisation.
  final TextCapitalization textCapitalization;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  @override
  State<PanelTextarea> createState() => _PanelTextareaState();
}

class _PanelTextareaState extends State<PanelTextarea> {
  FocusNode? _ownFocusNode;
  TextEditingController? _ownController;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());
  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void dispose() {
    _ownFocusNode?.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final size = widget.size;
    final metrics = _textareaMetrics[size]!;
    final style = theme.typography
        .sized(size.fontSize, color: c.foreground)
        .copyWith(height: metrics.lineHeight / size.fontSize);
    final maxLength = widget.maxLength;
    final disabled = !widget.enabled || widget.readOnly;

    return PanelFieldFrame(
      focusNode: _focusNode,
      label: widget.label,
      description: widget.description,
      errorMessage: widget.errorMessage,
      isInvalid: widget.isInvalid,
      isRequired: widget.isRequired,
      enabled: !disabled,
      variant: widget.variant,
      count: widget.showCount && maxLength != null
          ? _CharacterCount(controller: _controller, maxLength: maxLength)
          : null,
      focusRing: true,
      child: _FieldSemantics(
        label: widget.label,
        isRequired: widget.isRequired,
        isInvalid: widget.isInvalid || widget.errorMessage != null,
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            maxLength: maxLength,
            textCapitalization: widget.textCapitalization,
            keyboardType: TextInputType.multiline,
            minLines: widget.rows,
            maxLines: widget.autoGrow
                ? math.max(widget.rows, widget.maxRows)
                : widget.rows,
            onChanged: widget.onChanged,
            style: style,
            cursorColor: c.foreground,
            buildCounter: _noCounter,
            decoration: _decoration(
              widget.placeholder,
              style: style.copyWith(color: c.mutedForeground),
              // PanelUI gives the box exactly the rows and both paddings, so
              // the border comes out of the padding rather than adding to it.
              padding: EdgeInsets.symmetric(
                horizontal: size.horizontalPadding,
                vertical: metrics.padding - _border,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The chrome shared by PanelUI's text fields: a label above, the bordered
/// box, and a description, error and count below. The border animates to the
/// `ring` token (or `destructive` when invalid) while [focusNode] has focus.
///
/// Exposed for building custom fields that should match [PanelInput].
class PanelFieldFrame extends StatefulWidget {
  /// Creates a field frame.
  const PanelFieldFrame({
    super.key,
    required this.focusNode,
    required this.child,
    this.label,
    this.description,
    this.errorMessage,
    this.isInvalid = false,
    this.isRequired = false,
    this.enabled = true,
    this.variant = PanelInputVariant.outline,
    this.height,
    this.count,
    this.focusRing = false,
  });

  /// Whose focus drives the border.
  final FocusNode focusNode;

  /// The editable content inside the box, inset by its 1pt border.
  final Widget child;

  /// The label above the box.
  final String? label;

  /// A muted line under the box.
  final String? description;

  /// An error under the box, replacing [description].
  final String? errorMessage;

  /// Draws the error colours without a message.
  final bool isInvalid;

  /// Marks the label as required.
  final bool isRequired;

  /// Dims the box to 64% opacity, and the label with it, when false.
  final bool enabled;

  /// Outline or filled.
  final PanelInputVariant variant;

  /// A fixed height for the box. Null sizes it to its content.
  final double? height;

  /// A trailing element of the footer, such as a character count.
  final Widget? count;

  /// Draws the web package's focus ring around the box while it has focus
  /// and the app is driven by a pointer or a keyboard: 3pt of `ring` at 30%,
  /// or of `destructive` at 20% when invalid. A touch screen keeps PanelUI's
  /// border alone.
  final bool focusRing;

  @override
  State<PanelFieldFrame> createState() => _PanelFieldFrameState();
}

class _PanelFieldFrameState extends State<PanelFieldFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _focus = AnimationController(
    vsync: this,
    duration: PanelDurations.focus,
    value: widget.focusNode.hasFocus ? 1 : 0,
  );

  /// Whether a pointer or a keyboard drives the app, rather than touch.
  bool _traditional =
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocus);
    FocusManager.instance.addHighlightModeListener(_handleHighlightMode);
  }

  @override
  void didUpdateWidget(PanelFieldFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocus);
      widget.focusNode.addListener(_handleFocus);
      _handleFocus();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    FocusManager.instance.removeHighlightModeListener(_handleHighlightMode);
    _focus.dispose();
    super.dispose();
  }

  void _handleHighlightMode(FocusHighlightMode mode) {
    final traditional = mode == FocusHighlightMode.traditional;
    if (traditional != _traditional) {
      setState(() => _traditional = traditional);
    }
  }

  void _handleFocus() {
    final target = widget.focusNode.hasFocus ? 1.0 : 0.0;
    if (panelReduceMotion(context)) {
      _focus.value = target;
    } else {
      _focus.animateTo(target, curve: panelEase);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final invalid = widget.isInvalid || widget.errorMessage != null;
    // An invalid field is tinted even at rest: the error is a fact about the
    // value, not about whether the field happens to be focused.
    final idle = invalid ? c.destructive : c.input;
    final active = invalid ? c.destructive : c.ring;
    final fill = widget.variant == PanelInputVariant.outline
        ? c.background
        : c.muted;
    final radius = BorderRadius.circular(theme.radii.lg);
    final ring = !widget.focusRing || !_traditional
        ? null
        : invalid
        ? c.destructive.withValues(alpha: c.destructive.a * 0.2)
        : c.ring.withValues(alpha: c.ring.a * 0.3);

    final box = AnimatedBuilder(
      animation: _focus,
      builder: (context, child) {
        final t = _focus.value;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: Color.lerp(idle, active, t)!),
          ),
          // The ring fades in with the border, outside the box.
          foregroundDecoration: ring == null || t == 0
              ? null
              : BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: ring.withValues(alpha: ring.a * t),
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
          child: child,
        );
      },
      child: widget.child,
    );

    final message = widget.errorMessage ?? widget.description;
    final count = widget.count;
    return Column(
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
              isDisabled: !widget.enabled,
            ),
          ),
        Opacity(opacity: widget.enabled ? 1 : 0.64, child: box),
        if (message != null || count != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: message == null
                    ? const SizedBox.shrink()
                    : Text(
                        message,
                        style: theme.typography.style(
                          PanelTextSize.sm,
                          color: widget.errorMessage != null
                              ? c.destructive
                              : c.mutedForeground,
                        ),
                      ),
              ),
              ?count,
            ],
          ),
      ],
    );
  }
}

/// The width of a field's border.
const double _border = 1;

/// The size an icon in a field's leading or trailing content is drawn at when
/// it is not given one: PanelUI's glyphs are drawn at 16 unless sized.
const double _contentIconSize = 16;

/// A multiline [PanelInput] starts this tall (`min-h-24`) and grows.
const double _multilineMinHeight = 96;

/// The space above and below the text of a multiline [PanelInput] (`py-3`).
const double _multilinePadding = 12;

/// The line height of a multiline [PanelInput] (`leading-normal`). A field of
/// one line leaves the font its own leading, which keeps the text centred;
/// across several lines the leading is what separates them.
const double _multilineLeading = 1.5;

/// A textarea's type and spacing at each size, from PanelUI's `METRICS`: the
/// height of its box is derived from these, which is how [PanelTextarea.rows]
/// and [PanelTextarea.size] compose.
const Map<PanelInputSize, ({double lineHeight, double padding})>
_textareaMetrics = {
  PanelInputSize.xs: (lineHeight: 18, padding: 8),
  PanelInputSize.sm: (lineHeight: 20, padding: 10),
  PanelInputSize.md: (lineHeight: 22, padding: 12),
  PanelInputSize.lg: (lineHeight: 24, padding: 14),
  PanelInputSize.xl: (lineHeight: 26, padding: 16),
};

/// Lets a field take a press anywhere in its row: the [_FieldRow] it sits in
/// keeps the slop inside the field's box, and offers the content first.
const EdgeInsets _wholeRow = EdgeInsets.all(double.infinity);

/// The decoration every field's text sits in: no chrome of its own, the
/// placeholder in [style], and [padding] inside the text's own box, so a
/// press on the padding is a press on the text.
InputDecoration _decoration(
  String? placeholder, {
  required TextStyle style,
  required EdgeInsetsGeometry padding,
}) {
  return InputDecoration.collapsed(
    hintText: placeholder,
    hintStyle: style,
    // A placeholder goes the moment there is text, as React Native's does.
    hintFadeDuration: Duration.zero,
  ).copyWith(contentPadding: padding);
}

Widget? _noCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) => null;

/// Names a field for screen readers by its [label], with its required and
/// invalid states, as PanelUI's fields do through `accessibilityLabel`,
/// `aria-required` and `aria-invalid`. It merges into the text field's own
/// node.
class _FieldSemantics extends StatelessWidget {
  const _FieldSemantics({
    required this.label,
    required this.isRequired,
    required this.isInvalid,
    required this.child,
  });

  final String? label;
  final bool isRequired;
  final bool isInvalid;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      isRequired: isRequired ? true : null,
      validationResult: isInvalid
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: child,
    );
  }
}

/// [PanelInput.leading] or [PanelInput.trailing], at the field's edge.
///
/// PanelUI places the content against the field's outer edge, outside its
/// border, and pads the text clear of the content's whole width inside the
/// border. Inside the frame, which insets everything by the border, that is
/// the field's padding less the border on the outer side and plus it on the
/// inner, and the same for the top of a multiline field.
class _InputContent extends StatelessWidget {
  const _InputContent({
    required this.leading,
    required this.padding,
    required this.multiline,
    required this.interactive,
    required this.child,
  });

  final bool leading;
  final double padding;
  final bool multiline;
  final bool interactive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    Widget content = Padding(
      padding: EdgeInsetsDirectional.only(
        start: leading ? padding - _border : padding + _border,
        end: leading ? padding + _border : padding - _border,
        top: multiline ? _multilinePadding - _border : 0,
      ),
      // Quieter than the value: an icon at the text's weight reads as part
      // of what was typed, and the placeholder colour already says "not the
      // value".
      child: IconTheme(
        data: IconThemeData(color: c.mutedForeground, size: _contentIconSize),
        child: DefaultTextStyle(
          style: theme.typography.style(
            PanelTextSize.base,
            color: c.foreground,
          ),
          child: child,
        ),
      ),
    );
    if (!interactive) {
      content = IgnorePointer(child: ExcludeSemantics(child: content));
    }
    return content;
  }
}

/// A field's row: the content beside the text, and the text field as its one
/// flexible child.
///
/// PanelUI lays the content over the field rather than beside it, so the
/// field takes every press the content does not: the padding around an icon,
/// the space above and below the text. Here the two sit side by side, the
/// field's hit area is widened to the whole row, and the row asks the content
/// first.
class _FieldRow extends Flex {
  const _FieldRow({required super.crossAxisAlignment, required super.children})
    : super(direction: Axis.horizontal);

  @override
  RenderFlex createRenderObject(BuildContext context) => _RenderFieldRow(
    crossAxisAlignment: crossAxisAlignment,
    textDirection: getEffectiveTextDirection(context),
  );
}

class _RenderFieldRow extends RenderFlex {
  _RenderFieldRow({super.crossAxisAlignment, super.textDirection});

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? field;
    for (var child = lastChild; child != null; child = childBefore(child)) {
      final flex = (child.parentData! as FlexParentData).flex ?? 0;
      if (flex > 0) {
        field = child;
      } else if (_hitTestChild(child, result, position)) {
        return true;
      }
    }
    return field != null && _hitTestChild(field, result, position);
  }

  bool _hitTestChild(
    RenderBox child,
    BoxHitTestResult result,
    Offset position,
  ) {
    final parentData = child.parentData! as FlexParentData;
    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }
}

/// A textarea's count against its limit, tinted once the limit is reached:
/// past it, the count is the error.
class _CharacterCount extends StatelessWidget {
  const _CharacterCount({required this.controller, required this.maxLength});

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        // Characters as the limit counts them, so the two always agree.
        final length = value.text.characters.length;
        return Text(
          '$length/$maxLength',
          style: theme.typography
              .style(
                PanelTextSize.sm,
                color: length >= maxLength ? c.destructive : c.mutedForeground,
              )
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        );
      },
    );
  }
}
