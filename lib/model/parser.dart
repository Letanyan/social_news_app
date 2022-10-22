import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/theme.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class RegexPatterns {
  static final email =
      RegExp(r"\b[\w.!#$%&’*+\/=?^`{|}~-]+@[\w-]+(?:\.[\w-]+)*\b");
  static final url = RegExp(
      r"http[s]?:\/\/(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+");
  static final bold = RegExp(r"\[\[[^\]]+\]\]", dotAll: true, multiLine: true);
  static final italic =
      RegExp(r"\{\{[^\}]+\}\}", dotAll: true, multiLine: true);
  static final underline = RegExp(r"__[^_]+__", dotAll: true, multiLine: true);
}

class ParserMapping {
  final RegExp pattern;
  final InlineSpan Function(String, dynamic) result;

  const ParserMapping({required this.pattern, required this.result});

  static InlineSpan defaultMap(String s, dynamic c) =>
      TextSpan(text: s, style: MyTheme.current.textTheme.bodyText1);

  static ParserMapping email(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.email, result: f);
  }

  static ParserMapping url(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegexPatterns.url, result: f);
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

  static ParserMapping h1(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(
        pattern: RegExp(r"^![^\n]+$", dotAll: true, multiLine: true),
        result: f);
  }

  static ParserMapping h2(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegExp(r"^!!.+$", dotAll: true), result: f);
  }

  static ParserMapping h3(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegExp(r"^!!!.+$", dotAll: true), result: f);
  }

  static ParserMapping h4(InlineSpan Function(String, dynamic) f) {
    return ParserMapping(pattern: RegExp(r"^!!!!.+$", dotAll: true), result: f);
  }
}

class Parser {
  final List<ParserMapping> mappings;
  final InlineSpan Function(String, dynamic) defaultMap;

  Parser({required this.mappings, required this.defaultMap});

  TextSpan parse(String text, dynamic context) {
    var result = TextSpan(text: "", children: []);
    var count = 10000;
    while (text.isNotEmpty) {
      count -= 1;
      if (count <= 0) {
        break;
      }
      var minIndex = text.length;
      var endIndex = 0;
      var mapper = defaultMap;
      for (final map in mappings) {
        final match = map.pattern.firstMatch(text);
        if (match != null) {
          if (match.start < minIndex) {
            minIndex = match.start;
            endIndex = match.end;
            mapper = map.result;
          }
        }
      }
      if (minIndex < text.length) {
        if (minIndex > 0) {
          final t = text.substring(0, minIndex);
          result.children!.add(defaultMap(t, context));
        }
        final s = text.substring(minIndex, endIndex);
        result.children!.add(mapper(s, context));
        text = text.substring(endIndex);
      } else {
        result.children!.add(defaultMap(text, context));
        text = "";
      }
    }
    return result;
  }

  static Parser url = Parser(
      mappings: [ParserMapping.url(ParserMapping.defaultMap)],
      defaultMap: ParserMapping.defaultMap);

  static Parser basic = Parser(mappings: [
    ParserMapping.email(ParserMapping.defaultMap),
    ParserMapping.url(
      (s, c) {
        if (s.endsWith(".jpg")) {
          final m = min(c["w"] as double, c["h"] as double);
          final img = Image.network(
            s,
            // scale: 0.25,
            // width: m * 0.5,
            // height: m * 0.5,
          );
          return WidgetSpan(child: Center(child: img));
        } else {
          final text = TextSpan(
            text: s,
            style: MyTheme.current.textTheme.subtitle1,
          );
          final well = InkWell(
            child: RichText(text: text),
            onTap: () => launchURL(s),
          );
          return WidgetSpan(child: well);
        }
      },
    ),
    ParserMapping.h1((s, c) {
      return TextSpan(
          text: s.substring(1), // remove !
          style: MyTheme.current.textTheme.headline1);
    }),
    ParserMapping.bold((s, c) {
      return TextSpan(
        text: s.substring(2, s.length - 2),
        style: MyTheme.current.textTheme.bodyText2,
      );
    }),
    ParserMapping.italic((s, c) {
      return TextSpan(
        text: s.substring(2, s.length - 2),
        style: MyTheme.current.textTheme.caption,
      );
    }),
    ParserMapping.underline((s, c) {
      return TextSpan(
        text: s.substring(2, s.length - 2),
        style: MyTheme.current.textTheme.subtitle2,
      );
    }),
  ], defaultMap: ParserMapping.defaultMap);
}
