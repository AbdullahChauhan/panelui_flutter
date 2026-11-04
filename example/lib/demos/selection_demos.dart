import 'dart:async';

import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../gallery/gallery.dart';

/// Demos for the selection and display batch: radio groups, progress bars,
/// avatars, chips, toggle buttons and sliders.
final List<GalleryDemo> selectionDemos = [
  GalleryDemo(
    id: 'radio-group',
    title: 'Radio Group',
    description:
        'One choice from a set, as rows or as cards. The dot springs in; the '
        'arrow keys move the choice.',
    builder: (_) => const _RadioGroupDemo(),
  ),
  GalleryDemo(
    id: 'progress',
    title: 'Progress',
    description:
        'A bar that springs to each new value, reads against a range of its '
        'own, or sweeps while the length of the work is unknown.',
    builder: (_) => const _ProgressDemo(),
  ),
  GalleryDemo(
    id: 'avatar',
    title: 'Avatar',
    description:
        'A picture with initials to fall back on, a corner badge, and a '
        'stack that counts the people who did not fit.',
    builder: (_) => const _AvatarDemo(),
  ),
  GalleryDemo(
    id: 'chip',
    title: 'Chip',
    description:
        'A small pill that can be pressed, turned on as a filter, or removed '
        'with its own ✕.',
    builder: (_) => const _ChipDemo(),
  ),
  GalleryDemo(
    id: 'toggle-button',
    title: 'Toggle Button',
    description:
        'A button that stays down, alone or in a group of independent marks '
        'or an either-or choice.',
    builder: (_) => const _ToggleButtonDemo(),
  ),
  GalleryDemo(
    id: 'slider',
    title: 'Slider',
    description:
        'A value picked by dragging a pill-shaped thumb, or a span picked by '
        'two. Press the track, drag, or use the arrow keys.',
    builder: (_) => const _SliderDemo(),
  ),
];

/// The width most of these demos are laid out at: a form column.
const double _column = 420;

