import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/src/html_elements.dart';
import 'package:flutter_html/style.dart';
import 'package:html/dom.dart' as dom;

/// A [ReplacedElement] is a type of [StyledElement] that does not require its [children] to be rendered.
///
/// A [ReplacedElement] may use its children nodes to determine relevant information
/// (e.g. <video>'s <source> tags), but the children nodes will not be saved as [children].
abstract class ReplacedElement extends StyledElement {
  PlaceholderAlignment alignment;

  ReplacedElement(
      {String name,
      Style style,
      dom.Element node,
      this.alignment = PlaceholderAlignment.aboveBaseline})
      : super(name: name, children: null, style: style, node: node);

  static List<String> parseMediaSources(List<dom.Element> elements) {
    return elements
        .where((element) => element.localName == 'source')
        .map((element) {
      return element.attributes['src'];
    }).toList();
  }

  Widget toWidget(RenderContext context);
}

/// [TextContentElement] is a [ContentElement] with plaintext as its content.
class TextContentElement extends ReplacedElement {
  String text;

  TextContentElement({
    Style style,
    this.text,
  }) : super(name: "[text]", style: style);

  @override
  String toString() {
    return "\"${text.replaceAll("\n", "\\n")}\"";
  }

  @override
  Widget toWidget(_) => null;
}

/// [ImageContentElement] is a [ReplacedElement] with an image as its content.
/// https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img
class ImageContentElement extends ReplacedElement {
  final String src;
  final String alt;

  ImageContentElement({
    String name,
    Style style,
    this.src,
    this.alt,
    dom.Element node,
  }) : super(
          name: name,
          style: style,
          node: node,
          alignment: PlaceholderAlignment.middle,
        );

  @override
  Widget toWidget(RenderContext context) {
    for (final entry in context.parser.imageRenders.entries) {
      if (entry.key.call(attributes, element)) {
        final widget = entry.value.call(context, attributes, element);
        if (widget != null) {
          return widget;
        }
      }
    }
    return SizedBox(width: 0, height: 0);
  }
}

class EmptyContentElement extends ReplacedElement {
  EmptyContentElement({String name = "empty"}) : super(name: name);

  @override
  Widget toWidget(_) => null;
}

class RubyElement extends ReplacedElement {
  dom.Element element;

  RubyElement({@required this.element, String name = "ruby"})
      : super(name: name, alignment: PlaceholderAlignment.middle);

  @override
  Widget toWidget(RenderContext context) {
    dom.Node textNode;
    List<Widget> widgets = List<Widget>();
    //TODO calculate based off of parent font size.
    final rubySize = max(9.0, context.style.fontSize.size / 2);
    final rubyYPos = rubySize + rubySize / 2;
    element.nodes.forEach((c) {
      if (c.nodeType == dom.Node.TEXT_NODE) {
        textNode = c;
      }
      if (c is dom.Element) {
        if (c.localName == "rt" && textNode != null) {
          final widget = Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                  alignment: Alignment.bottomCenter,
                  child: Center(
                      child: Transform(
                          transform:
                              Matrix4.translationValues(0, -(rubyYPos), 0),
                          child: Text(c.innerHtml,
                              style: context.style
                                  .generateTextStyle()
                                  .copyWith(fontSize: rubySize))))),
              Container(
                  child: Text(textNode.text.trim(),
                      style: context.style.generateTextStyle())),
            ],
          );
          widgets.add(widget);
        }
      }
    });
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}

ReplacedElement parseReplacedElement(dom.Element element) {
  switch (element.localName) {
    case "br":
      return TextContentElement(
        text: "\n",
        style: Style(whiteSpace: WhiteSpace.PRE),
      );
    case "img":
      return ImageContentElement(
        name: "img",
        src: element.attributes['src'],
        alt: element.attributes['alt'],
        node: element,
      );
    case "ruby":
      return RubyElement(
        element: element,
      );
    default:
      return EmptyContentElement(name: element.localName);
  }
}

// TODO(Sub6Resources): Remove when https://github.com/flutter/flutter/issues/36304 is resolved
class PlatformViewVerticalGestureRecognizer
    extends VerticalDragGestureRecognizer {
  PlatformViewVerticalGestureRecognizer({PointerDeviceKind kind})
      : super(kind: kind);

  Offset _dragDistance = Offset.zero;

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    _dragDistance = _dragDistance + event.delta;
    if (event is PointerMoveEvent) {
      final double dy = _dragDistance.dy.abs();
      final double dx = _dragDistance.dx.abs();

      if (dy > dx && dy > kTouchSlop) {
        // vertical drag - accept
        resolve(GestureDisposition.accepted);
        _dragDistance = Offset.zero;
      } else if (dx > kTouchSlop && dx > dy) {
        // horizontal drag - stop tracking
        stopTrackingPointer(event.pointer);
        _dragDistance = Offset.zero;
      }
    }
  }

  @override
  String get debugDescription => 'horizontal drag (platform view)';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
