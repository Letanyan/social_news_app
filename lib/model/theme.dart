import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';

class MyTheme {
  static final light = ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blue[400]!,
      primaryColorLight: Colors.grey[400],
      primaryColorDark: Colors.blueGrey[400]!,
      bottomNavigationBarTheme:
          const BottomNavigationBarThemeData(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      bottomAppBarColor: Colors.white,
      fontFamily: 'Georgia',
      textTheme: const TextTheme(
        headline1: TextStyle(
            fontSize: 32, fontFamily: 'SF', fontWeight: FontWeight.w900),
        headline2: TextStyle(
            fontSize: 30, fontFamily: 'SF', fontWeight: FontWeight.w800),
        headline3: TextStyle(
            fontSize: 28, fontFamily: 'SF', fontWeight: FontWeight.w700),
        headline4: TextStyle(
            fontSize: 26, fontFamily: 'SF', fontWeight: FontWeight.w600),
        headline5: TextStyle(
            fontSize: 24, fontFamily: 'SF', fontWeight: FontWeight.w500),
        headline6: TextStyle(
            fontSize: 22, fontFamily: 'SF', fontWeight: FontWeight.w400),
        bodyText1: TextStyle(
            fontSize: 18, fontFamily: 'SF', fontWeight: FontWeight.w400),
        bodyText2: TextStyle(
            fontSize: 18, fontFamily: 'SF', fontWeight: FontWeight.bold),
        subtitle2: TextStyle(
            fontSize: 18,
            fontFamily: 'SF',
            fontWeight: FontWeight.w300,
            decoration: TextDecoration.underline),
        caption: TextStyle(
          fontSize: 18,
          fontFamily: 'SF',
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
        ),
      ));

  static final dark = ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.red,
      fontFamily: 'Georgia',
      textTheme: const TextTheme(
        headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
        bodyText1: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
      ));

  static var current = light;

  static var primary = Colors.pink;
  static var mode = ThemeMode.system;
  static var safe = true;
  static get isDark =>
      MyTheme.mode == ThemeMode.dark ||
      (MyTheme.mode == ThemeMode.system && SystemTheme.isDarkMode);

  static void loadThemeData() {
    SharedPreferences.getInstance().then((value) {
      final color = value.getInt("theme:color") ?? 1;
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
