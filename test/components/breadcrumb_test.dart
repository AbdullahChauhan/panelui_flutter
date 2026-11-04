import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

Widget _trail({
  List<String> crumbs = const ['Home', 'Library', 'Components'],
  String page = 'Breadcrumb',
  ValueChanged<String>? onPressed,
  int? maxItems,
  int itemsBeforeCollapse = 1,
  int itemsAfterCollapse = 1,
  VoidCallback? onEllipsisPressed,
  PanelBreadcrumbSize size = PanelBreadcrumbSize.md,
  Widget? separator,
}) {
  return PanelBreadcrumb(
    size: size,
    separator: separator,
    maxItems: maxItems,
    itemsBeforeCollapse: itemsBeforeCollapse,
    itemsAfterCollapse: itemsAfterCollapse,
    onEllipsisPressed: onEllipsisPressed,
    children: [
      for (final crumb in crumbs)
        PanelBreadcrumbLink(
          onPressed: onPressed == null ? null : () => onPressed(crumb),
          child: Text(crumb),
        ),
      PanelBreadcrumbPage(child: Text(page)),
    ],
  );
}

void main() {
  testWidgets('builds in every theme and size', (tester) async {
    for (final theme in allThemes) {
      for (final size in PanelBreadcrumbSize.values) {
        await tester.pumpWidget(
          wrap(
            _trail(size: size, onPressed: (_) {}),
            theme: theme,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Breadcrumb'), findsOneWidget);
      }
    }
  });

  testWidgets('a link reports its press', (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(wrap(_trail(onPressed: pressed.add)));
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(pressed, ['Library']);
  });

  testWidgets('a chevron sits between every pair of crumbs', (tester) async {
    await tester.pumpWidget(wrap(_trail(onPressed: (_) {})));
    final chevrons = find.byWidgetPredicate(
      (w) => w is PanelIcon && w.icon == PanelIcons.chevronRight,
    );
    expect(chevrons, findsNWidgets(3));

    await tester.pumpWidget(wrap(_trail(separator: const Text('/'))));
    expect(chevrons, findsNothing);
    expect(find.text('/'), findsNWidgets(3));
  });

  testWidgets('a long trail folds its middle into an ellipsis', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      wrap(
        _trail(
          crumbs: const ['Home', 'Library', 'Components', 'Navigation'],
          maxItems: 3,
          onEllipsisPressed: () => opened++,
        ),
      ),
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Library'), findsNothing);
    expect(find.text('Components'), findsNothing);
    expect(find.text('Navigation'), findsNothing);
    expect(find.text('Breadcrumb'), findsOneWidget);

    final ellipsis = find.byWidgetPredicate(
      (w) => w is PanelIcon && w.icon == PanelIcons.ellipsis,
    );
    expect(ellipsis, findsOneWidget);
    await tester.tap(ellipsis);
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('it does not fold when folding would save nothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        _trail(
          crumbs: const ['Home', 'Library'],
          maxItems: 2,
          itemsBeforeCollapse: 2,
        ),
      ),
    );
    // Three crumbs, keeping two at the start and one at the end: there is
    // nothing left to hide, so nothing folds.
    expect(find.text('Library'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is PanelIcon && w.icon == PanelIcons.ellipsis,
      ),
      findsNothing,
    );
  });

  testWidgets('the trail and its crumbs are announced', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(_trail(maxItems: 3, onPressed: (_) {})));
    expect(find.bySemanticsLabel('Breadcrumb'), findsWidgets);
    expect(
      tester.getSemantics(find.text('Home')),
      isSemantics(label: 'Home', isLink: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.text('Breadcrumb')),
      isSemantics(label: 'Breadcrumb', isSelected: true),
    );
    expect(find.bySemanticsLabel('More'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a link with no callback cannot be pressed', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(_trail()));
    expect(
      tester.getSemantics(find.text('Home')),
      isSemantics(isLink: true, hasTapAction: false),
    );
    handle.dispose();
  });
}
