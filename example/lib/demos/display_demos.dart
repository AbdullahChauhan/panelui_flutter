import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../gallery/gallery.dart';

/// Demos for buttons, badges, cards, typography, alerts, surfaces, meters,
/// loading states and empty states.
final List<GalleryDemo> displayDemos = [
  GalleryDemo(
    id: 'button',
    title: 'Button',
    description:
        'Six variants and six sizes, with icons, a loading state and press '
        'feedback that springs back on release.',
    builder: (_) => const _ButtonDemo(),
  ),
  GalleryDemo(
    id: 'button-group',
    title: 'Button Group',
    description:
        'A run of buttons that reads as one control: joined into one shape, '
        'or spaced apart.',
    builder: (_) => const _ButtonGroupDemo(),
  ),
  GalleryDemo(
    id: 'badge',
    title: 'Badge',
    description: 'A small status label, count or dot.',
    builder: (_) => const _BadgeDemo(),
  ),
  GalleryDemo(
    id: 'card',
    title: 'Card',
    description:
        'A content surface with a header, content and a plain or panel footer.',
    builder: (_) => const _CardDemo(),
  ),
  GalleryDemo(
    id: 'typography',
    title: 'Typography',
    description:
        'Headings, lead and body text, blockquotes, inline code and lists, '
        'on the type scale the components use.',
    builder: (_) => const _TypographyDemo(),
  ),
  GalleryDemo(
    id: 'alert',
    title: 'Alert',
    description: 'A status message whose icon and colour follow its variant.',
    builder: (_) => const _AlertDemo(),
  ),
  GalleryDemo(
    id: 'surface',
    title: 'Surface and Separator',
    description:
        'The elevation ladder: each step one level further from the '
        'background. Hairlines divide content.',
    builder: (_) => const _SurfaceDemo(),
  ),
  GalleryDemo(
    id: 'meter',
    title: 'Meter and Scroll Fade',
    description:
        'Readings on a fixed scale whose colour is a judgement, as a bar or '
        'in blocks; and edges that fade where there is more to scroll.',
    builder: (_) => const _MeterDemo(),
  ),
  GalleryDemo(
    id: 'loading',
    title: 'Spinner and Skeleton',
    description:
        'Indicators for work of unknown length, and placeholders for content '
        'that has not arrived.',
    builder: (_) => const _LoadingDemo(),
  ),
  GalleryDemo(
    id: 'empty-state',
    title: 'Empty State',
    description: 'The placeholder for a list or a view with nothing in it.',
    builder: (_) => const _EmptyStateDemo(),
  ),
];

class _ButtonDemo extends StatefulWidget {
  const _ButtonDemo();

  @override
  State<_ButtonDemo> createState() => _ButtonDemoState();
}

class _ButtonDemoState extends State<_ButtonDemo> {
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Variants',
          children: [
            PanelButton(onPressed: noop, child: const Text('Primary')),
            PanelButton(
              variant: PanelButtonVariant.secondary,
              onPressed: noop,
              child: const Text('Secondary'),
            ),
            PanelButton(
              variant: PanelButtonVariant.outline,
              onPressed: noop,
              child: const Text('Outline'),
            ),
            PanelButton(
              variant: PanelButtonVariant.ghost,
              onPressed: noop,
              child: const Text('Ghost'),
            ),
            PanelButton(
              variant: PanelButtonVariant.destructive,
              onPressed: noop,
              child: const Text('Delete'),
            ),
          ],
        ),
        DemoGroup(
          label: 'Sizes',
          children: [
            for (final size in [
              PanelButtonSize.xs,
              PanelButtonSize.sm,
              PanelButtonSize.md,
              PanelButtonSize.lg,
              PanelButtonSize.xl,
            ])
              PanelButton(
                size: size,
                variant: PanelButtonVariant.outline,
                onPressed: noop,
                child: Text(size.name),
              ),
            PanelButton(
              size: PanelButtonSize.icon,
              variant: PanelButtonVariant.outline,
              semanticLabel: 'Add',
              onPressed: noop,
              child: const PanelIcon(PanelIcons.plus),
            ),
          ],
        ),
        DemoGroup(
          label: 'With icons, loading and disabled',
          children: [
            PanelButton(
              leading: const PanelIcon(PanelIcons.plus),
              onPressed: noop,
              child: const Text('New project'),
            ),
            PanelButton(
              variant: PanelButtonVariant.secondary,
              trailing: const PanelIcon(PanelIcons.chevronRight),
              onPressed: noop,
              child: const Text('Continue'),
            ),
            PanelButton(
              loading: _loading,
              onPressed: _save,
              child: Text(_loading ? 'Saving' : 'Save changes'),
            ),
            const PanelButton(onPressed: null, child: Text('Disabled')),
          ],
        ),
        SizedBox(
          width: 360,
          child: PanelButton(
            variant: PanelButtonVariant.social,
            fullWidth: true,
            leading: const PanelIcon(PanelIcons.mail),
            onPressed: noop,
            child: const Text('Continue with email'),
          ),
        ),
      ],
    );
  }
}

