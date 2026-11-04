import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

const _light = PanelColors.panelLight;

/// The box decorations painted under [of] that match [test].
Iterable<BoxDecoration> _decorations(
  WidgetTester tester,
  Finder of,
  bool Function(BoxDecoration decoration) test,
) => tester
    .widgetList<DecoratedBox>(
      find.descendant(of: of, matching: find.byType(DecoratedBox)),
    )
    .map((box) => box.decoration)
    .whereType<BoxDecoration>()
    .where(test);

/// Whether a focus ring in [color] is drawn under [of].
bool _hasRing(WidgetTester tester, Finder of, Color color) => _decorations(
  tester,
  of,
  (d) => d.border is Border && (d.border! as Border).top.color == color,
).any((d) => (d.border! as Border).top.width == 2);

/// Hover and keyboard focus are drawn only in the traditional highlight
/// mode, the one a desktop or a browser starts in.
void _useTraditionalHighlights() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

Future<void> _hover(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(target));
  await tester.pump();
}

void main() {
  group('PanelSwitch', () {
    Widget host({TextDirection direction = TextDirection.ltr}) {
      var value = false;
      return wrap(
        Directionality(
          textDirection: direction,
          child: StatefulBuilder(
            builder: (context, setState) => PanelSwitch(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
    }

    Rect thumb(WidgetTester tester) => tester.getRect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
      ),
    );

    testWidgets('reports the flipped value', (tester) async {
      bool? received;
      await tester.pumpWidget(
        wrap(PanelSwitch(value: false, onChanged: (v) => received = v)),
      );
      await tester.tap(find.byType(PanelSwitch));
      expect(received, isTrue);
    });

    testWidgets('springs the thumb across', (tester) async {
      await tester.pumpWidget(host());
      final track = tester.getRect(find.byType(PanelSwitch));
      // 3pt of padding inside a 1pt border.
      expect(thumb(tester).topLeft, track.topLeft + const Offset(4, 4));
      await tester.tap(find.byType(PanelSwitch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        thumb(tester).left,
        inExclusiveRange(track.left + 4, track.left + 24),
      );
      await tester.pumpAndSettle();
      // md: 48 - 20 - 8 of travel.
      expect(thumb(tester).left, closeTo(track.left + 24, 0.01));
    });

    testWidgets('runs the other way in a right-to-left row', (tester) async {
      await tester.pumpWidget(host(direction: TextDirection.rtl));
      final track = tester.getRect(find.byType(PanelSwitch));
      expect(thumb(tester).right, track.right - 4);
      await tester.tap(find.byType(PanelSwitch));
      await tester.pumpAndSettle();
      expect(thumb(tester).left, closeTo(track.left + 4, 0.01));
    });

    testWidgets('the fill sits inside the track and fades in', (tester) async {
      await tester.pumpWidget(host());
      final fill = find.descendant(
        of: find.byType(PanelSwitch),
        matching: find.byType(FadeTransition),
      );
      expect(tester.widget<FadeTransition>(fill).opacity.value, 0);
      // Inside the transparent 1pt border, so the track colour rings it.
      expect(
        tester.getRect(fill),
        tester.getRect(find.byType(PanelSwitch)).deflate(1),
      );
      await tester.tap(find.byType(PanelSwitch));
      await tester.pumpAndSettle();
      expect(tester.widget<FadeTransition>(fill).opacity.value, 1);
    });

    testWidgets('flips at once with reduced motion', (tester) async {
      var value = false;
      await tester.pumpWidget(
        wrap(
          reduceMotion: true,
          StatefulBuilder(
            builder: (context, setState) => PanelSwitch(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PanelSwitch));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(
        thumb(tester).left,
        tester.getRect(find.byType(PanelSwitch)).left + 24,
      );
    });

    testWidgets('announces as a toggle, and disables without onChanged', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const PanelSwitch(
            value: true,
            onChanged: null,
            semanticLabel: 'Wi-Fi',
            semanticHint: 'Joins known networks',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Wi-Fi')),
        isSemantics(
          label: 'Wi-Fi',
          hint: 'Joins known networks',
          isToggled: true,
          isEnabled: false,
        ),
      );
    });

    testWidgets('a pointer over it darkens the track', (tester) async {
      _useTraditionalHighlights();
      await tester.pumpWidget(
        wrap(PanelSwitch(value: false, onChanged: (_) {})),
      );
      bool trackIs(Color color) => _decorations(
        tester,
        find.byType(PanelSwitch),
        (d) => d.color == color,
      ).isNotEmpty;
      expect(trackIs(_light.input), isTrue);
      await _hover(tester, find.byType(PanelSwitch));
      expect(
        trackIs(Color.lerp(_light.input, _light.foreground, 0.08)!),
        isTrue,
      );
    });

    testWidgets('keyboard focus draws a ring clear of the track', (
      tester,
    ) async {
      _useTraditionalHighlights();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        wrap(PanelSwitch(value: false, focusNode: focus, onChanged: (_) {})),
      );
      expect(_hasRing(tester, find.byType(PanelSwitch), _light.ring), isFalse);
      focus.requestFocus();
      await tester.pump();
      expect(_hasRing(tester, find.byType(PanelSwitch), _light.ring), isTrue);
    });
  });

  group('PanelCheckbox', () {
    Finder fill() => find.descendant(
      of: find.byType(PanelCheckbox),
      matching: find.byType(FadeTransition),
    );

    testWidgets('toggles from the box and from the label', (tester) async {
      final values = <bool>[];
      await tester.pumpWidget(
        wrap(
          PanelCheckbox(value: false, label: 'Accept', onChanged: values.add),
        ),
      );
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(values, [true]);
    });

    testWidgets('reads its label once', (tester) async {
      await tester.pumpWidget(
        wrap(
          PanelCheckbox(
            value: true,
            label: 'Accept terms',
            description: 'Required to continue.',
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PanelCheckbox)),
        isSemantics(
          label: 'Accept terms',
          hint: 'Required to continue.',
          isChecked: true,
        ),
      );
    });

    testWidgets('an indeterminate box resolves to true', (tester) async {
      bool? received;
      await tester.pumpWidget(
        wrap(
          PanelCheckbox(
            value: false,
            indeterminate: true,
            label: 'All',
            onChanged: (v) => received = v,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PanelCheckbox)),
        isSemantics(isCheckStateMixed: true),
      );
      await tester.tap(find.text('All'));
      expect(received, isTrue);
    });

    testWidgets('the fill springs in inside the border', (tester) async {
      var value = false;
      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) => PanelCheckbox(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      expect(tester.widget<FadeTransition>(fill()).opacity.value, 0);
      await tester.tap(find.byType(PanelCheckbox));
      await tester.pumpAndSettle();
      expect(tester.widget<FadeTransition>(fill()).opacity.value, 1);
      // A 20pt box with a 1pt border keeps its edge around an 18pt fill.
      expect(tester.getSize(fill()), const Size(18, 18));
    });

    testWidgets('labels keep their size step and its line height', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              for (final size in PanelCheckboxSize.values)
                PanelCheckbox(
                  value: true,
                  size: size,
                  label: size.name,
                  onChanged: (_) {},
                ),
            ],
          ),
        ),
      );
      double? lineHeight(String text) {
        final style = tester.widget<Text>(find.text(text)).style!;
        return style.height == null ? null : style.height! * style.fontSize!;
      }

      expect(lineHeight('xs'), 16);
      // `text-[13px]`: the font's own line height.
      expect(lineHeight('sm'), isNull);
      expect(lineHeight('md'), 20);
      expect(lineHeight('lg'), 24);
      expect(lineHeight('xl'), 28);
    });

    testWidgets('with a description the box lines up with the label', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PanelCheckbox(
            value: true,
            size: PanelCheckboxSize.xs,
            label: 'Updates',
            description: 'At most weekly.',
            onChanged: (_) {},
          ),
        ),
      );
      final row = tester.getRect(find.byType(PanelCheckbox));
      expect(tester.getRect(find.text('Updates')).top, row.top);
      expect(tester.getRect(fill()).top, row.top + 1);
    });

    testWidgets('a checked card takes the accent and the primary edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PanelCheckbox(
            variant: PanelCheckboxVariant.card,
            value: true,
            label: 'Pro',
            onChanged: (_) {},
          ),
        ),
      );
      final card = _decorations(
        tester,
        find.byType(PanelCheckbox),
        (d) => d.color == _light.accent,
      ).single;
      expect((card.border! as Border).top.color, _light.primary);
    });

    testWidgets('a pointer over it darkens the box edge', (tester) async {
      _useTraditionalHighlights();
      await tester.pumpWidget(
        wrap(PanelCheckbox(value: false, label: 'A', onChanged: (_) {})),
      );
      bool edgeIs(Color color) => _decorations(
        tester,
        find.byType(PanelCheckbox),
        (d) => d.border is Border && (d.border! as Border).top.color == color,
      ).isNotEmpty;
      expect(edgeIs(_light.input), isTrue);
      await _hover(tester, find.byType(PanelCheckbox));
      expect(
        edgeIs(Color.lerp(_light.input, _light.foreground, 0.25)!),
        isTrue,
      );
    });

    testWidgets('builds both variants in every theme', (tester) async {
      for (final theme in allThemes) {
        await tester.pumpWidget(
          wrap(
            theme: theme,
            Column(
              children: [
                for (final size in PanelCheckboxSize.values)
                  PanelCheckbox(
                    value: true,
                    size: size,
                    label: 'Label',
                    description: 'Description',
                    onChanged: (_) {},
                  ),
                PanelCheckbox(
                  variant: PanelCheckboxVariant.card,
                  value: true,
                  label: 'Pro',
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('PanelInput', () {
    Finder box() => find
        .descendant(
          of: find.byType(PanelFieldFrame),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                (w.decoration as BoxDecoration?)?.border != null,
          ),
        )
        .first;

    Color border(WidgetTester tester) =>
        ((tester.widget<Container>(box()).decoration! as BoxDecoration).border!
                as Border)
            .top
            .color;

    testWidgets('reports edits and shows its label', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        wrap(
          PanelInput(
            label: 'Email',
            placeholder: 'you@example.com',
            onChanged: values.add,
          ),
        ),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('you@example.com'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'a@b.co');
      expect(values.last, 'a@b.co');
    });

    testWidgets('an error replaces the description', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PanelInput(
            label: 'Username',
            description: 'Pick something memorable.',
            errorMessage: 'That username is taken.',
          ),
        ),
      );
      expect(find.text('That username is taken.'), findsOneWidget);
      expect(find.text('Pick something memorable.'), findsNothing);
      expect(border(tester), _light.destructive);
    });

    testWidgets('the border crosses to the ring colour over 150ms', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const PanelInput(label: 'Name')));
      expect(border(tester), _light.input);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(border(tester), isNot(anyOf(_light.input, _light.ring)));
      await tester.pump(const Duration(milliseconds: 75));
      expect(border(tester), _light.ring);
    });

    testWidgets('with a pointer or keys, focus also rings the box', (
      tester,
    ) async {
      BoxDecoration? ring() =>
          tester.widget<Container>(box()).foregroundDecoration
              as BoxDecoration?;
      await tester.pumpWidget(wrap(const PanelInput(label: 'Name')));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      // Touch keeps PanelUI's border alone.
      expect(ring(), isNull);

      _useTraditionalHighlights();
      await tester.pumpWidget(wrap(const PanelInput(label: 'Name')));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final side = (ring()!.border! as Border).top;
      expect(side.width, 3);
      expect(side.color, _light.ring.withValues(alpha: 0.3));
    });

    testWidgets('a press anywhere in the box puts the caret in it', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        wrap(
          PanelInput(
            focusNode: focus,
            leading: const PanelIcon(PanelIcons.search),
          ),
        ),
      );
      final field = tester.getRect(box());
      // Above the line of text, and in the padding around the icon.
      for (final point in [
        Offset(field.center.dx, field.top + 3),
        Offset(field.left + 6, field.center.dy),
      ]) {
        await tester.tapAt(point);
        await tester.pump();
        expect(focus.hasFocus, isTrue, reason: '$point');
        focus.unfocus();
        await tester.pump();
      }
    });

    testWidgets('content keeps its own presses unless it is decoration', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var cleared = 0;
      Widget input({required bool interactive}) => wrap(
        PanelInput(
          focusNode: focus,
          interactiveContent: interactive,
          leading: const PanelIcon(PanelIcons.search),
          trailing: PanelPressable(
            onPressed: () => cleared++,
            child: const PanelIcon(PanelIcons.x, semanticLabel: 'Clear'),
          ),
        ),
      );

      await tester.pumpWidget(input(interactive: true));
      await tester.tap(find.byType(PanelPressable));
      await tester.pump();
      expect((cleared, focus.hasFocus), (1, false));
      await tester.tap(find.byType(PanelIcon).first);
      await tester.pump();
      expect(focus.hasFocus, isFalse);

      await tester.pumpWidget(input(interactive: false));
      await tester.tap(find.byType(PanelPressable));
      await tester.pump();
      expect((cleared, focus.hasFocus), (1, true));
      expect(find.bySemanticsLabel('Clear'), findsNothing);
    });

    testWidgets('content sits at the edge and the text clears it', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const PanelInput(
            placeholder: 'Search',
            leading: PanelIcon(PanelIcons.search),
          ),
        ),
      );
      final field = tester.getRect(box());
      final icon = tester.getRect(find.byType(PanelIcon));
      // md: 14pt from the outer edge, as the text would have started.
      expect(icon.left - field.left, 14);
      expect(icon.size, const Size.square(16));
      // The border, then the content's whole width.
      expect(
        tester.getRect(find.text('Search')).left - field.left,
        1 + 14 + 16 + 14,
      );
      expect(icon.center.dy, field.center.dy);
    });

    testWidgets('names the field by its label, with its states', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const PanelInput(
            label: 'Email',
            isRequired: true,
            errorMessage: 'Required.',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(
          label: 'Email',
          isTextField: true,
          isRequired: true,
          validationResult: SemanticsValidationResult.invalid,
        ),
      );
    });

    testWidgets('a multiline field starts 96pt tall and grows', (tester) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 300,
            child: PanelInput(
              multiline: true,
              leading: PanelIcon(PanelIcons.pencil),
            ),
          ),
        ),
      );
      expect(tester.getSize(box()).height, 96);
      // The content follows the text to the top.
      expect(
        tester.getRect(find.byType(PanelIcon)).top - tester.getRect(box()).top,
        12,
      );
      await tester.enterText(
        find.byType(TextField),
        List.filled(5, 'line').join('\n'),
      );
      await tester.pump();
      // Five 24pt lines, 12pt above and below, and the border.
      expect(tester.getSize(box()).height, 5 * 24 + 24 + 2);
    });
  });

  group('PanelTextarea', () {
    double height(WidgetTester tester) => tester
        .getSize(
          find
              .descendant(
                of: find.byType(PanelFieldFrame),
                matching: find.byType(Container),
              )
              .first,
        )
        .height;

    testWidgets('is as tall as its rows and their padding', (tester) async {
      await tester.pumpWidget(wrap(const PanelTextarea()));
      // md: four 22pt rows and 12pt above and below.
      expect(height(tester), 4 * 22 + 24);
      await tester.pumpWidget(
        wrap(const PanelTextarea(size: PanelInputSize.xs, rows: 2)),
      );
      expect(height(tester), 2 * 18 + 16);
      await tester.pumpWidget(
        wrap(const PanelTextarea(size: PanelInputSize.xl, rows: 3)),
      );
      expect(height(tester), 3 * 26 + 32);
    });

    testWidgets('grows to maxRows, never below rows', (tester) async {
      await tester.pumpWidget(
        wrap(const PanelTextarea(rows: 6, maxRows: 2, autoGrow: true)),
      );
      expect(height(tester), 6 * 22 + 24);
      await tester.pumpWidget(
        wrap(const PanelTextarea(rows: 2, maxRows: 3, autoGrow: true)),
      );
      await tester.enterText(
        find.byType(TextField),
        List.filled(6, 'line').join('\n'),
      );
      await tester.pump();
      expect(height(tester), 3 * 22 + 24);
    });

    testWidgets('counts characters against its limit', (tester) async {
      await tester.pumpWidget(
        wrap(const PanelTextarea(showCount: true, maxLength: 10)),
      );
      expect(find.text('0/10'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();
      expect(find.text('5/10'), findsOneWidget);
      // With no limit there is nothing to count towards.
      await tester.pumpWidget(wrap(const PanelTextarea(showCount: true)));
      expect(find.textContaining('/'), findsNothing);
    });

    testWidgets('a read-only textarea is drawn disabled', (tester) async {
      await tester.pumpWidget(
        wrap(const PanelTextarea(label: 'Bio', readOnly: true)),
      );
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.64);
    });
  });
}
