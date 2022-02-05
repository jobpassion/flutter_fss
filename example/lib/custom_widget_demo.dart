import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

* {
  color: fuchsia;  
}

''';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Creates a simple app with a custom styled widget.
/// So you get the styles of the STYLESHEET above.
class TestApp extends StatelessWidget {
  /// Constructor
  const TestApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSS Custom Demo',
      builder: (c, _) => FssTheme.withAppDefaults(
        context: c,
        stylesheet: styleSheet,
        child: Fss.styled(
          // Via the FssWidgetBuilder we have access to the styles.
          builder: (context, applicableStyles) {
            return Text(
              'Hello World',
              style: TextStyle(color: applicableStyles.color),
            );
          },
        ),
      ),
    );
  }
}

/// This example shows you how to access the styles by inheriting from FssWidget
class MyWidget extends FssWidget {
  /// Constructor
  const MyWidget({Key? key}) : super(key: key);

  /// You just need to implement this method where you have access to the styles.
  @override
  Widget buildContent(BuildContext context, FssRuleBlock applicableStyles) {
    return Text(
      'Hello World',
      style: TextStyle(color: applicableStyles.color),
    );
  }
}

/// This widget uses another way to access the styles
/// This can be used anywhere, where you have access to an BuildContext
class MyWidget2 extends StatelessWidget {
  /// Constructor
  const MyWidget2({Key? key}) : super(key: key);

  /// Build method
  @override
  Widget build(BuildContext context) {
    // This gives you access to specially resolved styles.
    final myStyles = resolveApplicableStyles(
      context: context,
      fssType: 'myWidget',
      fssId: 'myID',
      fssClass: 'box darker my_style',
    );

    return Text(
      'Hello World',
      style: TextStyle(color: myStyles.color),
    );
  }
}
