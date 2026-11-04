import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

/// A group holding its own selection, reporting each change.
class _Group extends StatefulWidget {
  const _Group({
    this.initial = const [],
    this.mode = PanelToggleSelectionMode.multiple,
    this.enabled = true,
    this.size,
    this.onChanged,
  });

  final List<String> initial;
  final PanelToggleSelectionMode mode;
  final bool enabled;
  final PanelToggleButtonSize? size;
  final ValueChanged<List<String>>? onChanged;

  @override
  State<_Group> createState() => _GroupState();
}

class _GroupState extends State<_Group> {
  late List<String> _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return PanelToggleButtonGroup<String>(
      value: _value,
      selectionMode: widget.mode,
      size: widget.size,
      onChanged: widget.enabled
          ? (value) {
              widget.onChanged?.call(value);
              setState(() => _value = value);
            }
          : null,
      children: const [
        PanelToggleButton(id: 'day', child: Text('Day')),
        PanelToggleButton(id: 'week', child: Text('Week')),
        PanelToggleButton(id: 'month', child: Text('Month')),
      ],
    );
  }
}

void main() {
  testWidgets('pressing flips the value', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      wrap(
        PanelToggleButton(onChanged: changes.add, child: const Text('Follow')),
      ),
    );
    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();
    expect(changes, [true]);

    await tester.pumpWidget(
      wrap(
        PanelToggleButton(
          value: true,
          onChanged: changes.add,
          child: const Text('Follow'),
        ),
      ),
    );
    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
  });

  testWidgets('is announced as a checked button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        PanelToggleButton(
          value: true,
          onChanged: (_) {},
          child: const Text('Follow'),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Follow')),
      isSemantics(
        label: 'Follow',
        isButton: true,
        isChecked: true,
        hasCheckedState: true,
        hasTapAction: true,
        isFocusable: true,
        isEnabled: true,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('with no onChanged, or enabled: false, it ignores presses', (
    tester,
  ) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      wrap(const PanelToggleButton(child: Text('Follow'))),
    );
    await tester.tap(find.text('Follow'));
    await tester.pumpWidget(
      wrap(
        PanelToggleButton(
          enabled: false,
          onChanged: changes.add,
          child: const Text('Follow'),
        ),
      ),
    );
    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(PanelToggleButton),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, 0.64);
  });

  testWidgets('Enter and Space press it from the keyboard', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      wrap(
        PanelToggleButton(onChanged: changes.add, child: const Text('Follow')),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(changes, [true, true]);
  });

  testWidgets('selected and unselected text take their colours', (
    tester,
  ) async {
    const c = PanelColors.panelLight;
    await tester.pumpWidget(
      wrap(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PanelToggleButton(
              value: true,
              onChanged: (_) {},
              child: const Text('On'),
            ),
            PanelToggleButton(onChanged: (_) {}, child: const Text('Off')),
          ],
        ),
      ),
    );
    Color? colorOf(String text) =>
        DefaultTextStyle.of(tester.element(find.text(text))).style.color;
    expect(colorOf('On'), c.accentForeground);
    expect(colorOf('Off'), c.mutedForeground);
  });

  testWidgets('sizes match the button heights; iconOnly is square', (
    tester,
  ) async {
    const heights = {
      PanelToggleButtonSize.xs: 28.0,
      PanelToggleButtonSize.sm: 36.0,
      PanelToggleButtonSize.md: 44.0,
      PanelToggleButtonSize.lg: 48.0,
      PanelToggleButtonSize.xl: 56.0,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      await tester.pumpWidget(
        wrap(
          PanelToggleButton(
            size: size,
            iconOnly: true,
            semanticLabel: 'Bold',
            onChanged: (_) {},
            child: const PanelIcon(PanelIcons.bold),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(PanelToggleButton)),
        Size.square(height),
        reason: size.name,
      );
    }
  });

  testWidgets('a lone xs toggle takes presses just outside it', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      wrap(
        PanelToggleButton(
          size: PanelToggleButtonSize.xs,
          onChanged: changes.add,
          child: const Text('Mute'),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(PanelToggleButton));
    await tester.tapAt(rect.topCenter - const Offset(0, 6));
    await tester.pumpAndSettle();
    expect(changes, [true]);
  });

  testWidgets('multiple: each button turns its own id on and off', (
    tester,
  ) async {
    final changes = <List<String>>[];
    await tester.pumpWidget(
      wrap(_Group(initial: const ['week'], onChanged: changes.add)),
    );
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(changes, [
      ['week', 'day'],
      ['day'],
      ['day', 'month'],
    ]);
  });

  testWidgets('single: picking one clears the last; again clears it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final changes = <List<String>>[];
    await tester.pumpWidget(
      wrap(
        _Group(
          initial: const ['day'],
          mode: PanelToggleSelectionMode.single,
          onChanged: changes.add,
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Day')),
      isSemantics(
        label: 'Day',
        isButton: true,
        isChecked: true,
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
        isFocusable: true,
        isEnabled: true,
        hasEnabledState: true,
      ),
    );
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(changes, [
      ['week'],
      <String>[],
    ]);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('a group with no onChanged disables every button', (
    tester,
  ) async {
    final changes = <List<String>>[];
    await tester.pumpWidget(
      wrap(_Group(enabled: false, onChanged: changes.add)),
    );
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
  });

  testWidgets('the group fills in variant and size', (tester) async {
    await tester.pumpWidget(wrap(const _Group(size: PanelToggleButtonSize.sm)));
    expect(
      tester.getSize(find.widgetWithText(PanelToggleButton, 'Day')).height,
      36,
    );
    // Buttons sit 6pt apart.
    final day = tester.getRect(find.widgetWithText(PanelToggleButton, 'Day'));
    final week = tester.getRect(find.widgetWithText(PanelToggleButton, 'Week'));
    expect(week.left - day.right, 6);
  });

  testWidgets('an id of the wrong type is caught', (tester) async {
    await tester.pumpWidget(
      wrap(
        PanelToggleButtonGroup<String>(
          value: const [],
          onChanged: (_) {},
          children: const [
            // Bounded, so the error widget that replaces it cannot overflow.
            SizedBox(
              width: 80,
              height: 40,
              child: PanelToggleButton(id: 1, child: Text('One')),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('selection lands at once and is announced as selected', (
    tester,
  ) async {
    const c = PanelColors.panelLight;
    final handle = tester.ensureSemantics();
    var on = false;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) => PanelToggleButton(
            value: on,
            onChanged: (value) => setState(() => on = value),
            child: const Text('Follow'),
          ),
        ),
      ),
    );
    BoxDecoration face() =>
        tester
                .widget<Container>(
                  find
                      .ancestor(
                        of: find.text('Follow'),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;
    expect(face().color, c.secondary);
    await tester.tap(find.text('Follow'));
    await tester.pump();
    // PanelUI animates none of it, so one frame is enough.
    expect(face().color, c.accent);
    expect(
      (face().border! as Border).top.color,
      c.primary.withValues(alpha: 0.24),
    );
    expect(
      tester.getSemantics(find.text('Follow')),
      isSemantics(isChecked: true, isSelected: true, hasSelectedState: true),
    );
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('a pointer lights a resting toggle as the web button does', (
    tester,
  ) async {
    const c = PanelColors.panelLight;
    await tester.pumpWidget(
      wrap(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PanelToggleButton(onChanged: (_) {}, child: const Text('Soft')),
            PanelToggleButton(
              variant: PanelToggleButtonVariant.ghost,
              onChanged: (_) {},
              child: const Text('Ghost'),
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
    Color? text(String label) =>
        DefaultTextStyle.of(tester.element(find.text(label))).style.color;
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

    await mouse.moveTo(tester.getCenter(find.text('Soft')));
    await tester.pump();
    expect(fill('Soft'), c.secondary.withValues(alpha: c.secondary.a * 0.8));
    expect(text('Soft'), c.mutedForeground);

    await mouse.moveTo(tester.getCenter(find.text('Ghost')));
    await tester.pump();
    expect(fill('Ghost'), c.accent);
    expect(text('Ghost'), c.accentForeground);
  });

  testWidgets('labels take the line height of their step', (tester) async {
    const heights = {
      PanelToggleButtonSize.xs: 16 / 12,
      PanelToggleButtonSize.sm: 20 / 14,
      PanelToggleButtonSize.md: 24 / 16,
      PanelToggleButtonSize.lg: 28 / 18,
      PanelToggleButtonSize.xl: 28 / 18,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      await tester.pumpWidget(
        wrap(
          PanelToggleButton(
            size: size,
            onChanged: (_) {},
            child: const Text('Bold'),
          ),
        ),
      );
      final style = DefaultTextStyle.of(
        tester.element(find.text('Bold')),
      ).style;
      expect(style.height, height, reason: size.name);
    }
  });

  testWidgets('every variant and size builds in every theme', (tester) async {
    for (final theme in allThemes) {
      for (final variant in PanelToggleButtonVariant.values) {
        await tester.pumpWidget(
          wrap(
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final size in PanelToggleButtonSize.values) ...[
                  PanelToggleButton(
                    variant: variant,
                    size: size,
                    value: true,
                    onChanged: (_) {},
                    leading: const PanelIcon(PanelIcons.bell),
                    child: Text(size.name),
                  ),
                  PanelToggleButton(
                    variant: variant,
                    size: size,
                    iconOnly: true,
                    semanticLabel: 'Bold',
                    onChanged: (_) {},
                    child: const PanelIcon(PanelIcons.bold),
                  ),
                ],
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
