import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

/// An image that never arrives.
class _BrokenImage extends ImageProvider<_BrokenImage> {
  const _BrokenImage();

  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _BrokenImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(StateError('offline')),
  );
}

/// An image that is still loading.
class _PendingImage extends ImageProvider<_PendingImage> {
  const _PendingImage();

  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _PendingImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}

void main() {
  testWidgets('shows the initials without a picture', (tester) async {
    await tester.pumpWidget(wrap(const PanelAvatar(fallback: 'KA')));
    expect(find.text('KA'), findsOneWidget);
    expect(tester.getSize(find.byType(PanelAvatar)), const Size(40, 40));

    await tester.pumpWidget(wrap(const PanelAvatar()));
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('falls back to the initials when the picture fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const PanelAvatar(image: _BrokenImage(), fallback: 'AB')),
    );
    await tester.pumpAndSettle();
    expect(find.text('AB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the picture, not the initials, while it loads', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const PanelAvatar(image: _PendingImage(), fallback: 'AB')),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('AB'), findsNothing);
  });

  testWidgets('sizes set the diameter', (tester) async {
    for (final size in PanelAvatarSize.values) {
      await tester.pumpWidget(wrap(PanelAvatar(fallback: 'KA', size: size)));
      expect(
        tester.getSize(find.byType(PanelAvatar)),
        Size.square(size.diameter),
      );
    }
  });

  testWidgets('a badge hangs off the top trailing corner', (tester) async {
    const badge = Key('badge');
    await tester.pumpWidget(
      wrap(
        const PanelAvatar(
          fallback: 'EF',
          size: PanelAvatarSize.lg,
          badge: SizedBox(key: badge, width: 8, height: 8),
        ),
      ),
    );
    final avatar = tester.getRect(find.byType(PanelAvatar));
    final dot = tester.getRect(find.byKey(badge));
    // Ringed by 2pt, and pushed 4pt past the corner.
    expect(dot.right, avatar.right + 4 - 2);
    expect(dot.top, avatar.top - 4 + 2);

    await tester.pumpWidget(
      wrap(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: PanelAvatar(
            fallback: 'EF',
            badge: SizedBox(key: badge, width: 8, height: 8),
          ),
        ),
      ),
    );
    final rtlAvatar = tester.getRect(find.byType(PanelAvatar));
    expect(tester.getRect(find.byKey(badge)).left, rtlAvatar.left - 4 + 2);
  });

  testWidgets('is announced as an image named by its initials', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(const PanelAvatar(fallback: 'KA', semanticLabel: 'Khalid Abdi')),
    );
    expect(
      tester.getSemantics(find.byType(PanelAvatar)),
      isSemantics(label: 'Khalid Abdi', isImage: true),
    );
    handle.dispose();
  });

  test('countOf caps the faces, not the row', () {
    expect(PanelAvatarGroup.countOf(5, max: 3), (visible: 3, overflow: 2));
    expect(PanelAvatarGroup.countOf(3, max: 3, total: 40), (
      visible: 3,
      overflow: 37,
    ));
    // A cap below one is no cap.
    expect(PanelAvatarGroup.countOf(4, max: 0), (visible: 4, overflow: 0));
    // A total below what is already shown is stale.
    expect(PanelAvatarGroup.countOf(4, total: 2), (visible: 4, overflow: 0));
    expect(PanelAvatarGroup.countOf(0), (visible: 0, overflow: 0));
  });

  test('overlapOf is a third of the size unless given, never a gap', () {
    expect(PanelAvatarGroup.overlapOf(PanelAvatarSize.md), 13);
    expect(PanelAvatarGroup.overlapOf(PanelAvatarSize.xl), 26);
    expect(PanelAvatarGroup.overlapOf(PanelAvatarSize.md, 0), 0);
    expect(PanelAvatarGroup.overlapOf(PanelAvatarSize.md, -5), 0);
    expect(PanelAvatarGroup.overlapOf(PanelAvatarSize.md, 99), 40);
  });

  testWidgets('a group overlaps its faces and counts the rest', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        const PanelAvatarGroup(
          max: 2,
          children: [
            PanelAvatar(fallback: 'A'),
            PanelAvatar(fallback: 'B'),
            PanelAvatar(fallback: 'C'),
            PanelAvatar(fallback: 'D'),
          ],
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsNothing);
    expect(find.text('+2'), findsOneWidget);
    expect(find.bySemanticsLabel('2 more'), findsOneWidget);
    // Three 40pt faces, each sliding 13pt under the one before.
    expect(
      tester.getSize(find.byType(PanelAvatarGroup)),
      const Size(40 + 27 + 27, 40),
    );
    final a = tester.getRect(find.widgetWithText(PanelAvatar, 'A'));
    final b = tester.getRect(find.widgetWithText(PanelAvatar, 'B'));
    expect(b.left - a.left, 27);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('the first face is on top', (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      wrap(
        PanelAvatarGroup(
          children: [
            for (final name in ['A', 'B'])
              GestureDetector(
                onTap: () => pressed.add(name),
                child: PanelAvatar(fallback: name),
              ),
          ],
        ),
      ),
    );
    final a = tester.getRect(find.widgetWithText(PanelAvatar, 'A'));
    // A point where A and B overlap.
    await tester.tapAt(Offset(a.right - 4, a.center.dy));
    expect(pressed, ['A']);
  });

  testWidgets('faces in a group take its size and a background ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const PanelAvatarGroup(
          size: PanelAvatarSize.sm,
          children: [
            PanelAvatar(fallback: 'A'),
            PanelAvatar(fallback: 'B', size: PanelAvatarSize.lg),
          ],
        ),
      ),
    );
    expect(
      tester.getSize(find.widgetWithText(PanelAvatar, 'A')),
      const Size(32, 32),
    );
    // A face's own size still wins.
    expect(
      tester.getSize(find.widgetWithText(PanelAvatar, 'B')),
      const Size(56, 56),
    );
    final ring = tester.widget<Container>(
      find
          .descendant(
            of: find.widgetWithText(PanelAvatar, 'A'),
            matching: find.byType(Container),
          )
          .first,
    );
    final border = (ring.decoration! as BoxDecoration).border! as Border;
    expect(border.top.width, 2);
    expect(border.top.color, PanelThemeData.panelLight.colors.background);
  });

  testWidgets('a group runs from the right in a right-to-left layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: PanelAvatarGroup(
            children: [
              PanelAvatar(fallback: 'A'),
              PanelAvatar(fallback: 'B'),
            ],
          ),
        ),
      ),
    );
    final a = tester.getRect(find.widgetWithText(PanelAvatar, 'A'));
    final b = tester.getRect(find.widgetWithText(PanelAvatar, 'B'));
    expect(a.left, greaterThan(b.left));
  });

  testWidgets('overlap: 0 closes the stack into a plain row', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PanelAvatarGroup(
          overlap: 0,
          children: [
            PanelAvatar(fallback: 'A'),
            PanelAvatar(fallback: 'B'),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(PanelAvatarGroup)), const Size(80, 40));
  });

  testWidgets('builds in every theme and size', (tester) async {
    for (final theme in allThemes) {
      for (final size in PanelAvatarSize.values) {
        await tester.pumpWidget(
          wrap(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PanelAvatar(
                  fallback: 'KA',
                  size: size,
                  badge: const PanelBadge.dot(
                    variant: PanelBadgeVariant.success,
                  ),
                ),
                PanelAvatar(
                  image: const _BrokenImage(),
                  fallback: 'AB',
                  size: size,
                  badge: const PanelBadge.count(5),
                ),
                PanelAvatarGroup(
                  size: size,
                  max: 3,
                  total: 40,
                  children: const [
                    PanelAvatar(fallback: 'A'),
                    PanelAvatar(fallback: 'B'),
                    PanelAvatar(fallback: 'C'),
                  ],
                ),
              ],
            ),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
}
