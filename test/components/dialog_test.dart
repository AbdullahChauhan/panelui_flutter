import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';
import 'package:panelui_flutter/src/foundation/overlay_scrim.dart';

import '../helpers.dart';

/// A button that opens a confirm dialog and records what it returns.
class _Opener extends StatefulWidget {
  const _Opener({
    this.barrierDismissible = true,
    this.footerVariant = PanelDialogFooterVariant.plain,
    this.blur = false,
    this.focusNode,
  });

  final bool barrierDismissible;
  final PanelDialogFooterVariant footerVariant;
  final bool blur;
  final FocusNode? focusNode;

  @override
  State<_Opener> createState() => _OpenerState();
}

class _OpenerState extends State<_Opener> {
  bool? result;
  bool returned = false;

  Future<void> _open() async {
    final value = await showPanelDialog<bool>(
      context,
      barrierDismissible: widget.barrierDismissible,
      blur: widget.blur,
      builder: (context) => PanelDialog(
        title: const Text('Delete project?'),
        description: const Text('This action cannot be undone.'),
        footerVariant: widget.footerVariant,
        actions: [
          PanelButton(
            variant: PanelButtonVariant.ghost,
            size: PanelButtonSize.sm,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          PanelButton(
            variant: PanelButtonVariant.destructive,
            size: PanelButtonSize.sm,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    setState(() {
      result = value;
      returned = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PanelButton(
      focusNode: widget.focusNode,
      onPressed: _open,
      child: const Text('Open'),
    );
  }
}

_OpenerState _state(WidgetTester tester) =>
    tester.state<_OpenerState>(find.byType(_Opener));

void main() {
  testWidgets('opens, and returns the value it is popped with', (tester) async {
    await tester.pumpWidget(wrap(const _Opener()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Delete project?'), findsOneWidget);
    expect(find.text('This action cannot be undone.'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete project?'), findsNothing);
    expect(_state(tester).returned, isTrue);
    expect(_state(tester).result, isTrue);
  });

  testWidgets('a tap on the scrim closes it with null', (tester) async {
    await tester.pumpWidget(wrap(const _Opener()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text('Delete project?'), findsNothing);
    expect(_state(tester).returned, isTrue);
    expect(_state(tester).result, isNull);
  });

  testWidgets('Escape closes it', (tester) async {
    await tester.pumpWidget(wrap(const _Opener()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Delete project?'), findsNothing);
    expect(_state(tester).returned, isTrue);
  });

  testWidgets('a dialog that is not dismissible ignores the scrim, Escape '
      'and back', (tester) async {
    await tester.pumpWidget(wrap(const _Opener(barrierDismissible: false)));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Delete project?'), findsOneWidget);
    expect(_state(tester).returned, isFalse);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete project?'), findsNothing);
    expect(_state(tester).result, isFalse);
  });

  testWidgets('zooms in from nothing on a spring, overshooting full size', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const _Opener()));
    await tester.tap(find.text('Open'));
    await tester.pump();

    double scale() {
      final transform = tester.widget<Transform>(
        find
            .ancestor(
              of: find.byType(PanelDialog),
              matching: find.byType(Transform),
            )
            .first,
      );
      return transform.transform.storage[0];
    }

    expect(scale(), lessThan(0.05));
    var peak = 0.0;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      peak = peak < scale() ? scale() : peak;
    }
    expect(peak, greaterThan(1.0));
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1, 0.001));
  });

  testWidgets('under reduced motion it fades without the zoom', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: wrap(const _Opener()),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final transform = tester.widget<Transform>(
      find
          .ancestor(
            of: find.byType(PanelDialog),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(transform.transform.storage[0], 1);
    await tester.pumpAndSettle();
  });

  testWidgets('scopes and names its route, and labels the scrim', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const _Opener()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // A plain line of text, as in PanelUI, that names the route.
    expect(
      tester.getSemantics(find.text('Delete project?')),
      matchesSemantics(label: 'Delete project?', namesRoute: true),
    );
    expect(find.bySemanticsLabel('Close dialog'), findsOneWidget);
    final route = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && (widget.properties.scopesRoute ?? false),
    );
    expect(route, findsWidgets);
    handle.dispose();
  });

  testWidgets('moves focus in and gives it back when it closes', (
    tester,
  ) async {
    final opener = FocusNode();
    addTearDown(opener.dispose);
    await tester.pumpWidget(wrap(_Opener(focusNode: opener)));
    opener.requestFocus();
    await tester.pump();
    expect(opener.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Delete project?'), findsOneWidget);
    expect(opener.hasFocus, isFalse);

    // Tab reaches the dialog's buttons and stays inside it.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      find.ancestor(
        of: find.byWidget(focused.widget),
        matching: find.byType(PanelDialog),
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Delete project?'), findsNothing);
    expect(opener.hasFocus, isTrue);
  });

  testWidgets('a panel footer draws a band in the inset tint', (tester) async {
    await tester.pumpWidget(
      wrap(const _Opener(footerVariant: PanelDialogFooterVariant.panel)),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final band = find.ancestor(
      of: find.text('Delete'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                PanelColors.panelLight.inset,
      ),
    );
    expect(band, findsOneWidget);
    final dialog = tester.getRect(find.byType(PanelDialog));
    final footer = tester.getRect(band);
    // Out to the dialog's border, and down to its bottom edge.
    expect(footer.left, dialog.left + 1);
    expect(footer.right, dialog.right - 1);
    expect(footer.bottom, dialog.bottom - 1);
    // 26pt below the content: the column's gap and `mt-5`.
    final surface = tester.getRect(
      find.descendant(of: band, matching: find.byType(DecoratedBox)).first,
    );
    final description = find.text('This action cannot be undone.');
    expect(surface.top - tester.getRect(description).bottom, 26);
    // Its bottom corners are the dialog's own, `rounded-b-2xl`.
    final decoration =
        tester.widget<Container>(band).decoration! as BoxDecoration;
    final radius = PanelThemeData.panelLight.radii.xxl;
    expect(
      decoration.borderRadius,
      BorderRadius.only(
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      ),
    );
  });

  testWidgets('the scrim fades inside the layer, as a square of its fade', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const _Opener()));
    double dim() => tester
        .widget<ColoredBox>(
          find.descendant(
            of: find.byType(PanelOverlayScrim),
            matching: find.byType(ColoredBox),
          ),
        )
        .color
        .a;

    // Halfway through the 150ms in, the layer and the scrim's own fade are
    // each at half, so the 50% dim is at a quarter of itself.
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(dim(), closeTo(0.5 * 0.25, 0.01));
    await tester.pumpAndSettle();
    expect(dim(), closeTo(0.5, 0.001));

    // And the same on the way out.
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(dim(), closeTo(0.5 * 0.25, 0.01));
    await tester.pumpAndSettle();
  });

  testWidgets('centres on the whole screen, 24pt in from its edges', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          padding: EdgeInsets.only(top: 47, bottom: 34),
          viewPadding: EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: wrap(const _Opener()),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(PanelDialog)).center.dy, 300);
  });

  testWidgets('it rises clear of the keyboard', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
        child: wrap(const _Opener()),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    // Centred in what the keyboard leaves, 24pt in from it.
    final dialog = tester.getRect(find.byType(PanelDialog));
    expect(dialog.center.dy, closeTo((600 - 300) / 2, 0.5));
    expect(dialog.bottom, lessThanOrEqualTo(600 - 300 - 24));
  });

  testWidgets('is 384pt wide at most, and fills a narrower screen', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const _Opener()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PanelDialog)).width, 384);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PanelDialog)).width, 360 - 48);
  });

  testWidgets('a long body scrolls between the heading and the actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => PanelButton(
            onPressed: () => showPanelDialog<void>(
              context,
              builder: (context) => PanelDialog(
                title: const Text('Terms'),
                actions: [
                  PanelButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Accept'),
                  ),
                ],
                child: Column(
                  children: [for (var i = 0; i < 40; i++) Text('Clause $i')],
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Accept').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.text('Terms'), findsNothing);
  });

  testWidgets('builds in every theme, with either footer and a blur', (
    tester,
  ) async {
    for (final theme in allThemes) {
      for (final variant in PanelDialogFooterVariant.values) {
        await tester.pumpWidget(
          wrap(_Opener(footerVariant: variant, blur: true), theme: theme),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(PanelDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    }
  });
}
