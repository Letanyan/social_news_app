
import 'package:flutter/material.dart';
import 'package:social_news_app/login.dart';
import 'package:social_news_app/model/geo.dart';
import 'package:social_news_app/model/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Geo.init();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    MyTheme.loadThemeData();
    return MaterialApp(
      title: 'New Source',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: MyTheme.primary,
        brightness: MyTheme.mode == ThemeMode.light
            ? Brightness.light
            : Brightness.dark,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('New Source'),
        ),
        body: const LoginPage(),
      ),
    );
  }
}
