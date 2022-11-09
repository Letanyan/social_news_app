import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/widgets/filter_widget.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/widgets/location_picker.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/model/user_pref.dart';
import 'package:social_news_app/posts_page.dart';

class UserPrefPage extends StatefulWidget {
  final bool showSearch;
  final ContentKind prefKind;
  final Author user;
  final bool isViewed;
  String title;

  UserPrefPage(
      {super.key,
      required this.title,
      required this.showSearch,
      required this.prefKind,
      required this.user,
      required this.isViewed});

  @override
  State<UserPrefPage> createState() => _UserPrefPageState();
}

class _UserPrefPageState extends State<UserPrefPage> {
  late Future<List<UserPrefTag>> tags;
  late Future<List<UserPrefPost>> posts;
  late Future<List<UserPrefUser>> users;
  late Future<List<UserPrefComment>> comments;

  var current = ContentKind.tag;
  var offset = 0;
  var pageSize = 20;
  var count = 0;
  var hasMore = true;
  var isLoading = false;
  late final FilterBox filterBox;
  bool showingFilter = true;

  @override
  void initState() {
    super.initState();

    current = widget.prefKind;
    filterBox = FilterBox(
      search: "",
      startDate: DateTime.utc(1970),
      endDate: DateTime.now(),
      location: widget.prefKind == ContentKind.post ? "" : null,
      sorting: sortOrdersIncluding([SortOrder.updatedOn]),
      valueChanged: (p0) {
        updateFilter(() {});
      },
    );

    tags = Future(() => []);
    posts = Future(() => []);
    users = Future(() => []);
    comments = Future(() => []);
    if (current == ContentKind.tag) {
      tags = getNewItems<UserPrefTag>().then(updateItemsState);
    } else if (current == ContentKind.post) {
      posts = getNewItems<UserPrefPost>().then(updateItemsState);
    } else if (current == ContentKind.user) {
      users = getNewItems<UserPrefUser>().then(updateItemsState);
    } else if (current == ContentKind.comment) {
      comments = getNewItems<UserPrefComment>().then(updateItemsState);
    }

    offset = pageSize;
  }

  int currentIndex<T>() {
    if (isTypeEqual<T, UserPrefTag>()) {
      return 0;
    } else if (isTypeEqual<T, UserPrefPost>()) {
      return 1;
    } else if (isTypeEqual<T, UserPrefUser>()) {
      return 2;
    } else if (isTypeEqual<T, UserPrefComment>()) {
      return 3;
    } else {
      return 100;
    }
  }

