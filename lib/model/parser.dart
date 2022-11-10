import 'dart:math';

import 'package:flutter/material.dart';
import 'package:social_news_app/model/helpers.dart';

abstract class RegexPatterns {
  static final email =
      RegExp(r"\b[\w.!#$%&’*+\/=?^`{|}~-]+@[\w-]+(?:\.[\w-]+)*\b");
  static final url = RegExp(
      r"http[s]?:\/\/(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+");
  static final bold = RegExp(r"\*\*[^\*]+\*\*", multiLine: true);
  static final italic = RegExp(r"~~[^~]+~~", multiLine: true);
  static final underline = RegExp(r"__[^_]+__", multiLine: true);
  static final strikeThrough = RegExp(r"--[^-]+--", multiLine: true);
  static final h4 = RegExp(r"^!!!![^\n]+$", dotAll: true, multiLine: true);
  static final h3 = RegExp(r"^!!![^\n]+$", dotAll: true, multiLine: true);
  static final h2 = RegExp(r"^!![^\n]+$", dotAll: true, multiLine: true);
  static final h1 = RegExp(r"^![^\n]+$", dotAll: true, multiLine: true);
  static final line = RegExp(r"^.+$", dotAll: true, multiLine: true);
  static final namedUrl =
      RegExp("\\[([\\w\\d\\s]+)\\]\\((${url.pattern})\\)", multiLine: true);
  static final numberItem = RegExp(
    r"(^\s*)(\d+)\.(.+)$",
    dotAll: true,
    multiLine: true,
  );
  static final listItem = RegExp(
    r"^(\s*)(-+)(.+)$",
    dotAll: true,
    multiLine: true,
  );
}

class ParserMapping {
  final RegExp pattern;
  final InlineSpan Function(String, dynamic) result;

  const ParserMapping({required this.pattern, required this.result});

  static InlineSpan defaultMap(String s, dynamic c) =>
      TextSpan(text: s, style: null);

  static ParserMapping email(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.email, result: f);
  }

  static ParserMapping url(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.url, result: f);
  }

  static ParserMapping namedUrl(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.namedUrl, result: f);
  }

  static ParserMapping bold(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.bold, result: f);
  }

  static ParserMapping italic(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.italic, result: f);
  }

  static ParserMapping underline(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.underline, result: f);
  }

  static ParserMapping strikeThrough(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.strikeThrough, result: f);
  }

  static ParserMapping h1(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.h1, result: f);
  }

  static ParserMapping h2(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.h2, result: f);
  }

  static ParserMapping h3(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.h3, result: f);
  }

  static ParserMapping h4(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.h4, result: f);
  }

  static ParserMapping numberItem(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.numberItem, result: f);
  }

  static ParserMapping listItem(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.listItem, result: f);
  }
}

class Parser {
  final List<ParserMapping> mappings;
  final InlineSpan Function(String, dynamic) defaultMap;
  final TextStyle defaultTextStyle;

  Parser(
      {required this.mappings, required this.defaultMap, TextStyle? textStyle})
      : defaultTextStyle = textStyle ??
            const TextStyle(
              fontFamily: "Helvetica",
              fontWeight: FontWeight.normal,
              color: Colors.white,
            );

  TextSpan parse(String text, dynamic context) {
    var result = <InlineSpan>[];
    var count = 10000;
    while (text.isNotEmpty) {
      count -= 1;
      if (count <= 0) {
        break;
      }
      var minIndex = text.length;
      var endIndex = 0;
      var mapper = defaultMap;
      var mapIndex = 0;
      var currentIndex = 0;
      for (final map in mappings) {
        final match = map.pattern.firstMatch(text);
        if (match != null) {
          if (match.start < minIndex) {
            minIndex = match.start;
            endIndex = match.end;
            mapper = map.result;
            mapIndex = currentIndex;
          }
        }
        currentIndex += 1;
      }
      if (minIndex < text.length) {
        if (minIndex > 0) {
          final t = text.substring(0, minIndex);
          result.add(defaultMap(t, context));
        }
        final s = text.substring(minIndex, endIndex);
        var f = mapper(s, context);
        if (f is TextSpan) {
          f = parseTextSpan(f, context);
        }
        result.add(f);
        text = text.substring(endIndex);
      } else {
        result.add(defaultMap(text, context));
        text = "";
      }
    }
    return TextSpan(style: defaultTextStyle, children: result);
  }

  InlineSpan parseTextSpan(TextSpan text, dynamic context) {
    var result = <InlineSpan>[];
    var count = 10000;
    var rawText = text.toPlainText();
    var rawStyle = text.style;
    while (rawText.isNotEmpty) {
      count -= 1;
      if (count <= 0) {
        break;
      }
      var minIndex = rawText.length;
      var endIndex = 0;
      var mapper = defaultMap;
      var mapIndex = 0;
      var currentIndex = 0;
      for (final map in mappings) {
        final match = map.pattern.firstMatch(rawText);
        if (match != null) {
          if (match.start < minIndex) {
            minIndex = match.start;
            endIndex = match.end;
            mapper = map.result;
            mapIndex = currentIndex;
          }
        }
        currentIndex += 1;
      }
      if (minIndex < rawText.length) {
        if (minIndex > 0) {
          final t = rawText.substring(0, minIndex);
          result.add(defaultMap(t, context));
        }
        final s = rawText.substring(minIndex, endIndex);
        context["style"] = rawStyle;
        var f = mapper(s, context);
        if (f is TextSpan && rawText != s) {
          f = parseTextSpan(f, context);
        }
        result.add(f);
        rawText = rawText.substring(endIndex);
      } else {
        result.add(defaultMap(rawText, context));
        rawText = "";
      }
    }
    return TextSpan(style: rawStyle, children: result);
  }

