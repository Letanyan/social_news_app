import 'package:flutter/material.dart';

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
        headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
        bodyText1: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
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
}
