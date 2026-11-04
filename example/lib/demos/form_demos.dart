import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

import '../gallery/gallery.dart';

/// Demos for the text fields, toggles, fields, code and number inputs, and
/// the theme selector.
final List<GalleryDemo> formDemos = [
  GalleryDemo(
    id: 'input',
    title: 'Input and Textarea',
    description:
        'Text fields with a label, a description or an error, and a border '
        'that crosses to the focus colour over 150ms.',
    builder: (_) => const _InputDemo(),
  ),
  GalleryDemo(
    id: 'otp-number',
    title: 'OTP Input and Number Input',
    description:
        'A one-time code spread over cells with a blinking caret, and a '
        'number you can nudge (hold to repeat) or type.',
    builder: (_) => const _CodeAndNumberDemo(),
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
    id: 'theme-selector',
    title: 'Theme Selector',
    description:
        'Light, dark or the device setting, as miniatures of a screen. Pick '
        'one here and the whole gallery follows.',
    builder: (_) => const _ThemeSelectorDemo(),
  ),
];

/// A column of fields at the width of a form.
class _FormColumn extends StatelessWidget {
  const _FormColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: children,
      ),
    );
  }
}

class _InputDemo extends StatelessWidget {
  const _InputDemo();

  @override
  Widget build(BuildContext context) {
    return const DemoStack(
      children: [
        DemoGroup(
          label: 'Content inside the field',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 24,
          children: [_InputContentDemo()],
        ),
        DemoGroup(
          label: 'States and sizes',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 24,
          children: [
            _FormColumn(
              children: [
                PanelInput(label: 'Name', placeholder: 'Khalid Abdi'),
                PanelInput(
                  label: 'Email',
                  placeholder: 'you@example.com',
                  isRequired: true,
                  description: 'We never share your address.',
                  keyboardType: TextInputType.emailAddress,
                ),
                _SeededInput(
                  label: 'Username',
                  text: 'panel',
                  validate: _usernameTaken,
                ),
                _SeededInput(label: 'Plan', text: 'Premium', enabled: false),
              ],
            ),
            _InputSizes(),
          ],
        ),
        DemoGroup(
          label: 'Textarea',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 24,
          children: [
            _FormColumn(
              children: [
                PanelTextarea(rows: 2, placeholder: 'Two rows'),
                PanelTextarea(placeholder: 'Four rows, the default'),
                PanelTextarea(
                  label: 'Feedback',
                  rows: 3,
                  isRequired: true,
                  placeholder: 'What went wrong?',
                  errorMessage: 'Tell us a little more.',
                ),
              ],
            ),
            _FormColumn(
              children: [
                PanelTextarea(
                  label: 'Message',
                  placeholder: 'Type a few lines…',
                  description:
                      'Starts at two rows, grows to six, then scrolls.',
                  rows: 2,
                  autoGrow: true,
                  maxRows: 6,
                ),
                _StatusTextarea(),
              ],
            ),
          ],
        ),
        DemoGroup(
          label: 'Filled, inside a card',
          children: [_FilledFieldsCard()],
        ),
      ],
    );
  }
}

/// Every size, eight points apart.
class _InputSizes extends StatelessWidget {
  const _InputSizes();

  @override
  Widget build(BuildContext context) {
    return _FormColumn(
      children: [
        for (final (size, name) in [
          (PanelInputSize.xs, 'Extra small'),
          (PanelInputSize.sm, 'Small'),
          (PanelInputSize.md, 'Medium'),
          (PanelInputSize.lg, 'Large'),
          (PanelInputSize.xl, 'Extra large'),
        ])
          PanelInput(
            size: size,
            label: name,
            placeholder: '${size.height.round()} tall',
          ),
      ],
    );
  }
}

/// The case PanelUI built its content slots for: icons that stay put on the
/// field however the label and description around it change.
class _InputContentDemo extends StatefulWidget {
  const _InputContentDemo();

  @override
  State<_InputContentDemo> createState() => _InputContentDemoState();
}

