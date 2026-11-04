# Porting a PanelUI component to Flutter

PanelUI's components are React Native, styled with Tailwind classes through
Uniwind and animated with Reanimated. Each one has a `tv()` table of slots and
variants that is, in effect, its visual spec. Porting a component means
reading that table and the component's behaviour, and rebuilding both on this
package's foundation, so the result looks and moves the same.

The source of a component is
`packages/panelui/src/components/<name>/index.tsx` in
[panel-ui/PanelUI](https://github.com/panel-ui/PanelUI). Read the whole file:
the comments explain why things are shaped the way they are, and that reasoning
usually carries over.

## Where things live

| Path | What |
| --- | --- |
| `lib/src/theme/panel_tokens.dart` | `PanelColors` (58 tokens) and `PanelRadii`, generated from PanelUI's `theme.css` by `tool/generate_tokens.dart`. Never edit by hand. |
| `lib/src/theme/panel_theme_data.dart` | `PanelThemeData` (a `ThemeExtension`), the six built-in themes, `PanelThemeFamily`, `toMaterialTheme()`. |
| `lib/src/theme/panel_theme.dart` | `PanelTheme.of(context)`, `AnimatedPanelTheme`, `context.panelTheme`. |
| `lib/src/theme/panel_typography.dart` | `PanelTextSize`, `PanelTypography` (`style`, `sized`, `mono`), `PanelShadows`. |
| `lib/src/theme/panel_motion.dart` | `PanelSprings`, `PanelDurations`, `panelEase`, `controller.springTo()`, `panelReduceMotion()`. |
| `lib/src/foundation/panel_pressable.dart` | `PanelPressable`: press feedback, focus, hover, keyboard activation, semantics. |
| `lib/src/foundation/panel_text.dart` | `PanelText`. |
| `lib/src/icons/` | `PanelIcon` and `PanelIcons` (PanelUI's icon names mapped onto the same HugeIcons glyphs). |
| `lib/src/components/<name>.dart` | One file per component, or per small family of components. |
| `example/lib/demos/` | Gallery demos. |
| `test/components/<name>_test.dart` | Widget tests. `test/helpers.dart` has `wrap()`. |

Reference ports to read before starting: `button.dart` (variants, sizes,
palette resolution, a group scope), `checkbox.dart` (a spring-driven control),
`switch.dart` and `input.dart` (a focus-driven animation and a shared frame).

## Translating the Tailwind classes

| PanelUI | Flutter |
| --- | --- |
| `bg-primary`, `text-muted-foreground`, `border-border` | `theme.colors.primary`, `.mutedForeground`, `.border` (kebab-case becomes camelCase) |
| `bg-success/16` | `c.success.withValues(alpha: 0.16)` |
| `rounded-sm` … `rounded-3xl` | `theme.radii.sm` … `theme.radii.xxxl` (`2xl` is `xxl`, `3xl` is `xxxl`). Never a number: the radius belongs to the theme family. |
| `rounded-full` | `BorderRadius.circular(height / 2)` or `BoxShape.circle` |
| `p-4`, `px-3.5`, `gap-1.5`, `h-11` | 16, 14, 6, 44. One Tailwind step is 4 logical pixels. |
| `text-sm`, `text-lg`, … | `theme.typography.style(PanelTextSize.sm, weight: …, color: …)`. These carry Tailwind's paired line height. |
| `text-[13px]` (a bare size) | `theme.typography.sized(13, …)`: size only, the font's own line height. |
| `font-medium` / `font-semibold` / `font-bold` | `FontWeight.w500` / `w600` / `w700` |
| `leading-tight` / `leading-normal` | `.copyWith(height: 1.25)` / `1.5` |
| `shadow-sm`, `shadow-lg` | `theme.shadows.sm`, `theme.shadows.lg` |
| `opacity-[0.64]` on a disabled control | `Opacity(opacity: 0.64)` |
| `border` | `Border.all(color: …)`. A `Container` adds the border width to its padding, the same box CSS's `border-box` draws. |
| `flex-row gap-2` | `Row(spacing: 8)` |
| `self-start`, `items-center` | `Align`, `crossAxisAlignment` |

Text styles are built with `inherit: false`, so Material's default text style
(with its letter spacing) does not leak into a component. To style a `Widget`
slot that will usually be a `Text`, wrap it in a `DefaultTextStyle` with the
style the slot has in PanelUI.

## Motion

PanelUI animates on Reanimated. Its springs take the same three parameters as
Flutter's `SpringDescription`, so they port exactly.

| Reanimated | Flutter |
| --- | --- |
| `withSpring(x, { damping, stiffness, mass })` | `controller.springTo(x, PanelSprings.…)` on an `AnimationController.unbounded` (a bounded controller clamps the overshoot away). Every spring lives in `PanelSprings`, named for what it moves; add one there, documented, rather than a private copy. |
| `withTiming(x, { duration })` | `controller.animateTo(x, duration: …, curve: panelEase)` |
| `FadeIn.duration(150)`, `FadeOut.duration(120)` | `PanelDurations.fadeIn`, `PanelDurations.fadeOut` |
| `useReducedMotion()` | `panelReduceMotion(context)`. Do what the source does under it: usually jump to the end, sometimes a gentler variant (a spinner pulses instead of turning). |

Drive several properties from one controller where the source drives them from
one shared value (a switch's thumb position and track fill).

## Interaction and accessibility

- Anything pressable goes through `PanelPressable`. It gives the 0.97 press
  scale (set `pressScale: 1` where the source uses a plain `Pressable`), a
  keyboard focus ring (pass `focusRingRadius`), hover, and Enter/Space
  activation. Use its `builder:` to style by `pressed`, `hovered` and
  `focused`.
- PanelUI's `hitSlop` is `PanelPressable(hitSlop:)`, or `PanelHitSlop` around
  anything else. It reaches only as far as the parent's own bounds, as in
  React Native.
- State a control's `expanded`, `semanticValue` and `semanticRole` on
  `PanelPressable` rather than nesting a `Semantics` that relies on merging.
- Carry PanelUI's accessibility state over to `Semantics` flags: `checked`,
  `mixed`, `toggled`, `selected`, `inMutuallyExclusiveGroup`, a label, a hint,
  `liveRegion` for announcements. Hide decoration with `ExcludeSemantics`.
- A null callback disables a control, as in Flutter's own widgets.
- On the web and desktop, follow PanelUI's web package
  (`packages/web/src/components`) for hover states where it has one, such as
  `hover:bg-accent` or `hover:bg-primary/90`.

## API conventions

- Public widgets are prefixed `Panel` (`PanelTabs`), so they never collide with
  Material's `Tab`, `Switch` or `Badge`. Enums are `Panel<Component><Prop>`.
- Dart has no `default` identifier. Name PanelUI's `default` variant for what it
  is (`neutral`, `plain`, `primary`) and say so in the doc comment.
- Controlled widgets take `value` and `onChanged`, the Flutter convention, in
  place of PanelUI's `checked`/`onCheckedChange` and `value`/`onValueChange`.
- `startContent` / `endContent` become `leading` / `trailing`.
- Compound parts (`Card.Header`) become either separate widgets
  (`PanelCardHeader`) or named slots (`title:`), whichever reads better in a
  widget tree. Slots that hold text are `Widget`s styled through
  `DefaultTextStyle`; form-control labels stay `String`, as in PanelUI.
- Colours come only from tokens. The one exception is a literal the source
  hardcodes on purpose, such as a switch thumb's white.
- Every public member has a `///` comment (the `public_member_api_docs` lint is
  on). Say what it is for; keep the *why* where it changes what a reader does.

## Overlays

Build on Flutter's own layers rather than inventing one:

- Dialogs and sheets: a route (`showGeneralDialog`, `RawDialogRoute`, or a
  `PopupRoute`) with the PanelUI scrim fade and entrance spring.
- Toasts: an `OverlayEntry` in the root `Overlay`, managed by a small
  controller.
- Tooltips, popovers, selects and menus: `AnchoredOverlay` in
  `lib/src/foundation/anchored_overlay.dart`, which places a panel against
  its trigger with PanelUI's rules (flip, then clamp inside the safe area),
  and handles outside taps, Escape, the back button and focus. Reuse it for
  anything anchored.

Three things that are easy to trip over:

- A route whose motion is a spring can return a `SpringSimulation` from
  `TransitionRoute.createSimulation` instead of using a duration and curve.
- `OverlayPortalController.show()` cannot be called during a build; defer it
  a frame.
- While a popup built with `OverlayPortal.overlayChildLayoutBuilder` is open,
  `tester.hasRunningAnimations` stays true, so close it before a test ends or
  pump a fixed duration instead of `pumpAndSettle()`.

## Testing

- One `test/components/<name>_test.dart` per component file. Pump through
  `wrap()` from `test/helpers.dart`, which supplies a `MaterialApp` and a theme.
- Test behaviour: callbacks fire with the right values, state changes show,
  disabled controls ignore input, semantics flags are set, and the component
  builds without exceptions in every built-in theme.
- `await tester.pumpAndSettle()` after anything that animates.

## Gallery

Add a `GalleryDemo` with realistic content to the demo file for the batch in
`example/lib/demos/`, and register the list in `registry.dart`.
