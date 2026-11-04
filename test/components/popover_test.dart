import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';
import 'package:panelui_flutter/src/foundation/anchored_overlay.dart';

import '../helpers.dart';

Widget _trigger(BuildContext context, PanelPopoverController controller) =>
    PanelButton(
      key: const Key('trigger'),
      onPressed: controller.toggle,
      child: const Text('Open'),
    );

Widget _popover({
  PanelPopoverController? controller,
  bool? isOpen,
  ValueChanged<bool>? onOpenChange,
  bool initiallyOpen = false,
  PanelPopoverPlacement placement = PanelPopoverPlacement.bottom,
  PanelPopoverAlign align = PanelPopoverAlign.center,
  bool dismissible = true,
  bool showArrow = false,
  bool scrim = false,
  double? width = 200,
  bool matchTriggerWidth = false,
  double? minWidth,
  double? maxHeight,
  bool scrollable = false,
  List<Widget>? children,
}) {
  return PanelPopover(
    controller: controller,
    isOpen: isOpen,
    onOpenChange: onOpenChange,
    initiallyOpen: initiallyOpen,
    placement: placement,
    align: align,
    dismissible: dismissible,
    showArrow: showArrow,
    scrim: scrim,
    width: width,
    matchTriggerWidth: matchTriggerWidth,
    minWidth: minWidth,
    maxHeight: maxHeight,
    scrollable: scrollable,
    builder: _trigger,
    children:
        children ??
        const [
          PanelPopoverTitle(child: Text('Export')),
          PanelPopoverDescription(child: Text('Choose a format.')),
        ],
  );
}

/// The panel's surface, found from its title.
Rect _panel(WidgetTester tester) => tester.getRect(
  find
      .ancestor(
        of: find.text('Export'),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      )
      .first,
);

/// A view of [size] logical pixels with the popover pinned by [alignment].
Future<void> _pumpInView(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 400),
  Alignment alignment = Alignment.center,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: PanelThemeData.panelLight.toMaterialTheme(),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(alignment: alignment, child: child),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('trigger')));
  await tester.pumpAndSettle();
}

