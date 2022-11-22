import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:social_news_app/account.dart';
import 'package:http/http.dart' as http;

import 'package:social_news_app/email_verification_page.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/mod_packages/sign_button.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/sign_up.dart';

import 'model/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var originController = TextEditingController();
  var isLoading = false;

  @override
  void initState() {
    super.initState();
    checkStoredUser();
  }

  Future<void> checkStoredUser() async {
    User savedUser = await User.fromStore();
    if (savedUser.id != 0 && savedUser.secret.isNotEmpty) {
      User.current = savedUser;
      openApp();
      try {
        final user = await NewSource.getUser(savedUser.id);
        user.secret = savedUser.secret;
        User.current = user;
      } catch (e) {
        print(e);
      }
    }
  }

  void openApp() {
    setState(() {
      isLoading = false;
    });
    if (User.current != null) {
      if (User.current?.validationKey != 0) {
        Navigator.pop(context);
        Navigator.push(
          context,
          route(builder: (context) => const EmailVerificationPage()),
        );
      } else {
        Navigator.pop(context);
        Navigator.push(
          context,
          route(builder: (context) => const HomeView()),
        );
      }
    }
  }

  void signInTemplate(String email, String password) async {
    try {
      final user = await NewSource.signInUser(email, password);
      User.current = user;
      user.storeUser();
    } catch (e) {
      late final String message;
      if (e.toString() == "missing") {
        // if email not in database
        gotoSignUpPage();
        return;
      } else if (e.toString() == "incorrect") {
        message = "Incorrect password or email address";
      } else {
        message = e.toString();
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      openApp();
    }
  }

  void signIn() async {
    final email =
        emailController.text == "" ? "ribet@yahoo.com" : emailController.text;
    final password =
        passwordController.text == "" ? "123456" : passwordController.text;

    if (email.isEmpty) {
      gotoSignUpPage();
    }

    setState(() {
      isLoading = true;
    });

    signInTemplate(email, password);
  }

  void signInAnon() {
    Navigator.pop(context);
    Navigator.push(
      context,
      route(builder: (context) => const HomeView()),
    );
  }

  void signInGoogle() async {
    setState(() {
      isLoading = true;
    });

    final auth = await AuthService.instance.login(GOOGLE_ISSUER);

    if (auth) {
      openApp();
    }
  }

  void signInApple() async {
    setState(() {
      isLoading = true;
    });

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: "com.letanyan.newsourceserviceid",
            redirectUri: Uri.parse(
                "https://new-source-server-mhvly.ondigitalocean.app/api/v1/auth/callbacks/sign-in-with-apple"),
          ));

      final user =
          await NewSource.signInUserApple(credential.authorizationCode);

      if (user.id != 0) {
        user.storeUser();
        User.current = user;
        openApp();
      }
    } catch (e) {
      print(e);
    }
  }

  Widget _getIndicator() {
    if (isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [CircularProgressIndicator()],
      );
    } else {
      return const SizedBox();
    }
  }

  void gotoSignUpPage() {
    final page = Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: const SignUpPage(),
    );

    Navigator.push(context, route(builder: (c) => page));
  }

  @override
  Widget build(BuildContext context) {
    var email = TextField(
      controller: emailController,
      decoration: const InputDecoration(labelText: "Email"),
    );
    var password = TextField(
      controller: passwordController,
      obscureText: true,
      decoration: const InputDecoration(labelText: "Password"),
    );
    var emailRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 0, maxWidth: 320),
          child: email,
        ),
      ],
    );
    var passwordRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 0, maxWidth: 320),
          child: password,
        ),
      ],
    );
    var signInWithApple = SignInButton(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8))),
      buttonType: MyTheme.isDark ? ButtonType.apple : ButtonType.appleDark,
      onPressed: signInApple,
    );
    var signInWithGoogle = SignInButton(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8))),
      buttonType: MyTheme.isDark ? ButtonType.google : ButtonType.googleDark,
      onPressed: signInGoogle,
    );
    var signInWithEmail = SignInButton(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8))),
      buttonType: MyTheme.isDark ? ButtonType.email : ButtonType.emailDark,
      onPressed: signIn,
    );
    var forgot = TextButton(
      onPressed: signIn,
      child: Text(
        "Forgot Password",
        style: TextStyle(
          color: MyTheme.isDark ? Colors.grey[200] : Colors.grey[800],
          fontSize: 9,
        ),
      ),
    );
    final createAccount = TextButton(
      onPressed: gotoSignUpPage,
      child: Text(
        "Create Account",
        style: TextStyle(
          color: MyTheme.isDark ? Colors.grey[200] : Colors.grey[800],
          fontSize: 12,
        ),
      ),
    );
    var anon = TextButton(
      onPressed: signInAnon,
      child: Text(
        "Just Browse",
        style: TextStyle(color: MyTheme.isDark ? Colors.white : Colors.black),
      ),
    );

    var form = Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              signInWithGoogle,
              const SizedBox(height: 8),
              signInWithApple,
            ],
          ),
        ),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              emailRow,
              passwordRow,
              const SizedBox(height: 16),
              Center(child: signInWithEmail),
              const SizedBox(height: 8),
              Center(child: createAccount),
              Center(child: forgot),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: anon,
        ),
      ],
    );

    return form;
  }
}
