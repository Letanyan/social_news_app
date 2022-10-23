import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:url_launcher/url_launcher.dart';
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
  if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
    throw err("Could not launch website");
  }
}

String formatDate(DateTime date) {
  final today = DateTime.now();
  final sameYear = today.year == date.year;
  final sameMonth = today.month == date.month;
  final sameDay = today.day == date.day;

  if (sameYear) {
    if (sameMonth) {
      if (sameDay) {
        return "Today";
      } else if ((today.day - date.day).abs() < 7) {
        return DateFormat.EEEE().format(date);
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
  final sameHour = today.hour == date.hour;
  final sameMinute = today.minute == date.minute;

  final sameYear = today.year == date.year;
  final sameMonth = today.month == date.month;
  final sameDay = today.day == date.day;

  if (sameYear && sameMonth && sameDay) {
    if (sameHour) {
      final diff = today.minute - date.minute;
      if (diff == 1) {
        return "1 Minute Ago";
      } else {
        return "$diff Minutes Ago";
      }
    } else {
      final diff = today.hour - date.hour;
      if (diff == 1) {
        return "1 Hour Ago";
      } else {
        return "$diff Hours Ago";
      }
    }
  } else {
    return formatDate(date);
  }
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
