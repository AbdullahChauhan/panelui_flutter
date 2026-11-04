import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

const _fruit = <PanelSelectEntry<String>>[
  PanelSelectOption(value: 'apple', label: 'Apple'),
  PanelSelectOption(value: 'banana', label: 'Banana'),
  PanelSelectOption(value: 'cherry', label: 'Cherry'),
  PanelSelectOption(value: 'mango', label: 'Mango', enabled: false),
];

const _cities = <String>[
  'UTC',
  'London',
  'Paris',
  'Berlin',
  'Madrid',
  'Istanbul',
  'Cairo',
  'Lagos',
  'Nairobi',
  'Dubai',
  'Karachi',
  'Kolkata',
  'Singapore',
  'Tokyo',
  'Sydney',
  'São Paulo',
  'New York',
  'Chicago',
  'Denver',
  'Los Angeles',
];

const _zones = <PanelSelectEntry<String>>[
  PanelSelectGroup(
    label: 'Europe',
    options: [
      PanelSelectOption(value: 'london', label: 'London'),
      PanelSelectOption(value: 'paris', label: 'Paris'),
    ],
  ),
  PanelSelectGroup(
    label: 'Americas',
    options: [PanelSelectOption(value: 'la', label: 'Los Angeles')],
  ),
  PanelSelectGroup(
    label: 'Asia',
    options: [PanelSelectOption(value: 'tokyo', label: 'Tokyo')],
  ),
];

/// A select whose value lives in a [StatefulBuilder], reporting each change
/// to [changes]. It floats its list unless told otherwise, since that is the
/// presentation most of these tests are about.
Widget _select({
  String? initial,
  List<PanelSelectEntry<String>> options = _fruit,
  List<String>? changes,
  List<bool>? openChanges,
  bool enabled = true,
  String? label = 'Fruit',
  String? errorMessage,
  PanelSelectSize size = PanelSelectSize.md,
  PanelInputVariant variant = PanelInputVariant.outline,
  PanelSelectPresentation presentation = PanelSelectPresentation.overlay,
  String? title,
  bool searchable = false,
  bool menuFitsContent = false,
}) {
  var value = initial;
  return SizedBox(
    width: 320,
    child: StatefulBuilder(
      builder: (context, setState) => PanelSelect<String>(
        key: const Key('select'),
        label: label,
        placeholder: 'Select a fruit',
        value: value,
        size: size,
        variant: variant,
        presentation: presentation,
        title: title,
        searchable: searchable,
        menuFitsContent: menuFitsContent,
        errorMessage: errorMessage,
        options: options,
        onOpenChange: openChanges?.add,
        onChanged: enabled
            ? (next) {
                changes?.add(next);
                setState(() => value = next);
              }
            : null,
      ),
    ),
  );
}

/// The trigger. The open list's options are built under the select too, so
/// they come after it.
Finder get _trigger => find
    .descendant(
      of: find.byKey(const Key('select')),
      matching: find.byType(PanelPressable),
    )
    .first;

/// The field's bordered box, which the list is anchored to.
Finder get _box => find
    .ancestor(
      of: _trigger,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container && (w.decoration as BoxDecoration?)?.border != null,
      ),
    )
    .first;

/// The colour the field's border is drawn in.
Color _borderColor(WidgetTester tester) =>
    ((tester.widget<Container>(_box).decoration! as BoxDecoration).border!
            as Border)
        .top
        .color;

/// The list's surface, found from one of its options.
Rect _listRect(WidgetTester tester, String option) => tester.getRect(
  find
      .ancestor(
        of: find.text(option).last,
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.padding == const EdgeInsets.all(8),
        ),
      )
      .first,
);

/// Whether the option labelled [label] has keyboard focus.
bool _focused(WidgetTester tester, String label) =>
    tester
        .getSemantics(find.text(label).last)
        .getSemanticsData()
        .flagsCollection
        .isFocused ==
    Tristate.isTrue;