class _InputContentDemoState extends State<_InputContentDemo> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormColumn(
      children: [
        const PanelInput(
          label: 'Description',
          placeholder: 'A short description',
          description: 'Shown on your public profile.',
          leading: PanelIcon(PanelIcons.pencil, size: 18),
          interactiveContent: false,
        ),
        ListenableBuilder(
          listenable: _query,
          builder: (context, _) => PanelInput(
            controller: _query,
            placeholder: 'Find a project',
            // The magnifier is decoration, so a press on it goes to the
            // field; the clear button beside the text stays a button.
            leading: const IgnorePointer(
              child: PanelIcon(PanelIcons.search, size: 18),
            ),
            trailing: _query.text.isEmpty
                ? null
                : PanelPressable(
                    onPressed: _query.clear,
                    semanticLabel: 'Clear search',
                    child: const PanelIcon(PanelIcons.x),
                  ),
          ),
        ),
        PanelInput(
          label: 'Amount',
          placeholder: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          leading: PanelText(r'$', muted: true),
          trailing: PanelText('USD', muted: true),
          interactiveContent: false,
        ),
        const PanelInput(
          label: 'Note',
          placeholder: 'Anything worth remembering',
          multiline: true,
          leading: PanelIcon(PanelIcons.pencil, size: 18),
          interactiveContent: false,
        ),
      ],
    );
  }
}

/// A field that starts with a value in it, checked by [validate] as it
/// changes.
class _SeededInput extends StatefulWidget {
  const _SeededInput({
    required this.label,
    required this.text,
    this.enabled = true,
    this.validate,
  });

  final String label;
  final String text;
  final bool enabled;
  final String? Function(String value)? validate;

  @override
  State<_SeededInput> createState() => _SeededInputState();
}

class _SeededInputState extends State<_SeededInput> {
  late final _value = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _value,
      builder: (context, _) => PanelInput(
        label: widget.label,
        controller: _value,
        enabled: widget.enabled,
        errorMessage: widget.validate?.call(_value.text),
      ),
    );
  }
}

String? _usernameTaken(String value) =>
    value == 'panel' ? 'That username is already taken.' : null;

/// A count driven by a real value, so it has something to count.
class _StatusTextarea extends StatefulWidget {
  const _StatusTextarea();

  @override
  State<_StatusTextarea> createState() => _StatusTextareaState();
}

class _StatusTextareaState extends State<_StatusTextarea> {
  final _status = TextEditingController(
    text: 'Shipping the new calendar today.',
  );

  @override
  void dispose() {
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PanelTextarea(
      label: 'Status',
      controller: _status,
      rows: 3,
      maxLength: 140,
      showCount: true,
      description: 'Keep it short.',
    );
  }
}

/// Filled fields inside a card, where a second border beside the card's own
/// would read as a seam.
class _FilledFieldsCard extends StatelessWidget {
  const _FilledFieldsCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 380,
      child: PanelCard(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                PanelInput(
                  variant: PanelInputVariant.filled,
                  label: 'Workspace',
                  placeholder: 'Acme',
                  isRequired: true,
                ),
                PanelInput(
                  variant: PanelInputVariant.filled,
                  label: 'Notes',
                  placeholder: 'Anything we should know?',
                  multiline: true,
                ),
                PanelTextarea(
                  variant: PanelInputVariant.filled,
                  label: 'Delivery instructions',
                  rows: 3,
                  placeholder: 'Leave it with the concierge.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeAndNumberDemo extends StatelessWidget {
  const _CodeAndNumberDemo();

  @override
  Widget build(BuildContext context) {
    return const DemoStack(
      children: [
        DemoGroup(
          label: 'Verify a code',
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [_VerifyCodeDemo()],
        ),
        DemoGroup(
          label: 'Masked, grouped and lettered',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 32,
          runSpacing: 24,
          children: [
            _SeededCode(length: 4, mask: true),
            _SeededCode(length: 6, groupEvery: 3),
            PanelOtpInput(
              length: 5,
              numeric: false,
              placeholder: '•',
              semanticLabel: 'Invite code',
            ),
          ],
        ),
        DemoGroup(
          label: 'Code sizes',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 32,
          runSpacing: 24,
          children: [
            _SeededCode(length: 4, size: PanelOtpInputSize.sm),
            _SeededCode(length: 4),
            _SeededCode(length: 4, size: PanelOtpInputSize.lg),
          ],
        ),
        DemoGroup(
          label: 'Quantity and budget',
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [_QuantityDemo()],
        ),
        DemoGroup(
          label: 'Bounds, steps, sizes and variants',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 24,
          runSpacing: 24,
          children: [_NumberVariantsDemo()],
        ),
      ],
    );
  }
}

/// Six digits, and the row confirms the moment the last one lands. The
/// completion fires once, on the way to full: the moment to submit.
class _VerifyCodeDemo extends StatefulWidget {
  const _VerifyCodeDemo();

  @override
  State<_VerifyCodeDemo> createState() => _VerifyCodeDemoState();
}

enum _CodeStatus { waiting, verified, refused }

class _VerifyCodeDemoState extends State<_VerifyCodeDemo> {
  _CodeStatus _status = _CodeStatus.waiting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        PanelOtpInput(
          semanticLabel: 'Verification code',
          isInvalid: _status == _CodeStatus.refused,
          onChanged: (_) {
            if (_status != _CodeStatus.waiting) {
              setState(() => _status = _CodeStatus.waiting);
            }
          },
          onCompleted: (code) => setState(
            () => _status = code == '123456'
                ? _CodeStatus.verified
                : _CodeStatus.refused,
          ),
        ),
        PanelText(
          switch (_status) {
            _CodeStatus.waiting => 'Type a six-digit code (123456).',
            _CodeStatus.verified => 'Verified: the code was 123456.',
            _CodeStatus.refused => 'That code didn’t match. Try 123456.',
          },
          size: PanelTextSize.sm,
          muted: true,
        ),
      ],
    );
  }
}

