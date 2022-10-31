import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class RegexPatterns {
  static final email =
      RegExp(r"\b[\w.!#$%&’*+\/=?^`{|}~-]+@[\w-]+(?:\.[\w-]+)*\b");
  static final url = RegExp(
      r"http[s]?:\/\/(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+");
  static final bold = RegExp(r"\*\*[^\*]+\*\*", multiLine: true);
  static final italic = RegExp(r"\{\{[^\}]+\}\}", multiLine: true);
  static final underline = RegExp(r"__[^_]+__", multiLine: true);
  static final strikeThrough = RegExp(r"--[^-]+--", multiLine: true);
  static final h1 = RegExp(r"^![^\n]+$", dotAll: true, multiLine: true);
  static final h2 = RegExp(r"^!![^\n]+$", dotAll: true, multiLine: true);
  static final h3 = RegExp(r"^!!![^\n]+$", dotAll: true, multiLine: true);
  static final h4 = RegExp(r"^!!!![^\n]+$", dotAll: true, multiLine: true);
  static final line = RegExp(r"^.+$", dotAll: true, multiLine: true);
  static final namedUrl =
      RegExp("\\[([\\w\\d\\s]+)\\]\\((${url.pattern})\\)", multiLine: true);
  static final numberItem = RegExp(
    r"(^\s*)(\d+)\.(.+)$",
    dotAll: true,
    multiLine: true,
  );
  static final listItem = RegExp(
    r"^(\s*)(-+)\.(.+)$",
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
        final f = mapper(s, context);
        result.add(f);
        text = text.substring(endIndex);
      } else {
        result.add(defaultMap(text, context));
        text = "";
      }
    }
    return TextSpan(style: defaultTextStyle, children: result);
  }

  static Parser url = Parser(
      mappings: [ParserMapping.url(ParserMapping.defaultMap)],
      defaultMap: ParserMapping.defaultMap);

  static Parser basic = Parser(mappings: [
    ParserMapping.email(ParserMapping.defaultMap),
    ParserMapping.url(
      (s, c) {
        // FIXME: Check header if url is image
        if (s.endsWith(".jpg") || s.endsWith(".png")) {
          final m = min(c["w"] as double, c["h"] as double);
          final img = Image.network(s, width: m * 0.75);
          final clip = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: img,
          );
          return WidgetSpan(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: clip),
            ),
          );
        } else {
          final text = Text(
            s,
            style: const TextStyle(decoration: TextDecoration.underline),
          );
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
        final text = Text(
          name,
          style: const TextStyle(decoration: TextDecoration.underline),
        );
        final well = InkWell(
          child: text,
          onTap: () => launchURL(url ?? ""),
        );
        return WidgetSpan(child: well);
      } else {
        return TextSpan(text: s);
      }
    }),
    ParserMapping.h1((s, c) {
      return TextSpan(
        text: s.substring(1), // remove !
        style: const TextStyle(fontSize: 24),
      );
    }),
    ParserMapping.h2((s, c) {
      return TextSpan(
        text: s.substring(2),
        style: const TextStyle(fontSize: 22),
      );
    }),
    ParserMapping.h3((s, c) {
      return TextSpan(
        text: s.substring(2),
        style: const TextStyle(fontSize: 20),
      );
    }),
    ParserMapping.h4((s, c) {
      return TextSpan(
        text: s.substring(2),
        style: const TextStyle(fontSize: 18),
      );
    }),
    ParserMapping.bold((s, c) {
      return TextSpan(
        text: s.substring(2, s.length - 2),
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }),
    ParserMapping.italic((s, c) {
      return TextSpan(
        text: s.substring(2, s.length - 2),
        style: const TextStyle(fontStyle: FontStyle.italic),
      );
    }),
    ParserMapping.underline((s, c) {
      return TextSpan(
        text: s.substring(2, s.length - 2),
        style: const TextStyle(decoration: TextDecoration.underline),
      );
    }),
    ParserMapping.strikeThrough((s, c) {
      return TextSpan(
        text: s.substring(2, s.length - 2),
        style: const TextStyle(decoration: TextDecoration.lineThrough),
      );
    }),
    ParserMapping.numberItem((s, c) {
      final match = RegexPatterns.namedUrl.firstMatch(s);
      if (match != null) {
        final indent = match.group(1) ?? "";
        final number = match.group(2) ?? "";
        final content = match.group(3) ?? "";
        final text = TextSpan(
          text: " ",
          children: [
            TextSpan(text: number),
            TextSpan(text: content),
          ],
        );
        return text;
      } else {
        return TextSpan(text: s);
      }
    }),
  ], defaultMap: ParserMapping.defaultMap);
}
