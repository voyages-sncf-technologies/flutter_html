import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/src/html_elements.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("Check that default parser does not fail on empty data",
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Html(
            data: "",
          ),
        ),
      ),
    );
  });

  testNewParser();
}

void testNewParser() {
  test("Html Parser works correctly", () {
    HtmlParser.parseHTML("<b>Hello, World!</b>");
  });

  test("lexDomTree works correctly", () {
    StyledElement tree = HtmlParser.lexDomTree(
      HtmlParser.parseHTML(
          "Hello! <b>Hello, World!</b><i>Hello, New World!</i>"),
      [],
      [],
    );
    print(tree.toString());
  });

  test("InteractableElements work correctly", () {
    StyledElement tree = HtmlParser.lexDomTree(
        HtmlParser.parseHTML(
            "Hello, World! <a href='https://example.com'>This is a link</a>"),
        [],
        []);
    print(tree.toString());
  });

  test("ContentElements work correctly", () {
    StyledElement tree = HtmlParser.lexDomTree(
      HtmlParser.parseHTML("<img src='https://image.example.com' />"),
      [],
      [],
    );
    print(tree.toString());
  });

  test("Nesting of elements works correctly", () {
    StyledElement tree = HtmlParser.lexDomTree(
      HtmlParser.parseHTML(
          "<div><div><div><div><a href='link'>Link</a><div>Hello, World! <b>Bold and <i>Italic</i></b></div></div></div></div></div>"),
      [],
      [],
    );
    print(tree.toString());
  });

  test("Test style merging", () {
    Style style1 = Style(
      display: Display.BLOCK,
      fontWeight: FontWeight.bold,
    );

    Style style2 = Style(
      before: "* ",
      direction: TextDirection.rtl,
      fontStyle: FontStyle.italic,
    );

    Style finalStyle = style1.merge(style2);

    expect(finalStyle.display, equals(Display.BLOCK));
    expect(finalStyle.before, equals("* "));
    expect(finalStyle.direction, equals(TextDirection.rtl));
    expect(finalStyle.fontStyle, equals(FontStyle.italic));
    expect(finalStyle.fontWeight, equals(FontWeight.bold));
  });
}
