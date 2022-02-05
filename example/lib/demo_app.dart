import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheetFile = 'assets/test_app.fss';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Simple example application that loads a stylesheet from a file in the
/// assets and then install it as a theme into the widget tree.
class TestApp extends StatelessWidget {
  /// Constructor
  const TestApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSS Demo App',
      // Here we inject the FSS theme into the widget tree
      // We use the system Theme to set some default styles and rules.
      // This will take over the color theme and fonts of the system.
      // We use a future builder because we load the stylesheet from an asset.
      builder: (c, _) => FutureBuilder(
        future: DefaultAssetBundle.of(c).loadString(styleSheetFile),
        initialData: '',
        builder: (c, stylesheetAsset) {
          if (!stylesheetAsset.hasData) {
            return const CircularProgressIndicator();
          }

          return FssTheme.withAppDefaults(
            context: c,
            stylesheet: stylesheetAsset.data.toString(),
            // Now we add the widgets of the demo app. A div container and
            // inside some example widgets.
            child: Fss.div(
              fssClass: 'frame',
              builder: (c, ap) => SingleChildScrollView(
                child: Column(
                  children: [
                    // Lets add some text with different styles
                    Fss.h1('H1 - FSS'),
                    Fss.h2('H2 - FSS with style.'),
                    Fss.h3('H3 - FSS style your widgets with style.'),
                    Fss.h4('H4 - FSS style your widgets with style.'),
                    Fss.h5('H5 - FSS style your widgets with style.'),
                    Fss.h6('H6 - FSS style your widgets with style.'),
                    Fss.subtitle1(
                      'Subtitle1 - FSS style your widgets with style.',
                    ),
                    Fss.subtitle2(
                      'Subtitle1 - FSS style your widgets with style.',
                    ),
                    Fss.body('Body - FSS style your widgets with style.'),
                    Fss.body2('Body2 - FSS style your widgets with style.'),
                    Fss.caption('Caption - FSS style your widgets with style.'),
                    Fss.hr(),
                    // We also offer a simple list
                    Fss.ol(
                      fssClass: 'simple',
                      children: [
                        Fss.text('A simple styleable list'),
                        Fss.text('Second'),
                        Fss.text('Third'),
                      ],
                    ),
                    // Here we use a button and configure it from styles.
                    // For this we lookup the styles for the element type "button"
                    Fss.styled(
                      fssType: 'button',
                      builder: (context, styles) => ElevatedButton(
                        onPressed: () => {},
                        style: ElevatedButton.styleFrom(
                          primary: styles.backgroundColor,
                          onPrimary: styles.color,
                        ),
                        child: Text('My Button', style: styles.textStyle),
                      ),
                    ),

                    // Finally we add an image. It has the fss class "test"
                    Fss.img(src: const AssetImage('test.png'), fssID: 'my_img'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
