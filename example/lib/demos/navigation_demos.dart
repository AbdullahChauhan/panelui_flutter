import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../gallery/gallery.dart';

/// Demos for the navigation and disclosure components: tabs, accordion,
/// collapsible, breadcrumb, pagination, steps and item.
final List<GalleryDemo> navigationDemos = [
  GalleryDemo(
    id: 'tabs',
    title: 'Tabs',
    description:
        'Segmented navigation between panels. One indicator springs from tab '
        'to tab, so a switch two tabs away reads as a single movement.',
    builder: (_) => const _TabsDemo(),
  ),
  GalleryDemo(
    id: 'tabs-sizes',
    title: 'Tab sizes',
    description:
        'Five sizes, from a row inside a card to the main navigation of a '
        'screen.',
    builder: (_) => const _TabSizesDemo(),
  ),
  GalleryDemo(
    id: 'tabs-scrollable',
    title: 'Scrollable and swipeable tabs',
    description:
        'More tabs than fit keep their natural widths and scroll the selected '
        'one into view. Swipeable panels sit side by side and follow a drag.',
    builder: (_) => const _ScrollableTabsDemo(),
  ),
  GalleryDemo(
    id: 'tabs-expanding',
    title: 'Expanding tabs',
    description:
        'Icon pills where only the selected one opens to show its label, '
        'over panels that slide in from the side they belong on.',
    builder: (_) => const _ExpandingTabsDemo(),
  ),
  GalleryDemo(
    id: 'accordion',
    title: 'Accordion',
    description:
        'Collapsible sections, one or several open at a time. The section '
        'grows to its height while the chevron turns.',
    builder: (_) => const _AccordionDemo(),
  ),
  GalleryDemo(
    id: 'collapsible',
    title: 'Collapsible',
    description:
        'One section shown and hidden by its own header. The body stays '
        'built, so what is inside survives being closed.',
    builder: (_) => const _CollapsibleDemo(),
  ),
  GalleryDemo(
    id: 'breadcrumb',
    title: 'Breadcrumb',
    description: 'The trail back up to the current page.',
    builder: (_) => const _BreadcrumbDemo(),
  ),
  GalleryDemo(
    id: 'pagination',
    title: 'Pagination',
    description:
        'Moving through a result set one page at a time: the full run, '
        'a compact summary, or labelled steps.',
    builder: (_) => const _PaginationDemo(),
  ),
  GalleryDemo(
    id: 'steps',
    title: 'Steps',
    description:
        'A stepper for multi-step flows. Each step works out whether it is '
        'done, current or still to come.',
    builder: (_) => const _StepsDemo(),
  ),
  GalleryDemo(
    id: 'item',
    title: 'Item',
    description:
        'A row of media, text and actions: the shape of a settings row, a '
        'file in a picker or a member of a team.',
    builder: (_) => const _ItemDemo(),
  ),
];

/// A padded card for the body of a demo panel.
class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// Initials in a circle, standing in for an avatar.
class _Initials extends StatelessWidget {
  const _Initials(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = PanelTheme.of(context).colors;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
      child: PanelText(text, size: PanelTextSize.sm, weight: FontWeight.w500),
    );
  }
}

