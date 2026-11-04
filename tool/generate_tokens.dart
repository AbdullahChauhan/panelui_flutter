// Generates lib/src/theme/panel_tokens.dart from PanelUI's theme.css.
//
// PanelUI keeps its semantic tokens in one CSS file
// (packages/panelui/theme.css in the PanelUI repository), already
// precomputed to static hex/rgba values for native. This script reads that
// file and writes the Dart token classes, so the Flutter port follows the
// upstream palette exactly and can be refreshed when it changes:
//
//   dart run tool/generate_tokens.dart path/to/PanelUI/packages/panelui/theme.css
//
// Every theme in the CSS must define every token; the script fails loudly if
// one does not, rather than emitting a class with a hole in it.
import 'dart:io';

/// CSS variant name -> Dart identifier of the generated colour set.
const _variantIds = <String, String>{
  'light': 'panelLight',
  'dark': 'panelDark',
  'moon': 'moonLight',
  'moon-dark': 'moonDark',
  'grass': 'grassLight',
  'grass-dark': 'grassDark',
};

/// CSS variant name -> theme family the radius scale belongs to.
const _variantFamily = <String, String>{
  'light': 'panel',
  'dark': 'panel',
  'moon': 'moon',
  'moon-dark': 'moon',
  'grass': 'grass',
  'grass-dark': 'grass',
};

/// CSS radius step -> Dart field name.
const _radiusIds = <String, String>{
  'xs': 'xs',
  'sm': 'sm',
  'md': 'md',
  'lg': 'lg',
  'xl': 'xl',
  '2xl': 'xxl',
  '3xl': 'xxxl',
};

