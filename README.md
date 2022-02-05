# Flutter Style Sheets

Style your apps with "CSS like" theme files.

This allows you to cleanly separate the theme and styling from your code.
The Flutter styling system is fully in code, hard to extend and not cleanly fitting for your own components.
For this reason and as CSS is a well known technology I decided to bring the benefits of CSS to the Flutter world.

## Getting Started

Styling your widget with FSS involves basically the following steps.
1. Install your stylesheet into the widget tree via the `FssTheme` widget
The most common way is to use the `FssTheme.withAppDefaults` factory method.
2. Provide a style sheet as string or load it from a resource into the FssTheme.
3. Add styleable widgets to your UI and assign FSS classes and IDs to them.
For this you should have a look at the `Fss` class that offers a variety of factory methods to
create styleable widgets.

Here a minimum example:

```dart
    class MyApp extends StatelessWidget {

        @override
        Widget build(BuildContext context) {
            return MaterialApp(
                title: 'My App',
                builder: (c, _) => FssTheme.withAppDefaults(
                    context: c,
                    stylesheet: styleSheet, // This string contains your stylesheet
                    child: Fss.div(fssID: 'box1', fssClass: 'box', 
                    		child: Fss.text('Hello World')),
                ),
            ));
        }
    }
```

Look into the [examples](example/lib) folder to see how this all works with more complex widgets.

## Writing Stylesheets

Stylesheets use the CSS syntax. Please note that the parser is very simplistic 
and not a full featured CSS parser. So some syntax is not supported. We do also
not support all CSS attributes and features but try to get as close as possible.

Stylesheets are composed of a list of rules. Rules are written like this:

```css
selector {
  property: value;
  property: value;
  ... 
}
```

**ATTENTION: The parser expects the open and closing brackets exactly like this. You cannot put multiple rules or multiple properties on a single line! Line breaks matter here! When saving or loading a stylesheet from a file that file must be UTF-8 encoded.**

**In FSS in contrast to CSS we try to be as much case insensitive as possible. This means all property names, values, class names, selectors... are ignoring case. 
Only for some exceptions like font names, paths or URLs we need proper case. As a best practice prefer using lowercase when possible everywhere.**
  
 
### Selectors 

The selector follows the CSS syntax. You can select by type, ID, classes.
FSS also supports media query selectors and rules. 

```css
div {
  color: red;
}

#myid {
  color: blue;
}

.myclass {
  color: green;
}

div.myclass {
  color: yellow;
}

```

Rules are matched in the same way as in CSS. Properties are defined like in CSS with property name and value.
You can combine selectors as in CSS as seen in the example above where we have a type `div` and a class `myclass`.

We **DO** support:
- .class
- .class1.class2
- #id
- \*
- element
- element.class
- element,element

and combinations of those. Additionally we also support media query selectors.

Currently we **DO NOT** support hierarchical selectors and attribute selectors:
- .class1 .class2
- element element
- element>element
- element+element
- element1~element2
- \[attribute\] and other variant in brackets
- :active or any other variant starting with a :

### Comments

You can add comments to your stylesheets by using the CSS block comment syntax:

```css
/* My remarks */
```

### Properties

Properties always consist of a name and a value definition.

**Normally property names and values are case insensitive. Some like font names, paths or URLs may need proper case. As a best practice prefer using lowercase when possible.**

Property names starting with **--** are interpreted as variables (see Variables section below).
Property names starting with **-fss** are proprietary. This prefix is reserved for internal use.

The property value definition part can consist of one or more values that are separated by spaces.
It is mandatory to always end the property definition with a semicolon.  

```css
div {
  text-align: center;
  background-color: yellow;
  color: black;
  margin: 5px;
  border: 5px outset #999999;
}
```

### Variables

You can define and use variables in your style sheets similar to CSS. Variables are defined in the same way as other properties 
but their name always starts with -- as a prefix. Variables are inherited and can be redefined. To use a variable as value for 
another property you can use the `var()` function. 

Here an example:

```css
* {
  --mycolor: #ff0c0f;
}

div {
  color: var(--mycolor);
}
```

### Colors

Many of the properties of CSS are related to colors. We support here most of the CSS syntax and options to define colors.
You can define them as Hex encoded, as RGB via the `rgb()` and `rgba()` functions, `hsl()` and `hsla()` or use one of the predefined color names. Colors support transparency.