  Future<List<T>> getNewItems<T>() async {
    final idx = currentIndex<T>();
    final sd = filterBox.currentState?.start;
    final ed = filterBox.currentState?.end;
    final loc = filterBox.currentState?.location;
    final srt = filterBox.currentState?.order;
    final src = filterBox.currentState?.search;
    if (isTypeEqual<T, UserPrefTag>()) {
      return NewSource.getUserPrefTags(
        uid: widget.user.ID,
        startVoted: sd,
        endVoted: ed,
        offset: offset,
        limit: pageSize,
        order: srt, // FIXME: sort by vote date?
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefPost>()) {
      return NewSource.getUserPrefPosts(
        uid: widget.user.ID,
        location: loc,
        startVoted: sd,
        endVoted: ed,
        offset: offset,
        limit: pageSize,
        order: srt, // FIXME: sort by vote date?
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefUser>()) {
      return NewSource.getUserPrefUsers(
        uid: widget.user.ID,
        startVoted: sd,
        endVoted: ed,
        offset: offset,
        limit: pageSize,
        order: srt, // FIXME: sort by vote date?
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefComment>()) {
      return NewSource.getUserPrefComments(
        uid: widget.user.ID,
        startVoted: sd,
        endVoted: ed,
        offset: offset,
        limit: pageSize,
        order: srt, // FIXME: sort by vote date?
        search: src,
      ) as Future<List<T>>;
    } else {
      return Future(() => <T>[]);
    }
  }

  Future<List<T>> updateItemsState<T>(List<T> value) async {
    count += value.length;
    isLoading = false;
    return value;
  }

  void updateFilter(void Function() f) {
    setState(() {
      f();
      count = 0;
      offset = 0;
      isLoading = true;
      if (current == ContentKind.tag) {
        tags = getNewItems<UserPrefTag>().then(updateItemsState);
      } else if (current == ContentKind.post) {
        posts = getNewItems<UserPrefPost>().then(updateItemsState);
      } else if (current == ContentKind.user) {
        users = getNewItems<UserPrefUser>().then(updateItemsState);
      } else if (current == ContentKind.comment) {
        comments = getNewItems<UserPrefComment>().then(updateItemsState);
      }
      offset = pageSize;
    });
  }

  void _loadMore<T>(Future<List<T>> newItems, Future<List<T>> oldItems) async {
    final newPosts = await newItems;
    var oldPosts = await oldItems;
    offset += newPosts.length;
    if (newPosts.isEmpty) {
      hasMore = false;
    }
    oldPosts.addAll(newPosts);
    setState(() {
      count = oldPosts.length;
      isLoading = false;
    });
    oldItems = Future(() => oldPosts);
  }

  Widget makeList() {
    return ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return const ListTile(title: Text("Test"));
        });
  }

  void updateState() {
    setState(() {});
  }

  EdgeInsets listViewInsets() {
    return EdgeInsets.only(
      top: !showingFilter ? 0 : filterBox.getWidgetSize().height,
      bottom: 48,
    );
  }

  Widget buildList<T>(BuildContext context, Future<List<T>> items) {
    return FutureBuilder<List<T>>(
        future: items,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == null || snapshot.data?.isEmpty == true) {
              return const SizedBox();
            }
            final list = ListView.builder(
              itemCount: count,
              padding: listViewInsets(),
              itemBuilder: (context, index) {
                if (index >= count) {
                  if (isLoading) {
                    return const CircularProgressIndicator();
                  } else if (hasMore) {
                    if (current == ContentKind.tag) {
                      final newItems = getNewItems<UserPrefTag>();
                      _loadMore(newItems, tags);
                    } else if (current == ContentKind.post) {
                      final newItems = getNewItems<UserPrefPost>();
                      _loadMore(newItems, posts);
                    } else if (current == ContentKind.user) {
                      final newItems = getNewItems<UserPrefUser>();
                      _loadMore(newItems, users);
                    } else if (current == ContentKind.comment) {
                      final newItems = getNewItems<UserPrefComment>();
                      _loadMore(newItems, comments);
                    }
                    isLoading = true;
                    return const CircularProgressIndicator();
                  } else {
                    return const SizedBox();
                  }
                }
                final item = snapshot.data![index];
                if (current == ContentKind.tag) {
                  final tag = item as UserPrefTag;
                  return tag.tag.card(context, updateState,
                      up: tag.upvotes, down: tag.downvotes);
                } else if (current == ContentKind.post) {
                  final post = item as UserPrefPost;
                  return post.post.tile(context, updateState,
                      up: post.upvotes, down: post.downvotes);
                } else if (current == ContentKind.user) {
                  final user = item as UserPrefUser;
                  return user.author.card(context, updateState,
                      up: user.upvotes, down: user.downvotes);
                } else if (current == ContentKind.comment) {
                  final comment = (item as UserPrefComment);
                  return comment.comment.card(
                      context,
                      false,
                      0,
                      (c) => c.showParentPost(context)(),
                      updateState,
                      null,
                      false,
                      up: comment.upvotes,
                      down: comment.downvotes);
                } else {
                  return const SizedBox();
                }
              },
            );
            return RefreshIndicator(
              onRefresh: () async {
                updateFilter(() {});
              },
              child: list,
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return const CircularProgressIndicator();
        });
  }

  @override
  Widget build(BuildContext context) {
    late final Widget list;
    if (current == ContentKind.tag) {
      list = buildList(context, tags);
    } else if (current == ContentKind.post) {
      list = buildList(context, posts);
    } else if (current == ContentKind.user) {
      list = buildList(context, users);
    } else if (current == ContentKind.comment) {
      list = buildList(context, comments);
    } else {
      list = const SizedBox();
    }

    var stack = <Widget>[list];
    stack.add(Visibility(
      visible: showingFilter,
      maintainState: true,
      child: filterBox,
    ));
    final page = Stack(children: stack);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              showingFilter = !showingFilter;
              updateState();
            },
            icon: const Icon(Icons.filter_alt_rounded),
          )
        ],
      ),
      body: page,
    );
  }
}
