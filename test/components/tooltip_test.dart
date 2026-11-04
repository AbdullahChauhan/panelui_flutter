import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';
import 'package:panelui_flutter/src/foundation/anchored_overlay.dart';

import '../helpers.dart';

Widget _button({VoidCallback? onPressed}) => PanelButton(
  key: const Key('trigger'),
  size: PanelButtonSize.icon,
  variant: PanelButtonVariant.ghost,
  semanticLabel: 'Copy',
  onPressed: onPressed ?? () {},
  child: const PanelIcon(PanelIcons.link),
);

/// A view of [size] logical pixels with the trigger pinned by [alignment].
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

void main() {
  testWidgets('a long press shows the label, which hides itself', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(
        PanelTooltip(
          message: 'Copy link',
          child: _button(onPressed: () => pressed++),
        ),
      ),
    );
    expect(find.text('Copy link'), findsNothing);

    await tester.longPress(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsOneWidget);
    // The long press belongs to the tooltip, not to the button.
    expect(pressed, 0);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsNothing);
  });

  testWidgets('sits above its trigger, centred, 6pt away', (tester) async {
    await tester.pumpWidget(
      wrap(PanelTooltip(message: 'Copy link', child: _button())),
    );
    await tester.longPress(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();

    final trigger = tester.getRect(find.byKey(const Key('trigger')));
    final label = tester.getRect(
      find
          .ancestor(
            of: find.text('Copy link'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(label.bottom, moreOrLessEquals(trigger.top - 6, epsilon: 0.01));
    expect(label.center.dx, moreOrLessEquals(trigger.center.dx, epsilon: 0.01));
  });

  testWidgets('openOn press toggles the label and still presses the trigger', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(
        PanelTooltip(
          message: 'Syncs every 15 minutes',
          openOn: PanelTooltipOpenOn.press,
          duration: Duration.zero,
          child: _button(onPressed: () => pressed++),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(find.text('Syncs every 15 minutes'), findsOneWidget);
    expect(pressed, 1);

    // Duration zero keeps it up.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Syncs every 15 minutes'), findsOneWidget);

    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(find.text('Syncs every 15 minutes'), findsNothing);
    expect(pressed, 2);
  });

  testWidgets('a tap elsewhere hides the label and still lands', (
    tester,
  ) async {
    var other = 0;
    await tester.pumpWidget(
      wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 80,
          children: [
            PanelTooltip(
              message: 'Copy link',
              openOn: PanelTooltipOpenOn.press,
              duration: Duration.zero,
              child: _button(),
            ),
            PanelButton(
              key: const Key('other'),
              onPressed: () => other++,
              child: const Text('Other'),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsOneWidget);

    await tester.tap(find.byKey(const Key('other')));
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsNothing);
    expect(other, 1);
  });

  testWidgets('a mouse shows it after the hover delay and hides it on exit', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(PanelTooltip(message: 'Copy link', child: _button())),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(const Key('trigger'))));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Copy link'), findsNothing);

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsOneWidget);

    // Hover keeps it up past the touch duration.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Copy link'), findsOneWidget);

    await mouse.moveTo(const Offset(1, 1));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsNothing);
  });

  testWidgets('a click keeps up a press tooltip that hovering showed', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PanelTooltip(
          message: 'Syncs every 15 minutes',
          openOn: PanelTooltipOpenOn.press,
          duration: Duration.zero,
          child: _button(),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    final trigger = tester.getCenter(find.byKey(const Key('trigger')));
    await mouse.moveTo(trigger);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Syncs every 15 minutes'), findsOneWidget);

    await mouse.down(trigger);
    await mouse.up();
    await mouse.moveTo(const Offset(1, 1));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    // Kept, not toggled away, and no longer tied to the pointer.
    expect(find.text('Syncs every 15 minutes'), findsOneWidget);

    await mouse.down(trigger);
    await mouse.up();
    await tester.pumpAndSettle();
    expect(find.text('Syncs every 15 minutes'), findsNothing);
  });

  testWidgets('keyboard focus shows it and Escape hides it', (tester) async {
    await tester.pumpWidget(
      wrap(PanelTooltip(message: 'Copy link', child: _button())),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsNothing);
  });

  testWidgets('flips below a trigger at the top of the screen', (tester) async {
    await _pumpInView(
      tester,
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: PanelTooltip(message: 'Copy link', child: _button()),
      ),
      alignment: Alignment.topCenter,
    );
    await tester.longPress(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    final trigger = tester.getRect(find.byKey(const Key('trigger')));
    expect(
      tester.getRect(find.text('Copy link')).top,
      greaterThan(trigger.bottom),
    );
  });

  testWidgets('start is the left in LTR and the right in RTL', (tester) async {
    for (final direction in TextDirection.values) {
      await _pumpInView(
        tester,
        PanelTooltip(
          message: 'Copy link',
          placement: PanelTooltipPlacement.start,
          child: _button(),
        ),
        direction: direction,
      );
      await tester.longPress(find.byKey(const Key('trigger')));
      await tester.pumpAndSettle();
      final trigger = tester.getRect(find.byKey(const Key('trigger')));
      final label = tester.getRect(find.text('Copy link'));
      if (direction == TextDirection.ltr) {
        expect(label.right, lessThan(trigger.left));
      } else {
        expect(label.left, greaterThan(trigger.right));
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('slides back on screen near the side', (tester) async {
    await _pumpInView(
      tester,
      PanelTooltip(
        message: 'A label long enough to run off the edge',
        child: _button(),
      ),
      alignment: Alignment.centerRight,
    );
    await tester.longPress(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    final label = tester.getRect(
      find.text('A label long enough to run off the edge'),
    );
    expect(label.right, lessThanOrEqualTo(400 - 12));
  });

  testWidgets('gives its message to the trigger as a tooltip', (tester) async {
    await tester.pumpWidget(
      wrap(PanelTooltip(message: 'Copy link', child: _button())),
    );
    final data = tester
        .getSemantics(find.byKey(const Key('trigger')))
        .getSemanticsData();
    expect(data.tooltip, 'Copy link');
    expect(data.label, 'Copy');
  });

  testWidgets('a controlled tooltip shows and asks to hide', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      wrap(
        PanelTooltip(
          message: 'Copy link',
          isOpen: true,
          onOpenChange: changes.add,
          child: _button(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(changes, [false]);
    // It is controlled, so it stays until the parent says otherwise.
    expect(find.text('Copy link'), findsOneWidget);
  });

  testWidgets('rich surface content with a title and a description', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PanelTooltip(
          variant: PanelTooltipVariant.surface,
          width: 264,
          showArrow: true,
          isOpen: true,
          duration: Duration.zero,
          content: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              PanelTooltipTitle(child: Text('Streaming')),
              PanelTooltipDescription(child: Text('Tokens arrive as written.')),
            ],
          ),
          child: _button(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Streaming'), findsOneWidget);
    final style = DefaultTextStyle.of(
      tester.element(find.text('Tokens arrive as written.')),
    ).style;
    expect(style.color, PanelThemeData.panelLight.colors.mutedForeground);
    final panel = tester.getRect(
      find
          .ancestor(
            of: find.text('Streaming'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(panel.width, 264);
    // A column written without `mainAxisSize: min` still sizes to its lines.
    expect(panel.height, lessThan(120));
  });

  testWidgets('the arrow is the label\'s fill, without an outline', (
    tester,
  ) async {
    final c = PanelThemeData.panelLight.colors;
    for (final variant in PanelTooltipVariant.values) {
      await tester.pumpWidget(
        wrap(
          PanelTooltip(
            message: 'Copy link',
            variant: variant,
            showArrow: true,
            isOpen: true,
            duration: Duration.zero,
            child: _button(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final arrow = tester
          .widget<AnchoredOverlay>(find.byType(AnchoredOverlay))
          .arrow!;
      final surface = variant == PanelTooltipVariant.surface;
      expect(arrow.size, 10);
      expect(arrow.radius, 1);
      expect(arrow.color, surface ? c.popover : c.foreground);
      // PanelUI gives the surface arrow a border colour but no width.
      expect(arrow.borderWidth, 0);
      expect(arrow.inset, surface ? 1 : 0);
      await tester.pumpWidget(const SizedBox());
    }
  });

  for (final theme in allThemes) {
    testWidgets('builds in every theme '
        '(${theme.brightness.name}, radius ${theme.radii.lg})', (tester) async {
      await tester.pumpWidget(
        wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 80,
            children: [
              PanelTooltip(
                message: 'Inverted',
                showArrow: true,
                isOpen: true,
                duration: Duration.zero,
                child: _button(),
              ),
              const PanelTooltip(
                message: 'Surface',
                variant: PanelTooltipVariant.surface,
                placement: PanelTooltipPlacement.bottom,
                showArrow: true,
                isOpen: true,
                duration: Duration.zero,
                child: Text('Trigger'),
              ),
            ],
          ),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inverted'), findsOneWidget);
      expect(find.text('Surface'), findsOneWidget);
    });
  }
}
