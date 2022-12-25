import 'package:flutter/material.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/mod_packages/sign_button.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/parser.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/onboard.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  var usernameController = TextEditingController();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var passwordValidateController = TextEditingController();
  var isLoading = false;

  bool validateLength(String name, String value, int min, int max) {
    if (value.length > max) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(TRSignUp.tooLong(name, max))));
      return false;
    }
    if (value.length < min) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(TRSignUp.tooShort(name, min))));
      return false;
    }
    return true;
  }

  void signUp(BuildContext context) async {
    try {
      final p1 = passwordController.text;
      final p2 = passwordValidateController.text;
      final un = usernameController.text;
      final em = emailController.text;

      if (p1 != p2) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(TRSignUp.passwordMismatch)));
        return;
      }
      if (!validateLength(TRGeneral.displayName.toLowerCase(), un, 3, 15)) {
        return;
      }
      if (!validateLength(TRGeneral.password.toLowerCase(), p1, 8, 2048)) {
        return;
      }
      if (!RegexPatterns.email.hasMatch(em)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(TRSignUp.emailInvalid)));
        return;
      }

      setState(() {
        isLoading = true;
      });
      final user = await NewSource.signUpUser(un, em, p1);
      User.current = user;
    } catch (e) {
      displayError(context, e);
    } finally {
      setState(() {
        isLoading = false;
      });
      if (User.current != null) {
        if (User.current?.validationKey != 0) {
          Navigator.push(
            context,
            route(builder: (context) => const Onboard()),
          );
        } else {
          Navigator.push(
            context,
            route(builder: (context) => const HomeView()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var username = TextField(
      controller: usernameController,
      decoration: InputDecoration(labelText: TRGeneral.displayName.toTitleCase),
    );
    var email = TextField(
      controller: emailController,
      decoration: InputDecoration(labelText: TRGeneral.email.toTitleCase),
    );
    var password = TextField(
      controller: passwordController,
      obscureText: true,
      decoration: InputDecoration(labelText: TRGeneral.password.toTitleCase),
    );
    var passwordValidate = TextField(
      controller: passwordValidateController,
      obscureText: true,
      decoration:
          InputDecoration(labelText: TRGeneral.renterPassword.toTitleCase),
    );
    var create = SignInButton(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8))),
      buttonType: MyTheme.isDark ? ButtonType.account : ButtonType.accountDark,
      onPressed: () async => signUp(context),
    );

    final usernameRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 0, maxWidth: 320),
          child: username,
        ),
      ],
    );
    final emailRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 0, maxWidth: 320),
          child: email,
        ),
      ],
    );
    final passwordRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 0, maxWidth: 320),
          child: password,
        ),
      ],
    );
    final passwordValidateRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 0, maxWidth: 320),
          child: passwordValidate,
        ),
      ],
    );

    final body = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        emailRow,
        usernameRow,
        const SizedBox(height: 8),
        passwordRow,
        passwordValidateRow,
        const SizedBox(height: 16),
        create,
      ],
    );

    final list = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Flexible(flex: 25, child: SizedBox()),
        Flexible(flex: 75, child: body),
      ],
    );

    return Padding(padding: const EdgeInsets.all(8), child: list);
  }
}
