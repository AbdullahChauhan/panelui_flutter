import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

String _run(List<PanelPaginationEntry> entries) =>
    entries.map((e) => e.toString()).join(' ');

Finder _page(int number) => find.bySemanticsLabel('Page $number');

void main() {
  group('panelPaginationRange', () {
    test('keeps a fixed number of targets', () {
      expect(
        _run(panelPaginationRange(count: 12, page: 1)),
        '1 2 3 4 5 end-ellipsis 12',
      );
      expect(
        _run(panelPaginationRange(count: 12, page: 6)),
        '1 start-ellipsis 5 6 7 end-ellipsis 12',
      );
      expect(
        _run(panelPaginationRange(count: 12, page: 12)),
        '1 start-ellipsis 8 9 10 11 12',
      );
    });

    test('draws a one-page gap as the page', () {
      expect(
        _run(panelPaginationRange(count: 12, page: 4)),
        '1 2 3 4 5 end-ellipsis 12',
      );
      expect(_run(panelPaginationRange(count: 7, page: 4)), '1 2 3 4 5 6 7');
    });

    test('widens with siblings and boundaries', () {
      expect(
        _run(
          panelPaginationRange(
            count: 240,
            page: 120,
            siblings: 2,
            boundaries: 2,
          ),
        ),
        '1 2 start-ellipsis 118 119 120 121 122 end-ellipsis 239 240',
      );
    });

    test('handles tiny and empty sets', () {
      expect(_run(panelPaginationRange(count: 1, page: 1)), '1');
      expect(_run(panelPaginationRange(count: 3, page: 2)), '1 2 3');
      expect(panelPaginationRange(count: 0, page: 0), isEmpty);
    });
  });

  group('PanelPagination', () {
    testWidgets('builds every variant and size in every theme', (tester) async {
      for (final theme in allThemes) {
        for (final variant in PanelPaginationVariant.values) {
          for (final size in PanelPaginationSize.values) {
            await tester.pumpWidget(
              wrap(
                PanelPagination(
                  count: 12,
                  variant: variant,
                  size: size,
                  leading: variant == PanelPaginationVariant.compact
                      ? const PanelPaginationStatus(pageSize: 20, total: 240)
                      : null,
                ),
                theme: theme,
              ),
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('pressing a page reports it and lights it', (tester) async {
      final pages = <int>[];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(PanelPagination(count: 12, onChanged: pages.add)),
      );
      expect(
        tester.getSemantics(_page(1)),
        isSemantics(isSelected: true, isButton: true),
      );
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      expect(pages, [3]);
      expect(tester.getSemantics(_page(3)), isSemantics(isSelected: true));
      expect(tester.getSemantics(_page(1)), isSemantics(isSelected: false));
      handle.dispose();
    });

    testWidgets('the arrows step and stop at the ends', (tester) async {
      final pages = <int>[];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(PanelPagination(count: 3, onChanged: pages.add)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Previous')),
        isSemantics(isEnabled: false, hasEnabledState: true),
      );
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Next'));
      await tester.pumpAndSettle();
      expect(pages, [2, 3]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Next')),
        isSemantics(isEnabled: false, hasEnabledState: true),
      );
      await tester.tap(find.bySemanticsLabel('Previous'));
      await tester.pumpAndSettle();
      expect(pages, [2, 3, 2]);
      handle.dispose();
    });

    testWidgets('an ellipsis jumps pageJump pages its way', (tester) async {
      final pages = <int>[];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(PanelPagination(count: 40, page: 20, onChanged: pages.add)),
      );
      await tester.tap(find.bySemanticsLabel('Forward 5 pages'));
      await tester.tap(find.bySemanticsLabel('Back 5 pages'));
      await tester.pumpAndSettle();
      expect(pages, [25, 15]);
      handle.dispose();
    });

    testWidgets('a controlled page is clamped to the count', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(const PanelPagination(count: 5, page: 9)));
      expect(tester.getSemantics(_page(5)), isSemantics(isSelected: true));
      handle.dispose();
    });

    testWidgets('compact shows where you are', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          const PanelPagination(
            count: 12,
            page: 3,
            variant: PanelPaginationVariant.compact,
          ),
        ),
      );
      expect(find.text('3 / 12'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 3 of 12'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('simple writes its labels', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PanelPagination(
            count: 12,
            variant: PanelPaginationVariant.simple,
          ),
        ),
      );
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('a disabled row ignores presses', (tester) async {
      final pages = <int>[];
      await tester.pumpWidget(
        wrap(PanelPagination(count: 12, enabled: false, onChanged: pages.add)),
      );
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      expect(pages, isEmpty);
    });

    testWidgets('an uncontrolled row keeps its own page', (tester) async {
      await tester.pumpWidget(wrap(const PanelPagination(count: 12)));
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      // Page 2 is lit, so its label takes the primary foreground.
      final label = tester.widget<Text>(find.text('2'));
      expect(
        label.style!.color,
        PanelThemeData.panelLight.colors.primaryForeground,
      );
    });

    testWidgets('the status line counts the span', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PanelPagination(
            count: 12,
            page: 12,
            variant: PanelPaginationVariant.compact,
            leading: PanelPaginationStatus(pageSize: 20, total: 235),
          ),
        ),
      );
      expect(find.text('221–235 of 235'), findsOneWidget);
      await tester.pumpWidget(
        wrap(const PanelPaginationStatus(page: 1, pageSize: 20, total: 0)),
      );
      expect(find.text('None'), findsOneWidget);
    });

    testWidgets('a run too wide for its space is clipped, not overflowed', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 200,
            child: PanelPagination(count: 240, page: 120, siblings: 2),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
