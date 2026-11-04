import 'dart:ui' show CheckedState, SemanticsRole, Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

Widget _trigger(BuildContext context, PanelPopoverController controller) =>
    PanelButton(
      key: const Key('trigger'),
      variant: PanelButtonVariant.outline,
      onPressed: controller.toggle,
      child: const Text('Options'),
    );

void main() {
  testWidgets('a row runs its action and closes the menu', (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          width: 224,
          builder: _trigger,
          children: [
            PanelMenuItem(
              leading: const PanelIcon(PanelIcons.pencil),
              shortcut: '⌘R',
              onSelected: () => selected.add('rename'),
              child: const Text('Rename'),
            ),
            const PanelMenuSeparator(),
            PanelMenuItem(
              variant: PanelMenuItemVariant.destructive,
              leading: const PanelIcon(PanelIcons.trash),
              description: 'This cannot be undone',
              onSelected: () => selected.add('delete'),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('⌘R'), findsOneWidget);
    expect(find.text('This cannot be undone'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(selected, ['delete']);
    expect(find.text('Rename'), findsNothing);
  });

  testWidgets('haptics tick as a row is chosen', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          haptics: true,
          builder: _trigger,
          children: [
            PanelMenuItem(onSelected: () {}, child: const Text('Rename')),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(
      calls.where(
        (call) =>
            call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.selectionClick',
      ),
      hasLength(1),
    );
  });

  testWidgets('a disabled row ignores taps and keeps the menu open', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          builder: _trigger,
          children: [
            // No onSelected: the row is disabled.
            const PanelMenuItem(child: Text('Download')),
            PanelMenuItem(onSelected: () {}, child: const Text('Share')),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(find.text('Download'), findsOneWidget);

    final opacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('Download'), matching: find.byType(Opacity))
          .first,
    );
    expect(opacity.opacity, 0.45);
    expect(
      tester
          .getSemantics(find.text('Download'))
          .getSemanticsData()
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
  });

  testWidgets('checkbox rows toggle and keep the menu open', (tester) async {
    var done = true;
    var archived = false;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) => PanelMenu(
            builder: _trigger,
            children: [
              const PanelMenuLabel('Show'),
              PanelMenuCheckboxItem(
                value: done,
                onChanged: (v) => setState(() => done = v),
                child: const Text('Completed'),
              ),
              PanelMenuCheckboxItem(
                value: archived,
                onChanged: (v) => setState(() => archived = v),
                child: const Text('Archived'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(find.text('SHOW'), findsOneWidget);

    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(archived, isTrue);
    expect(find.text('Archived'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(done, isFalse);

    final semantics = tester.getSemantics(find.text('Archived'));
    expect(
      semantics.getSemanticsData().flagsCollection.isChecked,
      CheckedState.isTrue,
    );
    expect(semantics.role, SemanticsRole.menuItemCheckbox);
  });

  testWidgets('a radio group reports the value chosen', (tester) async {
    var density = 'comfortable';
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) => PanelMenu(
            builder: _trigger,
            children: [
              PanelMenuRadioGroup<String>(
                value: density,
                onChanged: (v) => setState(() => density = v),
                children: const [
                  PanelMenuRadioItem(
                    value: 'comfortable',
                    indicator: PanelMenuRadioIndicator.dot,
                    child: Text('Comfortable'),
                  ),
                  PanelMenuRadioItem(
                    value: 'compact',
                    indicator: PanelMenuRadioIndicator.dot,
                    child: Text('Compact'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.text('Comfortable'))
          .getSemanticsData()
          .flagsCollection
          .isChecked,
      CheckedState.isTrue,
    );

    await tester.tap(find.text('Compact'));
    await tester.pumpAndSettle();
    expect(density, 'compact');
    // A radio row closes the menu, as an action row does.
    expect(find.text('Compact'), findsNothing);
  });

  testWidgets('a submenu expands in place', (tester) async {
    String? moved;
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          builder: _trigger,
          children: [
            PanelMenuSub(
              leading: const PanelIcon(PanelIcons.package),
              children: [
                for (final folder in ['Inbox', 'Archive'])
                  PanelMenuItem(
                    onSelected: () => moved = folder,
                    child: Text(folder),
                  ),
              ],
              child: const Text('Move to'),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsNothing);
    expect(
      tester
          .getSemantics(find.text('Move to'))
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      Tristate.isFalse,
    );

    await tester.tap(find.text('Move to'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Move to'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.text('Move to'))
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      Tristate.isTrue,
    );

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(moved, 'Archive');
    expect(find.text('Move to'), findsNothing);
  });

  testWidgets('arrow keys move between rows, skipping disabled ones', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          builder: _trigger,
          children: [
            PanelMenuItem(
              onSelected: () => selected.add('one'),
              child: const Text('One'),
            ),
            const PanelMenuItem(child: Text('Two')),
            PanelMenuItem(
              onSelected: () => selected.add('three'),
              child: const Text('Three'),
            ),
          ],
        ),
      ),
    );

    // Opened from the keyboard, the first row takes focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focusIsWithin(tester, find.byKey(const Key('trigger'))), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('One'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.text('One'))
          .getSemanticsData()
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      tester
          .getSemantics(find.text('Three'))
          .getSemanticsData()
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );

    // Wraps round to the top.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      tester
          .getSemantics(find.text('One'))
          .getSemanticsData()
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, ['three']);
    expect(find.text('One'), findsNothing);
    expect(focusIsWithin(tester, find.byKey(const Key('trigger'))), isTrue);
  });

  testWidgets('opened with a pointer, the arrows start from the top', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          builder: _trigger,
          children: [
            PanelMenuItem(onSelected: () {}, child: const Text('One')),
            PanelMenuItem(onSelected: () {}, child: const Text('Two')),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    // No row is lit under a pointer that has not moved.
    expect(
      tester
          .getSemantics(find.text('One'))
          .getSemanticsData()
          .flagsCollection
          .isFocused,
      Tristate.isFalse,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      tester
          .getSemantics(find.text('One'))
          .getSemanticsData()
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(
      tester
          .getSemantics(find.text('Two'))
          .getSemanticsData()
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
  });

  testWidgets('the arrow along the line opens a submenu, the other closes it', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          builder: _trigger,
          children: [
            PanelMenuSub(
              children: [
                PanelMenuItem(onSelected: () {}, child: const Text('Inbox')),
              ],
              child: const Text('Move to'),
            ),
          ],
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    bool focused(String label) =>
        tester
            .getSemantics(find.text(label))
            .getSemanticsData()
            .flagsCollection
            .isFocused ==
        Tristate.isTrue;
    expect(focused('Move to'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focused('Inbox'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsNothing);
    expect(focused('Move to'), isTrue);
  });

  testWidgets('Tab and Escape close the menu', (tester) async {
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          builder: _trigger,
          children: [
            PanelMenuItem(onSelected: () {}, child: const Text('One')),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('One'), findsNothing);

    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('One'), findsNothing);
  });

  testWidgets('a tap outside closes the menu without reaching the page', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PanelMenu(
              builder: _trigger,
              children: [
                PanelMenuItem(onSelected: () {}, child: const Text('One')),
              ],
            ),
            const SizedBox(height: 200),
            PanelButton(
              key: const Key('other'),
              onPressed: () => pressed++,
              child: const Text('Other'),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('other')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('One'), findsNothing);
    expect(pressed, 0);
  });

  testWidgets('the panel is a menu of menu items', (tester) async {
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          builder: _trigger,
          children: [
            PanelMenuItem(onSelected: () {}, child: const Text('One')),
          ],
        ),
      ),
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('trigger')))
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      Tristate.isFalse,
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.text('One')).role, SemanticsRole.menuItem);
    expect(
      tester
          .getSemantics(find.byKey(const Key('trigger')))
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      Tristate.isTrue,
    );
  });

  testWidgets('a controlled menu asks its parent to open and close', (
    tester,
  ) async {
    final requests = <bool>[];
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          isOpen: false,
          onOpenChange: requests.add,
          builder: _trigger,
          children: [
            PanelMenuItem(onSelected: () {}, child: const Text('One')),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(requests, [true]);
    expect(find.text('One'), findsNothing);
  });

  testWidgets('a menu near the bottom edge opens upwards', (tester) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PanelThemeData.panelLight.toMaterialTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PanelMenu(
                builder: _trigger,
                children: [
                  for (final label in ['One', 'Two', 'Three'])
                    PanelMenuItem(onSelected: () {}, child: Text(label)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    final trigger = tester.getRect(find.byKey(const Key('trigger')));
    expect(tester.getRect(find.text('Three')).bottom, lessThan(trigger.top));
  });

  testWidgets('a lit row takes the web highlight; at rest a glyph is muted', (
    tester,
  ) async {
    final c = PanelThemeData.panelLight.colors;
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          builder: _trigger,
          children: [
            PanelMenuItem(
              leading: const PanelIcon(PanelIcons.pencil),
              onSelected: () {},
              child: const Text('Rename'),
            ),
            PanelMenuItem(
              variant: PanelMenuItemVariant.destructive,
              leading: const PanelIcon(PanelIcons.trash),
              onSelected: () {},
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    // Opened with a mouse click, so hover highlights show.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.down(tester.getCenter(find.byKey(const Key('trigger'))));
    await mouse.up();
    await tester.pumpAndSettle();

    Color? labelColor(String label) =>
        DefaultTextStyle.of(tester.element(find.text(label))).style.color;
    Color? glyphColor(String label) => IconTheme.of(
      tester.element(
        find.descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byType(PanelPressable),
          ),
          matching: find.byType(PanelIcon),
        ),
      ),
    ).color;
    Color? fill(String label) =>
        (tester
                    .widget<DecoratedBox>(
                      find
                          .ancestor(
                            of: find.text(label),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .color;

    // At rest: PanelUI's native row. The destructive glyph is not red.
    expect(labelColor('Rename'), c.overlayForeground);
    expect(glyphColor('Rename'), c.mutedForeground);
    expect(labelColor('Delete'), c.destructive);
    expect(glyphColor('Delete'), c.mutedForeground);
    expect(fill('Rename'), isNull);

    await mouse.moveTo(tester.getCenter(find.text('Rename')));
    await tester.pump();
    expect(fill('Rename'), c.accent);
    expect(labelColor('Rename'), c.accentForeground);
    expect(glyphColor('Rename'), c.accentForeground);

    await mouse.moveTo(tester.getCenter(find.text('Delete')));
    await tester.pump();
    expect(fill('Delete'), c.destructive.withValues(alpha: 0.1));
    expect(glyphColor('Delete'), c.destructive);
    expect(fill('Rename'), isNull);
  });

  testWidgets('a closed submenu still leaves the menu gap under its row', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PanelMenu(
          builder: _trigger,
          children: [
            PanelMenuSub(
              children: [
                PanelMenuItem(onSelected: () {}, child: const Text('Inbox')),
              ],
              child: const Text('Move to'),
            ),
            PanelMenuItem(onSelected: () {}, child: const Text('Delete')),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    Rect row(String label) => tester.getRect(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(PanelPressable),
      ),
    );
    // PanelUI's trigger row and its rows are two items of the menu's column,
    // 6pt apart in a scrolling menu, so a folded submenu leaves two gaps.
    expect(row('Delete').top - row('Move to').bottom, moreOrLessEquals(12));
  });

  testWidgets('presented as a sheet, rows run, toggle and close it', (
    tester,
  ) async {
    var archived = false;
    final selected = <String>[];
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) => PanelMenu(
            presentation: PanelPopoverPresentation.bottomSheet,
            builder: _trigger,
            children: [
              PanelMenuCheckboxItem(
                value: archived,
                onChanged: (v) => setState(() => archived = v),
                child: const Text('Archived'),
              ),
              PanelMenuItem(
                onSelected: () => selected.add('share'),
                child: const Text('Share'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(find.byType(PanelBottomSheetBody), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Share')).role,
      SemanticsRole.menuItem,
    );

    // A toggle keeps the sheet up, and the sheet shows the new state.
    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(archived, isTrue);
    expect(
      tester
          .getSemantics(find.text('Archived'))
          .getSemanticsData()
          .flagsCollection
          .isChecked,
      CheckedState.isTrue,
    );

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(selected, ['share']);
    expect(find.text('Share'), findsNothing);
  });

  for (final theme in allThemes) {
    testWidgets('builds open in ${theme.brightness.name} ${theme.radii.lg}', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PanelMenu(
            initiallyOpen: true,
            width: 240,
            builder: _trigger,
            children: [
              const PanelMenuLabel('Account', inset: true),
              const PanelMenuItem(inset: true, child: Text('Profile')),
              PanelMenuItem(
                leading: const PanelIcon(PanelIcons.lock),
                onSelected: () {},
                child: const Text('Lock'),
              ),
              const PanelMenuSeparator(),
              PanelMenuItem(
                variant: PanelMenuItemVariant.destructive,
                leading: const PanelIcon(PanelIcons.trash),
                onSelected: () {},
                child: const Text('Delete'),
              ),
            ],
          ),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lock'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
