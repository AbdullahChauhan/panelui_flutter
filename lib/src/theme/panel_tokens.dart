// GENERATED CODE. Do not edit by hand.
//
// Source: PanelUI's packages/panelui/theme.css (MIT License,
// Copyright (c) 2026 Khalid Abdi).
// Regenerate with: dart run tool/generate_tokens.dart <theme.css>

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The semantic colour tokens of a PanelUI theme.
///
/// Components never hardcode a colour: every fill, border and text colour
/// resolves to one of these, so switching the theme recolours everything.
@immutable
class PanelColors with Diagnosticable {
  /// Creates a colour set. Every token is required.
  const PanelColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.overlay,
    required this.overlayForeground,
    required this.inset,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.destructiveSolidForeground,
    required this.info,
    required this.infoForeground,
    required this.infoSolidForeground,
    required this.success,
    required this.successForeground,
    required this.successSolidForeground,
    required this.warning,
    required this.warningForeground,
    required this.warningSolidForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.skeleton,
    required this.infoSoft,
    required this.infoSubtle,
    required this.successSoft,
    required this.successSubtle,
    required this.warningSoft,
    required this.warningSubtle,
    required this.destructiveSoft,
    required this.destructiveSubtle,
    required this.codeKeyword,
    required this.codeString,
    required this.codeNumber,
    required this.codeComment,
    required this.codeFunction,
    required this.codeProperty,
    required this.codePunctuation,
    required this.codeInserted,
    required this.codeDeleted,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
  });

  /// The `light` theme from PanelUI.
  static const PanelColors panelLight = PanelColors(
    background: Color(0xFFFFFFFF), // #ffffff
    foreground: Color(0xFF262626), // #262626
    card: Color(0xFFFFFFFF), // #ffffff
    cardForeground: Color(0xFF262626), // #262626
    popover: Color(0xFFFFFFFF), // #ffffff
    popoverForeground: Color(0xFF262626), // #262626
    overlay: Color(0xFFFFFFFF), // #ffffff
    overlayForeground: Color(0xFF262626), // #262626
    inset: Color(0x09000000), // rgba(0, 0, 0, 0.035)
    primary: Color(0xFF262626), // #262626
    primaryForeground: Color(0xFFFAFAFA), // #fafafa
    secondary: Color(0x0F000000), // rgba(0, 0, 0, 0.06)
    secondaryForeground: Color(0xFF262626), // #262626
    muted: Color(0x0F000000), // rgba(0, 0, 0, 0.06)
    mutedForeground: Color(0xFF686868), // #686868
    accent: Color(0x0F000000), // rgba(0, 0, 0, 0.06)
    accentForeground: Color(0xFF262626), // #262626
    destructive: Color(0xFFEF4444), // #ef4444
    destructiveForeground: Color(0xFFB91C1C), // #b91c1c
    destructiveSolidForeground: Color(0xFF171717), // #171717
    info: Color(0xFF3B82F6), // #3b82f6
    infoForeground: Color(0xFF1D4ED8), // #1d4ed8
    infoSolidForeground: Color(0xFF171717), // #171717
    success: Color(0xFF10B981), // #10b981
    successForeground: Color(0xFF047857), // #047857
    successSolidForeground: Color(0xFF171717), // #171717
    warning: Color(0xFFF59E0B), // #f59e0b
    warningForeground: Color(0xFFB45309), // #b45309
    warningSolidForeground: Color(0xFF171717), // #171717
    border: Color(0x14000000), // rgba(0, 0, 0, 0.08)
    input: Color(0x1A000000), // rgba(0, 0, 0, 0.1)
    ring: Color(0xFFA3A3A3), // #a3a3a3
    surface: Color(0xFFF7F7F7), // #f7f7f7
    surfaceSecondary: Color(0xFFF1F1F1), // #f1f1f1
    surfaceTertiary: Color(0xFFEAEAEA), // #eaeaea
    skeleton: Color(0x1A000000), // rgba(0, 0, 0, 0.1)
    infoSoft: Color(0x1A3B82F6), // rgba(59, 130, 246, 0.1)
    infoSubtle: Color(0x143B82F6), // rgba(59, 130, 246, 0.08)
    successSoft: Color(0x1A10B981), // rgba(16, 185, 129, 0.1)
    successSubtle: Color(0x1410B981), // rgba(16, 185, 129, 0.08)
    warningSoft: Color(0x1AF59E0B), // rgba(245, 158, 11, 0.1)
    warningSubtle: Color(0x14F59E0B), // rgba(245, 158, 11, 0.08)
    destructiveSoft: Color(0x1AEF4444), // rgba(239, 68, 68, 0.1)
    destructiveSubtle: Color(0x14EF4444), // rgba(239, 68, 68, 0.08)
    codeKeyword: Color(0xFF8250DF), // #8250df
    codeString: Color(0xFF0A7D55), // #0a7d55
    codeNumber: Color(0xFF0550AE), // #0550ae
    codeComment: Color(0xFF8B949E), // #8b949e
    codeFunction: Color(0xFF6639BA), // #6639ba
    codeProperty: Color(0xFF953800), // #953800
    codePunctuation: Color(0xFF57606A), // #57606a
    codeInserted: Color(0xFF0A7D55), // #0a7d55
    codeDeleted: Color(0xFFCF222E), // #cf222e
    chart1: Color(0xFF262626), // #262626
    chart2: Color(0xFF3B82F6), // #3b82f6
    chart3: Color(0xFF10B981), // #10b981
    chart4: Color(0xFFF59E0B), // #f59e0b
    chart5: Color(0xFF8B5CF6), // #8b5cf6
  );

  /// The `dark` theme from PanelUI.
  static const PanelColors panelDark = PanelColors(
    background: Color(0xFF141414), // #141414
    foreground: Color(0xFFF5F5F5), // #f5f5f5
    card: Color(0xFF191919), // #191919
    cardForeground: Color(0xFFF5F5F5), // #f5f5f5
    popover: Color(0xFF1D1D1D), // #1d1d1d
    popoverForeground: Color(0xFFF5F5F5), // #f5f5f5
    overlay: Color(0xFF232323), // #232323
    overlayForeground: Color(0xFFF5F5F5), // #f5f5f5
    inset: Color(0x38000000), // rgba(0, 0, 0, 0.22)
    primary: Color(0xFFF5F5F5), // #f5f5f5
    primaryForeground: Color(0xFF262626), // #262626
    secondary: Color(0x14FFFFFF), // rgba(255, 255, 255, 0.08)
    secondaryForeground: Color(0xFFF5F5F5), // #f5f5f5
    muted: Color(0x14FFFFFF), // rgba(255, 255, 255, 0.08)
    mutedForeground: Color(0xFF878787), // #878787
    accent: Color(0x14FFFFFF), // rgba(255, 255, 255, 0.08)
    accentForeground: Color(0xFFF5F5F5), // #f5f5f5
    destructive: Color(0xFFF15757), // #f15757
    destructiveForeground: Color(0xFFF87171), // #f87171
    destructiveSolidForeground: Color(0xFF171717), // #171717
    info: Color(0xFF3B82F6), // #3b82f6
    infoForeground: Color(0xFF60A5FA), // #60a5fa
    infoSolidForeground: Color(0xFF171717), // #171717
    success: Color(0xFF10B981), // #10b981
    successForeground: Color(0xFF34D399), // #34d399
    successSolidForeground: Color(0xFF171717), // #171717
    warning: Color(0xFFF59E0B), // #f59e0b
    warningForeground: Color(0xFFFBBF24), // #fbbf24
    warningSolidForeground: Color(0xFF171717), // #171717
    border: Color(0x0FFFFFFF), // rgba(255, 255, 255, 0.06)
    input: Color(0x14FFFFFF), // rgba(255, 255, 255, 0.08)
    ring: Color(0xFF737373), // #737373
    surface: Color(0xFF1C1C1C), // #1c1c1c
    surfaceSecondary: Color(0xFF222222), // #222222
    surfaceTertiary: Color(0xFF282828), // #282828
    skeleton: Color(0x21FFFFFF), // rgba(255, 255, 255, 0.13)
    infoSoft: Color(0x0F3B82F6), // rgba(59, 130, 246, 0.06)
    infoSubtle: Color(0x293B82F6), // rgba(59, 130, 246, 0.16)
    successSoft: Color(0x0F10B981), // rgba(16, 185, 129, 0.06)
    successSubtle: Color(0x2910B981), // rgba(16, 185, 129, 0.16)
    warningSoft: Color(0x0FF59E0B), // rgba(245, 158, 11, 0.06)
    warningSubtle: Color(0x29F59E0B), // rgba(245, 158, 11, 0.16)
    destructiveSoft: Color(0x0FF15757), // rgba(241, 87, 87, 0.06)
    destructiveSubtle: Color(0x29F15757), // rgba(241, 87, 87, 0.16)
    codeKeyword: Color(0xFFD2A8FF), // #d2a8ff
    codeString: Color(0xFF7EE787), // #7ee787
    codeNumber: Color(0xFF79C0FF), // #79c0ff
    codeComment: Color(0xFF8B949E), // #8b949e
    codeFunction: Color(0xFFD2A8FF), // #d2a8ff
    codeProperty: Color(0xFFFFA657), // #ffa657
    codePunctuation: Color(0xFF8B949E), // #8b949e
    codeInserted: Color(0xFF7EE787), // #7ee787
    codeDeleted: Color(0xFFFF7B72), // #ff7b72
    chart1: Color(0xFFFAFAFA), // #fafafa
    chart2: Color(0xFF60A5FA), // #60a5fa
    chart3: Color(0xFF34D399), // #34d399
    chart4: Color(0xFFFBBF24), // #fbbf24
    chart5: Color(0xFFA78BFA), // #a78bfa
  );

  /// The `moon` theme from PanelUI.
  static const PanelColors moonLight = PanelColors(
    background: Color(0xFFFFFFFF), // #ffffff
    foreground: Color(0xFF08090A), // #08090a
    card: Color(0xFFFFFFFF), // #ffffff
    cardForeground: Color(0xFF08090A), // #08090a
    popover: Color(0xFFFFFFFF), // #ffffff
    popoverForeground: Color(0xFF08090A), // #08090a
    overlay: Color(0xFFFFFFFF), // #ffffff
    overlayForeground: Color(0xFF08090A), // #08090a
    inset: Color(0x09000000), // rgba(0, 0, 0, 0.035)
    primary: Color(0xFF5E6AD2), // #5e6ad2
    primaryForeground: Color(0xFFFFFFFF), // #ffffff
    secondary: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
    secondaryForeground: Color(0xFF08090A), // #08090a
    muted: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
    mutedForeground: Color(0xFF6B6F76), // #6b6f76
    accent: Color(0x0F000000), // rgba(0, 0, 0, 0.06)
    accentForeground: Color(0xFF08090A), // #08090a
    destructive: Color(0xFFEB5757), // #eb5757
    destructiveForeground: Color(0xFFC62B30), // #c62b30
    destructiveSolidForeground: Color(0xFF08090A), // #08090a
    info: Color(0xFF4EA7FC), // #4ea7fc
    infoForeground: Color(0xFF0B6EC4), // #0b6ec4
    infoSolidForeground: Color(0xFF08090A), // #08090a
    success: Color(0xFF27A644), // #27a644
    successForeground: Color(0xFF1C7A32), // #1c7a32
    successSolidForeground: Color(0xFF08090A), // #08090a
    warning: Color(0xFFF2C94C), // #f2c94c
    warningForeground: Color(0xFF8A6D0B), // #8a6d0b
    warningSolidForeground: Color(0xFF08090A), // #08090a
    border: Color(0x14000000), // rgba(0, 0, 0, 0.08)
    input: Color(0x1F000000), // rgba(0, 0, 0, 0.12)
    ring: Color(0xFF5E6AD2), // #5e6ad2
    surface: Color(0xFFF5F6F6), // #f5f6f6
    surfaceSecondary: Color(0xFFF6F7F7), // #f6f7f7
    surfaceTertiary: Color(0xFFEEEFF1), // #eeeff1
    skeleton: Color(0x12000000), // rgba(0, 0, 0, 0.07)
    infoSoft: Color(0x1A4EA7FC), // rgba(78, 167, 252, 0.1)
    infoSubtle: Color(0x144EA7FC), // rgba(78, 167, 252, 0.08)
    successSoft: Color(0x1A27A644), // rgba(39, 166, 68, 0.1)
    successSubtle: Color(0x1427A644), // rgba(39, 166, 68, 0.08)
    warningSoft: Color(0x24F2C94C), // rgba(242, 201, 76, 0.14)
    warningSubtle: Color(0x1AF2C94C), // rgba(242, 201, 76, 0.1)
    destructiveSoft: Color(0x1AEB5757), // rgba(235, 87, 87, 0.1)
    destructiveSubtle: Color(0x14EB5757), // rgba(235, 87, 87, 0.08)
    codeKeyword: Color(0xFF5E6AD2), // #5e6ad2
    codeString: Color(0xFF1C7A32), // #1c7a32
    codeNumber: Color(0xFF0B6EC4), // #0b6ec4
    codeComment: Color(0xFF8A8F98), // #8a8f98
    codeFunction: Color(0xFF6639BA), // #6639ba
    codeProperty: Color(0xFF953800), // #953800
    codePunctuation: Color(0xFF62666D), // #62666d
    codeInserted: Color(0xFF1C7A32), // #1c7a32
    codeDeleted: Color(0xFFCF222E), // #cf222e
    chart1: Color(0xFF5E6AD2), // #5e6ad2
    chart2: Color(0xFF4EA7FC), // #4ea7fc
    chart3: Color(0xFF27A644), // #27a644
    chart4: Color(0xFFF2C94C), // #f2c94c
    chart5: Color(0xFF7A7FAD), // #7a7fad
  );

  /// The `moon-dark` theme from PanelUI.
  static const PanelColors moonDark = PanelColors(
    background: Color(0xFF010102), // #010102
    foreground: Color(0xFFF7F8F8), // #f7f8f8
    card: Color(0xFF0F1011), // #0f1011
    cardForeground: Color(0xFFF7F8F8), // #f7f8f8
    popover: Color(0xFF141516), // #141516
    popoverForeground: Color(0xFFF7F8F8), // #f7f8f8
    overlay: Color(0xFF18191A), // #18191a
    overlayForeground: Color(0xFFF7F8F8), // #f7f8f8
    inset: Color(0x38000000), // rgba(0, 0, 0, 0.22)
    primary: Color(0xFF5E6AD2), // #5e6ad2
    primaryForeground: Color(0xFFFFFFFF), // #ffffff
    secondary: Color(0x0FFFFFFF), // rgba(255, 255, 255, 0.06)
    secondaryForeground: Color(0xFFF7F8F8), // #f7f8f8
    muted: Color(0x0FFFFFFF), // rgba(255, 255, 255, 0.06)
    mutedForeground: Color(0xFF8A8F98), // #8a8f98
    accent: Color(0x14FFFFFF), // rgba(255, 255, 255, 0.08)
    accentForeground: Color(0xFFF7F8F8), // #f7f8f8
    destructive: Color(0xFFEB5757), // #eb5757
    destructiveForeground: Color(0xFFFF8A8A), // #ff8a8a
    destructiveSolidForeground: Color(0xFF08090A), // #08090a
    info: Color(0xFF4EA7FC), // #4ea7fc
    infoForeground: Color(0xFF8EC5FF), // #8ec5ff
    infoSolidForeground: Color(0xFF08090A), // #08090a
    success: Color(0xFF27A644), // #27a644
    successForeground: Color(0xFF4CC061), // #4cc061
    successSolidForeground: Color(0xFF08090A), // #08090a
    warning: Color(0xFFF2C94C), // #f2c94c
    warningForeground: Color(0xFFF5D97A), // #f5d97a
    warningSolidForeground: Color(0xFF08090A), // #08090a
    border: Color(0xFF23252A), // #23252a
    input: Color(0xFF34343A), // #34343a
    ring: Color(0xFF5E6AD2), // #5e6ad2
    surface: Color(0xFF0F1011), // #0f1011
    surfaceSecondary: Color(0xFF141516), // #141516
    surfaceTertiary: Color(0xFF18191A), // #18191a
    skeleton: Color(0x14FFFFFF), // rgba(255, 255, 255, 0.08)
    infoSoft: Color(0x294EA7FC), // rgba(78, 167, 252, 0.16)
    infoSubtle: Color(0x1A4EA7FC), // rgba(78, 167, 252, 0.1)
    successSoft: Color(0x2E27A644), // rgba(39, 166, 68, 0.18)
    successSubtle: Color(0x1F27A644), // rgba(39, 166, 68, 0.12)
    warningSoft: Color(0x29F2C94C), // rgba(242, 201, 76, 0.16)
    warningSubtle: Color(0x1AF2C94C), // rgba(242, 201, 76, 0.1)
    destructiveSoft: Color(0x29EB5757), // rgba(235, 87, 87, 0.16)
    destructiveSubtle: Color(0x1AEB5757), // rgba(235, 87, 87, 0.1)
    codeKeyword: Color(0xFF828FFF), // #828fff
    codeString: Color(0xFF4CC061), // #4cc061
    codeNumber: Color(0xFF8EC5FF), // #8ec5ff
    codeComment: Color(0xFF62666D), // #62666d
    codeFunction: Color(0xFFD2A8FF), // #d2a8ff
    codeProperty: Color(0xFFFFA657), // #ffa657
    codePunctuation: Color(0xFF8A8F98), // #8a8f98
    codeInserted: Color(0xFF4CC061), // #4cc061
    codeDeleted: Color(0xFFFF8A8A), // #ff8a8a
    chart1: Color(0xFF5E6AD2), // #5e6ad2
    chart2: Color(0xFF4EA7FC), // #4ea7fc
    chart3: Color(0xFF27A644), // #27a644
    chart4: Color(0xFFF2C94C), // #f2c94c
    chart5: Color(0xFF7A7FAD), // #7a7fad
  );

  /// The `grass` theme from PanelUI.
  static const PanelColors grassLight = PanelColors(
    background: Color(0xFFFFFFFF), // #ffffff
    foreground: Color(0xFF171717), // #171717
    card: Color(0xFFFFFFFF), // #ffffff
    cardForeground: Color(0xFF171717), // #171717
    popover: Color(0xFFFFFFFF), // #ffffff
    popoverForeground: Color(0xFF171717), // #171717
    overlay: Color(0xFFFFFFFF), // #ffffff
    overlayForeground: Color(0xFF171717), // #171717
    inset: Color(0x09000000), // rgba(0, 0, 0, 0.035)
    primary: Color(0xFF24B47E), // #24b47e
    primaryForeground: Color(0xFF052E1B), // #052e1b
    secondary: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
    secondaryForeground: Color(0xFF171717), // #171717
    muted: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
    mutedForeground: Color(0xFF707070), // #707070
    accent: Color(0x1A3ECF8E), // rgba(62, 207, 142, 0.1)
    accentForeground: Color(0xFF16794C), // #16794c
    destructive: Color(0xFFEF4444), // #ef4444
    destructiveForeground: Color(0xFFB91C1C), // #b91c1c
    destructiveSolidForeground: Color(0xFF171717), // #171717
    info: Color(0xFF3B82F6), // #3b82f6
    infoForeground: Color(0xFF1D4ED8), // #1d4ed8
    infoSolidForeground: Color(0xFF171717), // #171717
    success: Color(0xFF24B47E), // #24b47e
    successForeground: Color(0xFF16794C), // #16794c
    successSolidForeground: Color(0xFF171717), // #171717
    warning: Color(0xFFF59E0B), // #f59e0b
    warningForeground: Color(0xFFB45309), // #b45309
    warningSolidForeground: Color(0xFF171717), // #171717
    border: Color(0x14000000), // rgba(0, 0, 0, 0.08)
    input: Color(0x1A000000), // rgba(0, 0, 0, 0.1)
    ring: Color(0xFF3ECF8E), // #3ecf8e
    surface: Color(0xFFF8F9FA), // #f8f9fa
    surfaceSecondary: Color(0xFFF1F3F5), // #f1f3f5
    surfaceTertiary: Color(0xFFE9ECEF), // #e9ecef
    skeleton: Color(0x14000000), // rgba(0, 0, 0, 0.08)
    infoSoft: Color(0x1A3B82F6), // rgba(59, 130, 246, 0.1)
    infoSubtle: Color(0x143B82F6), // rgba(59, 130, 246, 0.08)
    successSoft: Color(0x1A24B47E), // rgba(36, 180, 126, 0.1)
    successSubtle: Color(0x1424B47E), // rgba(36, 180, 126, 0.08)
    warningSoft: Color(0x1AF59E0B), // rgba(245, 158, 11, 0.1)
    warningSubtle: Color(0x14F59E0B), // rgba(245, 158, 11, 0.08)
    destructiveSoft: Color(0x1AEF4444), // rgba(239, 68, 68, 0.1)
    destructiveSubtle: Color(0x14EF4444), // rgba(239, 68, 68, 0.08)
    codeKeyword: Color(0xFF8250DF), // #8250df
    codeString: Color(0xFF0A7D55), // #0a7d55
    codeNumber: Color(0xFF0550AE), // #0550ae
    codeComment: Color(0xFF8B949E), // #8b949e
    codeFunction: Color(0xFF6639BA), // #6639ba
    codeProperty: Color(0xFF953800), // #953800
    codePunctuation: Color(0xFF57606A), // #57606a
    codeInserted: Color(0xFF0A7D55), // #0a7d55
    codeDeleted: Color(0xFFCF222E), // #cf222e
    chart1: Color(0xFF24B47E), // #24b47e
    chart2: Color(0xFF1F2937), // #1f2937
    chart3: Color(0xFF2563EB), // #2563eb
    chart4: Color(0xFFF59E0B), // #f59e0b
    chart5: Color(0xFFDB2777), // #db2777
  );

  /// The `grass-dark` theme from PanelUI.
  static const PanelColors grassDark = PanelColors(
    background: Color(0xFF1C1C1C), // #1c1c1c
    foreground: Color(0xFFEDEDED), // #ededed
    card: Color(0xFF1F1F1F), // #1f1f1f
    cardForeground: Color(0xFFEDEDED), // #ededed
    popover: Color(0xFF232323), // #232323
    popoverForeground: Color(0xFFEDEDED), // #ededed
    overlay: Color(0xFF2A2A2A), // #2a2a2a
    overlayForeground: Color(0xFFEDEDED), // #ededed
    inset: Color(0x38000000), // rgba(0, 0, 0, 0.22)
    primary: Color(0xFF3ECF8E), // #3ecf8e
    primaryForeground: Color(0xFF052E1B), // #052e1b
    secondary: Color(0x12FFFFFF), // rgba(255, 255, 255, 0.07)
    secondaryForeground: Color(0xFFEDEDED), // #ededed
    muted: Color(0x12FFFFFF), // rgba(255, 255, 255, 0.07)
    mutedForeground: Color(0xFF8F8F8F), // #8f8f8f
    accent: Color(0x1F3ECF8E), // rgba(62, 207, 142, 0.12)
    accentForeground: Color(0xFF3ECF8E), // #3ecf8e
    destructive: Color(0xFFF15757), // #f15757
    destructiveForeground: Color(0xFFF87171), // #f87171
    destructiveSolidForeground: Color(0xFF171717), // #171717
    info: Color(0xFF3B82F6), // #3b82f6
    infoForeground: Color(0xFF60A5FA), // #60a5fa
    infoSolidForeground: Color(0xFF171717), // #171717
    success: Color(0xFF3ECF8E), // #3ecf8e
    successForeground: Color(0xFF4ADE80), // #4ade80
    successSolidForeground: Color(0xFF171717), // #171717
    warning: Color(0xFFF59E0B), // #f59e0b
    warningForeground: Color(0xFFFBBF24), // #fbbf24
    warningSolidForeground: Color(0xFF171717), // #171717
    border: Color(0x12FFFFFF), // rgba(255, 255, 255, 0.07)
    input: Color(0x1AFFFFFF), // rgba(255, 255, 255, 0.1)
    ring: Color(0xFF3ECF8E), // #3ecf8e
    surface: Color(0xFF242424), // #242424
    surfaceSecondary: Color(0xFF2A2A2A), // #2a2a2a
    surfaceTertiary: Color(0xFF303030), // #303030
    skeleton: Color(0x1CFFFFFF), // rgba(255, 255, 255, 0.11)
    infoSoft: Color(0x143B82F6), // rgba(59, 130, 246, 0.08)
    infoSubtle: Color(0x293B82F6), // rgba(59, 130, 246, 0.16)
    successSoft: Color(0x143ECF8E), // rgba(62, 207, 142, 0.08)
    successSubtle: Color(0x293ECF8E), // rgba(62, 207, 142, 0.16)
    warningSoft: Color(0x14F59E0B), // rgba(245, 158, 11, 0.08)
    warningSubtle: Color(0x29F59E0B), // rgba(245, 158, 11, 0.16)
    destructiveSoft: Color(0x14F15757), // rgba(241, 87, 87, 0.08)
    destructiveSubtle: Color(0x29F15757), // rgba(241, 87, 87, 0.16)
    codeKeyword: Color(0xFFD2A8FF), // #d2a8ff
    codeString: Color(0xFF7EE787), // #7ee787
    codeNumber: Color(0xFF79C0FF), // #79c0ff
    codeComment: Color(0xFF8B949E), // #8b949e
    codeFunction: Color(0xFFD2A8FF), // #d2a8ff
    codeProperty: Color(0xFFFFA657), // #ffa657
    codePunctuation: Color(0xFF8B949E), // #8b949e
    codeInserted: Color(0xFF7EE787), // #7ee787
    codeDeleted: Color(0xFFFF7B72), // #ff7b72
    chart1: Color(0xFF3ECF8E), // #3ecf8e
    chart2: Color(0xFFEDEDED), // #ededed
    chart3: Color(0xFF60A5FA), // #60a5fa
    chart4: Color(0xFFFBBF24), // #fbbf24
    chart5: Color(0xFFF472B6), // #f472b6
  );

  /// The page canvas.
  final Color background;

  /// Body text on [background].
  final Color foreground;

  /// Fill of a card.
  final Color card;

  /// Text on [card].
  final Color cardForeground;

  /// Fill of a floating surface: dialogs, popovers, toasts.
  final Color popover;

  /// Text on [popover].
  final Color popoverForeground;

  /// One step further forward than [popover], for menus opened over one.
  final Color overlay;

  /// Text on [overlay].
  final Color overlayForeground;

  /// A translucent band set into a surface, such as a footer of actions.
  final Color inset;

  /// The main action colour.
  final Color primary;

  /// Text and icons on [primary].
  final Color primaryForeground;

  /// A quiet filled control.
  final Color secondary;

  /// Text on [secondary].
  final Color secondaryForeground;

  /// A low-emphasis fill.
  final Color muted;

  /// Secondary text: descriptions, placeholders, captions.
  final Color mutedForeground;

  /// Hover and selection fill.
  final Color accent;

  /// Text on [accent].
  final Color accentForeground;

  /// Fill for a destructive action or an error state.
  final Color destructive;

  /// Destructive text on a neutral or soft fill.
  final Color destructiveForeground;

  /// Text on a solid [destructive] fill.
  final Color destructiveSolidForeground;

  /// Informational status colour.
  final Color info;

  /// Informational text on a neutral or soft fill.
  final Color infoForeground;

  /// Text on a solid [info] fill.
  final Color infoSolidForeground;

  /// Success status colour.
  final Color success;

  /// Success text on a neutral or soft fill.
  final Color successForeground;

  /// Text on a solid [success] fill.
  final Color successSolidForeground;

  /// Warning status colour.
  final Color warning;

  /// Warning text on a neutral or soft fill.
  final Color warningForeground;

  /// Text on a solid [warning] fill.
  final Color warningSolidForeground;

  /// Hairline borders and separators.
  final Color border;

  /// The resting border of a form control.
  final Color input;

  /// Focus rings and the focused border of a form control.
  final Color ring;

  /// First step of the elevation ladder (grouping surface).
  final Color surface;

  /// Second step of the elevation ladder.
  final Color surfaceSecondary;

  /// Third step of the elevation ladder.
  final Color surfaceTertiary;

  /// Fill of a loading placeholder.
  final Color skeleton;

  /// Tinted info fill for an alert.
  final Color infoSoft;

  /// Tinted info fill for a badge.
  final Color infoSubtle;

  /// Tinted success fill for an alert.
  final Color successSoft;

  /// Tinted success fill for a badge.
  final Color successSubtle;

  /// Tinted warning fill for an alert.
  final Color warningSoft;

  /// Tinted warning fill for a badge.
  final Color warningSubtle;

  /// Tinted destructive fill for an alert.
  final Color destructiveSoft;

  /// Tinted destructive fill for a badge.
  final Color destructiveSubtle;

  /// Syntax colour: keywords.
  final Color codeKeyword;

  /// Syntax colour: strings.
  final Color codeString;

  /// Syntax colour: numbers.
  final Color codeNumber;

  /// Syntax colour: comments.
  final Color codeComment;

  /// Syntax colour: function names.
  final Color codeFunction;

  /// Syntax colour: properties.
  final Color codeProperty;

  /// Syntax colour: punctuation.
  final Color codePunctuation;

  /// Syntax colour: inserted lines in a diff.
  final Color codeInserted;

  /// Syntax colour: deleted lines in a diff.
  final Color codeDeleted;

  /// Chart series 1, the series a chart is about.
  final Color chart1;

  /// Chart series 2.
  final Color chart2;

  /// Chart series 3.
  final Color chart3;

  /// Chart series 4.
  final Color chart4;

  /// Chart series 5.
  final Color chart5;

  /// Returns a copy with the given tokens replaced.
  PanelColors copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? popoverForeground,
    Color? overlay,
    Color? overlayForeground,
    Color? inset,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? destructiveSolidForeground,
    Color? info,
    Color? infoForeground,
    Color? infoSolidForeground,
    Color? success,
    Color? successForeground,
    Color? successSolidForeground,
    Color? warning,
    Color? warningForeground,
    Color? warningSolidForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? surface,
    Color? surfaceSecondary,
    Color? surfaceTertiary,
    Color? skeleton,
    Color? infoSoft,
    Color? infoSubtle,
    Color? successSoft,
    Color? successSubtle,
    Color? warningSoft,
    Color? warningSubtle,
    Color? destructiveSoft,
    Color? destructiveSubtle,
    Color? codeKeyword,
    Color? codeString,
    Color? codeNumber,
    Color? codeComment,
    Color? codeFunction,
    Color? codeProperty,
    Color? codePunctuation,
    Color? codeInserted,
    Color? codeDeleted,
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
  }) {
    return PanelColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      popover: popover ?? this.popover,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      overlay: overlay ?? this.overlay,
      overlayForeground: overlayForeground ?? this.overlayForeground,
      inset: inset ?? this.inset,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      destructiveSolidForeground:
          destructiveSolidForeground ?? this.destructiveSolidForeground,
      info: info ?? this.info,
      infoForeground: infoForeground ?? this.infoForeground,
      infoSolidForeground: infoSolidForeground ?? this.infoSolidForeground,
      success: success ?? this.success,
      successForeground: successForeground ?? this.successForeground,
      successSolidForeground:
          successSolidForeground ?? this.successSolidForeground,
      warning: warning ?? this.warning,
      warningForeground: warningForeground ?? this.warningForeground,
      warningSolidForeground:
          warningSolidForeground ?? this.warningSolidForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceTertiary: surfaceTertiary ?? this.surfaceTertiary,
      skeleton: skeleton ?? this.skeleton,
      infoSoft: infoSoft ?? this.infoSoft,
      infoSubtle: infoSubtle ?? this.infoSubtle,
      successSoft: successSoft ?? this.successSoft,
      successSubtle: successSubtle ?? this.successSubtle,
      warningSoft: warningSoft ?? this.warningSoft,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      destructiveSoft: destructiveSoft ?? this.destructiveSoft,
      destructiveSubtle: destructiveSubtle ?? this.destructiveSubtle,
      codeKeyword: codeKeyword ?? this.codeKeyword,
      codeString: codeString ?? this.codeString,
      codeNumber: codeNumber ?? this.codeNumber,
      codeComment: codeComment ?? this.codeComment,
      codeFunction: codeFunction ?? this.codeFunction,
      codeProperty: codeProperty ?? this.codeProperty,
      codePunctuation: codePunctuation ?? this.codePunctuation,
      codeInserted: codeInserted ?? this.codeInserted,
      codeDeleted: codeDeleted ?? this.codeDeleted,
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
    );
  }

  /// Interpolates every token between [a] and [b].
  static PanelColors lerp(PanelColors a, PanelColors b, double t) {
    if (identical(a, b)) return a;
    return PanelColors(
      background: Color.lerp(a.background, b.background, t)!,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      card: Color.lerp(a.card, b.card, t)!,
      cardForeground: Color.lerp(a.cardForeground, b.cardForeground, t)!,
      popover: Color.lerp(a.popover, b.popover, t)!,
      popoverForeground: Color.lerp(
        a.popoverForeground,
        b.popoverForeground,
        t,
      )!,
      overlay: Color.lerp(a.overlay, b.overlay, t)!,
      overlayForeground: Color.lerp(
        a.overlayForeground,
        b.overlayForeground,
        t,
      )!,
      inset: Color.lerp(a.inset, b.inset, t)!,
      primary: Color.lerp(a.primary, b.primary, t)!,
      primaryForeground: Color.lerp(
        a.primaryForeground,
        b.primaryForeground,
        t,
      )!,
      secondary: Color.lerp(a.secondary, b.secondary, t)!,
      secondaryForeground: Color.lerp(
        a.secondaryForeground,
        b.secondaryForeground,
        t,
      )!,
      muted: Color.lerp(a.muted, b.muted, t)!,
      mutedForeground: Color.lerp(a.mutedForeground, b.mutedForeground, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      accentForeground: Color.lerp(a.accentForeground, b.accentForeground, t)!,
      destructive: Color.lerp(a.destructive, b.destructive, t)!,
      destructiveForeground: Color.lerp(
        a.destructiveForeground,
        b.destructiveForeground,
        t,
      )!,
      destructiveSolidForeground: Color.lerp(
        a.destructiveSolidForeground,
        b.destructiveSolidForeground,
        t,
      )!,
      info: Color.lerp(a.info, b.info, t)!,
      infoForeground: Color.lerp(a.infoForeground, b.infoForeground, t)!,
      infoSolidForeground: Color.lerp(
        a.infoSolidForeground,
        b.infoSolidForeground,
        t,
      )!,
      success: Color.lerp(a.success, b.success, t)!,
      successForeground: Color.lerp(
        a.successForeground,
        b.successForeground,
        t,
      )!,
      successSolidForeground: Color.lerp(
        a.successSolidForeground,
        b.successSolidForeground,
        t,
      )!,
      warning: Color.lerp(a.warning, b.warning, t)!,
      warningForeground: Color.lerp(
        a.warningForeground,
        b.warningForeground,
        t,
      )!,
      warningSolidForeground: Color.lerp(
        a.warningSolidForeground,
        b.warningSolidForeground,
        t,
      )!,
      border: Color.lerp(a.border, b.border, t)!,
      input: Color.lerp(a.input, b.input, t)!,
      ring: Color.lerp(a.ring, b.ring, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      surfaceSecondary: Color.lerp(a.surfaceSecondary, b.surfaceSecondary, t)!,
      surfaceTertiary: Color.lerp(a.surfaceTertiary, b.surfaceTertiary, t)!,
      skeleton: Color.lerp(a.skeleton, b.skeleton, t)!,
      infoSoft: Color.lerp(a.infoSoft, b.infoSoft, t)!,
      infoSubtle: Color.lerp(a.infoSubtle, b.infoSubtle, t)!,
      successSoft: Color.lerp(a.successSoft, b.successSoft, t)!,
      successSubtle: Color.lerp(a.successSubtle, b.successSubtle, t)!,
      warningSoft: Color.lerp(a.warningSoft, b.warningSoft, t)!,
      warningSubtle: Color.lerp(a.warningSubtle, b.warningSubtle, t)!,
      destructiveSoft: Color.lerp(a.destructiveSoft, b.destructiveSoft, t)!,
      destructiveSubtle: Color.lerp(
        a.destructiveSubtle,
        b.destructiveSubtle,
        t,
      )!,
      codeKeyword: Color.lerp(a.codeKeyword, b.codeKeyword, t)!,
      codeString: Color.lerp(a.codeString, b.codeString, t)!,
      codeNumber: Color.lerp(a.codeNumber, b.codeNumber, t)!,
      codeComment: Color.lerp(a.codeComment, b.codeComment, t)!,
      codeFunction: Color.lerp(a.codeFunction, b.codeFunction, t)!,
      codeProperty: Color.lerp(a.codeProperty, b.codeProperty, t)!,
      codePunctuation: Color.lerp(a.codePunctuation, b.codePunctuation, t)!,
      codeInserted: Color.lerp(a.codeInserted, b.codeInserted, t)!,
      codeDeleted: Color.lerp(a.codeDeleted, b.codeDeleted, t)!,
      chart1: Color.lerp(a.chart1, b.chart1, t)!,
      chart2: Color.lerp(a.chart2, b.chart2, t)!,
      chart3: Color.lerp(a.chart3, b.chart3, t)!,
      chart4: Color.lerp(a.chart4, b.chart4, t)!,
      chart5: Color.lerp(a.chart5, b.chart5, t)!,
    );
  }

  List<Color> get _values => [
    background,
    foreground,
    card,
    cardForeground,
    popover,
    popoverForeground,
    overlay,
    overlayForeground,
    inset,
    primary,
    primaryForeground,
    secondary,
    secondaryForeground,
    muted,
    mutedForeground,
    accent,
    accentForeground,
    destructive,
    destructiveForeground,
    destructiveSolidForeground,
    info,
    infoForeground,
    infoSolidForeground,
    success,
    successForeground,
    successSolidForeground,
    warning,
    warningForeground,
    warningSolidForeground,
    border,
    input,
    ring,
    surface,
    surfaceSecondary,
    surfaceTertiary,
    skeleton,
    infoSoft,
    infoSubtle,
    successSoft,
    successSubtle,
    warningSoft,
    warningSubtle,
    destructiveSoft,
    destructiveSubtle,
    codeKeyword,
    codeString,
    codeNumber,
    codeComment,
    codeFunction,
    codeProperty,
    codePunctuation,
    codeInserted,
    codeDeleted,
    chart1,
    chart2,
    chart3,
    chart4,
    chart5,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PanelColors) return false;
    return listEquals(_values, other._values);
  }

  @override
  int get hashCode => Object.hashAll(_values);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('background', background));
    properties.add(ColorProperty('foreground', foreground));
    properties.add(ColorProperty('card', card));
    properties.add(ColorProperty('cardForeground', cardForeground));
    properties.add(ColorProperty('popover', popover));
    properties.add(ColorProperty('popoverForeground', popoverForeground));
    properties.add(ColorProperty('overlay', overlay));
    properties.add(ColorProperty('overlayForeground', overlayForeground));
    properties.add(ColorProperty('inset', inset));
    properties.add(ColorProperty('primary', primary));
    properties.add(ColorProperty('primaryForeground', primaryForeground));
    properties.add(ColorProperty('secondary', secondary));
    properties.add(ColorProperty('secondaryForeground', secondaryForeground));
    properties.add(ColorProperty('muted', muted));
    properties.add(ColorProperty('mutedForeground', mutedForeground));
    properties.add(ColorProperty('accent', accent));
    properties.add(ColorProperty('accentForeground', accentForeground));
    properties.add(ColorProperty('destructive', destructive));
    properties.add(
      ColorProperty('destructiveForeground', destructiveForeground),
    );
    properties.add(
      ColorProperty('destructiveSolidForeground', destructiveSolidForeground),
    );
    properties.add(ColorProperty('info', info));
    properties.add(ColorProperty('infoForeground', infoForeground));
    properties.add(ColorProperty('infoSolidForeground', infoSolidForeground));
    properties.add(ColorProperty('success', success));
    properties.add(ColorProperty('successForeground', successForeground));
    properties.add(
      ColorProperty('successSolidForeground', successSolidForeground),
    );
    properties.add(ColorProperty('warning', warning));
    properties.add(ColorProperty('warningForeground', warningForeground));
    properties.add(
      ColorProperty('warningSolidForeground', warningSolidForeground),
    );
    properties.add(ColorProperty('border', border));
    properties.add(ColorProperty('input', input));
    properties.add(ColorProperty('ring', ring));
    properties.add(ColorProperty('surface', surface));
    properties.add(ColorProperty('surfaceSecondary', surfaceSecondary));
    properties.add(ColorProperty('surfaceTertiary', surfaceTertiary));
    properties.add(ColorProperty('skeleton', skeleton));
    properties.add(ColorProperty('infoSoft', infoSoft));
    properties.add(ColorProperty('infoSubtle', infoSubtle));
    properties.add(ColorProperty('successSoft', successSoft));
    properties.add(ColorProperty('successSubtle', successSubtle));
    properties.add(ColorProperty('warningSoft', warningSoft));
    properties.add(ColorProperty('warningSubtle', warningSubtle));
    properties.add(ColorProperty('destructiveSoft', destructiveSoft));
    properties.add(ColorProperty('destructiveSubtle', destructiveSubtle));
    properties.add(ColorProperty('codeKeyword', codeKeyword));
    properties.add(ColorProperty('codeString', codeString));
    properties.add(ColorProperty('codeNumber', codeNumber));
    properties.add(ColorProperty('codeComment', codeComment));
    properties.add(ColorProperty('codeFunction', codeFunction));
    properties.add(ColorProperty('codeProperty', codeProperty));
    properties.add(ColorProperty('codePunctuation', codePunctuation));
    properties.add(ColorProperty('codeInserted', codeInserted));
    properties.add(ColorProperty('codeDeleted', codeDeleted));
    properties.add(ColorProperty('chart1', chart1));
    properties.add(ColorProperty('chart2', chart2));
    properties.add(ColorProperty('chart3', chart3));
    properties.add(ColorProperty('chart4', chart4));
    properties.add(ColorProperty('chart5', chart5));
  }
}

