import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

#bg {
  background-color: black;
  padding: 10px;
} 

body {
  font-size: 14px;
  color: FloralWhite;
}

''';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Creates a simple app that displays the default property values,
/// variables and rules.
///
/// We add a lot of the standard material theme values as variables
/// with the --mat prefix. You can use them in your own rules via the var()
/// function.
///
class TestApp extends StatelessWidget {
  /// Constructor
  const TestApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSS Defaults Demo',
      builder: (c, _) => FssTheme.withAppDefaults(
        context: c,
        stylesheet: styleSheet,
        child: Builder(
          builder: (c) {
            final FssTheme theme = FssTheme.of(c)!;
            return Fss.div(
              fssID: 'bg',
              child: SingleChildScrollView(
                // This gives you all the details of the currently used fss theme
                child: Fss.body(theme.toString(minLevel: DiagnosticLevel.fine)),
              ),
            );
          },
        ),
      ),
    );
  }
}
