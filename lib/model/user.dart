import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/main.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/widgets/vote_widget.dart';

class User {
  final int id;
  String name;
  final String email;
  String password;
  final DateTime registerDate;
  int upvotes;
  int downvotes;
  int credits;
  int investment;
  final int validationKey;
  List<Author> following;
  List<Author> ignored;
  List<Tag> favourites;
  List<int> readLater;
  String secret;

  bool publicViews;
  bool publicReadLater;
  bool publicFollowing;
  bool publicIgnored;
  bool publicPostVotes;
  bool publicCommentVotes;
  bool publicUserVotes;
  bool publicTagVotes;
  bool publicTagFollow;

  Future<void>? streakUpdate;
  bool checkedForStreakToday;

  String creditAmount() {
    return credits < 0 ? "..." : "$credits";
  }

  Future<void> storeUser() async {
    final pref = await SharedPreferences.getInstance();
    pref.setInt("user:id", id);
    pref.setString("user:name", name);
    pref.setString("user:email", email);
    pref.setInt("user:register", registerDate.millisecondsSinceEpoch);
    pref.setInt("user:validation", validationKey);
    pref.setString("user:secret", secret);
  }

  static Future<void> removeUser() async {
    final pref = await SharedPreferences.getInstance();
    pref.remove("user:id");
    pref.remove("user:name");
    pref.remove("user:email");
    pref.remove("user:register");
    pref.remove("user:validation");
    pref.remove("user:secret");
    pref.remove("user:cipher");
    pref.remove("theme:color");
    pref.remove("theme:mode");
  }

