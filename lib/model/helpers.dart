import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:intl/intl.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/locale.dart';
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
    throw err(TRHelper.launchWebFailed);
  }
}

String formatDate(DateTime date) {
  final today = DateTime.now();
  final sameYear = today.year == date.year;
  final sameMonth = today.month == date.month;
  final sameDay = today.day == date.day;

  if (sameYear) {
    if (sameMonth) {
      if (sameDay) {
        return TRHelper.today;
      } else if ((today.day - date.day).abs() == 1) {
        return TRHelper.yesterday;
      } else if ((today.day - date.day).abs() < 7) {
        return "${TRHelper.last} ${DateFormat.EEEE().format(date)}";
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
          return "${diff.inMinutes}${TRHelper.minute}";
        } else {
          return "${diff.inHours}${TRHelper.hour}";
        }
      } else {
        return "${diff.inDays}${TRHelper.day}";
      }
    } else {
      return "${diff.inDays / 30}${TRHelper.month}";
    }
  } else {
    return "${diff.inDays / 365}${TRHelper.year}";
  }
}

String utcMidnight() {
  final n = DateTime.now().toUtc();
  final end =
      DateTime.utc(n.year, n.month, n.day).add(Duration(days: 1)).toLocal();
  return DateFormat.j(Intl.systemLocale).format(end);
}

DateTime endOfDay(DateTime d) {
  return DateTime(d.year, d.month, d.day, 23, 59, 59);
}

DateTime startOfDay(DateTime d) {
  return DateTime(d.year, d.month, d.day);
}

String formatNumber(int value, int major, int minor) {
  double shift = (log(value + 1) / log(10)).ceilToDouble() - major;
  if (shift < 0) {
    shift = 0;
  }
  final j = value / pow(10, shift);
  String mj = "";
  String mn = "";
  if (major == 0 || major > shift) {
    mj = "#";
  } else {
    for (int i = 0; i < major; i += 1) {
      mj += "0";
    }
    if (shift > 0) {
      for (int i = 0; i < minor; i += 1) {
        mn += "0";
      }
      if (!mn.isEmpty) {
        mn = ".$mn";
      }
    }
  }

  final formatter = NumberFormat("$mj${mn}");
  return formatter.format(j);
}

class TruncatedNumber {
  final String value;
  final int groupCount;
  const TruncatedNumber(this.value, this.groupCount);
}

TruncatedNumber formatNumberPlaces(int value, int places) {
  final l = (log(value + 1) / log(10)).ceil();
  int m = l % places;
  if (m == 0) {
    m = places;
  }
  final k = (l - 1) ~/ places;
  int mn = 0;
  if (m == 1) {
    mn = 1;
  }
  return TruncatedNumber(formatNumber(value, m, mn), k);
}

bool isTypeEqual<S, T>() => S == T;

class AlwaysScroll extends MaterialScrollBehavior {
  const AlwaysScroll();

  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.android:
        return const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics());
      // BouncingScrollPhysics();
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics());
    }
  }
}

