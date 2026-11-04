import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// The artwork a [PanelThemeSelector] draws for each option.
enum PanelThemePreviewVariant {
  /// An app screen with a panel on it: an avatar and lines of text.
  window,

  /// A framed card with an accent on it, cut on the diagonal for system.
  card,
}

/// How big a [PanelThemeSelector]'s miniatures are.
enum PanelThemeSelectorSize {
  /// 72pt wide, for a settings row that has other things on it.
  sm(72),

  /// 88pt wide, the default, for a screen that is about choosing the theme.
  md(88);

  const PanelThemeSelectorSize(this.width);

  /// The miniature's width. Its height keeps the artwork's 88:70 ratio.
  final double width;
}

/// Light, dark, or whatever the device is set to.
///
/// Miniatures of a screen with the chosen one ringed. "System" is the option
/// people hesitate over, and a screen split down the middle explains it
/// faster than a sentence.
///
/// It chooses a [ThemeMode], so it plugs straight into
/// `MaterialApp.themeMode`, and the light and dark themes stay those of the
/// app's family. Flutter keeps no app-wide theme for it to read and set, so
/// unlike PanelUI's it is always given its [value], and applying the choice
/// is [onChanged]'s job.
///
/// ```dart
/// PanelThemeSelector(
///   label: 'Appearance',
///   value: mode,
///   onChanged: (m) => setState(() => mode = m),
/// )
/// ```
class PanelThemeSelector extends StatelessWidget {
  /// Creates a selector.
  const PanelThemeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.variant = PanelThemePreviewVariant.window,
    this.size = PanelThemeSelectorSize.md,
    this.options = const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
    this.labels = const {
      ThemeMode.system: 'System',
      ThemeMode.light: 'Light',
      ThemeMode.dark: 'Dark',
    },
    this.previewBuilder,
  });

  /// The chosen mode.
  final ThemeMode value;

  /// Called with the mode picked. Null disables the selector.
  final ValueChanged<ThemeMode>? onChanged;

  /// The heading above the options, and the group's name for screen readers.
  final String? label;

  /// The artwork.
  final PanelThemePreviewVariant variant;

  /// The miniature size.
  final PanelThemeSelectorSize size;

  /// The options, in the order they are drawn: leave out system for a choice
  /// between light and dark only.
  final List<ThemeMode> options;

  /// What each option is called.
  final Map<ThemeMode, String> labels;

  /// Draws an option's miniature in place of the built-in [variant]: a
  /// screenshot of the app itself, say. It keeps the ring and the rounded
  /// corners around it.
  final Widget Function(BuildContext context, ThemeMode mode)? previewBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final onChanged = this.onChanged;
    return Opacity(
      opacity: onChanged == null ? 0.4 : 1,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.radioGroup,
        label: label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            if (label != null)
              // The group carries the words already.
              ExcludeSemantics(
                child: Text(
                  label!,
                  style: theme.typography.style(
                    PanelTextSize.sm,
                    weight: FontWeight.w500,
                    color: theme.colors.foreground,
                  ),
                ),
              ),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final mode in options)
                  _ThemeOption(
                    name: labels[mode] ?? mode.name,
                    selected: mode == value,
                    preview:
                        previewBuilder?.call(context, mode) ??
                        _ThemePreview(
                          mode: mode,
                          variant: variant,
                          width: size.width,
                        ),
                    onPressed: onChanged == null ? null : () => onChanged(mode),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One option: the miniature in its ring, and its name under it. The whole
/// of it is the target, because at this size the name is the easier of the
/// two to hit.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.name,
    required this.selected,
    required this.preview,
    required this.onPressed,
  });

  final String name;
  final bool selected;
  final Widget preview;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    return PanelPressable(
      onPressed: onPressed,
      // PanelUI draws an option on a plain Pressable: no press shrink.
      pressScale: 1,
      isButton: false,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: name,
      focusRingRadius: BorderRadius.circular(theme.radii.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          // The ring is on a frame around the artwork rather than on the
          // artwork, so choosing an option never takes a strip out of its
          // drawing.
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(theme.radii.xl),
              border: Border.all(
                width: 2,
                color: selected ? c.primary : const Color(0x00000000),
              ),
            ),
            // The artwork's corners sit concentrically inside the frame's: its
            // radius less the padding between them.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(theme.radii.lg),
              child: preview,
            ),
          ),
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.typography.style(
              PanelTextSize.sm,
              color: selected ? c.foreground : c.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// One built-in miniature, [width] wide and as tall as the artwork's 88:70
/// ratio makes it.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.mode,
    required this.variant,
    required this.width,
  });

  final ThemeMode mode;
  final PanelThemePreviewVariant variant;
  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, (width / _board.width * _board.height).roundToDouble()),
      painter: _ThemePreviewPainter(mode: mode, variant: variant),
    );
  }
}

/// The colours of a miniature screen: a ground, a surface on it, a mark, and
/// lines of text.
class _Palette {
  const _Palette(this.ground, this.surface, this.mark, this.line);

  /// Behind everything: the desktop, the page around the app.
  final Color ground;

  /// The app's own surface.
  final Color surface;

  /// A shape on it: an avatar, an image, a control.
  final Color mark;

