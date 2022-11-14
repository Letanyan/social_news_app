import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/model/helpers.dart';
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
    final message = Parser.basic(defaultStyle).parse(
        "Please click the verification link in the email sent to you "
        "(**${User.current!.email}**). If you did not receive "
        "an email you can resend the link by pressing the "
        "**Resend Verification Link** button below. Ensure that the email is "
        "not in the Junk folder.\n\n"
        "Without having a verified account you will not have functionality "
        "which allows you to participate in the New Source community.",
        {});

    final resend = ElevatedButton(
      onPressed: () async {
        if (User.current == null) {
          return;
        }
        await NewSource.sendVerificationLink(
            User.current!.id, User.current!.email, User.current!.validationKey);
      },
      child: const Text("Resend Verification Link"),
    );

    final ignore = ElevatedButton(
      onPressed: () =>
          Navigator.push(context, route(builder: (c) => const HomeView())),
      child: const Text("Got It"),
    );

    final body = ListView(children: [
      RichText(text: message),
      const SizedBox(height: 32),
      ignore,
      const SizedBox(height: 32),
      resend,
    ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Email Verification"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: body),
    );
  }
}
