import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

ul.custom {
  color: red;
  list-style-type: #;
}

ul.square {
  color: green;
  list-style-type: square;
}

ol.decimal {
  color: brown;
  list-style-type: decimal;
}

ol.roman {
  color: purple;
  list-style-type: lower-roman;
}

ol.spacing {
  color: purple;
  list-style-type: upper-latin;
  -fss-list-symbol-width: 20px;
  -fss-list-symbol-gap: 30px;
}


''';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Creates a simple app with a single list.
/// So you get the styles of the STYLESHEET above.
class TestApp extends StatelessWidget {
  /// Constructor
  const TestApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSS List Demo',
      builder: (c, _) => FssTheme.withAppDefaults(
        context: c,
        stylesheet: styleSheet,
        child: ListView(
          children: [
            Fss.ul(
              children: [
                Fss.text('With default icon'),
                Fss.text('Second'),
                Fss.text('Third'),
              ],
            ),
            Fss.ul(
              fssClass: 'custom',
              children: [
                Fss.text('With custom text'),
                Fss.text('Second'),
                Fss.text('Third'),
              ],
            ),
            Fss.ul(
              fssClass: 'square',
              children: [
                Fss.text('With square icon'),
                Fss.text('Second'),
                Fss.text('Third'),
              ],
            ),
            Fss.ol(
              fssClass: 'decimal',
              children: [
                Fss.text('With number'),
                Fss.text('Second'),
                Fss.text('Third'),
              ],
            ),
            Fss.ol(
              fssClass: 'roman',
              children: [
                Fss.text('With roman numbers'),
                Fss.text('Second'),
                Fss.text('Third'),
              ],
            ),
            Fss.ol(
              fssClass: 'spacing',
              children: [
                Fss.text('With custom spacing'),
                Fss.text('Second'),
                Fss.text('Third'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
