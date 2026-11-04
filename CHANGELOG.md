# Changelog

## 0.1.0

The first release of the port.

### Added

- Theme foundation: PanelUI's 58 colour tokens and its radius scales,
  generated from PanelUI's `theme.css`, for the Panel, Moon and Grass
  families in light and dark. `PanelThemeData` is a `ThemeExtension`, with
  `toMaterialTheme()`, `PanelTheme`, `AnimatedPanelTheme`, a type scale,
  shadows and PanelUI's springs.
- `PanelPressable`, the shared press feedback (0.97 scale, spring release),
  with keyboard focus rings, hover and Enter/Space activation.
- `PanelIcon` and `PanelIcons`, PanelUI's icon set on the same HugeIcons
  glyphs.
- 43 of PanelUI's 141 components (see [docs/COMPONENTS.md](docs/COMPONENTS.md)):
  - Actions: Button, ButtonGroup, Chip, Menu, ToggleButton.
  - Forms: Checkbox, Field, Input, Label, NumberInput, OtpInput, RadioGroup,
    Select, Slider and RangeSlider, Switch, Textarea, ThemeSelector.
  - Feedback: Alert, Badge, EmptyState, Meter, Progress, Skeleton, Spinner.
  - Overlays: BottomSheet, Dialog, Popover, Toast, Tooltip.
  - Navigation: Breadcrumb, Pagination, Steps, Tabs.
  - Layout: Accordion, Card, Collapsible, Item, ScrollFade, Separator,
    Surface, Typography.
  - Media: Avatar and AvatarGroup.
- A gallery app in `example/`.
