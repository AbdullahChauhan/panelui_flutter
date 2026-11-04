import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../gallery/gallery.dart';

final List<GalleryDemo> overlayDemos = [
  GalleryDemo(
    id: 'dialog',
    title: 'Dialog',
    description:
        'A task taken out of the page and done in a box over it. It zooms in '
        'on a spring over a dimmed screen, and the scrim, Escape or the back '
        'button close it unless it has to be answered.',
    builder: (_) => const _DialogDemo(),
  ),
  GalleryDemo(
    id: 'bottom-sheet',
    title: 'Bottom Sheet',
    description:
        'A sheet that rises from the bottom edge and follows the finger: drag '
        'it down or flick it to put it away. A list inside it hands the drag '
        'to the sheet once it is scrolled to the top.',
    builder: (_) => const _BottomSheetDemo(),
  ),
  GalleryDemo(
    id: 'toast',
    title: 'Toast',
    description:
        'Short notifications that stack into a deck, swipe away toward their '
        'edge and leave on their own. Hover the deck with a mouse to spread '
        'it and hold it open.',
    builder: (_) => const _ToastDemo(),
  ),
];

/* -------------------------------------------------------------------------- */
/* Dialog                                                                     */
/* -------------------------------------------------------------------------- */

class _DialogDemo extends StatelessWidget {
  const _DialogDemo();