/// A code field that starts with two characters in it.
class _SeededCode extends StatefulWidget {
  const _SeededCode({
    required this.length,
    this.mask = false,
    this.groupEvery = 0,
    this.size = PanelOtpInputSize.md,
  });

  final int length;
  final bool mask;
  final int groupEvery;
  final PanelOtpInputSize size;

  @override
  State<_SeededCode> createState() => _SeededCodeState();
}

class _SeededCodeState extends State<_SeededCode> {
  final _code = TextEditingController(text: '12');

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PanelOtpInput(
      controller: _code,
      length: widget.length,
      mask: widget.mask,
      groupEvery: widget.groupEvery,
      size: widget.size,
      semanticLabel: 'Code',
    );
  }
}

/// A quantity beside the line it prices, and a budget formatted as money.
class _QuantityDemo extends StatefulWidget {
  const _QuantityDemo();

  @override
  State<_QuantityDemo> createState() => _QuantityDemoState();
}

class _QuantityDemoState extends State<_QuantityDemo> {
  double _quantity = 1;
  double _budget = 40;

  @override
  Widget build(BuildContext context) {
    final count = _quantity.round();
    return SizedBox(
      width: 380,
      child: PanelCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Row(
                  spacing: 16,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PanelText(
                            'Wireless keyboard',
                            weight: FontWeight.w500,
                          ),
                          PanelText(
                            '$count × \$49 = \$${count * 49}',
                            size: PanelTextSize.sm,
                            muted: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 128,
                      child: PanelNumberInput(
                        value: _quantity,
                        min: 1,
                        max: 20,
                        onChanged: (v) => setState(() => _quantity = v),
                      ),
                    ),
                  ],
                ),
                PanelNumberInput(
                  label: 'Budget',
                  value: _budget,
                  min: 0,
                  max: 1000,
                  step: 10,
                  formatValue: (v) => '\$${v.round()}',
                  onChanged: (v) => setState(() => _budget = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberVariantsDemo extends StatefulWidget {
  const _NumberVariantsDemo();

  @override
  State<_NumberVariantsDemo> createState() => _NumberVariantsDemoState();
}

class _NumberVariantsDemoState extends State<_NumberVariantsDemo> {
  double _rating = 0;
  double _opacity = 0.5;
  double _guests = 2;
  final _sizes = {for (final size in PanelNumberInputSize.values) size: 1.0};
  double _filled = 1;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _FormColumn(
          children: [
            PanelNumberInput(
              label: 'Rating',
              description: 'Whole stars, from 0 to 5.',
              value: _rating,
              min: 0,
              max: 5,
              onChanged: (v) => setState(() => _rating = v),
            ),
            PanelNumberInput(
              label: 'Opacity',
              description: 'Steps of 0.1, from 0 to 1.',
              value: _opacity,
              min: 0,
              max: 1,
              step: 0.1,
              onChanged: (v) => setState(() => _opacity = v),
            ),
            PanelNumberInput(
              label: 'Guests',
              description: 'Up to eight per reservation.',
              value: _guests,
              min: 1,
              max: 8,
              isRequired: true,
              onChanged: (v) => setState(() => _guests = v),
            ),
          ],
        ),
        _FormColumn(
          children: [
            for (final size in PanelNumberInputSize.values)
              PanelNumberInput(
                size: size,
                value: _sizes[size]!,
                onChanged: (v) => setState(() => _sizes[size] = v),
              ),
            PanelNumberInput(
              variant: PanelInputVariant.filled,
              value: _filled,
              onChanged: (v) => setState(() => _filled = v),
            ),
            const PanelNumberInput(value: 3, onChanged: null),
          ],
        ),
      ],
    );
  }
}

class _ToggleDemo extends StatelessWidget {
  const _ToggleDemo();

