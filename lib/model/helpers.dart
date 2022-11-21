import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/model/user_pref.dart';
import 'package:social_news_app/posts_page.dart';
import 'package:social_news_app/widgets/filter_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';

bool targetPlatformIsMobile() {
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

bool targetPlatformIsDesktop() {
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

Future<void> launchURL(String url) async {
  if (url == "") {
    return;
  }
  if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
    throw err("Could not launch website");
  }
}

String formatDate(DateTime date) {
  final today = DateTime.now();
  date = date.toLocal();
  final sameYear = today.year == date.year;
  final sameMonth = today.month == date.month;
  final sameDay = today.day == date.day;

  if (sameYear) {
    if (sameMonth) {
      if (sameDay) {
        return "Today";
      } else if ((today.day - date.day).abs() == 1) {
        return "Yesterday";
      } else if ((today.day - date.day).abs() < 7) {
        return "Last ${DateFormat.EEEE().format(date)}";
      } else {
        return DateFormat.MMMEd().format(date);
      }
    } else {
      return DateFormat.MMMEd().format(date);
    }
  } else {
    return DateFormat.yMMMMd().format(date);
  }
}

String formatDateTime(DateTime date) {
  final today = DateTime.now();
  date = date.toLocal();

  final sameYear = today.day - date.day < 365;
  final sameMonth = today.day - date.day < 30;
  final sameDay = (today.millisecondsSinceEpoch - date.millisecondsSinceEpoch) <
      1000 * 60 * 60 * 24;
  final sameHour =
      (today.millisecondsSinceEpoch - date.millisecondsSinceEpoch) <
          1000 * 60 * 60;

  final diff = today.difference(date);

  if (sameYear) {
    if (sameMonth) {
      if (sameDay) {
        if (sameHour) {
          return "${diff.inMinutes}m";
        } else {
          return "${diff.inHours}h";
        }
      } else {
        return "${diff.inDays}d";
      }
    } else {
      return "${diff.inDays / 30}mon";
    }
  } else {
    return "${diff.inDays / 365}y";
  }
}

DateTime endOfDay(DateTime d) {
  return DateTime(d.year, d.month, d.day, 23, 59, 59);
}

DateTime startOfDay(DateTime d) {
  return DateTime(d.year, d.month, d.day);
}

bool isTypeEqual<S, T>() => S == T;

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

TextStyle merge(TextStyle base, TextStyle? other) {
  if (other == null) {
    return base;
  }

  String? mergedDebugLabel;
  assert(() {
    if (other.debugLabel != null || base.debugLabel != null) {
      mergedDebugLabel =
          '(${base.debugLabel ?? "_kDefaultDebugLabel"}).merge(${other.debugLabel ?? "_kDefaultDebugLabel"})';
    }
    return true;
  }());

  return base.copyWith(
    color: other.color,
    backgroundColor: other.backgroundColor,
    fontSize: other.fontSize,
    fontWeight: other.fontWeight,
    fontStyle: other.fontStyle,
    letterSpacing: other.letterSpacing,
    wordSpacing: other.wordSpacing,
    textBaseline: other.textBaseline,
    height: other.height,
    leadingDistribution: other.leadingDistribution,
    locale: other.locale,
    foreground: other.foreground,
    background: other.background,
    shadows: other.shadows,
    fontFeatures: (base.fontFeatures ?? []) + (other.fontFeatures ?? []),
    fontVariations: (base.fontVariations ?? []) + (other.fontVariations ?? []),
    decoration: TextDecoration.combine([
      base.decoration ?? TextDecoration.none,
      other.decoration ?? TextDecoration.none,
    ]),
    decorationColor: other.decorationColor,
    decorationStyle: other.decorationStyle,
    decorationThickness: other.decorationThickness,
    debugLabel: mergedDebugLabel,
    fontFamily: other.fontFamily,
    fontFamilyFallback: other.fontFamilyFallback,
    // package: other.package,
    overflow: other.overflow,
  );
}

List<T> jsonArrayTo<T>(
    dynamic list, T Function(Map<String, dynamic> json) map) {
  var result = <T>[];
  for (final item in list) {
    final p = map(item);
    result.add(p);
  }
  return result;
}

PageRoute route({required Widget Function(BuildContext) builder}) {
  try {
    if (Platform.isIOS) {
      return CupertinoPageRoute(builder: builder);
    } else if (Platform.isAndroid) {
      return MaterialPageRoute(builder: builder);
    }
    return MaterialPageRoute(builder: builder);
  } catch (e) {
    return MaterialPageRoute(builder: builder);
  }
}

FutureBuilder<List<T>> Function<T>(Future<List<T>> items) buildFutureList(
  BuildContext context,
  void Function<U>(Future<List<U>>, Future<List<U>>) loadMore,
  FilterBoxState filterState,
  List<int> count,
  List<bool> isLoading,
  List<bool> hasMore,
  Future<List<U>> Function<U>() getNewItems,
  void Function() updateState,
  Future<List<Tag>> tags,
  Future<List<Post>> posts,
  Future<List<Author>> users,
  Future<List<Comment>> comments,
  Future<List<FlaggedPost>> flaggedPosts,
  Future<List<FlaggedComment>> flaggedComments,
  Future<List<UserPrefTag>> prefTags,
  Future<List<UserPrefPost>> prefPosts,
  Future<List<UserPrefUser>> prefUsers,
  Future<List<UserPrefComment>> prefComments,
) {
  return <T>(Future<List<T>> items) {
    return FutureBuilder<List<T>>(
        future: items,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            final circle = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [CircularProgressIndicator()],
            );
            return SliverList(
              delegate: SliverChildListDelegate.fixed([circle]),
            );
          }

          if (snapshot.hasError) {
            return SliverList(
              delegate: SliverChildListDelegate.fixed(
                [Text("${snapshot.error}")],
              ),
            );
          }

          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            return const SliverList(
                delegate: SliverChildListDelegate.fixed([]));
          }

          final list = SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: count[filterState.current] + 1,
              (context, index) {
                if (index >= count[filterState.current]) {
                  if (isLoading[filterState.current]) {
                    return const CircularProgressIndicator();
                  } else if (hasMore[filterState.current]) {
                    final newItems = getNewItems<T>();
                    if (isTypeEqual<T, Tag>()) {
                      loadMore(newItems, tags);
                    } else if (isTypeEqual<T, Post>()) {
                      loadMore(newItems, posts);
                    } else if (isTypeEqual<T, Author>()) {
                      loadMore(newItems, users);
                    } else if (isTypeEqual<T, Comment>()) {
                      loadMore(newItems, comments);
                    } else if (isTypeEqual<T, FlaggedPost>()) {
                      loadMore(newItems, flaggedPosts);
                    } else if (isTypeEqual<T, FlaggedComment>()) {
                      loadMore(newItems, flaggedComments);
                    } else if (isTypeEqual<T, UserPrefTag>()) {
                      loadMore(newItems, prefTags);
                    } else if (isTypeEqual<T, UserPrefPost>()) {
                      loadMore(newItems, prefPosts);
                    } else if (isTypeEqual<T, UserPrefUser>()) {
                      loadMore(newItems, prefUsers);
                    } else if (isTypeEqual<T, UserPrefComment>()) {
                      loadMore(newItems, prefComments);
                    }
                    isLoading[filterState.current] = true;
                    return const CircularProgressIndicator();
                  } else {
                    return const SizedBox();
                  }
                }
                final item = snapshot.data![index];
                if (isTypeEqual<T, Tag>()) {
                  final tag = item as Tag;
                  final page = PostsPage(title: tag.name, tags: [tag.id]);
                  return ListTile(
                    title: Text(tag.name),
                    onTap: () => Navigator.push(
                      context,
                      route(builder: (context) => page),
                    ),
                  );
                } else if (isTypeEqual<T, Post>()) {
                  return (item as Post).tile(context, updateState);
                } else if (isTypeEqual<T, Author>()) {
                  final user = item as Author;
                  return ListTile(
                      title: Text(user.name),
                      onTap: () => user.showUserPage(context));
                } else if (isTypeEqual<T, Comment>()) {
                  final comment = item as Comment;
                  return comment.card(
                      context,
                      false,
                      0,
                      (c) => c.showParentPost(context)(),
                      updateState,
                      null,
                      false,
                      false);
                } else if (isTypeEqual<T, FlaggedPost>()) {
                  final flag = item as FlaggedPost;
                  final content = flag.content.tile(context, updateState);
                  final review = flag.card(context, updateState);
                  return Column(children: [content, review]);
                } else if (isTypeEqual<T, FlaggedComment>()) {
                  final flag = (item as FlaggedComment);
                  final content = flag.content.card(
                    context,
                    false,
                    0,
                    (c) => c.showParentPost(context)(),
                    updateState,
                    null,
                    false,
                    false,
                  );
                  final review = flag.card(context, updateState);
                  return Column(children: [content, review]);
                } else if (isTypeEqual<T, UserPrefTag>()) {
                  final tag = item as UserPrefTag;
                  return tag.tag.card(context, updateState,
                      up: tag.upvotes, down: tag.downvotes);
                } else if (isTypeEqual<T, UserPrefPost>()) {
                  final post = item as UserPrefPost;
                  return post.post.tile(context, updateState,
                      up: post.upvotes, down: post.downvotes);
                } else if (isTypeEqual<T, UserPrefUser>()) {
                  final user = item as UserPrefUser;
                  return user.author.card(context, updateState,
                      up: user.upvotes, down: user.downvotes);
                } else if (isTypeEqual<T, UserPrefComment>()) {
                  final comment = (item as UserPrefComment);
                  return comment.comment.card(
                      context,
                      false,
                      0,
                      (c) => c.showParentPost(context)(),
                      updateState,
                      null,
                      false,
                      false,
                      up: comment.upvotes,
                      down: comment.downvotes);
                } else {
                  return const SizedBox();
                }
              },
            ),
          );
          return list;
        });
  };
}

Widget buildFilteredList<T>(
  Widget list,
  FilterBoxState filterState,
  void Function(FilterBoxState) updateFilterState,
  bool showingFilter,
  void Function(void Function()) updateFilter,
) {
  late final Widget sliver;
  final filterBox = FilterBox(
    filterKey: GlobalKey(),
    valueChanged: (state) => updateFilterState(state),
    state: filterState,
  );

  var stack = <Widget>[];
  if (showingFilter) {
    sliver = CustomScrollView(
      slivers: [
        list,
      ],
    );
    final pull = RefreshIndicator(
        child: sliver, onRefresh: () async => updateFilter(() {}));
    stack.add(pull);
    stack.add(filterBox);
  } else {
    sliver = CustomScrollView(
      slivers: [
        SliverList(delegate: SliverChildListDelegate([filterBox])),
        list,
      ],
    );
    final pull = RefreshIndicator(
        child: sliver, onRefresh: () async => updateFilter(() {}));
    stack.add(pull);
  }

  return Stack(children: stack);
}
