import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../helpers.dart';

const _faq = [
  ('shipping', 'How long does shipping take?', 'Three to five working days.'),
  ('returns', 'What is your returns policy?', 'Thirty days for a refund.'),
  ('support', 'How do I contact support?', 'Reply to your order email.'),
];

Widget _accordion({
  PanelAccordionVariant variant = PanelAccordionVariant.plain,
  PanelAccordionSelectionMode mode = PanelAccordionSelectionMode.single,
  Set<String>? value,
  Set<String> initialValue = const {'shipping'},
  ValueChanged<Set<String>>? onChanged,
  bool keepMounted = false,
  bool supportEnabled = true,
}) {
  return PanelAccordion<String>(
    variant: variant,
    selectionMode: mode,
    value: value,
    initialValue: initialValue,
    onChanged: onChanged,
    keepMounted: keepMounted,
    children: [
      for (final (id, question, answer) in _faq)
        PanelAccordionItem(
          value: id,
          enabled: id != 'support' || supportEnabled,
          title: Text(question),
          child: id == 'returns' ? const _Counter() : Text(answer),
        ),
    ],
  );
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _count++),
      child: Text('Count $_count'),
    );
  }
}

Finder _header(String question) => find.ancestor(
  of: find.text(question),
  matching: find.byType(PanelPressable),
);

