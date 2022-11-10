import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/flags_page.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/main.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/news_agent_page.dart';
import 'package:social_news_app/settings.dart';
import 'package:social_news_app/user_cont_page.dart';
import 'package:social_news_app/user_pref_page.dart';
import 'package:social_news_app/widgets/purchase_credit_widget.dart';

class AccountPage extends StatefulWidget {
  final Author user;
  final String title;
  final HomeViewState? homeView;

  const AccountPage(
      {super.key, this.homeView, required this.user, required this.title});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = User.current;
  }

  void Function() showUserPrefPage(
      BuildContext context, ContentKind kind, bool isViewed) {
    return () {
      final title = contentKindToString(kind);

      final body = UserPrefPage(
        title: title,
        showSearch: true,
        prefKind: kind,
        user: widget.user,
        isViewed: isViewed,
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

      final body = UserContPage(
        title: title,
        showSearch: true,
        kind: kind,
        playlist: playlist,
        user: widget.user,
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
            NewSource.updateUserDetails(User.current!);
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(title: const Text("Account")),
          body: SettingsPage(homeView: widget.homeView),
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
      var page = FlagsPage(isPosts: isPosts);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => page,
        ),
      );
    };
  }

  void Function() showAgents(BuildContext context) {
    return () {
      const page = NewsAgentPage();
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
    final isOwner = widget.user.id == User.current?.id;
    if (isOwner) {
      credit = InkWell(
        onTap: () {
          showPlatformDialog(
              context: context, builder: (context) => const PurchaseCredit());
        },
        child: Text("Credits: ${User.current!.creditAmount()}"),
      );
      action = TextButton(
        onPressed: () {
          User.removeUser();
          NewSource.signOut();
          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => const MainApp()));
        },
        child: const Text("Logout"),
      );
    } else {
      credit = null;
      action = widget.user.followButton(() => setState(() {}));
    }
    final name = ListTile(
      title: Text(widget.user.name),
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
    final agents = ListTile(
      title: const Text("Agents"),
      onTap: showAgents(context),
    );
    var settingsSection = <Widget>[];
    if (NewSource.isDebug) {
      if (isOwner) {
        settingsSection.add(const Divider(thickness: 1));
        settingsSection.add(const Padding(
            padding: EdgeInsets.all(8), child: Text("Preferences")));
        settingsSection.add(const Divider(thickness: 1));
        settingsSection.add(settings);
        if (User.current?.id == -1 && NewSource.isDebug) {
          settingsSection.add(postFlags);
          settingsSection.add(commentFlags);
          settingsSection.add(agents);
        }
      }
    }

    final list = ListView(children: [
      name,
      const Divider(thickness: 1),
      const Padding(padding: EdgeInsets.all(8), child: Text("Created Content")),
      const Divider(thickness: 1),
      userPosts,
      userComments,
      const Divider(thickness: 1),
      const Padding(padding: EdgeInsets.all(8), child: Text("Collections")),
      const Divider(thickness: 1),
      viewed,
      readLater,
      following,
      ignored,
      const Divider(thickness: 1),
      const Padding(padding: EdgeInsets.all(8), child: Text("Voted For")),
      const Divider(thickness: 1),
      votedPosts,
      votedUsers,
      votedTags,
      votedComments,
      ...settingsSection,
    ]);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
