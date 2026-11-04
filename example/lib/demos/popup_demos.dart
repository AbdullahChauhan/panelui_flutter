import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../gallery/gallery.dart';

/// Tooltip, Popover, Select and Menu: panels anchored to the thing that
/// opened them.
final List<GalleryDemo> popupDemos = [
  GalleryDemo(
    id: 'tooltip',
    title: 'Tooltip',
    description:
        'A small label that names the control under the pointer: shown on '
        'hover or focus, on a long press on touch, flipped when it would leave '
        'the screen.',
    builder: (_) => const _TooltipDemo(),
  ),
  GalleryDemo(
    id: 'popover',
    title: 'Popover',
    description:
        'A panel anchored to its trigger that keeps the page around it in '
        'view. It unfolds from the trigger, flips and slides to stay on '
        'screen, and closes on a tap outside or Escape.',
    builder: (_) => const _PopoverDemo(),
  ),
  GalleryDemo(
    id: 'select',
    title: 'Select',
    description:
        'A field that opens a list of options, drawn like an input so the two '
        'sit together in a form. Arrow keys, type-ahead and Enter work too.',
    builder: (_) => const _SelectDemo(),
  ),
  GalleryDemo(
    id: 'menu',
    title: 'Menu',
    description:
        'The list of things you can do to something: rows with icons and '
        'shortcuts, toggles, a submenu that opens in place and a destructive '
        'action set apart.',
    builder: (_) => const _MenuDemo(),
  ),
];

// ---------------------------------------------------------------------------
// Tooltip
// ---------------------------------------------------------------------------

class _TooltipDemo extends StatelessWidget {
  const _TooltipDemo();

