import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

void main() {
  testWidgets('calls onPressed when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(PanelButton(onPressed: () => taps++, child: const Text('Save'))),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('a null onPressed disables and dims the button', (tester) async {
    await tester.pumpWidget(
      wrap(const PanelButton(onPressed: null, child: Text('Save'))),
    );
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Save'), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.64);
    expect(
      tester.getSemantics(find.text('Save')),
      isSemantics(label: 'Save', isButton: true, isEnabled: false),
    );
  });

  testWidgets('loading shows a spinner and blocks presses', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        PanelButton(
          loading: true,
          leading: const Icon(Icons.add),
          onPressed: () => taps++,
          child: const Text('Saving'),
        ),
      ),
    );
    expect(find.byType(PanelSpinner), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    await tester.tap(find.text('Saving'));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('shrinks while pressed and springs back', (tester) async {
    await tester.pumpWidget(
      wrap(PanelButton(onPressed: () {}, child: const Text('Press'))),
    );
    final scale = find.descendant(
      of: find.byType(PanelButton),
      matching: find.byType(Transform),
    );
    expect(scale, findsNothing);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Press')),
    );
    // The first frame starts the ticker; the second advances it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<Transform>(scale).transform.entry(0, 0),
      closeTo(0.97, 0.001),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale, findsNothing);
  });

  testWidgets('activates from the keyboard', (tester) async {
    var taps = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      wrap(
        PanelButton(
          focusNode: focus,
          onPressed: () => taps++,
          child: const Text('Go'),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('a group fills in variant and size', (tester) async {
    PanelButtonGroupScope? scope;
    await tester.pumpWidget(
      wrap(
        PanelButtonGroup(
          variant: PanelButtonVariant.ghost,
          size: PanelButtonSize.sm,
          children: [
            Builder(
              builder: (context) {
                scope = PanelButtonGroup.maybeScopeOf(context);
                return PanelButton(onPressed: () {}, child: const Text('A'));
              },
            ),
            PanelButton(onPressed: () {}, child: const Text('B')),
          ],
        ),
      ),
    );
    expect(scope?.variant, PanelButtonVariant.ghost);
    expect(scope?.size, PanelButtonSize.sm);
    expect(scope?.attached, isTrue);
    // A small group button is 36pt tall.
    expect(tester.getSize(find.byType(PanelButtonGroup)).height, 36 + 2);
  });

  testWidgets('sizes follow the PanelUI scale', (tester) async {
    for (final (size, height) in [
      (PanelButtonSize.xs, 28.0),
      (PanelButtonSize.sm, 36.0),
      (PanelButtonSize.md, 44.0),
      (PanelButtonSize.lg, 48.0),
      (PanelButtonSize.xl, 56.0),
    ]) {
      await tester.pumpWidget(
        wrap(PanelButton(size: size, onPressed: () {}, child: const Text('x'))),
      );
      expect(
        tester.getSize(find.byType(PanelButton)).height,
        height,
        reason: '$size',
      );
    }
    await tester.pumpWidget(
      wrap(
        PanelButton(
          size: PanelButtonSize.icon,
          onPressed: () {},
          child: const PanelIcon(PanelIcons.plus),
        ),
      ),
    );
    expect(tester.getSize(find.byType(PanelButton)), const Size(44, 44));
  });

  testWidgets('builds every variant in every theme', (tester) async {
    for (final theme in allThemes) {
      await tester.pumpWidget(
        wrap(
          theme: theme,
          Wrap(
            children: [
              for (final variant in PanelButtonVariant.values)
                PanelButton(
                  variant: variant,
                  onPressed: () {},
                  child: Text(variant.name),
                ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a compact button takes a press just outside its edge', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        Padding(
          padding: const EdgeInsets.all(24),
          child: PanelButton(
            size: PanelButtonSize.xs,
            onPressed: () => taps++,
            child: const Text('Edit'),
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(PanelButton));
    // xs reaches 10pt past each edge (PanelUI's BUTTON_HIT_SLOP).
    await tester.tapAt(box.topCenter - const Offset(0, 8));
    await tester.pumpAndSettle();
    expect(taps, 1);
    await tester.tapAt(box.topCenter - const Offset(0, 14));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}
