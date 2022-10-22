import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:social_news_app/email_verification_page.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/signup.dart';

import 'model/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var isLoading = false;
  late BuildContext _context;

  void signIn() async {
    final email =
        emailController.text == "" ? "ribet@yahoo.com" : emailController.text;
    final password =
        passwordController.text == "" ? "123456" : passwordController.text;

    setState(() {
      isLoading = true;
    });

    try {
      User.current = await NewSource.signInUser(email, password);
    } catch (e) {
      ScaffoldMessenger.of(_context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        isLoading = false;
      });
      if (User.current != null) {
        if (User.current?.ValidationKey != 0) {
          Navigator.push(
            _context,
            MaterialPageRoute(
                builder: (context) => const EmailVerificationPage()),
          );
        } else {
          Navigator.push(
            _context,
            MaterialPageRoute(builder: (context) => const HomeView()),
          );
        }
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

  void gotoSignUpPage() {
    final page = Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: const SignUpPage(),
    );

    Navigator.push(context, MaterialPageRoute(builder: (c) => page));
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    final s = MediaQuery.of(context).size;

    var email = TextField(
      controller: emailController,
      decoration: const InputDecoration(labelText: "Email"),
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
    var signUp = TextButton(onPressed: gotoSignUpPage, child: Text("Sign Up"));
    var forgot = TextButton(
        onPressed: signIn,
        child: const Text("Forgot Password",
            style: TextStyle(
                color: Color.fromARGB(255, 64, 64, 64), fontSize: 9)));

    var form = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        email,
        password,
        const SizedBox(height: 8),
        Center(child: signInWithEmail),
        Center(child: signUp),
        Center(child: forgot),
        const SizedBox(height: 8),
        Center(child: signInWithGoole),
        Center(child: signInWithApple)
      ],
    );

    return form;
  }
}