class _ButtonGroupDemo extends StatefulWidget {
  const _ButtonGroupDemo();

  @override
  State<_ButtonGroupDemo> createState() => _ButtonGroupDemoState();
}

class _ButtonGroupDemoState extends State<_ButtonGroupDemo> {
  String _range = 'Week';

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Attached',
          children: [
            PanelButtonGroup(
              variant: PanelButtonVariant.ghost,
              size: PanelButtonSize.sm,
              children: [
                for (final range in ['Day', 'Week', 'Month'])
                  PanelButton(
                    variant: range == _range
                        ? PanelButtonVariant.secondary
                        : null,
                    onPressed: () => setState(() => _range = range),
                    child: Text(range),
                  ),
              ],
            ),
            PanelButtonGroup(
              variant: PanelButtonVariant.ghost,
              size: PanelButtonSize.sm,
              children: [
                PanelButton(
                  size: PanelButtonSize.sm,
                  semanticLabel: 'Bold',
                  onPressed: noop,
                  child: const PanelIcon(PanelIcons.bold),
                ),
                PanelButton(
                  semanticLabel: 'Italic',
                  onPressed: noop,
                  child: const PanelIcon(PanelIcons.italic),
                ),
                PanelButton(
                  semanticLabel: 'Code',
                  onPressed: noop,
                  child: const PanelIcon(PanelIcons.code),
                ),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Spaced',
          children: [
            PanelButtonGroup(
              attached: false,
              variant: PanelButtonVariant.outline,
              size: PanelButtonSize.sm,
              children: [
                PanelButton(onPressed: noop, child: const Text('Archive')),
                PanelButton(onPressed: noop, child: const Text('Report')),
                PanelButton(
                  variant: PanelButtonVariant.destructive,
                  onPressed: noop,
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _BadgeDemo extends StatelessWidget {
  const _BadgeDemo();

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Variants',
          children: [
            for (final variant in PanelBadgeVariant.values)
              PanelBadge(variant: variant, child: Text(variant.name)),
          ],
        ),
        DemoGroup(
          label: 'Sizes',
          children: [
            for (final size in PanelBadgeSize.values)
              PanelBadge(
                size: size,
                variant: PanelBadgeVariant.secondary,
                child: Text(size.name),
              ),
          ],
        ),
        const DemoGroup(
          label: 'Counts and dots',
          children: [
            PanelBadge.count(3),
            PanelBadge.count(42, variant: PanelBadgeVariant.destructive),
            PanelBadge.count(128, variant: PanelBadgeVariant.secondary),
            PanelBadge.dot(variant: PanelBadgeVariant.success),
            PanelBadge.dot(variant: PanelBadgeVariant.warning),
            PanelBadge.dot(variant: PanelBadgeVariant.destructive),
          ],
        ),
      ],
    );
  }
}

class _CardDemo extends StatelessWidget {
  const _CardDemo();

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        SizedBox(
          width: 340,
          child: PanelCard(
            children: [
              const PanelCardHeader(
                title: Text('Create project'),
                description: Text('Deploy your new project in one click.'),
              ),
              const PanelCardContent(
                child: Column(
                  spacing: 16,
                  children: [
                    PanelInput(label: 'Name', placeholder: 'My project'),
                    PanelInput(
                      label: 'Framework',
                      placeholder: 'Flutter',
                      variant: PanelInputVariant.filled,
                    ),
                  ],
                ),
              ),
              PanelCardFooter(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PanelButton(
                    variant: PanelButtonVariant.ghost,
                    size: PanelButtonSize.sm,
                    onPressed: noop,
                    child: const Text('Cancel'),
                  ),
                  PanelButton(
                    size: PanelButtonSize.sm,
                    onPressed: noop,
                    child: const Text('Deploy'),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: 340,
          child: PanelCard(
            children: [
              PanelCardHeader(
                title: const Text('Team plan'),
                description: const Text('Billed annually · renews 1 Mar'),
                trailing: const PanelBadge(
                  variant: PanelBadgeVariant.success,
                  child: Text('Active'),
                ),
              ),
              PanelCardContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    PanelText(
                      r'$1,248.00',
                      size: PanelTextSize.xxxl,
                      weight: FontWeight.w600,
                    ),
                    const PanelText(
                      '12 seats · 3 available',
                      size: PanelTextSize.sm,
                      muted: true,
                    ),
                  ],
                ),
              ),
              PanelCardFooter(
                variant: PanelCardFooterVariant.panel,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PanelButton(
                    variant: PanelButtonVariant.outline,
                    size: PanelButtonSize.sm,
                    onPressed: noop,
                    child: const Text('Manage seats'),
                  ),
                  PanelButton(
                    size: PanelButtonSize.sm,
                    onPressed: noop,
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypographyDemo extends StatelessWidget {
  const _TypographyDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        PanelText.h1('The Joke Tax Chronicles'),
        PanelText.lead(
          'Once upon a time, in a far-off land, there was a very lazy king '
          'who spent all day lounging on his throne.',
        ),
        PanelText.h3('The King\'s Plan'),
        PanelText(
          'He came up with a brilliant plan: he would tax the jokes in the '
          'kingdom.',
        ),
        PanelBlockquote(
          child: Text(
            '"After all," he said, "everyone enjoys a good joke, so it\'s '
            'only fair that they should pay for the privilege."',
          ),
        ),
        PanelText.h4('The Joke Tax'),
        PanelList(
          items: [
            Text('1st level of puns: 5 gold coins'),
            Text('2nd level of jokes: 10 gold coins'),
            Text('3rd level of one-liners: 20 gold coins'),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            PanelText.small('Install with'),
            PanelCode('flutter pub add panelui_flutter'),
          ],
        ),
      ],
    );
  }
}

class _AlertDemo extends StatelessWidget {
  const _AlertDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      spacing: 12,
      children: [
        PanelAlert(
          title: Text('Heads up'),
          description: Text('You can add components to your app with the CLI.'),
        ),
        PanelAlert(
          variant: PanelAlertVariant.info,
          title: Text('Update available'),
          description: Text('Version 1.2 adds three new chart types.'),
        ),
        PanelAlert(
          variant: PanelAlertVariant.success,
          title: Text('Payment received'),
          description: Text('Your invoice has been sent to your inbox.'),
        ),
        PanelAlert(
          variant: PanelAlertVariant.warning,
          title: Text('Your trial ends in 3 days'),
          description: Text('Add a payment method to keep your projects.'),
        ),
        PanelAlert(
          variant: PanelAlertVariant.destructive,
          title: Text('Deployment failed'),
          description: Text('The build exited with code 1. Check the logs.'),
        ),
      ],
    );
  }
}

class _SurfaceDemo extends StatelessWidget {
  const _SurfaceDemo();

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        const PanelSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              PanelText('Surface', size: PanelTextSize.sm, muted: true),
              PanelSurface(
                variant: PanelSurfaceVariant.secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    PanelText('Secondary', size: PanelTextSize.sm, muted: true),
                    PanelSurface(
                      variant: PanelSurfaceVariant.tertiary,
                      child: PanelText(
                        'Tertiary',
                        size: PanelTextSize.sm,
                        muted: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PanelSeparator(label: Text('or continue with')),
        IntrinsicHeight(
          child: Row(
            spacing: 16,
            children: [
              const PanelText('Blog', size: PanelTextSize.sm),
              const PanelSeparator(orientation: Axis.vertical),
              const PanelText('Docs', size: PanelTextSize.sm),
              const PanelSeparator(orientation: Axis.vertical),
              const PanelText('Source', size: PanelTextSize.sm),
            ],
          ),
        ),
      ],
    );
  }
}

class _MeterDemo extends StatefulWidget {
  const _MeterDemo();

  @override
  State<_MeterDemo> createState() => _MeterDemoState();
}

class _MeterDemoState extends State<_MeterDemo> {
  double _storage = 212;

  static const _storageThresholds = [
    PanelMeterThreshold(from: 192, color: PanelMeterColor.warning),
    PanelMeterThreshold(from: 240, color: PanelMeterColor.destructive),
  ];

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        SizedBox(
          width: 420,
          child: Column(
            spacing: 20,
            children: [
              PanelMeter(
                label: 'Storage',
                value: _storage,
                max: 256,
                valueLabel: '${_storage.round()} of 256 GB',
                thresholds: _storageThresholds,
              ),
              const PanelMeter(
                label: 'Battery',
                value: 18,
                color: PanelMeterColor.success,
                thresholds: [
                  PanelMeterThreshold(
                    from: 0,
                    color: PanelMeterColor.destructive,
                  ),
                  PanelMeterThreshold(from: 20, color: PanelMeterColor.success),
                ],
              ),
              const PanelMeter(
                label: 'Password strength',
                value: 3,
                max: 4,
                segments: 4,
                valueLabel: 'Strong',
                color: PanelMeterColor.success,
              ),
              Row(
                spacing: 8,
                children: [
                  for (final gb in [64.0, 212.0, 248.0])
                    PanelButton(
                      size: PanelButtonSize.xs,
                      variant: PanelButtonVariant.outline,
                      onPressed: () => setState(() => _storage = gb),
                      child: Text('${gb.round()} GB'),
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: PanelScrollFade(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 16,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Center(
                child: PanelBadge(
                  variant: PanelBadgeVariant.secondary,
                  size: PanelBadgeSize.lg,
                  child: Text(
                    const [
                      'Design',
                      'Engineering',
                      'Marketing',
                      'Sales',
                      'Support',
                      'Finance',
                      'Legal',
                      'Research',
                    ][i % 8],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingDemo extends StatelessWidget {
  const _LoadingDemo();

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        const DemoGroup(
          label: 'Spinner',
          children: [
            PanelSpinner(size: PanelSpinnerSize.sm),
            PanelSpinner(),
            PanelSpinner(size: PanelSpinnerSize.lg),
          ],
        ),
        DemoGroup(
          label: 'Skeleton',
          children: [
            SizedBox(
              width: 320,
              child: Row(
                spacing: 12,
                children: [
                  const PanelSkeleton.circle(size: 40),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: const [
                        PanelSkeleton(width: 180, height: 14),
                        PanelSkeleton(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyStateDemo extends StatelessWidget {
  const _EmptyStateDemo();

  @override
  Widget build(BuildContext context) {
    return PanelEmptyState(
      variant: PanelEmptyStateVariant.card,
      icon: const PanelIcon(PanelIcons.folder),
      title: const Text('No projects yet'),
      description: const Text(
        'Create your first project to start deploying. It takes a minute.',
      ),
      action: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          PanelButton(
            size: PanelButtonSize.sm,
            onPressed: () {},
            child: const Text('New project'),
          ),
          PanelButton(
            size: PanelButtonSize.sm,
            variant: PanelButtonVariant.outline,
            onPressed: () {},
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
