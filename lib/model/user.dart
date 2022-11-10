import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/model/new_source.dart';
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
  final int validationKey;
  List<Author> following;
  List<Author> ignored;
  String secret;

  bool publicViews;
  bool publicReadLater;
  bool publicFollowing;
  bool publicIgnored;
  bool publicPostVotes;
  bool publicCommentVotes;
  bool publicUserVotes;
  bool publicTagVotes;

  String creditAmount() {
    return credits < 0 ? "..." : "$credits";
  }

  void storeUser() async {
    final pref = await SharedPreferences.getInstance();
    pref.setInt("user:id", id);
    pref.setString("user:name", name);
    pref.setString("user:email", email);
    pref.setInt("user:register", registerDate.millisecondsSinceEpoch);
    pref.setInt("user:validation", validationKey);
    pref.setString("user:secret", secret);
  }

  static void removeUser() async {
    final pref = await SharedPreferences.getInstance();
    pref.remove("user:id");
    pref.remove("user:name");
    pref.remove("user:email");
    pref.remove("user:register");
    pref.remove("user:validation");
    pref.remove("user:secret");
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
      validationKey: validation,
      publicViews: false,
      publicReadLater: false,
      publicFollowing: false,
      publicIgnored: false,
      publicPostVotes: false,
      publicCommentVotes: false,
      publicUserVotes: false,
      publicTagVotes: false,
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
    required this.validationKey,
    required this.publicViews,
    required this.publicReadLater,
    required this.publicFollowing,
    required this.publicIgnored,
    required this.publicPostVotes,
    required this.publicCommentVotes,
    required this.publicUserVotes,
    required this.publicTagVotes,
  })  : following = [],
        ignored = [],
        secret = "";

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["ID"],
      name: json["Name"],
      email: json["Email"],
      password: json["Password"],
      registerDate: DateTime.parse(json["RegisterDate"]),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
      credits: json["Credits"],
      validationKey: json["ValidationKey"],
      publicViews: json["PublicViews"],
      publicReadLater: json["PublicReadLater"],
      publicFollowing: json["PublicFollowing"],
      publicIgnored: json["PublicIgnored"],
      publicPostVotes: json["PublicPostVotes"],
      publicCommentVotes: json["PublicCommentVotes"],
      publicUserVotes: json["PublicUserVotes"],
      publicTagVotes: json["PublicTagVotes"],
    );
  }

  factory User.fromSecretJson(Map<String, dynamic> json) {
    final obj = json["user"];
    var user = User(
      id: obj["ID"],
      name: obj["Name"],
      email: obj["Email"],
      password: obj["Password"],
      registerDate: DateTime.parse(obj["RegisterDate"]),
      upvotes: obj["Upvotes"],
      downvotes: obj["Downvotes"],
      credits: obj["Credits"],
      validationKey: obj["ValidationKey"],
      publicViews: obj["PublicViews"],
      publicReadLater: obj["PublicReadLater"],
      publicFollowing: obj["PublicFollowing"],
      publicIgnored: obj["PublicIgnored"],
      publicPostVotes: obj["PublicPostVotes"],
      publicCommentVotes: obj["PublicCommentVotes"],
      publicUserVotes: obj["PublicUserVotes"],
      publicTagVotes: obj["PublicTagVotes"],
    );
    user.secret = json["token"];
    return user;
  }

  static User? current;

  Author toAuthor() {
    return Author(
      id: id,
      name: name,
      registerDate: registerDate,
      upvotes: upvotes,
      downvotes: downvotes,
      score: 0,
      cred: 0,
      rank: 0,
    );
  }

  static String validateLength(String name, String value, int min, int max) {
    if (value.length > max) {
      return "$name must be at most $max characters long";
    }
    if (value.length < min) {
      return "$name must be at least $min characters long";
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
  final double score;
  final double cred;
  final double rank;

  const Author({
    required this.id,
    required this.name,
    required this.registerDate,
    required this.upvotes,
    required this.downvotes,
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
      score: 0,
      cred: 0,
      rank: 0,
    );
  }

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json["ID"],
      name: json["Name"],
      registerDate: DateTime.parse(json["RegisterDate"]),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
      score: json["Score"],
      cred: json["Cred"],
      rank: json["Rank"],
    );
  }

  void showUserPage(BuildContext context) {
    final page = AccountPage(user: this, title: name);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget followButton(Function() updateState) {
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
    final actionText = isIgnored
        ? "Don't Ignore"
        : isFollowing
            ? "Unfollow"
            : "Follow";
    final action = TextButton(
      onPressed: () async {
        if (User.current == null) {
          return;
        }
        if (isIgnored) {
          User.current?.ignored.removeWhere((u) => u.id == id);
          NewSource.deleteUserCont(User.current!.id, id, UserContKind.ignored);
        } else if (isFollowing) {
          User.current?.following.removeWhere((u) => u.id == id);
          NewSource.deleteUserCont(
              User.current!.id, id, UserContKind.userFollow);
        } else {
          User.current?.following.add(this);
          NewSource.addUserCont(
              uid: User.current!.id, kind: UserContKind.userFollow, pid: id);
        }
        updateState();
      },
      style: const ButtonStyle(alignment: Alignment.centerLeft),
      child: Text(actionText),
    );

    return action;
  }

  Widget card(BuildContext context, Function() updateState,
      {int? up, int? down}) {
    final title = Text(name);
    final upChip = buildUpvoteChip(context, upvotes);
    final downChip = buildDownvoteChip(context, downvotes);
    final follow =
        FittedBox(fit: BoxFit.contain, child: followButton(updateState));
    final votes = FittedBox(
        fit: BoxFit.contain, child: Row(children: [upChip, downChip]));

    return ListTile(
      title: title,
      trailing: Padding(padding: const EdgeInsets.all(8), child: votes),
      subtitle: follow,
      onTap: () => showUserPage(context),
    );
  }
}
