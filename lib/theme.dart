import 'package:flutter/foundation.dart';
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
}
