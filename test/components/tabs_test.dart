import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

Widget _tabs({
  String? value,
  String initialValue = 'account',
  ValueChanged<String>? onChanged,
  PanelTabsVariant variant = PanelTabsVariant.segmented,
  PanelTabsSize size = PanelTabsSize.md,
  bool scrollable = false,
  bool keepMounted = false,
  bool swipeable = false,
  bool animated = true,
  bool teamEnabled = true,
  List<String> extra = const [],
}) {
  return PanelTabs<String>(
    value: value,
    initialValue: initialValue,
    onChanged: onChanged,
    variant: variant,
    size: size,
    keepMounted: keepMounted,
    swipeable: swipeable,
    animated: animated,
    children: [
      PanelTabsList(
        scrollable: scrollable,
        children: [
          const PanelTabsTrigger(
            value: 'account',
            icon: PanelIcon(PanelIcons.lock),
            child: Text('Account'),
          ),
          const PanelTabsTrigger(value: 'password', child: Text('Password')),
          PanelTabsTrigger(
            value: 'team',
            enabled: teamEnabled,
            icon: const PanelIcon(PanelIcons.globe),
            badge: const PanelBadge.count(3),
            child: const Text('Team'),
          ),
          for (final name in extra)
            PanelTabsTrigger(value: name, child: Text(name)),
        ],
      ),
      const PanelTabsContent(value: 'account', child: Text('Account panel')),
      const PanelTabsContent(value: 'password', child: Text('Password panel')),
      const PanelTabsContent(
        value: 'team',
        child: _Counter(label: 'Team'),
      ),
      for (final name in extra)
        PanelTabsContent(value: name, child: Text('$name panel')),
    ],
  );
}

/// A panel with state of its own, to tell a kept panel from a rebuilt one.
class _Counter extends StatefulWidget {
  const _Counter({required this.label});

  final String label;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _count++),
      child: Text('${widget.label} panel $_count'),
    );
  }
}

Rect _indicatorRect(WidgetTester tester) {
  // The indicator is the last rounded rectangle the list's painter draws
  // (after its shadows).
  final box = tester
      .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
      .firstWhere(
        (r) => r.painter.runtimeType.toString() == '_IndicatorPainter',
      );
  final canvas = _RecordingCanvas();
  box.painter!.paint(canvas, box.size);
  return canvas.last!.outerRect;
}

class _RecordingCanvas implements Canvas {
  RRect? last;

  @override
  void drawRRect(RRect rrect, Paint paint) => last = rrect;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Rect _localRect(WidgetTester tester, Finder trigger) {
  final row = tester.renderObject<RenderBox>(
    find.descendant(
      of: find.byType(PanelTabsList),
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_TabsRow',
      ),
    ),
  );
  final box = tester.renderObject<RenderBox>(trigger);
  final topLeft = box.localToGlobal(Offset.zero, ancestor: row);
  return topLeft & box.size;
}

Finder _trigger(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(PanelTabsTrigger<String>),
);