  static Future<User> fromStore() async {
    final pref = await SharedPreferences.getInstance();
    final id = pref.getInt("user:id") ?? 0;
    final name = pref.getString("user:name") ?? "";
    final email = pref.getString("user:email") ?? "";
    final register =
        DateTime.fromMillisecondsSinceEpoch(pref.getInt("user:register") ?? 0);
    final validation = pref.getInt("user:validation") ?? 0;
    final secret = pref.getString("user:secret") ?? "";
    var result = User(
      id: id,
      name: name,
      email: email,
      password: "",
      registerDate: register,
      upvotes: 0,
      downvotes: 0,
      credits: -1,
      investment: 0,
      validationKey: validation,
      publicViews: false,
      publicReadLater: false,
      publicFollowing: false,
      publicIgnored: false,
      publicPostVotes: false,
      publicCommentVotes: false,
      publicUserVotes: false,
      publicTagVotes: false,
      publicTagFollow: false,
    );
    result.secret = secret;
    return result;
  }

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.registerDate,
    required this.upvotes,
    required this.downvotes,
    required this.credits,
    required this.investment,
    required this.validationKey,
    required this.publicViews,
    required this.publicReadLater,
    required this.publicFollowing,
    required this.publicIgnored,
    required this.publicPostVotes,
    required this.publicCommentVotes,
    required this.publicUserVotes,
    required this.publicTagVotes,
    required this.publicTagFollow,
  })  : following = [],
        ignored = [],
        favourites = [],
        readLater = [],
        secret = "",
        checkedForStreakToday = false;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json["ID"]),
      name: json["Name"],
      email: json["Email"],
      password: json["Password"],
      registerDate: DateTime.parse(json["RegisterDate"]).toLocal(),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
      credits: json["Credits"],
      investment: json["Investment"],
      validationKey: int.parse(json["ValidationKey"]),
      publicViews: json["PublicViews"],
      publicReadLater: json["PublicReadLater"],
      publicFollowing: json["PublicFollowing"],
      publicIgnored: json["PublicIgnored"],
      publicPostVotes: json["PublicPostVotes"],
      publicCommentVotes: json["PublicCommentVotes"],
      publicUserVotes: json["PublicUserVotes"],
      publicTagVotes: json["PublicTagVotes"],
      publicTagFollow: json["PublicTagFollow"],
    );
  }

  factory User.fromSecretJson(Map<String, dynamic> json) {
    final obj = json["user"];
    var user = User(
      id: int.parse(obj["ID"]),
      name: obj["Name"],
      email: obj["Email"],
      password: obj["Password"],
      registerDate: DateTime.parse(obj["RegisterDate"]).toLocal(),
      upvotes: obj["Upvotes"],
      downvotes: obj["Downvotes"],
      credits: obj["Credits"],
      investment: obj["Investment"],
      validationKey: int.parse(obj["ValidationKey"]),
      publicViews: obj["PublicViews"],
      publicReadLater: obj["PublicReadLater"],
      publicFollowing: obj["PublicFollowing"],
      publicIgnored: obj["PublicIgnored"],
      publicPostVotes: obj["PublicPostVotes"],
      publicCommentVotes: obj["PublicCommentVotes"],
      publicUserVotes: obj["PublicUserVotes"],
      publicTagVotes: obj["PublicTagVotes"],
      publicTagFollow: obj["PublicTagFollow"],
    );
    user.secret = json["token"];
    user.following = jsonArrayTo(json["following"], Author.fromJson);
    user.ignored = jsonArrayTo(json["ignored"], Author.fromJson);
    user.favourites = jsonArrayTo(json["tags"], Tag.fromJson);
    checkStreak(user);
    return user;
  }

  static void checkStreak(User user) {
    final n = DateTime.now().toUtc();
    final end = DateTime.utc(n.year, n.month, n.day).add(Duration(days: 1));
    final dur = end.difference(n).inSeconds + 5;
    print("Set up user for streak. Will activate after $dur seconds");
    user.streakUpdate = Future.delayed(Duration(seconds: dur), () async {
      User.updateStreak();
    });
  }

  static void updateStreak() async {
    if (User.current == null) {
      return;
    }
    print("Getting user for streak at ${DateTime.now()}");
    final secret = User.current!.secret;
    try {
      User.current = await NewSource.getUser(User.current!.id);
      User.current!.secret = secret;
    } catch (e) {
      NewSource.signOut(User.current?.id ?? 0).catchError((e) {});
      User.removeUser().then((value) {
        User.current = null;
        Get.offAll(const MainApp());
      });
    }
  }

  static var streakMessage = StreamController<StreakMessage>.broadcast();

  static User? _current;
  static set current(User? user) {
    if (_current?.streakUpdate != null) {
      _current?.streakUpdate?.timeout(Duration(seconds: 0), onTimeout: () {});
    }
    _current = user;
  }

  static User? get current {
    return _current;
  }

  Author toAuthor() {
    return Author(
      id: id,
      name: name,
      registerDate: registerDate,
      upvotes: upvotes,
      downvotes: downvotes,
      investment: investment,
      isAgent: email.isEmpty,
      score: 0,
      cred: 0,
      rank: 0,
    );
  }

  static String validateLength(String name, String value, int min, int max) {
    if (value.length > max) {
      return TRSignUp.tooLong(name, max);
    }
    if (value.length < min) {
      return TRSignUp.tooShort(name, min);
    }
    return "";
  }
}

class Author {
  final int id;
  final String name;
  final DateTime registerDate;
  final int upvotes;
  final int downvotes;
  final int investment;
  final bool isAgent;
  final num score;
  final num cred;
  final num rank;

  const Author({
    required this.id,
    required this.name,
    required this.registerDate,
    required this.upvotes,
    required this.downvotes,
    required this.investment,
    required this.isAgent,
    required this.score,
    required this.cred,
    required this.rank,
  });