void main() {
  group('PanelAccordion', () {
    testWidgets('builds every variant in every theme', (tester) async {
      for (final theme in allThemes) {
        for (final variant in PanelAccordionVariant.values) {
          await tester.pumpWidget(
            wrap(_accordion(variant: variant), theme: theme),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Three to five working days.'), findsOneWidget);
        }
      }
    });

    testWidgets('single mode keeps one section open', (tester) async {
      final reported = <Set<String>>[];
      await tester.pumpWidget(wrap(_accordion(onChanged: reported.add)));
      await tester.pumpAndSettle();
      expect(find.text('Three to five working days.'), findsOneWidget);
      expect(find.text('Count 0'), findsNothing);

      await tester.tap(find.text('What is your returns policy?'));
      await tester.pumpAndSettle();
      expect(reported.last, {'returns'});
      expect(find.text('Count 0'), findsOneWidget);
      expect(find.text('Three to five working days.'), findsNothing);

      await tester.tap(find.text('What is your returns policy?'));
      await tester.pumpAndSettle();
      expect(reported.last, isEmpty);
      expect(find.text('Count 0'), findsNothing);
    });

    testWidgets('multiple mode opens sections side by side', (tester) async {
      final reported = <Set<String>>[];
      await tester.pumpWidget(
        wrap(
          _accordion(
            mode: PanelAccordionSelectionMode.multiple,
            onChanged: reported.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('What is your returns policy?'));
      await tester.pumpAndSettle();
      expect(reported.last, {'shipping', 'returns'});
      expect(find.text('Three to five working days.'), findsOneWidget);
      expect(find.text('Count 0'), findsOneWidget);
    });

    testWidgets('a controlled accordion shows what it is told', (tester) async {
      final reported = <Set<String>>[];
      await tester.pumpWidget(
        wrap(_accordion(value: const {'support'}, onChanged: reported.add)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reply to your order email.'), findsOneWidget);
      await tester.tap(find.text('How long does shipping take?'));
      await tester.pumpAndSettle();
      expect(reported, [
        {'shipping'},
      ]);
      expect(find.text('Three to five working days.'), findsNothing);
    });

    testWidgets('a section grows to its height over 200ms', (tester) async {
      await tester.pumpWidget(wrap(_accordion(initialValue: const {})));
      await tester.pumpAndSettle();
      final closed = tester.getSize(find.byType(PanelAccordion<String>));
      await tester.tap(find.text('How long does shipping take?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final midway = tester.getSize(find.byType(PanelAccordion<String>));
      await tester.pump(const Duration(milliseconds: 150));
      final open = tester.getSize(find.byType(PanelAccordion<String>));
      expect(midway.height, greaterThan(closed.height));
      expect(midway.height, lessThan(open.height));
      // The chevron has turned half a circle.
      final rotation = tester.widget<AnimatedRotation>(
        find.descendant(
          of: _header('How long does shipping take?'),
          matching: find.byType(AnimatedRotation),
        ),
      );
      expect(rotation.turns, 0.5);
    });

    testWidgets('a disabled section ignores presses', (tester) async {
      final reported = <Set<String>>[];
      await tester.pumpWidget(
        wrap(_accordion(supportEnabled: false, onChanged: reported.add)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('How do I contact support?'));
      await tester.pumpAndSettle();
      expect(reported, isEmpty);
      expect(find.text('Reply to your order email.'), findsNothing);
    });

    testWidgets('headers announce whether they are expanded', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(_accordion(supportEnabled: false)));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(_header('How long does shipping take?')),
        isSemantics(
          label: 'How long does shipping take?',
          isButton: true,
          hasExpandedState: true,
          isExpanded: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(_header('What is your returns policy?')),
        isSemantics(hasExpandedState: true, isExpanded: false),
      );
      expect(
        tester.getSemantics(_header('How do I contact support?')),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('keepMounted keeps a closed body and its state', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(_accordion(keepMounted: true, initialValue: const {'returns'})),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Count 0'));
      await tester.pump();
      await tester.tap(find.text('What is your returns policy?'));
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsNothing);
      expect(find.text('Count 1', skipOffstage: false), findsOneWidget);
      await tester.tap(find.text('What is your returns policy?'));
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsOneWidget);
    });

    testWidgets('without keepMounted a closed body starts afresh', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(_accordion(initialValue: const {'returns'})),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Count 0'));
      await tester.pump();
      await tester.tap(find.text('What is your returns policy?'));
      await tester.pumpAndSettle();
      expect(find.text('Count 1', skipOffstage: false), findsNothing);
      await tester.tap(find.text('What is your returns policy?'));
      await tester.pumpAndSettle();
      expect(find.text('Count 0'), findsOneWidget);
    });
  });

  group('PanelCollapsible', () {
    Widget collapsible({
      bool? open,
      bool initiallyOpen = false,
      ValueChanged<bool>? onOpenChanged,
      PanelCollapsibleVariant variant = PanelCollapsibleVariant.plain,
      bool enabled = true,
    }) {
      return PanelCollapsible(
        open: open,
        initiallyOpen: initiallyOpen,
        onOpenChanged: onOpenChanged,
        variant: variant,
        enabled: enabled,
        title: const Text('What is included'),
        child: const _Counter(),
      );
    }

    testWidgets('builds every variant in every theme', (tester) async {
      for (final theme in allThemes) {
        for (final variant in PanelCollapsibleVariant.values) {
          await tester.pumpWidget(
            wrap(
              collapsible(variant: variant, initiallyOpen: true),
              theme: theme,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Count 0'), findsOneWidget);
        }
      }
    });

    testWidgets('opens and closes, keeping the body and its state', (
      tester,
    ) async {
      final reported = <bool>[];
      await tester.pumpWidget(wrap(collapsible(onOpenChanged: reported.add)));
      await tester.pumpAndSettle();
      // Closed, the body is built but takes no room and is not hit.
      expect(find.text('Count 0', skipOffstage: false), findsOneWidget);
      final closed = tester.getSize(find.byType(PanelCollapsible));

      await tester.tap(find.text('What is included'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final midway = tester.getSize(find.byType(PanelCollapsible));
      await tester.pumpAndSettle();
      final open = tester.getSize(find.byType(PanelCollapsible));
      expect(reported, [true]);
      expect(midway.height, greaterThan(closed.height));
      expect(midway.height, lessThan(open.height));

      await tester.tap(find.text('Count 0'));
      await tester.pump();
      await tester.tap(find.text('What is included'));
      await tester.pumpAndSettle();
      expect(reported, [true, false]);
      expect(tester.getSize(find.byType(PanelCollapsible)), closed);
      await tester.tap(find.text('What is included'));
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsOneWidget);
    });

    testWidgets('the body starts at the leading edge, full width', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            width: 320,
            child: PanelCollapsible(
              initiallyOpen: true,
              title: Text('What is included'),
              child: Text('Storage'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final section = tester.getRect(find.byType(PanelCollapsible));
      final title = tester.getRect(find.text('What is included'));
      final body = tester.getRect(find.text('Storage'));
      // Inset 4pt, the same as the header's title.
      expect(body.left, title.left);
      expect(body.left - section.left, 4);
    });

    testWidgets('a controlled collapsible follows its value', (tester) async {
      final reported = <bool>[];
      await tester.pumpWidget(
        wrap(collapsible(open: false, onOpenChanged: reported.add)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('What is included'));
      await tester.pumpAndSettle();
      expect(reported, [true]);
      final closed = tester.getSize(find.byType(PanelCollapsible));

      await tester.pumpWidget(wrap(collapsible(open: true)));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(PanelCollapsible)).height,
        greaterThan(closed.height),
      );
    });

    testWidgets('a disabled collapsible ignores presses', (tester) async {
      final reported = <bool>[];
      await tester.pumpWidget(
        wrap(collapsible(enabled: false, onOpenChanged: reported.add)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('What is included'));
      await tester.pumpAndSettle();
      expect(reported, isEmpty);
    });

    testWidgets('announces its state and hides a closed body', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(collapsible()));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(_header('What is included')),
        isSemantics(hasExpandedState: true, isExpanded: false),
      );
      expect(find.bySemanticsLabel('Count 0'), findsNothing);

      await tester.tap(find.text('What is included'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(_header('What is included')),
        isSemantics(hasExpandedState: true, isExpanded: true),
      );
      expect(find.bySemanticsLabel('Count 0'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an open body is not clipped', (tester) async {
      await tester.pumpWidget(wrap(collapsible()));
      await tester.pumpAndSettle();
      ClipRect clip() => tester.widget<ClipRect>(
        find
            .ancestor(
              of: find.text('Count 0', skipOffstage: false),
              matching: find.byType(ClipRect),
            )
            .first,
      );
      expect(clip().clipBehavior, Clip.hardEdge);
      await tester.tap(find.text('What is included'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(clip().clipBehavior, Clip.hardEdge);
      await tester.pumpAndSettle();
      // Settled open, the body draws as it would anywhere else.
      expect(clip().clipBehavior, Clip.none);
    });

    testWidgets('with reduced motion it snaps open', (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: collapsible(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final closed = tester.getSize(find.byType(PanelCollapsible));
      await tester.tap(find.text('What is included'));
      await tester.pump();
      final open = tester.getSize(find.byType(PanelCollapsible));
      expect(open.height, greaterThan(closed.height));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