  @override
  Widget build(BuildContext context) {
    return const DemoStack(
      children: [
        DemoGroup(
          label: 'Switch: settings rows',
          children: [_SwitchSettingsDemo()],
        ),
        DemoGroup(
          label: 'Switch: states and sizes',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 48,
          children: [_SwitchStatesDemo(), _SwitchSizesDemo()],
        ),
        DemoGroup(
          label: 'Checkbox',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 48,
          runSpacing: 24,
          children: [_CheckboxDescriptionsDemo(), _CheckboxSelectAllDemo()],
        ),
        DemoGroup(
          label: 'Checkbox: states and sizes',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 48,
          runSpacing: 24,
          children: [_CheckboxStatesDemo(), _CheckboxSizesDemo()],
        ),
        DemoGroup(label: 'Checkbox cards', children: [_CheckboxCardDemo()]),
      ],
    );
  }
}

/// A title and a line of help beside a switch, the way a settings list has
/// them.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    this.haptics = false,
  });

  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool haptics;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelText(title, weight: FontWeight.w500),
              if (description != null)
                PanelText(description!, size: PanelTextSize.sm, muted: true),
            ],
          ),
        ),
        PanelSwitch(
          value: value,
          semanticLabel: title,
          semanticHint: description,
          haptics: haptics,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SwitchSettingsDemo extends StatefulWidget {
  const _SwitchSettingsDemo();

  @override
  State<_SwitchSettingsDemo> createState() => _SwitchSettingsDemoState();
}

class _SwitchSettingsDemoState extends State<_SwitchSettingsDemo> {
  bool _email = true;
  bool _push = false;
  bool _wifi = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: PanelCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              spacing: 20,
              children: [
                _SettingRow(
                  title: 'Email notifications',
                  description: 'Receive updates and newsletters',
                  value: _email,
                  onChanged: (v) => setState(() => _email = v),
                ),
                _SettingRow(
                  title: 'Push notifications',
                  description: 'Get instant alerts on your device',
                  value: _push,
                  onChanged: (v) => setState(() => _push = v),
                ),
                _SettingRow(
                  title: 'Wi-Fi',
                  description: 'Ticks the haptic engine on each flip',
                  value: _wifi,
                  haptics: true,
                  onChanged: (v) => setState(() => _wifi = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchStatesDemo extends StatefulWidget {
  const _SwitchStatesDemo();

  @override
  State<_SwitchStatesDemo> createState() => _SwitchStatesDemoState();
}

class _SwitchStatesDemoState extends State<_SwitchStatesDemo> {
  bool _on = true;
  bool _off = false;

  @override
  Widget build(BuildContext context) {
    Widget row(Widget control, String name) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        control,
        PanelText(name, size: PanelTextSize.sm, muted: true),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        row(
          PanelSwitch(
            value: _on,
            semanticLabel: 'On',
            onChanged: (v) => setState(() => _on = v),
          ),
          'On',
        ),
        row(
          PanelSwitch(
            value: _off,
            semanticLabel: 'Off',
            onChanged: (v) => setState(() => _off = v),
          ),
          'Off',
        ),
        row(
          const PanelSwitch(
            value: true,
            semanticLabel: 'Disabled',
            onChanged: null,
          ),
          'Disabled',
        ),
      ],
    );
  }
}

class _SwitchSizesDemo extends StatefulWidget {
  const _SwitchSizesDemo();

  @override
  State<_SwitchSizesDemo> createState() => _SwitchSizesDemoState();
}

class _SwitchSizesDemoState extends State<_SwitchSizesDemo> {
  final _on = {for (final size in PanelSwitchSize.values) size: true};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        for (final (size, name) in [
          (PanelSwitchSize.xs, 'Extra small'),
          (PanelSwitchSize.sm, 'Small'),
          (PanelSwitchSize.md, 'Medium'),
          (PanelSwitchSize.lg, 'Large'),
          (PanelSwitchSize.xl, 'Extra large'),
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              PanelSwitch(
                size: size,
                value: _on[size]!,
                semanticLabel: name,
                onChanged: (v) => setState(() => _on[size] = v),
              ),
              PanelText(name, size: PanelTextSize.sm, muted: true),
            ],
          ),
      ],
    );
  }
}

