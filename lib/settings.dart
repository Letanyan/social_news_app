import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/main.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';

class SettingsPage extends StatefulWidget {
  final HomeViewState? homeView;

  const SettingsPage({super.key, required this.homeView});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var cont = <UserContKind, bool>{};
  var pref = <UserPrefKind, bool>{};
  var controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (User.current != null) {
      cont[UserContKind.viewed] = User.current!.publicViews;
      cont[UserContKind.readLater] = User.current!.publicReadLater;
      cont[UserContKind.ignored] = User.current!.publicIgnored;
      cont[UserContKind.userFollow] = User.current!.publicFollowing;
      cont[UserContKind.tagFollow] = User.current!.publicTagFollow;

      pref[UserPrefKind.post] = User.current!.publicPostVotes;
      pref[UserPrefKind.comment] = User.current!.publicCommentVotes;
      pref[UserPrefKind.user] = User.current!.publicUserVotes;
      pref[UserPrefKind.tag] = User.current!.publicTagVotes;
    }
    controller.text = User.current?.name ?? "";
  }

  void updateState(Function() f) {
    setState(() {
      f();

      String un = User.validateLength(
          TRGeneral.displayName.toLowerCase(), controller.text, 3, 15);
      if (un.isEmpty) {
        User.current!.name = controller.text;
      }
      User.current!.publicCommentVotes = pref[UserPrefKind.comment] ?? false;
      User.current!.publicPostVotes = pref[UserPrefKind.post] ?? false;
      User.current!.publicUserVotes = pref[UserPrefKind.user] ?? false;
      User.current!.publicTagVotes = pref[UserPrefKind.tag] ?? false;

      User.current!.publicReadLater = cont[UserContKind.readLater] ?? false;
      User.current!.publicViews = cont[UserContKind.viewed] ?? false;
      User.current!.publicIgnored = cont[UserContKind.ignored] ?? false;
      User.current!.publicFollowing = cont[UserContKind.userFollow] ?? false;
      User.current!.publicTagFollow = cont[UserContKind.tagFollow] ?? false;
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

  Widget buildColorSwatch(
      BuildContext context, MaterialColor color, int index) {
    final size = color == MyTheme.primary ? 48.0 : 32.0;
    return GestureDetector(
      onTap: () {
        setState(() {
          MyTheme.primary = color;
          widget.homeView?.setState(() {});
        });
        SharedPreferences.getInstance()
            .then((value) => value.setInt("theme:color", index));
      },
      child: Container(width: size, height: size, color: color),
    );
  }

  Widget buildThemeMode(BuildContext context, ThemeMode mode, int index) {
    return RadioListTile<ThemeMode>(
      title: Text(mode == ThemeMode.system
          ? TRGeneral.system
          : mode == ThemeMode.dark
              ? TRGeneral.dark
              : TRGeneral.light),
      value: mode,
      groupValue: MyTheme.mode,
      onChanged: (mode) async {
        setState(() {
          MyTheme.mode = mode ?? ThemeMode.system;
          widget.homeView?.setState(() {});
        });
        SharedPreferences.getInstance()
            .then((value) => value.setInt("theme:mode", index));
      },
    );
  }

  Widget buildSafeMode(BuildContext context, bool safe) {
    return SwitchListTile(
      title: Text(TRSettings.safeImage),
      value: MyTheme.safe,
      onChanged: (safe) {
        setState(() {
          MyTheme.safe = safe;
        });
        SharedPreferences.getInstance()
            .then((value) => value.setBool("theme:safe", safe));
      },
    );
  }

  Widget buildDeleteAccount(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.delete_forever_rounded),
      title: Text(TRSettings.deleteAccount),
      onTap: () {
        showPlatformDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(TRSettings.deleteAccount),
              content: Text(TRSettings.areYouSureDelete),
              actions: [
                TextButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(
                        MyTheme.isDark ? Colors.white : Colors.black),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(TRGeneral.cancel),
                ),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.red),
                    ),
                    onPressed: () {
                      final ctx = WeakReference(context);
                      NewSource.deleteUser(User.current?.id ?? 0)
                          .catchError((e) {
                        displayError(ctx.target, e);
                        return false;
                      });
                      User.removeUser().then((value) {
                        User.current = null;
                        Navigator.pop(context);
                        Navigator.push(
                            context, route(builder: (c) => const MainApp()));
                      });
                    },
                    child: Text(TRGeneral.delete)),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const Divider(thickness: 1),
      Padding(
        padding: EdgeInsets.all(8),
        child: Text(TRSettings.accountDetails),
      ),
      const Divider(thickness: 1),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Text("${TRGeneral.displayName}: "),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: TRGeneral.displayName.toLowerCase(),
                ),
                onChanged: (value) => updateState(() {}),
              ),
            ),
          ],
        ),
      ),
      const Divider(thickness: 1),
      Padding(padding: EdgeInsets.all(8), child: Text(TRSettings.theme)),
      const Divider(thickness: 1),
      SizedBox(
        height: 48,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildColorSwatch(context, Colors.purple, 0),
              buildColorSwatch(context, Colors.pink, 1),
              buildColorSwatch(context, Colors.red, 2),
              buildColorSwatch(context, Colors.deepOrange, 3),
              buildColorSwatch(context, Colors.orange, 4),
              buildColorSwatch(context, Colors.amber, 5),
              buildColorSwatch(context, Colors.lime, 6),
              buildColorSwatch(context, Colors.lightGreen, 7),
              buildColorSwatch(context, Colors.green, 8),
              buildColorSwatch(context, Colors.teal, 9),
              buildColorSwatch(context, Colors.deepPurple, 10),
              buildColorSwatch(context, Colors.indigo, 11),
              buildColorSwatch(context, Colors.blue, 12),
              buildColorSwatch(context, Colors.lightBlue, 13),
              buildColorSwatch(context, Colors.cyan, 14),
              buildColorSwatch(context, Colors.brown, 15),
              buildColorSwatch(context, Colors.blueGrey, 16),
              buildColorSwatch(context, Colors.grey, 17),
            ],
          ),
        ),
      ),
      buildThemeMode(context, ThemeMode.system, 0),
      buildThemeMode(context, ThemeMode.dark, 1),
      buildThemeMode(context, ThemeMode.light, 2),
      const Divider(thickness: 1),
      Padding(padding: EdgeInsets.all(8), child: Text(TRSettings.safeMode)),
      const Divider(thickness: 1),
      buildSafeMode(context, MyTheme.safe),
      const Divider(thickness: 1),
      Padding(padding: EdgeInsets.all(8), child: Text(TRSettings.permission)),
      const Divider(thickness: 1),
      publicContSetting(TRSettings.publicReadLater, UserContKind.readLater),
      publicContSetting(TRSettings.publicViewedPosts, UserContKind.viewed),
      publicContSetting(
          TRSettings.publicFollowedUsers, UserContKind.userFollow),
      publicContSetting(TRSettings.publicIgnoredUsers, UserContKind.ignored),
      publicContSetting(TRSettings.publicFollowedTags, UserContKind.tagFollow),
      publicPrefSetting(TRSettings.publicVotedPosts, UserPrefKind.post),
      publicPrefSetting(TRSettings.publicVotedComments, UserPrefKind.comment),
      publicPrefSetting(TRSettings.publicVotedUsers, UserPrefKind.user),
      publicPrefSetting(TRSettings.publicVotedTags, UserPrefKind.tag),
      const Divider(thickness: 1),
      Padding(padding: EdgeInsets.all(8), child: Text(TRSettings.actions)),
      const Divider(thickness: 1),
      buildDeleteAccount(context),
    ]);
  }
}
