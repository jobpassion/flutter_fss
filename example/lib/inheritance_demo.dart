import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

* {
  font-size: 20px;
  color: black;
}

div.mybox {
  color: red;
}

#text2 {
  color: blue;
}

''';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Creates a simple app with some styleable widgets.
/// So you get the styles of the STYLESHEET above.
class TestApp extends StatelessWidget {
  /// Constructor
  const TestApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSS Inheritance Demo',
      builder: (c, _) => FssTheme.withAppDefaults(
        context: c,
        stylesheet: styleSheet,
        // This is the "parent" for the text elements
        child: Fss.div(
          fssClass: 'mybox',
          child: ListView(
            children: [
              // Center and ListView will be ignored as they are not stylable
              Center(
                child: Fss.text('Color inherited from parent.', fssID: 'text1'),
              ),
              Fss.text('Color resolved via ID', fssID: 'text2'),
            ],
          ),
        ),
      ),
    );
  }
}
