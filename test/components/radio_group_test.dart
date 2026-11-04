import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

/// A plan picker holding its own value, reporting each change.
class _Plans extends StatefulWidget {
  const _Plans({
    this.initial,
    this.variant = PanelRadioVariant.plain,
    this.orientation = Axis.vertical,
    this.enabled = true,
    this.disabledItem,
    this.onChanged,
  });

  final String? initial;
  final PanelRadioVariant variant;
  final Axis orientation;
  final bool enabled;
  final String? disabledItem;
  final ValueChanged<String>? onChanged;

  @override
  State<_Plans> createState() => _PlansState();
}

class _PlansState extends State<_Plans> {
  late String? _plan = widget.initial;

  @override
  Widget build(BuildContext context) {
    return PanelRadioGroup<String>(
      value: _plan,
      variant: widget.variant,
      orientation: widget.orientation,
      onChanged: widget.enabled
          ? (value) {
              widget.onChanged?.call(value);
              setState(() => _plan = value);
            }
          : null,
      children: [
        for (final plan in const ['Free', 'Pro', 'Team'])
          PanelRadioItem<String>(
            value: plan,
            label: plan,
            description: '$plan plan',
            enabled: plan != widget.disabledItem,
          ),
      ],
    );
  }
}

void main() {
  testWidgets('pressing an option reports its value', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(
      wrap(_Plans(initial: 'Free', onChanged: changes.add)),
    );

    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();
    expect(changes, ['Pro']);

    // Pressing the chosen option again does not report it twice.
    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();
    expect(changes, ['Pro']);
  });

  testWidgets('the whole row is the target, not only the disc', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(wrap(_Plans(onChanged: changes.add)));
    final row = tester.getRect(
      find
          .ancestor(
            of: find.text('Team'),
            matching: find.byType(PanelPressable),
          )
          .first,
    );
    // The row keeps a 48pt target however small the disc is.
    expect(row.height, greaterThanOrEqualTo(48));
    await tester.tapAt(row.centerLeft + const Offset(4, 0));
    await tester.pumpAndSettle();
    expect(changes, ['Team']);
  });

  testWidgets('a group with no onChanged ignores presses', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(
      wrap(_Plans(initial: 'Free', enabled: false, onChanged: changes.add)),
    );
    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Pro')),
      isSemantics(
        isEnabled: false,
        hasEnabledState: true,
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
  });

  testWidgets('a disabled option ignores presses and the rest still work', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      wrap(_Plans(disabledItem: 'Pro', onChanged: changes.add)),
    );
    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();
    expect(changes, ['Team']);
  });

  testWidgets('options are announced as radios, the chosen one checked', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const _Plans(initial: 'Pro')));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Pro')),
      isSemantics(
        label: 'Pro',
        isChecked: true,
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Free')),
      isSemantics(
        label: 'Free',
        isChecked: false,
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    // The group itself is a radio group, holding one checked radio.
    final pro = tester.getSemantics(find.bySemanticsLabel('Pro'));
    SemanticsNode? group = pro.parent;
    while (group != null &&
        group.getSemanticsData().role != SemanticsRole.radioGroup) {
      group = group.parent;
    }
    expect(group, isNotNull);
    handle.dispose();
  });

  testWidgets('the label is not read twice', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const _Plans(initial: 'Pro')));
    expect(find.bySemanticsLabel('Pro\nPro'), findsNothing);
    expect(find.bySemanticsLabel('Pro'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('arrow keys move the choice; Tab lands on the chosen option', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      wrap(_Plans(initial: 'Pro', onChanged: changes.add)),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final focused = FocusManager.instance.primaryFocus;
    expect(focused?.debugLabel, 'PanelRadioItem');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(changes, ['Team']);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(changes, ['Team', 'Pro']);
  });

  testWidgets('Space and Enter choose the focused option', (tester) async {
    final changes = <String>[];
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      wrap(
        PanelRadioGroup<int>(
          value: 1,
          onChanged: (v) => changes.add('$v'),
          children: [
            const PanelRadioItem(value: 1, label: 'One'),
            PanelRadioItem(value: 2, label: 'Two', focusNode: node),
          ],
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(changes, ['2']);
  });

  testWidgets('the dot springs in on selection and lands at full size', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const _Plans(initial: 'Free')));
    await tester.tap(find.text('Team'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reduced motion puts the dot in place without animating', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: wrap(const _Plans(initial: 'Free')),
      ),
    );
    await tester.tap(find.text('Team'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('card options carry their description and fill the width', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 360,
          child: _Plans(
            initial: 'Pro',
            variant: PanelRadioVariant.card,
            onChanged: changes.add,
          ),
        ),
      ),
    );
    expect(find.text('Team plan'), findsOneWidget);
    final card = find
        .ancestor(of: find.text('Team'), matching: find.byType(PanelPressable))
        .first;
    expect(tester.getSize(card).width, 360);
    // Anywhere on the card chooses it.
    await tester.tapAt(tester.getRect(card).bottomRight - const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(changes, ['Team']);
  });

  testWidgets('horizontal cards share the row', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 400,
          child: _Plans(
            variant: PanelRadioVariant.card,
            orientation: Axis.horizontal,
          ),
        ),
      ),
    );
    final free = tester.getRect(
      find
          .ancestor(
            of: find.text('Free'),
            matching: find.byType(PanelPressable),
          )
          .first,
    );
    final team = tester.getRect(
      find
          .ancestor(
            of: find.text('Team'),
            matching: find.byType(PanelPressable),
          )
          .first,
    );
    expect(free.top, team.top);
    expect(free.width, closeTo(team.width, 0.01));
    expect(free.width, closeTo((400 - 40) / 3, 0.01));
  });

  testWidgets('horizontal rows wrap', (tester) async {
    await tester.pumpWidget(wrap(const _Plans(orientation: Axis.horizontal)));
    final free = tester.getTopLeft(find.text('Free'));
    final pro = tester.getTopLeft(find.text('Pro'));
    expect(free.dy, pro.dy);
    expect(pro.dx, greaterThan(free.dx));
    expect(find.byType(Wrap), findsOneWidget);
  });

  testWidgets('hideIndicator drops the disc', (tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 300,
          child: PanelRadioGroup<String>(
            value: 'a',
            variant: PanelRadioVariant.card,
            onChanged: (_) {},
            children: const [
              PanelRadioItem(value: 'a', label: 'A', hideIndicator: true),
            ],
          ),
        ),
      ),
    );
    final circles = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
    );
    expect(circles, findsNothing);
  });

  testWidgets('an option outside a group says where it belongs', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const PanelRadioItem<String>(value: 'a', label: 'A')),
    );
    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect('$error', contains('PanelRadioGroup<String>'));
  });

  testWidgets('a plain row draws no description; a card does, as a hint', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const _Plans(initial: 'Pro')));
    expect(find.text('Pro plan'), findsNothing);

    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 360,
          child: _Plans(initial: 'Pro', variant: PanelRadioVariant.card),
        ),
      ),
    );
    expect(find.text('Pro plan'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Pro')),
      isSemantics(label: 'Pro', hint: 'Pro plan', isChecked: true),
    );
    handle.dispose();
  });

  testWidgets(
    'a chosen card takes the accent fill and a primary edge at once',
    (tester) async {
      const c = PanelColors.panelLight;
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 360,
            child: _Plans(initial: 'Free', variant: PanelRadioVariant.card),
          ),
        ),
      );
      BoxDecoration card(String label) =>
          tester
                  .widget<Container>(
                    find
                        .ancestor(
                          of: find.text(label),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(card('Pro').color, c.card);
      await tester.tap(find.text('Pro'));
      await tester.pump();
      // The accent tint itself, laid over whatever the card sits on.
      expect(card('Pro').color, c.accent);
      expect((card('Pro').border! as Border).top.color, c.primary);
      expect(card('Free').color, c.card);
    },
  );

  testWidgets('a pointer lights a row disc as the web package does', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const _Plans(initial: 'Free')));
    Color ring(String label) {
      final disc = tester.widget<Container>(
        find
            .descendant(
              of: find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(PanelPressable),
                  )
                  .first,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration! as BoxDecoration).shape ==
                        BoxShape.circle,
              ),
            )
            .first,
      );
      return ((disc.decoration! as BoxDecoration).border! as Border).top.color;
    }

    expect(ring('Pro'), PanelColors.panelLight.input);
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
    await mouse.moveTo(tester.getCenter(find.text('Pro')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = ring('Pro');
    await tester.pumpAndSettle();
    // `color-mix(in oklab, input, foreground 25%)`, after the web package's
    // 200ms fade, which halfway is on neither colour.
    final lit = ring('Pro');
    expect(midway, isNot(anyOf(PanelColors.panelLight.input, lit)));
    expect(lit.a, closeTo(0.32647, 0.002));
    expect(lit.r * 255, closeTo(23.24, 0.5));
    expect(lit.g, closeTo(lit.r, 1e-6));
    // The chosen option's disc does not change under the pointer.
    await mouse.moveTo(tester.getCenter(find.text('Free')));
    await tester.pump();
    expect(ring('Free'), PanelColors.panelLight.input);
  });

  testWidgets("a card's edge darkens under the pointer, and turns primary "
      'at once when chosen', (tester) async {
    const c = PanelColors.panelLight;
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 360,
          child: _Plans(initial: 'Free', variant: PanelRadioVariant.card),
        ),
      ),
    );
    Color edge(String label) {
      final card = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('$label plan'),
              matching: find.byType(Container),
            )
            .last,
      );
      return ((card.decoration! as BoxDecoration).border! as Border).top.color;
    }

    final lit = c.border.mixOklab(c.foreground, 0.18);
    expect(edge('Pro'), c.border);
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
    await mouse.moveTo(tester.getCenter(find.text('Pro plan')));
    await tester.pump();
    // Halfway through the web package's 200ms fade, it is neither colour.
    await tester.pump(const Duration(milliseconds: 100));
    expect(edge('Pro'), isNot(anyOf(c.border, lit)));
    await tester.pumpAndSettle();
    expect(edge('Pro'), lit);
    await tester.tap(find.text('Pro plan'));
    await tester.pump();
    expect(edge('Pro'), c.primary);
    await tester.pumpAndSettle();
  });

  testWidgets('keyboard focus rings the disc 2pt off it, as the web does', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const _Plans(initial: 'Pro')));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final ring = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          ((widget.decoration as BoxDecoration).border as Border?)?.top.color ==
              PanelColors.panelLight.ring,
    );
    expect(ring, findsOneWidget);
    final side =
        ((tester.widget<DecoratedBox>(ring).decoration as BoxDecoration).border!
                as Border)
            .top;
    expect(side.width, 2);
    expect(side.strokeAlign, 3);
    // Round the 20pt disc, not the 48pt row.
    expect(tester.getSize(ring), const Size(20, 20));
  });

  testWidgets('every size and variant builds in every theme', (tester) async {
    for (final theme in allThemes) {
      for (final variant in PanelRadioVariant.values) {
        for (final size in PanelRadioSize.values) {
          await tester.pumpWidget(
            wrap(
              SizedBox(
                width: 360,
                child: PanelRadioGroup<String>(
                  value: 'b',
                  size: size,
                  variant: variant,
                  onChanged: (_) {},
                  children: const [
                    PanelRadioItem(value: 'a', label: 'Monthly'),
                    PanelRadioItem(
                      value: 'b',
                      label: 'Yearly',
                      description: 'Two months free',
                    ),
                    PanelRadioItem(
                      value: 'c',
                      label: 'Lifetime',
                      enabled: false,
                    ),
                  ],
                ),
              ),
              theme: theme,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    }
  });
}
