import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:social_news_app/login.dart';
import 'package:social_news_app/model/geo.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Geo.init();
  Get.updateLocale(Get.deviceLocale ?? Locale("en", "US"));
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
      title: TRGeneral.newSource,
      debugShowCheckedModeBanner: false,
      scrollBehavior: TouchAndMouseScrollBehaviour(),
      theme: ThemeData(
        primarySwatch: MyTheme.primary,
        brightness: MyTheme.isDark ? Brightness.dark : Brightness.light,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(TRGeneral.newSource),
        ),
        body: const LoginPage(),
      ),
    );
  }
}