void main() {
  testWidgets('builds every variant and size in every theme', (tester) async {
    for (final theme in allThemes) {
      for (final variant in PanelTabsVariant.values) {
        for (final size in PanelTabsSize.values) {
          await tester.pumpWidget(
            wrap(
              _tabs(variant: variant, size: size),
              theme: theme,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Account panel'), findsOneWidget);
        }
      }
    }
  });

  testWidgets('pressing a trigger reports it and shows its panel', (
    tester,
  ) async {
    String? reported;
    await tester.pumpWidget(wrap(_tabs(onChanged: (v) => reported = v)));
    await tester.pumpAndSettle();
    expect(find.text('Account panel'), findsOneWidget);
    expect(find.text('Password panel'), findsNothing);

    await tester.tap(find.text('Password'));
    await tester.pumpAndSettle();
    expect(reported, 'password');
    expect(find.text('Password panel'), findsOneWidget);
    expect(find.text('Account panel'), findsNothing);
  });

  testWidgets('a controlled tab set shows what it is told', (tester) async {
    final values = <String>[];
    await tester.pumpWidget(
      wrap(_tabs(value: 'password', onChanged: values.add)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Password panel'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(values, ['account']);
    // The parent did not change the value, so the panel stays.
    expect(find.text('Password panel'), findsOneWidget);
  });

  testWidgets('a disabled trigger ignores presses', (tester) async {
    final values = <String>[];
    await tester.pumpWidget(
      wrap(_tabs(teamEnabled: false, onChanged: values.add)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();
    expect(values, isEmpty);
    expect(find.text('Account panel'), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('Team'), matching: find.byType(Opacity))
          .first,
    );
    expect(opacity.opacity, 0.44);
  });

  testWidgets('triggers are announced as tabs with their selection', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(_tabs(teamEnabled: false)));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(_trigger('Account')),
      isSemantics(
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        isEnabled: true,
      ),
    );
    expect(
      tester.getSemantics(_trigger('Password')),
      isSemantics(isSelected: false, hasSelectedState: true),
    );
    expect(
      tester.getSemantics(_trigger('Team')),
      isSemantics(isEnabled: false, hasEnabledState: true),
    );
    for (final label in ['Account', 'Password', 'Team']) {
      expect(
        tester.getSemantics(_trigger(label)).getSemanticsData().role,
        SemanticsRole.tab,
      );
    }
    handle.dispose();
  });

  testWidgets('the indicator springs from one trigger to the next', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(_tabs()));
    await tester.pumpAndSettle();
    final first = _localRect(tester, _trigger('Account'));
    expect(_indicatorRect(tester).left, moreOrLessEquals(first.left));
    expect(_indicatorRect(tester).width, moreOrLessEquals(first.width));

    await tester.tap(find.text('Team'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final team = _localRect(tester, _trigger('Team'));
    final moving = _indicatorRect(tester);
    expect(moving.left, greaterThan(first.left));
    expect(moving.left, lessThan(team.left));

    await tester.pumpAndSettle();
    expect(_indicatorRect(tester).left, moreOrLessEquals(team.left));
    expect(_indicatorRect(tester).width, moreOrLessEquals(team.width));
  });

  testWidgets('with reduced motion the indicator jumps', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: _tabs(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team'));
    await tester.pump();
    final team = _localRect(tester, _trigger('Team'));
    expect(_indicatorRect(tester).left, moreOrLessEquals(team.left));
  });

  testWidgets('a fixed row shares its width equally', (tester) async {
    await tester.pumpWidget(
      wrap(SizedBox(width: 360, child: _tabs(variant: PanelTabsVariant.pill))),
    );
    await tester.pumpAndSettle();
    final widths = [
      for (final label in ['Account', 'Password', 'Team'])
        tester.getSize(_trigger(label)).width,
    ];
    expect(widths[0], moreOrLessEquals(widths[1]));
    expect(widths[1], moreOrLessEquals(widths[2]));
    // Three shares and two 4pt gaps fill the row.
    expect(widths.reduce((a, b) => a + b) + 8, moreOrLessEquals(360));
  });

  testWidgets('a segmented md row is 40pt tall', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PanelTabs<String>(
          initialValue: 'a',
          children: [
            PanelTabsList(
              children: [
                PanelTabsTrigger(value: 'a', child: Text('A')),
                PanelTabsTrigger(value: 'b', child: Text('B')),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PanelTabsList)).height, 40);
  });

  testWidgets('a scrollable row brings the selected tab into view', (
    tester,
  ) async {
    final extra = [for (var i = 0; i < 8; i++) 'Section $i'];
    Widget build(String value) => wrap(
      SizedBox(
        width: 320,
        child: _tabs(
          value: value,
          variant: PanelTabsVariant.underline,
          scrollable: true,
          extra: extra,
        ),
      ),
    );

    await tester.pumpWidget(build('Section 2'));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(PanelTabsList),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.pixels, greaterThan(0));
    final row = tester.getRect(find.byType(PanelTabsList));
    final tab = tester.getRect(_trigger('Section 2'));
    // A little in from the leading edge rather than flush against it.
    expect(tab.left - row.left, moreOrLessEquals(24));

    // A tab near the end can only come as far as the row lets it.
    await tester.pumpWidget(build('Section 7'));
    await tester.pumpAndSettle();
    expect(
      scrollable.position.pixels,
      moreOrLessEquals(scrollable.position.maxScrollExtent),
    );
    expect(row.contains(tester.getRect(_trigger('Section 7')).center), isTrue);

    await tester.pumpWidget(build('account'));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, 0);
  });

  testWidgets('the scroller still travels when the tab set does not move', (
    tester,
  ) async {
    final extra = [for (var i = 0; i < 8; i++) 'Section $i'];
    Widget build(String value) => wrap(
      SizedBox(
        width: 320,
        child: _tabs(
          value: value,
          variant: PanelTabsVariant.underline,
          scrollable: true,
          animated: false,
          extra: extra,
        ),
      ),
    );
    await tester.pumpWidget(build('account'));
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(PanelTabsList),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(position.pixels, 0);

    // `animated: false` stills the indicator, the strip and the reveal, as
    // in PanelUI; bringing the selection into view is still a scroll.
    await tester.pumpWidget(build('Section 7'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(position.pixels, greaterThan(0));
    expect(position.pixels, lessThan(position.maxScrollExtent));
    await tester.pumpAndSettle();
    expect(position.pixels, moreOrLessEquals(position.maxScrollExtent));
  });

  testWidgets('labels are centred in their triggers in every variant', (
    tester,
  ) async {
    for (final variant in [
      PanelTabsVariant.segmented,
      PanelTabsVariant.underline,
      PanelTabsVariant.pill,
    ]) {
      for (final scrollable in [false, true]) {
        await tester.pumpWidget(
          wrap(
            SizedBox(
              width: 360,
              child: _tabs(variant: variant, scrollable: scrollable),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final trigger = tester.getRect(_trigger('Password'));
        final label = tester.getRect(find.text('Password'));
        expect(
          label.center.dx,
          moreOrLessEquals(trigger.center.dx),
          reason: '$variant, scrollable: $scrollable',
        );
        if (scrollable) {
          // PanelUI's `px-4` either side of the label.
          expect(trigger.width, moreOrLessEquals(label.width + 32));
        }
      }
    }
  });

  testWidgets('keepMounted keeps a hidden panel and its state', (tester) async {
    await tester.pumpWidget(wrap(_tabs(keepMounted: true)));
    await tester.pumpAndSettle();
    // Every panel is built from the start; only the selected one shows.
    expect(find.text('Team panel 0', skipOffstage: false), findsOneWidget);
    expect(find.text('Team panel 0'), findsNothing);

    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team panel 0'));
    await tester.pump();
    expect(find.text('Team panel 1'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();
    expect(find.text('Team panel 1'), findsOneWidget);
  });

  testWidgets('without keepMounted a panel starts afresh', (tester) async {
    await tester.pumpWidget(wrap(_tabs()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team panel 0'));
    await tester.pump();
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();
    expect(find.text('Team panel 0'), findsOneWidget);
  });

  testWidgets('a swipe on the panels moves to the next tab', (tester) async {
    final values = <String>[];
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 360,
          height: 400,
          child: _tabs(swipeable: true, onChanged: values.add),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Account panel'), findsOneWidget);

    await tester.fling(find.text('Account panel'), const Offset(-200, 0), 800);
    await tester.pumpAndSettle();
    expect(values, ['password']);
    final viewport = tester.getRect(find.byType(PanelTabs<String>));
    final panel = tester.getRect(find.text('Password panel'));
    expect(viewport.contains(panel.center), isTrue);

    // Pressing a trigger slides the strip there too.
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(
      viewport.contains(tester.getRect(find.text('Account panel')).center),
      isTrue,
    );
  });

  testWidgets('a short drag springs back', (tester) async {
    final values = <String>[];
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 360,
          height: 300,
          child: _tabs(swipeable: true, onChanged: values.add),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.getRect(find.text('Account panel'));
    final gesture = await tester.startGesture(before.center);
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(values, isEmpty);
    expect(tester.getRect(find.text('Account panel')), before);
  });

  testWidgets('an expanding tab opens its label and keeps it announced', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(_tabs(variant: PanelTabsVariant.expanding)));
    await tester.pumpAndSettle();
    final closed = tester.getSize(_trigger('Password')).width;
    final open = tester.getSize(_trigger('Account')).width;
    expect(open, greaterThan(closed));
    expect(
      tester.getSemantics(_trigger('Password')),
      isSemantics(label: 'Password', isSelected: false),
    );

    await tester.tap(_trigger('Password'));
    await tester.pumpAndSettle();
    expect(tester.getSize(_trigger('Password')).width, greaterThan(closed));
    handle.dispose();
  });

  testWidgets('right to left, the row and the swipe run the other way', (
    tester,
  ) async {
    final values = <String>[];
    await tester.pumpWidget(
      wrap(
        Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: 360,
            height: 300,
            child: _tabs(swipeable: true, onChanged: values.add),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final account = tester.getRect(_trigger('Account'));
    final password = tester.getRect(_trigger('Password'));
    expect(account.left, greaterThan(password.left));
    final first = _localRect(tester, _trigger('Account'));
    expect(_indicatorRect(tester).left, moreOrLessEquals(first.left));

    // The next panel is on the left, so it is brought on by dragging right.
    await tester.fling(find.text('Account panel'), const Offset(200, 0), 800);
    await tester.pumpAndSettle();
    expect(values, ['password']);
    final password2 = _localRect(tester, _trigger('Password'));
    expect(_indicatorRect(tester).left, moreOrLessEquals(password2.left));
  });

  testWidgets('without a height the strip is as tall as its tallest panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const SingleChildScrollView(
          child: PanelTabs<String>(
            swipeable: true,
            initialValue: 'short',
            children: [
              PanelTabsList(
                children: [
                  PanelTabsTrigger(value: 'short', child: Text('Short')),
                  PanelTabsTrigger(value: 'tall', child: Text('Tall')),
                ],
              ),
              PanelTabsContent(value: 'short', child: SizedBox(height: 50)),
              PanelTabsContent(value: 'tall', child: SizedBox(height: 200)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final height = tester.getSize(find.byType(PanelTabs<String>)).height;
    // The list (40), the gap (12) and the tallest panel, built a frame after
    // the first as the selected one's neighbour.
    expect(height, 40 + 12 + 200);
    await tester.tap(find.text('Tall'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PanelTabs<String>)).height, height);
  });

  testWidgets('animated: false moves nothing', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PanelTabs<String>(
          animated: false,
          initialValue: 'a',
          children: [
            PanelTabsList(
              children: [
                PanelTabsTrigger(value: 'a', child: Text('A')),
                PanelTabsTrigger(value: 'b', child: Text('B')),
              ],
            ),
            PanelTabsContent(value: 'a', child: Text('Panel A')),
            PanelTabsContent(value: 'b', child: Text('Panel B')),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    await tester.pump();
    final b = _localRect(tester, _trigger('B'));
    expect(_indicatorRect(tester).left, moreOrLessEquals(b.left));
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Panel B'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('a panel fades in when it arrives', (tester) async {
    await tester.pumpWidget(wrap(_tabs()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Password panel'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, greaterThan(0));
    expect(fade.opacity.value, lessThan(1));
  });

  testWidgets('a small trigger takes presses in the track around it', (
    tester,
  ) async {
    for (final (size, reaches) in [
      (PanelTabsSize.xs, true),
      (PanelTabsSize.sm, true),
      (PanelTabsSize.md, false),
    ]) {
      final values = <String>[];
      await tester.pumpWidget(wrap(_tabs(size: size, onChanged: values.add)));
      await tester.pumpAndSettle();
      // 2pt above the trigger, inside the segmented track's 4pt padding.
      final password = tester.getRect(_trigger('Password'));
      await tester.tapAt(Offset(password.center.dx, password.top - 2));
      await tester.pumpAndSettle();
      expect(values, reaches ? ['password'] : isEmpty, reason: '$size');
    }
  });

  testWidgets('a vertical drag on the strip is left to whatever scrolls', (
    tester,
  ) async {
    final values = <String>[];
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 360,
          height: 300,
          child: _tabs(swipeable: true, onChanged: values.add),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.getRect(find.text('Account panel'));

    // Up and down past 8pt before 12pt sideways: the strip lets it go, and
    // the sideways travel that follows does not take it back.
    final gesture = await tester.startGesture(before.center);
    await gesture.moveBy(const Offset(-4, 10));
    await tester.pump();
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();
    expect(tester.getRect(find.text('Account panel')), before);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(values, isEmpty);
    expect(tester.getRect(find.text('Account panel')), before);
  });

  testWidgets('a vertical drag on the strip scrolls the page around it', (
    tester,
  ) async {
    final values = <String>[];
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 360,
          height: 400,
          child: ListView(
            controller: scroll,
            children: [
              SizedBox(
                height: 300,
                child: _tabs(swipeable: true, onChanged: values.add),
              ),
              const SizedBox(height: 600),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // A little sideways, mostly down: the page takes it.
    await tester.drag(find.text('Account panel'), const Offset(-10, -120));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    expect(values, isEmpty);
  });

  testWidgets('a drag follows the finger from where it touched down', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(SizedBox(width: 360, height: 300, child: _tabs(swipeable: true))),
    );
    await tester.pumpAndSettle();
    final before = tester.getRect(find.text('Account panel'));
    final gesture = await tester.startGesture(before.center);
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    // Past the 12pt threshold, the strip has caught up with the finger.
    expect(
      tester.getRect(find.text('Account panel')).left,
      moreOrLessEquals(before.left - 20),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('an icon keeps the muted colour, selected or not', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(_tabs()));
    await tester.pumpAndSettle();
    final muted = PanelThemeData.panelLight.colors.mutedForeground;
    for (final icon in [PanelIcons.lock, PanelIcons.globe]) {
      final context = tester.element(
        find.byWidgetPredicate((w) => w is PanelIcon && w.icon == icon),
      );
      expect(IconTheme.of(context).color, muted);
    }
  });

  testWidgets('a mouse over an underline tab lights a plate behind it', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(width: 360, child: _tabs(variant: PanelTabsVariant.underline)),
      ),
    );
    await tester.pumpAndSettle();
    Color? plate() =>
        (tester
                    .widget<AnimatedContainer>(
                      find.descendant(
                        of: _trigger('Password'),
                        matching: find.byType(AnimatedContainer),
                      ),
                    )
                    .decoration!
                as BoxDecoration)
            .color;
    expect(plate()!.a, 0);

    // Hover shows where highlights do: with a mouse, not after a touch.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(_trigger('Password')));
    await tester.pumpAndSettle();
    final muted = PanelThemeData.panelLight.colors.muted;
    expect(plate()!.a, moreOrLessEquals(muted.a * 0.7));
    // The label lifts to the foreground too.
    expect(
      tester
          .widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text('Password'),
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          )
          .style
          .color,
      PanelThemeData.panelLight.colors.foreground,
    );
  });

  testWidgets('parts outside a PanelTabs say so', (tester) async {
    await tester.pumpWidget(
      wrap(const PanelTabsTrigger(value: 'a', child: Text('A'))),
    );
    expect(tester.takeException(), isA<FlutterError>());
  });
}
