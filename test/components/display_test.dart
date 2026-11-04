import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

void main() {
  group('PanelBadge', () {
    testWidgets('clamps a count to 99+ and names it', (tester) async {
      await tester.pumpWidget(wrap(const PanelBadge.count(128)));
      expect(find.text('99+'), findsOneWidget);
      expect(tester.getSemantics(find.byType(PanelBadge)).label, '128 unread');
    });

    testWidgets('a dot has no label and the solid status colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const PanelBadge.dot(variant: PanelBadgeVariant.success)),
      );
      expect(find.byType(Text), findsNothing);
      final dot = tester.widget<Container>(
        find.descendant(
          of: find.byType(PanelBadge),
          matching: find.byType(Container),
        ),
      );
      expect(
        (dot.decoration! as BoxDecoration).color,
        PanelColors.panelLight.success,
      );
    });
  });

  group('PanelAlert', () {
    testWidgets('picks the icon from the variant', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PanelAlert(
            variant: PanelAlertVariant.success,
            title: Text('Paid'),
            description: Text('Thanks.'),
          ),
        ),
      );
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Thanks.'), findsOneWidget);
      final icon = tester.widget<PanelIcon>(find.byType(PanelIcon));
      expect(icon.icon, PanelIcons.checkCircle);
    });

    testWidgets('can drop the icon', (tester) async {
      await tester.pumpWidget(
        wrap(const PanelAlert(showIcon: false, title: Text('Note'))),
      );
      expect(find.byType(PanelIcon), findsNothing);
    });
  });

  group('PanelLabel', () {
    testWidgets('marks a required field', (tester) async {
      await tester.pumpWidget(
        wrap(const PanelLabel('Email', isRequired: true)),
      );
      expect(find.text('*'), findsOneWidget);
      expect(find.bySemanticsLabel('Email, required'), findsOneWidget);
    });
  });

  group('PanelSeparator', () {
    testWidgets('breaks around a label', (tester) async {
      await tester.pumpWidget(wrap(const PanelSeparator(label: Text('or'))));
      expect(find.text('or'), findsOneWidget);
      expect(find.byType(Expanded), findsNWidgets(2));
    });
  });

  group('loading', () {
    testWidgets('a spinner is silent unless labelled', (tester) async {
      await tester.pumpWidget(wrap(const PanelSpinner()));
      expect(find.bySemanticsLabel('Loading'), findsNothing);
      await tester.pumpWidget(
        wrap(const PanelSpinner(semanticLabel: 'Loading')),
      );
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(tester.getSize(find.byType(PanelSpinner)), const Size.square(24));
    });

    testWidgets('a skeleton holds still under reduced motion', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: wrap(const PanelSkeleton(width: 100, height: 12)),
        ),
      );
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(PanelSkeleton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.7);
    });
  });

  testWidgets('surfaces, cards and empty states build in every theme', (
    tester,
  ) async {
    for (final theme in allThemes) {
      await tester.pumpWidget(
        wrap(
          theme: theme,
          SingleChildScrollView(
            child: Column(
              children: [
                const PanelSurface(
                  bordered: true,
                  elevated: true,
                  child: PanelSurface(
                    variant: PanelSurfaceVariant.secondary,
                    child: Text('Nested'),
                  ),
                ),
                PanelCard(
                  children: [
                    const PanelCardHeader(
                      title: Text('Title'),
                      description: Text('Description'),
                    ),
                    const PanelCardContent(child: Text('Body')),
                    PanelCardFooter(
                      variant: PanelCardFooterVariant.panel,
                      children: [
                        PanelButton(onPressed: () {}, child: const Text('Go')),
                      ],
                    ),
                  ],
                ),
                const PanelEmptyState(
                  variant: PanelEmptyStateVariant.card,
                  icon: PanelIcon(PanelIcons.folder),
                  title: Text('Empty'),
                  description: Text('Nothing here yet.'),
                ),
                for (final variant in PanelAlertVariant.values)
                  PanelAlert(variant: variant, title: Text(variant.name)),
                for (final variant in PanelBadgeVariant.values)
                  PanelBadge(variant: variant, child: Text(variant.name)),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Body'), findsOneWidget);
    }
  });

  testWidgets('every PanelUI glyph paints', (tester) async {
    await tester.pumpWidget(
      wrap(
        Wrap(
          children: [
            for (final icon in PanelIcons.all.values)
              PanelIcon(icon, size: 16, filled: true),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(PanelIcon), findsNWidgets(PanelIcons.all.length));
  });
}