  factory Author.fromInt(int json) {
    return Author(
      id: json,
      name: "",
      registerDate: DateTime.fromMicrosecondsSinceEpoch(0),
      upvotes: 0,
      downvotes: 0,
      investment: 0,
      isAgent: false,
      score: 0,
      cred: 0,
      rank: 0,
    );
  }

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: int.parse(json["ID"]),
      name: json["Name"],
      registerDate: DateTime.parse(json["RegisterDate"]).toLocal(),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
      investment: json["Investment"],
      isAgent: json["IsAgent"],
      score: double.parse(json["Score"].toString()),
      cred: double.parse(json["Cred"].toString()),
      rank: double.parse(json["Rank"].toString()),
    );
  }

  double ratio(int x, int y) {
    final bottom = x + y;
    if (bottom == 0) {
      return 0;
    }
    return x / bottom;
  }

  String calculateCred() {
    final v = ratio(upvotes, downvotes) * 100;
    return "${v.toStringAsFixed(0)}%";
  }

  String calculateScore() {
    final v = upvotes * ratio(upvotes + investment, downvotes + investment);
    return v.toStringAsFixed(0);
  }

  void showUserPage(BuildContext context) {
    final page = AccountPage(user: this, title: name);

    Navigator.push(
      context,
      route(builder: (context) => page),
    );
  }

  Widget followButton(BuildContext context, Function() updateState) {
    final isFollowing = User.current?.following
            .firstWhere((u) => u.id == id,
                orElse: () => User.current?.toAuthor() ?? Author.fromInt(-1))
            .id !=
        User.current?.id;
    final isIgnored = User.current?.ignored
            .firstWhere((u) => u.id == id,
                orElse: () => User.current?.toAuthor() ?? Author.fromInt(-1))
            .id !=
        User.current?.id;
    final actionText = User.current == null
        ? TRGeneral.signIn
        : isIgnored
            ? TRGeneral.doNotIgnore
            : isFollowing
                ? TRGeneral.unfollow
                : TRGeneral.follow;
    final action = TextButton(
      onPressed: () async {
        if (User.current == null) {
          Navigator.pop(context);
          Navigator.push(context, route(builder: (c) => const MainApp()));
        } else if (isIgnored) {
          User.current?.ignored.removeWhere((u) => u.id == id);
          NewSource.deleteUserCont(User.current!.id, id, UserContKind.ignored)
              .catchError((e) {
            displayError(context, e);
          });
        } else if (isFollowing) {
          User.current?.following.removeWhere((u) => u.id == id);
          NewSource.deleteUserCont(
                  User.current!.id, id, UserContKind.userFollow)
              .catchError((e) {
            displayError(context, e);
          });
        } else {
          User.current?.following.add(this);
          NewSource.addUserCont(
                  uid: User.current!.id, kind: UserContKind.userFollow, pid: id)
              .catchError((e) {
            displayError(context, e);
          });
        }
        updateState();
      },
      style: const ButtonStyle(alignment: Alignment.centerLeft),
      child: Text(actionText),
    );

    return action;
  }

  Widget buildCreator(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => showUserPage(context),
      child: RichText(
        text: TextSpan(
          text: "$name ",
          style: theme.bodyText1,
          children: [
            TextSpan(
              text: "${calculateScore()} ",
              style: const TextStyle(color: Colors.grey),
            ),
            TextSpan(
              text: "(${calculateCred()})",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget card(BuildContext context, Function() updateState,
      {int? up, int? down}) {
    final follow = followButton(context, updateState);
    final title = Text(name);
    final upvoteButton =
        buildVoteButton(context, upvotes, true, UserVoteKind.post, null);
    final downvoteButton =
        buildVoteButton(context, downvotes, false, UserVoteKind.post, null);

    final primary = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, follow],
          ),
        ),
        upvoteButton,
        downvoteButton,
      ],
    );

    late Widget body;
    if (up != null && down != null) {
      final upChip = buildVoteChip(context, up, true);
      final downChip = buildVoteChip(context, down, false);
      final desc = Padding(
        padding: EdgeInsets.all(4),
        child: Text(TRGeneral.votesFromUser),
      );
      body = Column(
        children: [
          primary,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [desc, SizedBox(width: 4), upChip, downChip],
          ),
        ],
      );
    } else {
      body = primary;
    }

    return InkWell(
      onTap: () => showUserPage(context),
      child: Padding(padding: EdgeInsets.all(8), child: body),
    );
  }
}
