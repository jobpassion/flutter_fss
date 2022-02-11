/// This library will provide some base classes for the Flutter Style Sheet
/// It offers all the building blocks to model the theme and its rules and
/// to wrap or create Fss styled widgets.
///
/// Some entry points are [FssTheme] to install a fss style sheet based theme
/// into your widget tree. Then you can use the [Fss] which offers factory methods
/// to create styleable widgets.
///
/// To create your own styleable widgets either wrap them into [FssBox] or extend
/// [FssWidget].
///

library fss_widgets;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fss/src/material_bridge.dart';

import 'fss_parser.dart';

/// This is mainly a factory to create widgets which can be then styled from
/// a style sheet file.
/// If offers methods to create common elements which are imitating popular
/// elements of HTML like for example: div, p, h1 - h6, img ...
///
/// To wrap your own widgets into a styleable "box" use the [Fss.box] method or
/// [Fss.styled(builder: builder)] method.
class Fss {
  /// Private constructor
  Fss._();

  /// Allows you to build you own widget with Fss styles applied.
  /// This allows you to specify for your widget an type, id and a list of classes.
  /// The builder will then be invoked and will give you access to the resolved
  /// style properties that you can use then to configure your widget.
  static Widget styled({
    Key? key,
    String? fssID,
    String? fssType,
    String? fssClass,
    required FssWidgetBuilder builder,
  }) {
    return _FssBuilder(
      key: key,
      builder: builder,
      fssType: fssType,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget with a TextTheme applied from the style sheet.
  static FssText text(
    String data, {
    Key? key,
    String? fssType,
    String? fssID,
    String? fssClass,
  }) {
    return FssText(
      data,
      key: key,
      fssType: fssType,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a container widget similar to the HTML div element but you can
  /// specify an own "type".
  static FssBox box({
    Key? key,
    String? fssID,
    String? fssType,
    String? fssClass,
    Widget? child,
    FssWidgetBuilder? builder,
  }) {
    return FssBox(
      key: key,
      builder: builder,
      fssType: fssType,
      fssID: fssID,
      fssClass: fssClass,
      child: child,
    );
  }

  /// Builds a list widget similar to the HTML ul element.
  static Widget ul({
    Key? key,
    String? fssID,
    String? fssClass,
    required List<Widget> children,
  }) {
    return FssList(
      key: key,
      fssType: FssType.ul.name,
      fssID: fssID,
      fssClass: fssClass,
      children: children,
    );
  }

  /// Builds a list widget similar to the HTML ol element.
  static Widget ol({
    Key? key,
    String? fssID,
    String? fssClass,
    required List<Widget> children,
  }) {
    return FssList(
      key: key,
      fssType: FssType.ol.name,
      fssID: fssID,
      fssClass: fssClass,
      children: children,
    );
  }

  /// Builds a list widget similar to the HTML li element.
  static Widget li({
    Key? key,
    String? fssID,
    String? fssType,
    String? fssClass,
    required Widget child,
  }) {
    return FssListItem(
      key: key,
      fssType: FssType.li.name,
      fssID: fssID,
      fssClass: fssClass,
      child: child,
    );
  }

  /// Builds a container widget similar to the HTML div element.
  static FssBox div({
    Key? key,
    String? fssID,
    String? fssClass,
    Widget? child,
    FssWidgetBuilder? builder,
  }) {
    return box(
      key: key,
      child: child,
      builder: builder,
      fssType: FssType.div.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a container widget similar to the HTML img element.
  static FssBox img({
    Key? key,
    String? fssID,
    String? fssClass,
    required ImageProvider src,
  }) {
    return FssBox.withImage(
      key: key,
      imageOverride: DecorationImage(image: src, fit: BoxFit.fill),
      fssType: FssType.img.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a container widget similar to the HTML hr element.
  /// You can style the "border" property in the fss file to change its look.
  static FssBox hr({Key? key, String? fssID, String? fssClass}) {
    return box(
      key: key,
      fssType: FssType.hr.name,
      fssID: fssID,
      fssClass: fssClass,
      child: const SizedBox.shrink(),
    );
  }

  /// Builds a container widget similar to the HTML p element.
  static FssBox p({
    Key? key,
    String? fssID,
    String? fssClass,
    Widget? child,
    FssWidgetBuilder? builder,
  }) {
    return box(
      key: key,
      child: child,
      builder: builder,
      fssType: FssType.p.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget similar to the HTML h1 element.
  static FssText h1(String data, {Key? key, String? fssID, String? fssClass}) {
    return FssText(
      data,
      key: key,
      fssType: FssType.h1.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget similar to the HTML h2 element.
  static FssText h2(String data, {Key? key, String? fssID, String? fssClass}) {
    return FssText(
      data,
      key: key,
      fssType: FssType.h2.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget similar to the HTML h3 element.
  static FssText h3(String data, {Key? key, String? fssID, String? fssClass}) {
    return FssText(
      data,
      key: key,
      fssType: FssType.h3.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget similar to the HTML h4 element.
  static FssText h4(String data, {Key? key, String? fssID, String? fssClass}) {
    return FssText(
      data,
      key: key,
      fssType: FssType.h4.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget similar to the HTML h5 element.
  static FssText h5(String data, {Key? key, String? fssID, String? fssClass}) {
    return FssText(
      data,
      key: key,
      fssType: FssType.h5.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget similar to the HTML h6 element.
  static FssText h6(String data, {Key? key, String? fssID, String? fssClass}) {
    return FssText(
      data,
      key: key,
      fssType: FssType.h6.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget for a body text.
  static FssText body(
    String data, {
    Key? key,
    String? fssID,
    String? fssClass,
  }) {
    return FssText(
      data,
      key: key,
      fssType: FssType.body.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget for an alternative body text.
  static FssText body2(
    String data, {
    Key? key,
    String? fssID,
    String? fssClass,
  }) {
    return FssText(
      data,
      key: key,
      fssType: FssType.body2.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget for an caption.
  static FssText caption(
    String data, {
    Key? key,
    String? fssID,
    String? fssClass,
  }) {
    return FssText(
      data,
      key: key,
      fssType: FssType.caption.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget for an sub title.
  static FssText subtitle1(
    String data, {
    Key? key,
    String? fssID,
    String? fssClass,
  }) {
    return FssText(
      data,
      key: key,
      fssType: FssType.subtitle1.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }

  /// Builds a text widget for an alternative sub title.
  static FssText subtitle2(
    String data, {
    Key? key,
    String? fssID,
    String? fssClass,
  }) {
    return FssText(
      data,
      key: key,
      fssType: FssType.subtitle2.name,
      fssID: fssID,
      fssClass: fssClass,
    );
  }
}

/// A widget to install a css like stylesheet into the widget tree as a theme.
/// All fss widgets will then access this stylesheet to resolve rules and
/// to apply the styles to them. To create fss styling aware widgets
/// use the [Fss] factory class.
///
/// You can retrieve the current theme from the BuildContext via [FssTheme.of]
///
/// Via the [resolveStyles] method you can programmatically resolve all rules
/// for a given element type, ID and list of classes but normally an FssWidget
/// will resolve for you automatically the rules into a set of styles and you
/// do not need to invoke this manually.
///
class FssTheme extends InheritedWidget {
  final FlutterStyleSheet stylesheet;

  /// Parses the rules from the given String
  /// If you specify both the stylesheet and rules then we parse first
  /// the stylesheet and add the rules afterwards
  FssTheme({
    Key? key,
    String? stylesheet = '',
    List<FssRule>? rules,
    required Widget child,
    FssRuleBlock? systemDefaults,
  })  : stylesheet = FlutterStyleSheet(
          stylesheet: stylesheet,
          rules: rules,
          systemDefaults: systemDefaults,
        ),
        super(key: key, child: child);

  // Creates a theme with some system defaults derived from the Material Theme
  // Additionally this will add variables and some default rules.
  factory FssTheme.withAppDefaults({
    Key? key,
    required BuildContext context,
    FssRuleBlock? defaultOverrides,
    required String stylesheet,
    required Widget child,
  }) {
    // start with initial values
    FssRuleBlock defaults = FssProperty.getDefaults();

    // extract variables and default values from material design
    final FssRuleBlock materialDefaults = getSystemDefaults(context);
    defaults = defaults.merge(materialDefaults);

    // than merge the given system defaults on top
    if (defaultOverrides != null) {
      defaults = defaults.merge(defaultOverrides);
    }

    // Build some standard rules matching the material design
    final defaultRules = getSystemDefaultRules(context);

    return FssTheme(
      key: key,
      stylesheet: stylesheet,
      rules: defaultRules,
      systemDefaults: defaults,
      child: child,
    );
  }

  /// Builds a special FssRule that can be used as defaults for an FssTheme.
  /// It will set some initial styles and add many of the Material theme values
  /// as variables.
  static FssRuleBlock getSystemDefaults(BuildContext context) {
    return FssRuleBlock(MaterialThemeBridge.extractStylesAndVars(context));
  }

  /// Creates some default rules matching the current Material Theme.
  static List<FssRule> getSystemDefaultRules(BuildContext context) {
    return MaterialThemeBridge.extractDefaultRules(context);
  }

  /// Find the currently applicable FssTheme in the widget tree.
  static FssTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FssTheme>();
  }

  /// Create a copy of the current theme with additional rules.
  FssTheme copyWith({
    Key? key,
    String? stylesheet = '',
    List<FssRule>? rules,
    required Widget child,
    FssRuleBlock? systemDefaults,
  }) {
    // original rules then add on top
    final newRuleSet = [
      ...this.stylesheet.rules,
      ...?rules,
      ...parseStylesheet(stylesheet),
    ];

    // Original defaults then the given defaults on top.
    final newDefaults = this.stylesheet.systemDefaults.merge(systemDefaults);

    return FssTheme(
      key: key,
      systemDefaults: newDefaults,
      rules: newRuleSet,
      child: child,
    );
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;

  /// Resolves and merges all the rules that match the given classes list, type
  /// and FSS ID. All matching rules will be processed and merged into a final
  /// combined rule block.
  /// If your stylesheet contains media query rules you
  /// need to provide MediaQueryData otherwise these rules will not be resolved.
  /// If you do not provide parentStyles then no property inheritance will take
  /// place and if a property is not found in the matching rules it will fallback
  /// to the default value for that property.
  FssRuleBlock resolveStyles({
    String matchType = '',
    String matchId = '',
    String matchClasses = '',
    FssRuleBlock? parentStyles,
    MediaQueryData? media,
  }) {
    return stylesheet.resolveStyles(
      matchType: matchType,
      matchId: matchId,
      matchClasses: matchClasses,
      parentStyles: parentStyles,
      media: media,
    );
  }

  /// When invoked with diagnostic level "fine" it will generate the
  /// style sheet debug info too.
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    var result = super.toString(minLevel: minLevel);
    if (minLevel == DiagnosticLevel.fine) {
      result += '\n${stylesheet.getDebugThemeInfo()}';
    }
    return result;
  }
}

/// This widget is a invisible node that is injected into the widget tree to support
/// style inheritance.
///
class FssParent extends InheritedWidget {
  final FssRuleBlock? applicableStyles;

  const FssParent({
    Key? key,
    required Widget child,
    required this.applicableStyles,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }

  static FssRuleBlock? of(BuildContext context) {
    final c = context.dependOnInheritedWidgetOfExactType<FssParent>();
    return c?.applicableStyles;
  }
}

/// Abstract widget that resolves the applicable [FssRuleBlock] for you and
/// allows you to configure any widget with it. When you inherit from
/// this class you need to implement the [buildContent] method.
///
abstract class FssWidget extends StatelessWidget {
  /// A child widget.
  ///
  /// The child widget encapsulated in this styleable widget.
  final Widget? child;

  /// FSS class names used to resolve the styles for this container.
  ///
  /// See [FssTheme.resolveStyles] for details how styles are resolved.
  final String? fssClass;

  /// An style ID that can be used to resolve rules from the style sheet.
  final String? fssID;

  /// This specifies the type of the widget that can be used to resolve rules
  /// from the style sheet.
  final String? fssType;

  const FssWidget({
    Key? key,
    this.child,
    this.fssType,
    this.fssID,
    this.fssClass,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final applicableStyles = resolveApplicableStyles(
      context: context,
      fssClass: fssClass,
      fssId: getIDForResolve(),
      fssType: fssType,
    );

    final content = !applicableStyles.visible
        ? const SizedBox.shrink()
        : buildContent(context, applicableStyles);

    return FssParent(
      applicableStyles: applicableStyles,
      child: Builder(builder: (c) => content),
    );
  }

  /// Gets the ID that is used to resolve rules.
  /// This is either set fssID otherwise we try to build it from the widget [Key]
  /// if that one is a instance of [ValueKey]
  String getIDForResolve() {
    if (fssID != null) {
      return fssID!;
    }
    // Try as fallback to convert the key to an "ID"
    if (key is ValueKey) {
      final value = (key! as ValueKey).value;
      return value?.toString() ?? '';
    }
    return '';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('fssID', fssID, defaultValue: null));
    properties.add(StringProperty('fssClass', fssClass, defaultValue: null));
    properties.add(StringProperty('fssType', fssType, defaultValue: null));
  }

  /// Overwrite this method to build the content for the widget
  Widget buildContent(BuildContext context, FssRuleBlock applicableStyles);
}

/// A container that will automatically apply some styles of the applicable [FssRuleBlock]
///
/// This will resolve the applicable rule from the [FssTheme] and then apply some
/// styles to the container like: padding, margin, border, background, box-shadow...
/// So everything which is applicable for a container directly.
class FssBox extends FssWidget {
  final DecorationImage? imageOverride;

  /// A builder to create the child widget.
  ///
  /// The builder will have access to the applicable FssRule containing all
  /// the styles. Use this if you want to configure your widget with styles.
  /// If a [child] is defined the builder is ignored.
  final FssWidgetBuilder? builder;

  const FssBox({
    Key? key,
    Widget? child,
    this.builder,
    String? fssType,
    String? fssID,
    String? fssClass,
  })  : imageOverride = null,
        super(
          key: key,
          child: child,
          fssType: fssType,
          fssID: fssID,
          fssClass: fssClass,
        );

  const FssBox.withImage({
    Key? key,
    required this.imageOverride,
    String? fssType,
    String? fssID,
    String? fssClass,
  })  : builder = null,
        super(
          key: key,
          fssType: fssType,
          fssID: fssID,
          fssClass: fssClass,
        );

  @override
  Widget buildContent(BuildContext context, FssRuleBlock applicableRule) {
    Widget? content = const SizedBox.shrink();
    if (applicableRule.contentVisible) {
      content = child ?? builder?.call(context, applicableRule);
    }

    return Container(
      padding: applicableRule.padding,
      margin: applicableRule.margin,
      width: applicableRule.width,
      height: applicableRule.height,
      transform: applicableRule.transformMatrix,
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        boxShadow: applicableRule.boxShadow == null
            ? null
            : [applicableRule.boxShadow!],
        color: applicableRule.backgroundColor,
        image: imageOverride ?? applicableRule.backgroundImage,
        gradient: applicableRule.backgroundGradient,
        border: applicableRule.border,
        borderRadius: applicableRule.borderRadius,
      ),
      alignment: applicableRule.alignment,
      constraints: applicableRule.constraints,
      child: content,
    );
  }
}

/// A container that will layout its children in a list (column)
///
/// This mimics to some degree the HTML ul and ol elements
/// Use it in combination with [FssListItem] elements as children.
/// Do not use this class directly. It is cleaner to use Fss.ul and Fss.ol
/// factory methods instead.
///
class FssList extends StatelessWidget {
  const FssList({
    Key? key,
    required this.children,
    this.fssType = 'ul',
    this.fssID,
    this.fssClass,
  }) : super(key: key);

  /// FSS class names used to resolve the styles for this container.
  ///
  /// See [FssTheme.resolveStyles] for details how styles are resolved.
  final String? fssClass;

  /// An style ID that can be used to resolve rules from the style sheet.
  final String? fssID;

  /// This specifies the type of the widget that can be used to resolve rules
  /// from the style sheet.
  final String? fssType;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Fss.box(
      fssID: fssID,
      fssType: fssType,
      fssClass: fssClass,
      builder: (cnx, al) {
        // Build and prepare list items
        int i = 1;
        final listItems = children.map((li) {
          // If already a list item repackage it.
          if (li is FssListItem) {
            return li._copyWithPos(
              key: ValueKey('$i'),
              listPos: i++,
              listLength: children.length,
            );
          }
          return FssListItem(
            key: ValueKey('$i'),
            listPos: i++,
            listLength: children.length,
            child: li,
          );
        }).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: listItems,
        );
      },
    );
  }
}

/// A list item wrapper
///
class FssListItem extends FssWidget {
  final int listPos;
  final int listLength;

  const FssListItem({
    Key? key,
    String? fssType,
    String? fssID,
    String? fssClass,
    this.listPos = 1,
    this.listLength = 1,
    required Widget? child,
  }) : super(
          key: key,
          child: child,
          fssType: fssType,
          fssID: fssID,
          fssClass: fssClass,
        );

  /// Copies this list item and applies a new position or list length
  FssListItem _copyWithPos({
    Key? key,
    required int listPos,
    required int listLength,
  }) {
    return FssListItem(
      key: key,
      fssType: fssType,
      fssID: fssID,
      fssClass: fssClass,
      listLength: listLength,
      listPos: listPos,
      child: child,
    );
  }

  @override
  Widget buildContent(BuildContext context, FssRuleBlock applicableRule) {
    if (!applicableRule.contentVisible) {
      return const SizedBox.shrink();
    }

    Widget symbolWidget;
    final img = applicableRule.getListStyleImage();
    if (img != null) {
      symbolWidget = Image(
        image: img,
        fit: BoxFit.scaleDown,
        height: applicableRule.convert('1em'),
      );
    } else {
      final symbol = applicableRule.getListStyleSymbol(listPos, listLength);
      // What a shame but the Noto font does not contain these as characters!
      // So we use here a hack with icons
      if (symbol == 'disc') {
        symbolWidget = Icon(
          Icons.fiber_manual_record,
          color: applicableRule.color,
          size: applicableRule.convert('0.5em'),
        );
      } else if (symbol == 'circle') {
        symbolWidget = Icon(
          Icons.fiber_manual_record_outlined,
          color: applicableRule.color,
          size: applicableRule.convert('0.5em'),
        );
      } else if (symbol == 'square') {
        symbolWidget = Icon(
          Icons.stop,
          color: applicableRule.color,
          size: applicableRule.convert('0.5em'),
        );
      } else {
        symbolWidget = Fss.text(symbol);
      }
    }

    final symbolInset = applicableRule.getSize('-fss-list-symbol-width') ??
        applicableRule.convert('3em');
    final symbolPadding = applicableRule.getSize('-fss-list-symbol-gap') ??
        applicableRule.convert('0.5em');

    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(right: symbolPadding),
          child: Container(
            constraints: BoxConstraints(minWidth: symbolInset),
            alignment: AlignmentDirectional.centerEnd,
            child: symbolWidget,
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

/// A builder that will allow you to style your component.
///
/// This will resolve the applicable rule from the [FssTheme] and then invoke
/// the builder.
class _FssBuilder extends FssWidget {
  /// A builder to create the child widget.
  ///
  /// The builder will have access to the applicable FssRule containing all
  /// the styles. Use this if you want to configure your widget with styles.
  /// If a [child] is defined the builder is ignored.
  final FssWidgetBuilder builder;

  const _FssBuilder({
    Key? key,
    required this.builder,
    String? fssType,
    String? fssID,
    String? fssClass,
  }) : super(
          key: key,
          fssType: fssType,
          fssID: fssID,
          fssClass: fssClass,
        );

  @override
  Widget buildContent(BuildContext context, FssRuleBlock applicableRule) {
    return builder(context, applicableRule);
  }
}

/// A styleable text inline widget.
///
/// This will set the [TextStyle] of the widget from the stylesheet.
class FssText extends FssWidget {
  final String data;

  const FssText(
    this.data, {
    Key? key,
    String? fssType,
    String? fssID,
    String? fssClass,
  }) : super(
          key: key,
          fssType: fssType,
          fssID: fssID,
          fssClass: fssClass,
        );

  @override
  Widget buildContent(BuildContext context, FssRuleBlock applicableRule) {
    return Text(
      applicableRule.transformText(data),
      style: applicableRule.textStyle,
      overflow: applicableRule.wrapText ? null : applicableRule.textOverflow,
      softWrap: applicableRule.wrapText,
      textDirection: applicableRule.direction,
    );
  }
}

/// Finds the applicable rule to use for this widget.
/// If no class is set on this container look up the hirarchy
FssRuleBlock resolveApplicableStyles({
  required BuildContext context,
  String? fssType,
  String? fssId,
  String? fssClass,
}) {
  final stylesheet = FssTheme.of(context);
  if (stylesheet == null) {
    throw const FssParseException(
      'No FssTheme found in the widget tree. Cannot resolve styles.',
    );
  }

  // Used to resolve media query rules.
  final media = MediaQuery.maybeOf(context);

  // Find parent container and get its styles for inheritance
  final parentStyles = FssParent.of(context);

  return stylesheet.resolveStyles(
    matchId: fssId ?? '',
    matchClasses: fssClass ?? '',
    matchType: fssType ?? '',
    parentStyles: parentStyles,
    media: media,
  );
}
