import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

/// Opens a sheet and records what it returns.
class _Opener extends StatefulWidget {
  const _Opener({
    this.builder,
    this.size = PanelBottomSheetSize.auto,
    this.isDismissible = true,
    this.detached = false,
    this.blur = false,
  });

  final WidgetBuilder? builder;
  final PanelBottomSheetSize size;
  final bool isDismissible;
  final bool detached;
  final bool blur;

  @override
  State<_Opener> createState() => _OpenerState();
}

class _OpenerState extends State<_Opener> {
  String? result;
  bool returned = false;

  Future<void> _open() async {
    final value = await showPanelBottomSheet<String>(
      context,
      size: widget.size,
      isDismissible: widget.isDismissible,
      detached: widget.detached,
      blur: widget.blur,
      builder: widget.builder ?? _defaultSheet,
    );
    if (!mounted) return;
    setState(() {
      result = value;
      returned = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PanelButton(onPressed: _open, child: const Text('Open'));
  }
}

Widget _defaultSheet(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const PanelBottomSheetHeader(
        title: Text('Rate your order'),
        description: Text('How was the delivery?'),
      ),
      PanelButton(
        onPressed: () => Navigator.pop(context, 'great'),
        child: const Text('Great'),
      ),
    ],
  );
}

Widget _listSheet(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const PanelBottomSheetHeader(title: Text('Choose a country')),
      PanelBottomSheetBody(
        children: [
          for (var i = 0; i < 40; i++)
            SizedBox(height: 48, child: Text('Country $i')),
        ],
      ),
    ],
  );
}

_OpenerState _state(WidgetTester tester) =>
    tester.state<_OpenerState>(find.byType(_Opener));

Future<void> _open(
  WidgetTester tester,
  Widget opener, {
  PanelThemeData? theme,
}) async {
  await tester.pumpWidget(
    wrap(opener, theme: theme ?? PanelThemeData.panelLight),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// The sheet's surface: the box carrying the popover fill.
Finder _surface() => find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration! as BoxDecoration).boxShadow != null &&
      (widget.decoration! as BoxDecoration).color ==
          PanelColors.panelLight.popover,
);

