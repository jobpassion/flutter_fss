library fss_parser;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fss/src/fss_dashed_border.dart';

/// Represents a style sheet containing a set of rules.
class FlutterStyleSheet {
  final List<FssRule> _rules = [];

  List<FssRule> get rules {
    return List.unmodifiable(_rules);
  }

  /// Defines the system defaults for all styles. Use this to initialize values.
  /// These will then be used when no other rule is overriding them.
  FssRuleBlock _systemDefaults = FssRuleBlock(const {});
  FssRuleBlock get systemDefaults => _systemDefaults;

  FlutterStyleSheet({
    String? stylesheet = '',
    List<FssRule>? rules,
    FssRuleBlock? systemDefaults,
  }) {
    _systemDefaults = systemDefaults ?? FssProperty.getDefaults();

    if (rules != null) {
      _rules.addAll(rules);
    }
    // Add everything from the style sheet
    _rules.addAll(parseStylesheet(stylesheet));
  }

  /// Resolves and merges all the rules that match the given classes string and
  /// FSS ID. All matching rules will be processed and merged into a final
  /// combined rule.
  FssRuleBlock resolveStyles({
    String matchType = '',
    String matchId = '',
    String matchClasses = '',
    FssRuleBlock? parentStyles,
    MediaQueryData? media,
  }) {
    var idToMatch = matchId;
    if (idToMatch.isNotEmpty && !idToMatch.startsWith('#')) {
      idToMatch = '#$idToMatch';
    }

    // split into single classes and add . in front of each
    final matchClassesAsList =
        matchClasses.split(RegExp(r'\s+')).map((e) => '.${e.trim()}').toList();

    // first check all the @Media query rules
    final List<FssRule> rulesToMatch = [];
    for (final rule in _rules) {
      if (rule is _FssMediaRule) {
        if (rule.selector.getSpecificity('', '', [], media) > 0) {
          // print('-> @Media matched: ${rule.selector}');
          rulesToMatch.addAll(rule.subRules);
        }
      } else {
        rulesToMatch.add(rule);
      }
    }

    // now check all the rules
    final List<_FssRuleMatch> matchedRules = [];
    int ruleNo = 0;
    for (final rule in rulesToMatch) {
      final specificity = rule.selector
          .getSpecificity(matchType, idToMatch, matchClassesAsList);
      if (specificity > 0) {
        matchedRules.add(_FssRuleMatch(rule, specificity, ruleNo));
      }
      ruleNo++;
    }

    // Sort by specificity
    matchedRules.sort();

    // Now merge properties of all the matched rules
    // Start with an empty property set with parent and system defaults set
    FssRuleBlock result = FssRuleBlock(
      const {},
      parent: parentStyles,
      initialValues: systemDefaults,
    );

    for (final match in matchedRules) {
      result = result.merge(match.rule.properties);
    }
    return result;
  }

  /// Create a copy of the current stylesheet with additional rules added.
  FlutterStyleSheet copyWith({
    String? stylesheet,
    List<FssRule>? rules,
    FssRuleBlock? systemDefaults,
  }) {
    // original rules then add on top
    final List<FssRule> newRuleSet = [
      ..._rules,
      ...?rules,
      ...parseStylesheet(stylesheet)
    ];

    return FlutterStyleSheet(
      systemDefaults: systemDefaults,
      rules: newRuleSet,
    );
  }

  /// Gets a debug summary of all the rules and defaults in this style sheet.
  String getDebugThemeInfo() {
    final result = StringBuffer()
      ..writeln('System Defaults:')
      ..writeln('----------------------------------------------------------')
      ..writeln(systemDefaults)
      ..writeln('Rules:')
      ..writeln('----------------------------------------------------------');
    _rules.forEach(result.writeln);
    return result.toString();
  }
}

/// Specifies a FSS rule consisting of a selector and a set of properties.
///
/// The list of properties is stored in a [FssRuleBlock]
@immutable
class FssRule {
  final FssSelector selector;
  final FssRuleBlock properties;

  const FssRule(this.selector, this.properties);

  @override
  String toString() {
    return '$selector\n$properties';
  }
}

/// A list of properties representing all properties of a rule block.
///
/// This will be used for parsing a rule but also to merge and inherit
/// properties into an "applicable rule block" when resolving all rules for a
/// given element.
@immutable
class FssRuleBlock {
  final Map<String, FssPropertyValue> _properties = {};
  final FssRuleBlock? _initialValues;
  final FssRuleBlock? _parent;

  Color? get color => getColor(FssProperty.color.name);

  Color? get backgroundColor => getColor(FssProperty.background_color.name);

  DecorationImage? get backgroundImage {
    final imagePath = get(FssProperty.background_image.name);
    // TODO support multiple images and merge them into a DecorationImage.
    // Maybe support effects via BackdropFilter widget
    if (imagePath == null) {
      return null;
    }
    if (imagePath.value.contains('linear-gradient(') ||
        imagePath.value.contains('radial-gradient(')) {
      return null;
    }

    final img = _parseImageSource(imagePath);

    var propValue = get(FssProperty.background_repeat.name);
    final repeat = propValue == null
        ? ImageRepeat.repeat
        : _parseBackroundRepeat(propValue);

    propValue = get(FssProperty.background_size.name);
    final BoxFit? boxFit =
        propValue == null ? null : _parseBackroundSize(propValue);

    propValue = get(FssProperty.background_position.name);
    AlignmentGeometry align = Alignment.topLeft;
    if (propValue != null) {
      final parts = _splitValues(this, propValue.value);
      final hor = _parseTextAlign(FssPropertyValue('', parts[0]));
      final vert = parts.length > 1
          ? _parseVertAlign(FssPropertyValue('', parts[1]))
          : null;
      align = _combineAlignment(hor, vert) ?? Alignment.center;
    }

    return DecorationImage(
      image: img,
      //colorFilter: ColorFilter.mode(Colors.white, BlendMode.darken)
      repeat: repeat,
      fit: boxFit,
      alignment: align,
    );
  }

  Gradient? get backgroundGradient {
    final imageDef = get(FssProperty.background_image.name);
    if (imageDef == null) {
      return null;
    }
    final propValue = imageDef.value;
    if (propValue.startsWith('linear-gradient(')) {
      return _parseLinearGradient(propValue, imageDef);
    }
    if (propValue.startsWith('radial-gradient(')) {
      return _parseRadialGradient(propValue, imageDef);
    }
    if (propValue.startsWith('sweep-gradient(')) {
      //TODO support cone gradient?.
      return const SweepGradient(
        colors: [Colors.black, Colors.white],
        startAngle: -4.45,
        endAngle: 4.7,
      );
    }
    return null;
  }

  BoxBorder? get border {
    final topSide = getBorderSide('top');
    final bottomSide = getBorderSide('bottom');
    final leftSide = getBorderSide('left');
    final rightSide = getBorderSide('right');

    // No border or hidden border
    if (BorderStyle.none == topSide.style &&
        BorderStyle.none == bottomSide.style &&
        BorderStyle.none == leftSide.style &&
        BorderStyle.none == rightSide.style) {
      return null;
    }

    final topStyle = getString('border-top-style');
    final bottomStyle = getString('border-bottom-style');
    final leftStyle = getString('border-left-style');
    final rightStyle = getString('border-right-style');

    // These are all painted via the standard border
    final simple = {'solid', 'none', 'hidden', 'inset', 'outset', null};
    final onlySolid = simple.contains(topStyle) &&
        simple.contains(bottomStyle) &&
        simple.contains(leftStyle) &&
        simple.contains(rightStyle);

    if (onlySolid) {
      return Border(
        top: topSide,
        bottom: bottomSide,
        left: leftSide,
        right: rightSide,
      );
    }

    // With different sides or non solid stroke.
    return DashPathBorder(
      top: topSide,
      dashTopArray: _parseBorderPattern(topSide, topStyle),
      bottom: bottomSide,
      dashBottomArray: _parseBorderPattern(bottomSide, bottomStyle),
      left: leftSide,
      dashLeftArray: _parseBorderPattern(leftSide, leftStyle),
      right: rightSide,
      dashRightArray: _parseBorderPattern(rightSide, rightStyle),
    );
  }

  BorderRadiusGeometry? get borderRadius {
    final tl = getSize(FssProperty.border_top_left_radius.name);
    final tr = getSize(FssProperty.border_top_right_radius.name);
    final br = getSize(FssProperty.border_bottom_right_radius.name);
    final bl = getSize(FssProperty.border_bottom_left_radius.name);
    if (tl == null && tr == null && bl == null && br == null) {
      return null;
    }
    // TODO support elliptical  corners too?

    return BorderRadius.only(
      topLeft: tl == null ? Radius.zero : Radius.circular(tl),
      topRight: tr == null ? Radius.zero : Radius.circular(tr),
      bottomLeft: bl == null ? Radius.zero : Radius.circular(bl),
      bottomRight: br == null ? Radius.zero : Radius.circular(br),
    );
  }

  TextStyle? get textStyle {
    Color? color = getColor(FssProperty.color.name);

    FssPropertyValue? propValue;

    final sfValue = getString(FssProperty.font_style.name);
    final fontStyle = (sfValue == null)
        ? null
        : ((sfValue == 'italic') ? FontStyle.italic : FontStyle.normal);

    var fontFamily = getString(FssProperty.font_family.name);
    List<String>? fallbackFonts;
    if (fontFamily != null) {
      final fontFaces = _splitFunctionParams(this, fontFamily);
      final fonts = fontFaces
          .map((e) => e.trim())
          .map((e) => e.startsWith('"') ? e.substring(1) : e)
          .map((e) => e.endsWith('"') ? e.substring(0, e.length - 1) : e)
          .map((e) => _resolveValue(e)!)
          .toList();
      fontFamily = fonts[0];
      fallbackFonts = fonts.length > 1 ? fonts.sublist(1) : null;
    }

    final fontSize = getSize(FssProperty.font_size.name);

    propValue = get(FssProperty.font_weight.name);
    final fontWeight = (propValue == null) ? null : _parseFontWeight(propValue);

    propValue = get(FssProperty.text_decoration_line.name);
    final decoration = (propValue == null)
        ? TextDecoration.none
        : _parseTextDecLine(propValue);

    propValue = get(FssProperty.text_decoration_style.name);
    final decorationStyle = (decoration == null || propValue == null)
        ? null
        : _parseTextDecStyle(propValue);

    final decorationColor = decoration == null
        ? null
        : getColor(FssProperty.text_decoration_color.name);

    final decorationThickness = decoration == null
        ? null
        : getSize(FssProperty.text_decoration_thickness.name);

    propValue = get(FssProperty.text_shadow.name);
    final shadows =
        (propValue == null) ? null : [_parseShadow(propValue, _getBaseline())];

    Paint? outline;
    final strokeWidth = getSize(FssProperty.text_stroke_width.name);
    final strokeCol = getColor(FssProperty.text_stroke_color.name);
    if (strokeWidth != null && strokeCol != null) {
      outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = strokeCol;
      // TODO setting an outline will override the text color
      // https://github.com/flutter/flutter/issues/29911
      color = null;
    }

    final letterSpacing = getSize(FssProperty.letter_spacing.name);
    final wordSpacing = getSize(FssProperty.word_spacing.name);
    final height = getSize(FssProperty.height.name);

    return TextStyle(
      color: color,
      fontStyle: fontStyle,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamilyFallback: fallbackFonts,
      decoration: decoration,
      decorationStyle: decorationStyle,
      decorationColor: decorationColor,
      decorationThickness: decorationThickness,
      shadows: shadows,
      foreground: outline,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
    );
  }

