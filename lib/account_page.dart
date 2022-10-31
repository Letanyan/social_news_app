import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/flags_page.dart';
import 'package:social_news_app/login.dart';
import 'package:social_news_app/main.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/search.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/settings.dart';
import 'package:social_news_app/user_cont_page.dart';
import 'package:social_news_app/user_pref_page.dart';
import 'package:social_news_app/widgets/purchase_credit_widget.dart';

class AccountPage extends StatefulWidget {
  final Author user;

  const AccountPage({super.key, required this.user});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  void Function() showUserPrefPage(
      BuildContext context, ContentKind kind, bool isViewed) {
    return () {
      final title = contentKindToString(kind);

      final body = Scaffold(
        appBar: AppBar(title: Text(title)),
        body: UserPrefPage(
          showSearch: true,
          prefKind: kind,
          user: widget.user,
          isViewed: isViewed,
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

  void Function() showSettingsPage(BuildContext context) {
    return () {
      var page = WillPopScope(
        onWillPop: () async {
          if (User.current != null) {
            NewSource.updateUserPermissions(User.current!);
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(title: const Text("Settings")),
          body: const SettingsPage(),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => page,
        ),
      );
    };
  }

  void Function() showFlaggedContent(BuildContext context, bool isPosts) {
    return () {
      var page = Scaffold(
        appBar:
            AppBar(title: Text(isPosts ? "Flagged Posts" : "Flagged Comments")),
        body: FlagsPage(isPosts: isPosts),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => page,
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final Widget? credit;
    final Widget? action;
    final isOwner = widget.user.ID == User.current?.ID;
    if (isOwner) {
      credit = InkWell(
        onTap: () {
          showPlatformDialog(
              context: context, builder: (context) => const PurchaseCredit());
        },
        child: Text("Credits: ${User.current!.Credits}"),
      );
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
      action = widget.user.followButton(() => setState(() {}));
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
      onTap: showUserPrefPage(context, ContentKind.post, false),
    );
    final votedUsers = ListTile(
      title: const Text("Users"),
      onTap: showUserPrefPage(context, ContentKind.user, false),
    );
    final votedTags = ListTile(
        title: const Text("Tags"),
        onTap: showUserPrefPage(context, ContentKind.tag, false));
    final votedComments = ListTile(
        title: const Text("Comments"),
        onTap: showUserPrefPage(context, ContentKind.comment, false));

    final settings = ListTile(
      title: const Text("Settings"),
      onTap: showSettingsPage(context),
    );
    final postFlags = ListTile(
      title: const Text("Reported Posts"),
      onTap: showFlaggedContent(context, true),
    );
    final commentFlags = ListTile(
      title: const Text("Reported Comments"),
      onTap: showFlaggedContent(context, false),
    );
    var settingsSection = <Widget>[];
    if (isOwner) {
      settingsSection.add(const Divider());
      settingsSection.add(const Padding(
          padding: EdgeInsets.all(8), child: Text("Preferences")));
      settingsSection.add(const Divider());
      settingsSection.add(settings);
      if (User.current!.ID == -1 && NewSource.isDebug) {
        settingsSection.add(postFlags);
        settingsSection.add(commentFlags);
      }
    }

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
      ...settingsSection,
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
