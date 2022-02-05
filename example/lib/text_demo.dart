import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

* {
  font-size: 20px;
}

#text1 {
  font-size: 32px;
  color: red;
}

#text2 {
  font-weight: bold;
}

#text3 {
  font-style: italic;
}

#text4 {
  text-decoration-line: underline;
  text-decoration-style: dashed;
}

#text5 {
  text-decoration-line: line-through;
}

#text6 {
  text-transform: uppercase;
}

#text7 {
  text-shadow: 3 3 1.5 gray;
}

#text8 {
  color: brown; 
  font-size: 40px;
  font-style: italic;
  font-family: StyleScript; 
  text-shadow: 3 3 1.5 gray;
  text-decoration-line: underline;
  text-decoration-style: dotted;
}

#text9 {
  content: Text replaced via CSS "content";
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
      title: 'FSS Text Demo',
      builder: (c, _) => FssTheme.withAppDefaults(
        context: c,
        stylesheet: styleSheet,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              Fss.text(
                'Almost before we knew it, we had left the ground.',
                fssID: 'text1',
              ),
              Fss.text(
                'Almost before we knew it, we had left the ground.',
                fssID: 'text2',
              ),
              Fss.text(
                'Almost before we knew it, we had left the ground.',
                fssID: 'text3',
              ),
              Fss.text(
                'Almost before we knew it, we had left the ground.',
                fssID: 'text4',
              ),
              Fss.text(
                'Almost before we knew it, we had left the ground.',
                fssID: 'text5',
              ),
              Fss.text(
                'Almost before we knew it, we had left the ground.',
                fssID: 'text6',
              ),
              Fss.text(
                'Almost before we knew it, we had left the ground.',
                fssID: 'text7',
              ),
              Fss.text(
                'Almost before we knew it, we had left the ground.',
                fssID: 'text8',
              ),
              Fss.text(
                'Almost before we knew it, we had left the ground.',
                fssID: 'text9',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