  Future<void> _confirm(BuildContext context) async {
    final deleted = await showPanelDialog<bool>(
      context,
      builder: (context) => PanelDialog(
        title: const Text('Delete project?'),
        description: const Text(
          'This action cannot be undone. The project and all of its data '
          'will be permanently removed.',
        ),
        actions: [
          PanelButton(
            size: PanelButtonSize.sm,
            variant: PanelButtonVariant.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          PanelButton(
            size: PanelButtonSize.sm,
            variant: PanelButtonVariant.destructive,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (deleted == true && context.mounted) {
      showPanelToast(
        context,
        title: const Text('Project deleted'),
        description: const Text('Acme Web and its 14 deployments are gone.'),
      );
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final saved = await showPanelDialog<bool>(
      context,
      builder: (context) => PanelDialog(
        title: const Text('Edit profile'),
        description: const Text(
          "Make changes to your profile here. Save when you're done.",
        ),
        // The panel band keeps the buttons from reading as one more field.
        footerVariant: PanelDialogFooterVariant.panel,
        actions: [
          PanelButton(
            size: PanelButtonSize.sm,
            variant: PanelButtonVariant.outline,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          PanelButton(
            size: PanelButtonSize.sm,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save changes'),
          ),
        ],
        child: const _ProfileFields(),
      ),
    );
    if (saved == true && context.mounted) {
      showPanelToast(
        context,
        variant: PanelToastVariant.success,
        title: const Text('Profile saved'),
      );
    }
  }

  void _whatsNew(BuildContext context) {
    showPanelDialog<void>(
      context,
      builder: (context) => PanelDialog(
        title: const Text('PanelUI 0.4'),
        description: const Text(
          'Themes now change corner radius as well as colour, and there is a '
          'new Steps component for multi-step flows.',
        ),
        actions: [
          PanelButton(
            size: PanelButtonSize.sm,
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _leave(BuildContext context) {
    showPanelDialog<void>(
      context,
      blur: true,
      barrierDismissible: false,
      builder: (context) => PanelDialog(
        title: const Text('Leave without saving?'),
        description: const Text(
          'Your changes will be lost. The screen behind is blurred so the '
          'choice is the only thing in focus, and only the buttons close it.',
        ),
        actions: [
          PanelButton(
            size: PanelButtonSize.sm,
            variant: PanelButtonVariant.ghost,
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep editing'),
          ),
          PanelButton(
            size: PanelButtonSize.sm,
            variant: PanelButtonVariant.destructive,
            onPressed: () => Navigator.pop(context),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Confirm, plain footer',
          children: [
            PanelButton(
              variant: PanelButtonVariant.outline,
              onPressed: () => _confirm(context),
              child: const Text('Delete project'),
            ),
            PanelButton(
              variant: PanelButtonVariant.outline,
              onPressed: () => _whatsNew(context),
              child: const Text("What's new"),
            ),
          ],
        ),
        DemoGroup(
          label: 'A form, panel footer',
          children: [
            PanelButton(
              variant: PanelButtonVariant.outline,
              onPressed: () => _editProfile(context),
              child: const Text('Edit profile'),
            ),
          ],
        ),
        DemoGroup(
          label: 'Blurred, must be answered',
          children: [
            PanelButton(
              variant: PanelButtonVariant.outline,
              onPressed: () => _leave(context),
              child: const Text('Open, blurred'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileFields extends StatefulWidget {
  const _ProfileFields();

  @override
  State<_ProfileFields> createState() => _ProfileFieldsState();
}

class _ProfileFieldsState extends State<_ProfileFields> {
  final _name = TextEditingController(text: 'Pedro Duarte');
  final _username = TextEditingController(text: '@peduarte');

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PanelInput(label: 'Name', controller: _name, autofocus: true),
          PanelInput(label: 'Username', controller: _username),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* Bottom sheet                                                               */
/* -------------------------------------------------------------------------- */

class _BottomSheetDemo extends StatelessWidget {
  const _BottomSheetDemo();

  void _share(BuildContext context) {
    showPanelBottomSheet<void>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelBottomSheetHeader(
            title: Text('Share project'),
            description: Text('Anyone with the link can view this project.'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                const PanelInput(placeholder: 'https://panelui.dev/p/xK2f9'),
                PanelButton(
                  fullWidth: true,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Copy link'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The corner close button is on by default; a sheet the reader can drag
  /// away or dismiss from the backdrop can do without it.
  void _withoutClose(BuildContext context) {
    showPanelBottomSheet<void>(
      context,
      showClose: false,
      builder: (context) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: PanelBottomSheetHeader(
          title: Text('Drag to dismiss'),
          description: Text('Pull the sheet down, or tap the backdrop.'),
        ),
      ),
    );
  }

  void _rate(BuildContext context, {bool blur = false}) {
    showPanelBottomSheet<void>(
      context,
      detached: true,
      blur: blur,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelBottomSheetHeader(
            title: Text(blur ? 'Move to trash' : 'Rate your order'),
            description: Text(
              blur
                  ? 'The file stays recoverable for 30 days.'
                  : 'How was the delivery?',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(
              spacing: 8,
              children: [
                for (final (label, variant)
                    in blur
                        ? const [
                            ('Cancel', PanelButtonVariant.outline),
                            ('Move to trash', PanelButtonVariant.destructive),
                          ]
                        : const [
                            ('Bad', PanelButtonVariant.outline),
                            ('Fine', PanelButtonVariant.outline),
                            ('Great', PanelButtonVariant.primary),
                          ])
                  Expanded(
                    child: PanelButton(
                      variant: variant,
                      fullWidth: true,
                      onPressed: () => Navigator.pop(context),
                      child: Text(label),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _invite(BuildContext context) {
    showPanelBottomSheet<void>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelBottomSheetHeader(
            title: Text('Invite a teammate'),
            description: Text('They will get an email with a join link.'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                const PanelInput(
                  label: 'Email',
                  placeholder: 'teammate@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const PanelInput(
                  label: 'Message',
                  placeholder: 'Optional note',
                ),
                PanelButton(
                  fullWidth: true,
                  onPressed: () {
                    Navigator.pop(context);
                    showPanelToast(
                      context,
                      variant: PanelToastVariant.success,
                      title: const Text('Invite sent'),
                    );
                  },
                  child: const Text('Send invite'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _projectActions(BuildContext context) {
    PanelButton action(String label, PanelButtonVariant variant) => PanelButton(
      variant: variant,
      fullWidth: true,
      onPressed: () => Navigator.pop(context),
      child: Text(label),
    );

    showPanelBottomSheet<void>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelBottomSheetHeader(title: Text('Project')),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                action('Rename', PanelButtonVariant.ghost),
                action('Duplicate', PanelButtonVariant.ghost),
                action('Archive', PanelButtonVariant.ghost),
                action('Delete', PanelButtonVariant.destructive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _countries(BuildContext context) {
    showPanelBottomSheet<String>(
      context,
      size: PanelBottomSheetSize.half,
      builder: (context) {
        final theme = PanelTheme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The heading names the behaviour, not just the task: every
            // version of this sheet looks much the same from the outside.
            const PanelBottomSheetHeader(
              title: Text('Choose a country'),
              description: Text(
                'The list scrolls under the fixed heading. The sheet itself '
                'still drags.',
              ),
            ),
            PanelBottomSheetBody(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                for (final (index, country) in _countryNames.indexed)
                  PanelPressable(
                    pressScale: 1,
                    pressOpacity: 0.6,
                    onPressed: () => Navigator.pop(context, country),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: index == 0
                            ? null
                            : Border(
                                top: BorderSide(color: theme.colors.border),
                              ),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(country)),
                          const PanelIcon(PanelIcons.chevronRight, size: 16),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    ).then((country) {
      if (country != null && context.mounted) {
        showPanelToast(context, title: Text('Shipping to $country'));
      }
    });
  }

  void _filters(BuildContext context) {
    showPanelBottomSheet<void>(
      context,
      size: PanelBottomSheetSize.full,
      builder: (context) => const _FiltersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    PanelButton open(String label, VoidCallback onPressed) => PanelButton(
      variant: PanelButtonVariant.outline,
      onPressed: onPressed,
      child: Text(label),
    );

    return DemoStack(
      children: [
        DemoGroup(
          label: 'Basic',
          children: [
            open('Open sheet', () => _share(context)),
            open('Open, no close button', () => _withoutClose(context)),
            open('Open actions', () => _projectActions(context)),
          ],
        ),
        DemoGroup(
          label: 'Detached',
          children: [
            open('Open detached', () => _rate(context)),
            open('Over a frosted screen', () => _rate(context, blur: true)),
          ],
        ),
        DemoGroup(
          label: 'A form, clear of the keyboard',
          children: [open('Open form', () => _invite(context))],
        ),
        DemoGroup(
          label: 'A list, and a full-height sheet',
          children: [
            open('Open list', () => _countries(context)),
            open('Open filters', () => _filters(context)),
          ],
        ),
      ],
    );
  }
}

const _countryNames = [
  'Somalia',
  'Kenya',
  'Ethiopia',
  'Djibouti',
  'Uganda',
  'Tanzania',
  'Rwanda',
  'Egypt',
  'Morocco',
  'Nigeria',
  'Ghana',
  'South Africa',
];

const _sortOptions = [
  ('relevance', 'Most relevant'),
  ('recent', 'Newest first'),
  ('price-low', 'Price: low to high'),
  ('price-high', 'Price: high to low'),
];

const _brands = [
  ('Aurora', 128),
  ('Basin', 94),
  ('Cadence', 61),
  ('Dovetail', 47),
  ('Ember', 33),
  ('Fathom', 21),
];

/// A full-height sheet is a shape as much as a size: a heading that stays
/// put, a body that scrolls under it, and the action pinned where it can
/// always be reached. Filters are the honest example: there are more of them
/// than fit, and the thing you came to press is the last thing you want to
/// have to scroll to.
class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet();

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  String _sort = 'relevance';
  double _budget = 240;
  bool _inStock = true;
  bool _freeReturns = false;
  final Set<String> _brandsOn = {'Aurora'};

  int get _active =>
      _brandsOn.length + (_inStock ? 1 : 0) + (_freeReturns ? 1 : 0);

  void _toggleBrand(String brand) => setState(
    () => _brandsOn.contains(brand)
        ? _brandsOn.remove(brand)
        : _brandsOn.add(brand),
  );

  void _reset() => setState(() {
    _sort = 'relevance';
    _budget = 240;
    _inStock = true;
    _freeReturns = false;
    _brandsOn.clear();
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelBottomSheetHeader(
          title: const Text('Filters'),
          description: Text('$_active applied · 384 results'),
        ),
        PanelBottomSheetBody(
          spacing: 24,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _FilterGroup(
              label: 'Sort by',
              children: [
                PanelRadioGroup<String>(
                  value: _sort,
                  onChanged: (value) => setState(() => _sort = value),
                  children: [
                    for (final (value, label) in _sortOptions)
                      PanelRadioItem<String>(value: value, label: label),
                  ],
                ),
              ],
            ),
            const PanelSeparator(),
            _FilterGroup(
              label: 'Budget',
              spacing: 12,
              trailing: PanelText(
                'Up to \$${_budget.round()}',
                size: PanelTextSize.sm,
                muted: true,
              ),
              children: [
                PanelSlider(
                  value: _budget,
                  min: 20,
                  max: 500,
                  step: 10,
                  semanticLabel: 'Budget',
                  onChanged: (value) => setState(() => _budget = value),
                ),
              ],
            ),
            const PanelSeparator(),
            _FilterGroup(
              label: 'Brand',
              children: [
                for (final (brand, count) in _brands)
                  PanelItem(
                    onPressed: () => _toggleBrand(brand),
                    title: Text(brand),
                    description: Text('$count items'),
                    actions: [
                      PanelCheckbox(
                        value: _brandsOn.contains(brand),
                        onChanged: (_) => _toggleBrand(brand),
                        semanticLabel: brand,
                      ),
                    ],
                  ),
              ],
            ),
            const PanelSeparator(),
            _FilterGroup(
              label: 'Availability',
              children: [
                PanelItem(
                  title: const Text('In stock only'),
                  description: const Text('Hide anything on backorder'),
                  actions: [
                    PanelSwitch(
                      value: _inStock,
                      onChanged: (value) => setState(() => _inStock = value),
                      semanticLabel: 'In stock only',
                    ),
                  ],
                ),
                PanelItem(
                  title: const Text('Free returns'),
                  description: const Text('Within 30 days of delivery'),
                  actions: [
                    PanelSwitch(
                      value: _freeReturns,
                      onChanged: (value) =>
                          setState(() => _freeReturns = value),
                      semanticLabel: 'Free returns',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        PanelBottomSheetFooter(
          direction: Axis.horizontal,
          children: [
            Expanded(
              child: PanelButton(
                variant: PanelButtonVariant.outline,
                fullWidth: true,
                onPressed: _reset,
                child: const Text('Reset'),
              ),
            ),
            Expanded(
              flex: 2,
              child: PanelButton(
                fullWidth: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('Show 384 results'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One group of filters: a label, and what it sets under it.
class _FilterGroup extends StatelessWidget {
  const _FilterGroup({
    required this.label,
    required this.children,
    this.trailing,
    this.spacing = 8,
  });

  final String label;
  final List<Widget> children;

  /// Shown at the end of the label's line, such as the value it is set to.
  final Widget? trailing;

  /// The gap between the label and what it sets.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [PanelLabel(label), ?trailing],
        ),
        ...children,
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/* Toast                                                                      */
/* -------------------------------------------------------------------------- */

class _ToastDemo extends StatelessWidget {
  const _ToastDemo();

  /// Raised a fifth of a second apart rather than together: the deck is
  /// built by things arriving, and four toasts on one frame is a deck that
  /// was already there.
  void _stack(BuildContext context) {
    const variants = [
      PanelToastVariant.neutral,
      PanelToastVariant.info,
      PanelToastVariant.success,
      PanelToastVariant.warning,
    ];
    for (var i = 0; i < variants.length; i++) {
      Future<void>.delayed(Duration(milliseconds: 220 * i), () {
        if (!context.mounted) return;
        showPanelToast(
          context,
          variant: variants[i],
          title: Text('Notification ${i + 1}'),
          description: const Text('Swipe down to dismiss the front one.'),
          duration: const Duration(seconds: 8),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    PanelButton raise(String label, VoidCallback onPressed) => PanelButton(
      variant: PanelButtonVariant.outline,
      onPressed: onPressed,
      child: Text(label),
    );

    return DemoStack(
      children: [
        DemoGroup(
          label: 'Variants',
          children: [
            raise(
              'Neutral',
              () => showPanelToast(
                context,
                title: const Text('Link copied to clipboard'),
              ),
            ),
            raise(
              'Info',
              () => showPanelToast(
                context,
                variant: PanelToastVariant.info,
                title: const Text('Update available'),
                description: const Text('Version 1.2 is ready to install.'),
              ),
            ),
            raise(
              'Success, with an action',
              () => showPanelToast(
                context,
                variant: PanelToastVariant.success,
                title: const Text('Deployment complete'),
                description: const Text('panelui.dev is live on production.'),
                action: PanelToastAction(
                  onPressed: () {},
                  child: const Text('View'),
                ),
              ),
            ),
            raise(
              'Warning',
              () => showPanelToast(
                context,
                variant: PanelToastVariant.warning,
                title: const Text('Storage almost full'),
                description: const Text('You have used 92% of your 10 GB.'),
                action: PanelToastAction(
                  onPressed: () {},
                  child: const Text('Upgrade'),
                ),
                closable: true,
              ),
            ),
            raise(
              'Destructive, top',
              () => showPanelToast(
                context,
                variant: PanelToastVariant.destructive,
                position: PanelToastPosition.top,
                title: const Text('Upload failed'),
                description: const Text('The file exceeds the 25 MB limit.'),
              ),
            ),
          ],
        ),
        DemoGroup(
          label: 'A deck',
          children: [
            raise('Stack four', () => _stack(context)),
            raise(
              'Stays until closed',
              () => showPanelToast(
                context,
                title: const Text('Sync paused'),
                description: const Text('Reconnect to pick up where you left.'),
                duration: Duration.zero,
              ),
            ),
            PanelButton(
              variant: PanelButtonVariant.ghost,
              onPressed: () => hideAllPanelToasts(context),
              child: const Text('Hide all'),
            ),
          ],
        ),
        DemoGroup(
          label: 'Positions',
          children: [
            for (final (label, position) in const [
              ('Top start', PanelToastPosition.topStart),
              ('Top', PanelToastPosition.top),
              ('Top end', PanelToastPosition.topEnd),
              ('Bottom start', PanelToastPosition.bottomStart),
              ('Bottom', PanelToastPosition.bottom),
              ('Bottom end', PanelToastPosition.bottomEnd),
            ])
              raise(
                label,
                () => showPanelToast(
                  context,
                  position: position,
                  variant: PanelToastVariant.info,
                  title: Text(label),
                  description: const Text('Each position keeps its own deck.'),
                ),
              ),
          ],
        ),
        DemoGroup(
          label: 'Drawn by the caller',
          children: [
            raise(
              'Custom component',
              () => showPanelToast(
                context,
                duration: const Duration(seconds: 6),
                builder: (context, toast) => PanelToast(
                  variant: PanelToastVariant.info,
                  icon: const PanelIcon(PanelIcons.sparkles),
                  title: const Text('Custom component'),
                  description: const Text('Rendered entirely by the caller.'),
                  onClose: toast.hide,
                ),
              ),
            ),
          ],
        ),
        const DemoGroup(
          label: 'Anatomy',
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            SizedBox(
              width: 380,
              child: Column(
                spacing: 12,
                children: [
                  PanelToast(
                    variant: PanelToastVariant.success,
                    title: Text('Changes saved'),
                    description: Text('Your profile is up to date.'),
                    onClose: _noop,
                  ),
                  PanelToast(
                    variant: PanelToastVariant.warning,
                    title: Text('Storage almost full'),
                    action: PanelToastAction(
                      onPressed: _noop,
                      child: Text('Upgrade'),
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

void _noop() {}