  TextAlign? get textAlign {
    final value = get(FssProperty.text_align.name);
    if (value == null) {
      return null;
    }
    return _parseTextAlign(value);
  }

  Alignment? get verticalAlign {
    final propValue = get(FssProperty.vertical_align.name);
    if (propValue == null) {
      return null;
    }
    return _parseVertAlign(propValue);
  }

  AlignmentGeometry? get alignment {
    return _combineAlignment(textAlign, verticalAlign);
  }

  BoxShadow? get boxShadow {
    final value = get(FssProperty.box_shadow.name);
    if (value == null) {
      return null;
    }
    return _parseBoxShadow(value, _getBaseline());
  }

  bool get visible {
    final value = get(FssProperty.visibility.name);
    if (value == null) {
      return true;
    }
    return value.value != 'hidden';
  }

  bool get contentVisible {
    final value = get(FssProperty.content_visibility.name);
    if (value == null) {
      return true;
    }
    return value.value != 'hidden';
  }

  TextOverflow? get textOverflow {
    final value = get(FssProperty.text_overflow.name);
    if (value == null) {
      return null;
    }
    return _parseTextOverflow(value);
  }

  String? get whiteSpace => getString(FssProperty.white_space.name);

  /// Should we wrap text or render it in a single line?
  /// This is determined by looking at the white-space property
  bool get wrapText {
    return 'nowrap' != whiteSpace;
  }

  TextDirection? get direction {
    final value = get(FssProperty.direction.name);
    if (value == null) {
      return null;
    }
    return value.value == 'rtl' ? TextDirection.rtl : TextDirection.ltr;
  }

  double? get lineHeight => getSize(FssProperty.line_height.name);

  double? get maxHeight => getSize(FssProperty.max_height.name);
  double? get minHeight => getSize(FssProperty.min_height.name);
  double? get maxWidth => getSize(FssProperty.max_width.name);
  double? get minWidth => getSize(FssProperty.min_width.name);

  BoxConstraints? get constraints {
    if (maxHeight == null &&
        minHeight == null &&
        maxWidth == null &&
        minWidth == null) {
      return null;
    }
    return BoxConstraints(
      maxHeight: maxHeight ?? 0.0,
      minHeight: minHeight ?? 0.0,
      maxWidth: maxWidth ?? 0.0,
      minWidth: minWidth ?? 0.0,
    );
  }

  double? get width => getSize(FssProperty.width.name);
  double? get height => getSize(FssProperty.height.name);

  EdgeInsetsGeometry? get margin {
    final top = getSize(FssProperty.margin_top.name);
    final left = getSize(FssProperty.margin_left.name);
    final bottom = getSize(FssProperty.margin_bottom.name);
    final right = getSize(FssProperty.margin_right.name);
    if (top == null && left == null && bottom == null && right == null) {
      return null;
    }
    return EdgeInsets.only(
      top: top ?? 0.0,
      left: left ?? 0.0,
      bottom: bottom ?? 0.0,
      right: right ?? 0.0,
    );
  }

  EdgeInsetsGeometry? get padding {
    final top = getSize(FssProperty.padding_top.name);
    final left = getSize(FssProperty.padding_left.name);
    final bottom = getSize(FssProperty.padding_bottom.name);
    final right = getSize(FssProperty.padding_right.name);
    if (top == null && left == null && bottom == null && right == null) {
      return null;
    }
    return EdgeInsets.only(
      top: top ?? 0.0,
      left: left ?? 0.0,
      bottom: bottom ?? 0.0,
      right: right ?? 0.0,
    );
  }

