import 'package:flutter/material.dart'
    show InputDecoration, Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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

/// How big a [PanelInput] is.
enum PanelInputSize {
  /// 32pt tall, 13px text.
  xs(32, 10, 13, 14),

  /// 40pt tall, 14px text.
  sm(40, 12, 14, 16),

  /// 48pt tall, 16px text. The default.
  md(48, 14, 16, 18),

  /// 56pt tall, 16px text.
  lg(56, 16, 16, 18),

  /// 64pt tall, 18px text.
  xl(64, 20, 18, 20);

  const PanelInputSize(
    this.height,
    this.horizontalPadding,
    this.fontSize,
    this.iconSize,
  );

  /// Field height.
  final double height;

  /// Inset of the text and of any leading or trailing content.
  final double horizontalPadding;

  /// Text size.
  final double fontSize;

  /// Size given to icons in the leading and trailing slots.
  final double iconSize;
}

/// A single-line text field with a label above it and a description or an
/// error below.
///
/// The border crosses to the focused colour over 150ms rather than snapping,
/// so the field reads as answering you rather than being redrawn.
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
    this.leading,
    this.trailing,
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
  });

  /// Controls the text. One is created if null.
  final TextEditingController? controller;

  /// Controls focus. One is created if null.
  final FocusNode? focusNode;

  /// The label above the field.
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

  /// Marks the label as required.
  final bool isRequired;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether the text can be selected but not changed.
  final bool readOnly;

  /// Outline or filled.
  final PanelInputVariant variant;

  /// The size.
  final PanelInputSize size;

  /// Content at the start of the field, such as an icon.
  final Widget? leading;

  /// Content at the end of the field, such as a clear button.
  final Widget? trailing;

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
    final style = theme.typography.sized(size.fontSize, color: c.foreground);
    final pad = size.horizontalPadding;

    final field = Material(
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
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
        onTap: widget.onTap,
        style: style,
        cursorColor: c.foreground,
        textAlignVertical: TextAlignVertical.center,
        buildCounter: _noCounter,
        decoration: InputDecoration.collapsed(
          hintText: widget.placeholder,
          hintStyle: style.copyWith(color: c.mutedForeground),
        ),
      ),
    );

    Widget slot(Widget child) => Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: IconTheme(
        data: IconThemeData(color: c.mutedForeground, size: size.iconSize),
        child: child,
      ),
    );

    final row = Row(
      children: [
        if (widget.leading != null) slot(widget.leading!),
        Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: widget.leading == null ? pad : 0,
              end: widget.trailing == null ? pad : 0,
            ),
            child: field,
          ),
        ),
        if (widget.trailing != null) slot(widget.trailing!),
      ],
    );

    return PanelFieldFrame(
      focusNode: _focusNode,
      label: widget.label,
      description: widget.description,
      errorMessage: widget.errorMessage,
      isInvalid: widget.isInvalid,
      isRequired: widget.isRequired,
      enabled: widget.enabled,
      variant: widget.variant,
      height: size.height,
      child: row,
    );
  }
}

/// A text field for several lines.
///
/// Its height comes from [rows], so three rows of 14px text and three rows of
/// 16px text are both three rows. With [autoGrow] it follows its content up
/// to [maxRows] and then scrolls, which is what a composer wants.
///
/// ```dart
/// const PanelTextarea(label: 'Notes', placeholder: 'Anything we should know?')
/// const PanelTextarea(autoGrow: true, rows: 2, maxRows: 8, showCount: true, maxLength: 280)
/// ```
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
    this.rows = 3,
    this.autoGrow = false,
    this.maxRows = 8,
    this.showCount = false,
    this.maxLength,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.onChanged,
  }) : assert(rows > 0 && maxRows >= rows);

  /// Controls the text. One is created if null.
  final TextEditingController? controller;

  /// Controls focus. One is created if null.
  final FocusNode? focusNode;

  /// The label above the field.
  final String? label;

  /// Hint text shown while the field is empty.
  final String? placeholder;

  /// A muted line under the field.
  final String? description;

  /// An error under the field, replacing [description].
  final String? errorMessage;

  /// Draws the field in its error colours without a message.
  final bool isInvalid;

  /// Marks the label as required.
  final bool isRequired;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether the text can be selected but not changed.
  final bool readOnly;

  /// Outline or filled.
  final PanelInputVariant variant;

  /// The text size and horizontal padding.
  final PanelInputSize size;

  /// Visible rows.
  final int rows;

  /// Grow with the content up to [maxRows].
  final bool autoGrow;

  /// The most rows [autoGrow] reaches before scrolling.
  final int maxRows;

  /// Shows a character count under the field.
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
    final style = theme.typography
        .sized(size.fontSize, color: c.foreground)
        .copyWith(height: 1.5);

    final field = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        maxLength: widget.maxLength,
        textCapitalization: widget.textCapitalization,
        keyboardType: TextInputType.multiline,
        minLines: widget.rows,
        maxLines: widget.autoGrow ? widget.maxRows : widget.rows,
        onChanged: widget.onChanged,
        style: style,
        cursorColor: c.foreground,
        buildCounter: _noCounter,
        decoration: InputDecoration.collapsed(
          hintText: widget.placeholder,
          hintStyle: style.copyWith(color: c.mutedForeground),
        ),
      ),
    );

    Widget? count;
    if (widget.showCount) {
      count = ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          final length = value.text.characters.length;
          final max = widget.maxLength;
          final atLimit = max != null && length >= max;
          return Text(
            max == null ? '$length' : '$length/$max',
            style: theme.typography
                .style(
                  PanelTextSize.sm,
                  color: atLimit ? c.destructive : c.mutedForeground,
                )
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          );
        },
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
      count: count,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.horizontalPadding,
          vertical: 12,
        ),
        child: field,
      ),
    );
  }
}

Widget? _noCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) => null;

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
  });

  /// Whose focus drives the border.
  final FocusNode focusNode;

  /// The editable content inside the box.
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

  /// Dims the field to 64% opacity when false.
  final bool enabled;

  /// Outline or filled.
  final PanelInputVariant variant;

  /// A fixed height for the box. Null sizes it to its content.
  final double? height;

  /// A trailing element of the footer, such as a character count.
  final Widget? count;

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

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocus);
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
    _focus.dispose();
    super.dispose();
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
    final idle = invalid ? c.destructive : c.input;
    final active = invalid ? c.destructive : c.ring;
    final fill = widget.variant == PanelInputVariant.outline
        ? c.background
        : c.muted;

    final box = AnimatedBuilder(
      animation: _focus,
      builder: (context, child) => Container(
        height: widget.height,
        constraints: widget.height == null
            ? const BoxConstraints(minHeight: 96)
            : null,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(theme.radii.lg),
          border: Border.all(color: Color.lerp(idle, active, _focus.value)!),
        ),
        child: child,
      ),
      child: widget.child,
    );

    final message = widget.errorMessage ?? widget.description;
    final messageStyle = theme.typography.style(
      PanelTextSize.sm,
      color: widget.errorMessage != null ? c.destructive : c.mutedForeground,
    );

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
        if (message != null || widget.count != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: message == null
                    ? const SizedBox.shrink()
                    : Semantics(
                        liveRegion: widget.errorMessage != null,
                        child: Text(message, style: messageStyle),
                      ),
              ),
              ?widget.count,
            ],
          ),
      ],
    );
  }
}