void main() {
  testWidgets('rises into place and returns the value it is popped with', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const _Opener()));
    await tester.tap(find.text('Open'));
    await tester.pump();
    // It starts below the screen.
    expect(tester.getRect(_surface()).top, greaterThanOrEqualTo(600));

    await tester.pumpAndSettle();
    final rect = tester.getRect(_surface());
    expect(rect.bottom, 600);
    // Docked sheets stop at 672pt wide, centred, as on PanelUI's web.
    expect(rect.width, 672);
    expect(rect.left, (800 - 672) / 2);
    expect(find.text('Rate your order'), findsOneWidget);

    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    expect(find.text('Rate your order'), findsNothing);
    expect(_state(tester).result, 'great');
  });

  testWidgets('the close button closes it with null', (tester) async {
    await _open(tester, const _Opener());
    // A 16pt cross in a 32pt circle, 12pt from the top and 16pt from the end.
    final close = find.bySemanticsLabel('Close');
    final circle = tester.getRect(close);
    final sheet = tester.getRect(_surface());
    expect(circle.size, const Size(32, 32));
    expect(circle.top - sheet.top, 1 + 12);
    expect(sheet.right - circle.right, 1 + 16);
    final glyph = find.descendant(
      of: find.byType(PanelPressable),
      matching: find.byType(PanelIcon),
    );
    expect(tester.getSize(glyph), const Size(16, 16));

    // Its target reaches 8pt past the circle.
    await tester.tapAt(circle.centerLeft - const Offset(7, 0));
    await tester.pumpAndSettle();
    expect(find.text('Rate your order'), findsNothing);
    expect(_state(tester).returned, isTrue);
    expect(_state(tester).result, isNull);
  });

  testWidgets('a press dims the close button at once, without a shrink', (
    tester,
  ) async {
    await _open(tester, const _Opener());
    final close = find.bySemanticsLabel('Close');
    final gesture = await tester.startGesture(tester.getCenter(close));
    // Past the wait for the sheet's drag to give up the touch.
    await tester.pump(const Duration(milliseconds: 150));
    final dim = tester.widget<Opacity>(
      find.descendant(of: close, matching: find.byType(Opacity)).first,
    );
    expect(dim.opacity, 0.7);
    expect(
      find.descendant(of: close, matching: find.byType(Transform)),
      findsNothing,
    );
    await gesture.cancel();
    await tester.pumpAndSettle();
  });

  testWidgets('a tap on the scrim and Escape close it', (tester) async {
    await _open(tester, const _Opener());
    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();
    expect(find.text('Rate your order'), findsNothing);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Rate your order'), findsNothing);
  });

  testWidgets('dragged down past the threshold, it leaves', (tester) async {
    await _open(tester, const _Opener());
    final top = tester.getRect(_surface()).top;

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Rate your order')),
    );
    // Once the drag starts the sheet follows the whole of the finger's
    // travel, the slop included, so the point it was taken by stays under it.
    await gesture.moveBy(const Offset(0, 40));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(tester.getRect(_surface()).top, top + 100);
    // 140pt down, past the 120pt threshold, and released at rest.
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Rate your order'), findsNothing);
    expect(_state(tester).returned, isTrue);
  });

  testWidgets('a short slow drag springs back', (tester) async {
    await _open(tester, const _Opener());
    final top = tester.getRect(_surface()).top;

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Rate your order')),
    );
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pump();
    expect(tester.getRect(_surface()).top, greaterThan(top + 20));
    await tester.pumpAndSettle();

    expect(find.text('Rate your order'), findsOneWidget);
    expect(tester.getRect(_surface()).top, closeTo(top, 0.5));
  });

  testWidgets('a quick flick dismisses it however short', (tester) async {
    await _open(tester, const _Opener());
    await tester.fling(find.text('Rate your order'), const Offset(0, 60), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Rate your order'), findsNothing);
  });

  testWidgets('dragged up, it rubber-bands and comes back', (tester) async {
    await _open(tester, const _Opener());
    final top = tester.getRect(_surface()).top;

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Rate your order')),
    );
    // Each move is added to where the sheet is and the result cut to a
    // third, so it settles near half a move above rest however far the
    // finger goes: 300pt up leaves it about 10pt up.
    for (var i = 0; i < 15; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final lifted = top - tester.getRect(_surface()).top;
    expect(lifted, closeTo(20 / 2, 0.5));
    // A move back down is taken whole.
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(tester.getRect(_surface()).top, closeTo(top + 30 - lifted, 0.5));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getRect(_surface()).top, closeTo(top, 0.5));
  });

  testWidgets('taken hold of while it rises, it stops under the finger', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const _Opener(size: PanelBottomSheetSize.half)),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final caught = tester.getRect(_surface()).top;
    // Partway up: on screen, short of its resting place.
    expect(caught, inExclusiveRange(300, 580));

    final gesture = await tester.startGesture(Offset(400, caught + 10));
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump(const Duration(milliseconds: 100));
    // Without the catch it would have gone on rising under the finger.
    expect(tester.getRect(_surface()).top, closeTo(caught + 30, 0.5));

    // The rest of its rise is the drag's now: pushed back to 40pt short of
    // rest and let go slowly, it springs the rest of the way.
    final above = tester.getRect(_surface()).top - 300 - 40;
    await gesture.moveBy(Offset(0, -above));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Rate your order'), findsOneWidget);
    expect(tester.getRect(_surface()).top, 300);
  });

  testWidgets('a sheet that is not dismissible holds still and stays', (
    tester,
  ) async {
    await _open(tester, const _Opener(isDismissible: false));
    final top = tester.getRect(_surface()).top;

    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.drag(find.text('Rate your order'), const Offset(0, 300));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Rate your order'), findsOneWidget);
    expect(tester.getRect(_surface()).top, top);

    // Its own controls still close it.
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Rate your order'), findsNothing);
  });

  testWidgets(
    'a list in it scrolls, and pulls the sheet down from its top',
    (tester) async {
      await _open(
        tester,
        const _Opener(builder: _listSheet, size: PanelBottomSheetSize.half),
      );
      final top = tester.getRect(_surface()).top;
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));

      // Up on the list scrolls it; the sheet stays.
      await tester.drag(find.text('Country 2'), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(100));
      expect(tester.getRect(_surface()).top, top);

      // Down on a scrolled list scrolls it back first.
      await tester.drag(find.text('Country 4'), const Offset(0, 80));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0));
      expect(find.text('Choose a country'), findsOneWidget);

      // Down on the list at its top drags the sheet away.
      scrollable.position.jumpTo(0);
      await tester.pump();
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Country 1')),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.getRect(_surface()).top, greaterThan(top + 100));
      expect(scrollable.position.pixels, 0);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Choose a country'), findsNothing);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('a body the caller wraps in Expanded takes the height left', (
    tester,
  ) async {
    await _open(
      tester,
      _Opener(
        size: PanelBottomSheetSize.full,
        builder: (context) => Column(
          children: [
            const PanelBottomSheetHeader(title: Text('Components')),
            Expanded(
              child: PanelBottomSheetBody(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                spacing: 16,
                children: [for (var i = 0; i < 40; i++) Text('Row $i')],
              ),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final body = tester.getRect(find.byType(SingleChildScrollView));
    final sheet = tester.getRect(_surface());
    // Down to the sheet's 16pt bottom padding.
    expect(body.bottom, closeTo(sheet.bottom - 16, 0.5));
  });

  testWidgets(
    'the body draws no scrollbar, as PanelUI hides its indicator',
    (tester) async {
      await _open(
        tester,
        const _Opener(builder: _listSheet, size: PanelBottomSheetSize.half),
      );
      expect(find.byType(RawScrollbar), findsNothing);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'a touch on the list that catches the sheet settling lets it settle',
    (tester) async {
      await _open(
        tester,
        const _Opener(builder: _listSheet, size: PanelBottomSheetSize.half),
      );
      final top = tester.getRect(_surface()).top;

      // Pull the sheet down by the list at its top, and let it go slowly.
      final pull = await tester.startGesture(
        tester.getCenter(find.text('Country 1')),
      );
      for (var i = 0; i < 4; i++) {
        await pull.moveBy(const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await pull.up();
      await tester.pump(const Duration(milliseconds: 30));
      expect(tester.getRect(_surface()).top, greaterThan(top + 20));

      // A touch that stops it on its way back and lifts straight after the
      // drag starts must not leave it stranded there.
      final touch = await tester.startGesture(
        tester.getCenter(find.text('Country 2')),
      );
      await touch.moveBy(const Offset(0, -20));
      await touch.up();
      await tester.pumpAndSettle();
      expect(tester.getRect(_surface()).top, closeTo(top, 0.5));
    },
    variant: const TargetPlatformVariant({TargetPlatform.android}),
  );

  testWidgets('a mouse drags it by the handle, not by the list', (
    tester,
  ) async {
    await _open(
      tester,
      const _Opener(builder: _listSheet, size: PanelBottomSheetSize.half),
    );
    final top = tester.getRect(_surface()).top;

    final list = await tester.startGesture(
      tester.getCenter(find.text('Country 1')),
      kind: PointerDeviceKind.mouse,
    );
    await list.moveBy(const Offset(0, 100));
    await tester.pump();
    expect(tester.getRect(_surface()).top, top);
    await list.up();
    await tester.pumpAndSettle();

    final handle = await tester.startGesture(
      Offset(400, top + 10),
      kind: PointerDeviceKind.mouse,
    );
    for (var i = 0; i < 10; i++) {
      await handle.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.getRect(_surface()).top, greaterThan(top + 100));
    await handle.up();
    await tester.pumpAndSettle();
    expect(find.text('Choose a country'), findsNothing);
  });

  testWidgets('half and full fix the height, clear of the status bar', (
    tester,
  ) async {
    await _open(tester, const _Opener(size: PanelBottomSheetSize.half));
    expect(tester.getSize(_surface()).height, 300);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          padding: EdgeInsets.only(top: 47, bottom: 34),
          viewPadding: EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: wrap(const _Opener(size: PanelBottomSheetSize.full)),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    // 94% of 600 is 564, more than the 600 - 47 - 8 the status bar allows.
    expect(tester.getSize(_surface()).height, 545);
  });

  testWidgets('without a close button or a handle', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => PanelButton(
            onPressed: () => showPanelBottomSheet<void>(
              context,
              showClose: false,
              showHandle: false,
              builder: _defaultSheet,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Rate your order'), findsOneWidget);
    expect(find.bySemanticsLabel('Close'), findsNothing);
    // The sheet keeps its 8pt top padding when the handle is gone.
    expect(
      tester.getRect(find.text('Rate your order')).top -
          tester.getRect(_surface()).top,
      closeTo(1 + 8, 4),
    );
  });

  testWidgets('a detached sheet floats clear of the edges', (tester) async {
    await _open(tester, const _Opener(detached: true));
    final rect = tester.getRect(_surface());
    expect(rect.bottom, 600 - 24);
    expect(rect.left, (800 - 512) / 2);
    expect(rect.width, 512);
  });

  testWidgets('it rides above the keyboard', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          viewInsets: EdgeInsets.only(bottom: 250),
        ),
        child: wrap(const _Opener()),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.getRect(_surface()).bottom, 350);
  });

  testWidgets('under reduced motion it fades in at rest', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          disableAnimations: true,
        ),
        child: wrap(const _Opener()),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getRect(_surface()).bottom, 600);
    final fade = tester.widget<Opacity>(
      find.ancestor(of: _surface(), matching: find.byType(Opacity)).first,
    );
    expect(fade.opacity, greaterThan(0));
    expect(fade.opacity, lessThan(1));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getRect(_surface()).bottom, 600);
    await tester.pumpAndSettle();
    expect(find.text('Rate your order'), findsNothing);
  });

  testWidgets('scopes and names its route, and labels the scrim', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester, const _Opener());
    // A plain line of text, as in PanelUI, that names the route.
    expect(
      tester.getSemantics(find.text('Rate your order')),
      matchesSemantics(label: 'Rate your order', namesRoute: true),
    );
    expect(find.bySemanticsLabel('Close sheet'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('builds in every theme, docked and detached', (tester) async {
    for (final theme in allThemes) {
      for (final detached in [false, true]) {
        await _open(
          tester,
          _Opener(detached: detached, blur: detached),
          theme: theme,
        );
        expect(find.text('Rate your order'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.bySemanticsLabel('Close'));
        await tester.pumpAndSettle();
      }
    }
  });
}
