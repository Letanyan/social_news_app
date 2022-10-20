import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/model/search.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/user_cont_page.dart';
import 'package:social_news_app/user_pref_page.dart';

class AccountPage extends StatefulWidget {
  final Author user;

  const AccountPage({super.key, required this.user});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  void Function() showUserPrefPage(BuildContext context, int kind) {
    return () {
      final title = (kind == 0
          ? "Tags"
          : (kind == 1 ? "Posts" : (kind == 2 ? "Users" : "Comments")));

      final body = Scaffold(
        appBar: AppBar(title: Text(title)),
        body:
            UserPrefPage(showSearch: false, prefKind: kind, user: widget.user),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => body,
        ),
      );
    };
  }

  void Function() showUserContPage(BuildContext context, bool isPost) {
    return () {
      final title = isPost ? "Posts" : "Comments";

      final body = Scaffold(
        appBar: AppBar(title: Text(title)),
        body:
            UserContPage(showSearch: false, isPost: isPost, user: widget.user),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => body,
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final Text? credit;
    if (widget.user.ID == User.current?.ID) {
      credit = Text("${User.current!.Credits}");
    } else {
      credit = null;
    }
    final name = ListTile(
      title: Text(widget.user.Name),
      subtitle: credit,
    );

    final userPosts = ListTile(
        title: const Text("Posts"), onTap: showUserContPage(context, true));
    final userComments = ListTile(
        title: const Text("Comments"), onTap: showUserContPage(context, false));

    final votedPosts = ListTile(
      title: const Text("Posts"),
      onTap: showUserPrefPage(context, 1),
    );
    final votedUsers = ListTile(
      title: const Text("Users"),
      onTap: showUserPrefPage(context, 2),
    );
    final votedTags = ListTile(
        title: const Text("Tags"), onTap: showUserPrefPage(context, 0));
    final votedComments = ListTile(
        title: const Text("Comments"), onTap: showUserPrefPage(context, 3));

    return ListView(children: [
      name,
      const Text("Created Content"),
      userPosts,
      userComments,
      const SizedBox(height: 8),
      const Text("Voted For"),
      votedPosts,
      votedUsers,
      votedTags,
      votedComments,
    ]);
  }
}
