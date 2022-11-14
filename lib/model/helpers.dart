import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:url_launcher/url_launcher_string.dart';

bool targetPlatformIsMobile() {
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

bool targetPlatformIsDesktop() {
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

Future<void> launchURL(String url) async {
  if (url == "") {
    return;
  }
  if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
    throw err("Could not launch website");
  }
}

String formatDate(DateTime date) {
  final today = DateTime.now();
  date = date.toLocal();
  final sameYear = today.year == date.year;
  final sameMonth = today.month == date.month;
  final sameDay = today.day == date.day;

  if (sameYear) {
    if (sameMonth) {
      if (sameDay) {
        return "Today";
      } else if ((today.day - date.day).abs() == 1) {
        return "Yesterday";
      } else if ((today.day - date.day).abs() < 7) {
        return "Last ${DateFormat.EEEE().format(date)}";
      } else {
        return DateFormat.MMMEd().format(date);
      }
    } else {
      return DateFormat.MMMEd().format(date);
    }
  } else {
    return DateFormat.yMMMMd().format(date);
  }
}

String formatDateTime(DateTime date) {
  final today = DateTime.now();
  date = date.toLocal();

  final sameYear = today.day - date.day < 365;
  final sameMonth = today.day - date.day < 30;
  final sameDay = (today.millisecondsSinceEpoch - date.millisecondsSinceEpoch) <
      1000 * 60 * 60 * 24;
  final sameHour =
      (today.millisecondsSinceEpoch - date.millisecondsSinceEpoch) <
          1000 * 60 * 60;

  final diff = today.difference(date);

  if (sameYear) {
    if (sameMonth) {
      if (sameDay) {
        if (sameHour) {
          return "${diff.inMinutes}m";
        } else {
          return "${diff.inHours}h";
        }
      } else {
        return "${diff.inDays}d";
      }
    } else {
      return "${diff.inDays / 30}mon";
    }
  } else {
    return "${diff.inDays / 365}y";
  }
}

DateTime endOfDay(DateTime d) {
  return DateTime(d.year, d.month, d.day, 23, 59, 59);
}

DateTime startOfDay(DateTime d) {
  return DateTime(d.year, d.month, d.day);
}

bool isTypeEqual<S, T>() => S == T;

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

TextStyle merge(TextStyle base, TextStyle? other) {
  if (other == null) {
    return base;
  }

  String? mergedDebugLabel;
  assert(() {
    if (other.debugLabel != null || base.debugLabel != null) {
      mergedDebugLabel =
          '(${base.debugLabel ?? "_kDefaultDebugLabel"}).merge(${other.debugLabel ?? "_kDefaultDebugLabel"})';
    }
    return true;
  }());

  return base.copyWith(
    color: other.color,
    backgroundColor: other.backgroundColor,
    fontSize: other.fontSize,
    fontWeight: other.fontWeight,
    fontStyle: other.fontStyle,
    letterSpacing: other.letterSpacing,
    wordSpacing: other.wordSpacing,
    textBaseline: other.textBaseline,
    height: other.height,
    leadingDistribution: other.leadingDistribution,
    locale: other.locale,
    foreground: other.foreground,
    background: other.background,
    shadows: other.shadows,
    fontFeatures: (base.fontFeatures ?? []) + (other.fontFeatures ?? []),
    fontVariations: (base.fontVariations ?? []) + (other.fontVariations ?? []),
    decoration: TextDecoration.combine([
      base.decoration ?? TextDecoration.none,
      other.decoration ?? TextDecoration.none,
    ]),
    decorationColor: other.decorationColor,
    decorationStyle: other.decorationStyle,
    decorationThickness: other.decorationThickness,
    debugLabel: mergedDebugLabel,
    fontFamily: other.fontFamily,
    fontFamilyFallback: other.fontFamilyFallback,
    // package: other.package,
    overflow: other.overflow,
  );
}

List<T> jsonArrayTo<T>(
    dynamic list, T Function(Map<String, dynamic> json) map) {
  var result = <T>[];
  for (final item in list) {
    final p = map(item);
    result.add(p);
  }
  return result;
}

PageRoute route({required Widget Function(BuildContext) builder}) {
  try {
    if (Platform.isIOS) {
      return CupertinoPageRoute(builder: builder);
    } else if (Platform.isAndroid) {
      return MaterialPageRoute(builder: builder);
    }
    return MaterialPageRoute(builder: builder);
  } catch (e) {
    return MaterialPageRoute(builder: builder);
  }
}