/// The corner-radius scale of a PanelUI theme.
///
/// A theme is a shape as well as a palette: Moon is tight, Grass is soft.
/// Components ask for a step (`radii.lg`), never for a number.
@immutable
class PanelRadii with Diagnosticable {
  /// Creates a radius scale.
  const PanelRadii({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
  });

  /// The radius scale of the Panel family.
  static const PanelRadii panel = PanelRadii(
    xs: 4.0,
    sm: 6.0,
    md: 8.0,
    lg: 10.0,
    xl: 14.0,
    xxl: 16.0,
    xxxl: 24.0,
  );

  /// The radius scale of the Moon family.
  static const PanelRadii moon = PanelRadii(
    xs: 4.0,
    sm: 6.0,
    md: 8.0,
    lg: 12.0,
    xl: 16.0,
    xxl: 24.0,
    xxxl: 32.0,
  );

  /// The radius scale of the Grass family.
  static const PanelRadii grass = PanelRadii(
    xs: 6.0,
    sm: 8.0,
    md: 12.0,
    lg: 14.0,
    xl: 18.0,
    xxl: 22.0,
    xxxl: 28.0,
  );

  /// `rounded-xs`.
  final double xs;

  /// `rounded-sm`.
  final double sm;

  /// `rounded-md`.
  final double md;