  /// Lines of text.
  final Color line;
}

// Fixed rather than themed: a preview built from the active theme would show
// the theme the reader already has, three times over. The light option has
// to look light while the app around it is dark.
const _light = _Palette(
  Color(0xFFE5E5E5),
  Color(0xFFFFFFFF),
  Color(0xFFD4D4D4),
  Color(0xFFE5E5E5),
);
const _dark = _Palette(
  Color(0xFF171717),
  Color(0xFF262626),
  Color(0xFF525252),
  Color(0xFF404040),
);

/// The one colour that is not a grey: warm rather than blue, so it reads as a
/// colour in the app on both grounds without looking like the ring that marks
/// the chosen option.
const _accent = Color(0xFFC1704F);

/// Every miniature is drawn on this board and scaled to its box.
const _board = Size(88, 70);

/// The card variant's frame and the card inside it.
final _cardFrame = RRect.fromRectAndRadius(
  Offset.zero & _board,
  const Radius.circular(16),
);
final _cardSurface = RRect.fromRectAndRadius(
  const Rect.fromLTWH(8, 8, 72, 54),
  const Radius.circular(10),
);

/// PanelUI's `ThemePreview`, drawn on the canvas rather than from SVG.
class _ThemePreviewPainter extends CustomPainter {
  const _ThemePreviewPainter({required this.mode, required this.variant});

  final ThemeMode mode;
  final PanelThemePreviewVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    // Scaled to fit and centred, as an SVG draws its viewBox.
    final scale = math.min(
      size.width / _board.width,
      size.height / _board.height,
    );
    canvas
      ..translate(
        (size.width - _board.width * scale) / 2,
        (size.height - _board.height * scale) / 2,
      )
      ..scale(scale);
    if (variant == PanelThemePreviewVariant.card) {
      _card(canvas);
    } else if (mode == ThemeMode.system) {
      // Half a screen each, and the halves are not mirror images: each panel
      // starts at the same inset and runs to the half's right edge, so the
      // seam falls where the two app surfaces meet rather than down the
      // middle of one of them.
      _windowHalf(canvas, _light, 0);
      _windowHalf(canvas, _dark, _board.width / 2);
    } else {
      _window(canvas, mode == ThemeMode.dark ? _dark : _light);
    }
  }

  static Paint _fill(Color color) => Paint()..color = color;

  /// A panel from [left] to [right], below the top edge, with its top-left
  /// corner rounded.
  static RRect _pane(double left, double right) => RRect.fromRectAndCorners(
    Rect.fromLTRB(left, 8, right, _board.height),
    topLeft: const Radius.circular(4),
  );

  /// Lines of text at [x], seven apart, of the given [widths].
  static void _lines(
    Canvas canvas,
    Color color,
    double x,
    List<double> widths,
  ) {
    for (var i = 0; i < widths.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 42 + i * 7.0, widths[i], 4),
          const Radius.circular(2),
        ),
        _fill(color),
      );
    }
  }

  static void _window(Canvas canvas, _Palette p) {
    canvas
      ..drawRect(Offset.zero & _board, _fill(p.ground))
      ..drawRRect(_pane(10, _board.width), _fill(p.surface))
      ..drawCircle(const Offset(28, 26), 8, _fill(p.mark));
    _lines(canvas, p.line, 20, const [58, 58, 29]);
  }

  static void _windowHalf(Canvas canvas, _Palette p, double x) {
    canvas
      ..drawRect(Rect.fromLTWH(x, 0, 44, _board.height), _fill(p.ground))
      ..drawRRect(_pane(x + 10, x + 44), _fill(p.surface))
      ..drawCircle(Offset(x + 28, 26), 8, _fill(p.mark));
    _lines(canvas, p.line, x + 20, const [24, 24, 24]);
  }

  void _card(Canvas canvas) {
    final p = mode == ThemeMode.dark ? _dark : _light;
    canvas
      ..drawRRect(_cardFrame, _fill(p.ground))
      ..drawRRect(_cardSurface, _fill(p.surface));
    for (final (y, width) in const [(18.0, 34.0), (26.0, 23.0)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(17, y, width, 4),
          const Radius.circular(2),
        ),
        _fill(p.line),
      );
    }
    if (mode == ThemeMode.system) {
      // The dark half, cut from the top-right corner to the bottom-left one:
      // the same triangle clipped once to the frame and once to the card
      // inside it, so both keep their rounded corners.
      final diagonal = Path()
        ..moveTo(_board.width, 0)
        ..lineTo(_board.width, _board.height)
        ..lineTo(0, _board.height)
        ..close();
      canvas
        ..save()
        ..clipRRect(_cardFrame)
        ..drawPath(diagonal, _fill(_dark.ground))
        ..restore()
        ..save()
        ..clipRRect(_cardSurface)
        ..drawPath(diagonal, _fill(_dark.surface))
        ..restore();
    }
    canvas.drawCircle(const Offset(64, 47), 8, _fill(_accent));
  }

  @override
  bool shouldRepaint(_ThemePreviewPainter oldDelegate) =>
      oldDelegate.mode != mode || oldDelegate.variant != variant;
}