class _TabsDemo extends StatelessWidget {
  const _TabsDemo();

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Segmented',
          children: [
            PanelTabs<String>(
              initialValue: 'account',
              children: [
                const PanelTabsList(
                  children: [
                    PanelTabsTrigger(value: 'account', child: Text('Account')),
                    PanelTabsTrigger(
                      value: 'password',
                      child: Text('Password'),
                    ),
                    PanelTabsTrigger(value: 'team', child: Text('Team')),
                  ],
                ),
                const PanelTabsContent(
                  value: 'account',
                  child: _PanelCard(
                    children: [
                      PanelInput(label: 'Name', placeholder: 'Khalid Abdi'),
                      PanelInput(label: 'Username', placeholder: '@khalid'),
                    ],
                  ),
                ),
                const PanelTabsContent(
                  value: 'password',
                  child: _PanelCard(
                    children: [
                      PanelInput(label: 'Current password', obscureText: true),
                      PanelInput(label: 'New password', obscureText: true),
                    ],
                  ),
                ),
                PanelTabsContent(
                  value: 'team',
                  child: _PanelCard(
                    children: [
                      Row(
                        spacing: 12,
                        children: [
                          const _Initials('KA'),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PanelText(
                                  'Khalid Abdi',
                                  weight: FontWeight.w500,
                                ),
                                PanelText(
                                  'Owner',
                                  size: PanelTextSize.sm,
                                  muted: true,
                                ),
                              ],
                            ),
                          ),
                          const PanelBadge(
                            variant: PanelBadgeVariant.secondary,
                            child: Text('Admin'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const DemoGroup(
          label: 'Underline, with a badge and a disabled tab',
          children: [
            PanelTabs<String>(
              variant: PanelTabsVariant.underline,
              initialValue: 'overview',
              children: [
                PanelTabsList(
                  children: [
                    PanelTabsTrigger(
                      value: 'overview',
                      child: Text('Overview'),
                    ),
                    PanelTabsTrigger(
                      value: 'activity',
                      badge: PanelBadge.count(
                        4,
                        variant: PanelBadgeVariant.secondary,
                      ),
                      child: Text('Activity'),
                    ),
                    PanelTabsTrigger(
                      value: 'archived',
                      enabled: false,
                      child: Text('Archived'),
                    ),
                  ],
                ),
                PanelTabsContent(
                  value: 'overview',
                  child: PanelText(
                    'A rule under the active tab, on a row that has no track '
                    'of its own: for a page-level switch rather than a '
                    'control.',
                    size: PanelTextSize.sm,
                    muted: true,
                  ),
                ),
                PanelTabsContent(
                  value: 'activity',
                  child: PanelText(
                    'Four things happened while you were away.',
                    size: PanelTextSize.sm,
                    muted: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        const DemoGroup(
          label: 'Pill',
          children: [
            PanelTabs<String>(
              variant: PanelTabsVariant.pill,
              initialValue: 'all',
              children: [
                PanelTabsList(
                  children: [
                    PanelTabsTrigger(value: 'all', child: Text('All')),
                    PanelTabsTrigger(value: 'unread', child: Text('Unread')),
                    PanelTabsTrigger(value: 'flagged', child: Text('Flagged')),
                  ],
                ),
                PanelTabsContent(
                  value: 'all',
                  child: PanelText(
                    'A filled chip on the page, with the active label '
                    'inverted against it.',
                    size: PanelTextSize.sm,
                    muted: true,
                  ),
                ),
                PanelTabsContent(
                  value: 'unread',
                  child: PanelText(
                    'Nothing unread.',
                    size: PanelTextSize.sm,
                    muted: true,
                  ),
                ),
                PanelTabsContent(
                  value: 'flagged',
                  child: PanelText(
                    'Nothing flagged.',
                    size: PanelTextSize.sm,
                    muted: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        const DemoGroup(label: 'Custom colours', children: [_CustomTabs()]),
      ],
    );
  }
}

class _CustomTabs extends StatelessWidget {
  const _CustomTabs();

  @override
  Widget build(BuildContext context) {
    final c = PanelTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        PanelTabs<String>(
          initialValue: 'week',
          children: [
            PanelTabsList(
              indicatorColor: c.primary,
              children: [
                for (final name in ['Day', 'Week', 'Month'])
                  PanelTabsTrigger(
                    value: name.toLowerCase(),
                    activeLabelColor: c.primaryForeground,
                    child: Text(name),
                  ),
              ],
            ),
          ],
        ),
        PanelTabs<String>(
          variant: PanelTabsVariant.underline,
          initialValue: 'open',
          children: [
            PanelTabsList(
              indicatorColor: c.success,
              indicatorThickness: 4,
              children: [
                for (final name in ['Open', 'Merged', 'Closed'])
                  PanelTabsTrigger(
                    value: name.toLowerCase(),
                    activeLabelColor: c.successForeground,
                    child: Text(name),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _TabSizesDemo extends StatelessWidget {
  const _TabSizesDemo();

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      spacing: 20,
      children: [
        for (final size in PanelTabsSize.values)
          DemoGroup(
            label: size.name,
            children: [
              PanelTabs<String>(
                size: size,
                initialValue: 'week',
                children: const [
                  PanelTabsList(
                    children: [
                      PanelTabsTrigger(value: 'day', child: Text('Day')),
                      PanelTabsTrigger(value: 'week', child: Text('Week')),
                      PanelTabsTrigger(value: 'month', child: Text('Month')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        DemoGroup(
          label: 'Underline and pill, small',
          children: [
            for (final variant in [
              PanelTabsVariant.underline,
              PanelTabsVariant.pill,
            ])
              PanelTabs<String>(
                size: PanelTabsSize.sm,
                variant: variant,
                initialValue: 'week',
                children: const [
                  PanelTabsList(
                    children: [
                      PanelTabsTrigger(value: 'day', child: Text('Day')),
                      PanelTabsTrigger(value: 'week', child: Text('Week')),
                      PanelTabsTrigger(value: 'month', child: Text('Month')),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

const _sections = [
  'Overview',
  'Activity',
  'Members',
  'Billing',
  'Integrations',
  'Security',
  'Audit log',
];

const _days = [
  ('mon', 'Mon', 'Two runs and a swim. 14km total.'),
  ('tue', 'Tue', 'Rest day. Nothing logged.'),
  ('wed', 'Wed', 'One long ride, 62km, out to the coast.'),
  ('thu', 'Thu', 'Intervals: 8 × 400m on the track.'),
];

class _ScrollableTabsDemo extends StatelessWidget {
  const _ScrollableTabsDemo();

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Scrollable',
          children: [
            PanelTabs<String>(
              variant: PanelTabsVariant.underline,
              initialValue: 'Overview',
              children: [
                PanelTabsList(
                  scrollable: true,
                  children: [
                    for (final section in _sections)
                      PanelTabsTrigger(value: section, child: Text(section)),
                  ],
                ),
                for (final section in _sections)
                  PanelTabsContent(
                    value: section,
                    child: PanelText(
                      '$section settings for the workspace.',
                      size: PanelTextSize.sm,
                      muted: true,
                    ),
                  ),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Swipe between panels',
          children: [
            PanelTabs<String>(
              swipeable: true,
              initialValue: 'mon',
              children: [
                PanelTabsList(
                  children: [
                    for (final (value, label, _) in _days)
                      PanelTabsTrigger(value: value, child: Text(label)),
                  ],
                ),
                for (final (value, label, body) in _days)
                  PanelTabsContent(
                    value: value,
                    child: _PanelCard(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            PanelText(label, weight: FontWeight.w500),
                            PanelText(
                              body,
                              size: PanelTextSize.sm,
                              muted: true,
                            ),
                            const PanelText(
                              'Swipe left or right on this card.',
                              size: PanelTextSize.xs,
                              muted: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        const DemoGroup(
          label: 'Keeping panels mounted',
          children: [_KeepMountedTabs()],
        ),
      ],
    );
  }
}

class _KeepMountedTabs extends StatelessWidget {
  const _KeepMountedTabs();

  @override
  Widget build(BuildContext context) {
    return const PanelTabs<String>(
      keepMounted: true,
      initialValue: 'draft',
      children: [
        PanelTabsList(
          children: [
            PanelTabsTrigger(value: 'draft', child: Text('Draft')),
            PanelTabsTrigger(value: 'settings', child: Text('Settings')),
          ],
        ),
        PanelTabsContent(
          value: 'draft',
          child: _PanelCard(
            children: [
              PanelInput(
                label: 'Title',
                placeholder: 'Type something, then switch tab',
              ),
              PanelText(
                'This panel stays mounted, so what you type survives the '
                'switch.',
                size: PanelTextSize.xs,
                muted: true,
              ),
            ],
          ),
        ),
        PanelTabsContent(
          value: 'settings',
          child: _PanelCard(
            children: [
              PanelText(
                'Switch back to Draft: the title you typed is still there.',
                size: PanelTextSize.sm,
                muted: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _destinations = [
  (
    'home',
    'Home',
    PanelIcons.package,
    'Everything that changed since you were last here.',
  ),
  (
    'chats',
    'Chats',
    PanelIcons.messageCircle,
    'Four threads, two of them waiting on you.',
  ),
  (
    'calendar',
    'Calendar',
    PanelIcons.calendar,
    'Nothing until Thursday, and then rather a lot.',
  ),
  ('inbox', 'Inbox', PanelIcons.bell, 'Three notifications, none urgent.'),
];

class _ExpandingTabsDemo extends StatelessWidget {
  const _ExpandingTabsDemo();

  @override
  Widget build(BuildContext context) {
    return PanelTabs<String>(
      variant: PanelTabsVariant.expanding,
      swipeable: true,
      initialValue: 'chats',
      children: [
        PanelTabsList(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (value, label, icon, _) in _destinations)
              PanelTabsTrigger(
                value: value,
                icon: PanelIcon(icon, size: 18),
                child: Text(label),
              ),
          ],
        ),
        for (final (value, label, _, body) in _destinations)
          PanelTabsContent(
            value: value,
            child: _PanelCard(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    PanelText(label, weight: FontWeight.w500),
                    PanelText(body, size: PanelTextSize.sm, muted: true),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

const _faq = [
  (
    'shipping',
    'How long does shipping take?',
    'Standard delivery arrives in three to five working days.',
  ),
  (
    'returns',
    'What is your returns policy?',
    'Send anything back within 30 days for a full refund.',
  ),
  (
    'support',
    'How do I contact support?',
    'Reply to your order email and a person will answer.',
  ),
];

class _AccordionDemo extends StatefulWidget {
  const _AccordionDemo();

  @override
  State<_AccordionDemo> createState() => _AccordionDemoState();
}

class _AccordionDemoState extends State<_AccordionDemo> {
  PanelAccordionVariant _variant = PanelAccordionVariant.surface;

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Variants',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                PanelTabs<PanelAccordionVariant>(
                  size: PanelTabsSize.sm,
                  value: _variant,
                  onChanged: (v) => setState(() => _variant = v),
                  children: [
                    PanelTabsList(
                      children: [
                        for (final variant in PanelAccordionVariant.values)
                          PanelTabsTrigger(
                            value: variant,
                            child: Text(variant.name),
                          ),
                      ],
                    ),
                  ],
                ),
                PanelAccordion<String>(
                  key: ValueKey(_variant),
                  variant: _variant,
                  initialValue: const {'shipping'},
                  children: [
                    for (final (value, question, answer) in _faq)
                      PanelAccordionItem(
                        value: value,
                        title: Text(question),
                        child: Text(answer),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Several open at once',
          children: [
            PanelAccordion<String>(
              variant: PanelAccordionVariant.separated,
              selectionMode: PanelAccordionSelectionMode.multiple,
              initialValue: const {'shipping', 'returns'},
              children: [
                for (final (value, question, answer) in _faq)
                  PanelAccordionItem(
                    value: value,
                    title: Text(question),
                    child: Text(answer),
                  ),
              ],
            ),
          ],
        ),
        const DemoGroup(
          label: 'Keeps its state',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                PanelAccordion<String>(
                  variant: PanelAccordionVariant.surface,
                  keepMounted: true,
                  initialValue: {'note'},
                  children: [
                    PanelAccordionItem(
                      value: 'note',
                      title: Text('Delivery note'),
                      child: PanelTextarea(
                        placeholder: 'Leave it with a neighbour…',
                      ),
                    ),
                    PanelAccordionItem(
                      value: 'gift',
                      title: Text('Gift message'),
                      child: PanelTextarea(placeholder: 'Happy birthday…'),
                    ),
                  ],
                ),
                PanelText(
                  'Type into a field, collapse the section, then open it '
                  'again.',
                  size: PanelTextSize.xs,
                  muted: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _CollapsibleDemo extends StatefulWidget {
  const _CollapsibleDemo();

  @override
  State<_CollapsibleDemo> createState() => _CollapsibleDemoState();
}

class _CollapsibleDemoState extends State<_CollapsibleDemo> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Plain, surface and ghost',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                for (final variant in PanelCollapsibleVariant.values)
                  PanelCollapsible(
                    variant: variant,
                    initiallyOpen: variant != PanelCollapsibleVariant.ghost,
                    title: const Text('What is included'),
                    child: const Text(
                      'Unlimited projects, 100GB of storage, and email '
                      'support.',
                    ),
                  ),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Controlled',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                PanelButton(
                  variant: PanelButtonVariant.outline,
                  fullWidth: true,
                  onPressed: () => setState(() => _open = !_open),
                  child: Text(
                    _open ? 'Close it from out here' : 'Open it from out here',
                  ),
                ),
                PanelCollapsible(
                  variant: PanelCollapsibleVariant.surface,
                  open: _open,
                  onOpenChanged: (open) => setState(() => _open = open),
                  title: const Text('Billing details'),
                  child: const Text('Billed monthly, cancel any time.'),
                ),
              ],
            ),
          ],
        ),
        const DemoGroup(
          label: 'The body keeps its state',
          children: [
            PanelCollapsible(
              variant: PanelCollapsibleVariant.surface,
              title: Text('Delivery note'),
              child: PanelTextarea(placeholder: 'Leave it with a neighbour…'),
            ),
          ],
        ),
        const DemoGroup(
          label: 'Disabled',
          children: [
            PanelCollapsible(
              variant: PanelCollapsibleVariant.surface,
              enabled: false,
              title: Text('Enterprise billing'),
              child: Text('Contact sales.'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BreadcrumbDemo extends StatelessWidget {
  const _BreadcrumbDemo();

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return DemoStack(
      children: [
        DemoGroup(
          label: 'A trail',
          children: [
            PanelBreadcrumb(
              children: [
                PanelBreadcrumbLink(onPressed: noop, child: const Text('Home')),
                PanelBreadcrumbLink(
                  onPressed: noop,
                  child: const Text('Components'),
                ),
                const PanelBreadcrumbPage(child: Text('Breadcrumb')),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Custom separator',
          children: [
            PanelBreadcrumb(
              separator: const Text('/'),
              children: [
                PanelBreadcrumbLink(onPressed: noop, child: const Text('Docs')),
                PanelBreadcrumbLink(
                  onPressed: noop,
                  child: const Text('Guides'),
                ),
                const PanelBreadcrumbPage(child: Text('Theming')),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Collapsed',
          children: [
            PanelBreadcrumb(
              maxItems: 3,
              onEllipsisPressed: noop,
              children: [
                PanelBreadcrumbLink(onPressed: noop, child: const Text('Home')),
                PanelBreadcrumbLink(
                  onPressed: noop,
                  child: const Text('Library'),
                ),
                PanelBreadcrumbLink(
                  onPressed: noop,
                  child: const Text('Components'),
                ),
                const PanelBreadcrumbPage(child: Text('Breadcrumb')),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Dense header',
          children: [
            PanelBreadcrumb(
              size: PanelBreadcrumbSize.sm,
              children: [
                PanelBreadcrumbLink(
                  onPressed: noop,
                  child: const Text('Settings'),
                ),
                const PanelBreadcrumbPage(child: Text('Billing')),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _PaginationDemo extends StatefulWidget {
  const _PaginationDemo();

  @override
  State<_PaginationDemo> createState() => _PaginationDemoState();
}

class _PaginationDemoState extends State<_PaginationDemo> {
  int _page = 1;
  int _longPage = 120;

  @override
  Widget build(BuildContext context) {
    void setPage(int page) => setState(() => _page = page);
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Numbers',
          children: [
            PanelPagination(count: 12, page: _page, onChanged: setPage),
          ],
        ),
        DemoGroup(
          label: 'Compact, with a status line',
          children: [
            PanelPagination(
              count: 12,
              page: _page,
              onChanged: setPage,
              variant: PanelPaginationVariant.compact,
              leading: const PanelPaginationStatus(pageSize: 20, total: 240),
            ),
          ],
        ),
        DemoGroup(
          label: 'Simple',
          children: [
            PanelPagination(
              count: 12,
              page: _page,
              onChanged: setPage,
              variant: PanelPaginationVariant.simple,
            ),
          ],
        ),
        DemoGroup(
          label: 'Small',
          children: [
            PanelPagination(
              count: 12,
              page: _page,
              onChanged: setPage,
              size: PanelPaginationSize.sm,
            ),
          ],
        ),
        DemoGroup(
          label: 'A long set, with a wider run',
          children: [
            PanelPagination(
              count: 240,
              page: _longPage,
              siblings: 2,
              onChanged: (page) => setState(() => _longPage = page),
            ),
          ],
        ),
        const DemoGroup(
          label: 'Disabled while loading',
          children: [PanelPagination(count: 12, page: 4, enabled: false)],
        ),
      ],
    );
  }
}

const _stepData = [
  ('Account', 'Create your login'),
  ('Profile', 'Tell us about you'),
  ('Billing', 'Add a payment method'),
];

class _StepsDemo extends StatefulWidget {
  const _StepsDemo();

  @override
  State<_StepsDemo> createState() => _StepsDemoState();
}

class _StepsDemoState extends State<_StepsDemo> {
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    final (title, description) = _stepData[_step];
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Horizontal',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 24,
              children: [
                PanelSteps(
                  value: _step,
                  onChanged: (step) => setState(() => _step = step),
                  children: [for (final _ in _stepData) const PanelStep()],
                ),
                Column(
                  spacing: 4,
                  children: [
                    PanelText(title, weight: FontWeight.w500),
                    PanelText(description, size: PanelTextSize.sm, muted: true),
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: PanelButton(
                        variant: PanelButtonVariant.outline,
                        fullWidth: true,
                        onPressed: _step == 0
                            ? null
                            : () => setState(() => _step--),
                        child: const Text('Back'),
                      ),
                    ),
                    Expanded(
                      child: PanelButton(
                        fullWidth: true,
                        onPressed: _step == _stepData.length - 1
                            ? null
                            : () => setState(() => _step++),
                        child: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Vertical',
          children: [
            PanelSteps(
              initialValue: 1,
              orientation: Axis.vertical,
              onChanged: (_) {},
              children: [
                for (final (title, description) in _stepData)
                  PanelStep(title: Text(title), description: Text(description)),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Loading',
          children: [
            PanelSteps(
              value: 1,
              orientation: Axis.vertical,
              children: [
                for (var i = 0; i < _stepData.length; i++)
                  PanelStep(loading: i == 1, title: Text(_stepData[i].$1)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ItemDemo extends StatelessWidget {
  const _ItemDemo();

  @override
  Widget build(BuildContext context) {
    void noop() {}
    final c = PanelTheme.of(context).colors;
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Variants',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                for (final variant in PanelItemVariant.values)
                  PanelItem(
                    variant: variant,
                    media: const PanelItemMedia(
                      variant: PanelItemMediaVariant.icon,
                      child: PanelIcon(PanelIcons.package),
                    ),
                    title: Text(variant.name),
                    description: Text('The ${variant.name} surface treatment.'),
                    actions: const [
                      PanelBadge(
                        variant: PanelBadgeVariant.secondary,
                        child: Text('New'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Sizes',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                for (final size in PanelItemSize.values)
                  PanelItem(
                    variant: PanelItemVariant.outline,
                    size: size,
                    media: const PanelItemMedia(
                      variant: PanelItemMediaVariant.icon,
                      child: PanelIcon(PanelIcons.receipt),
                    ),
                    title: Text('Size ${size.name}'),
                    description: const Text(
                      'Media, title and description all follow it.',
                    ),
                  ),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Media',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                const PanelItem(
                  variant: PanelItemVariant.outline,
                  media: PanelItemMedia(
                    variant: PanelItemMediaVariant.icon,
                    child: PanelIcon(PanelIcons.bell),
                  ),
                  title: Text('Icon tile'),
                  description: Text('A rounded, bordered tile.'),
                ),
                PanelItem(
                  variant: PanelItemVariant.outline,
                  media: PanelItemMedia(
                    variant: PanelItemMediaVariant.image,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [c.chart2, c.chart5],
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  title: const Text('Thumbnail'),
                  description: const Text('Clipped to a rounded frame.'),
                ),
                const PanelItem(
                  variant: PanelItemVariant.outline,
                  media: _Initials('KA'),
                  title: Text('Avatar passed through'),
                  description: Text('The plain media variant adds no box.'),
                ),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'A settings group',
          children: [
            PanelCard(
              clipBehavior: Clip.antiAlias,
              children: [
                PanelItemGroup(
                  separated: true,
                  children: [
                    for (final (title, description) in [
                      ('Notifications', 'Push, email and in-app'),
                      ('Privacy', 'Who can see your activity'),
                      ('Appearance', 'Theme and text size'),
                    ])
                      PanelItem(
                        size: PanelItemSize.sm,
                        onPressed: noop,
                        title: Text(title),
                        description: Text(description),
                        actions: const [PanelIcon(PanelIcons.chevronRight)],
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'A horizontal group of cards',
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: PanelItemGroup(
                orientation: Axis.horizontal,
                children: [
                  for (final (name, price, summary) in [
                    ('Starter', r'$0', 'One project'),
                    ('Pro', r'$12', 'Unlimited projects'),
                    ('Team', r'$40', 'Shared workspaces'),
                  ])
                    SizedBox(
                      width: 192,
                      child: PanelItem(
                        orientation: Axis.vertical,
                        variant: PanelItemVariant.outline,
                        media: const PanelItemMedia(
                          variant: PanelItemMediaVariant.icon,
                          child: PanelIcon(PanelIcons.package),
                        ),
                        title: Text(name),
                        description: Text(summary),
                        footer: PanelItemFooter(
                          children: [
                            PanelText(price, weight: FontWeight.w600),
                            const PanelText(
                              'per month',
                              size: PanelTextSize.xs,
                              muted: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        DemoGroup(
          label: 'A vertical item',
          children: [
            PanelItem(
              orientation: Axis.vertical,
              variant: PanelItemVariant.outline,
              header: const PanelItemHeader(
                children: [
                  PanelBadge(
                    variant: PanelBadgeVariant.secondary,
                    child: Text('Draft'),
                  ),
                  PanelText(
                    'Updated 2h ago',
                    size: PanelTextSize.xs,
                    muted: true,
                  ),
                ],
              ),
              title: const Text('Quarterly report'),
              description: const Text(
                'Revenue, retention and headcount for Q3.',
              ),
              footer: PanelItemFooter(
                children: [
                  PanelButton(
                    size: PanelButtonSize.sm,
                    variant: PanelButtonVariant.outline,
                    onPressed: noop,
                    child: const Text('Preview'),
                  ),
                  PanelButton(
                    size: PanelButtonSize.sm,
                    onPressed: noop,
                    child: const Text('Publish'),
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoGroup(
          label: 'With a control',
          children: [_SwitchItem(onChanged: (_) {})],
        ),
      ],
    );
  }
}

class _SwitchItem extends StatefulWidget {
  const _SwitchItem({required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  State<_SwitchItem> createState() => _SwitchItemState();
}

class _SwitchItemState extends State<_SwitchItem> {
  bool _on = true;

  void _set(bool value) {
    setState(() => _on = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return PanelItem(
      variant: PanelItemVariant.muted,
      media: const PanelItemMedia(
        variant: PanelItemMediaVariant.icon,
        child: PanelIcon(PanelIcons.bell),
      ),
      title: const Text('Push notifications'),
      description: const Text('Mentions, replies and reminders.'),
      onPressed: () => _set(!_on),
      actions: [
        PanelSwitch(
          value: _on,
          onChanged: _set,
          semanticLabel: 'Push notifications',
        ),
      ],
    );
  }
}
