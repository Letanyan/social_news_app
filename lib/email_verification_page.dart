import 'package:flutter/material.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/parser.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  @override
  Widget build(BuildContext context) {
    if (User.current == null) {
      Navigator.pop(context);
    }
    final isDark = MyTheme.isDark;
    final defaultStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontFamily: "Helvetica",
      fontWeight: FontWeight.normal,
    );
    final message = Parser.basic(defaultStyle)
        .parse(TREmailVerify.message(User.current?.email ?? ""), {});

    final resend = ElevatedButton(
      onPressed: () async {
        if (User.current == null) {
          return;
        }
        await NewSource.sendVerificationLink(
            User.current!.id, User.current!.email, User.current!.validationKey);
      },
      child: Text(TREmailVerify.resend),
    );

    final ignore = ElevatedButton(
      onPressed: () =>
          Navigator.push(context, route(builder: (c) => const HomeView())),
      child: Text(TRGeneral.gotIt),
    );

    final body = ListView(children: [
      RichText(text: message),
      const SizedBox(height: 32),
      ignore,
      const SizedBox(height: 32),
      resend,
    ]);

    final page = Scaffold(
      appBar: AppBar(
        title: Text(TREmailVerify.verifyEmail),
        automaticallyImplyLeading: false,
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: body),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: TouchAndMouseScrollBehaviour(),
      theme: ThemeData(
        primarySwatch: MyTheme.primary,
        brightness: MyTheme.isDark ? Brightness.dark : Brightness.light,
      ),
      home: page,
    );
  }
}
