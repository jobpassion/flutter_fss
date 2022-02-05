import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

div {
  text-align: center;
  background-color: yellow;
  color: black;
  margin: 5px;
  border: 5px outset #999999;
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
      title: 'FSS Simple Demo',
      builder: (c, _) => FssTheme.withAppDefaults(
        context: c,
        stylesheet: styleSheet,
        child: GridView.count(
          crossAxisCount: 5,
          padding: const EdgeInsets.all(8),
          children: [
            Fss.div(child: Fss.text('Test')),
          ],
        ),
      ),
    );
  }
}