class _CheckboxDescriptionsDemo extends StatefulWidget {
  const _CheckboxDescriptionsDemo();

  @override
  State<_CheckboxDescriptionsDemo> createState() =>
      _CheckboxDescriptionsDemoState();
}

class _CheckboxDescriptionsDemoState extends State<_CheckboxDescriptionsDemo> {
  bool _marketing = true;
  bool _updates = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          PanelCheckbox(
            value: _marketing,
            label: 'Marketing & promotions',
            description: 'Special offers and exclusive deals',
            onChanged: (v) => setState(() => _marketing = v),
          ),
          PanelCheckbox(
            value: _updates,
            label: 'Product updates',
            description: 'News about features and releases',
            onChanged: (v) => setState(() => _updates = v),
          ),
        ],
      ),
    );
  }
}

/// A box that governs a group: a dash while the group is partly on, and a
/// press that turns the whole group on or off.
class _CheckboxSelectAllDemo extends StatefulWidget {
  const _CheckboxSelectAllDemo();

  @override
  State<_CheckboxSelectAllDemo> createState() => _CheckboxSelectAllDemoState();
}

class _CheckboxSelectAllDemoState extends State<_CheckboxSelectAllDemo> {
  static const _channels = ['Email', 'Push', 'SMS'];
  final _on = {'Email'};

  @override
  Widget build(BuildContext context) {
    final all = _on.length == _channels.length;
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PanelCheckbox(
            value: all,
            indeterminate: _on.isNotEmpty && !all,
            label: all ? 'Deselect all' : 'Select all',
            onChanged: (v) => setState(() {
              _on.clear();
              if (v) _on.addAll(_channels);
            }),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                for (final channel in _channels)
                  PanelCheckbox(
                    value: _on.contains(channel),
                    label: channel,
                    onChanged: (v) => setState(
                      () => v ? _on.add(channel) : _on.remove(channel),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckboxStatesDemo extends StatefulWidget {
  const _CheckboxStatesDemo();

  @override
  State<_CheckboxStatesDemo> createState() => _CheckboxStatesDemoState();
}

class _CheckboxStatesDemoState extends State<_CheckboxStatesDemo> {
  bool _checked = true;
  bool _unchecked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        PanelCheckbox(
          value: _checked,
          label: 'Checked',
          onChanged: (v) => setState(() => _checked = v),
        ),
        PanelCheckbox(
          value: _unchecked,
          label: 'Unchecked',
          onChanged: (v) => setState(() => _unchecked = v),
        ),
        const PanelCheckbox(value: true, label: 'Disabled', onChanged: null),
      ],
    );
  }
}

class _CheckboxSizesDemo extends StatefulWidget {
  const _CheckboxSizesDemo();

  @override
  State<_CheckboxSizesDemo> createState() => _CheckboxSizesDemoState();
}

class _CheckboxSizesDemoState extends State<_CheckboxSizesDemo> {
  final _on = {for (final size in PanelCheckboxSize.values) size: true};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        for (final (size, name) in [
          (PanelCheckboxSize.xs, 'Extra small'),
          (PanelCheckboxSize.sm, 'Small'),
          (PanelCheckboxSize.md, 'Medium'),
          (PanelCheckboxSize.lg, 'Large'),
          (PanelCheckboxSize.xl, 'Extra large'),
        ])
          PanelCheckbox(
            size: size,
            value: _on[size]!,
            label: name,
            onChanged: (v) => setState(() => _on[size] = v),
          ),
      ],
    );
  }
}

class _CheckboxCardDemo extends StatefulWidget {
  const _CheckboxCardDemo();

  @override
  State<_CheckboxCardDemo> createState() => _CheckboxCardDemoState();
}

class _CheckboxCardDemoState extends State<_CheckboxCardDemo> {
  static const _plans = [
    ('starter', 'Starter', 'Everything you need to begin.'),
    ('pro', 'Pro', 'Advanced analytics and priority support.'),
    ('team', 'Team', 'Shared workspaces and audit logs.'),
  ];
  final _picked = {'pro'};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          for (final (id, label, description) in _plans)
            PanelCheckbox(
              variant: PanelCheckboxVariant.card,
              value: _picked.contains(id),
              label: label,
              description: description,
              onChanged: (v) =>
                  setState(() => v ? _picked.add(id) : _picked.remove(id)),
            ),
        ],
      ),
    );
  }
}

