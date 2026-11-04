import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter_example/demos/registry.dart';
import 'package:panelui_flutter_example/main.dart';

void main() {
  // Measure text in the gallery's real face. The test default draws every
  // glyph as a full square, far wider than any text the gallery shows.
  setUpAll(() async {
    final inter = FontLoader('Inter');
    for (final weight in [400, 500, 600, 700]) {
      inter.addFont(rootBundle.load('fonts/Inter-$weight.ttf'));
    }
    await inter.load();
  });

  test('every demo is on a page, and only one', () {
    final placed = [
      for (final category in galleryCategories)
        for (final page in category.pages) ...page.demoIds,
    ];
    expect(placed.toSet(), galleryDemos.keys.toSet());
    expect(placed.length, placed.toSet().length);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('every page builds in ${mode.name} mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GalleryApp(initialMode: mode));
      await tester.pump(const Duration(milliseconds: 500));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      for (final id in galleryPages.keys) {
        navigator.pushReplacementNamed('/$id');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: id);
      }
    });
  }

  testWidgets('the sidebar keeps its place when a page opens', (tester) async {
    tester.view.physicalSize = const Size(1280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GalleryApp(initialMode: ThemeMode.light));
    await tester.pump(const Duration(milliseconds: 500));
    // A page near the end of the list, scrolled up into view. The sidebar
    // comes before the page in the tree, so its entry is the first match.
    final entry = find.text(galleryCategories.last.pages.last.title).first;
    final unscrolled = tester.getTopLeft(entry);
    await tester.ensureVisible(entry);
    await tester.pump();
    final scrolled = tester.getTopLeft(entry);
    expect(scrolled.dy, lessThan(unscrolled.dy));
    await tester.tap(entry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(entry), scrolled);
  });
}