```css
* {
  color: black;
  background-color: #ffffff;
}

div {
  color: rgba(255, 255, 255, 0.5);
  background-color: fuchsia;
  border-color: #ff00ffcc; /* rgba */
}
```
Please check this for further details: https://developer.mozilla.org/en-US/docs/Web/CSS/color_value

### Sizes and length values

For defining sizes and length we support the following options. 
You can define values in the following units:
- px
- in
- rem
- em

Check class `FssSize` to see all the options.

Here an example:

```css
* {
 font-size: 16; /* Same as px */
}

div {
  font-size: 1.5em; 
  font-size: 2rem;
  font-size: 24px;
}
```
**DO NOT** put white-space between value and unit!

We **DO NOT** support **percentage (%)** for most properties because of the way Flutter layout works this is not easy to implement.
This is only supported for some specific use cases (for example in gradient stops.)

### Setting defaults values

The easiest way to set some good defaults for colors, fonts and some other properties is to use the system defaults.
This can be done by using `FssTheme.withAppDefaults()` to create your theme. This will add styles and default rules
to based on the current Material Theme's values. This offers a good starting point.

Another way is to create a `FssTheme` and provide defaults via the `systemDefaults` and `rules` as constructor parameters.

To set defaults via the stylesheet a good way is via the * selector that will match all elements:

```css
* {
  font-size: 16;
  color: black;
  background-color: #ffffff;  
}
```

Properties will be resolved in the following way.
1. If something is defined via a rule that value is used
2. else if the property is inheritable then we get the inherited value from the _parent_
3. else use the default value

For default values the following is the order: 
1. Hard-coded default values
2. can be overwritten by values from the Flutter Theme 
3. can be overwritten by values provided as constructor parameter

  
### Media Queries

We support also media query blocks that allow to group a list of rules and apply them only if a media query conditions is met.
This uses the same syntax as CSS.

```css
/* We also support media queries. When the app is resized the rules change */
@media screen (width <= 600px) AND (height <= 1000px)  {

/* When the screen width is smaller than 600px then change h1 and h2  */
  h1, h2 {
    color: rgb(155,0,0);
    font-size: 32px;
  }

}
```

Look at the examples and the `FssMediaSelector` to learn more about what media query syntax is supported.

## Styling your widgets

To apply the styles from your stylesheet file to widgets you need to use special widgets which are 
styleable. The `Fss` class offers some helper methods to create widgets which are similar to commonly used HTML elements.
There is basically two types of widgets. Block widgets like p, div... and text widgets like h1 - h6, bodyText, caption...

Block widgets are using in the background the `FssBox` widget. That one will apply automatically a set of properties like: background, border, padding and margin, box-shadow and some more.
Text widgets are implemented in the class `FssText`. This one mainly applies automatically: font, color, outline and some other properties which are related to text.

If you want to style your own widget you can use `Fss.styled` factory method which will resolve for you automatically the styles and give you access to it via a builder.
Alternatively you can implement your own widget by extending the `FssWidget` class and implementing the

`Widget buildContent(BuildContext context, FssRuleBlock applicableStyles);` 

method.

Due to the differences in HTML and Flutter widget trees the styling is mainly limited to the look of widgets.
Features related to layout like flex, grid... are not supported or only very limited. Keep this in mind.

Layout is done in Flutter, styling is done in the stylesheet file.

### Rule / Style resolving

FssWidgets and it's descendants will automatically lookup all the rules that match this element and combine the properties
into the final set of applicable properties. The order in which rules are resolved and applied is as specified by CSS.
See: https://developer.mozilla.org/en-US/docs/Web/CSS/Specificity for more information.

All FssWidgets offer to define via the constructor the following attributes that are used for rule matching.

**fssID** - This is a unique ID for your element it comparable to the HTML id attribute. If you do not specify 
an ID explicitly an ID may be generated from the Widget Key if one is set. 

**fssType** - This is the type of the element. This is comparable to the HTML element name. For example "div", "p"... 
but you can use any name element name that you want like: "button", "list", "spinner"...

**fssClass** - Allows you to assign a space separated list of class names to your element. These will then be used
to match the class names used in the rules: For example the following will assign three classes to your element: "box header colorful"

Based on these attributes plus the current `MediaQuery` the rules will be resolved.

Here an example of a widget that we assign an ID, type and classes to:

```dart
Fss.box(
  fssType: 'box',
  fssID: 'mybox22',
  fssClass: 'with_border header colorful',
  child: ...
)
```

When you use the `Fss` factory methods a fssType will be often set automatically.

### Inheritance