class ScrollWhenOverflow extends ScrollBehavior {
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

PageRoute route(
    {required Widget Function(BuildContext) builder, RouteSettings? settings}) {
  try {
    if (Platform.isIOS) {
      return CupertinoPageRoute(builder: builder, settings: settings);
    } else if (Platform.isAndroid) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return MaterialPageRoute(builder: builder, settings: settings);
  } catch (e) {
    return MaterialPageRoute(builder: builder, settings: settings);
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
          if (snapshot.hasError) {
            return SliverList(
              delegate: SliverChildListDelegate.fixed(
                [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text(TRGeneral.errorOccurred)],
                  )
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            final circle = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [CircularProgressIndicator()],
            );
            return SliverList(
              delegate: SliverChildListDelegate.fixed([circle]),
            );
          }

          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            final empty = Center(
              child: Text(
                TRHelper.noResults,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            );
            return SliverList(delegate: SliverChildListDelegate.fixed([empty]));
          }

          final dataSource = snapshot.data!.toList();
          final list = SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: count[filterState.current] + 1 + 1,
              (context, index) {
                if (index >= count[filterState.current]) {
                  if (index == count[filterState.current] + 1) {
                    return SizedBox(height: 96);
                  } else if (isLoading[filterState.current]) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [CircularProgressIndicator()],
                    );
                  } else {
                    return const SizedBox();
                  }
                }
                const remainingItemsBeforeLoadingMore = 10;
                final indexPoint = count[filterState.current] -
                    remainingItemsBeforeLoadingMore;
                final underLimit =
                    count[filterState.current] < 10 && index == 0;
                if (hasMore[filterState.current] &&
                    (index == indexPoint || underLimit)) {
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
                }
                final item = dataSource[index];
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
                  return comment.tile(
                      context,
                      false,
                      0,
                      null,
                      null,
                      (c) => c.showParentPost(context)(),
                      updateState,
                      null,
                      false,
                      false,
                      false);
                } else if (isTypeEqual<T, FlaggedPost>()) {
                  final flag = item as FlaggedPost;
                  final content = flag.content.tile(context, updateState);
                  final review = flag.card(context, updateState);
                  return Column(children: [content, review]);
                } else if (isTypeEqual<T, FlaggedComment>()) {
                  final flag = (item as FlaggedComment);
                  final content = flag.content.tile(
                    context,
                    false,
                    0,
                    null,
                    null,
                    (c) => c.showParentPost(context)(),
                    updateState,
                    null,
                    false,
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
                  return comment.comment.tile(
                      context,
                      false,
                      0,
                      null,
                      null,
                      (c) => c.showParentPost(context)(),
                      updateState,
                      null,
                      false,
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

Widget buildCountItemList(Future<int> item) {
  return FutureBuilder(
    future: item,
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
      if (snapshot.data == null || snapshot.data! <= 0) {
        return SliverList(delegate: SliverChildListDelegate.fixed([]));
      }
      return SliverList(
        delegate: SliverChildListDelegate.fixed([
          Center(
            child: Text(TRHelper.numberOfUsers(snapshot.data!)),
          )
        ]),
      );
    },
  );
}

Widget buildFilteredList<T>(
  Widget list,
  FilterBoxState filterState,
  void Function(FilterBoxState) updateFilterState,
  bool showingFilter,
  void Function(void Function()) updateFilter,
  Widget? header,
) {
  late final Widget sliver;
  final filterBox = FilterBox(
    filterKey: GlobalKey(),
    valueChanged: (state) => updateFilterState(state),
    state: filterState,
  );

  var stack = <Widget>[];
  var finalHeader = [];
  if (header != null) {
    finalHeader.add(header);
  }
  if (showingFilter) {
    sliver = CustomScrollView(
      slivers: [
        ...finalHeader,
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
        ...finalHeader,
        list,
      ],
    );
    final pull = RefreshIndicator(
        child: sliver, onRefresh: () async => updateFilter(() {}));
    stack.add(pull);
  }

  return Stack(children: stack);
}

Future<String> deviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  if (kIsWeb) {
    final info = await deviceInfo.webBrowserInfo;
    return info.userAgent ?? "web";
  } else if (Platform.isAndroid) {
    final info = await deviceInfo.androidInfo;
    return info.id;
  } else if (Platform.isIOS) {
    final info = await deviceInfo.iosInfo;
    return info.identifierForVendor ?? "ios";
  } else {
    return "other";
  }
}

String sha256Hash(String s) {
  final bytes = utf8.encode("[_${s}_]");
  final digest = sha256.convert(bytes);
  final result = base64Encode(digest.bytes);
  return result;
}

extension Union<K, V> on Map<K, V> {
  Map<K, V> addingAll(Map<K, V> other) {
    addAll(other);
    return this;
  }
}

Map<K, V> combineMaps<K, V>(List<Map<K, V>> operands) {
  var result = <K, V>{};
  for (final op in operands) {
    result.addAll(op);
  }
  return result;
}

void displayError(BuildContext? context, Object e) {
  if (context != null) {
    if (e == notValidated && User.current?.email != "") {
      if (User.current?.email == "temp@new-source.app") {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
        return;
      }
      showPlatformDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(TRError.notValidated),
          actions: [
            ElevatedButton(
                onPressed: () async {
                  if (User.current == null) {
                    return;
                  }
                  try {
                    await NewSource.sendVerificationLink(User.current!.id,
                        User.current!.email, User.current!.validationKey);
                  } catch (e) {
                    displayError(context, e);
                  }
                },
                child: Text(TREmailVerify.resend)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(TRGeneral.okay),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

void displayString(BuildContext? context, String s) {
  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
    }
  });
}

class InOut<T> {
  T value;
  InOut(this.value);
}
