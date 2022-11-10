import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/widgets/vote_widget.dart';

class User {
  final int ID;
  String Name;
  final String Email;
  String Password;
  final DateTime RegisterDate;
  int Upvotes;
  int Downvotes;
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

  String creditAmount() {
    return Credits < 0 ? "..." : "$Credits";
  }

  void storeUser() async {
    final pref = await SharedPreferences.getInstance();
    pref.setInt("user:id", ID);
    pref.setString("user:name", Name);
    pref.setString("user:email", Email);
    pref.setInt("user:register", RegisterDate.millisecondsSinceEpoch);
    pref.setInt("user:validation", ValidationKey);
    pref.setString("user:secret", Secret);
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
      ID: id,
      Name: name,
      Email: email,
      Password: "",
      RegisterDate: register,
      Upvotes: 0,
      Downvotes: 0,
      Credits: -1,
      ValidationKey: validation,
      PublicViews: false,
      PublicReadLater: false,
      PublicFollowing: false,
      PublicIgnored: false,
      PublicPostVotes: false,
      PublicCommentVotes: false,
      PublicUserVotes: false,
      PublicTagVotes: false,
    );
    result.Secret = secret;
    return result;
  }

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
      Score: 0,
      Cred: 0,
      Rank: 0,
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
  final int ID;
  final String Name;
  final DateTime RegisterDate;
  final int Upvotes;
  final int Downvotes;
  final double Score;
  final double Cred;
  final double Rank;

  const Author({
    required this.ID,
    required this.Name,
    required this.RegisterDate,
    required this.Upvotes,
    required this.Downvotes,
    required this.Score,
    required this.Cred,
    required this.Rank,
  });

  factory Author.fromInt(int json) {
    return Author(
      ID: json,
      Name: "",
      RegisterDate: DateTime.fromMicrosecondsSinceEpoch(0),
      Upvotes: 0,
      Downvotes: 0,
      Score: 0,
      Cred: 0,
      Rank: 0,
    );
  }

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      ID: json["ID"],
      Name: json["Name"],
      RegisterDate: DateTime.parse(json["RegisterDate"]),
      Upvotes: json["Upvotes"],
      Downvotes: json["Downvotes"],
      Score: json["Score"],
      Cred: json["Cred"],
      Rank: json["Rank"],
    );
  }

  void showUserPage(BuildContext context) {
    final page = AccountPage(user: this, title: Name);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget followButton(Function() updateState) {
    final isFollowing = User.current?.following
            .firstWhere((u) => u.ID == ID,
                orElse: () => User.current?.toAuthor() ?? Author.fromInt(-1))
            .ID !=
        User.current?.ID;
    final isIgnored = User.current?.ignored
            .firstWhere((u) => u.ID == ID,
                orElse: () => User.current?.toAuthor() ?? Author.fromInt(-1))
            .ID !=
        User.current?.ID;
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
          User.current?.ignored.removeWhere((u) => u.ID == ID);
          NewSource.deleteUserCont(User.current!.ID, ID, UserContKind.ignored);
        } else if (isFollowing) {
          User.current?.following.removeWhere((u) => u.ID == ID);
          NewSource.deleteUserCont(
              User.current!.ID, ID, UserContKind.userFollow);
        } else {
          User.current?.following.add(this);
          NewSource.addUserCont(
              uid: User.current!.ID, kind: UserContKind.userFollow, pid: ID);
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
    final title = Text(Name);
    final upChip = buildUpvoteChip(context, Upvotes);
    final downChip = buildDownvoteChip(context, Downvotes);
    final follow =
        FittedBox(fit: BoxFit.contain, child: followButton(updateState));
    final votes = FittedBox(
        fit: BoxFit.contain, child: Row(children: [upChip, downChip]));

    return ListTile(
      title: title,
      trailing: Padding(padding: const EdgeInsets.all(8), child: votes),
      subtitle: followButton(updateState),
      onTap: () => showUserPage(context),
    );
  }
}