Inheritance in CSS relies on the element structure. The main important point here is the  _parent_ element from which property values are inherited.
In FSS this is a little bit special. We do not consider all widgets. In Flutter you often have non visual widgets in the tree and we do not have full access to the whole UI tree. For this reason inheritance works a little bit different.  

FSS will only see FssWidgets added to the tree. All others will be not relevant. For example:

```dart
class TestApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'FSS Inheritance Demo',
        builder: (c, _) => FssTheme.withAppDefaults(
              context: c,
              stylesheet: STYLESHEET,
              child: Fss.div(         // This will be the parent  
                fssClass: 'mybox',
                child: ListView(
                  children: [
                    Center(child: Fss.text('Test 1', fssID: 'text1')),
                    Fss.text('Test 2', fssID: 'text2'),
                  ],
                ),
              ),
            ));
  }
}
```
In the example above the  _parent_  of the text widgets "Test 1" and "Test 2" will be in both cases the div.
The intermediate widgets like the Center or the ListView will be ignored as they are not FSS styleable widgets.

To inject a parent into the tree or to define values to inherit for a widget subtree you can use the `FssParent` widget.

### Accessing styles programmatically

The easiest way is to use `Fss.styled` factory method. This wraps your widget and, will allow you
access to the applicable styles via a parameter in the `FssWidgetBuilder`.

Another way to access the current effective styles you can retrieve them via the `resolveApplicableStyles`
helper method from the BuildContext:

```dart
class TestApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    // As we do not provide any classes id or type to resolve this will give us the
    // styles of the parent container.
    FssRuleBlock applicableStyles = resolveApplicableStyles(context: context);
    var textColor = applicableStyles.textStyle.color;
    ...
    // This will resolve rules via a given type, id and classes.
    FssRuleBlock myStyles = resolveApplicableStyles(
       context: context,
       fssType: 'myWidget',
       fssId: 'myID',
       fssClass: 'box darker my_style',
    );
    var myTextColor = myStyles.textStyle.color;
    ...
  }
}
```
The resolved `FssRuleBlock` gives you access to all the properties with the following methods:
`FssRuleBlock.get`, `FssRuleBlock.getString`, `FssRuleBlock.getSize`, `FssRuleBlock.getColor`

and additionally it offers a lot of methods to access Flutter helper objects configured from the
properties like: `TextStyle`, `BoxConstraints`, colors, `BoxBorder`, `Alignment`
and other ready to use Flutter object.

## Property Reference

This section describes the supported properties and their values. We try to support many of the properties of CSS 3.0
as documented here: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Properties_Reference
But due to the differences of HTML and Flutter we cannot implement everything one to one.
The following section will list the supported properties and their syntax.

----
##### accent_color

Allowed values: *any color*  
Initial value: *auto*

Example: `accent_color: white;`  

----
##### visibility

Allowed values: *visible, hidden*  
Initial value: *visible*

Example: `visibility: hidden;`

----
##### background-color

Allowed values: *any color*  
Initial value: *transparent*

Example: `background-color: yellow;`  

----
##### background-image

Currently if the provided image starts with http it will be treated as URL else
as asset name. 

Allowed values: *path, url or asset name*  
Initial value: *none*

Example: `background-image: myImage.png;`  

----
##### background-repeat

Allowed values: *repeat, repeat-x, repeat-y, no-repeat*  
Initial value: *repeat*

Example: `background-repeat: myImage.png;`  

----
##### background-size

Allowed values: *contain, cover, fill, scale-down, fit-width, fit-height, auto*  
Initial value: *auto auto*

Example: `background-size: fill;`  

----
##### background-position

This expects two values for horizontal and for vertical alignment.

Allowed values: *left, right, start, end, middle, bottom, top, center*  
Initial value: *left top*

Example: `background-position: center bottom;`  

----
##### color

Allowed values: *any color*  
Initial value: *black*

Example: `color: #caffee;`  

----
##### caret_color

Allowed values: *any color*  
Initial value: *none*

Example: `caret_color: blue;`  

----
##### content-visibility

Allowed values: *visible, hidden*  
Initial value: *visible*

Example: `content-visibility: hidden;`  

----
...and many many more which still need to be documented.

## Function Reference
Fss has support for the following functions that you can use inside of the fss files similar to the CSS functions. 

For colors you can use rgb(), rgba(), hsl(), hsla(), ... and gradient functions. (See Colors section)

You can define your own variables and use them via the var() function. (See Variables section) 

TODO: some more info about the functions syntax supported, but I'm too lazy today. 
 