/// A whole number of dollars with its thousands separated: `$1,250`.
String _dollars(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer(r'$');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

// ---------------------------------------------------------------------------
// Radio group
// ---------------------------------------------------------------------------

class _RadioGroupDemo extends StatefulWidget {
  const _RadioGroupDemo();

  @override
  State<_RadioGroupDemo> createState() => _RadioGroupDemoState();
}

class _RadioGroupDemoState extends State<_RadioGroupDemo> {
  String _plan = 'pro';
  String _size = 'm';
  String _tier = 'pro';
  String _billing = 'monthly';
  String _delivery = 'standard';
  final Map<PanelRadioSize, String> _bySize = {};

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        DemoGroup(
          label: 'A list of options',
          children: [
            PanelRadioGroup<String>(
              value: _plan,
              onChanged: (value) => setState(() => _plan = value),
              children: const [
                PanelRadioItem(value: 'free', label: 'Free — \$0/month'),
                PanelRadioItem(value: 'pro', label: 'Pro — \$12/month'),
                PanelRadioItem(value: 'team', label: 'Team — \$36/month'),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'In a row that wraps',
          children: [
            PanelRadioGroup<String>(
              value: _size,
              orientation: Axis.horizontal,
              onChanged: (value) => setState(() => _size = value),
              children: const [
                PanelRadioItem(value: 's', label: 'Small'),
                PanelRadioItem(value: 'm', label: 'Medium'),
                PanelRadioItem(value: 'l', label: 'Large'),
                PanelRadioItem(value: 'xl', label: 'X-Large'),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Cards',
          children: [
            SizedBox(
              width: _column,
              child: PanelRadioGroup<String>(
                value: _tier,
                variant: PanelRadioVariant.card,
                onChanged: (value) => setState(() => _tier = value),
                children: const [
                  PanelRadioItem(
                    value: 'starter',
                    label: 'Starter',
                    description:
                        'For a side project — one seat, community support.',
                  ),
                  PanelRadioItem(
                    value: 'pro',
                    label: 'Pro',
                    description:
                        'For growing teams — five seats, priority support.',
                  ),
                  PanelRadioItem(
                    value: 'max',
                    label: 'Max',
                    description:
                        'Everything, uncapped — unlimited seats and SSO.',
                  ),
                  PanelRadioItem(
                    value: 'enterprise',
                    label: 'Enterprise',
                    description: 'Through sales only — talk to us first.',
                    enabled: false,
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoGroup(
          label: 'Cards sharing a row',
          children: [
            SizedBox(
              width: _column,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  PanelRadioGroup<String>(
                    value: _billing,
                    variant: PanelRadioVariant.card,
                    orientation: Axis.horizontal,
                    onChanged: (value) => setState(() => _billing = value),
                    children: const [
                      PanelRadioItem(
                        value: 'monthly',
                        label: 'Monthly',
                        description: '\$12/mo',
                      ),
                      PanelRadioItem(
                        value: 'yearly',
                        label: 'Yearly',
                        description: '\$120/yr',
                      ),
                    ],
                  ),
                  PanelRadioGroup<String>(
                    value: _delivery,
                    variant: PanelRadioVariant.card,
                    orientation: Axis.horizontal,
                    onChanged: (value) => setState(() => _delivery = value),
                    children: const [
                      PanelRadioItem(
                        value: 'standard',
                        label: 'Standard',
                        description: '3–5 days',
                      ),
                      PanelRadioItem(
                        value: 'express',
                        label: 'Express',
                        description: 'Next day',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoGroup(
          label: 'Sizes',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (size, name) in const [
                  (PanelRadioSize.xs, 'Extra small'),
                  (PanelRadioSize.sm, 'Small'),
                  (PanelRadioSize.md, 'Medium'),
                  (PanelRadioSize.lg, 'Large'),
                  (PanelRadioSize.xl, 'Extra large'),
                ])
                  PanelRadioGroup<String>(
                    value: _bySize[size] ?? 'monthly',
                    size: size,
                    orientation: Axis.horizontal,
                    onChanged: (value) => setState(() => _bySize[size] = value),
                    children: [
                      PanelRadioItem(value: 'monthly', label: '$name, monthly'),
                      const PanelRadioItem(value: 'yearly', label: 'Yearly'),
                    ],
                  ),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Disabled',
          children: [
            const PanelRadioGroup<String>(
              value: 'email',
              onChanged: null,
              children: [
                PanelRadioItem(value: 'email', label: 'Email me'),
                PanelRadioItem(value: 'sms', label: 'Text me'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Progress
// ---------------------------------------------------------------------------

class _ProgressDemo extends StatefulWidget {
  const _ProgressDemo();

  @override
  State<_ProgressDemo> createState() => _ProgressDemoState();
}

class _ProgressDemoState extends State<_ProgressDemo> {
  double _uploaded = 20;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      setState(() => _uploaded = _uploaded >= 100 ? 0 : _uploaded + 20);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget column(List<Widget> children) => SizedBox(
      width: _column,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: children,
      ),
    );

    return DemoStack(
      children: [
        DemoGroup(
          label: 'Animated',
          children: [
            column([
              PanelProgress(
                value: _uploaded,
                label: 'Uploading',
                showValueLabel: true,
              ),
              PanelProgress(
                value: _uploaded,
                color: PanelProgressColor.success,
                size: PanelProgressSize.sm,
              ),
              const PanelProgress(
                value: 70,
                color: PanelProgressColor.warning,
                size: PanelProgressSize.lg,
              ),
              const PanelProgress(
                indeterminate: true,
                color: PanelProgressColor.info,
              ),
            ]),
          ],
        ),
        DemoGroup(
          label: 'Labelled',
          children: [
            column(const [
              PanelProgress(
                value: 64,
                label: 'Downloading',
                showValueLabel: true,
              ),
              PanelProgress(
                value: 41,
                color: PanelProgressColor.success,
                label: 'Storage',
                valueLabel: '8.2 GB of 20 GB',
                showValueLabel: true,
              ),
              PanelProgress(
                value: 90,
                color: PanelProgressColor.warning,
                showValueLabel: true,
              ),
              PanelProgress(
                indeterminate: true,
                label: 'Syncing your library',
                showValueLabel: true,
              ),
            ]),
          ],
        ),
        DemoGroup(
          label: 'A range of its own',
          children: [
            column([
              PanelProgress(
                value: 1250,
                max: 2000,
                label: 'Budget',
                formatValue: (value) => '${_dollars(value)} of \$2,000',
                showValueLabel: true,
              ),
              const PanelProgress(
                value: 18,
                max: 24,
                color: PanelProgressColor.info,
                label: 'Seats',
                valueLabel: '18 of 24',
                showValueLabel: true,
              ),
              const PanelProgress(
                value: 72,
                min: 40,
                max: 80,
                color: PanelProgressColor.success,
                showValueLabel: true,
              ),
            ]),
          ],
        ),
        DemoGroup(
          label: 'Colours',
          children: [
            column(const [
              PanelProgress(value: 35),
              PanelProgress(value: 55, color: PanelProgressColor.success),
              PanelProgress(value: 75, color: PanelProgressColor.warning),
              PanelProgress(value: 90, color: PanelProgressColor.destructive),
              PanelProgress(value: 45, color: PanelProgressColor.info),
            ]),
          ],
        ),
        DemoGroup(
          label: 'Sizes',
          children: [
            column(const [
              PanelProgress(value: 60, size: PanelProgressSize.sm),
              PanelProgress(value: 60),
              PanelProgress(value: 60, size: PanelProgressSize.lg),
            ]),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------

const _photos = [
  NetworkImage('https://i.pravatar.cc/150?img=12'),
  NetworkImage('https://i.pravatar.cc/150?img=32'),
  NetworkImage('https://i.pravatar.cc/150?img=47'),
  NetworkImage('https://i.pravatar.cc/150?img=5'),
  NetworkImage('https://i.pravatar.cc/150?img=68'),
];

const _people = [
  'Ada Byron',
  'Chen Dong',
  'Eva Fischer',
  'Grace Hu',
  'Ivo Jung',
];

String _initials(String name) =>
    name.split(' ').map((word) => word[0]).join().toUpperCase();

class _AvatarDemo extends StatelessWidget {
  const _AvatarDemo();

  @override
  Widget build(BuildContext context) {
    final faces = [
      for (var i = 0; i < _people.length; i++)
        PanelAvatar(
          image: _photos[i],
          fallback: _initials(_people[i]),
          semanticLabel: _people[i],
        ),
    ];
    return DemoStack(
      children: [
        const DemoGroup(
          label: 'Sizes',
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            PanelAvatar(fallback: 'KA', size: PanelAvatarSize.sm),
            PanelAvatar(fallback: 'KA'),
            PanelAvatar(fallback: 'PU', size: PanelAvatarSize.lg),
            PanelAvatar(fallback: 'P', size: PanelAvatarSize.xl),
          ],
        ),
        DemoGroup(
          label: 'With a picture, and when it fails',
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            PanelAvatar(
              image: _photos[0],
              fallback: 'AB',
              size: PanelAvatarSize.sm,
            ),
            PanelAvatar(image: _photos[1], fallback: 'CD'),
            PanelAvatar(
              image: _photos[2],
              fallback: 'EF',
              size: PanelAvatarSize.lg,
            ),
            // A picture that never arrives shows the initials.
            const PanelAvatar(
              image: NetworkImage('https://example.invalid/missing.png'),
              fallback: 'GH',
              size: PanelAvatarSize.lg,
            ),
          ],
        ),
        DemoGroup(
          label: 'With a badge',
          spacing: 24,
          children: [
            PanelAvatar(
              image: _photos[0],
              fallback: 'AB',
              size: PanelAvatarSize.lg,
              badge: const PanelBadge.count(
                5,
                variant: PanelBadgeVariant.destructive,
              ),
            ),
            PanelAvatar(
              image: _photos[1],
              fallback: 'CD',
              size: PanelAvatarSize.lg,
              badge: const PanelBadge.count(
                128,
                variant: PanelBadgeVariant.destructive,
              ),
            ),
            const PanelAvatar(
              fallback: 'EF',
              size: PanelAvatarSize.lg,
              badge: PanelBadge.dot(variant: PanelBadgeVariant.success),
            ),
            const PanelAvatar(
              fallback: 'GH',
              badge: PanelBadge.dot(variant: PanelBadgeVariant.warning),
            ),
          ],
        ),
        DemoGroup(
          label: 'A stacked group',
          children: [PanelAvatarGroup(children: faces.take(3).toList())],
        ),
        DemoGroup(
          label: 'A capped group',
          spacing: 32,
          children: [
            // Three of the five, and thirty-seven more behind them.
            PanelAvatarGroup(
              size: PanelAvatarSize.sm,
              max: 3,
              total: 40,
              children: faces,
            ),
            // The cap counts faces: two shown, three counted.
            PanelAvatarGroup(max: 2, children: faces),
            PanelAvatarGroup(
              size: PanelAvatarSize.lg,
              max: 4,
              children: [
                for (final name in _people)
                  PanelAvatar(fallback: _initials(name), semanticLabel: name),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Chip
// ---------------------------------------------------------------------------

class _ChipDemo extends StatefulWidget {
  const _ChipDemo();

  @override
  State<_ChipDemo> createState() => _ChipDemoState();
}

class _ChipDemoState extends State<_ChipDemo> {
  static const _everyone = ['Ada', 'Grace', 'Alan', 'Katherine'];

  final Set<String> _tags = {'design'};
  List<String> _people = [..._everyone];

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        const DemoGroup(
          label: 'Variants',
          spacing: 8,
          children: [
            PanelChip(child: Text('Default')),
            PanelChip(
              variant: PanelChipVariant.primary,
              child: Text('Primary'),
            ),
            PanelChip(
              variant: PanelChipVariant.outline,
              child: Text('Outline'),
            ),
            PanelChip(
              variant: PanelChipVariant.success,
              child: Text('Shipped'),
            ),
            PanelChip(variant: PanelChipVariant.warning, child: Text('Beta')),
            PanelChip(variant: PanelChipVariant.info, child: Text('New')),
            PanelChip(
              variant: PanelChipVariant.destructive,
              child: Text('Blocked'),
            ),
          ],
        ),
        DemoGroup(
          label: 'Sizes',
          spacing: 8,
          children: [
            for (final (size, name) in const [
              (PanelChipSize.xs, 'Extra small'),
              (PanelChipSize.sm, 'Small'),
              (PanelChipSize.md, 'Medium'),
              (PanelChipSize.lg, 'Large'),
              (PanelChipSize.xl, 'Extra large'),
            ])
              PanelChip(size: size, child: Text(name)),
          ],
        ),
        const DemoGroup(
          label: 'With a leading icon',
          spacing: 8,
          children: [
            PanelChip(
              variant: PanelChipVariant.success,
              leading: PanelIcon(PanelIcons.check),
              child: Text('Available'),
            ),
            PanelChip(
              variant: PanelChipVariant.outline,
              leading: PanelIcon(PanelIcons.search),
              child: Text('Search'),
            ),
            PanelChip(
              variant: PanelChipVariant.info,
              leading: PanelIcon(PanelIcons.clock),
              child: Text('Due Friday'),
            ),
          ],
        ),
        DemoGroup(
          label: 'A filter bar',
          spacing: 8,
          children: [
            for (final tag in const ['design', 'code', 'research', 'ops'])
              PanelChip(
                selected: _tags.contains(tag),
                haptics: true,
                onPressed: () => setState(
                  () =>
                      _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag),
                ),
                child: Text(tag),
              ),
          ],
        ),
        DemoGroup(
          label: 'Removable tokens',
          spacing: 8,
          children: [
            for (final name in _people)
              PanelChip(
                variant: PanelChipVariant.outline,
                closeLabel: 'Remove $name',
                onClose: () => setState(() => _people.remove(name)),
                child: Text(name),
              ),
            if (_people.length < _everyone.length)
              PanelButton(
                variant: PanelButtonVariant.ghost,
                size: PanelButtonSize.xs,
                onPressed: () => setState(() => _people = [..._everyone]),
                child: const Text('Reset'),
              ),
          ],
        ),
        DemoGroup(
          label: 'Disabled',
          spacing: 8,
          children: [
            PanelChip(
              enabled: false,
              selected: true,
              onPressed: () {},
              child: const Text('Archived'),
            ),
            PanelChip(
              enabled: false,
              variant: PanelChipVariant.outline,
              onClose: () {},
              child: const Text('Locked'),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle button
// ---------------------------------------------------------------------------

class _ToggleButtonDemo extends StatefulWidget {
  const _ToggleButtonDemo();

  @override
  State<_ToggleButtonDemo> createState() => _ToggleButtonDemoState();
}

class _ToggleButtonDemoState extends State<_ToggleButtonDemo> {
  bool _following = true;
  bool _subscribed = false;
  bool _saved = false;
  List<String> _marks = ['shield'];
  List<String> _view = ['day'];
  List<String> _format = ['bold'];
  final Map<PanelToggleButtonSize, List<String>> _bySize = {};

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        DemoGroup(
          label: 'On its own',
          children: [
            PanelToggleButton(
              value: _following,
              onChanged: (value) => setState(() => _following = value),
              child: Text(_following ? 'Following' : 'Follow'),
            ),
            PanelToggleButton(
              value: _subscribed,
              onChanged: (value) => setState(() => _subscribed = value),
              leading: const PanelIcon(PanelIcons.bell),
              child: Text(_subscribed ? 'Subscribed' : 'Subscribe'),
            ),
            PanelToggleButton(
              value: _saved,
              variant: PanelToggleButtonVariant.ghost,
              iconOnly: true,
              semanticLabel: 'Save',
              onChanged: (value) => setState(() => _saved = value),
              child: const PanelIcon(PanelIcons.plusSquare),
            ),
          ],
        ),
        DemoGroup(
          label: 'A toolbar of marks',
          children: [
            PanelToggleButtonGroup<String>(
              value: _marks,
              variant: PanelToggleButtonVariant.ghost,
              onChanged: (value) => setState(() => _marks = value),
              children: const [
                PanelToggleButton(
                  id: 'shield',
                  iconOnly: true,
                  semanticLabel: 'Protected',
                  child: PanelIcon(PanelIcons.shieldCheck),
                ),
                PanelToggleButton(
                  id: 'bell',
                  iconOnly: true,
                  semanticLabel: 'Notify',
                  child: PanelIcon(PanelIcons.bell),
                ),
                PanelToggleButton(
                  id: 'share',
                  iconOnly: true,
                  semanticLabel: 'Shared',
                  child: PanelIcon(PanelIcons.shareNodes),
                ),
              ],
            ),
            PanelToggleButtonGroup<String>(
              value: _format,
              size: PanelToggleButtonSize.sm,
              onChanged: (value) => setState(() => _format = value),
              children: const [
                PanelToggleButton(
                  id: 'bold',
                  iconOnly: true,
                  semanticLabel: 'Bold',
                  child: PanelIcon(PanelIcons.bold),
                ),
                PanelToggleButton(
                  id: 'italic',
                  iconOnly: true,
                  semanticLabel: 'Italic',
                  child: PanelIcon(PanelIcons.italic),
                ),
                PanelToggleButton(
                  id: 'code',
                  iconOnly: true,
                  semanticLabel: 'Code',
                  child: PanelIcon(PanelIcons.code),
                ),
              ],
            ),
            PanelText(
              'On: ${_marks.isEmpty ? 'nothing' : _marks.join(', ')}',
              size: PanelTextSize.sm,
              muted: true,
            ),
          ],
        ),
        DemoGroup(
          label: 'An either-or choice',
          children: [
            PanelToggleButtonGroup<String>(
              value: _view,
              selectionMode: PanelToggleSelectionMode.single,
              onChanged: (value) => setState(() => _view = value),
              children: const [
                PanelToggleButton(id: 'day', child: Text('Day')),
                PanelToggleButton(id: 'week', child: Text('Week')),
                PanelToggleButton(id: 'month', child: Text('Month')),
              ],
            ),
            PanelText(
              'Showing: ${_view.isEmpty ? 'nothing' : _view.first}',
              size: PanelTextSize.sm,
              muted: true,
            ),
          ],
        ),
        DemoGroup(
          label: 'Sizes',
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                for (final (size, name) in const [
                  (PanelToggleButtonSize.xs, 'Extra small'),
                  (PanelToggleButtonSize.sm, 'Small'),
                  (PanelToggleButtonSize.md, 'Medium'),
                  (PanelToggleButtonSize.lg, 'Large'),
                  (PanelToggleButtonSize.xl, 'Extra large'),
                ])
                  PanelToggleButtonGroup<String>(
                    value: _bySize[size] ?? const ['a'],
                    size: size,
                    onChanged: (value) => setState(() => _bySize[size] = value),
                    children: [
                      PanelToggleButton(id: 'a', child: Text(name)),
                      PanelToggleButton(id: 'b', child: Text(name)),
                    ],
                  ),
              ],
            ),
          ],
        ),
        const DemoGroup(
          label: 'Disabled',
          children: [
            PanelToggleButton(value: true, child: Text('Disabled')),
            PanelToggleButton(
              variant: PanelToggleButtonVariant.ghost,
              iconOnly: true,
              semanticLabel: 'Pin',
              child: PanelIcon(PanelIcons.bookmark),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Slider
// ---------------------------------------------------------------------------

class _SliderDemo extends StatefulWidget {
  const _SliderDemo();

  @override
  State<_SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<_SliderDemo> {
  double _volume = 40;
  double _brightness = 62;
  double _budget = 340;
  double _rating = 2;
  RangeValues _price = const RangeValues(220, 680);
  RangeValues _nights = const RangeValues(2, 6);
  final Map<Object, double> _values = {};

  double _of(Object key, double initial) => _values[key] ?? initial;

  void _set(Object key, double value) => setState(() => _values[key] = value);

  @override
  Widget build(BuildContext context) {
    Widget column(List<Widget> children) => SizedBox(
      width: _column,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: children,
      ),
    );

    return DemoStack(
      children: [
        DemoGroup(
          label: 'Interactive',
          children: [
            column([
              PanelSlider(
                label: 'Volume',
                showValue: true,
                formatValue: (value) => '${value.round()}%',
                value: _volume,
                onChanged: (value) => setState(() => _volume = value),
              ),
              PanelSlider(
                label: 'Brightness',
                showValue: true,
                value: _brightness,
                color: PanelSliderColor.info,
                onChanged: (value) => setState(() => _brightness = value),
              ),
              PanelSlider(
                label: 'Budget',
                showValue: true,
                formatValue: _dollars,
                value: _budget,
                max: 1000,
                step: 20,
                color: PanelSliderColor.success,
                onChanged: (value) => setState(() => _budget = value),
              ),
            ]),
          ],
        ),
        DemoGroup(
          label: 'A range',
          children: [
            column([
              PanelRangeSlider(
                label: 'Price',
                showValue: true,
                formatValue: _dollars,
                values: _price,
                max: 1000,
                step: 20,
                color: PanelSliderColor.success,
                onChanged: (value) => setState(() => _price = value),
              ),
              // A gap the span can never close: an empty range matches
              // nothing and looks like a bug rather than a choice.
              PanelRangeSlider(
                label: 'Nights',
                showValue: true,
                values: _nights,
                min: 1,
                max: 14,
                minStepsBetweenThumbs: 1,
                onChanged: (value) => setState(() => _nights = value),
              ),
            ]),
          ],
        ),
        DemoGroup(
          label: 'Colours',
          children: [
            column([
              for (final (color, initial) in const [
                (PanelSliderColor.primary, 40.0),
                (PanelSliderColor.success, 55.0),
                (PanelSliderColor.warning, 70.0),
                (PanelSliderColor.destructive, 85.0),
              ])
                PanelSlider(
                  value: _of(color, initial),
                  color: color,
                  onChanged: (value) => _set(color, value),
                ),
            ]),
          ],
        ),
        DemoGroup(
          label: 'Sizes',
          children: [
            column([
              for (final size in PanelSliderSize.values)
                PanelSlider(
                  value: _of(size, 40),
                  size: size,
                  onChanged: (value) => _set(size, value),
                ),
            ]),
          ],
        ),
        DemoGroup(
          label: 'Stepped and disabled',
          children: [
            column([
              PanelSlider(
                label: 'Rating',
                showValue: true,
                value: _rating,
                max: 5,
                color: PanelSliderColor.warning,
                size: PanelSliderSize.lg,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const PanelSlider(
                label: 'Locked',
                showValue: true,
                value: 30,
                onChanged: null,
              ),
              const PanelRangeSlider(
                label: 'Locked range',
                showValue: true,
                values: RangeValues(30, 60),
                onChanged: null,
              ),
            ]),
          ],
        ),
      ],
    );
  }
}