  /// `rounded-lg`, the default control radius.
  final double lg;

  /// `rounded-xl`.
  final double xl;

  /// `rounded-2xl`, cards and dialogs.
  final double xxl;

  /// `rounded-3xl`, surfaces and sheets.
  final double xxxl;

  /// Returns a copy with the given steps replaced.
  PanelRadii copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
  }) {
    return PanelRadii(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
    );
  }

  /// Interpolates every step between [a] and [b].
  static PanelRadii lerp(PanelRadii a, PanelRadii b, double t) {
    if (identical(a, b)) return a;
    return PanelRadii(
      xs: lerpDouble(a.xs, b.xs, t)!,
      sm: lerpDouble(a.sm, b.sm, t)!,
      md: lerpDouble(a.md, b.md, t)!,
      lg: lerpDouble(a.lg, b.lg, t)!,
      xl: lerpDouble(a.xl, b.xl, t)!,
      xxl: lerpDouble(a.xxl, b.xxl, t)!,
      xxxl: lerpDouble(a.xxxl, b.xxxl, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PanelRadii &&
        other.xs == xs &&
        other.sm == sm &&
        other.md == md &&
        other.lg == lg &&
        other.xl == xl &&
        other.xxl == xxl &&
        other.xxxl == xxxl;
  }

  @override
  int get hashCode => Object.hash(xs, sm, md, lg, xl, xxl, xxxl);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('xs', xs));
    properties.add(DoubleProperty('sm', sm));
    properties.add(DoubleProperty('md', md));
    properties.add(DoubleProperty('lg', lg));
    properties.add(DoubleProperty('xl', xl));
    properties.add(DoubleProperty('xxl', xxl));
    properties.add(DoubleProperty('xxxl', xxxl));
  }
}
