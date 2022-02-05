library material_bridge;

import 'package:flutter/material.dart';

import 'fss_parser.dart';

/// Parses Material Theme and translates it into some default styles and rules.
///
/// Additionally this will set many material design related variables e.g.:
/// --mat-color-primary, --mat-color-background ... which you can use then in
/// your own rules via the var() function.
///
class MaterialThemeBridge {
  /// Private constructor
  MaterialThemeBridge._();

  /// Parses Material Theme and translates it into some default styles and variables.
  ///
  /// This will mainly set the default colors and fonts.
  /// Additionally we set many material design related variables e.g.:
  /// --mat-color-primary, --mat-color-background ... which you can use then in
  /// your own rules via the var() function.
  ///
  /// Used to initialize the defaults for [FlutterStyleSheet]
  ///
  static Map<String, FssPropertyValue> extractStylesAndVars(
    BuildContext context,
  ) {
    final Map<String, FssPropertyValue> styles = {};

    final themeData = Theme.of(context);

    // Add material theme legacy colors
    _addVar(
      styles,
      FssProperty.background_color.name,
      FssColor.colorToHex(themeData.backgroundColor),
    );
    _addVar(
      styles,
      'bottom-appbar-color',
      FssColor.colorToHex(themeData.bottomAppBarColor),
    );
    _addVar(styles, 'canvas-color', FssColor.colorToHex(themeData.canvasColor));
    _addVar(styles, 'card-color', FssColor.colorToHex(themeData.cardColor));
    _addVar(
      styles,
      'dialog-background-color',
      FssColor.colorToHex(themeData.dialogBackgroundColor),
    );
    _addVar(
      styles,
      'disabled-color',
      FssColor.colorToHex(themeData.disabledColor),
    );
    _addVar(
      styles,
      'divider-color',
      FssColor.colorToHex(themeData.dividerColor),
    );
    _addVar(
      styles,
      'error-color',
      FssColor.colorToHex(themeData.errorColor),
    );
    _addVar(styles, 'focus-color', FssColor.colorToHex(themeData.focusColor));
    _addVar(
      styles,
      'highlight-color',
      FssColor.colorToHex(themeData.highlightColor),
    );
    _addVar(styles, 'hint-color', FssColor.colorToHex(themeData.hintColor));
    _addVar(styles, 'hover-color', FssColor.colorToHex(themeData.hoverColor));
    _addVar(
      styles,
      'indicator-color',
      FssColor.colorToHex(themeData.indicatorColor),
    );
    _addVar(
      styles,
      'primary-color',
      FssColor.colorToHex(themeData.primaryColor),
    );
    _addVar(
      styles,
      'primary-color-dark',
      FssColor.colorToHex(themeData.primaryColorDark),
    );
    _addVar(
      styles,
      'primary-color-light',
      FssColor.colorToHex(themeData.primaryColorLight),
    );
    _addVar(
      styles,
      'primary-color-brightness',
      '${themeData.primaryColorBrightness}',
    );
    _addVar(
      styles,
      'scaffold-background-color',
      FssColor.colorToHex(themeData.scaffoldBackgroundColor),
    );
    _addVar(
      styles,
      'secondary-header-color',
      FssColor.colorToHex(themeData.secondaryHeaderColor),
    );
    _addVar(
      styles,
      'selected-row-color',
      FssColor.colorToHex(themeData.selectedRowColor),
    );
    _addVar(styles, 'shadow-color', FssColor.colorToHex(themeData.shadowColor));
    _addVar(styles, 'splash-color', FssColor.colorToHex(themeData.splashColor));
    _addVar(
      styles,
      'toggleable-active-color',
      FssColor.colorToHex(themeData.toggleableActiveColor),
    );
    _addVar(
      styles,
      'unselected-widget-color',
      FssColor.colorToHex(themeData.unselectedWidgetColor),
    );

    // From color scheme.
    _addVar(styles, 'color-brightness', '${themeData.colorScheme.brightness}');
    _addVar(
      styles,
      'color-background',
      FssColor.colorToHex(themeData.colorScheme.background),
    );
    _addVar(
      styles,
      'color-error',
      FssColor.colorToHex(themeData.colorScheme.error),
    );
    _addVar(
      styles,
      'color-onbackground',
      FssColor.colorToHex(themeData.colorScheme.onBackground),
    );
    _addVar(
      styles,
      'color-onerror',
      FssColor.colorToHex(themeData.colorScheme.onError),
    );
    _addVar(
      styles,
      'color-onprimary',
      FssColor.colorToHex(themeData.colorScheme.onPrimary),
    );
    _addVar(
      styles,
      'color-onsecondary',
      FssColor.colorToHex(themeData.colorScheme.onSecondary),
    );
    _addVar(
      styles,
      'color-onsurface',
      FssColor.colorToHex(themeData.colorScheme.onSurface),
    );
    _addVar(
      styles,
      'color-primary',
      FssColor.colorToHex(themeData.colorScheme.primary),
    );
    _addVar(
      styles,
      'color-primaryvariant',
      FssColor.colorToHex(themeData.colorScheme.primaryVariant),
    );
    _addVar(
      styles,
      'color-secondary',
      FssColor.colorToHex(themeData.colorScheme.secondary),
    );
    _addVar(
      styles,
      'color-secondaryvariant',
      FssColor.colorToHex(themeData.colorScheme.secondaryVariant),
    );
    _addVar(
      styles,
      'color-surface',
      FssColor.colorToHex(themeData.colorScheme.surface),
    );

    // Add misc
    _addVar(styles, 'brightness', '${themeData.brightness}');
    _addVar(
      styles,
      'visual-density-horizontal',
      '${themeData.visualDensity.horizontal}',
    );
    _addVar(
      styles,
      'visual-density-vertical',
      '${themeData.visualDensity.vertical}',
    );

    // Set some standard properties too
    _addStyle(
      styles,
      FssProperty.background_color.name,
      FssColor.colorToHex(themeData.colorScheme.background),
    );
    _addStyle(
      styles,
      FssProperty.color.name,
      FssColor.colorToHex(themeData.colorScheme.onBackground),
    );
    _translateTextTheme(styles, themeData.textTheme.bodyText1);

    return styles;
  }

