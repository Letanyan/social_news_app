import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/account_page.dart';

class User {
  final int ID;
  String Name;
  final String Email;
  String Password;
  final DateTime RegisterDate;
  double Upvotes;
  double Downvotes;
  int Credits;
  final int ValidationKey;
  List<Author> following;
  List<Author> ignored;

  User({
    required this.ID,
    required this.Name,
    required this.Email,
    required this.Password,
    required this.RegisterDate,
    required this.Upvotes,
    required this.Downvotes,
    required this.Credits,
    required this.ValidationKey,
  })  : following = [],
        ignored = [];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      ID: json["ID"],
      Name: json["Name"],
      Email: json["Email"],
      Password: json["Password"],
      RegisterDate: DateTime.parse(json["RegisterDate"]),
      Upvotes: json["Upvotes"],
      Downvotes: json["Downvotes"],
      Credits: json["Credits"],
      ValidationKey: json["ValidationKey"],
    );
  }

  static User? current;

  Author toAuthor() {
    return Author(
      ID: ID,
      Name: Name,
      RegisterDate: RegisterDate,
      Upvotes: Upvotes,
      Downvotes: Downvotes,
    );
  }
}

class Author {
  final int ID;
  final String Name;
  final DateTime RegisterDate;
  final double Upvotes;
  final double Downvotes;

  const Author({
    required this.ID,
    required this.Name,
    required this.RegisterDate,
    required this.Upvotes,
    required this.Downvotes,
  });

  factory Author.fromInt(int json) {
    return Author(
      ID: json as int,
      Name: "",
      RegisterDate: DateTime.fromMicrosecondsSinceEpoch(0),
      Upvotes: 0,
      Downvotes: 0,
    );
  }

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      ID: json["ID"],
      Name: json["Name"],
      RegisterDate: DateTime.parse(json["RegisterDate"]),
      Upvotes: json["Upvotes"],
      Downvotes: json["Downvotes"],
    );
  }

  void showUserPage(BuildContext context) {
    final page = Scaffold(
      appBar: AppBar(title: Text(Name)),
      body: AccountPage(user: this),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
