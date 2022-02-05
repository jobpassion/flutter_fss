import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

div {
  text-align: center;
  background-color: yellow;
  color: black;
  margin: 5px;
}

#box1 {
  border: 3px solid black;
}

#box2 {
  border: 3px dashed black;
}

#box3 {
  border: 3px dotted black;
}

#box4 {
  border: 3px hidden black;
}

#box5 {
  border-top: 2px solid black;
}

#box6 {
  border-bottom: 3px dashed blue;
}

#box7 {
  border-left: 4px dotted red;
}

#box8 {
  border-right: 5px solid green;
}

#box9 {
  border-top: 3px solid black;
  border-bottom: 3px solid black;
}

#box10 {
  border-left: 3px solid black;
  border-right: 3px solid black;
}

#box11 {
  border: 3px solid black;
  border-radius: 10px;
}

#box12 {
  border: 3px dashed black;
  border-radius: 10px;
}

#box13 {
  border: 3px dotted black;
  border-radius: 10px;
}

#box14 {
  border: 3px hidden black;
  border-radius: 10px;
}

#box15 {
  border-top: 3px solid red;
  border-right: medium dashed green;
  border-bottom: thick solid blue;
  border-left: 5px dotted gray;
}

#box16 {
  border: medium inset #cccccc;
}

#box17 {
  border: medium outset #cccccc;
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
      title: 'FSS Border Demo',
      builder: (c, _) => FssTheme.withAppDefaults(
        context: c,
        stylesheet: styleSheet,
        child: GridView.count(
          crossAxisCount: 5,
          padding: const EdgeInsets.all(8),
          children: [
            Fss.div(fssID: 'box1', child: Fss.text('solid')),
            Fss.div(fssID: 'box2', child: Fss.text('dashed')),
            Fss.div(fssID: 'box3', child: Fss.text('dotted')),
            Fss.div(fssID: 'box4', child: Fss.text('hidden')),
            Fss.div(fssID: 'box5', child: Fss.text('top')),
            Fss.div(fssID: 'box6', child: Fss.text('bottom')),
            Fss.div(fssID: 'box7', child: Fss.text('left')),
            Fss.div(fssID: 'box8', child: Fss.text('right')),
            Fss.div(fssID: 'box9', child: Fss.text('top bottom')),
            Fss.div(fssID: 'box10', child: Fss.text('left right')),
            Fss.div(fssID: 'box11', child: Fss.text('radius solid')),
            Fss.div(fssID: 'box12', child: Fss.text('radius dashed')),
            Fss.div(fssID: 'box13', child: Fss.text('radius dotted')),
            Fss.div(fssID: 'box14', child: Fss.text('radius hidden')),
            Fss.div(fssID: 'box15', child: Fss.text('mixed')),
            Fss.div(fssID: 'box16', child: Fss.text('inset')),
            Fss.div(fssID: 'box17', child: Fss.text('outset')),
          ],
        ),
      ),
    );
  }
}
