import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

void main() {
  testWidgets('builds every variant, size and orientation in every theme', (
    tester,
  ) async {
    for (final theme in allThemes) {
      for (final variant in PanelItemVariant.values) {
        for (final size in PanelItemSize.values) {
          for (final orientation in Axis.values) {
            await tester.pumpWidget(
              wrap(
                SizedBox(
                  width: 320,
                  child: PanelItem(
                    variant: variant,
                    size: size,
                    orientation: orientation,
                    media: const PanelItemMedia(
                      variant: PanelItemMediaVariant.icon,
                      child: PanelIcon(PanelIcons.package),
                    ),
                    title: const Text('Invoice.pdf'),
                    description: const Text('2.4 MB'),
                    actions: const [PanelIcon(PanelIcons.chevronRight)],
                    header: const PanelItemHeader(children: [Text('Draft')]),
                    footer: const PanelItemFooter(children: [Text(r'$12')]),
                  ),
                ),
                theme: theme,
              ),
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    }
  });

  testWidgets('padding and media follow the size', (tester) async {
    for (final (size, padding, tile) in [
      (PanelItemSize.md, 16.0, 40.0),
      (PanelItemSize.sm, 12.0, 32.0),
      (PanelItemSize.xs, 8.0, 24.0),
    ]) {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 320,
            child: PanelItem(
              size: size,
              media: const PanelItemMedia(
                variant: PanelItemMediaVariant.icon,
                child: PanelIcon(PanelIcons.bell),
              ),
              title: const Text('Title'),
            ),
          ),
        ),
      );
      final item = tester.getRect(find.byType(PanelItem));
      final media = tester.getRect(find.byType(PanelItemMedia));
      expect(media.width, tile);
      expect(media.left - item.left, padding);
    }
  });

  testWidgets('a pressable item reports presses; a static one is no button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var pressed = 0;
    await tester.pumpWidget(
      wrap(PanelItem(title: const Text('Privacy'), onPressed: () => pressed++)),
    );
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(pressed, 1);
    expect(
      tester.getSemantics(find.byType(PanelItem)),
      isSemantics(isButton: true, hasTapAction: true),
    );

    await tester.pumpWidget(wrap(const PanelItem(title: Text('Static'))));
    expect(find.byType(PanelPressable), findsNothing);
    expect(
      tester.getSemantics(find.text('Static')),
      isSemantics(isButton: false),
    );
    handle.dispose();
  });

  testWidgets('a disabled item is dimmed and ignores presses', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      wrap(
        PanelItem(
          enabled: false,
          title: const Text('Privacy'),
          onPressed: () => pressed++,
        ),
      ),
    );
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(pressed, 0);
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Privacy'), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.64);
  });

  testWidgets('a group puts hairlines between its items', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PanelItemGroup(
          separated: true,
          children: [
            PanelItem(title: Text('Notifications')),
            PanelItem(title: Text('Privacy')),
            PanelItem(title: Text('Appearance')),
          ],
        ),
      ),
    );
    expect(find.byType(PanelSeparator), findsNWidgets(2));
  });

  testWidgets('a horizontal group stretches its items to one height', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: PanelItemGroup(
            orientation: Axis.horizontal,
            children: [
              SizedBox(
                width: 160,
                child: PanelItem(
                  orientation: Axis.vertical,
                  variant: PanelItemVariant.outline,
                  title: Text('Starter'),
                ),
              ),
              SizedBox(
                width: 160,
                child: PanelItem(
                  orientation: Axis.vertical,
                  variant: PanelItemVariant.outline,
                  title: Text('Pro'),
                  description: Text('Unlimited projects and more'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final first = tester.getSize(find.byType(PanelItem).first);
    final second = tester.getSize(find.byType(PanelItem).last);
    expect(first.height, second.height);
  });
}
