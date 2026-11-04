# Changelog

## Unreleased

### Fixed

- Hover fades now interpolate in premultiplied alpha, as CSS transitions do.
  An outline button no longer flashes grey on its way to the hover tint.
  Added `panelLerpColor` and `PanelColorTween`.
- Shadows are now cast as CSS casts them: only outside the box. A translucent
  fill, such as an outline button's hover tint or a transparent elevated
  surface, no longer shows its own shadow through it. Added
  `PanelBoxDecoration`, `PanelShapeDecoration` and `paintPanelShadows`.
- The checkbox and switch hover colours mix in Oklab, as the web package's
  `color-mix(in oklab, …)` does.
- The checkbox, switch, radio, chip and toggle button now ease into and out
  of their hover look over the web package's 150–200ms, rather than
  switching at once. Selection still lands at once, as in PanelUI. Added
  `PanelHoverFade`.
- Gallery: the sidebar keeps its scroll position when a page opens.

## 0.1.0

The first release of the port.

### Added

- Theme foundation: PanelUI's 58 colour tokens and its radius scales,
  generated from PanelUI's `theme.css`, for the Panel, Moon and Grass
  families in light and dark. `PanelThemeData` is a `ThemeExtension`, with
  `toMaterialTheme()`, `PanelTheme`, `AnimatedPanelTheme`, a type scale,
  shadows and PanelUI's springs.
- `PanelPressable`, the shared press feedback (0.97 scale, spring release),
  with keyboard focus rings, hover, Enter/Space activation, PanelUI's hit
  slop and nested-press handling. `PanelFocusRing`, `PanelHitSlop`,
  `PanelCurves` (Reanimated's easings, exact) and `Color.mixOklab`.
- `PanelIcon` and `PanelIcons`, PanelUI's icon set on the same HugeIcons
  glyphs, painted directly at each glyph's PanelUI default size.
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
- A gallery app in `example/`, grouped by PanelUI's categories and published
  to GitHub Pages from `main`.

Every component was checked against PanelUI's source, value for value: sizes,
colours, radii, type, motion, interaction and accessibility.
