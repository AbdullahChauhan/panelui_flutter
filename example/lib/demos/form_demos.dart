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

class _CodeAndNumberDemo extends StatefulWidget {
  const _CodeAndNumberDemo();

  @override
  State<_CodeAndNumberDemo> createState() => _CodeAndNumberDemoState();
}

class _CodeAndNumberDemoState extends State<_CodeAndNumberDemo> {
  final _code = TextEditingController(text: '4096');
  double _seats = 3;
  double _price = 12.5;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoStack(
      children: [
        DemoGroup(
          label: 'One-time code',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 32,
          children: [
            PanelOtpInput(controller: _code),
            const PanelOtpInput(
              length: 4,
              mask: true,
              size: PanelOtpInputSize.sm,
              placeholder: '0',
            ),
            const PanelOtpInput(
              length: 6,
              groupEvery: 3,
              size: PanelOtpInputSize.sm,
              errorMessage: 'That code has expired.',
            ),
          ],
        ),
        DemoGroup(
          label: 'Number',
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 24,
          children: [
            SizedBox(
              width: 220,
              child: PanelNumberInput(
                label: 'Seats',
                description: 'Between 1 and 20.',
                value: _seats,
                min: 1,
                max: 20,
                onChanged: (v) => setState(() => _seats = v),
              ),
            ),
            SizedBox(
              width: 220,
              child: PanelNumberInput(
                label: 'Price',
                variant: PanelInputVariant.filled,
                size: PanelNumberInputSize.sm,
                step: 0.5,
                min: 0,
                value: _price,
                onChanged: (v) => setState(() => _price = v),
              ),
            ),
          ],
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
