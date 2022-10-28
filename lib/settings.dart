import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/user.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var cont = <UserContKind, bool>{};
  var pref = <UserPrefKind, bool>{};

  @override
  void initState() {
    super.initState();

    if (User.current != null) {
      cont[UserContKind.viewed] = User.current!.PublicViews;
      cont[UserContKind.readLater] = User.current!.PublicReadLater;
      cont[UserContKind.ignored] = User.current!.PublicIgnored;
      cont[UserContKind.userFollow] = User.current!.PublicFollowing;

      pref[UserPrefKind.post] = User.current!.PublicPostVotes;
      pref[UserPrefKind.comment] = User.current!.PublicCommentVotes;
      pref[UserPrefKind.user] = User.current!.PublicUserVotes;
      pref[UserPrefKind.tag] = User.current!.PublicTagVotes;
    }
  }

  void updateState(Function() f) {
    setState(() {
      f();
      User.current!.PublicCommentVotes = pref[UserPrefKind.comment] ?? false;
      User.current!.PublicPostVotes = pref[UserPrefKind.post] ?? false;
      User.current!.PublicUserVotes = pref[UserPrefKind.user] ?? false;
      User.current!.PublicTagVotes = pref[UserPrefKind.tag] ?? false;

      User.current!.PublicReadLater = cont[UserContKind.readLater] ?? false;
      User.current!.PublicViews = cont[UserContKind.viewed] ?? false;
      User.current!.PublicIgnored = cont[UserContKind.ignored] ?? false;
      User.current!.PublicFollowing = cont[UserContKind.userFollow] ?? false;
    });
  }

  ListTile publicContSetting(String title, UserContKind kind) {
    return ListTile(
      title: Text(title),
      leading: Switch(
        value: cont[kind] ?? true,
        onChanged: (value) => updateState(() => cont[kind] = value),
      ),
    );
  }

  ListTile publicPrefSetting(String title, UserPrefKind kind) {
    return ListTile(
      title: Text(title),
      leading: Switch(
        value: pref[kind] ?? true,
        onChanged: (value) => updateState(() => pref[kind] = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      publicContSetting("Public Read Later", UserContKind.readLater),
      publicContSetting("Public Viewed Posts", UserContKind.viewed),
      publicContSetting("Public Followed Users", UserContKind.userFollow),
      publicContSetting("Public Ignored Users", UserContKind.ignored),
      publicPrefSetting("Public Voted For Posts", UserPrefKind.post),
      publicPrefSetting("Public Voted For Comments", UserPrefKind.comment),
      publicPrefSetting("Public Voted For Users", UserPrefKind.user),
      publicPrefSetting("Public Voted For Tags", UserPrefKind.tag),
    ]);
  }
}
