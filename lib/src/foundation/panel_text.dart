import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// Tailwind's `tracking-tight`, in ems.
const double _trackingTight = -0.025;

/// Tailwind's `leading-tight`.
const double _leadingTight = 1.25;

/// Text on PanelUI's type scale, in the theme's foreground colour: PanelUI's
/// `Text` primitive and its `Typography` presets.
///
/// ```dart
/// PanelText('Billing', size: PanelTextSize.lg, weight: FontWeight.w600)
/// PanelText('Updated 2 minutes ago', size: PanelTextSize.sm, muted: true)
/// PanelText('Terms', style: TextStyle(decoration: TextDecoration.underline))
/// ```
///
/// The named constructors are PanelUI's typography roles: [PanelText.h1]
/// through [PanelText.h6] (announced as headings of that level),
/// [PanelText.lead], [PanelText.large] and [PanelText.small]. PanelUI's
/// `body`, `body-sm` and `body-xs` are the default constructor at
/// [PanelTextSize.base], [PanelTextSize.sm] and [PanelTextSize.xs].
///
/// PanelUI's marks (`underline`, `italic`, `strike`) and its `weight`
/// override are a [style], which is how Flutter carries them; its `transform`
/// is the string itself, upper- or lower-cased before it is passed in.
class PanelText extends StatelessWidget {
  /// Creates a run of text.
  const PanelText(
    this.data, {
    super.key,
    this.size = PanelTextSize.base,
    this.weight = FontWeight.w400,
    this.muted = false,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : _tracking = 0,
       _lineHeight = null,
       _headingLevel = 0;

  /// A page title: 36px, bold, tracked tight.
  const PanelText.h1(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : size = PanelTextSize.xxxxl,
       weight = FontWeight.w700,
       muted = false,
       _tracking = _trackingTight,
       _lineHeight = null,
       _headingLevel = 1;

  /// A section title: 30px, semibold, tracked tight.
  const PanelText.h2(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : size = PanelTextSize.xxxl,
       weight = FontWeight.w600,
       muted = false,
       _tracking = _trackingTight,
       _lineHeight = null,
       _headingLevel = 2;

  /// 24px, semibold, tracked tight.
  const PanelText.h3(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : size = PanelTextSize.xxl,
       weight = FontWeight.w600,
       muted = false,
       _tracking = _trackingTight,
       _lineHeight = null,
       _headingLevel = 3;

  /// 20px, semibold.
  const PanelText.h4(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : size = PanelTextSize.xl,
       weight = FontWeight.w600,
       muted = false,
       _tracking = 0,
       _lineHeight = null,
       _headingLevel = 4;

  /// 18px, semibold.
  const PanelText.h5(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : size = PanelTextSize.lg,
       weight = FontWeight.w600,
       muted = false,
       _tracking = 0,
       _lineHeight = null,
       _headingLevel = 5;

  /// 16px, semibold.
  const PanelText.h6(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : size = PanelTextSize.base,
       weight = FontWeight.w600,
       muted = false,
       _tracking = 0,
       _lineHeight = null,
       _headingLevel = 6;

  /// An introductory paragraph: 20px and muted.
  const PanelText.lead(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : size = PanelTextSize.xl,
       weight = FontWeight.w400,
       muted = true,
       _tracking = 0,
       _lineHeight = null,
       _headingLevel = 0;

  /// Body one step up, for a number or a name that carries a row.
  const PanelText.large(
    this.data, {
    super.key,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : size = PanelTextSize.lg,
       weight = FontWeight.w600,
       muted = false,
       _tracking = 0,
       _lineHeight = null,
       _headingLevel = 0;

  /// Body one step down and tighter, for captions and meta.
  ///
  /// Tight, but not tighter than the glyphs: a line height equal to the font
  /// size leaves nothing below the baseline and descenders get clipped.
  const PanelText.small(
    this.data, {
    super.key,
    this.muted = false,
    this.color,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : size = PanelTextSize.sm,
       weight = FontWeight.w500,
       _tracking = 0,
       _lineHeight = _leadingTight,
       _headingLevel = 0;

  /// The text.
  final String data;

  /// The step on the type scale.
  final PanelTextSize size;

  /// The weight.
  final FontWeight weight;

  /// Draws in the `mutedForeground` token, for secondary text.
  final bool muted;

  /// Overrides the colour.
  final Color? color;

  /// Merged over the computed style.
  final TextStyle? style;

  /// Horizontal alignment.
  final TextAlign? textAlign;

  /// Maximum number of lines.
  final int? maxLines;

  /// How overflow is drawn.
  final TextOverflow? overflow;

  /// Whether to wrap at soft line breaks.
  final bool? softWrap;

  /// An alternative label for screen readers.
  final String? semanticsLabel;

  /// Letter spacing in ems.
  final double _tracking;

  /// A line-height multiplier overriding the size's paired one.
  final double? _lineHeight;

  /// The heading level screen readers announce (PanelUI's `aria-level`), or
  /// 0 for body text.
  final int _headingLevel;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    var base = theme.typography.style(
      size,
      weight: weight,
      color:
          color ??
          (muted ? theme.colors.mutedForeground : theme.colors.foreground),
    );
    if (_tracking != 0 || _lineHeight != null) {
      base = base.copyWith(
        letterSpacing: _tracking * size.fontSize,
        height: _lineHeight,
      );
    }
    final text = Text(
      data,
      style: style == null ? base : base.merge(style),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );
    if (_headingLevel == 0) return text;
    return Semantics(header: true, headingLevel: _headingLevel, child: text);
  }
}
