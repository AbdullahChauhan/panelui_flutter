import 'dart:ui' show SemanticsAction;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

/// A page with a button that raises toasts through [onPressed].
Widget _app(
  void Function(BuildContext context) onPressed, {
  PanelThemeData theme = PanelThemeData.panelLight,
}) {
  return wrap(
    Builder(
      builder: (context) => PanelButton(
        onPressed: () => onPressed(context),
        child: const Text('Raise'),
      ),
    ),
    theme: theme,
  );
}

/// The card a toast with [title] is drawn on.
Finder _card(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(PanelToast));

/// Counts how often its subtree is mounted.
class _Probe extends StatefulWidget {
  const _Probe({required this.onMount, required this.child});

  final VoidCallback onMount;
  final Widget child;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> _setLifecycle(WidgetTester tester, AppLifecycleState state) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.lifecycle.name,
    SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
    (_) {},
  );
}

void main() {
  testWidgets('shows a toast that leaves on its own after four seconds', (
    tester,
  ) async {
    late PanelToastHandle toast;
    await tester.pumpWidget(
      _app(
        (context) => toast = showPanelToast(
          context,
          title: const Text('Saved'),
          description: const Text('All changes are stored.'),
        ),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('All changes are stored.'), findsOneWidget);
    expect(toast.isShowing, isTrue);

    // The countdown runs from the moment it is raised.
    await tester.pump(const Duration(milliseconds: 3900));
    expect(toast.isShowing, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(toast.isShowing, isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
    await expectLater(toast.closed, completes);
  });

  testWidgets('a toast with no duration stays until it is closed', (
    tester,
  ) async {
    late PanelToastHandle toast;
    await tester.pumpWidget(
      _app(
        (context) => toast = showPanelToast(
          context,
          title: const Text('Pinned'),
          duration: Duration.zero,
        ),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('Pinned'), findsOneWidget);
    // A 14pt cross in a 24pt circle.
    final glyph = find.descendant(
      of: find.byType(PanelPressable),
      matching: find.byType(PanelIcon),
    );
    expect(tester.getSize(glyph), const Size(14, 14));
    expect(
      tester.getSize(
        find.ancestor(of: glyph, matching: find.byType(AnimatedContainer)),
      ),
      const Size(24, 24),
    );

    await tester.tap(find.bySemanticsLabel('Dismiss notification'));
    await tester.pumpAndSettle();
    expect(find.text('Pinned'), findsNothing);
    expect(toast.isShowing, isFalse);
  });

  testWidgets('hide() closes it, and the overlay entry goes with it', (
    tester,
  ) async {
    late PanelToastHandle toast;
    await tester.pumpWidget(
      _app(
        (context) => toast = showPanelToast(
          context,
          title: const Text('Uploading'),
          duration: Duration.zero,
        ),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    expect(find.byType(PanelToast), findsOneWidget);

    toast.hide();
    await tester.pumpAndSettle();
    expect(find.byType(PanelToast), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ToastLayer',
      ),
      findsNothing,
    );
    // Hiding twice is harmless.
    toast.hide();
    await tester.pump();
  });

  testWidgets('a toast still counting down when the app goes away leaves '
      'no timer behind', (tester) async {
    late PanelToastHandle toast;
    await tester.pumpWidget(
      _app(
        (context) => toast = showPanelToast(context, title: const Text('Bye')),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    expect(toast.isShowing, isFalse);
    await expectLater(toast.closed, completes);
  });

  testWidgets('an action runs and closes its toast, with no close button', (
    tester,
  ) async {
    var viewed = false;
    await tester.pumpWidget(
      _app(
        (context) => showPanelToast(
          context,
          variant: PanelToastVariant.success,
          title: const Text('Deployment complete'),
          action: PanelToastAction(
            onPressed: () => viewed = true,
            child: const Text('View'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Dismiss notification'), findsNothing);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(viewed, isTrue);
    expect(find.text('Deployment complete'), findsNothing);
  });

  testWidgets('each variant draws its own icon and colours, in every theme', (
    tester,
  ) async {
    for (final theme in allThemes) {
      await tester.pumpWidget(
        _app((context) {
          for (final variant in PanelToastVariant.values) {
            // One deck each, so all five are on screen.
            showPanelToast(
              context,
              position: PanelToastPosition.values[variant.index],
              variant: variant,
              title: Text(variant.name),
              description: const Text('Details'),
              duration: Duration.zero,
            );
          }
        }, theme: theme),
      );
      await tester.tap(find.text('Raise'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final c = theme.colors;
      final success = tester.widget<Container>(
        find
            .descendant(of: _card('success'), matching: find.byType(Container))
            .first,
      );
      final decoration = success.decoration! as BoxDecoration;
      expect(decoration.color, c.popover);
      expect(
        (decoration.border! as Border).top.color,
        c.success.withValues(alpha: 0.32),
      );
      final title = DefaultTextStyle.of(tester.element(find.text('success')));
      expect(title.style.color, c.successForeground);
      expect(title.style.fontWeight, FontWeight.w500);
      final neutral = DefaultTextStyle.of(tester.element(find.text('neutral')));
      expect(neutral.style.color, c.popoverForeground);

      hideAllPanelToasts(tester.element(find.text('Raise')));
      await tester.pumpAndSettle();
      expect(find.byType(PanelToast), findsNothing);
    }
  });

  testWidgets('swiped toward its edge it leaves; the other way it returns', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        (context) => showPanelToast(
          context,
          title: const Text('Swipe me'),
          duration: Duration.zero,
        ),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    final rest = tester.getRect(_card('Swipe me'));

    // Up, away from the bottom edge: it resists, then returns.
    final gesture = await tester.startGesture(rest.center);
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final lifted = rest.top - tester.getRect(_card('Swipe me')).top;
    expect(lifted, greaterThan(20));
    expect(lifted, lessThanOrEqualTo(40));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Swipe me'), findsOneWidget);
    expect(tester.getRect(_card('Swipe me')).top, closeTo(rest.top, 0.5));

    // Down, toward it: past 50pt it goes.
    await tester.timedDrag(
      find.text('Swipe me'),
      const Offset(0, 90),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(find.text('Swipe me'), findsNothing);
  });

  testWidgets('a top toast hangs from the top and is swiped up', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        (context) => showPanelToast(
          context,
          variant: PanelToastVariant.destructive,
          position: PanelToastPosition.top,
          title: const Text('Upload failed'),
          duration: Duration.zero,
        ),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    final rect = tester.getRect(_card('Upload failed'));
    // 800pt is wide, so the margin is 24pt and the toast at most 360pt.
    expect(rect.top, 24);
    expect(rect.width, 360);
    expect(rect.center.dx, 400);

    // Short of the 50pt distance, so it is the speed that dismisses it.
    await tester.fling(find.text('Upload failed'), const Offset(0, -60), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Upload failed'), findsNothing);
  });

  testWidgets('positions: corners on a wide screen, full width on a phone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        (context) => showPanelToast(
          context,
          position: PanelToastPosition.bottomEnd,
          title: const Text('Corner'),
          duration: Duration.zero,
        ),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    final corner = tester.getRect(_card('Corner'));
    expect(corner.right, 800 - 24);
    expect(corner.bottom, 600 - 24);
    hideAllPanelToasts(tester.element(find.text('Raise')));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    final phone = tester.getRect(_card('Corner'));
    expect(phone.left, 16);
    expect(phone.right, 390 - 16);
    expect(phone.bottom, 800 - 16);
  });

  testWidgets('it keeps clear of the keyboard and the safe area', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          padding: EdgeInsets.only(top: 20),
          viewInsets: EdgeInsets.only(bottom: 250),
        ),
        child: _app((context) {
          showPanelToast(
            context,
            title: const Text('Bottom'),
            duration: Duration.zero,
          );
          showPanelToast(
            context,
            position: PanelToastPosition.top,
            title: const Text('Top'),
            duration: Duration.zero,
          );
        }),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    expect(tester.getRect(_card('Bottom')).bottom, 600 - 250 - 24);
    expect(tester.getRect(_card('Top')).top, 20 + 24);
  });

  testWidgets('stacks the newest in front, with two peeking out behind', (
    tester,
  ) async {
    const titles = ['One', 'Two', 'Three', 'Four', 'Five'];
    var raised = 0;
    await tester.pumpWidget(
      _app(
        (context) => showPanelToast(
          context,
          title: Text(titles[raised++]),
          description: const Text('Swipe down to dismiss the front one.'),
          duration: Duration.zero,
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Raise'));
      await tester.pump(const Duration(milliseconds: 220));
    }
    await tester.pumpAndSettle();

    final front = tester.getRect(_card('Four'));
    final second = tester.getRect(_card('Three'));
    final third = tester.getRect(_card('Two'));
    // Each one back peeks out 10pt above, a step smaller.
    expect(second.top, closeTo(front.top - 10 + front.height * 0.015, 0.5));
    expect(third.top, closeTo(front.top - 20 + front.height * 0.03, 0.5));
    expect(second.width, closeTo(front.width * 0.97, 0.5));
    // The fourth has faded out.
    double opacityOf(String title) => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text(title), matching: find.byType(Opacity))
              .first,
        )
        .opacity;
    expect(opacityOf('Four'), 1);
    expect(opacityOf('Two'), 1);
    expect(opacityOf('One'), 0);

    // A fifth pushes the oldest off the deck.
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    expect(find.text('One'), findsNothing);
    expect(opacityOf('Two'), 0);

    // Dismissing the front one brings the deck forward a step.
    await tester.tap(
      find.descendant(
        of: _card('Five'),
        matching: find.bySemanticsLabel('Dismiss notification'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Five'), findsNothing);
    expect(tester.getRect(_card('Four')).bottom, closeTo(front.bottom, 0.5));
    expect(opacityOf('Two'), 1);

    hideAllPanelToasts(tester.element(find.text('Raise')));
    await tester.pumpAndSettle();
    expect(find.byType(PanelToast), findsNothing);
  });

  testWidgets('hovering the deck spreads it and holds the timers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app((context) {
        for (final title in ['Alpha', 'Beta', 'Gamma']) {
          showPanelToast(context, title: Text(title));
        }
      }),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    final collapsedBeta = tester.getRect(_card('Beta'));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(_card('Gamma')));
    await tester.pumpAndSettle();

    final gamma = tester.getRect(_card('Gamma'));
    final beta = tester.getRect(_card('Beta'));
    final alpha = tester.getRect(_card('Alpha'));
    expect(beta.bottom, closeTo(gamma.top - 10, 0.5));
    expect(alpha.bottom, closeTo(beta.top - 10, 0.5));
    expect(beta.width, gamma.width);
    expect(beta.top, lessThan(collapsedBeta.top));

    // Held open well past their four seconds.
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Gamma'), findsOneWidget);

    await mouse.moveTo(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(tester.getRect(_card('Beta')).top, closeTo(collapsedBeta.top, 0.5));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(PanelToast), findsNothing);
  });

  testWidgets('cards keep their state as the deck spreads and gathers', (
    tester,
  ) async {
    var mounts = 0;
    await tester.pumpWidget(
      _app((context) {
        // The one behind is taller, so it is clipped only while gathered.
        showPanelToast(
          context,
          duration: Duration.zero,
          builder: (context, toast) => _Probe(
            onMount: () => mounts++,
            child: const PanelToast(
              title: Text('Behind'),
              description: Text('A longer note.\nOn two lines.'),
            ),
          ),
        );
        showPanelToast(
          context,
          duration: Duration.zero,
          builder: (context, toast) => _Probe(
            onMount: () => mounts++,
            child: const PanelToast(title: Text('Front')),
          ),
        );
      }),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    expect(mounts, 2);
    final front = tester.getRect(_card('Front'));
    // Gathered, the taller card shows only the front card's height of itself.
    Clip clipOf(String title) => tester
        .widget<ClipRect>(
          find.ancestor(of: find.text(title), matching: find.byType(ClipRect)),
        )
        .clipBehavior;
    expect(clipOf('Behind'), Clip.hardEdge);
    expect(clipOf('Front'), Clip.none);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(front.center);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(_card('Behind')).bottom,
      closeTo(front.top - 10, 0.5),
    );
    expect(clipOf('Behind'), Clip.none);
    await mouse.moveTo(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(mounts, 2);
  });

  testWidgets('the countdown pauses while the app is out of sight', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app((context) => showPanelToast(context, title: const Text('Later'))),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();

    await _setLifecycle(tester, AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Later'), findsOneWidget);

    await _setLifecycle(tester, AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Later'), findsNothing);
  });

  testWidgets('it stays above a dialog opened after it, and takes touches', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app((context) {
        showPanelToast(
          context,
          title: const Text('Still here'),
          duration: Duration.zero,
        );
        showPanelDialog<void>(
          context,
          builder: (context) => const PanelDialog(title: Text('A dialog')),
        );
      }),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    expect(find.text('A dialog'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Dismiss notification'));
    await tester.pumpAndSettle();
    expect(find.text('Still here'), findsNothing);
    expect(find.text('A dialog'), findsOneWidget);
  });

  testWidgets('it is announced as a live region and can be dismissed by a '
      'screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        (context) => showPanelToast(
          context,
          title: const Text('Link copied'),
          duration: Duration.zero,
        ),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(PanelToast)),
      isSemantics(isLiveRegion: true),
    );
    final node = tester.getSemantics(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.onDismiss != null,
      ),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.dismiss), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.dismiss);
    await tester.pumpAndSettle();
    expect(find.text('Link copied'), findsNothing);
    semantics.dispose();
  });

  testWidgets('under reduced motion it fades in where it rests', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          disableAnimations: true,
        ),
        child: _app(
          (context) => showPanelToast(
            context,
            title: const Text('Calm'),
            duration: Duration.zero,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getRect(_card('Calm')).bottom, 600 - 24);
    final fade = tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text('Calm'), matching: find.byType(Opacity))
              .first,
        )
        .opacity;
    expect(fade, greaterThan(0));
    expect(fade, lessThan(1));
    await tester.pumpAndSettle();
  });

  testWidgets('a custom toast is drawn by the caller and managed by the deck', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        (context) => showPanelToast(
          context,
          duration: const Duration(seconds: 6),
          builder: (context, toast) => PanelToast(
            variant: PanelToastVariant.info,
            title: const Text('Custom component'),
            onClose: toast.hide,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    expect(find.text('Custom component'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Dismiss notification'));
    await tester.pumpAndSettle();
    expect(find.text('Custom component'), findsNothing);
  });

  testWidgets('raised in a themed subtree, it takes that theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PanelTheme(
          data: PanelThemeData.moonDark,
          child: Builder(
            builder: (context) => PanelButton(
              onPressed: () => showPanelToast(
                context,
                title: const Text('Dark'),
                duration: Duration.zero,
              ),
              child: const Text('Raise'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Raise'));
    await tester.pumpAndSettle();
    final card = tester.widget<Container>(
      find
          .descendant(of: _card('Dark'), matching: find.byType(Container))
          .first,
    );
    expect(
      (card.decoration! as BoxDecoration).color,
      PanelColors.moonDark.popover,
    );
  });

  testWidgets('the surface builds on its own in every theme', (tester) async {
    for (final theme in allThemes) {
      await tester.pumpWidget(
        wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final variant in PanelToastVariant.values)
                PanelToast(
                  variant: variant,
                  title: Text(variant.name),
                  description: const Text('Details'),
                  action: PanelToastAction(
                    onPressed: () {},
                    child: const Text('Undo'),
                  ),
                  onClose: () {},
                ),
            ],
          ),
          theme: theme,
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