void main() {
  group('placement', () {
    const bounds = Rect.fromLTRB(12, 12, 388, 388);
    const size = Size(100, 60);

    test('opens on the preferred side when it fits', () {
      final geometry = placeBesideAnchor(
        anchor: const Rect.fromLTWH(150, 150, 100, 40),
        size: size,
        side: AnchorSide.bottom,
        bounds: bounds,
        offset: 8,
      );
      expect(geometry.side, AnchorSide.bottom);
      expect(geometry.offset, const Offset(150, 198));
      expect(geometry.arrowOffset, 50);
    });

    test('flips only when the other side has more room', () {
      final flipped = placeBesideAnchor(
        anchor: const Rect.fromLTWH(150, 330, 100, 40),
        size: size,
        side: AnchorSide.bottom,
        bounds: bounds,
        offset: 8,
      );
      expect(flipped.side, AnchorSide.top);
      expect(flipped.offset.dy, 330 - 8 - 60);

      // Neither side fits a tall panel; the roomier one wins.
      final tall = placeBesideAnchor(
        anchor: const Rect.fromLTWH(150, 100, 100, 40),
        size: const Size(100, 300),
        side: AnchorSide.top,
        bounds: bounds,
        offset: 8,
      );
      expect(tall.side, AnchorSide.bottom);
    });

    test('clamps along the other axis and keeps the arrow on the anchor', () {
      final geometry = placeBesideAnchor(
        anchor: const Rect.fromLTWH(360, 150, 20, 20),
        size: size,
        side: AnchorSide.bottom,
        bounds: bounds,
        offset: 8,
        arrowInset: 12,
      );
      expect(geometry.offset.dx, 388 - 100);
      // The anchor's centre is at 370, 82 into the panel.
      expect(geometry.arrowOffset, 82);
    });

    test('aligns start and end, and beside the anchor', () {
      final start = placeBesideAnchor(
        anchor: const Rect.fromLTWH(150, 150, 100, 40),
        size: size,
        side: AnchorSide.bottom,
        align: AnchorAlign.end,
        alignOffset: 4,
        bounds: bounds,
      );
      expect(start.offset.dx, 250 - 100 + 4);

      final right = placeBesideAnchor(
        anchor: const Rect.fromLTWH(100, 150, 40, 40),
        size: size,
        side: AnchorSide.right,
        bounds: bounds,
        offset: 6,
      );
      expect(right.side, AnchorSide.right);
      expect(right.offset, const Offset(146, 140));
    });

    test('a dropdown is capped at the room below, never under 160', () {
      const screen = Rect.fromLTRB(0, 0, 400, 500);
      const roomy = Rect.fromLTWH(20, 100, 200, 48);
      expect(
        dropdownRoom(
          anchor: roomy,
          bounds: screen,
          side: AnchorSide.bottom,
          offset: 8,
        ),
        500 - 148 - 8 - 8,
      );
      const cramped = Rect.fromLTWH(20, 380, 200, 48);
      expect(
        dropdownRoom(
          anchor: cramped,
          bounds: screen,
          side: AnchorSide.bottom,
          offset: 8,
        ),
        160,
      );
      // It flips only when the list is taller than the space below.
      expect(
        dropdownFlips(anchor: roomy, bounds: screen, height: 336, offset: 8),
        isFalse,
      );
      expect(
        dropdownFlips(anchor: cramped, bounds: screen, height: 160, offset: 8),
        isTrue,
      );
    });
  });

  testWidgets('opens below the trigger and closes on a second press', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(_popover()));
    expect(find.text('Export'), findsNothing);

    await _open(tester);
    expect(find.text('Export'), findsOneWidget);
    final trigger = tester.getRect(find.byKey(const Key('trigger')));
    final panel = _panel(tester);
    expect(panel.top, moreOrLessEquals(trigger.bottom + 8, epsilon: 0.01));
    expect(panel.center.dx, moreOrLessEquals(trigger.center.dx, epsilon: 0.01));
    expect(panel.width, 200);

    // The catcher covers the trigger, so a second press closes the panel.
    await tester.tap(find.byKey(const Key('trigger')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Export'), findsNothing);
  });

  testWidgets('closes on Escape and gives focus back to the trigger', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(_popover()));
    await _open(tester);
    expect(focusIsWithin(tester, find.byKey(const Key('trigger'))), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Export'), findsNothing);
    expect(focusIsWithin(tester, find.byKey(const Key('trigger'))), isTrue);
  });

  testWidgets('a tap outside closes it without reaching the page', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 160,
          children: [
            _popover(),
            PanelButton(
              key: const Key('other'),
              onPressed: () => pressed++,
              child: const Text('Other'),
            ),
          ],
        ),
      ),
    );
    await _open(tester);
    await tester.tap(find.byKey(const Key('other')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Export'), findsNothing);
    expect(pressed, 0);
  });

  testWidgets('a tap inside the panel keeps it open', (tester) async {
    await tester.pumpWidget(wrap(_popover()));
    await _open(tester);
    await tester.tap(find.text('Choose a format.'));
    await tester.pumpAndSettle();
    expect(find.text('Export'), findsOneWidget);
  });

  testWidgets('one that is not dismissible ignores taps outside and Escape', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        _popover(
          dismissible: false,
          children: [
            const PanelPopoverTitle(child: Text('Export')),
            Builder(
              builder: (context) => PanelButton(
                key: const Key('close'),
                onPressed: () => PanelPopover.of(context).close(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
    await _open(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Export'), findsOneWidget);

    await tester.tap(find.byKey(const Key('close')));
    await tester.pumpAndSettle();
    expect(find.text('Export'), findsNothing);
  });

  testWidgets('a controller opens and closes it and reports changes', (
    tester,
  ) async {
    final controller = PanelPopoverController();
    addTearDown(controller.dispose);
    final changes = <bool>[];
    await tester.pumpWidget(
      wrap(_popover(controller: controller, onOpenChange: changes.add)),
    );
    controller.open();
    await tester.pumpAndSettle();
    expect(find.text('Export'), findsOneWidget);
    expect(controller.isOpen, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.text('Export'), findsNothing);
    expect(changes, [true, false]);
  });

  testWidgets('isOpen hands every request to onOpenChange', (tester) async {
    var open = false;
    final requests = <bool>[];
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) => _popover(
            isOpen: open,
            onOpenChange: (value) {
              requests.add(value);
              setState(() => open = value);
            },
          ),
        ),
      ),
    );
    await _open(tester);
    expect(requests, [true]);
    expect(find.text('Export'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(requests, [true, false]);
    expect(find.text('Export'), findsNothing);
  });

  testWidgets('the back gesture closes it instead of leaving the screen', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(_popover(initiallyOpen: true)));
    await tester.pumpAndSettle();
    expect(find.text('Export'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.text('Export'), findsNothing);
    expect(find.byKey(const Key('trigger')), findsOneWidget);
  });

  testWidgets('one back press closes only the popup opened last', (
    tester,
  ) async {
    String? fruit;
    await tester.pumpWidget(
      wrap(
        _popover(
          width: 260,
          children: [
            const PanelPopoverTitle(child: Text('Export')),
            StatefulBuilder(
              builder: (context, setState) => PanelSelect<String>(
                key: const Key('select'),
                value: fruit,
                onChanged: (value) => setState(() => fruit = value),
                options: const [
                  PanelSelectOption(value: 'pdf', label: 'PDF'),
                  PanelSelectOption(value: 'csv', label: 'CSV'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await _open(tester);
    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('select')),
            matching: find.byType(PanelPressable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('CSV'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('CSV'), findsNothing);
    expect(find.text('Export'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Export'), findsNothing);
  });

  testWidgets('flips above a trigger near the bottom edge', (tester) async {
    await _pumpInView(
      tester,
      Padding(padding: const EdgeInsets.only(bottom: 24), child: _popover()),
      alignment: Alignment.bottomCenter,
    );
    await _open(tester);
    final trigger = tester.getRect(find.byKey(const Key('trigger')));
    expect(
      _panel(tester).bottom,
      moreOrLessEquals(trigger.top - 8, epsilon: 0.01),
    );
  });

  testWidgets('slides back inside the safe area near the side', (tester) async {
    await _pumpInView(
      tester,
      _popover(width: 260, align: PanelPopoverAlign.start),
      alignment: Alignment.centerRight,
    );
    await _open(tester);
    expect(_panel(tester).right, moreOrLessEquals(400 - 12, epsilon: 0.01));
  });

  testWidgets('start and end follow the reading direction', (tester) async {
    for (final direction in TextDirection.values) {
      await _pumpInView(
        tester,
        _popover(width: 120, placement: PanelPopoverPlacement.end),
        direction: direction,
      );
      await _open(tester);
      final trigger = tester.getRect(find.byKey(const Key('trigger')));
      final panel = _panel(tester);
      if (direction == TextDirection.ltr) {
        expect(panel.left, moreOrLessEquals(trigger.right + 8, epsilon: 0.01));
      } else {
        expect(panel.right, moreOrLessEquals(trigger.left - 8, epsilon: 0.01));
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('matches the trigger width, with a floor', (tester) async {
    await tester.pumpWidget(
      wrap(_popover(width: null, matchTriggerWidth: true)),
    );
    await _open(tester);
    final trigger = tester.getRect(find.byKey(const Key('trigger')));
    expect(_panel(tester).width, moreOrLessEquals(trigger.width));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      wrap(_popover(width: null, matchTriggerWidth: true, minWidth: 260)),
    );
    await _open(tester);
    expect(_panel(tester).width, 260);
  });

  testWidgets('sizes to its content when it has no width', (tester) async {
    await tester.pumpWidget(wrap(_popover(width: null)));
    await _open(tester);
    final title = tester.getRect(find.text('Choose a format.'));
    // The panel's padding (16) and border (1) either side of the widest line.
    expect(_panel(tester).width, moreOrLessEquals(title.width + 34));
  });

  testWidgets('a scrollable panel is capped at maxHeight and scrolls', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        _popover(
          maxHeight: 200,
          scrollable: true,
          children: [
            const PanelPopoverTitle(child: Text('Export')),
            for (var i = 0; i < 12; i++)
              PanelPopoverDescription(child: Text('Release note $i')),
          ],
        ),
      ),
    );
    await _open(tester);
    expect(_panel(tester).height, 200);
    await tester.scrollUntilVisible(
      find.text('Release note 11'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Release note 11').hitTestable(), findsOneWidget);
  });

  testWidgets('the trigger announces whether it is expanded', (tester) async {
    await tester.pumpWidget(wrap(_popover()));
    expect(
      tester
          .getSemantics(find.byKey(const Key('trigger')))
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      Tristate.isFalse,
    );
    await _open(tester);
    expect(
      tester
          .getSemantics(find.byKey(const Key('trigger')))
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      Tristate.isTrue,
    );
  });

  testWidgets('opens at once when motion is reduced', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: _popover(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    // One frame for the portal to show, one to build the panel in it.
    await tester.pump();
    await tester.pump();
    expect(find.text('Export'), findsOneWidget);
    // Nothing is left animating, so no further frame is asked for.
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump();
    expect(find.text('Export'), findsNothing);
  });

  for (final theme in allThemes) {
    testWidgets('builds open with an arrow and a scrim '
        '(${theme.brightness.name}, radius ${theme.radii.lg})', (tester) async {
      await tester.pumpWidget(
        wrap(
          _popover(initiallyOpen: true, showArrow: true, scrim: true),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Export'), findsOneWidget);
      final title = DefaultTextStyle.of(
        tester.element(find.text('Export')),
      ).style;
      expect(title.color, theme.colors.popoverForeground);
      expect(title.fontWeight, FontWeight.w600);
    });
  }
}