  @override
  Widget build(BuildContext context) {
    void noop() {}
    Widget tool(String label, PanelIconData icon) => PanelTooltip(
      message: label,
      showArrow: true,
      child: PanelButton(
        size: PanelButtonSize.icon,
        variant: PanelButtonVariant.ghost,
        onPressed: noop,
        child: PanelIcon(icon),
      ),
    );

    return DemoStack(
      children: [
        DemoGroup(
          label: 'On icon buttons: hover, focus or long press',
          children: [
            PanelButtonGroup(
              variant: PanelButtonVariant.outline,
              children: [
                for (final (label, icon) in [
                  ('Bold', PanelIcons.bold),
                  ('Italic', PanelIcons.italic),
                  ('Heading', PanelIcons.heading),
                  ('Quote', PanelIcons.quote),
                  ('Code', PanelIcons.code),
                ])
                  PanelTooltip(
                    message: label,
                    child: PanelButton(
                      size: PanelButtonSize.icon,
                      onPressed: noop,
                      child: PanelIcon(icon),
                    ),
                  ),
              ],
            ),
            tool('Copy link', PanelIcons.link),
            tool('Download', PanelIcons.download),
            tool('Delete', PanelIcons.trash),
          ],
        ),
        const DemoGroup(
          label: 'Placement, opened with a tap',
          children: [_TooltipPlacements()],
        ),
        DemoGroup(
          label: 'Rich content',
          children: [
            PanelTooltip(
              openOn: PanelTooltipOpenOn.press,
              duration: Duration.zero,
              showArrow: true,
              content: const _ShortcutLabel(),
              child: PanelButton(
                variant: PanelButtonVariant.secondary,
                onPressed: noop,
                child: const Text('Keyboard shortcut'),
              ),
            ),
            PanelTooltip(
              openOn: PanelTooltipOpenOn.press,
              duration: Duration.zero,
              variant: PanelTooltipVariant.surface,
              showArrow: true,
              width: 264,
              padding: const EdgeInsets.all(12),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  PanelTooltipTitle(child: Text('Streaming')),
                  PanelTooltipDescription(
                    child: Text(
                      'Tokens are rendered as they arrive rather than '
                      'waiting for the whole reply, so the first words appear '
                      'in a few hundred milliseconds.',
                    ),
                  ),
                ],
              ),
              child: PanelButton(
                variant: PanelButtonVariant.outline,
                onPressed: noop,
                child: const Text('What is streaming?'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// "Save" and its key, as one label.
class _ShortcutLabel extends StatelessWidget {
  const _ShortcutLabel();

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        const Text('Save'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: c.background.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(theme.radii.xs),
          ),
          child: Text(
            '⌘S',
            style: theme.typography.style(
              PanelTextSize.xs,
              weight: FontWeight.w600,
              color: c.background,
            ),
          ),
        ),
      ],
    );
  }
}

/// Four triggers, each pinned to the side that leaves room for its label to
/// open the way it says, so none of them has to flip.
class _TooltipPlacements extends StatelessWidget {
  const _TooltipPlacements();

  @override
  Widget build(BuildContext context) {
    Widget trigger(PanelTooltipPlacement placement) => PanelTooltip(
      message: 'Opens ${placement.name}',
      placement: placement,
      openOn: PanelTooltipOpenOn.press,
      duration: Duration.zero,
      showArrow: true,
      child: PanelButton(
        size: PanelButtonSize.sm,
        variant: PanelButtonVariant.secondary,
        onPressed: () {},
        child: Text(placement.name),
      ),
    );

    return SizedBox(
      width: 360,
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          trigger(PanelTooltipPlacement.bottom),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              trigger(PanelTooltipPlacement.end),
              trigger(PanelTooltipPlacement.start),
            ],
          ),
          trigger(PanelTooltipPlacement.top),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Popover
// ---------------------------------------------------------------------------

class _PopoverDemo extends StatefulWidget {
  const _PopoverDemo();

  @override
  State<_PopoverDemo> createState() => _PopoverDemoState();
}

class _PopoverDemoState extends State<_PopoverDemo> {
  final _rename = PanelPopoverController();
  final _name = TextEditingController(text: 'Untitled board');
  String _board = 'Untitled board';

  @override
  void dispose() {
    _rename.dispose();
    _name.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _board = _name.text.trim().isEmpty ? _board : _name.text);
    _rename.close();
  }

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        DemoGroup(
          label: 'A small form, as wide as its trigger',
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  PanelPopover(
                    controller: _rename,
                    matchTriggerWidth: true,
                    minWidth: 260,
                    align: PanelPopoverAlign.start,
                    spacing: 12,
                    semanticLabel: 'Rename board',
                    builder: (context, controller) => PanelButton(
                      variant: PanelButtonVariant.outline,
                      fullWidth: true,
                      leading: const PanelIcon(PanelIcons.pencil),
                      onPressed: controller.toggle,
                      child: const Text('Rename board'),
                    ),
                    children: [
                      const PanelPopoverTitle(child: Text('Rename')),
                      PanelInput(
                        controller: _name,
                        placeholder: 'Board name',
                        size: PanelInputSize.sm,
                        autocorrect: false,
                        onSubmitted: (_) => _save(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        spacing: 8,
                        children: [
                          PanelButton(
                            variant: PanelButtonVariant.ghost,
                            size: PanelButtonSize.sm,
                            onPressed: _rename.close,
                            child: const Text('Cancel'),
                          ),
                          PanelButton(
                            size: PanelButtonSize.sm,
                            onPressed: _save,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  PanelText(
                    'Board: $_board',
                    size: PanelTextSize.sm,
                    muted: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoGroup(
          label: 'With an arrow, and a title and a description',
          children: [
            PanelPopover(
              width: 240,
              showArrow: true,
              builder: (context, controller) => PanelButton(
                size: PanelButtonSize.icon,
                variant: PanelButtonVariant.ghost,
                semanticLabel: 'What is this?',
                onPressed: controller.toggle,
                child: const PanelIcon(PanelIcons.info),
              ),
              children: const [
                PanelPopoverTitle(child: Text('Monthly active users')),
                PanelPopoverDescription(
                  child: Text(
                    'Anyone who opened the app at least once in the last 30 '
                    'days.',
                  ),
                ),
              ],
            ),
            PanelPopover(
              width: 256,
              align: PanelPopoverAlign.start,
              showArrow: true,
              scrim: true,
              builder: (context, controller) => PanelButton(
                variant: PanelButtonVariant.outline,
                onPressed: controller.toggle,
                child: const Text('Dim the page'),
              ),
              children: const [
                PanelPopoverTitle(child: Text('Focus here')),
                PanelPopoverDescription(
                  child: Text(
                    'The page behind is dimmed so this panel reads as the '
                    'only thing to deal with.',
                  ),
                ),
              ],
            ),
            PanelPopover(
              width: 288,
              maxHeight: 260,
              scrollable: true,
              align: PanelPopoverAlign.start,
              builder: (context, controller) => PanelButton(
                variant: PanelButtonVariant.outline,
                onPressed: controller.toggle,
                child: const Text('Release notes'),
              ),
              children: [
                const PanelPopoverTitle(child: Text('What changed')),
                for (var i = 1; i <= 8; i++)
                  PanelPopoverDescription(
                    child: Text(
                      'Release note $i: a line of detail long enough to take '
                      'a couple of rows.',
                    ),
                  ),
              ],
            ),
          ],
        ),
        const DemoGroup(label: 'Placement', children: [_PopoverPlacements()]),
      ],
    );
  }
}

class _PopoverPlacements extends StatelessWidget {
  const _PopoverPlacements();

  @override
  Widget build(BuildContext context) {
    Widget trigger(PanelPopoverPlacement placement) => PanelPopover(
      placement: placement,
      width: 160,
      showArrow: true,
      builder: (context, controller) => PanelButton(
        size: PanelButtonSize.sm,
        variant: PanelButtonVariant.secondary,
        onPressed: controller.toggle,
        child: Text(placement.name),
      ),
      children: [
        PanelPopoverDescription(
          child: Text('Opens ${placement.name} of the trigger.'),
        ),
      ],
    );

    return SizedBox(
      width: 420,
      height: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          trigger(PanelPopoverPlacement.bottom),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              trigger(PanelPopoverPlacement.end),
              trigger(PanelPopoverPlacement.start),
            ],
          ),
          trigger(PanelPopoverPlacement.top),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Select
// ---------------------------------------------------------------------------

const _statuses = <PanelSelectEntry<String>>[
  PanelSelectOption(value: 'draft', label: 'Draft'),
  PanelSelectOption(value: 'review', label: 'In review'),
  PanelSelectOption(value: 'approved', label: 'Approved'),
  PanelSelectOption(value: 'shipped', label: 'Shipped'),
];

const _zones = <PanelSelectEntry<String>>[
  PanelSelectGroup(
    label: 'Europe',
    options: [
      PanelSelectOption(value: 'europe/london', label: 'London'),
      PanelSelectOption(value: 'europe/paris', label: 'Paris'),
      PanelSelectOption(value: 'europe/berlin', label: 'Berlin'),
    ],
  ),
  PanelSelectGroup(
    label: 'Asia',
    options: [
      PanelSelectOption(value: 'asia/dubai', label: 'Dubai'),
      PanelSelectOption(value: 'asia/tokyo', label: 'Tokyo'),
      PanelSelectOption(value: 'asia/singapore', label: 'Singapore'),
    ],
  ),
  PanelSelectSeparator(),
  PanelSelectGroup(
    label: 'Americas',
    options: [
      PanelSelectOption(value: 'america/new_york', label: 'New York'),
      PanelSelectOption(value: 'america/los_angeles', label: 'Los Angeles'),
    ],
  ),
];

const _cities = [
  'UTC',
  'London',
  'Paris',
  'Berlin',
  'Madrid',
  'Istanbul',
  'Cairo',
  'Lagos',
  'Nairobi',
  'Dubai',
  'Karachi',
  'Kolkata',
  'Singapore',
  'Tokyo',
  'Sydney',
  'São Paulo',
  'New York',
  'Chicago',
  'Denver',
  'Los Angeles',
];

class _SelectDemo extends StatefulWidget {
  const _SelectDemo();

  @override
  State<_SelectDemo> createState() => _SelectDemoState();
}

class _SelectDemoState extends State<_SelectDemo> {
  String? _fruit;
  String? _status = 'review';
  String? _plan;
  String? _zone;
  String? _city;
  String _size = 'review';

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Outline and filled, with an error',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 24,
          runSpacing: 24,
          children: [
            SizedBox(
              width: 320,
              child: Column(
                spacing: 20,
                children: [
                  PanelSelect<String>(
                    label: 'Favorite fruit',
                    placeholder: 'Select a fruit',
                    value: _fruit,
                    onChanged: (value) => setState(() => _fruit = value),
                    options: const [
                      PanelSelectOption(value: 'apple', label: 'Apple'),
                      PanelSelectOption(value: 'banana', label: 'Banana'),
                      PanelSelectOption(value: 'cherry', label: 'Cherry'),
                      PanelSelectOption(value: 'mango', label: 'Mango'),
                    ],
                  ),
                  PanelSelect<String>(
                    label: 'Plan',
                    isRequired: true,
                    placeholder: 'Choose a plan',
                    value: _plan,
                    errorMessage: _plan == null
                        ? 'Choose a plan to continue.'
                        : null,
                    description: 'You can change it at any time.',
                    onChanged: (value) => setState(() => _plan = value),
                    options: const [
                      PanelSelectOption(value: 'starter', label: 'Starter'),
                      PanelSelectOption(value: 'team', label: 'Team'),
                      PanelSelectOption(
                        value: 'enterprise',
                        label: 'Enterprise — contact sales',
                        enabled: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 320,
              child: Column(
                spacing: 20,
                children: [
                  PanelSelect<String>(
                    label: 'Status',
                    variant: PanelInputVariant.filled,
                    value: _status,
                    onChanged: (value) => setState(() => _status = value),
                    options: _statuses,
                  ),
                  PanelSelect<String>(
                    label: 'Time zone',
                    variant: PanelInputVariant.filled,
                    placeholder: 'Select a time zone',
                    description: 'Grouped by region.',
                    value: _zone,
                    onChanged: (value) => setState(() => _zone = value),
                    options: _zones,
                  ),
                  const PanelSelect<String>(
                    label: 'Region',
                    placeholder: 'Locked by your organisation',
                    value: null,
                    onChanged: null,
                    options: [],
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoGroup(
          label: 'Sizes, sharing one value',
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: Column(
                spacing: 12,
                children: [
                  for (final size in PanelInputSize.values)
                    PanelSelect<String>(
                      size: size,
                      value: _size,
                      semanticLabel: 'Status, ${size.name}',
                      onChanged: (value) => setState(() => _size = value),
                      options: _statuses,
                    ),
                ],
              ),
            ),
          ],
        ),
        DemoGroup(
          label: 'A long list scrolls; type a city name to jump to it',
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: PanelSelect<String>(
                label: 'City',
                placeholder: 'Select a city',
                value: _city,
                onChanged: (value) => setState(() => _city = value),
                options: [
                  for (final city in _cities)
                    PanelSelectOption(value: city, label: city),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Menu
// ---------------------------------------------------------------------------

class _MenuDemo extends StatefulWidget {
  const _MenuDemo();

  @override
  State<_MenuDemo> createState() => _MenuDemoState();
}

class _MenuDemoState extends State<_MenuDemo> {
  String _last = 'Nothing chosen yet';
  String _density = 'comfortable';
  bool _showDone = true;
  bool _showArchived = false;

  void _did(String what) => setState(() => _last = what);

  @override
  Widget build(BuildContext context) {
    PanelPopoverTriggerBuilder button(String label) =>
        (context, controller) => PanelButton(
          variant: PanelButtonVariant.outline,
          trailing: const PanelIcon(PanelIcons.chevronDown),
          onPressed: controller.toggle,
          child: Text(label),
        );

    return DemoStack(
      children: [
        DemoGroup(
          label: 'Actions with icons, shortcuts and a destructive row',
          children: [
            PanelMenu(
              align: PanelPopoverAlign.start,
              width: 224,
              builder: button('Options'),
              children: [
                PanelMenuItem(
                  leading: const PanelIcon(PanelIcons.shareNodes),
                  shortcut: '⌘S',
                  onSelected: () => _did('Shared'),
                  child: const Text('Share'),
                ),
                PanelMenuItem(
                  leading: const PanelIcon(PanelIcons.plusSquare),
                  onSelected: () => _did('Added to list'),
                  child: const Text('Add to list'),
                ),
                const PanelMenuItem(
                  leading: PanelIcon(PanelIcons.download),
                  child: Text('Download'),
                ),
                const PanelMenuSeparator(),
                PanelMenuItem(
                  variant: PanelMenuItemVariant.destructive,
                  leading: const PanelIcon(PanelIcons.trash),
                  shortcut: '⌫',
                  onSelected: () => _did('Deleted'),
                  child: const Text('Delete'),
                ),
              ],
            ),
            PanelMenu(
              align: PanelPopoverAlign.start,
              width: 244,
              builder: button('File actions'),
              children: [
                PanelMenuItem(
                  leading: const PanelIcon(PanelIcons.pencil),
                  shortcut: '⌘R',
                  onSelected: () => _did('Renamed'),
                  child: const Text('Rename'),
                ),
                PanelMenuSub(
                  leading: const PanelIcon(PanelIcons.package),
                  children: [
                    for (final folder in ['Inbox', 'Projects', 'Archive'])
                      PanelMenuItem(
                        onSelected: () => _did('Moved to $folder'),
                        child: Text(folder),
                      ),
                  ],
                  child: const Text('Move to'),
                ),
                const PanelMenuSeparator(),
                PanelMenuItem(
                  variant: PanelMenuItemVariant.destructive,
                  leading: const PanelIcon(PanelIcons.trash),
                  description: 'This cannot be undone',
                  onSelected: () => _did('Deleted'),
                  child: const Text('Delete'),
                ),
              ],
            ),
            PanelMenu(
              align: PanelPopoverAlign.end,
              width: 232,
              builder: (context, controller) => PanelButton(
                size: PanelButtonSize.icon,
                variant: PanelButtonVariant.ghost,
                semanticLabel: 'More',
                onPressed: controller.toggle,
                child: const PanelIcon(PanelIcons.ellipsis),
              ),
              children: [
                const PanelMenuLabel('Account', inset: true),
                PanelMenuItem(
                  inset: true,
                  onSelected: () => _did('Opened profile'),
                  child: const Text('Profile'),
                ),
                PanelMenuItem(
                  inset: true,
                  shortcut: '⌘,',
                  onSelected: () => _did('Opened settings'),
                  child: const Text('Settings'),
                ),
                const PanelMenuSeparator(),
                PanelMenuItem(
                  leading: const PanelIcon(PanelIcons.lock),
                  onSelected: () => _did('Locked'),
                  child: const Text('Lock screen'),
                ),
              ],
            ),
            PanelText(_last, size: PanelTextSize.sm, muted: true),
          ],
        ),
        DemoGroup(
          label: 'Toggles that keep it open, and a choice of one',
          children: [
            PanelMenu(
              align: PanelPopoverAlign.start,
              width: 248,
              builder: button('View options'),
              children: [
                const PanelMenuLabel('Density'),
                PanelMenuRadioGroup<String>(
                  value: _density,
                  onChanged: (value) => setState(() => _density = value),
                  children: const [
                    PanelMenuRadioItem(
                      value: 'comfortable',
                      indicator: PanelMenuRadioIndicator.dot,
                      child: Text('Comfortable'),
                    ),
                    PanelMenuRadioItem(
                      value: 'compact',
                      indicator: PanelMenuRadioIndicator.dot,
                      child: Text('Compact'),
                    ),
                  ],
                ),
                const PanelMenuSeparator(),
                const PanelMenuLabel('Show'),
                PanelMenuCheckboxItem(
                  value: _showDone,
                  onChanged: (value) => setState(() => _showDone = value),
                  child: const Text('Completed'),
                ),
                PanelMenuCheckboxItem(
                  value: _showArchived,
                  onChanged: (value) => setState(() => _showArchived = value),
                  child: const Text('Archived'),
                ),
              ],
            ),
            PanelMenu(
              align: PanelPopoverAlign.start,
              width: 230,
              maxHeight: 260,
              builder: button('Jump to section'),
              children: [
                for (var i = 1; i <= 14; i++)
                  PanelMenuItem(
                    inset: true,
                    onSelected: () => _did('Jumped to section $i'),
                    child: Text('Section $i'),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
