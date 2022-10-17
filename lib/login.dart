import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/model/new_source.dart';

import 'model/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var usernameController = TextEditingController();
  var passwordController = TextEditingController();
  var isLoading = false;
  late BuildContext _context;

  void signIn() async {
    final username = usernameController.text == ""
        ? "ribet@yahoo.com"
        : usernameController.text;
    final password =
        passwordController.text == "" ? "123456" : passwordController.text;

    final body = json.encode({"email": username, "password": password});

    setState(() {
      isLoading = true;
    });

    try {
      User.current = await NewSource.signInUser(username, password);
    } catch (e) {
      ScaffoldMessenger.of(_context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        isLoading = false;
      });
      if (User.current != null) {
        Navigator.push(_context,
            MaterialPageRoute(builder: (context) => const HomeView()));
      }
    }
  }

  void signInGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email']);
    final account = await googleSignIn.signIn();

    print(account?.email ?? "??");
  }

  void signInApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(scopes: [
      AppleIDAuthorizationScopes.email,
    ]);
    print(credential);
  }

  Widget _getIndicator() {
    if (isLoading) {
      return const CircularProgressIndicator();
    } else {
      return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    final s = MediaQuery.of(context).size;

    var username = TextField(
      controller: usernameController,
      decoration: const InputDecoration(labelText: "Username"),
    );
    var password = TextField(
      controller: passwordController,
      obscureText: true,
      decoration: const InputDecoration(labelText: "Password"),
    );

    var signInWithApple = TextButton(
        onPressed: signInApple, child: const Text("Sign In With Apple"));
    var signInWithGoole = TextButton(
        onPressed: signInGoogle, child: const Text("Sign In With Google"));
    var signInWithEmail =
        TextButton(onPressed: signIn, child: const Text("Sign In"));
    var signUp = TextButton(onPressed: () {}, child: Text("Sign Up"));
    var forgot = TextButton(
        onPressed: signIn,
        child: const Text("Forgot Password",
            style: TextStyle(
                color: Color.fromARGB(255, 64, 64, 64), fontSize: 9)));

    var form = Column(children: [
      username,
      password,
      const Spacer(flex: 1),
      signInWithEmail,
      signUp,
      forgot,
      const Spacer(flex: 1),
      signInWithGoole,
      signInWithApple
    ]);

    return Stack(
      children: [
        Center(child: _getIndicator()),
        Center(
          child: SizedBox(
            width: s.width * 0.8,
            height: s.height * 0.33,
            child: form,
          ),
        ),
      ],
    );
  }
}