  /// Generates some default rules for common used "element types" and "classes".
  ///
  /// Like for example: H1 - H6, DIV, P ...

  static List<FssRule> extractDefaultRules(BuildContext context) {
    final themeData = Theme.of(context);

    final List<FssRule> rules = [];

    _addTextRule(FssType.h1.name, themeData.textTheme.headline1, rules);
    _addTextRule(FssType.h2.name, themeData.textTheme.headline2, rules);
    _addTextRule(FssType.h3.name, themeData.textTheme.headline3, rules);
    _addTextRule(FssType.h4.name, themeData.textTheme.headline4, rules);
    _addTextRule(FssType.h5.name, themeData.textTheme.headline5, rules);
    _addTextRule(FssType.h6.name, themeData.textTheme.headline6, rules);

    _addTextRule(FssType.body.name, themeData.textTheme.bodyText1, rules);
    _addTextRule(FssType.p.name, themeData.textTheme.bodyText1, rules);
    _addTextRule(FssType.div.name, themeData.textTheme.bodyText1, rules);

    // Add some more non standard elements
    _addTextRule(FssType.body2.name, themeData.textTheme.bodyText2, rules);
    _addTextRule(FssType.overline.name, themeData.textTheme.overline, rules);
    _addTextRule(FssType.caption.name, themeData.textTheme.caption, rules);
    _addTextRule(FssType.button.name, themeData.textTheme.button, rules);
    _addTextRule(FssType.subtitle1.name, themeData.textTheme.subtitle1, rules);
    _addTextRule(FssType.subtitle2.name, themeData.textTheme.subtitle2, rules);

    // HR styling
    final dividerTheme = DividerTheme.of(context);
    final Map<String, FssPropertyValue> hrStyles = {};
    _addStyle(hrStyles, FssProperty.margin_top.name, '6');
    _addStyle(hrStyles, FssProperty.margin_bottom.name, '6');
    _addStyle(hrStyles, FssProperty.border_top_style.name, 'solid');
    _addStyle(
      hrStyles,
      FssProperty.border_top_width.name,
      '${dividerTheme.thickness ?? 0}',
    );
    final effectiveColor =
        DividerTheme.of(context).color ?? Theme.of(context).dividerColor;
    _addStyle(
      hrStyles,
      FssProperty.border_top_color.name,
      '${FssColor.colorToHex(effectiveColor)}',
    );
    _addStyle(hrStyles, FssProperty.background_color.name, 'transparent');
    rules.add(
      FssRule(FssSelector(type: FssType.hr.name), FssRuleBlock(hrStyles)),
    );

    return rules;
  }
}

