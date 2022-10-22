import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/login.dart';
import 'package:social_news_app/main.dart';
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
        body: UserPrefPage(showSearch: true, prefKind: kind, user: widget.user),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => body,
        ),
      );
    };
  }

  void Function() showUserContPage(
      BuildContext context, bool isPost, int playlist) {
    return () {
      final title = isPost ? "Posts" : "Comments";

      final body = Scaffold(
        appBar: AppBar(title: Text(title)),
        body: UserContPage(
          showSearch: true,
          isPost: isPost,
          playlist: playlist,
          user: widget.user,
        ),
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
    final TextButton? logout;
    if (widget.user.ID == User.current?.ID) {
      credit = Text("${User.current!.Credits}");
      logout = TextButton(
        onPressed: () {
          User.current = null;
          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => const MyApp()));
        },
        child: const Text("Logout"),
      );
    } else {
      credit = null;
      logout = null;
    }
    final name = ListTile(
      title: Text(widget.user.Name),
      subtitle: credit,
      trailing: logout,
    );

    final userPosts = ListTile(
        title: const Text("Posts"), onTap: showUserContPage(context, true, 0));
    final userComments = ListTile(
        title: const Text("Comments"),
        onTap: showUserContPage(context, false, 0));

    final viewed = ListTile(
        title: const Text("Viewed"), onTap: showUserContPage(context, true, 1));
    final readLater = ListTile(
        title: const Text("Read Later"),
        onTap: showUserContPage(context, true, 2));

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

    final list = ListView(children: [
      name,
      const Divider(),
      const Padding(padding: EdgeInsets.all(8), child: Text("Created Content")),
      const Divider(),
      userPosts,
      userComments,
      const Divider(),
      const Padding(padding: EdgeInsets.all(8), child: Text("Collections")),
      const Divider(),
      viewed,
      readLater,
      const Divider(),
      const Padding(padding: EdgeInsets.all(8), child: Text("Voted For")),
      const Divider(),
      votedPosts,
      votedUsers,
      votedTags,
      votedComments,
    ]);

    return Scaffold(
      body: list,
    );
  }
}
