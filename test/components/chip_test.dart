import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

/// A focus ring's stroke alignment and the size of what it rings.
typedef StrokeAlignAndSize = ({double strokeAlign, Size size});

Finder _pill(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PanelChip)).first;

void main() {
  testWidgets('a static tag does not invite a tap', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const PanelChip(child: Text('Design'))));
    expect(find.byType(PanelPressable), findsNothing);
    expect(
      tester.getSemantics(find.text('Design')),
      isSemantics(label: 'Design', isButton: false),
    );
    expect(tester.getSize(_pill('Design')).height, 28);
    handle.dispose();
  });

  testWidgets('a pressable chip reports presses', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      wrap(PanelChip(onPressed: () => presses++, child: const Text('Design'))),
    );
    await tester.tap(find.text('Design'));
    await tester.pumpAndSettle();
    expect(presses, 1);
  });

  testWidgets('selected makes a toggle, announced as selected', (tester) async {
    final handle = tester.ensureSemantics();
    var on = false;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) => PanelChip(
            selected: on,
            onPressed: () => setState(() => on = !on),
            child: const Text('Design'),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Design')),
      isSemantics(
        label: 'Design',
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
        hasTapAction: true,
        isFocusable: true,
        isEnabled: true,
        hasEnabledState: true,
      ),
    );
    await tester.tap(find.text('Design'));
    await tester.pumpAndSettle();
    expect(on, isTrue);
    expect(
      tester.getSemantics(find.text('Design')),
      isSemantics(
        label: 'Design',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        isFocusable: true,
        isEnabled: true,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the ✕ removes without pressing the chip', (tester) async {
    var presses = 0;
    var closes = 0;
    await tester.pumpWidget(
      wrap(
        PanelChip(
          onPressed: () => presses++,
          onClose: () => closes++,
          child: const Text('Ada'),
        ),
      ),
    );
    await tester.tap(find.byType(PanelIcon));
    await tester.pumpAndSettle();
    expect(closes, 1);
    expect(presses, 0);

    await tester.tap(find.text('Ada'));
    await tester.pumpAndSettle();
    expect(presses, 1);
    expect(closes, 1);
  });

  testWidgets('the ✕ takes a press that only just misses it', (tester) async {
    var closes = 0;
    await tester.pumpWidget(
      wrap(PanelChip(onClose: () => closes++, child: const Text('Ada'))),
    );
    // The innermost pressable around the glyph is the ✕'s own.
    final mark = tester.getRect(
      find
          .ancestor(
            of: find.byType(PanelIcon),
            matching: find.byType(PanelPressable),
          )
          .first,
    );
    expect(mark.size, const Size(20, 20));
    // Inside the pill, 6pt before the ✕'s own box.
    await tester.tapAt(mark.centerLeft - const Offset(6, 0));
    await tester.pumpAndSettle();
    expect(closes, 1);
  });

  testWidgets('the ✕ is a labelled button that answers Backspace', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var closes = 0;
    await tester.pumpWidget(
      wrap(
        PanelChip(
          onClose: () => closes++,
          closeLabel: 'Remove Ada',
          child: const Text('Ada'),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Remove Ada')),
      isSemantics(
        label: 'Remove Ada',
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
        isEnabled: true,
        hasEnabledState: true,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(closes, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(closes, 2);
    handle.dispose();
  });

  testWidgets('a disabled chip ignores the chip and the ✕', (tester) async {
    var presses = 0;
    var closes = 0;
    await tester.pumpWidget(
      wrap(
        PanelChip(
          enabled: false,
          onPressed: () => presses++,
          onClose: () => closes++,
          child: const Text('Ada'),
        ),
      ),
    );
    await tester.tap(find.text('Ada'), warnIfMissed: false);
    await tester.tap(find.byType(PanelIcon), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(presses, 0);
    expect(closes, 0);
    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(PanelChip),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, 0.56);
  });

  testWidgets('sizes set the pill height', (tester) async {
    const heights = {
      PanelChipSize.xs: 20.0,
      PanelChipSize.sm: 24.0,
      PanelChipSize.md: 28.0,
      PanelChipSize.lg: 36.0,
      PanelChipSize.xl: 44.0,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      await tester.pumpWidget(
        wrap(PanelChip(size: size, child: const Text('Tag'))),
      );
      expect(tester.getSize(_pill('Tag')).height, height);
    }
  });

  testWidgets('the label and a leading icon take the variant colour', (
    tester,
  ) async {
    const theme = PanelThemeData.panelLight;
    await tester.pumpWidget(
      wrap(
        const PanelChip(
          variant: PanelChipVariant.success,
          leading: PanelIcon(PanelIcons.check),
          child: Text('Shipped'),
        ),
      ),
    );
    final style = DefaultTextStyle.of(tester.element(find.text('Shipped')));
    expect(style.style.color, theme.colors.successForeground);
    expect(style.style.fontWeight, FontWeight.w500);
    final icon = IconTheme.of(tester.element(find.byType(PanelIcon)));
    expect(icon.color, theme.colors.successForeground);

    // Selected wins over the variant.
    await tester.pumpWidget(
      wrap(
        PanelChip(
          variant: PanelChipVariant.success,
          selected: true,
          onPressed: () {},
          child: const Text('Shipped'),
        ),
      ),
    );
    expect(
      DefaultTextStyle.of(tester.element(find.text('Shipped'))).style.color,
      theme.colors.accentForeground,
    );
  });

  testWidgets('labels take the line height of their step', (tester) async {
    const heights = {
      // `text-[11px]` sets the size alone and keeps the font's own height.
      PanelChipSize.xs: null,
      PanelChipSize.sm: 16 / 12,
      PanelChipSize.md: 20 / 14,
      PanelChipSize.lg: 24 / 16,
      PanelChipSize.xl: 24 / 16,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      await tester.pumpWidget(
        wrap(PanelChip(size: size, child: const Text('Tag'))),
      );
      final style = DefaultTextStyle.of(tester.element(find.text('Tag'))).style;
      expect(style.height, height, reason: size.name);
    }
  });

  testWidgets('a pointer lays the muted tint over the fill, but not a '
      'selected one', (tester) async {
    const c = PanelColors.panelLight;
    await tester.pumpWidget(
      wrap(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PanelChip(onPressed: () {}, child: const Text('Design')),
            PanelChip(
              selected: true,
              onPressed: () {},
              child: const Text('Code'),
            ),
          ],
        ),
      ),
    );
    Color? fill(String label) =>
        (tester
                    .widget<Container>(
                      find
                          .ancestor(
                            of: find.text(label),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration)
            .color;
    expect(fill('Design'), c.secondary);
    // Hover shows where a mouse is the pointer, as on the web and desktop.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('Design')));
    await tester.pump();
    // The web package's `hover:bg-muted/60`.
    expect(
      fill('Design'),
      Color.alphaBlend(c.muted.withValues(alpha: c.muted.a * 0.6), c.secondary),
    );
    await mouse.moveTo(tester.getCenter(find.text('Code')));
    await tester.pump();
    expect(fill('Code'), c.accent);
  });

  testWidgets('keyboard focus rings the pill 2pt off it, and the ✕ against '
      'it', (tester) async {
    StrokeAlignAndSize ring() {
      final finder = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            ((widget.decoration as BoxDecoration).border as Border?)
                    ?.top
                    .color ==
                PanelColors.panelLight.ring,
      );
      expect(finder, findsOneWidget);
      final side =
          ((tester.widget<DecoratedBox>(finder).decoration as BoxDecoration)
                      .border!
                  as Border)
              .top;
      return (strokeAlign: side.strokeAlign, size: tester.getSize(finder));
    }

    await tester.pumpWidget(
      wrap(PanelChip(onPressed: () {}, child: const Text('Design'))),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final pill = ring();
    expect(pill.strokeAlign, 3);
    expect(pill.size.height, 28);

    // A tag that is only removable takes focus on its ✕ alone.
    await tester.pumpWidget(
      wrap(PanelChip(onClose: () {}, child: const Text('Ada'))),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final close = ring();
    expect(close.strokeAlign, BorderSide.strokeAlignOutside);
    expect(close.size, const Size(20, 20));
  });

  testWidgets('a named chip still offers its ✕ to screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        PanelChip(
          onPressed: () {},
          onClose: () {},
          semanticLabel: 'Ada Lovelace',
          closeLabel: 'Remove Ada',
          child: const Text('Ada'),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Ada Lovelace'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove Ada'), findsOneWidget);
    expect(find.bySemanticsLabel('Ada'), findsNothing);
    handle.dispose();
  });

  testWidgets('every variant and size builds in every theme', (tester) async {
    for (final theme in allThemes) {
      for (final variant in PanelChipVariant.values) {
        await tester.pumpWidget(
          wrap(
            Wrap(
              spacing: 8,
              children: [
                for (final size in PanelChipSize.values)
                  PanelChip(
                    variant: variant,
                    size: size,
                    leading: const PanelIcon(PanelIcons.check),
                    onClose: () {},
                    child: Text(size.name),
                  ),
                PanelChip(
                  variant: variant,
                  selected: true,
                  onPressed: () {},
                  child: const Text('Selected'),
                ),
              ],
            ),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
}