/// Adds a text theme rule for a given element type.
void _addTextRule(String typeName, TextStyle? textTheme, List<FssRule> rules) {
  if (textTheme != null) {
    rules.add(
      FssRule(
        FssSelector(type: typeName),
        FssRuleBlock(_translateTextTheme({}, textTheme)),
      ),
    );
  }
}

/// Translates an Material text theme into css values.
Map<String, FssPropertyValue> _translateTextTheme(
  Map<String, FssPropertyValue> styles,
  TextStyle? textTheme,
) {
  if (textTheme == null) {
    return styles;
  }
  // Colors
  _addStyle(
    styles,
    FssProperty.color.name,
    FssColor.colorToHex(textTheme.color),
  );

  // Font
  _addStyle(
    styles,
    FssProperty.font_family.name,
    textTheme.fontFamily?.toString(),
  );
  _addStyle(
    styles,
    FssProperty.font_style.name,
    textTheme.fontStyle?.toString(),
  );
  _addStyle(styles, FssProperty.font_size.name, textTheme.fontSize?.toString());
  _addStyle(
    styles,
    FssProperty.font_weight.name,
    _translateFontWeight(textTheme.fontWeight)?.toString(),
  );
  _addStyle(
    styles,
    FssProperty.word_spacing.name,
    textTheme.wordSpacing?.toString(),
  );
  _addStyle(
    styles,
    FssProperty.letter_spacing.name,
    textTheme.letterSpacing?.toString(),
  );

  // Decoration
  _addStyle(
    styles,
    FssProperty.text_decoration_style.name,
    textTheme.decorationStyle?.toString(),
  );
  _addStyle(
    styles,
    FssProperty.text_decoration_thickness.name,
    textTheme.decorationThickness?.toString(),
  );
  _addStyle(
    styles,
    FssProperty.text_decoration_color.name,
    textTheme.decorationColor?.toString(),
  );
  _addStyle(
    styles,
    FssProperty.text_decoration_line.name,
    _translateTextDecLine(textTheme.decoration),
  );
  return styles;
}

/// Translates Material TextDecoration into CSS value
String? _translateTextDecLine(TextDecoration? value) {
  if (value == null) {
    return null;
  }
  if (TextDecoration.none == value) {
    return 'none';
  } else if (TextDecoration.underline == value) {
    return 'underline';
  } else if (TextDecoration.lineThrough == value) {
    return 'line-through';
  } else if (TextDecoration.overline == value) {
    return 'overline';
  }
  return null;
}

/// Translates Material font weight into CSS font weight values
String? _translateFontWeight(FontWeight? fontWeight) {
  if (fontWeight == null) {
    return null;
  }
  switch (fontWeight.index + 1) {
    case 4:
      return 'normal';
    case 7:
      return 'bold';
    case 8:
      return 'bolder';
    case 3:
      return 'lighter';
    default:
      return '${(fontWeight.index + 1) * 100}';
  }
}

/// Adds a custom property for the material design starting with --mat-
void _addVar(
  Map<String, FssPropertyValue> styles,
  String name,
  String? varValue,
) {
  _addStyle(styles, '${FssProperty.varPrefix}mat-$name', varValue ?? '');
}

/// Adds a style to the given style map
void _addStyle(
  Map<String, FssPropertyValue> styles,
  String name,
  String? varValue,
) {
  if (varValue != null) {
    styles[name] = FssPropertyValue(name, varValue);
  }
}
