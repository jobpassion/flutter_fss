import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

div {
  text-align: center;
  margin: 5px;
}

#box1 {
  background-color: red;
  color: white;
}

#box2 {
  background-color: yellow;
  border: 5px solid black;
}

#box3 {
  background-color: orange;
  box-shadow: 3 3 1.5 0.5 gray;
}

#box4 {
  color: red;
  background-image: test.png;
  background-size: fill;
}

#box5 {
  background-image: linear-gradient(to top right, white, blue 25%, green 50%, red 75%, black);
}

#box6 {
  background-image: radial-gradient(white, orange 15%, red 25%, yellow 50%, black 75%, black);
}

#box7 {
  background-color: green;
  color: red;
  background-image: test.png;
  background-size: contain;
  background-repeat: norepeat;
  background-position: center;  
}

#box8 {
  background-color: purple; 
  border: 2px solid black;
  border-color: red;
  border-radius: 10px;
}

#box9 {
  background-color: blue;
  color: red;
  font-weight: bold;
  font-size: 32px;
  text-align: left;
  vertical-align: top;
  padding: 15px;
}

#box10 {
  background-color: white;
  color: red;
  font-size: 40;
  background-image: test.png;
  background-size: contain;
  background-repeat: norepeat;
  background-position: center;  
  border: 2px solid black;
  border-radius: 10px;
  box-shadow: 3 3 1.5 0.5 gray;
  transform: rotate(15deg);
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
      title: 'FSS Box Demo',
      builder: (c, _) => FssTheme.withAppDefaults(
        context: c,
        stylesheet: styleSheet,
        child: GridView.count(
          crossAxisCount: 5,
          padding: const EdgeInsets.all(8),
          children: [
            Fss.div(fssID: 'box1', child: Fss.text('1')),
            Fss.div(fssID: 'box2', child: Fss.text('2')),
            Fss.div(fssID: 'box3', child: Fss.text('3')),
            Fss.div(fssID: 'box4', child: Fss.text('4')),
            Fss.div(fssID: 'box5', child: Fss.text('5')),
            Fss.div(fssID: 'box6', child: Fss.text('6')),
            Fss.div(fssID: 'box7', child: Fss.text('7')),
            Fss.div(fssID: 'box8', child: Fss.text('8')),
            Fss.div(fssID: 'box9', child: Fss.text('9')),
            Fss.div(fssID: 'box10', child: Fss.text('10')),
          ],
        ),
      ),
    );
  }
}
