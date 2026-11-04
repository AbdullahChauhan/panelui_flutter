import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

    testWidgets('a dot has no label and the variant\'s own fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PanelBadge.dot(variant: PanelBadgeVariant.success),
              PanelBadge.dot(variant: PanelBadgeVariant.outline),
            ],
          ),
        ),
      );
      expect(find.byType(Text), findsNothing);
      final dots = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(PanelBadge),
              matching: find.byType(Container),
            ),
          )
          .map((dot) => dot.decoration! as BoxDecoration)
          .toList();
      const c = PanelColors.panelLight;
      expect(dots[0].color, c.successSubtle);
      expect(dots[1].color, const Color(0x00000000));
      expect(dots[1].border!.top.color, c.border);
      expect(
        tester.getSize(find.byType(PanelBadge).first),
        const Size.square(8),
      );
    });

    testWidgets('label sizes carry their paired line heights', (tester) async {
      for (final (size, height) in [
        // 2pt of padding and a 1pt border either side of a 16pt line.
        (PanelBadgeSize.md, 16.0 + 4 + 2),
        (PanelBadgeSize.lg, 20.0 + 8 + 2),
        (PanelBadgeSize.xl, 24.0 + 12 + 2),
      ]) {
        await tester.pumpWidget(
          wrap(PanelBadge(size: size, child: const Text('New'))),
        );
        expect(
          tester.getSize(find.byType(PanelBadge)).height,
          height,
          reason: '$size',
        );
      }
    });

    testWidgets('keeps to its content in a stretching column', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PanelBadge(child: Text('New')),
              PanelCode('pub get'),
            ],
          ),
        ),
      );
      final badge = tester.getSize(
        find.descendant(
          of: find.byType(PanelBadge),
          matching: find.byType(Container),
        ),
      );
      expect(badge.width, lessThan(100));
      final code = tester.getSize(
        find.descendant(
          of: find.byType(PanelCode),
          matching: find.byType(Container),
        ),
      );
      expect(code.width, lessThan(200));
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

    testWidgets('is announced as an alert', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PanelAlert(
            variant: PanelAlertVariant.destructive,
            title: Text('Deployment failed'),
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(PanelAlert));
      expect(node.getSemanticsData().role, SemanticsRole.alert);
    });
  });

  group('PanelLabel', () {
    testWidgets('marks a required field for the eye only', (tester) async {
      await tester.pumpWidget(
        wrap(const PanelLabel('Email', isRequired: true)),
      );
      expect(find.text('*'), findsOneWidget);
      expect(find.bySemanticsLabel('Email'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'\*|required')), findsNothing);
    });

    testWidgets('a disabled label is dimmed and announced so', (tester) async {
      await tester.pumpWidget(wrap(const PanelLabel('Plan', isDisabled: true)));
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.64);
      expect(
        tester.getSemantics(find.text('Plan')),
        isSemantics(label: 'Plan', hasEnabledState: true, isEnabled: false),
      );
    });
  });

  group('PanelSeparator', () {
    testWidgets('breaks around a label', (tester) async {
      await tester.pumpWidget(wrap(const PanelSeparator(label: Text('or'))));
      expect(find.text('or'), findsOneWidget);
      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('spans its parent, and collapses rather than throw where '
        'the room is unbounded', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 200, child: PanelSeparator()),
              Row(mainAxisSize: MainAxisSize.min, children: [PanelSeparator()]),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final rules = find.byType(PanelSeparator);
      expect(tester.getSize(rules.first), const Size(200, 1));
      expect(tester.getSize(rules.last).width, 0);
    });
  });

  group('loading', () {
    testWidgets('a spinner is silent unless labelled', (tester) async {
      await tester.pumpWidget(wrap(const PanelSpinner()));
      expect(find.bySemanticsLabel('Loading'), findsNothing);
      await tester.pumpWidget(
        wrap(const PanelSpinner(semanticLabel: 'Loading')),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Loading'));
      expect(node.getSemanticsData().role, SemanticsRole.loadingSpinner);
      expect(tester.getSize(find.byType(PanelSpinner)), const Size.square(24));
    });

    testWidgets('a spinner pulses in place under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(reduceMotion: true, const PanelSpinner()));
      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(PanelSpinner),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, 1);
      await tester.pump(const Duration(milliseconds: 900));
      expect(fade.opacity.value, closeTo(0.35, 0.001));
      await tester.pump(const Duration(milliseconds: 450));
      // Halfway back, on Reanimated's `inOut(ease)`.
      expect(fade.opacity.value, closeTo(0.675, 0.001));
    });

    testWidgets('a skeleton holds still under reduced motion', (tester) async {
      await tester.pumpWidget(
        wrap(reduceMotion: true, const PanelSkeleton(width: 100, height: 12)),
      );
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(PanelSkeleton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.7);
    });

    testWidgets('a skeleton without a width spans its parent', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 240, child: PanelSkeleton(height: 12)),
              Row(children: [PanelSkeleton(height: 12)]),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(PanelSkeleton).first),
        const Size(240, 12),
      );
    });

    testWidgets('a labelled skeleton is announced as busy', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PanelSkeleton(
            width: 100,
            height: 12,
            semanticLabel: 'Loading messages',
          ),
        ),
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel('Loading messages'),
      );
      expect(node.getSemanticsData().role, SemanticsRole.loadingSpinner);
    });
  });

  group('typography', () {
    testWidgets('headings carry their level', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [PanelText.h1('Billing'), PanelText.h4('Invoices')],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Billing')).getSemanticsData(),
        isA<SemanticsData>().having((d) => d.headingLevel, 'level', 1),
      );
      expect(
        tester.getSemantics(find.text('Invoices')).getSemanticsData(),
        isA<SemanticsData>().having((d) => d.headingLevel, 'level', 4),
      );
    });

    testWidgets('a list is announced as a list of items', (tester) async {
      await tester.pumpWidget(
        wrap(const PanelList(ordered: true, items: [Text('One'), Text('Two')])),
      );
      final item = tester.getSemantics(find.text('Two'));
      expect(item.getSemanticsData().role, SemanticsRole.listItem);
      expect(item.parent!.getSemanticsData().role, SemanticsRole.list);
      expect(item.label, '2.\nTwo');
    });
  });

  group('PanelEmptyState', () {
    testWidgets('a card hugs its content; plain fills the space', (
      tester,
    ) async {
      Widget box(PanelEmptyStateVariant variant) => wrap(
        SizedBox(
          height: 500,
          child: Align(
            alignment: Alignment.topCenter,
            child: PanelEmptyState(
              variant: variant,
              icon: const PanelIcon(PanelIcons.folder),
              title: const Text('Empty'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(box(PanelEmptyStateVariant.card));
      expect(
        tester.getSize(find.byType(PanelEmptyState)).height,
        lessThan(300),
      );
      final icon = tester.widget<IconTheme>(
        find
            .ancestor(
              of: find.byType(PanelIcon),
              matching: find.byType(IconTheme),
            )
            .first,
      );
      expect(icon.data.color, PanelColors.panelLight.mutedForeground);
      expect(icon.data.size, 18);
      await tester.pumpWidget(box(PanelEmptyStateVariant.plain));
      expect(tester.getSize(find.byType(PanelEmptyState)).height, 500);
    });
  });

  testWidgets('a surface has continuous corners on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(wrap(const PanelSurface(child: Text('iOS'))));
    final decoration =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(PanelSurface),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as ShapeDecoration;
    expect(decoration.shape, isA<RoundedSuperellipseBorder>());
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('bare text in card content reads at body size', (tester) async {
    await tester.pumpWidget(
      wrap(const PanelCard(children: [PanelCardContent(child: Text('Body'))])),
    );
    final style = DefaultTextStyle.of(tester.element(find.text('Body'))).style;
    expect(style.fontSize, 16);
    expect(style.color, PanelColors.panelLight.cardForeground);
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