/// One-line docs for the tokens, written for someone choosing between them.
const _docs = <String, String>{
  'background': 'The page canvas.',
  'foreground': 'Body text on [background].',
  'card': 'Fill of a card.',
  'cardForeground': 'Text on [card].',
  'popover': 'Fill of a floating surface: dialogs, popovers, toasts.',
  'popoverForeground': 'Text on [popover].',
  'overlay':
      'One step further forward than [popover], for menus opened over one.',
  'overlayForeground': 'Text on [overlay].',
  'inset':
      'A translucent band set into a surface, such as a footer of actions.',
  'primary': 'The main action colour.',
  'primaryForeground': 'Text and icons on [primary].',
  'secondary': 'A quiet filled control.',
  'secondaryForeground': 'Text on [secondary].',
  'muted': 'A low-emphasis fill.',
  'mutedForeground': 'Secondary text: descriptions, placeholders, captions.',
  'accent': 'Hover and selection fill.',
  'accentForeground': 'Text on [accent].',
  'destructive': 'Fill for a destructive action or an error state.',
  'destructiveForeground': 'Destructive text on a neutral or soft fill.',
  'destructiveSolidForeground': 'Text on a solid [destructive] fill.',
  'info': 'Informational status colour.',
  'infoForeground': 'Informational text on a neutral or soft fill.',
  'infoSolidForeground': 'Text on a solid [info] fill.',
  'success': 'Success status colour.',
  'successForeground': 'Success text on a neutral or soft fill.',
  'successSolidForeground': 'Text on a solid [success] fill.',
  'warning': 'Warning status colour.',
  'warningForeground': 'Warning text on a neutral or soft fill.',
  'warningSolidForeground': 'Text on a solid [warning] fill.',
  'border': 'Hairline borders and separators.',
  'input': 'The resting border of a form control.',
  'ring': 'Focus rings and the focused border of a form control.',
  'surface': 'First step of the elevation ladder (grouping surface).',
  'surfaceSecondary': 'Second step of the elevation ladder.',
  'surfaceTertiary': 'Third step of the elevation ladder.',
  'skeleton': 'Fill of a loading placeholder.',
  'infoSoft': 'Tinted info fill for an alert.',
  'infoSubtle': 'Tinted info fill for a badge.',
  'successSoft': 'Tinted success fill for an alert.',
  'successSubtle': 'Tinted success fill for a badge.',
  'warningSoft': 'Tinted warning fill for an alert.',
  'warningSubtle': 'Tinted warning fill for a badge.',
  'destructiveSoft': 'Tinted destructive fill for an alert.',
  'destructiveSubtle': 'Tinted destructive fill for a badge.',
  'codeKeyword': 'Syntax colour: keywords.',
  'codeString': 'Syntax colour: strings.',
  'codeNumber': 'Syntax colour: numbers.',
  'codeComment': 'Syntax colour: comments.',
  'codeFunction': 'Syntax colour: function names.',
  'codeProperty': 'Syntax colour: properties.',
  'codePunctuation': 'Syntax colour: punctuation.',
  'codeInserted': 'Syntax colour: inserted lines in a diff.',
  'codeDeleted': 'Syntax colour: deleted lines in a diff.',
  'chart1': 'Chart series 1, the series a chart is about.',
  'chart2': 'Chart series 2.',
  'chart3': 'Chart series 3.',
  'chart4': 'Chart series 4.',
  'chart5': 'Chart series 5.',
};

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run tool/generate_tokens.dart <theme.css> [output.dart]',
    );
    exit(64);
  }
  final css = File(args[0]).readAsStringSync();
  final outPath = args.length > 1 ? args[1] : 'lib/src/theme/panel_tokens.dart';

  final withoutComments = css.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  final blockPattern = RegExp(r'@variant\s+([\w-]+)\s*\{([^{}]*)\}');
  final declPattern = RegExp(r'--(color|radius)-([\w-]+)\s*:\s*([^;]+);');

  final colors = <String, Map<String, String>>{}; // variant -> token -> css
  final radii = <String, Map<String, String>>{}; // variant -> step -> css
  for (final block in blockPattern.allMatches(withoutComments)) {
    final variant = block.group(1)!;
    if (!_variantIds.containsKey(variant)) continue; // ios/android font-mono
    for (final decl in declPattern.allMatches(block.group(2)!)) {
      final kind = decl.group(1)!;
      final name = decl.group(2)!;
      final value = decl.group(3)!.trim();
      if (kind == 'color') {
        (colors[variant] ??= {})[_camel(name)] = value;
      } else {
        (radii[variant] ??= {})[name] = value;
      }
    }
  }

  for (final variant in _variantIds.keys) {
    if (!colors.containsKey(variant)) {
      _fail('theme "$variant" was not found in ${args[0]}');
    }
  }
  final tokenNames = colors['light']!.keys.toList();
  for (final entry in colors.entries) {
    final missing = tokenNames.where((t) => !entry.value.containsKey(t));
    final extra = entry.value.keys.where((t) => !tokenNames.contains(t));
    if (missing.isNotEmpty || extra.isNotEmpty) {
      _fail(
        'theme "${entry.key}" does not match "light": '
        'missing $missing, extra $extra',
      );
    }
  }

  // Radii are a property of the family; light and dark must agree.
  final familyRadii = <String, Map<String, double>>{};
  for (final entry in radii.entries) {
    final family = _variantFamily[entry.key]!;
    final parsed = {
      for (final step in _radiusIds.keys)
        step: _parsePx(
          entry.value[step] ?? _fail('radius-$step missing in "${entry.key}"'),
        ),
    };
    final previous = familyRadii[family];
    if (previous != null && previous.toString() != parsed.toString()) {
      _fail('light and dark radius scales differ in family "$family"');
    }
    familyRadii[family] = parsed;
  }

  final b = StringBuffer()
    ..writeln('// GENERATED CODE. Do not edit by hand.')
    ..writeln('//')
    ..writeln("// Source: PanelUI's packages/panelui/theme.css (MIT License,")
    ..writeln('// Copyright (c) 2026 Khalid Abdi).')
    ..writeln(
      '// Regenerate with: dart run tool/generate_tokens.dart <theme.css>',
    )
    ..writeln()
    ..writeln("import 'dart:ui' show lerpDouble;")
    ..writeln()
    ..writeln("import 'package:flutter/foundation.dart';")
    ..writeln("import 'package:flutter/painting.dart';")
    ..writeln()
    ..writeln('/// The semantic colour tokens of a PanelUI theme.')
    ..writeln('///')
    ..writeln(
      '/// Components never hardcode a colour: every fill, border and text colour',
    )
    ..writeln(
      '/// resolves to one of these, so switching the theme recolours everything.',
    )
    ..writeln('@immutable')
    ..writeln('class PanelColors with Diagnosticable {')
    ..writeln('  /// Creates a colour set. Every token is required.')
    ..writeln('  const PanelColors({');
  for (final t in tokenNames) {
    b.writeln('    required this.$t,');
  }
  b.writeln('  });');
  b.writeln();

  for (final variant in _variantIds.keys) {
    final id = _variantIds[variant]!;
    b.writeln('  /// The `$variant` theme from PanelUI.');
    b.writeln('  static const PanelColors $id = PanelColors(');
    for (final t in tokenNames) {
      final cssValue = colors[variant]![t]!;
      b.writeln('    $t: ${_dartColor(cssValue)}, // $cssValue');
    }
    b.writeln('  );');
    b.writeln();
  }

  for (final t in tokenNames) {
    b.writeln('  /// ${_docs[t] ?? 'The `$t` token.'}');
    b.writeln('  final Color $t;');
    b.writeln();
  }

  b.writeln('  /// Returns a copy with the given tokens replaced.');
  b.writeln('  PanelColors copyWith({');
  for (final t in tokenNames) {
    b.writeln('    Color? $t,');
  }
  b.writeln('  }) {');
  b.writeln('    return PanelColors(');
  for (final t in tokenNames) {
    b.writeln('      $t: $t ?? this.$t,');
  }
  b.writeln('    );');
  b.writeln('  }');
  b.writeln();
  b.writeln('  /// Interpolates every token between [a] and [b].');
  b.writeln(
    '  static PanelColors lerp(PanelColors a, PanelColors b, double t) {',
  );
  b.writeln('    if (identical(a, b)) return a;');
  b.writeln('    return PanelColors(');
  for (final t in tokenNames) {
    b.writeln('      $t: Color.lerp(a.$t, b.$t, t)!,');
  }
  b.writeln('    );');
  b.writeln('  }');
  b.writeln();
  b.writeln('  List<Color> get _values => [');
  for (final t in tokenNames) {
    b.writeln('        $t,');
  }
  b.writeln('      ];');
  b.writeln();
  b.writeln('  @override');
  b.writeln('  bool operator ==(Object other) {');
  b.writeln('    if (identical(this, other)) return true;');
  b.writeln('    if (other is! PanelColors) return false;');
  b.writeln('    return listEquals(_values, other._values);');
  b.writeln('  }');
  b.writeln();
  b.writeln('  @override');
  b.writeln('  int get hashCode => Object.hashAll(_values);');
  b.writeln();
  b.writeln('  @override');
  b.writeln(
    '  void debugFillProperties(DiagnosticPropertiesBuilder properties) {',
  );
  b.writeln('    super.debugFillProperties(properties);');
  for (final t in tokenNames) {
    b.writeln("    properties.add(ColorProperty('$t', $t));");
  }
  b.writeln('  }');
  b.writeln('}');
  b.writeln();

  final steps = _radiusIds.values.toList();
  b
    ..writeln('/// The corner-radius scale of a PanelUI theme.')
    ..writeln('///')
    ..writeln(
      '/// A theme is a shape as well as a palette: Moon is tight, Grass is soft.',
    )
    ..writeln('/// Components ask for a step (`radii.lg`), never for a number.')
    ..writeln('@immutable')
    ..writeln('class PanelRadii with Diagnosticable {')
    ..writeln('  /// Creates a radius scale.')
    ..writeln('  const PanelRadii({');
  for (final s in steps) {
    b.writeln('    required this.$s,');
  }
  b.writeln('  });');
  b.writeln();
  for (final family in familyRadii.keys) {
    final values = familyRadii[family]!;
    b.writeln('  /// The radius scale of the ${_title(family)} family.');
    b.writeln('  static const PanelRadii $family = PanelRadii(');
    for (final step in _radiusIds.keys) {
      b.writeln('    ${_radiusIds[step]}: ${values[step]},');
    }
    b.writeln('  );');
    b.writeln();
  }
  const stepDocs = {
    'xs': '`rounded-xs`',
    'sm': '`rounded-sm`',
    'md': '`rounded-md`',
    'lg': '`rounded-lg`, the default control radius',
    'xl': '`rounded-xl`',
    'xxl': '`rounded-2xl`, cards and dialogs',
    'xxxl': '`rounded-3xl`, surfaces and sheets',
  };
  for (final s in steps) {
    b.writeln('  /// ${stepDocs[s]}.');
    b.writeln('  final double $s;');
    b.writeln();
  }
  b.writeln('  /// Returns a copy with the given steps replaced.');
  b.writeln('  PanelRadii copyWith({');
  for (final s in steps) {
    b.writeln('    double? $s,');
  }
  b.writeln('  }) {');
  b.writeln('    return PanelRadii(');
  for (final s in steps) {
    b.writeln('      $s: $s ?? this.$s,');
  }
  b.writeln('    );');
  b.writeln('  }');
  b.writeln();
  b.writeln('  /// Interpolates every step between [a] and [b].');
  b.writeln('  static PanelRadii lerp(PanelRadii a, PanelRadii b, double t) {');
  b.writeln('    if (identical(a, b)) return a;');
  b.writeln('    return PanelRadii(');
  for (final s in steps) {
    b.writeln('      $s: lerpDouble(a.$s, b.$s, t)!,');
  }
  b.writeln('    );');
  b.writeln('  }');
  b.writeln();
  b.writeln('  @override');
  b.writeln('  bool operator ==(Object other) {');
  b.writeln('    if (identical(this, other)) return true;');
  b.writeln('    return other is PanelRadii &&');
  b.writeln(steps.map((s) => '        other.$s == $s').join(' &&\n'));
  b.writeln('        ;');
  b.writeln('  }');
  b.writeln();
  b.writeln('  @override');
  b.writeln('  int get hashCode => Object.hash(${steps.join(', ')});');
  b.writeln();
  b.writeln('  @override');
  b.writeln(
    '  void debugFillProperties(DiagnosticPropertiesBuilder properties) {',
  );
  b.writeln('    super.debugFillProperties(properties);');
  for (final s in steps) {
    b.writeln("    properties.add(DoubleProperty('$s', $s));");
  }
  b.writeln('  }');
  b.writeln('}');

  File(outPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(b.toString());
  stdout.writeln(
    'Wrote $outPath: ${tokenNames.length} colour tokens x '
    '${_variantIds.length} themes, ${familyRadii.length} radius scales.',
  );
}

String _camel(String kebab) {
  final parts = kebab.split('-');
  return parts.first +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

String _title(String s) => s[0].toUpperCase() + s.substring(1);

double _parsePx(String value) {
  final match = RegExp(r'^([\d.]+)px$').firstMatch(value.trim());
  if (match == null) _fail('unsupported radius "$value"');
  return double.parse(match.group(1)!);
}

String _hex2(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();

String _dartColor(String css) {
  final hex = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(css);
  if (hex != null) return 'Color(0xFF${hex.group(1)!.toUpperCase()})';
  final rgba = RegExp(
    r'^rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)$',
  ).firstMatch(css);
  if (rgba != null) {
    final r = int.parse(rgba.group(1)!);
    final g = int.parse(rgba.group(2)!);
    final bl = int.parse(rgba.group(3)!);
    final a = (double.parse(rgba.group(4)!) * 255).round();
    return 'Color(0x${_hex2(a)}${_hex2(r)}${_hex2(g)}${_hex2(bl)})';
  }
  _fail('unsupported colour "$css"');
}

Never _fail(String message) {
  stderr.writeln('generate_tokens: $message');
  exit(1);
}