/// PanelUI's own Field demo: a set under a legend, a rule, a setting with its
/// switch beside it, and a field refused with a reason.
class _FieldDemo extends StatefulWidget {
  const _FieldDemo();

  @override
  State<_FieldDemo> createState() => _FieldDemoState();
}

class _FieldDemoState extends State<_FieldDemo> {
  bool _email = true;
  bool _sms = false;
  bool _analytics = true;
  final _username = TextEditingController(text: 'taken-name');

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          PanelFieldSet(
            legend: 'Notifications',
            children: [
              PanelCheckbox(
                value: _email,
                label: 'Email',
                onChanged: (v) => setState(() => _email = v),
              ),
              PanelCheckbox(
                value: _sms,
                label: 'SMS',
                onChanged: (v) => setState(() => _sms = v),
              ),
            ],
          ),
          const PanelSeparator(),
          PanelField(
            orientation: Axis.horizontal,
            title: 'Advanced analytics',
            description: 'Included with the Pro plan.',
            child: PanelSwitch(
              value: _analytics,
              onChanged: (v) => setState(() => _analytics = v),
            ),
          ),
          const PanelField(
            orientation: Axis.horizontal,
            title: 'Security alerts',
            description: 'Sign-ins from new devices. Always on for admins.',
            isDisabled: true,
            child: PanelSwitch(value: true, onChanged: null),
          ),
          ListenableBuilder(
            listenable: _username,
            builder: (context, _) => PanelField(
              label: 'Username',
              isRequired: true,
              errors: [
                if (_username.text == 'taken-name')
                  'That username is already taken.',
                if (_username.text.contains(' '))
                  'Use letters, numbers and dashes only.',
              ],
              child: PanelInput(controller: _username),
            ),
          ),
          const PanelSeparator(label: Text('Or')),
          const PanelField(
            label: 'Invite code',
            description: 'From the email your team sent you.',
            errors: [
              'That code has expired.',
              'Ask an admin for a new one.',
              'That code has expired.',
            ],
            child: PanelInput(placeholder: 'ABCD-1234', isInvalid: true),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelectorDemo extends StatelessWidget {
  const _ThemeSelectorDemo();

  @override
  Widget build(BuildContext context) {
    final scope = GalleryScope.of(context);
    return DemoStack(
      children: [
        DemoGroup(
          label: 'Applied to the gallery',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 48,
          runSpacing: 24,
          children: [
            PanelThemeSelector(
              label: 'Choose a theme',
              value: scope.mode,
              onChanged: scope.onModeChanged,
            ),
            PanelThemeSelector(
              label: 'Appearance',
              variant: PanelThemePreviewVariant.card,
              value: scope.mode,
              onChanged: scope.onModeChanged,
            ),
            PanelThemeSelector(
              variant: PanelThemePreviewVariant.card,
              size: PanelThemeSelectorSize.sm,
              value: scope.mode,
              onChanged: scope.onModeChanged,
            ),
          ],
        ),
        const DemoGroup(
          label: 'Stored, not applied',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 48,
          runSpacing: 24,
          children: [_StoredChoiceDemo(), _LightOrDarkDemo()],
        ),
      ],
    );
  }
}

/// A settings screen that keeps the choice to apply on the next launch,
/// rather than changing the theme now.
class _StoredChoiceDemo extends StatefulWidget {
  const _StoredChoiceDemo();

  @override
  State<_StoredChoiceDemo> createState() => _StoredChoiceDemoState();
}

class _StoredChoiceDemoState extends State<_StoredChoiceDemo> {
  ThemeMode _choice = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        PanelThemeSelector(
          label: 'Appearance',
          value: _choice,
          onChanged: (mode) => setState(() => _choice = mode),
        ),
        PanelText(
          'Stored as “${_choice.name}”; nothing has changed the theme.',
          size: PanelTextSize.sm,
          muted: true,
        ),
      ],
    );
  }
}

/// Two options only, for an app that does not follow the device.
class _LightOrDarkDemo extends StatefulWidget {
  const _LightOrDarkDemo();

  @override
  State<_LightOrDarkDemo> createState() => _LightOrDarkDemoState();
}

class _LightOrDarkDemoState extends State<_LightOrDarkDemo> {
  ThemeMode _choice = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return PanelThemeSelector(
      label: 'Light and dark only',
      options: const [ThemeMode.light, ThemeMode.dark],
      value: _choice,
      onChanged: (mode) => setState(() => _choice = mode),
    );
  }
}
