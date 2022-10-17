import 'package:flutter/foundation.dart';
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
