import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/comment_notification_page.dart';
import 'package:social_news_app/flags_page.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/main.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
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
  late Author? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  void Function() showUserPrefPage(
    BuildContext context,
    ContentKind kind,
    bool isViewed, {
    int? pid,
    int? sid,
  }) {
    return () {
      final title = contentKindToString(kind);

      final body = UserPrefPage(
        title: title,
        showSearch: true,
        prefKind: kind,
        user: widget.user,
        isViewed: isViewed,
        pid: pid,
        sid: sid,
      );

      Navigator.push(context, route(builder: (context) => body))
          .then((value) => setState(() {}));
    };
  }

  void Function() showUserContPage(BuildContext context, ContentKind kind,
      UserContKind playlist, bool isReview, bool forContent) {
    return () {
      late final String title;
      if (kind == ContentKind.comment && isReview) {
        title = TRGeneral.critiques;
      } else {
        title = contentKindToString(kind);
      }

      final body = UserContPage(
        title: title,
        showSearch: false,
        kind: kind,
        playlist: playlist,
        user: widget.user,
        isReview: isReview,
        forContent: forContent,
        pid: currentUser?.id,
        sid: -1,
      );

      Navigator.push(context, route(builder: (context) => body))
          .then((value) => setState(() {}));
    };
  }

  void Function() showCommentNotificationPage(BuildContext context) {
    return () {
      final body = CommentNotificationPage(
        title: TRGeneral.replies,
        showSearch: false,
        user: widget.user,
      );

      Navigator.push(context, route(builder: (context) => body))
          .then((value) => setState(() {}));
    };
  }

  void Function() showSettingsPage(BuildContext context) {
    return () {
      var page = WillPopScope(
        onWillPop: () async {
          if (User.current != null) {
            final ctx = WeakReference(context);
            NewSource.updateUserDetails(User.current!).catchError((e) {
              displayError(ctx.target, e);
              return false;
            });
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(title: Text(TRGeneral.account)),
          body: SettingsPage(homeView: widget.homeView),
        ),
      );

      Navigator.push(context, route(builder: (context) => page))
          .then((value) => setState(() {}));
    };
  }

  void Function() showFlaggedContent(BuildContext context, bool isPosts) {
    return () {
      var page = FlagsPage(isPosts: isPosts);
      Navigator.push(context, route(builder: (context) => page))
          .then((value) => setState(() {}));
    };
  }

  void Function() showAgents(BuildContext context) {
    return () {
      const page = NewsAgentPage();
      Navigator.push(context, route(builder: (context) => page))
          .then((value) => setState(() {}));
    };
  }

  @override
  Widget build(BuildContext context) {
    final Widget? subtitle;
    final Widget? action;
    final isOwner = widget.user.id == User.current?.id;
    if (isOwner) {
      final credit =
          Text("${TRGeneral.credits}: ${User.current!.creditAmount()}");
      action = TextButton(
        onPressed: () {
          final ctx = WeakReference(context);
          NewSource.signOut(User.current?.id ?? 0).catchError((e) {
            displayError(ctx.target, e);
            return false;
          });
          User.removeUser().then((value) {
            User.current = null;
            Navigator.pop(context);
            Navigator.push(context, route(builder: (c) => const MainApp()));
          });
        },
        child: Text(TRGeneral.signOut),
      );
      final col = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          credit,
          Text("${TRGeneral.reputation}: ${widget.user.calculateScore()}"),
          Text("${TRGeneral.credibility}: ${widget.user.calculateCred()}"),
        ],
      );
      subtitle = InkWell(
        onTap: kIsWeb
            ? null
            : () {
                showPlatformDialog(
                    context: context,
                    builder: (context) => const PurchaseCredit());
              },
        child: col,
      );
    } else if (User.current == null) {
      subtitle = null;
      action = widget.user.followButton(context, () => setState(() {}));
    } else {
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${TRGeneral.reputation}: ${widget.user.calculateScore()}"),
          Text("${TRGeneral.credibility}: ${widget.user.calculateCred()}"),
        ],
      );
      action = widget.user.followButton(context, () => setState(() {}));
    }
    final display =
        widget.user.name.isEmpty ? TRGeneral.anonymous : widget.user.name;
    final name = ListTile(
      title: widget.user.isAgent
          ? Row(
              children: [
                Icon(Icons.smart_toy_outlined),
                SizedBox(width: 8),
                Text(display),
              ],
            )
          : Text(display),
      subtitle: subtitle,
      trailing: action,
    );

    final userPosts = ListTile(
        title: Text(TRGeneral.posts),
        onTap: showUserContPage(
          context,
          ContentKind.post,
          UserContKind.created,
          false,
          false,
        ));
    final userComments = ListTile(
      title: Text(TRGeneral.comments),
      onTap: showUserContPage(
        context,
        ContentKind.comment,
        UserContKind.created,
        false,
        false,
      ),
    );
    final userReviews = ListTile(
      title: Text(TRGeneral.critiques),
      onTap: showUserContPage(
        context,
        ContentKind.comment,
        UserContKind.created,
        true,
        false,
      ),
    );
    final userReplies = ListTile(
      title: Text(TRGeneral.replies),
      onTap: showCommentNotificationPage(context),
    );

    final viewed = ListTile(
      title: Text(TRAccountPage.viewed),
      onTap: showUserContPage(
        context,
        ContentKind.post,
        UserContKind.viewed,
        false,
        false,
      ),
    );
    final readLater = ListTile(
      title: Text(TRAccountPage.readLater),
      onTap: showUserContPage(
        context,
        ContentKind.post,
        UserContKind.readLater,
        false,
        false,
      ),
    );
    final following = ListTile(
      title: Text(TRAccountPage.usersFollowing),
      onTap: showUserContPage(
        context,
        ContentKind.user,
        UserContKind.userFollow,
        false,
        false,
      ),
    );
    final ignored = ListTile(
      title: Text(TRAccountPage.usersIgnored),
      onTap: showUserContPage(
        context,
        ContentKind.user,
        UserContKind.ignored,
        false,
        false,
      ),
    );
    final followedBy = ListTile(
      title: Text(TRAccountPage.followedBy),
      onTap: showUserContPage(
        context,
        ContentKind.user,
        UserContKind.userFollow,
        false,
        true,
      ),
    );
    final ignoredBy = ListTile(
      title: Text(TRAccountPage.ignoredBy),
      onTap: showUserContPage(
        context,
        ContentKind.user,
        UserContKind.ignored,
        false,
        true,
      ),
    );
    final favourites = ListTile(
      title: Text(TRAccountPage.tagsFollowing),
      onTap: showUserContPage(
        context,
        ContentKind.tag,
        UserContKind.tagFollow,
        false,
        false,
      ),
    );

    final votedPosts = ListTile(
      title: Text(TRGeneral.posts),
      onTap: showUserPrefPage(context, ContentKind.post, false),
    );
    final votedUsers = ListTile(
      title: Text(TRGeneral.users),
      onTap: showUserPrefPage(context, ContentKind.user, false),
    );
    final votedTags = ListTile(
        title: Text(TRGeneral.tags),
        onTap: showUserPrefPage(context, ContentKind.tag, false));
    final votedComments = ListTile(
        title: Text(TRGeneral.comments),
        onTap: showUserPrefPage(context, ContentKind.comment, false));
    final votedByOthers = ListTile(
      title: Text(TRGeneral.forYou),
      onTap: showUserPrefPage(
        context,
        ContentKind.user,
        false,
        pid: User.current?.id ?? -1,
        sid: -1,
      ),
    );
    final watchedTags = ListTile(
        title: Text(TRGeneral.tagsViewed),
        onTap: showUserPrefPage(context, ContentKind.tag, true));

    final settings = ListTile(
      title: Text(TRGeneral.settings),
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
    if (isOwner) {
      settingsSection.add(const Divider(thickness: 1));
      settingsSection.add(
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(TRGeneral.preferences),
        ),
      );
      settingsSection.add(const Divider(thickness: 1));
      settingsSection.add(settings);
      if (User.current?.id == -1 && NewSource.isDebug) {
        settingsSection.add(postFlags);
        settingsSection.add(commentFlags);
        settingsSection.add(agents);
      }
    }

    final list = ListView(children: [
      name,
      const Divider(thickness: 1),
      Padding(
        padding: EdgeInsets.all(8),
        child: Text(TRAccountPage.createdContent),
      ),
      const Divider(thickness: 1),
      userPosts,
      userComments,
      userReviews,
      userReplies,
      const Divider(thickness: 1),
      Padding(
        padding: EdgeInsets.all(8),
        child: Text(TRAccountPage.collections),
      ),
      const Divider(thickness: 1),
      viewed,
      readLater,
      const Divider(thickness: 1),
      Padding(
        padding: EdgeInsets.all(8),
        child: Text(TRGeneral.following),
      ),
      const Divider(thickness: 1),
      favourites,
      watchedTags,
      following,
      followedBy,
      const Divider(thickness: 1),
      Padding(
        padding: EdgeInsets.all(8),
        child: Text(TRGeneral.ignoring),
      ),
      const Divider(thickness: 1),
      ignored,
      ignoredBy,
      const Divider(thickness: 1),
      Padding(
        padding: EdgeInsets.all(8),
        child: Text(TRAccountPage.votedFor),
      ),
      const Divider(thickness: 1),
      votedPosts,
      votedUsers,
      votedTags,
      votedComments,
      votedByOthers,
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
      return TRGeneral.comments;
    case ContentKind.post:
      return TRGeneral.posts;
    case ContentKind.user:
      return TRGeneral.users;
    case ContentKind.tag:
      return TRGeneral.tags;
  }
}
