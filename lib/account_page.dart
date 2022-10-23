import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/login.dart';
import 'package:social_news_app/main.dart';
import 'package:social_news_app/model/new_source.dart';
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
      BuildContext context, ContentKind kind, UserContKind playlist) {
    return () {
      final String title = contentKindToString(kind);

      final body = Scaffold(
        appBar: AppBar(title: Text(title)),
        body: UserContPage(
          showSearch: true,
          kind: kind,
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
    final TextButton? action;
    if (widget.user.ID == User.current?.ID) {
      credit = Text("${User.current!.Credits}");
      action = TextButton(
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
      final isFollowing = User.current!.following
              .firstWhere((u) => u.ID == widget.user.ID,
                  orElse: () => User.current!.toAuthor())
              .ID !=
          User.current!.ID;
      final isIgnored = User.current!.ignored
              .firstWhere((u) => u.ID == widget.user.ID,
                  orElse: () => User.current!.toAuthor())
              .ID !=
          User.current!.ID;
      final actionText = isIgnored
          ? "Don't Ignore"
          : isFollowing
              ? "Unfollow"
              : "Follow";
      action = TextButton(
        onPressed: () async {
          if (User.current == null) {
            return;
          }
          if (isIgnored) {
            User.current?.ignored.removeWhere((u) => u.ID == widget.user.ID);
            NewSource.deleteUserCont(
                User.current!.ID, widget.user.ID, UserContKind.ignored);
          } else if (isFollowing) {
            User.current?.following.removeWhere((u) => u.ID == widget.user.ID);
            NewSource.deleteUserCont(
                User.current!.ID, widget.user.ID, UserContKind.userFollow);
          } else {
            User.current?.following.add(widget.user);
            NewSource.addUserCont(
                uid: User.current!.ID,
                kind: UserContKind.userFollow,
                pid: widget.user.ID);
          }
          setState(() {});
        },
        child: Text(actionText),
      );
    }
    final name = ListTile(
      title: Text(widget.user.Name),
      subtitle: credit,
      trailing: action,
    );

    final userPosts = ListTile(
        title: const Text("Posts"),
        onTap:
            showUserContPage(context, ContentKind.post, UserContKind.created));
    final userComments = ListTile(
        title: const Text("Comments"),
        onTap: showUserContPage(
            context, ContentKind.comment, UserContKind.created));

    final viewed = ListTile(
        title: const Text("Viewed"),
        onTap:
            showUserContPage(context, ContentKind.post, UserContKind.viewed));
    final readLater = ListTile(
        title: const Text("Read Later"),
        onTap: showUserContPage(
            context, ContentKind.post, UserContKind.readLater));
    final following = ListTile(
      title: const Text("Following"),
      onTap:
          showUserContPage(context, ContentKind.user, UserContKind.userFollow),
    );
    final ignored = ListTile(
      title: const Text("Ignored"),
      onTap: showUserContPage(context, ContentKind.user, UserContKind.ignored),
    );

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
      following,
      ignored,
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

enum ContentKind { post, comment, user, tag }

String contentKindToString(ContentKind ck) {
  switch (ck) {
    case ContentKind.comment:
      return "Comments";
    case ContentKind.post:
      return "Posts";
    case ContentKind.user:
      return "Users";
    case ContentKind.tag:
      return "Tags";
  }
}