void main() {
  testWidgets('shows the placeholder, then the chosen label', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(wrap(_select(changes: changes)));
    expect(find.text('Select a fruit'), findsOneWidget);
    expect(find.text('Fruit'), findsOneWidget);

    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsOneWidget);

    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    expect(changes, ['banana']);
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('Cherry'), findsNothing);
    expect(find.text('Select a fruit'), findsNothing);
  });

  testWidgets('floats below the field as wide as it, a tick on the value', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(_select(initial: 'cherry')));
    await tester.tap(_trigger);
    await tester.pumpAndSettle();

    final box = tester.getRect(_box);
    final list = _listRect(tester, 'Apple');
    expect(list.top, moreOrLessEquals(box.bottom + 8, epsilon: 0.01));
    expect(list.width, moreOrLessEquals(box.width, epsilon: 0.01));
    expect(list.left, moreOrLessEquals(box.left, epsilon: 0.01));

    // The tick is on the chosen option only.
    final checks = find.byWidgetPredicate(
      (w) => w is PanelIcon && w.icon == PanelIcons.check,
    );
    expect(checks, findsOneWidget);
    final cherryRow = tester.getRect(find.text('Cherry').last);
    expect(
      tester.getCenter(checks).dy,
      moreOrLessEquals(cherryRow.center.dy, epsilon: 1),
    );
    expect(
      tester
          .getSemantics(find.text('Cherry').last)
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('a disabled option is shown but cannot be chosen', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(wrap(_select(changes: changes)));
    await tester.tap(_trigger);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mango'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(find.text('Mango'), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('Mango'), matching: find.byType(Opacity))
          .first,
    );
    expect(opacity.opacity, 0.64);
  });

  testWidgets('a select without onChanged does not open', (tester) async {
    await tester.pumpWidget(wrap(_select(enabled: false)));
    await tester.tap(_trigger, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsNothing);
  });

  testWidgets('a tap outside and Escape close the list', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(wrap(_select(changes: changes)));
    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    // The layer behind the list takes taps but, as in PanelUI, is kept out
    // of a screen reader's way.
    expect(find.bySemanticsLabel('Close'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsNothing);

    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsNothing);
    expect(changes, isEmpty);
  });

  testWidgets('works from the keyboard', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(wrap(_select(initial: 'apple', changes: changes)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    // The chosen option takes focus.
    expect(find.text('Cherry'), findsOneWidget);
    expect(_focused(tester, 'Apple'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_focused(tester, 'Banana'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_focused(tester, 'Cherry'), isTrue);
    // Mango is disabled, so the next stop is back at the top.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_focused(tester, 'Apple'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_focused(tester, 'Cherry'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(changes, ['cherry']);
    expect(find.text('Banana'), findsNothing);
    // Focus is back on the trigger.
    expect(
      tester
          .getSemantics(_trigger)
          .getSemanticsData()
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
  });

  testWidgets('opened by a pointer, no option is focused', (tester) async {
    await tester.pumpWidget(wrap(_select(initial: 'banana')));
    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    expect(_focused(tester, 'Banana'), isFalse);
    // The arrows still start from the top.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_focused(tester, 'Apple'), isTrue);
  });

  testWidgets('typing jumps to an option by its first letters', (tester) async {
    await tester.pumpWidget(
      wrap(
        _select(
          options: [
            for (final city in _cities)
              PanelSelectOption(value: city, label: city),
          ],
        ),
      ),
    );
    await tester.tap(_trigger);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.pump();
    expect(_focused(tester, 'London'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    expect(_focused(tester, 'Lagos'), isTrue);

    // After a pause the prefix starts again; repeating a letter cycles.
    await tester.pump(const Duration(seconds: 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pump();
    expect(_focused(tester, 'Singapore'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pump();
    expect(_focused(tester, 'Sydney'), isTrue);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a long list scrolls inside the room below', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final changes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: PanelThemeData.panelLight.toMaterialTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: _select(
                changes: changes,
                options: [
                  for (final city in _cities)
                    PanelSelectOption(value: city, label: city),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    final box = tester.getRect(_box);
    final list = _listRect(tester, 'UTC');
    expect(list.top, greaterThan(box.bottom));
    expect(list.bottom, lessThanOrEqualTo(600));
    expect(find.text('Los Angeles'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Los Angeles'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Los Angeles'));
    await tester.pumpAndSettle();
    expect(changes, ['Los Angeles']);
  });

  testWidgets('flips above the field near the bottom edge', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PanelThemeData.panelLight.toMaterialTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _select(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    final box = tester.getRect(_box);
    final list = _listRect(tester, 'Apple');
    expect(list.bottom, moreOrLessEquals(box.top - 8, epsilon: 0.01));
  });

  testWidgets('sized to its content, the list is as wide as its longest '
      'option and never narrower than the field', (tester) async {
    await tester.pumpWidget(
      wrap(
        _select(
          menuFitsContent: true,
          options: const [
            PanelSelectOption(value: 'a', label: 'A'),
            // The test font draws every glyph 16pt wide: this runs past
            // the 320pt field without running off the 800pt screen.
            PanelSelectOption(value: 'b', label: 'A label past the field'),
          ],
        ),
      ),
    );
    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    final box = tester.getRect(_box);
    final list = _listRect(tester, 'A');
    expect(list.width, greaterThan(box.width));
    expect(list.left, moreOrLessEquals(box.left, epsilon: 0.01));

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(wrap(_select(menuFitsContent: true)));
    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    expect(
      _listRect(tester, 'Apple').width,
      moreOrLessEquals(tester.getRect(_box).width, epsilon: 0.01),
    );
  });

  testWidgets('groups, separators and an error', (tester) async {
    await tester.pumpWidget(
      wrap(
        _select(
          errorMessage: 'Pick a time zone',
          options: const [
            PanelSelectGroup(
              label: 'Europe',
              options: [
                PanelSelectOption(value: 'london', label: 'London'),
                PanelSelectOption(value: 'paris', label: 'Paris'),
              ],
            ),
            PanelSelectSeparator(),
            PanelSelectGroup(
              label: 'Asia',
              options: [PanelSelectOption(value: 'tokyo', label: 'Tokyo')],
            ),
          ],
        ),
      ),
    );
    expect(find.text('Pick a time zone'), findsOneWidget);
    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    expect(find.text('EUROPE'), findsOneWidget);
    expect(find.text('ASIA'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.text('EUROPE'))
          .getSemanticsData()
          .flagsCollection
          .isHeader,
      isTrue,
    );
    await tester.tap(find.text('Tokyo'));
    await tester.pumpAndSettle();
    expect(find.text('Tokyo'), findsOneWidget);
  });

  testWidgets('a search filters on any part of a label, drops emptied '
      'groups and says when nothing matches', (tester) async {
    await tester.pumpWidget(wrap(_select(options: _zones, searchable: true)));
    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    // The filter is not focused on open.
    expect(find.text('Search'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );

    await tester.enterText(find.byType(EditableText), 'lo');
    await tester.pump();
    expect(find.text('London'), findsOneWidget);
    expect(find.text('Los Angeles'), findsOneWidget);
    expect(find.text('Paris'), findsNothing);
    expect(find.text('ASIA'), findsNothing);
    expect(find.text('EUROPE'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'zz');
    await tester.pump();
    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('London'), findsNothing);

    // Closed and opened again, the list is whole.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('No matches'), findsNothing);
  });

  testWidgets('a sheet is the default, with a title', (tester) async {
    final changes = <String>[];
    final openChanges = <bool>[];
    await tester.pumpWidget(
      wrap(
        _select(
          presentation: PanelSelectPresentation.sheet,
          title: 'Choose a fruit',
          changes: changes,
          openChanges: openChanges,
        ),
      ),
    );
    expect(
      tester
          .widget<PanelSelect<String>>(find.byKey(const Key('select')))
          .presentation,
      PanelSelectPresentation.sheet,
    );
    expect(
      const PanelSelect<String>(
        options: [],
        value: null,
        onChanged: null,
      ).presentation,
      PanelSelectPresentation.sheet,
    );

    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    expect(find.text('Choose a fruit'), findsOneWidget);
    expect(find.byType(PanelBottomSheetBody), findsOneWidget);

    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    expect(changes, ['banana']);
    expect(find.text('Choose a fruit'), findsNothing);
    expect(openChanges, [true, false]);

    // A tap on the scrim closes the sheet and the select with it.
    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Choose a fruit'), findsNothing);
    expect(openChanges, [true, false, true, false]);
    expect(
      tester
          .getSemantics(_trigger)
          .getSemanticsData()
          .flagsCollection
          .isExpanded,
      Tristate.isFalse,
    );
  });

  testWidgets('inline, the list takes room below and gives it back', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _select(
              presentation: PanelSelectPresentation.inline,
              changes: changes,
            ),
            const Text('Below'),
          ],
        ),
      ),
    );
    // How far below the field the next thing in the layout starts.
    double gap() =>
        tester.getRect(find.text('Below')).top - tester.getRect(_box).bottom;
    expect(gap(), 0);

    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    final list = _listRect(tester, 'Apple');
    expect(list.top, moreOrLessEquals(tester.getRect(_box).bottom + 8));
    expect(gap(), moreOrLessEquals(list.height + 8));

    await tester.tap(find.text('Cherry'));
    await tester.pump();
    // The layout closes up at once; the list fades out over what moved.
    expect(gap(), 0);
    expect(find.text('Apple'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsNothing);
    expect(changes, ['cherry']);
  });

  testWidgets('the field is as tall as PanelUI makes each size', (
    tester,
  ) async {
    const heights = {
      PanelSelectSize.xs: 30.0,
      PanelSelectSize.sm: 42.0,
      PanelSelectSize.md: 54.0,
      PanelSelectSize.lg: 62.0,
      PanelSelectSize.xl: 70.0,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      for (final variant in PanelInputVariant.values) {
        await tester.pumpWidget(
          wrap(_select(size: size, variant: variant, initial: 'apple')),
        );
        expect(tester.getRect(_box).height, height);
      }
    }
  });

  testWidgets('an xs field takes a press just above or below it', (
    tester,
  ) async {
    // As in React Native, a press outside a parent never reaches its
    // children, so the field is given room around it.
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 320,
          height: 60,
          child: Center(
            child: PanelSelect<String>(
              key: const Key('select'),
              size: PanelSelectSize.xs,
              presentation: PanelSelectPresentation.overlay,
              value: null,
              onChanged: (_) {},
              options: _fruit,
            ),
          ),
        ),
      ),
    );
    final box = tester.getRect(_box);
    await tester.tapAt(Offset(box.center.dx, box.top - 5));
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsOneWidget);
  });

  testWidgets('the border takes the ring colour only while the list shows', (
    tester,
  ) async {
    final colors = PanelThemeData.panelLight.colors;
    await tester.pumpWidget(wrap(_select()));
    expect(_borderColor(tester), colors.input);

    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    expect(_borderColor(tester), colors.ring);

    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    expect(_borderColor(tester), colors.input);
  });

  testWidgets('announces its name, value and open state', (tester) async {
    await tester.pumpWidget(wrap(_select(initial: 'banana')));
    var data = tester.getSemantics(_trigger).getSemanticsData();
    expect(data.label, 'Fruit');
    expect(data.value, 'Banana');
    expect(data.flagsCollection.isExpanded, Tristate.isFalse);

    await tester.tap(_trigger);
    await tester.pumpAndSettle();
    data = tester.getSemantics(_trigger).getSemanticsData();
    expect(data.flagsCollection.isExpanded, Tristate.isTrue);
  });

  for (final theme in allThemes) {
    testWidgets('builds open in every theme '
        '(${theme.brightness.name}, radius ${theme.radii.lg})', (tester) async {
      for (final presentation in PanelSelectPresentation.values) {
        await tester.pumpWidget(
          wrap(
            _select(
              initial: 'banana',
              errorMessage: 'Required',
              presentation: presentation,
              searchable: true,
            ),
            theme: theme,
          ),
        );
        await tester.tap(_trigger);
        await tester.pumpAndSettle();
        expect(find.text('Cherry'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    });
  }
}
