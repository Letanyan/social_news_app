import 'package:flutter/material.dart';

import 'package:social_news_app/email_verification_page.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/model/new_source.dart';
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
        User.current?.following =
            await NewSource.getUserContUsers(user.id, UserContKind.userFollow);
        User.current?.ignored =
            await NewSource.getUserContUsers(user.id, UserContKind.ignored);
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
          MaterialPageRoute(
              builder: (context) => const EmailVerificationPage()),
        );
      } else {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
      }
    }
  }

  void signInTemplate(String email, String password) async {
    try {
      final user = await NewSource.signInUser(email, password);
      User.current = user;
      User.current?.following =
          await NewSource.getUserContUsers(user.id, UserContKind.userFollow);
      User.current?.ignored =
          await NewSource.getUserContUsers(user.id, UserContKind.ignored);
      user.storeUser();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      openApp();
    }
  }

  void signIn() async {
    if (originController.text.isNotEmpty) {
      NewSource.host = originController.text;
    }
    final email =
        emailController.text == "" ? "ribet@yahoo.com" : emailController.text;
    final password =
        passwordController.text == "" ? "123456" : passwordController.text;

    setState(() {
      isLoading = true;
    });

    signInTemplate(email, password);
  }

  void signInGoogle() async {
    // final googleSignIn = GoogleSignIn(scopes: ['email']);
    // final account = await googleSignIn.signIn();

    // print(account?.email ?? "??");
    final email = emailController.text == "" ? "@@" : emailController.text;
    final password = passwordController.text == ""
        ? "AbstractServer8080"
        : passwordController.text;

    setState(() {
      isLoading = true;
    });

    signInTemplate(email, password);
  }

  void signInApple() async {
    // final credential = await SignInWithApple.getAppleIDCredential(scopes: [
    //   AppleIDAuthorizationScopes.email,
    // ]);
    // print(credential);
    final email = emailController.text == ""
        ? "letanyan@icloud.com"
        : emailController.text;
    final password =
        passwordController.text == "" ? "12345678" : passwordController.text;

    setState(() {
      isLoading = true;
    });

    signInTemplate(email, password);
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
    var origin = TextField(
      controller: originController,
      decoration: const InputDecoration(labelText: "Host"),
    );

    var signInWithApple = TextButton(
        onPressed: signInApple, child: const Text("Sign In With Apple"));
    var signInWithGoole = TextButton(
        onPressed: signInGoogle, child: const Text("Sign In With Google"));
    var signInWithEmail =
        TextButton(onPressed: signIn, child: const Text("Sign In"));
    var signUp =
        TextButton(onPressed: gotoSignUpPage, child: const Text("Sign Up"));
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
        Center(child: signInWithApple),
        const SizedBox(height: 8),
        Center(child: origin),
      ],
    );

    return form;
  }
}
