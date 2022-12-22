import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';

class MyTheme {
  static var primary = Colors.blueGrey;
  static var mode = ThemeMode.dark;
  static var safe = true;
  static get isDark =>
      MyTheme.mode == ThemeMode.dark ||
      (MyTheme.mode == ThemeMode.system && SystemTheme.isDarkMode);

  static void loadThemeData() {
    SharedPreferences.getInstance().then((value) {
      final color = value.getInt("theme:color") ?? 16;
      final mode = value.getInt("theme:mode") ?? 1;
      MyTheme.safe = value.getBool("theme:safe") ?? true;

      switch (color) {
        case 0:
          MyTheme.primary = Colors.purple;
          break;
        case 1:
          MyTheme.primary = Colors.pink;
          break;
        case 2:
          MyTheme.primary = Colors.red;
          break;
        case 3:
          MyTheme.primary = Colors.deepOrange;
          break;
        case 4:
          MyTheme.primary = Colors.orange;
          break;
        case 5:
          MyTheme.primary = Colors.amber;
          break;
        case 6:
          MyTheme.primary = Colors.lime;
          break;
        case 7:
          MyTheme.primary = Colors.lightGreen;
          break;
        case 8:
          MyTheme.primary = Colors.green;
          break;
        case 9:
          MyTheme.primary = Colors.teal;
          break;
        case 10:
          MyTheme.primary = Colors.deepPurple;
          break;
        case 11:
          MyTheme.primary = Colors.indigo;
          break;
        case 12:
          MyTheme.primary = Colors.blue;
          break;
        case 13:
          MyTheme.primary = Colors.lightBlue;
          break;
        case 14:
          MyTheme.primary = Colors.cyan;
          break;
        case 15:
          MyTheme.primary = Colors.brown;
          break;
        case 16:
          MyTheme.primary = Colors.blueGrey;
          break;
        case 17:
          MyTheme.primary = Colors.grey;
          break;
      }

      switch (mode) {
        case 0:
          MyTheme.mode = ThemeMode.system;
          break;
        case 1:
          MyTheme.mode = ThemeMode.dark;
          break;
        case 2:
          MyTheme.mode = ThemeMode.light;
          break;
      }
    });
  }
}
