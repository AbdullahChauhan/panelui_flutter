import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';

import '../foundation/panel_pressable.dart';
import '../theme/panel_theme.dart';
import '../theme/panel_typography.dart';

/// The artwork a [PanelThemeSelector] draws for each option.
enum PanelThemePreviewVariant {
  /// A miniature window with an avatar and lines of text.
  window,

  /// A miniature card with an accent dot.
  card,
}

/// How big a [PanelThemeSelector]'s miniatures are.
enum PanelThemeSelectorSize {
  /// 72pt wide.
  sm(72),

  /// 88pt wide, the default.
  md(88);

  const PanelThemeSelectorSize(this.width);

  /// The miniature's width. Its height keeps the artwork's 88:70 ratio.
  final double width;
}

/// Light, dark, or whatever the device is set to.
///
/// Three miniatures of a screen with the chosen one ringed. "System" is the
/// option people hesitate over, and a screen split down the middle explains
/// it faster than a sentence. It chooses a [ThemeMode], so it plugs straight
/// into `MaterialApp.themeMode`; the light and dark themes stay those of the
/// app's family.
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
    this.labels = const {
      ThemeMode.system: 'System',
      ThemeMode.light: 'Light',
      ThemeMode.dark: 'Dark',
    },
  });

  /// The chosen mode.
  final ThemeMode value;

  /// Called with the mode picked. Null disables the selector.
  final ValueChanged<ThemeMode>? onChanged;

  /// A legend above the options.
  final String? label;

  /// The artwork.
  final PanelThemePreviewVariant variant;

  /// The miniature size.
  final PanelThemeSelectorSize size;

  /// What each option is called.
  final Map<ThemeMode, String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final previewHeight = (size.width / 88 * 70).roundToDouble();

    Widget option(ThemeMode mode) {
      final selected = mode == value;
      final name = labels[mode] ?? mode.name;
      return PanelPressable(
        onPressed: enabled ? () => onChanged!(mode) : null,
        isButton: false,
        checked: selected,
        inMutuallyExclusiveGroup: true,
        semanticLabel: name,
        focusRingRadius: BorderRadius.circular(theme.radii.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(theme.radii.xl),
                border: Border.all(
                  width: 2,
                  color: selected ? c.primary : const Color(0x00000000),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(theme.radii.lg),
                child: CustomPaint(
                  size: Size(size.width, previewHeight),
                  painter: _ThemePreviewPainter(mode: mode, variant: variant),
                ),
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

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          if (label != null)
            Text(
              label!,
              style: theme.typography.style(
                PanelTextSize.sm,
                weight: FontWeight.w500,
                color: c.foreground,
              ),
            ),
          Semantics(
            container: true,
            explicitChildNodes: true,
            label: label,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                option(ThemeMode.system),
                option(ThemeMode.light),
                option(ThemeMode.dark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Palette {
  const _Palette(this.ground, this.surface, this.mark, this.line);

  final Color ground;
  final Color surface;
  final Color mark;
  final Color line;
}

// A picture of a light screen and a dark one, so these are fixed rather than
// themed: the artwork shows the modes, not the current theme.
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
const _accent = Color(0xFFC1704F);

class _ThemePreviewPainter extends CustomPainter {
  const _ThemePreviewPainter({required this.mode, required this.variant});

  final ThemeMode mode;
  final PanelThemePreviewVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    // The artwork is drawn on an 88 × 70 board and scaled to fit.
    canvas.scale(size.width / 88, size.height / 70);
    if (variant == PanelThemePreviewVariant.card) {
      _card(canvas);
    } else if (mode == ThemeMode.system) {
      _windowHalf(canvas, _light, 0);
      _windowHalf(canvas, _dark, 44);
    } else {
      _window(canvas, mode == ThemeMode.dark ? _dark : _light);
    }
  }

  static Paint _fill(Color color) => Paint()..color = color;

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

  static RRect _pane(double left, double right) => RRect.fromRectAndCorners(
    Rect.fromLTRB(left, 8, right, 70),
    topLeft: const Radius.circular(4),
  );

  static void _window(Canvas canvas, _Palette p) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, 88, 70), _fill(p.ground));
    canvas.drawRRect(_pane(10, 88), _fill(p.surface));
    canvas.drawCircle(const Offset(28, 26), 8, _fill(p.mark));
    _lines(canvas, p.line, 20, const [58, 58, 29]);
  }

  static void _windowHalf(Canvas canvas, _Palette p, double x) {
    canvas.drawRect(Rect.fromLTWH(x, 0, 44, 70), _fill(p.ground));
    canvas.drawRRect(_pane(x + 10, x + 44), _fill(p.surface));
    canvas.drawCircle(Offset(x + 28, 26), 8, _fill(p.mark));
    _lines(canvas, p.line, x + 20, const [24, 24, 24]);
  }

  void _card(Canvas canvas) {
    final p = mode == ThemeMode.dark ? _dark : _light;
    final frame = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 88, 70),
      const Radius.circular(16),
    );
    final surface = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 8, 72, 54),
      const Radius.circular(10),
    );
    canvas
      ..drawRRect(frame, _fill(p.ground))
      ..drawRRect(surface, _fill(p.surface));
    _cardLine(canvas, p.line, 18, 34);
    _cardLine(canvas, p.line, 26, 23);
    if (mode == ThemeMode.system) {
      // The dark half, cut corner to corner and clipped twice: once to the
      // frame and once to the card inside it.
      final diagonal = Path()
        ..moveTo(88, 0)
        ..lineTo(88, 70)
        ..lineTo(0, 70)
        ..close();
      canvas
        ..save()
        ..clipRRect(frame)
        ..drawPath(diagonal, _fill(_dark.ground))
        ..restore()
        ..save()
        ..clipRRect(surface)
        ..drawPath(diagonal, _fill(_dark.surface))
        ..restore();
    }
    canvas.drawCircle(const Offset(64, 47), 8, _fill(_accent));
  }

  static void _cardLine(Canvas canvas, Color color, double y, double width) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(17, y, width, 4),
        const Radius.circular(2),
      ),
      _fill(color),
    );
  }

  @override
  bool shouldRepaint(_ThemePreviewPainter oldDelegate) =>
      oldDelegate.mode != mode || oldDelegate.variant != variant;
}
