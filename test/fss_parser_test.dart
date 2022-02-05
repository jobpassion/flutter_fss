import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fss/fss.dart';

/// All kind of unit tests for the parser.

void main() {
  // -------------------------------------------------------------
  // Tests for basic parsing functions
  // -------------------------------------------------------------

  group('Generic Parsing', () {
    // -------------------------------------------------------------
    test('Parse size px', () {
      const input = '''
        test { 
          width: 3px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse size in', () {
      const input = '''
        test { 
          width: 3in; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.width, 288);
    });

    // -------------------------------------------------------------
    test('Parse size em', () {
      const input = '''
        test {
          font-size: 16; 
          width: 2em; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.width, 32);
    });

    // -------------------------------------------------------------
    test('Parse size em', () {
      const input = '''
        test {
          width: 2rem; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.width, 32);
    });

    // -------------------------------------------------------------
    test('Parse shorthand', () {
      const input = '''
        test { 
          border: 3px solid black; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff000000));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse shorthand with function', () {
      const input = '''
        test { 
          border: 3px solid rgb(0, 0, 255); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff0000ff));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse shorthand with var', () {
      const input = '''
        test { 
          --mycolor: blue; 
          border: 3px solid var(--mycolor); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff0000ff));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test(
      'Parse var in function',
      () {
        const input = '''
        test { 
          --zero: 0; 
          border: 3px solid rgb( var(--zero), 0, 0); 
        } ''';
        final styles = parseStylesheet(input).first.properties;
        expect(styles.border?.top.color, const Color(0xff000000));
        expect(styles.border?.top.style, BorderStyle.solid);
        expect(styles.border?.top.width, 3);
      },
      skip: true, // Not yet working
    );
  });

// -------------------------------------------------------------
  // Tests for specific property parsing
  // -------------------------------------------------------------

  group('Property Parsing', () {
    // -------------------------------------------------------------
    test('Parse color hex8', () {
      const input = '''
        test { 
          color: #FF0000FF;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromARGB(255, 0, 0, 255));
    });

    // -------------------------------------------------------------
    test('Parse color hex6', () {
      const input = '''
        test { 
          color: #0000FF;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromARGB(255, 0, 0, 255));
    });

    // -------------------------------------------------------------
    test('Parse color constant', () {
      const input = '''
        test { 
          color: blue;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromARGB(255, 0, 0, 255));
    });

    // -------------------------------------------------------------
    test('Parse color from var', () {
      const input = '''
        test {
          --colvar: blue; 
          color: var(--colvar);
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromARGB(255, 0, 0, 255));
    });

    // -------------------------------------------------------------
    test('Parse color rgb function', () {
      const input = '''
        test { 
          color: rgb( 0, 0, 255 ); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromARGB(255, 0, 0, 255));
    });

    // -------------------------------------------------------------
    test('Parse color rgba function', () {
      const input = '''
        test { 
          color: rgba( 0, 0, 255, 0.5 ); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromRGBO(0, 0, 255, 0.5));
    });

    // -------------------------------------------------------------
    test('Parse background-color', () {
      const input = '''
        test { 
          background-color: blue; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundColor, const Color(0xff0000ff));
    });

    // -------------------------------------------------------------
    test('Parse background-image', () {
      const input = '''
        test { 
          background-image: test.png; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundImage?.image, isNotNull);
    });

    // -------------------------------------------------------------
    test('Parse background-image linear-gradient', () {
      const input = '''
        test { 
          background-image: linear-gradient(45deg, red 25%, #00ff00 50%, rgb(0,0,255)); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is LinearGradient, true);
      expect(styles.backgroundGradient?.colors, [
        const Color(0xffff0000),
        const Color(0xff00ff00),
        const Color(0xff0000ff)
      ]);
      expect(styles.backgroundGradient?.stops, [0.25, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse background-image linear-radial', () {
      const input = '''
        test { 
          background-image: radial-gradient(red 25%, #00ff00 50%, rgb(0,0,255)); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is RadialGradient, true);
      expect(styles.backgroundGradient?.colors, [
        const Color(0xffff0000),
        const Color(0xff00ff00),
        const Color(0xff0000ff)
      ]);
      expect(styles.backgroundGradient?.stops, [0.25, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse border', () {
      const input = '''
        test { 
          border: 3px solid black; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff000000));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse border side', () {
      const input = '''
        test { 
          border-top: 3px solid black; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff000000));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse border side values', () {
      const input = '''
        test { 
          border-top-width: 3px; 
          border-top-color: black; 
          border-top-style: solid; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff000000));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse border radius', () {
      const input = '''
        test { 
          border-radius: 5px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.borderRadius, BorderRadius.circular(5));
    });

    // -------------------------------------------------------------
    test('Parse font3', () {
      const input = '''
        test { 
          font: bold 16px Roboto; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.fontSize, 16);
      expect(styles.textStyle?.fontWeight, FontWeight.bold);
      expect(styles.textStyle?.fontFamily, 'Roboto');
    });

    // -------------------------------------------------------------
    test('Parse font4', () {
      const input = '''
        test { 
          font: italic bold 16px Roboto; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.fontStyle, FontStyle.italic);
      expect(styles.textStyle?.fontSize, 16);
      expect(styles.textStyle?.fontWeight, FontWeight.bold);
      expect(styles.textStyle?.fontFamily, 'Roboto');
    });

    // -------------------------------------------------------------
    test('Parse font with fallback', () {
      const input = '''
        test { 
          font-family: Roboto, SansSerif; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.fontFamily, 'Roboto');
      expect(styles.textStyle?.fontFamilyFallback?[0], 'SansSerif');
    });

    // -------------------------------------------------------------
    test('Parse text-decoration', () {
      const input = '''
        test { 
          text-decoration-color: blue; 
          text-decoration-line: underline; 
          text-decoration-style: wavy; 
          text-decoration-thickness: 3px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.decorationColor, const Color(0xff0000ff));
      expect(styles.textStyle?.decoration, TextDecoration.underline);
      expect(styles.textStyle?.decorationStyle, TextDecorationStyle.wavy);
      expect(styles.textStyle?.decorationThickness, 3);
    });

    // -------------------------------------------------------------
    test('Parse outline', () {
      const input = '''
        test { 
          text-stroke: 2px blue; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.foreground?.strokeWidth, 2);
      expect(styles.textStyle?.foreground?.color, const Color(0xff0000ff));
    });

    // -------------------------------------------------------------
    test('Parse letter-spacing', () {
      const input = '''
        test { 
          letter-spacing: 10px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.letterSpacing, 10);
    });

    // -------------------------------------------------------------
    test('Parse letter-spacing', () {
      const input = '''
        test { 
          word-spacing: 10px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.wordSpacing, 10);
    });

    // -------------------------------------------------------------
    test('Parse text height', () {
      const input = '''
        test { 
          height: 10px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.height, 10);
    });

    // -------------------------------------------------------------
    test('Parse text-align', () {
      const input = '''
        test { 
          text-align: end; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textAlign, TextAlign.end);
    });

    // -------------------------------------------------------------
    test('Parse vertical-align', () {
      const input = '''
        test { 
          vertical-align: bottom; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.verticalAlign, Alignment.bottomCenter);
    });

    // -------------------------------------------------------------
    test('Parse combined alignment', () {
      const input = '''
        test { 
          text-align: right; 
          vertical-align: bottom; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.alignment, Alignment.bottomRight);
    });

    // -------------------------------------------------------------
    test('Parse box-shadow', () {
      const input = '''
        test { 
          box-shadow: 2px 3px 4px 5px blue;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.boxShadow?.offset.dx, 2);
      expect(styles.boxShadow?.offset.dy, 3);
      expect(styles.boxShadow?.blurRadius, 4);
      expect(styles.boxShadow?.spreadRadius, 5);
      expect(styles.boxShadow?.color, const Color(0xff0000ff));
    });

    // -------------------------------------------------------------
    test('Parse visibility', () {
      const input = '''
        test { 
          visibility: hidden;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.visible, false);
    });

    // -------------------------------------------------------------
    test('Parse content-visibility', () {
      const input = '''
        test { 
          content-visibility: hidden;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.contentVisible, false);
    });

    // -------------------------------------------------------------
    test('Parse text-overflow', () {
      const input = '''
        test { 
          text-overflow: fade;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textOverflow, TextOverflow.fade);
    });

    // -------------------------------------------------------------
    test('Parse white-space', () {
      const input = '''
        test { 
          white-space: nowrap;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.whiteSpace, 'nowrap');
      expect(styles.wrapText, false);
    });

    // -------------------------------------------------------------
    test('Parse direction', () {
      const input = '''
        test { 
          direction: rtl;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.direction, TextDirection.rtl);
    });

    // -------------------------------------------------------------
    test('Parse line-height', () {
      const input = '''
        test { 
           line-height: 11px;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.lineHeight, 11);
    });

    // -------------------------------------------------------------
    test('Parse sizes', () {
      const input = '''
        test { 
           min-height: 8px;
           height: 9px;
           max-height: 10px;
           min-width: 11px;
           width: 12px;
           max-width: 13px;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.minHeight, 8);
      expect(styles.height, 9);
      expect(styles.maxHeight, 10);
      expect(styles.minWidth, 11);
      expect(styles.width, 12);
      expect(styles.maxWidth, 13);
      expect(
        styles.constraints,
        const BoxConstraints(
          minHeight: 8,
          maxHeight: 10,
          minWidth: 11,
          maxWidth: 13,
        ),
      );
    });

    // -------------------------------------------------------------
    test('Parse margin', () {
      const input = '''
        test { 
           margin: 10px;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.margin, const EdgeInsets.all(10));
    });
  });

  // -------------------------------------------------------------
  // Selector related test cases
  // -------------------------------------------------------------

  group('Selector Parsing', () {
    // -------------------------------------------------------------
    test('Single class', () {
      final selector = FssSelector.parse('.class1');
      expect(selector.classes[0], '.class1');
    });

    // -------------------------------------------------------------
    test('Multi class', () {
      final selector = FssSelector.parse('.class1.class2');
      expect(selector.classes[0], '.class1');
      expect(selector.classes[1], '.class2');
    });

    // -------------------------------------------------------------
    test('Simple ID', () {
      final selector = FssSelector.parse('#my_id');
      expect(selector.id, '#my_id');
    });

    // -------------------------------------------------------------
    test('Simple type', () {
      final selector = FssSelector.parse('div');
      expect(selector.type, 'div');
    });

    // -------------------------------------------------------------
    test('All combined', () {
      final selector = FssSelector.parse('div.class1.class2#my_id');
      expect(selector.type, 'div');
      expect(selector.classes[0], '.class1');
      expect(selector.classes[1], '.class2');
      expect(selector.id, '#my_id');
    });

    // -------------------------------------------------------------
    test('With virtual "state" class', () {
      final selector = FssSelector.parse('btn:selected');
      expect(selector.type, 'btn');
      expect(selector.classes[0], ':selected');
    });

    // -------------------------------------------------------------
    test('With normal and virtual "state" class', () {
      final selector = FssSelector.parse('btn.class1:selected');
      expect(selector.type, 'btn');
      expect(selector.classes[0], '.class1');
      expect(selector.classes[1], ':selected');
    });
  });
}