  static Parser url = Parser(
      mappings: [ParserMapping.url(ParserMapping.defaultMap)],
      defaultMap: ParserMapping.defaultMap);

  static Parser basic(TextStyle style) => Parser(
      textStyle: style,
      mappings: [
        ParserMapping.email(ParserMapping.defaultMap),
        ParserMapping.url(
          (s, c) {
            // FIXME: Check header if url is image
            if (s.endsWith(".jpg") || s.endsWith(".png")) {
              final m = min(c["w"] as double, c["h"] as double);
              final img = Image.network(
                s,
                width: m * 0.75,
                errorBuilder: (context, error, stackTrace) =>
                    SizedBox(width: m * 0.75),
              );
              final clip = ClipRRect(
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: img,
              );
              return WidgetSpan(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(child: clip),
                ),
              );
            } else {
              var newStyle =
                  const TextStyle(decoration: TextDecoration.underline);
              if (c["style"] is TextStyle) {
                newStyle = merge(c["style"], newStyle);
              }
              final text = Text(s, style: newStyle);
              final well = InkWell(
                child: text,
                onTap: () => launchURL(s),
              );
              return WidgetSpan(child: well);
            }
          },
        ),
        ParserMapping.namedUrl((s, c) {
          final match = RegexPatterns.namedUrl.firstMatch(s);
          if (match != null) {
            final name = match.group(1) ?? "";
            final url = match.group(2);
            var newStyle =
                const TextStyle(decoration: TextDecoration.underline);
            if (c["style"] is TextStyle) {
              newStyle = merge(c["style"], newStyle);
            }
            final text = Text(name, style: newStyle);
            final well = InkWell(
              child: text,
              onTap: () => launchURL(url ?? ""),
            );
            return WidgetSpan(child: well);
          } else {
            return TextSpan(text: s);
          }
        }),
        ParserMapping.h4((s, c) {
          var newStyle = const TextStyle(fontSize: 18);
          if (c["style"] is TextStyle) {
            newStyle = merge(c["style"], newStyle);
          }
          return TextSpan(text: s.substring(4), style: newStyle);
        }),
        ParserMapping.h3((s, c) {
          var newStyle = const TextStyle(fontSize: 20);
          if (c["style"] is TextStyle) {
            newStyle = merge(c["style"], newStyle);
          }
          return TextSpan(text: s.substring(3), style: newStyle);
        }),
        ParserMapping.h2((s, c) {
          var newStyle = const TextStyle(fontSize: 22);
          if (c["style"] is TextStyle) {
            newStyle = merge(c["style"], newStyle);
          }
          return TextSpan(text: s.substring(2), style: newStyle);
        }),
        ParserMapping.h1((s, c) {
          var newStyle = const TextStyle(fontSize: 24);
          if (c["style"] is TextStyle) {
            newStyle = merge(c["style"], newStyle);
          }
          return TextSpan(text: s.substring(1), style: newStyle);
        }),
        ParserMapping.bold((s, c) {
          var newStyle = const TextStyle(fontWeight: FontWeight.bold);
          if (c["style"] is TextStyle) {
            newStyle = merge(c["style"], newStyle);
          }
          return TextSpan(text: s.substring(2, s.length - 2), style: newStyle);
        }),
        ParserMapping.italic((s, c) {
          var newStyle = const TextStyle(fontStyle: FontStyle.italic);
          if (c["style"] is TextStyle) {
            newStyle = merge(c["style"], newStyle);
          }
          return TextSpan(text: s.substring(2, s.length - 2), style: newStyle);
        }),
        ParserMapping.underline((s, c) {
          var newStyle = const TextStyle(decoration: TextDecoration.underline);
          if (c["style"] is TextStyle) {
            newStyle = merge(c["style"], newStyle);
          }
          return TextSpan(text: s.substring(2, s.length - 2), style: newStyle);
        }),
        ParserMapping.strikeThrough((s, c) {
          var newStyle =
              const TextStyle(decoration: TextDecoration.lineThrough);
          if (c["style"] is TextStyle) {
            newStyle = merge(c["style"], newStyle);
          }
          return TextSpan(text: s.substring(2, s.length - 2), style: newStyle);
        }),
        ParserMapping.listItem((s, c) {
          final match = RegexPatterns.listItem.firstMatch(s);
          if (match != null) {
            final indent = match.group(1) ?? "";
            final number = match.group(2) ?? "";
            final content = match.group(3) ?? "";
            final text = TextSpan(
              text: " ",
              children: [
                const TextSpan(text: "● "),
                TextSpan(text: content),
              ],
            );
            return text;
          } else {
            return TextSpan(text: s);
          }
        }),
      ],
      defaultMap: ParserMapping.defaultMap);
}
