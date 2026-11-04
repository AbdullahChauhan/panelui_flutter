import 'package:flutter/material.dart';
import 'package:panelui_flutter/panelui_flutter.dart';

/// One entry in the gallery: a component and its demo.
class GalleryDemo {
  const GalleryDemo({
    required this.id,
    required this.title,
    required this.description,
    required this.builder,
  });

  /// URL-safe identifier, used by `?demo=<id>`.
  final String id;

  /// The component's name.
  final String title;

  /// What it is for, in a sentence.
  final String description;

  /// Builds the demo.
  final WidgetBuilder builder;
}

/// A titled section with the demo drawn in a bordered preview well, the way
/// PanelUI's documentation presents a component.
class GallerySection extends StatelessWidget {
  const GallerySection({super.key, required this.demo});

  final GalleryDemo demo;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final c = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            PanelText(
              demo.title,
              size: PanelTextSize.lg,
              weight: FontWeight.w600,
            ),
            PanelText(demo.description, size: PanelTextSize.sm, muted: true),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(theme.radii.xl),
            border: Border.all(color: c.border),
          ),
          child: Builder(builder: demo.builder),
        ),
      ],
    );
  }
}

/// A labelled row of examples inside a demo.
class DemoGroup extends StatelessWidget {
  const DemoGroup({
    super.key,
    required this.label,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.crossAxisAlignment = WrapCrossAlignment.center,
  });

  final String label;
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapCrossAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        PanelText(
          label.toUpperCase(),
          size: PanelTextSize.xs,
          weight: FontWeight.w500,
          muted: true,
          style: const TextStyle(letterSpacing: 0.6),
        ),
        Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          crossAxisAlignment: crossAxisAlignment,
          children: children,
        ),
      ],
    );
  }
}

/// Stacks demo groups with even spacing.
class DemoStack extends StatelessWidget {
  const DemoStack({super.key, required this.children, this.spacing = 24});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing,
      children: children,
    );
  }
}
