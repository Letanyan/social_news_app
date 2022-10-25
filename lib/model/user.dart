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
  String Secret;

  bool PublicViews;
  bool PublicReadLater;
  bool PublicFollowing;
  bool PublicIgnored;
  bool PublicPostVotes;
  bool PublicCommentVotes;
  bool PublicUserVotes;
  bool PublicTagVotes;

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
    required this.PublicViews,
    required this.PublicReadLater,
    required this.PublicFollowing,
    required this.PublicIgnored,
    required this.PublicPostVotes,
    required this.PublicCommentVotes,
    required this.PublicUserVotes,
    required this.PublicTagVotes,
  })  : following = [],
        ignored = [],
        Secret = "";

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
      PublicViews: json["PublicViews"],
      PublicReadLater: json["PublicReadLater"],
      PublicFollowing: json["PublicFollowing"],
      PublicIgnored: json["PublicIgnored"],
      PublicPostVotes: json["PublicPostVotes"],
      PublicCommentVotes: json["PublicCommentVotes"],
      PublicUserVotes: json["PublicUserVotes"],
      PublicTagVotes: json["PublicTagVotes"],
    );
  }

  factory User.fromSecretJson(Map<String, dynamic> json) {
    final obj = json["user"];
    var user = User(
      ID: obj["ID"],
      Name: obj["Name"],
      Email: obj["Email"],
      Password: obj["Password"],
      RegisterDate: DateTime.parse(obj["RegisterDate"]),
      Upvotes: obj["Upvotes"],
      Downvotes: obj["Downvotes"],
      Credits: obj["Credits"],
      ValidationKey: obj["ValidationKey"],
      PublicViews: obj["PublicViews"],
      PublicReadLater: obj["PublicReadLater"],
      PublicFollowing: obj["PublicFollowing"],
      PublicIgnored: obj["PublicIgnored"],
      PublicPostVotes: obj["PublicPostVotes"],
      PublicCommentVotes: obj["PublicCommentVotes"],
      PublicUserVotes: obj["PublicUserVotes"],
      PublicTagVotes: obj["PublicTagVotes"],
    );
    user.Secret = json["token"];
    return user;
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
