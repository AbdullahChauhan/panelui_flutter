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
- Components: see [docs/COMPONENTS.md](docs/COMPONENTS.md).
- A gallery app in `example/`.