  Matrix4? get transformMatrix {
    final transDef = getString(FssProperty.transform.name);
    if (transDef == null || transDef == 'none') {
      return null;
    }
    final Matrix4 result = Matrix4.identity();
    for (final trans in _splitValues(this, transDef)) {
      final functionSpec =
          trans.substring(trans.indexOf('(') + 1, trans.indexOf(')')).trim();
      if (trans.startsWith('rotate(') || trans.startsWith('rotatez(')) {
        result.multiply(
          Matrix4.rotationZ(FssAngle.parse(functionSpec).getRadians()),
        );
      }
      if (trans.startsWith('rotatex(')) {
        result.multiply(
          Matrix4.rotationX(FssAngle.parse(functionSpec).getRadians()),
        );
      }
      if (trans.startsWith('rotatey(')) {
        result.multiply(
          Matrix4.rotationY(FssAngle.parse(functionSpec).getRadians()),
        );
      }
      if (trans.startsWith('scale(')) {
        final params = _splitFunctionParams(this, functionSpec);
        result.multiply(
          Matrix4.diagonal3Values(
            FssSize.parse(params[0]).getPixelSize(_getBaseline()),
            params.length > 1
                ? FssSize.parse(params[1]).getPixelSize(_getBaseline())
                : 1.0,
            params.length > 2
                ? FssSize.parse(params[2]).getPixelSize(_getBaseline())
                : 1.0,
          ),
        );
      }

      if (trans.startsWith('scalex(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.diagonal3Values(value, 1.0, 1.0));
      }
      if (trans.startsWith('scaley(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.diagonal3Values(1.0, value, 1.0));
      }
      if (trans.startsWith('scalez(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.diagonal3Values(1.0, 1.0, value));
      }
      if (trans.startsWith('skew(')) {
        final params = _splitFunctionParams(this, functionSpec);
        result.multiply(
          Matrix4.skew(
            FssAngle.parse(params[0]).getRadians(),
            params.length > 1 ? FssAngle.parse(params[1]).getRadians() : 0,
          ),
        );
      }
      if (trans.startsWith('skewx(')) {
        final value = FssAngle.parse(functionSpec).getRadians();
        result.multiply(Matrix4.skewX(value));
      }
      if (trans.startsWith('skewy(')) {
        final value = FssAngle.parse(functionSpec).getRadians();
        result.multiply(Matrix4.skewY(value));
      }
      if (trans.startsWith('translate(')) {
        final params = _splitFunctionParams(this, functionSpec);
        result.multiply(
          Matrix4.translationValues(
            FssSize.parse(params[0]).getPixelSize(_getBaseline()),
            params.length > 1
                ? FssSize.parse(params[1]).getPixelSize(_getBaseline())
                : 0,
            params.length > 2
                ? FssSize.parse(params[2]).getPixelSize(_getBaseline())
                : 0,
          ),
        );
      }
      if (trans.startsWith('translatex(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.translationValues(value, 0, 0));
      }
      if (trans.startsWith('translatey(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.translationValues(0, value, 0));
      }
      if (trans.startsWith('translatez(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.translationValues(0, 0, value));
      }
    }

    return result == Matrix4.identity() ? null : result;
  }

  ImageProvider? getListStyleImage() {
    final imagePath = get(FssProperty.list_style_image.name);
    if (imagePath == null) {
      return null;
    }
    return _parseImageSource(imagePath);
  }

  String getListStyleSymbol(int position, int max) {
    var value = getString(FssProperty.list_style_type.name);
    value ??= FssProperty.list_style_type.initialValue;

    switch (value) {
      // What a shame but the Noto font does not contain these characters!
      case 'disc':
      //  return '\u{2022}';
      case 'circle':
      //  return '\u{2E30}';
      case 'square':
        //  return 'square'; // '\u{2043}'
        break;

      case 'decimal':
        return '$position.';
      case 'decimal-leading-zero':
        return '${position.toString().padLeft('$max'.length, '0')}.';
      case 'lower-alpha':
      case 'lower-latin':
        final char = 'a'.codeUnitAt(0) + position - 1;
        return '${String.fromCharCode(char)}.';
      case 'upper-alpha':
      case 'upper-latin':
        final char = 'A'.codeUnitAt(0) + position - 1;
        return '${String.fromCharCode(char)}.';
      case 'lower-greek':
        final char = 'α'.codeUnitAt(0) + position - 1;
        return '${String.fromCharCode(char)}.';
      case 'lower-roman':
        return '${_toRoman(position).toLowerCase()}.';
      case 'upper-roman':
        return '${_toRoman(position)}.';
    }
    // A custom string
    return value!;
  }

  /// Constructs a rule from the given properties.
  FssRuleBlock(
    Map<String, FssPropertyValue>? properties, {
    FssRuleBlock? parent,
    FssRuleBlock? initialValues,
  })  : _parent = parent,
        _initialValues = initialValues {
    if (properties != null) {
      _properties.addAll(properties);
    }
  }

  /// Merges this rule with another one.
  /// All properties that are not null are taken over.
  FssRuleBlock merge(FssRuleBlock? other) {
    final FssRuleBlock result =
        FssRuleBlock(const {}, parent: _parent, initialValues: _initialValues);
    result._properties.addAll(_properties);
    if (other != null) {
      result._properties.addAll(other._properties);
    }
    return result;
  }

  /// Transforms and replaces text content
  /// This applies the "text_transformation" and "content" to the input text
  String transformText(String input) {
    var result = input;
    result = _replaceContent(result);
    result = _applyTextTransform(result);
    return result;
  }

  FssPropertyValue? get(String prop) {
    var lookup = _properties[prop];

    final propDef = FssProperty.byName(prop);
    final bool inheritingProperty = propDef != null && propDef.inherited;

    // Handle special value 'unset'
    if (lookup != null && lookup.value == 'unset') {
      return inheritingProperty
          ? _parent?.get(lookup.name)
          : _initialValues?.get(lookup.name);
    }

    // Handle special value 'initial'
    if (lookup != null && lookup.value == 'initial' && _initialValues != null) {
      return _initialValues!.get(prop);
    }

    // Handle special value 'inherit'
    if (lookup != null && lookup.value == 'inherit') {
      if (!inheritingProperty) {
        throw FssParseException('Cannot inherit $prop ');
      }
      return _parent?.get(prop);
    }

    // Not found and property allows to inherit from parent
    if (lookup == null && inheritingProperty && _parent != null) {
      lookup = _parent!.get(prop);
    }
    if (lookup == null && _initialValues != null) {
      lookup = _initialValues!.get(prop);
    }
    return _resolve(lookup);
  }

  String? getString(String prop) {
    final propValue = get(prop);
    return propValue?.value;
  }

  double? getSize(String prop) {
    final propValue = get(prop);
    if (propValue == null) {
      return null;
    }
    return _parseSizeDef(propValue).getPixelSize(_getBaseline());
  }

  Color? getColor(String prop) {
    var propValue = get(prop);
    if (propValue != null && propValue.value == 'currentcolor') {
      propValue = get(FssProperty.color.name);
    }
    return propValue == null ? null : FssColor._parseColorDef(propValue);
  }

  @override
  String toString() {
    final sb = StringBuffer('FssRuleBlock {\n');
    _properties.forEach((key, prop) => sb.writeln('$key: ${prop.value};'));
    sb.writeln('}');
    return sb.toString();
  }

  BorderSide getBorderSide(String side) {
    final colProp = getColor('border-$side-color');
    var borderColor =
        colProp ?? getColor(FssProperty.color.name) ?? Colors.black;

    final widthProp = get('border-$side-width');
    final borderWidth = _parseBorderSize(widthProp);

    final styleProp = get('border-$side-style');
    if (colProp == null && widthProp == null && styleProp == null) {
      return BorderSide.none;
    }

    BorderStyle style = BorderStyle.solid;
    if (styleProp == null ||
        'none' == styleProp.value ||
        'hidden' == styleProp.value) {
      style = BorderStyle.none;
    }

    if ('inset' == styleProp?.value && (side == 'top' || side == 'left')) {
      borderColor = _darkenColor(borderColor, 30);
    }
    if ('outset' == styleProp?.value && (side == 'bottom' || side == 'right')) {
      borderColor = _darkenColor(borderColor, 30);
    }

    return BorderSide(color: borderColor, width: borderWidth, style: style);
  }

  double convert(String sizeDef) {
    return _parseSizeDef(FssPropertyValue('', sizeDef))
        .getPixelSize(_getBaseline());
  }

  FssBase _getBaseline() {
    final emBase =
        _parent == null ? null : _parent!.getSize(FssProperty.font_size.name);
    final remBase = _initialValues == null
        ? null
        : _initialValues!.getSize(FssProperty.font_size.name);
    return FssBase(remBase: remBase, emBase: emBase);
  }

  // Resolves the value of a given property by replacing variables and
  // resolving special property values.
  FssPropertyValue? _resolve(FssPropertyValue? propertyValue) {
    if (propertyValue == null) {
      return null;
    }
    // Handle special value 'none'
    if (propertyValue.value == 'none') {
      return null;
    }

    if (!propertyValue.value.startsWith('var(')) {
      return propertyValue;
    }
    // Try to resolve var.
    final varName = propertyValue.value
        .substring(4, propertyValue.value.lastIndexOf(')'))
        .trim();
    final replacement = get(varName);
    if (replacement == null) {
      return null;
    }

    return _resolve(replacement);
  }

  // Resolves the value by replacing variables and
  // resolving special property values.
  String? _resolveValue(String? value) {
    if (value == null) {
      return null;
    }
    // Handle special value 'none'
    if (value == 'none') {
      return null;
    }

    if (!value.startsWith('var(')) {
      return value;
    }
    // Try to resolve var.
    final varName = value.substring(4, value.lastIndexOf(')')).trim();
    final replacement = get(varName);
    if (replacement == null) {
      return null;
    }

    return _resolveValue(replacement.value);
  }

  static String _toRoman(int number) {
    if (number < 1) return '';
    if (number >= 1000) return 'M${_toRoman(number - 1000)}';
    if (number >= 900) return 'CM${_toRoman(number - 900)}';
    if (number >= 500) return 'D${_toRoman(number - 500)}';
    if (number >= 400) return 'CD${_toRoman(number - 400)}';
    if (number >= 100) return 'C${_toRoman(number - 100)}';
    if (number >= 90) return 'XC${_toRoman(number - 90)}';
    if (number >= 50) return 'L${_toRoman(number - 50)}';
    if (number >= 40) return 'XL${_toRoman(number - 40)}';
    if (number >= 10) return 'X${_toRoman(number - 10)}';
    if (number >= 9) return 'IX${_toRoman(number - 9)}';
    if (number >= 5) return 'V${_toRoman(number - 5)}';
    if (number >= 4) return 'IV${_toRoman(number - 4)}';
    if (number >= 1) return 'I${_toRoman(number - 1)}';
    throw FssParseException('Number input invalid: $number');
  }

  TextOverflow _parseTextOverflow(FssPropertyValue valueDef) {
    switch (valueDef.value) {
      case 'clip':
        return TextOverflow.clip;
      case 'ellipsis':
        return TextOverflow.ellipsis;
      case 'fade':
        return TextOverflow.fade;
      default:
        throw FssParseException.forValue(valueDef);
    }
  }

  Shadow _parseShadow(FssPropertyValue valueDef, FssBase base) {
    // text-shadow: .2em .2em 0.3em #ccc;
    final values = _splitValues(this, valueDef.value);
    final dx = _parseSizeDef(valueDef.subValue(values[0])).getPixelSize(base);
    final dy = values.length > 1
        ? _parseSizeDef(valueDef.subValue(values[1])).getPixelSize(base)
        : 0.0;
    final blur = values.length > 2
        ? _parseSizeDef(valueDef.subValue(values[2])).getPixelSize(base)
        : 0.0;
    final color = values.length > 3
        ? FssColor._parseColorDef(valueDef.subValue(values[3]))
        : Colors.black;
    return Shadow(offset: Offset(dx, dy), color: color, blurRadius: blur);
  }

  BoxShadow _parseBoxShadow(FssPropertyValue valueDef, FssBase base) {
    // text-shadow: .2em .2em 0.3em #ccc;
    final values = _splitValues(this, valueDef.value);
    final dx = _parseSizeDef(valueDef.subValue(values[0])).getPixelSize(base);
    final dy = values.length > 1
        ? _parseSizeDef(valueDef.subValue(values[1])).getPixelSize(base)
        : 0.0;
    final blur = values.length > 2
        ? _parseSizeDef(valueDef.subValue(values[2])).getPixelSize(base)
        : 0.0;
    final spread = values.length > 3
        ? _parseSizeDef(valueDef.subValue(values[3])).getPixelSize(base)
        : 0.0;
    final color = values.length > 4
        ? FssColor._parseColorDef(valueDef.subValue(values[4]))
        : Colors.black;
    return BoxShadow(
      offset: Offset(dx, dy),
      blurRadius: blur,
      spreadRadius: spread,
      color: color,
    );
  }

  TextAlign _parseTextAlign(FssPropertyValue valueDef) {
    switch (valueDef.value) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      case 'start':
        return TextAlign.start;
      case 'end':
        return TextAlign.end;
      default:
        throw FssParseException.forValue(valueDef);
    }
  }

  double _parseBorderSize(FssPropertyValue? valueDef) {
    if (valueDef == null) {
      return 3; // default is medium
    }
    switch (valueDef.value) {
      case 'thin':
        return 1;
      case 'medium':
        return 3;
      case 'thick':
        return 5;
    }
    return _parseSizeDef(valueDef).value;
  }

  TextDecorationStyle _parseTextDecStyle(FssPropertyValue valueDef) {
    switch (valueDef.value) {
      case 'dashed':
        return TextDecorationStyle.dashed;
      case 'dotted':
        return TextDecorationStyle.dotted;
      case 'double':
        return TextDecorationStyle.double;
      case 'solid':
        return TextDecorationStyle.solid;
      case 'wavy':
        return TextDecorationStyle.wavy;
      default:
        throw FssParseException.forValue(valueDef);
    }
  }

  TextDecoration? _parseTextDecLine(FssPropertyValue valueDef) {
    switch (valueDef.value) {
      case 'none':
        return TextDecoration.none;
      case 'underline':
        return TextDecoration.underline;
      case 'line-through':
        return TextDecoration.lineThrough;
      case 'overline':
        return TextDecoration.overline;
      default:
        throw FssParseException.forValue(valueDef);
    }
  }

  /// Parse value for vertical alignment
  Alignment _parseVertAlign(FssPropertyValue valueDef) {
    switch (valueDef.value) {
      case 'top':
        return Alignment.topCenter;
      case 'middle':
        return Alignment.center;
      case 'center':
        return Alignment.center;
      case 'baseline': // TODO As we use a container this is not fully supported yet
        return Alignment.center;
      case 'bottom':
        return Alignment.bottomCenter;
      default:
        throw FssParseException.forValue(valueDef);
    }
  }

  /// Parses the font weight value
  FontWeight? _parseFontWeight(FssPropertyValue valueDef) {
    switch (valueDef.value) {
      case 'normal':
        return FontWeight.normal;
      case 'bold':
        return FontWeight.bold;
      case 'bolder':
        // should be relative to parent font but we do not know about UI hierarchy
        return FontWeight.w800;
      case 'lighter':
        // should be relative to parent font but we do not know about UI hierarchy
        return FontWeight.w300;
      default:
        final size = _parseSizeDef(valueDef);
        final index = ((size.value / 100) - 1).toInt();
        return FontWeight.values[index];
    }
  }

  ImageRepeat _parseBackroundRepeat(FssPropertyValue valueDef) {
    ImageRepeat repeat = ImageRepeat.noRepeat;
    switch (valueDef.value) {
      case 'repeat':
        repeat = ImageRepeat.repeat;
        break;
      case 'repeat-x':
        repeat = ImageRepeat.repeatX;
        break;
      case 'repeat-y':
        repeat = ImageRepeat.repeatY;
        break;
      default:
        repeat = ImageRepeat.noRepeat;
    }
    return repeat;
  }

  BoxFit? _parseBackroundSize(FssPropertyValue valueDef) {
    BoxFit? result;
    switch (valueDef.value) {
      case 'contain':
        result = BoxFit.contain;
        break;
      case 'cover':
        result = BoxFit.cover;
        break;
      case 'fill':
        result = BoxFit.fill;
        break;
      case 'scale-down':
        result = BoxFit.scaleDown;
        break;
      case 'fit-width':
        result = BoxFit.fitWidth;
        break;
      case 'fit-height':
        result = BoxFit.fitHeight;
        break;
      case 'auto':
        result = BoxFit.none;
        break;
      default:
        result = null;
    }
    // TODO support 2 value mode like 100% 100% or auto 100%
    return result;
  }

  /// Helper method to capitalize all words of a text.
  String _capitalizeAllWords(String input) {
    final result = StringBuffer();
    for (final m in RegExp(r'([\W-_]+)(\w+\S+)').allMatches(input)) {
      final whitespace = m.group(1)!;
      final word = m.group(2)!;
      result
        ..write(whitespace)
        ..write(word[0].toUpperCase())
        ..write(word.substring(1));
    }
    return result.toString();
  }

  AlignmentGeometry? _combineAlignment(TextAlign? hor, Alignment? vert) {
    if (hor == null && vert == null) {
      return null;
    }
    double x = 0.0;
    final y = vert == null ? 0.0 : vert.y;

    bool directional = false;
    if (hor != null) {
      switch (hor) {
        case TextAlign.left:
          x = Alignment.centerLeft.x;
          break;
        case TextAlign.right:
          x = Alignment.centerRight.x;
          break;
        case TextAlign.start:
          directional = true;
          x = AlignmentDirectional.centerStart.start;
          break;
        case TextAlign.end:
          directional = true;
          x = AlignmentDirectional.centerEnd.start;
          break;
        case TextAlign.center:
          x = Alignment.center.x;
          break;
        case TextAlign.justify:
          x = AlignmentDirectional.centerStart.start;
          break;
      }
    }
    return directional ? AlignmentDirectional(x, y) : Alignment(x, y);
  }

  /// Parses an image source into an ImageProvider
  ImageProvider _parseImageSource(FssPropertyValue valueDef) {
    if (valueDef.value.toLowerCase().startsWith('http:') ||
        valueDef.value.toLowerCase().startsWith('https:')) {
      // TODO properly parse this: should be url(http://...)
      // Allow also multiple backgrounds.
      // Make sure that URLs are not converted all to lowercase.
      return NetworkImage(valueDef.value, scale: 1.0);
    }

    // Assume it is a name of an asset image.
    return AssetImage(valueDef.value);
  }

  LinearGradient _parseLinearGradient(
    String propValue,
    FssPropertyValue imageDef,
  ) {
    final spec = propValue.substring(
      propValue.indexOf('(') + 1,
      propValue.lastIndexOf(')'),
    );
    final parts = _splitFunctionParams(this, spec);

    final List<Color> colors = [];
    final List<double> stops = [];
    var begin = Alignment.bottomCenter;
    var end = Alignment.topCenter;
    bool firstPart = true;
    for (final part in parts) {
      // First part is a direction instruction or an angel
      if (firstPart) {
        firstPart = false;
        if (part.startsWith('to ')) {
          final degree = _parseGradientTo(part);
          begin = _convertDegreeToAlignment(degree);
          end = _convertDegreeToAlignment(degree + 180);
        } else {
          final degree = FssAngle.parse(part).getDegree();
          begin = _convertDegreeToAlignment(degree);
          end = _convertDegreeToAlignment(degree + 180);
        }
        continue;
      }

      final colStop = _splitValues(this, part);
      colors.add(
        FssColor._parseColorDef(
          FssPropertyValue('color', colStop[0], imageDef.lineNo),
        ),
      );
      if (colStop.length == 1) {
        // Only color defined. Put a placeholder as stop to interpolate later.
        stops.add(-1);
      }
      if (colStop.length > 1) {
        // Color and stop defined
        stops.add(
          _parsePercent(
            FssPropertyValue('stop', colStop[1], imageDef.lineNo),
          ),
        );
      }
      if (colStop.length > 2) {
        // Two stop definition
        colors.add(
          FssColor._parseColorDef(
            FssPropertyValue('color', colStop[0], imageDef.lineNo),
          ),
        );
        stops.add(
          _parsePercent(
            FssPropertyValue('stop', colStop[2], imageDef.lineNo),
          ),
        );
      }
    }
    // Interpolate missing values
    if (stops.isNotEmpty && stops[0] == -1) stops[0] = 0;
    if (stops.isNotEmpty && stops[stops.length - 1] == -1) {
      stops[stops.length - 1] = 1.0;
    }
    // TODO interpolate values if -1

    return LinearGradient(colors: colors, stops: stops, begin: begin, end: end);
  }

  RadialGradient _parseRadialGradient(
    String propValue,
    FssPropertyValue imageDef,
  ) {
    final spec = propValue.substring(
      propValue.indexOf('(') + 1,
      propValue.lastIndexOf(')'),
    );
    final parts = _splitFunctionParams(this, spec);

    final List<Color> colors = [];
    final List<double> stops = [];
    // final begin = Alignment.bottomCenter;
    // final end = Alignment.topCenter;
    for (final part in parts) {
      // TODO First part is special

      final colStop = _splitValues(this, part);
      // TODO resolve split values
      colors.add(
        FssColor._parseColorDef(
          FssPropertyValue('color', colStop[0], imageDef.lineNo),
        ),
      );
      if (colStop.length == 1) {
        // Only color defined. Put a placeholder as stop to interpolate later.
        stops.add(-1);
      }
      if (colStop.length > 1) {
        // Color and stop defined
        stops.add(
          _parsePercent(
            FssPropertyValue('stop', colStop[1], imageDef.lineNo),
          ),
        );
      }
      if (colStop.length > 2) {
        // Two stop definition
        colors.add(
          FssColor._parseColorDef(
            FssPropertyValue('color', colStop[0], imageDef.lineNo),
          ),
        );
        stops.add(
          _parsePercent(
            FssPropertyValue('stop', colStop[2], imageDef.lineNo),
          ),
        );
      }
    }
    // Interpolate missing values
    if (stops.isNotEmpty && stops[0] == -1) stops[0] = 0;
    if (stops.isNotEmpty && stops[stops.length - 1] == -1) {
      stops[stops.length - 1] = 1.0;
    }
    // TODO interpolate values if -1

    // Where do we get the actual size from
    // const width = 100.0;
    // const height = 100.0;
    const radius = 1.0;
    const size = 'farthest-corner';
    if (size == 'closest-side') {}
    if (size == 'closest-corner') {}
    if (size == 'farthest-side') {}
    if (size == 'farthest-corner') {}

    return RadialGradient(
      colors: colors,
      stops: stops,
      radius: radius,
    );
  }

  /// Get the pattern for the dashed border
  List<double> _dashedBorderPattern() {
    final dashDef = get(FssProperty.fss_dashed_pattern.name);
    if (dashDef != null) {
      final values = _splitValues(this, dashDef.value);
      return values.map(double.parse).toList();
    }
    return [8.0, 8.0];
  }

  CircularIntervalList<double>? _parseBorderPattern(
    BorderSide side,
    String? style,
  ) {
    if (style == null) {
      return null;
    }
    switch (style) {
      case 'dashed':
        return CircularIntervalList(_dashedBorderPattern());
      case 'dotted':
        return CircularIntervalList([side.width, side.width]);
      case 'solid':
      case 'inset':
      case 'outset':
        return CircularIntervalList([100000000.0]);
      default:
        return null;
    }
  }

  /// Manipulates the input content in line with the "text_transform" property
  String _applyTextTransform(String input) {
    var result = input;
    final textTransform = get(FssProperty.text_transform.name);
    if (textTransform != null) {
      switch (textTransform.value) {
        case 'lowercase':
          result = result.toLowerCase();
          break;
        case 'uppercase':
          result = result.toUpperCase();
          break;
        case 'capitalize':
          result = _capitalizeAllWords(result);
          break;
      }
    }
    return result;
  }

  /// Replaces the input content in line with the "content" property
  String _replaceContent(String input) {
    var result = input;
    final contentMode = get(FssProperty.content.name);
    if (contentMode != null) {
      switch (contentMode.value) {
        case 'none':
          break;
        case 'normal':
          break;
        case 'open-quote':
          // TODO get this from "quote"
          result = '"';
          break;
        case 'close-quote':
          // TODO get this from "quote"
          result = '"';
          break;
        default:
          // TODO content "string" needs to be decoded properly
          result = contentMode.value;
      }
    }
    return result;
  }

  /// Parses a gradient to definition
  /// Returns the value as degree.
  double _parseGradientTo(String to) {
    final parts = _splitValues(this, to);
    parts.removeAt(0);
    parts.sort();
    final String dir = parts.fold('', (prev, next) => '$prev $next').trim();
    switch (dir) {
      case 'top':
        return 0.0;
      case 'right top':
        return 45.0;
      case 'right':
        return 90.0;
      case 'bottom right':
        return 135.0;
      case 'bottom':
        return 180.0;
      case 'bottom left':
        return 225.0;
      case 'left':
        return 270.0;
      case 'left top':
        return 315.0;
    }
    return 0.0;
  }
}

Alignment _convertDegreeToAlignment(double degree) {
  var result = degree;
  result %= 360; // normalize to 360 and positive degrees
  if (result < 0) {
    result = 360 - result;
  }
  double x = 0;
  double y = 0;
  final modulo = result % 45.0;
  final delta = modulo / 45.0;
  if (result >= 0 && result < 45) {
    x = delta * -1;
    y = 1.0;
  }
  if (result >= 45 && result < 90) {
    x = -1.0;
    y = 1 - delta;
  }
  if (result >= 90 && result < 135) {
    x = -1.0;
    y = delta * -1;
  }
  if (result >= 135 && result < 180) {
    x = -1 + delta;
    y = -1.0;
  }
  if (result >= 180 && result < 225) {
    x = delta;
    y = -1.0;
  }
  if (result >= 225 && result < 270) {
    x = 1.0;
    y = -1 + delta;
  }
  if (result >= 270 && result < 315) {
    x = 1.0;
    y = delta;
  }
  if (result >= 315 && result < 360) {
    x = 1 - delta;
    y = 1;
  }

  return Alignment(x, y);
}

/// Small helper class to store a rule match in a list and to allow to sort them
/// by specificity / order.
@immutable
class _FssRuleMatch implements Comparable<_FssRuleMatch> {
  final FssRule rule;
  final int specificity;
  final int order;

  /// Constructor
  const _FssRuleMatch(this.rule, this.specificity, this.order);

  /// compare first by specificity and then by order
  @override
  int compareTo(_FssRuleMatch other) {
    final result = specificity.compareTo(other.specificity);
    if (result == 0) {
      return order.compareTo(other.order);
    }
    return result;
  }
}

/// Defines a selector based on a "type" an "id" and a list of "classes"
///
/// There is a special selector with type=* that will match all elements.
@immutable
class FssSelector {
  static const typeAll = '*';
  static const matchAll = FssSelector(type: typeAll);
  static const noMatch = 0;

  final String type;
  final String id;
  final List<String> classes;

  /// Constructor to build a selector
  const FssSelector({this.type = '', this.id = '', this.classes = const []});

  /// Checks if the given type, id and classes will be matched by this selector.
  ///
  /// Returns the specificity of the selector matching the input with
  /// 0 meaning no match.
  /// The bigger the number the better is the match of this selector.
  /// Type match adds 1, class match adds 1000, id match adds 1million.
  int getSpecificity(
    String? matchType,
    String? matchId,
    List<String>? matchClasses, [
    MediaQueryData? media,
  ]) {
    int specificity = noMatch;
    final matchTypeL = matchType?.toLowerCase();

    // Check type
    if (type == typeAll) {
      specificity += 1;
    } else if (type.isNotEmpty && type != matchTypeL) {
      return noMatch;
    } else if (type.isNotEmpty && type == matchTypeL) {
      specificity += 5;
    }

    // Check classes
    if (classes.isNotEmpty && (matchClasses == null || matchClasses.isEmpty)) {
      return noMatch;
    }

    final matchClassesL = [];
    matchClasses?.forEach((cl) => matchClassesL.add(cl.toLowerCase()));
    for (final cl in classes) {
      if (!matchClassesL.contains(cl)) {
        return noMatch;
      }
    }
    specificity += classes.length * 1000;

    // Check ID
    final matchIdL = matchId?.toLowerCase();
    if (id.isNotEmpty && id != matchIdL) {
      return noMatch;
    } else if (id.isNotEmpty && id == matchIdL) {
      specificity += 1000000;
    }
    return specificity;
  }

  @override
  bool operator ==(Object other) {
    return other is FssSelector &&
        id == other.id &&
        type == other.type &&
        listEquals(classes, other.classes);
  }

  @override
  int get hashCode => hashValues(type, id, hashList(classes));

  @override
  String toString() {
    return 'FssSelector: type="$type" id="$id" classes=$classes';
  }

  factory FssSelector.parse(String path) {
    // We expect here a single selector. So splitting by "," should to be done already
    path = path.trim().toLowerCase();

    //for example: p h1  or p > h1 or p + h1
    if (path.contains(' ') ||
        path.contains('>') ||
        path.contains('+') ||
        path.contains('~')) {
      throw const FssParseException(
        'Hierarchical selectors are not supported ( + > ~)',
      );
    }
    //for example: [target]
    if (path.contains('[') && path.contains(']')) {
      throw const FssParseException(
        'Attribute matching selectors are not supported [...]',
      );
    }

    //for example: p::before
    if (path.contains('::')) {
      throw const FssParseException(
        'Selectors for virtual elements are not supported (::before ::after)',
      );
    }

    String type = '';
    String id = '';
    final List<String> classes = [];
    final token = path.split(RegExp(r'(?=[\.:#])'));
    for (final t in token) {
      if (t.startsWith('.') || t.startsWith(':')) {
        classes.add(t);
      } else if (t.startsWith('#')) {
        id = t;
      } else {
        type = t;
      }
    }
    return FssSelector(type: type, id: id, classes: classes);
  }
}

/// A special rule container for a media block.
///
/// It contains internally a list of sub rules. If the media rule's
/// selector matches only then the sub rules are evaluated.
@immutable
class _FssMediaRule extends FssRule {
  final List<FssRule> subRules;

  _FssMediaRule(String mediaQuery, this.subRules)
      : super(
          FssMediaSelector(mediaQuery: mediaQuery),
          FssRuleBlock(const {}),
        );

  @override
  String toString() {
    final result = StringBuffer();
    result
      ..writeln('// BEGIN @MEDIA BLOCK')
      ..write(selector)
      ..writeln(' {')
      ..writeln();
    subRules.forEach(result.writeln);
    result.writeln('} // END @MEDIA BLOCK');

    return result.toString();
  }
}

/// A Special selector for a media rules.
@immutable
class FssMediaSelector extends FssSelector {
  final String mediaQuery;

  const FssMediaSelector({required this.mediaQuery}) : super(type: mediaQuery);

  /// Checks only the given media against the media rule of this selector.
  /// Return 1 if the media features are matching else 0.
  @override
  int getSpecificity(
    String? matchType,
    String? matchId,
    List<String>? matchClasses, [
    MediaQueryData? media,
  ]) {
    if (media == null) {
      return 0;
    }
    bool matched = true;
    // CSS syntax @media only screen and (max-width: 600px)
    // ignore the media type and only look at the features.
    // We only support AND combined features for now.
    int start = mediaQuery.indexOf('(');
    while (start != -1 && matched) {
      final end = mediaQuery.indexOf(')', start);
      final feature = mediaQuery.substring(start + 1, end).trim();
      start = mediaQuery.indexOf('(', end + 1);

      String name = feature;
      String operator = '=';
      String value = '';
      final match = RegExp(r'([a-z-]+)\s*([<=>:]+)\s*([a-z0-9/-\s]+)')
          .firstMatch(feature);
      if (match != null) {
        name = match.group(1)!;
        operator = match.group(2)!;
        value = match.group(3)!;
      }
      if (operator == ':') operator = '=';
      if (name.startsWith('min-')) {
        name = name.substring(4);
        operator = '>';
      }
      if (name.startsWith('max-')) {
        name = name.substring(4);
        operator = '<';
      }

      switch (name) {
        case 'width':
          final expected = _parseSizeDef(FssPropertyValue(name, value))
              .getPixelSize(FssBase.fallback);
          matched = _compare(media.size.width, operator, expected);
          break;
        case 'height':
          final expected = _parseSizeDef(FssPropertyValue(name, value))
              .getPixelSize(FssBase.fallback);
          matched = _compare(media.size.height, operator, expected);
          break;
        case 'aspect-ratio':
          final parts = value.split('/'); // support value like this 16/9
          final expected = parts.length > 1
              ? (double.parse(parts[0].trim()) / double.parse(parts[1].trim()))
              : _parseSizeDef(FssPropertyValue(name, value))
                  .getPixelSize(FssBase.fallback);
          matched = _compare(
            media.size.width / media.size.height,
            operator,
            expected,
          );
          break;
        case 'orientation':
          matched = (media.orientation.toString()) == value;
          break;
        case 'resolution':
          final expected = _parseSizeDef(FssPropertyValue(name, value))
              .getPixelSize(FssBase.fallback);
          matched = _compare(media.devicePixelRatio, operator, expected);
          break;
        case 'prefers-contrast':
          // ignore: avoid_bool_literals_in_conditional_expressions
          matched = ('more' == value) ? media.highContrast : true;
          break;
        case 'inverted-colors':
          // ignore: avoid_bool_literals_in_conditional_expressions
          matched = ('inverted' == value) ? media.invertColors : true;
          break;
        case 'prefers-color-scheme':
          // ignore: avoid_bool_literals_in_conditional_expressions
          matched = ('dark' == value)
              ? media.platformBrightness == Brightness.dark
              : true;
          break;
        default:
          matched = false;
          break;
      }
    }

    return matched ? 1 : 0;
  }

  @override
  String toString() {
    return 'FssMediaSelector: rule="$mediaQuery"';
  }

  @override
  bool operator ==(Object other) {
    return other is FssMediaSelector && mediaQuery == other.mediaQuery;
  }

  @override
  int get hashCode => mediaQuery.hashCode;

  bool _compare(double actual, String operator, double expected) {
    switch (operator.trim()) {
      case '=':
        return actual == expected;
      case '<':
        return actual < expected;
      case '<=':
        return actual <= expected;
      case '>':
        return actual > expected;
      case '>=':
        return actual >= expected;
      default:
        return actual == expected;
    }
  }
}

/// Defines all standard properties with their names and initial values.
///
/// This can be used to lookup properties by name.
/// For example via [FssRuleBlock.get], [FssRuleBlock.getString],
/// [FssRuleBlock.getColor]
@immutable
class FssProperty {
  // Reserved for our own internal properties.
  static const fssPropertyPrefix = '-fss-';
  // We use this when we split shortcut properties into sub values.
  static const subPropertyPrefix = '_';
  // Used to declare variables.
  static const varPrefix = '--';

  static const accent_color = FssProperty._('accent_color', 'auto');
  static const background_color =
      FssProperty._('background-color', null, inherited: false);
  static const background_image =
      FssProperty._('background-image', null, inherited: false);
  static const background_position =
      FssProperty._('background-position', 'left top', inherited: false);
  static const background_repeat =
      FssProperty._('background-repeat', 'repeat', inherited: false);
  static const background_size =
      FssProperty._('background-size', 'auto auto', inherited: false);
  static const border = FssProperty._('border', null, inherited: false);
  static const border_bottom =
      FssProperty._('border-bottom', null, inherited: false);
  static const border_bottom_color =
      FssProperty._('border-bottom-color', 'currentcolor', inherited: false);
  static const border_bottom_left_radius =
      FssProperty._('border-bottom-left-radius', 'none', inherited: false);
  static const border_bottom_right_radius =
      FssProperty._('border-bottom-right-radius', 'none', inherited: false);
  static const border_bottom_style =
      FssProperty._('border-bottom-style', 'none', inherited: false);
  static const border_bottom_width =
      FssProperty._('border-bottom-width', 'medium', inherited: false);
  static const border_color =
      FssProperty._('border-color', null, inherited: false);
  static const border_left =
      FssProperty._('border-left', null, inherited: false);
  static const border_left_color =
      FssProperty._('border-left-color', 'currentcolor', inherited: false);
  static const border_left_style =
      FssProperty._('border-left-style', 'none', inherited: false);
  static const border_left_width =
      FssProperty._('border-left-width', 'medium', inherited: false);
  static const border_radius =
      FssProperty._('border-radius', null, inherited: false);
  static const border_right =
      FssProperty._('border-right', null, inherited: false);
  static const border_right_color =
      FssProperty._('border-right-color', 'currentcolor', inherited: false);
  static const border_right_style =
      FssProperty._('border-right-style', 'none', inherited: false);
  static const border_right_width =
      FssProperty._('border-right-width', 'medium', inherited: false);
  static const border_style =
      FssProperty._('border-style', null, inherited: false);
  static const border_top = FssProperty._('border-top', null, inherited: false);
  static const border_top_color =
      FssProperty._('border-top-color', 'currentcolor', inherited: false);
  static const border_top_left_radius =
      FssProperty._('border-top-left-radius', 'none', inherited: false);
  static const border_top_right_radius =
      FssProperty._('border-top-right-radius', 'none', inherited: false);
  static const border_top_style =
      FssProperty._('border-top-style', 'none', inherited: false);
  static const border_top_width =
      FssProperty._('border-top-width', 'medium', inherited: false);
  static const border_width =
      FssProperty._('border-width', null, inherited: false);
  static const box_shadow =
      FssProperty._('box-shadow', 'none', inherited: false);
  static const caret_color = FssProperty._('caret-color', null);
  static const color = FssProperty._('color', '#000000');
  static const content = FssProperty._('content', 'normal');
  static const content_visibility =
      FssProperty._('content-visibility', 'visible', inherited: false);
  static const direction = FssProperty._('direction', 'ltr');
  static const font = FssProperty._('font', null);
  static const font_family = FssProperty._('font-family', null);
  static const font_size = FssProperty._('font-size', 'medium');
  static const font_style = FssProperty._('font-style', 'normal');
  static const font_weight = FssProperty._('font-weight', 'normal');
  static const height = FssProperty._('height', null, inherited: false);
  static const letter_spacing = FssProperty._('letter-spacing', null);
  static const line_height = FssProperty._('line-height', null);
  static const list_style_image = FssProperty._('list-style-image', null);
  static const list_style_type = FssProperty._('list-style-type', 'disc');
  static const margin = FssProperty._('margin', null, inherited: false);
  static const margin_bottom =
      FssProperty._('margin-bottom', '0', inherited: false);
  static const margin_left =
      FssProperty._('margin-left', '0', inherited: false);
  static const margin_right =
      FssProperty._('margin-right', '0', inherited: false);
  static const margin_top = FssProperty._('margin-top', '0', inherited: false);
  static const max_height = FssProperty._('max-height', null, inherited: false);
  static const max_width = FssProperty._('max-width', null, inherited: false);
  static const min_height = FssProperty._('min-height', null, inherited: false);
  static const min_width = FssProperty._('min-width', null, inherited: false);
  static const padding = FssProperty._('padding', null, inherited: false);
  static const padding_bottom =
      FssProperty._('padding-bottom', '0', inherited: false);
  static const padding_left =
      FssProperty._('padding-left', '0', inherited: false);
  static const padding_right =
      FssProperty._('padding-right', '0', inherited: false);
  static const padding_top =
      FssProperty._('padding-top', '0', inherited: false);
  static const text_align = FssProperty._('text-align', 'start');
  static const text_decoration =
      FssProperty._('text-decoration', null, inherited: false);
  static const text_decoration_color =
      FssProperty._('text-decoration-color', 'currentcolor', inherited: false);
  static const text_decoration_line =
      FssProperty._('text-decoration-line', 'none', inherited: false);
  static const text_decoration_style =
      FssProperty._('text-decoration-style', 'solid', inherited: false);
  static const text_decoration_thickness =
      FssProperty._('text-decoration-thickness', 'none', inherited: false);
  static const text_overflow =
      FssProperty._('text-overflow', 'clip', inherited: false);
  static const text_shadow = FssProperty._('text-shadow', 'none');
  static const text_stroke =
      FssProperty._('text-stroke', null, inherited: false);
  static const text_stroke_color =
      FssProperty._('text-stroke-color', null, inherited: false);
  static const text_stroke_width =
      FssProperty._('text-stroke-width', '0', inherited: false);
  static const text_transform = FssProperty._('text-transform', 'none');
  static const transform = FssProperty._('transform', 'none', inherited: false);
  static const vertical_align =
      FssProperty._('vertical-align', 'baseline', inherited: false);
  static const visibility = FssProperty._('visibility', 'visible');
  static const white_space = FssProperty._('white-space', 'normal');
  static const width = FssProperty._('width', null, inherited: false);
  static const word_spacing = FssProperty._('word-spacing', null);

  // Below we have some custom properties

  // The total width for the list bullet area used to display the symbol.
  static const fss_list_symbol_width =
      FssProperty._('-fss-list-symbol-width', '3em');
  // The space between symbol and the start of a list item
  static const fss_list_symbol_gap =
      FssProperty._('-fss-list-symbol-gap', '0.5em');
  // The space between symbol and the start of a list item
  static const fss_dashed_pattern =
      FssProperty._('-fss-dashed-pattern', '8.0 8.0');

  static const List<FssProperty> all = [
    accent_color,
    background_color,
    background_image,
    background_position,
    background_repeat,
    background_size,
    border,
    border_bottom,
    border_bottom_color,
    border_bottom_left_radius,
    border_bottom_right_radius,
    border_bottom_style,
    border_bottom_width,
    border_color,
    border_left,
    border_left_color,
    border_left_style,
    border_left_width,
    border_radius,
    border_right,
    border_right_color,
    border_right_style,
    border_right_width,
    border_style,
    border_top,
    border_top_color,
    border_top_left_radius,
    border_top_right_radius,
    border_top_style,
    border_top_width,
    border_width,
    box_shadow,
    caret_color,
    color,
    content,
    content_visibility,
    direction,
    font,
    font_family,
    font_size,
    font_style,
    font_weight,
    height,
    letter_spacing,
    line_height,
    list_style_image,
    list_style_type,
    margin,
    margin_bottom,
    margin_left,
    margin_right,
    margin_top,
    max_height,
    max_width,
    min_height,
    min_width,
    padding,
    padding_bottom,
    padding_left,
    padding_right,
    padding_top,
    text_align,
    text_decoration,
    text_decoration_color,
    text_decoration_line,
    text_decoration_style,
    text_decoration_thickness,
    text_overflow,
    text_shadow,
    text_stroke,
    text_stroke_color,
    text_stroke_width,
    text_transform,
    transform,
    vertical_align,
    visibility,
    white_space,
    width,
    word_spacing,
  ];

  final String name;
  final String? initialValue; // Only null for shorthand properties
  final bool inherited;

  /// Private constructor
  const FssProperty._(this.name, this.initialValue, {this.inherited = true});

  // Gets all property defaults as FssRuleBlock
  static FssRuleBlock getDefaults() {
    final Map<String, FssPropertyValue> initialProps = {};
    for (final prop in FssProperty.all) {
      if (prop.initialValue != null) {
        initialProps[prop.name] =
            FssPropertyValue(prop.name, prop.initialValue!);
      }
    }
    return FssRuleBlock(initialProps);
  }

  static FssProperty? byName(String name) {
    final propDef = FssProperty.all.where((p) => p.name == name);
    return propDef.isEmpty ? null : propDef.first;
  }
}

/// Simple helper class to represent a property value definition as parsed from
/// a style sheet.
@immutable
class FssPropertyValue {
  final String name;
  final String value;
  final int lineNo;

  const FssPropertyValue(this.name, this.value, [this.lineNo = -1]);

  FssPropertyValue subValue(String subValue) =>
      FssPropertyValue(name, subValue, lineNo);

  @override
  String toString() {
    return '"$value" for property "$name" (line $lineNo)';
  }
}

/// Defines color constants for lookup
class FssColor {
  /// The standard colors supported by all browsers.
  /// The key is the name, the value is the hex color.
  /// You can use the [colorToHex] method to convert a browserColor
  /// value to a [Color]
  static const browserColors = {
    'aliceblue': '#f0f8ff',
    'antiquewhite': '#faebd7',
    'aqua': '#00ffff',
    'aquamarine': '#7fffd4',
    'azure': '#f0ffff',
    'beige': '#f5f5dc',
    'bisque': '#ffe4c4',
    'black': '#000000',
    'blanchedalmond': '#ffebcd',
    'blue': '#0000ff',
    'blueviolet': '#8a2be2',
    'brown': '#a52a2a',
    'burlywood': '#deb887',
    'cadetblue': '#5f9ea0',
    'chartreuse': '#7fff00',
    'chocolate': '#d2691e',
    'coral': '#ff7f50',
    'cornflowerblue': '#6495ed',
    'cornsilk': '#fff8dc',
    'crimson': '#dc143c',
    'cyan': '#00ffff',
    'darkblue': '#00008b',
    'darkcyan': '#008b8b',
    'darkgoldenrod': '#b8860b',
    'darkgray': '#a9a9a9',
    'darkgrey': '#a9a9a9',
    'darkgreen': '#006400',
    'darkkhaki': '#bdb76b',
    'darkmagenta': '#8b008b',
    'darkolivegreen': '#556b2f',
    'darkorange': '#ff8c00',
    'darkorchid': '#9932cc',
    'darkred': '#8b0000',
    'darksalmon': '#e9967a',
    'darkseagreen': '#8fbc8f',
    'darkslateblue': '#483d8b',
    'darkslategray': '#2f4f4f',
    'darkslategrey': '#2f4f4f',
    'darkturquoise': '#00ced1',
    'darkviolet': '#9400d3',
    'deeppink': '#ff1493',
    'deepskyblue': '#00bfff',
    'dimgray': '#696969',
    'dimgrey': '#696969',
    'dodgerblue': '#1e90ff',
    'firebrick': '#b22222',
    'floralwhite': '#fffaf0',
    'forestgreen': '#228b22',
    'fuchsia': '#ff00ff',
    'gainsboro': '#dcdcdc',
    'ghostwhite': '#f8f8ff',
    'gold': '#ffd700',
    'goldenrod': '#daa520',
    'gray': '#808080',
    'grey': '#808080',
    'green': '#008000',
    'greenyellow': '#adff2f',
    'honeydew': '#f0fff0',
    'hotpink': '#ff69b4',
    'indianred': '#cd5c5c',
    'indigo': '#4b0082',
    'ivory': '#fffff0',
    'khaki': '#f0e68c',
    'lavender': '#e6e6fa',
    'lavenderblush': '#fff0f5',
    'lawngreen': '#7cfc00',
    'lemonchiffon': '#fffacd',
    'lightblue': '#add8e6',
    'lightcoral': '#f08080',
    'lightcyan': '#e0ffff',
    'lightgoldenrodyellow': '#fafad2',
    'lightgray': '#d3d3d3',
    'lightgrey': '#d3d3d3',
    'lightgreen': '#90ee90',
    'lightpink': '#ffb6c1',
    'lightsalmon': '#ffa07a',
    'lightseagreen': '#20b2aa',
    'lightskyblue': '#87cefa',
    'lightslategray': '#778899',
    'lightslategrey': '#778899',
    'lightsteelblue': '#b0c4de',
    'lightyellow': '#ffffe0',
    'lime': '#00ff00',
    'limegreen': '#32cd32',
    'linen': '#faf0e6',
    'magenta': '#ff00ff',
    'maroon': '#800000',
    'mediumaquamarine': '#66cdaa',
    'mediumblue': '#0000cd',
    'mediumorchid': '#ba55d3',
    'mediumpurple': '#9370db',
    'mediumseagreen': '#3cb371',
    'mediumslateblue': '#7b68ee',
    'mediumspringgreen': '#00fa9a',
    'mediumturquoise': '#48d1cc',
    'mediumvioletred': '#c71585',
    'midnightblue': '#191970',
    'mintcream': '#f5fffa',
    'mistyrose': '#ffe4e1',
    'moccasin': '#ffe4b5',
    'navajowhite': '#ffdead',
    'navy': '#000080',
    'oldlace': '#fdf5e6',
    'olive': '#808000',
    'olivedrab': '#6b8e23',
    'orange': '#ffa500',
    'orangered': '#ff4500',
    'orchid': '#da70d6',
    'palegoldenrod': '#eee8aa',
    'palegreen': '#98fb98',
    'paleturquoise': '#afeeee',
    'palevioletred': '#db7093',
    'papayawhip': '#ffefd5',
    'peachpuff': '#ffdab9',
    'peru': '#cd853f',
    'pink': '#ffc0cb',
    'plum': '#dda0dd',
    'powderblue': '#b0e0e6',
    'purple': '#800080',
    'rebeccapurple': '#663399',
    'red': '#ff0000',
    'rosybrown': '#bc8f8f',
    'royalblue': '#4169e1',
    'saddlebrown': '#8b4513',
    'salmon': '#fa8072',
    'sandybrown': '#f4a460',
    'seagreen': '#2e8b57',
    'seashell': '#fff5ee',
    'sienna': '#a0522d',
    'silver': '#c0c0c0',
    'skyblue': '#87ceeb',
    'slateblue': '#6a5acd',
    'slategray': '#708090',
    'slategrey': '#708090',
    'snow': '#fffafa',
    'springgreen': '#00ff7f',
    'steelblue': '#4682b4',
    'tan': '#d2b48c',
    'teal': '#008080',
    'thistle': '#d8bfd8',
    'tomato': '#ff6347',
    'transparent': '#00000000',
    'turquoise': '#40e0d0',
    'violet': '#ee82ee',
    'wheat': '#f5deb3',
    'white': '#ffffff',
    'whitesmoke': '#f5f5f5',
    'yellow': '#ffff00',
    'yellowgreen': '#9acd32'
  };

  // matches rgb(2, 121, 139) and rgba(2, 121, 139, 0.5)
  static const _rgbFunctionPattern =
      r'rgb[a]?\(\s*([0-9]+)\s*,\s*([0-9]+)\s*,\s*([0-9]+)\s*(?:,\s*([0-9\.]+)\s*)?\)';

  static const _hslFunctionPattern =
      r'hsl[a]?\(\s*([0-9\.]+)\s*,\s*([0-9\.]+[%]?)\s*,\s*([0-9\.]+[%]?)\s*(?:,\s*([0-9\.]+)\s*)?\)';

  /// Private constructor
  FssColor._();

  /// Parses a color definition. Normally a hex color
  static Color _parseColorDef(FssPropertyValue valueDef) {
    try {
      return parseColor(valueDef.value);
    } on FssParseException {
      throw FssParseException.forValue(valueDef);
    }
  }

  /// Parses a color definition. Normally a hex color
  static Color parseColor(String value) {
    var colDef = value;
    colDef = colDef.trim();
    if (colDef.startsWith('#')) {
      return colorFromHex(colDef);
    }

    // is it a standard color name?
    final col = FssColor.browserColors[colDef];
    if (col != null) {
      return colorFromHex(col);
    }
    // is it a rgb function
    final Color? rgbCol = _parseRgbFunction(colDef);
    if (rgbCol != null) {
      return rgbCol;
    }

    // hsl function
    final Color? hslCol = _parseHslFunction(colDef);
    if (hslCol != null) {
      return hslCol;
    }

    throw FssParseException('Invalid color: $colDef');
  }

  static Color? _parseHslFunction(String value) {
    final hslValues = RegExp(_hslFunctionPattern).firstMatch(value);
    if (hslValues != null && hslValues.groupCount >= 3) {
      return HSLColor.fromAHSL(
        hslValues.group(4) == null
            ? 1.0
            : FssSize.parse(hslValues.group(4)!).value,
        FssSize.parse(hslValues.group(1)!).value,
        FssSize.parse(hslValues.group(2)!).value / 100.0,
        FssSize.parse(hslValues.group(3)!).value / 100.0,
      ).toColor();
    }
  }

  static Color? _parseRgbFunction(String value) {
    final rgbValues = RegExp(_rgbFunctionPattern).firstMatch(value);
    if (rgbValues != null && rgbValues.groupCount >= 3) {
      return Color.fromARGB(
        rgbValues.group(4) == null
            ? 255
            : (255 * double.parse(rgbValues.group(4)!.trim())).toInt(),
        int.parse(rgbValues.group(1)!.trim()),
        int.parse(rgbValues.group(2)!.trim()),
        int.parse(rgbValues.group(3)!.trim()),
      );
    }
    return null;
  }

  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String? colorToHex(Color? color) {
    return color == null
        ? null
        : '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }
}

/// Some predefined element type names as known from HTML
/// We add some non standard elements too.
enum FssType {
  body,
  body2,
  button,
  caption,
  div,
  h1,
  h2,
  h3,
  h4,
  h5,
  h6,
  hr,
  img,
  li,
  ol,
  overline,
  p,
  subtitle1,
  subtitle2,
  text,
  ul,
}

/// Some extension to the enum to get the name of an entry.
extension FssTypeNameEx on FssType {
  String get name => describeEnum(this);
}

/// Defines a length / size with unit
///
/// You can use the [getPixelSize] method to convert the value from any unit
/// to a size in virtual pixel.
@immutable
class FssSize {
  static const ppi = 96;
  static const baseFontSize = 16.0; // default font size in web browser 16

  final double value;
  final String? unit;

  const FssSize(this.value, this.unit);

  /// The calculated size in Logical Pixels
  /// 1 in = 96px = 2.54cm = 25.4mm = 72pt = 6pc
  double getPixelSize(FssBase base) {
    double result;
    switch (unit) {
      case 'in':
        result = value * ppi;
        break;
      case 'em':
        result = value * base.em;
        break;
      case 'ex':
        result = value * base.em * 0.5; // not exact but ok.
        break;
      case 'rem':
        result = value * base.rem;
        break;
      case '':
      case 'px':
        result = value;
        break;
      case 'dpi': // used for media query
        result = value;
        break;
      case 'dppx': // used for media query
      case 'x':
        result = value;
        break;
      case 'absolute':
        result = base.rem + value;
        break;
      case 'relative':
        result = base.em + value;
        break;
      default:
        throw FssParseException('Unit not supported: $unit');
    }
    return result;
  }

  factory FssSize.parse(String def) {
    switch (def) {
      case 'medium':
        return const FssSize(0, 'absolute');
      case 'small':
        return const FssSize(-1, 'absolute');
      case 'x-small':
        return const FssSize(-2, 'absolute');
      case 'xx-small':
        return const FssSize(-3, 'absolute');
      case 'large':
        return const FssSize(1, 'absolute');
      case 'x-large':
        return const FssSize(2, 'absolute');
      case 'xx-large':
        return const FssSize(3, 'absolute');
      case 'xxx-large':
        return const FssSize(4, 'absolute');
      case 'larger':
        return const FssSize(1, 'relative');
      case 'smaller':
        return const FssSize(-1, 'relative');
    }
    final m = RegExp(r'([+-]?[0-9\.]+)([a-z%]*)').matchAsPrefix(def.trim());
    if (m != null) {
      return FssSize(double.parse(m.group(1)!), m.group(2));
    }
    throw FssParseException('Invalid size value: $def');
  }

  @override
  String toString() {
    return 'FssValue: $value${unit ?? ''}';
  }
}

/// Defines a angel as used by gradient definitions.
@immutable
class FssAngle {
  final double value;
  final String? unit;

  const FssAngle(this.value, this.unit);

  /// The radians for the angle.
  double getRadians() {
    double result;
    switch (unit) {
      case 'deg':
        result = value * (pi / 180.0);
        break;
      case 'rad':
        result = value;
        break;
      case 'grad':
        result = value * 0.015708;
        break;
      case 'turn':
        result = value / 6.28319;
        break;
      default:
        throw FssParseException('Unit not supported: $unit');
    }
    return result;
  }

  /// Get the value as degree
  double getDegree() {
    return getRadians() * 180 / pi;
  }

  factory FssAngle.parse(String def) {
    final m = RegExp(r'([+-]?[0-9\.]+)([a-z]*)').matchAsPrefix(def.trim());
    if (m != null) {
      return FssAngle(double.parse(m.group(1)!), m.group(2));
    }
    throw FssParseException('Invalid angle value: $def');
  }

  @override
  String toString() {
    return 'FssAngle: $value${unit ?? ''}';
  }
}

/// Stores some base line values for size conversion
@immutable
class FssBase {
  static const fallback =
      FssBase(remBase: FssSize.baseFontSize, emBase: FssSize.baseFontSize);

  final double rem;
  final double em;

  const FssBase({double? remBase, double? emBase})
      : rem = remBase ?? FssSize.baseFontSize,
        em = emBase ?? FssSize.baseFontSize;
}

/// Widget builder callback that gives you access to the "applicable properties".
typedef FssWidgetBuilder = Widget Function(
  BuildContext context,
  FssRuleBlock applicableRule,
);

/// An exception thrown if the parsing of the stylesheet or rules fails.
class FssParseException implements Exception {
  final String message;
  const FssParseException(this.message);

  const FssParseException.forValue(FssPropertyValue value)
      : message = 'Unsupported value $value';

  @override
  String toString() {
    return 'FssException -> $message';
  }
}

/// Parses a style sheet file into a list of rules.
///
/// Normally you would not use this method directly but access the rules
/// via a [FlutterStyleSheet] which will manage the rule resolving for you.
List<FssRule> parseStylesheet(String? input) {
  // Nothing to parse
  if (input == null || input.trim().isEmpty) {
    return [];
  }

  final List<FssRule> result = [];
  FssRuleBlock? currentBlock;
  List<String> selectorPathList = [];
  List<String> mediaRulesList = [];
  List<FssRule> collectList = result;
  bool inBlockComment = false;

  final lines = input.split(RegExp(r'[\r\n]+'));
  int lineNo = -1;
  for (var line in lines) {
    lineNo++;
    if (line.contains('/*')) {
      inBlockComment = !line.contains('*/');
      line = line.substring(0, line.indexOf('/*'));
    }
    if (inBlockComment && line.contains('*/')) {
      line = line.substring(line.indexOf('*/') + 2);
      inBlockComment = false;
    }
    line = line.trim();

    // Skip empty lines and // commented lines
    if (line.isEmpty || line.startsWith('//') || inBlockComment) continue;

    // The first line that we find defines the path of the style
    // Can have a bracket on the end of the line or not.
    // Example field.myfield highlight {
    if (currentBlock == null) {
      // media query blocks
      if (line.toLowerCase().startsWith('@media')) {
        final mediaQuery = line.indexOf('{') > 0
            ? line.substring(0, line.indexOf('{')).trim()
            : line;
        mediaRulesList = mediaQuery.split(',');
        collectList = [];
        continue;
      }
      if (line == '{') continue;
      if (line == '}') {
        final List<FssRule> subRules = [];
        collectList.forEach(subRules.add);
        for (final mq in mediaRulesList) {
          result.add(_FssMediaRule(mq, subRules));
        }
        collectList = result;
      }
      // media query end

      // Start of a rule
      final selectorPath = line.indexOf('{') > 0
          ? line.substring(0, line.indexOf('{')).trim()
          : line;
      selectorPathList = selectorPath.split(',');
      currentBlock = FssRuleBlock(const {});
    } // So we are inside of a style definition.
    else {
      // Bracket on next line and not at the end of a style path
      if (line == '{') continue;
      // End Bracket so close style
      if (line == '}') {
        for (final path in selectorPathList) {
          final FssSelector selector = FssSelector.parse(path);
          collectList.add(FssRule(selector, currentBlock));
        }
        currentBlock = null;
        continue;
      }
      final nameValue = line.split(':');
      final name = nameValue[0].trim();
      var valueDef = nameValue[1].trim();
      // Cut the ending ;
      valueDef = valueDef.endsWith(';')
          ? valueDef.substring(0, valueDef.length - 1)
          : valueDef;

      _parseFssRule(currentBlock, name, valueDef, lineNo);
    }
  }
  return result;
}

void _parseFssRule(
  FssRuleBlock currentRule,
  String propName,
  String? valueDef,
  int lineNo,
) {
  // No value then do nothing.
  if (valueDef == null) {
    return;
  }
  var name = propName;
  name = name.toLowerCase().trim();
  var value = valueDef.toLowerCase().trim();

  // split "shortcut properties" into individual properties
  if (name == FssProperty.font.name) {
    return _parseFont(valueDef, currentRule, lineNo);
  }
  if (name == FssProperty.font_family.name) {
    // Here we keep the case and do not convert to lowercase.
    value = valueDef.trim();
  }
  if (name == FssProperty.padding.name) {
    return _parseBoxValues(
      [
        FssProperty.padding_top.name,
        FssProperty.padding_right.name,
        FssProperty.padding_bottom.name,
        FssProperty.padding_left.name
      ],
      value,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.margin.name) {
    return _parseBoxValues(
      [
        FssProperty.margin_top.name,
        FssProperty.margin_right.name,
        FssProperty.margin_bottom.name,
        FssProperty.margin_left.name
      ],
      value,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.border.name) {
    return _splitShortHand(
      [
        FssProperty.border_width.name,
        FssProperty.border_style.name,
        FssProperty.border_color.name
      ],
      valueDef,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.border_top.name) {
    return _splitShortHand(
      [
        FssProperty.border_top_width.name,
        FssProperty.border_top_style.name,
        FssProperty.border_top_color.name
      ],
      valueDef,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.border_bottom.name) {
    return _splitShortHand(
      [
        FssProperty.border_bottom_width.name,
        FssProperty.border_bottom_style.name,
        FssProperty.border_bottom_color.name
      ],
      valueDef,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.border_left.name) {
    return _splitShortHand(
      [
        FssProperty.border_left_width.name,
        FssProperty.border_left_style.name,
        FssProperty.border_left_color.name
      ],
      valueDef,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.border_right.name) {
    return _splitShortHand(
      [
        FssProperty.border_right_width.name,
        FssProperty.border_right_style.name,
        FssProperty.border_right_color.name
      ],
      valueDef,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.border_width.name) {
    return _parseBoxValues(
      [
        FssProperty.border_top_width.name,
        FssProperty.border_right_width.name,
        FssProperty.border_bottom_width.name,
        FssProperty.border_left_width.name,
      ],
      value,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.border_color.name) {
    _parseBoxValues(
      [
        FssProperty.border_top_color.name,
        FssProperty.border_right_color.name,
        FssProperty.border_bottom_color.name,
        FssProperty.border_left_color.name,
      ],
      value,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.border_style.name) {
    return _parseBoxValues(
      [
        FssProperty.border_top_style.name,
        FssProperty.border_right_style.name,
        FssProperty.border_bottom_style.name,
        FssProperty.border_left_style.name,
      ],
      value,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.border_radius.name) {
    return _parseBoxValues(
      [
        FssProperty.border_top_left_radius.name,
        FssProperty.border_top_right_radius.name,
        FssProperty.border_bottom_right_radius.name,
        FssProperty.border_bottom_left_radius.name,
      ],
      value,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.text_stroke.name) {
    return _splitShortHand(
      [
        FssProperty.text_stroke_width.name,
        FssProperty.text_stroke_color.name,
      ],
      valueDef,
      currentRule,
      lineNo,
    );
  }
  if (name == FssProperty.text_decoration.name) {
    return _splitShortHand(
      [
        FssProperty.text_decoration_line.name,
        FssProperty.text_decoration_style.name,
        FssProperty.text_decoration_color.name,
      ],
      valueDef,
      currentRule,
      lineNo,
    );
  }

  // Check if property is supported. If yes add it to the map
  final isStandardProperty = FssProperty.all.any((p) => p.name == name);
  if (isStandardProperty ||
      name.startsWith(FssProperty.fssPropertyPrefix) ||
      name.startsWith(FssProperty.varPrefix)) {
    currentRule._properties[name] = FssPropertyValue(name, value, lineNo);
  } else {
    throw FssParseException(
      'Unsupported property name: "$name" (line $lineNo)',
    );
  }
}

/// Parses a size definition
FssSize _parseSizeDef(FssPropertyValue valueDef) {
  return FssSize.parse(valueDef.value);
}

double _parsePercent(FssPropertyValue valueDef) {
  final def = _parseSizeDef(valueDef);
  var result = 0.0;
  if (def.unit == '%') {
    result = def.value / 100.0;
  } else {
    result = def.value;
  }
  return result;
}

void _splitShortHand(
  List<String> properties,
  String valueDef,
  FssRuleBlock currentRule,
  int lineNo,
) {
  final values = _splitValues(currentRule, valueDef);
  for (int i = 0; i < values.length; i++) {
    if (i < properties.length) {
      _parseFssRule(currentRule, properties[i], values[i], lineNo);
    } else {
      break;
    }
  }
}

/// Parse the 4 values for: top, right, bottom, left
void _parseBoxValues(
  List<String> properties,
  String valueDef,
  FssRuleBlock currentRule,
  int lineNo,
) {
  final sideValues = _splitValues(currentRule, valueDef);

  if (sideValues.length == 1) {
    _parseFssRule(currentRule, properties[0], sideValues[0], lineNo);
    _parseFssRule(currentRule, properties[1], sideValues[0], lineNo);
    _parseFssRule(currentRule, properties[2], sideValues[0], lineNo);
    _parseFssRule(currentRule, properties[3], sideValues[0], lineNo);
  }
  if (sideValues.length == 2) {
    _parseFssRule(currentRule, properties[0], sideValues[0], lineNo);
    _parseFssRule(currentRule, properties[1], sideValues[1], lineNo);
    _parseFssRule(currentRule, properties[2], sideValues[0], lineNo);
    _parseFssRule(currentRule, properties[3], sideValues[1], lineNo);
  }
  if (sideValues.length == 3) {
    _parseFssRule(currentRule, properties[0], sideValues[0], lineNo);
    _parseFssRule(currentRule, properties[1], sideValues[1], lineNo);
    _parseFssRule(currentRule, properties[2], sideValues[2], lineNo);
    _parseFssRule(currentRule, properties[3], sideValues[1], lineNo);
  }
  if (sideValues.length >= 4) {
    _parseFssRule(currentRule, properties[0], sideValues[0], lineNo);
    _parseFssRule(currentRule, properties[1], sideValues[1], lineNo);
    _parseFssRule(currentRule, properties[2], sideValues[2], lineNo);
    _parseFssRule(currentRule, properties[3], sideValues[3], lineNo);
  }
}

void _parseFont(String valueDef, FssRuleBlock currentRule, int lineNo) {
  // we get the case insensitive string here because of the font family
  // that might use upper case.

  // TODO improve parsing of optional values
  // font: font-style font-variant font-weight font-size/line-height font-family|caption|icon|menu|message-box|small-caption|status-bar|initial|inherit;
  final values = _splitValues(currentRule, valueDef);
  // TODO _resolve the parts
  if (values.length == 1) {
    _parseFssRule(currentRule, FssProperty.font_family.name, values[0], lineNo);
  } else if (values.length == 2) {
    _parseFssRule(
      currentRule,
      FssProperty.font_size.name,
      values[0].toLowerCase(),
      lineNo,
    );
    _parseFssRule(currentRule, FssProperty.font_family.name, values[1], lineNo);
  } else if (values.length == 3) {
    _parseFssRule(
      currentRule,
      FssProperty.font_weight.name,
      values[0].toLowerCase(),
      lineNo,
    );
    _parseFssRule(
      currentRule,
      FssProperty.font_size.name,
      values[1].toLowerCase(),
      lineNo,
    );
    _parseFssRule(currentRule, FssProperty.font_family.name, values[2], lineNo);
  } else if (values.length >= 4) {
    _parseFssRule(
      currentRule,
      FssProperty.font_style.name,
      values[0].toLowerCase(),
      lineNo,
    );
    _parseFssRule(
      currentRule,
      FssProperty.font_weight.name,
      values[1].toLowerCase(),
      lineNo,
    );
    _parseFssRule(
      currentRule,
      FssProperty.font_size.name,
      values[2].toLowerCase(),
      lineNo,
    );
    _parseFssRule(currentRule, FssProperty.font_family.name, values[3], lineNo);
  }
}

/// Splits function parameter by , supporting functions in functions.
List<String> _splitFunctionParams(
  FssRuleBlock currentRule,
  String value, [
  String separator = ',',
]) {
  // remove all function bodies as they may contain ,
  final temp = value.replaceAllMapped(
    RegExp(r'\(.*?\)'),
    (m) => ''.padRight(m.end - m.start, '_'),
  );

  // Now search for , and then split the original value on these positions.
  final separatorMatcher = RegExp(separator).allMatches(temp);
  final List<String> result = [];
  int start = 0;
  for (final match in separatorMatcher) {
    result.add(
      currentRule._resolveValue(value.substring(start, match.start).trim())!,
    );
    start = match.end;
  }
  result.add(currentRule._resolveValue(value.substring(start).trim())!);
  return result;
}

/// Splits a string with multiple values into a list
List<String> _splitValues(FssRuleBlock currentRule, String value) =>
    _splitFunctionParams(currentRule, value.trim(), r'\s+');

/// Darken a color by [percent] amount (100 = black)
Color _darkenColor(Color c, [int percent = 10]) {
  assert(1 <= percent && percent <= 100);
  final f = 1 - percent / 100;
  return Color.fromARGB(
    c.alpha,
    (c.red * f).round(),
    (c.green * f).round(),
    (c.blue * f).round(),
  );
}

/// Lighten a color by [percent] amount (100 = white)
/*
Color _lightenColor(Color c, [int percent = 10]) {
  assert(1 <= percent && percent <= 100);
  final p = percent / 100;
  return Color.fromARGB(
    c.alpha,
    c.red + ((255 - c.red) * p).round(),
    c.green + ((255 - c.green) * p).round(),
    c.blue + ((255 - c.blue) * p).round(),
  );
}
*/
