import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../gallery/gallery.dart';

final List<GalleryDemo> coreDemos = [
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
    id: 'input',
    title: 'Input and Textarea',
    description:
        'Text fields with a label, a description or an error, and a border '
        'that crosses to the focus colour over 150ms.',
    builder: (_) => const _InputDemo(),
  ),
  GalleryDemo(
    id: 'switch-checkbox',
    title: 'Switch and Checkbox',
    description:
        'Toggles that spring into place: a switch thumb across its track, a '
        'checkbox fill in from 60% scale.',
    builder: (_) => const _ToggleDemo(),
  ),
  GalleryDemo(
    id: 'field',
    title: 'Field',
    description:
        'Settings rows with the label beside the control, and groups of '
        'fields under a legend, with validation messages.',
    builder: (_) => const _FieldDemo(),
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
    id: 'theme-selector',
    title: 'Theme Selector',
    description:
        'Light, dark or the device setting, as miniatures of a screen. Pick '
        'one here and the whole gallery follows.',
    builder: (_) => const _ThemeSelectorDemo(),
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

class _InputDemo extends StatelessWidget {
  const _InputDemo();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        SizedBox(
          width: 320,
          child: Column(
            spacing: 20,
            children: [
              const PanelInput(
                label: 'Email',
                placeholder: 'you@example.com',
                isRequired: true,
                description: 'We never share your address.',
                keyboardType: TextInputType.emailAddress,
              ),
              const PanelInput(
                placeholder: 'Search components',
                leading: PanelIcon(PanelIcons.search),
                size: PanelInputSize.sm,
              ),
              PanelInput(
                label: 'Username',
                placeholder: 'panel',
                errorMessage: 'That username is taken.',
                controller: TextEditingController(text: 'panel'),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 320,
          child: Column(
            spacing: 20,
            children: [
              PanelInput(
                label: 'Workspace',
                placeholder: 'acme',
                variant: PanelInputVariant.filled,
              ),
              PanelInput(
                label: 'API key',
                placeholder: 'Generated on save',
                enabled: false,
              ),
              PanelTextarea(
                label: 'Bio',
                placeholder: 'Tell us a little about yourself',
                showCount: true,
                maxLength: 160,
                rows: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleDemo extends StatefulWidget {
  const _ToggleDemo();

  @override
  State<_ToggleDemo> createState() => _ToggleDemoState();
}

class _ToggleDemoState extends State<_ToggleDemo> {
  bool _wifi = true;
  bool _bluetooth = false;
  final _sizes = {for (final s in PanelSwitchSize.values) s: true};
  bool _terms = true;
  bool _marketing = false;
  final _tasks = [true, false, true];
  String _plan = 'pro';

  @override
  Widget build(BuildContext context) {
    final allTasks = _tasks.every((t) => t);
    final someTasks = _tasks.any((t) => t);
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Switch',
          children: [
            PanelSwitch(
              value: _wifi,
              semanticLabel: 'Wi-Fi',
              onChanged: (v) => setState(() => _wifi = v),
            ),
            PanelSwitch(
              value: _bluetooth,
              semanticLabel: 'Bluetooth',
              onChanged: (v) => setState(() => _bluetooth = v),
            ),
            const PanelSwitch(value: true, onChanged: null),
            const PanelSwitch(value: false, onChanged: null),
          ],
        ),
        DemoGroup(
          label: 'Switch sizes',
          children: [
            for (final size in PanelSwitchSize.values)
              PanelSwitch(
                size: size,
                value: _sizes[size]!,
                onChanged: (v) => setState(() => _sizes[size] = v),
              ),
          ],
        ),
        DemoGroup(
          label: 'Checkbox',
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PanelCheckbox(
                    value: _terms,
                    label: 'Accept terms and conditions',
                    onChanged: (v) => setState(() => _terms = v),
                  ),
                  PanelCheckbox(
                    value: _marketing,
                    label: 'Product updates',
                    description: 'At most one email a week.',
                    onChanged: (v) => setState(() => _marketing = v),
                  ),
                  const PanelCheckbox(
                    value: true,
                    label: 'Disabled',
                    onChanged: null,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PanelCheckbox(
                    value: allTasks,
                    indeterminate: someTasks && !allTasks,
                    label: 'All tasks',
                    onChanged: (v) =>
                        setState(() => _tasks.fillRange(0, _tasks.length, v)),
                  ),
                  for (var i = 0; i < _tasks.length; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 28),
                      child: PanelCheckbox(
                        value: _tasks[i],
                        size: PanelCheckboxSize.sm,
                        label: ['Design review', 'Write tests', 'Ship'][i],
                        onChanged: (v) => setState(() => _tasks[i] = v),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        DemoGroup(
          label: 'Checkbox cards',
          children: [
            for (final (id, title, detail) in [
              ('starter', 'Starter', r'$9 a month · 1 project'),
              ('pro', 'Pro', r'$29 a month · unlimited projects'),
            ])
              SizedBox(
                width: 260,
                child: PanelCheckbox(
                  variant: PanelCheckboxVariant.card,
                  value: _plan == id,
                  label: title,
                  description: detail,
                  onChanged: (_) => setState(() => _plan = id),
                ),
              ),
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

class _FieldDemo extends StatefulWidget {
  const _FieldDemo();

  @override
  State<_FieldDemo> createState() => _FieldDemoState();
}

class _FieldDemoState extends State<_FieldDemo> {
  bool _marketing = true;
  final bool _security = true;
  bool _digest = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 460,
      child: PanelFieldSet(
        legend: 'Email notifications',
        children: [
          PanelField(
            orientation: Axis.horizontal,
            title: 'Marketing emails',
            description: 'Product updates and offers, at most weekly.',
            child: PanelSwitch(
              value: _marketing,
              onChanged: (v) => setState(() => _marketing = v),
            ),
          ),
          PanelField(
            orientation: Axis.horizontal,
            title: 'Security alerts',
            description: 'Sign-ins from new devices. Always on for admins.',
            isDisabled: true,
            child: PanelSwitch(value: _security, onChanged: null),
          ),
          PanelField(
            orientation: Axis.horizontal,
            title: 'Weekly digest',
            description: 'A summary of activity in your workspaces.',
            child: PanelSwitch(
              value: _digest,
              onChanged: (v) => setState(() => _digest = v),
            ),
          ),
          const PanelSeparator(),
          const PanelField(
            label: 'Forward to',
            isRequired: true,
            errors: [
              'Enter an email address.',
              'Use an address on a verified domain.',
            ],
            child: PanelInput(placeholder: 'team@example.com', isInvalid: true),
          ),
        ],
      ),
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

class _ThemeSelectorDemo extends StatelessWidget {
  const _ThemeSelectorDemo();

  @override
  Widget build(BuildContext context) {
    final scope = GalleryScope.of(context);
    return Wrap(
      spacing: 48,
      runSpacing: 24,
      children: [
        PanelThemeSelector(
          label: 'Appearance',
          value: scope.mode,
          onChanged: scope.onModeChanged,
        ),
        PanelThemeSelector(
          label: 'Card artwork, small',
          variant: PanelThemePreviewVariant.card,
          size: PanelThemeSelectorSize.sm,
          value: scope.mode,
          onChanged: scope.onModeChanged,
        ),
      ],
    );
  }
}
