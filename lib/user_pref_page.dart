import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/filter_widget.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/location_picker.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/model/user_pref.dart';
import 'package:social_news_app/posts_page.dart';

class UserPrefPage extends StatefulWidget {
  final bool showSearch;
  final int prefKind;
  final Author user;

  const UserPrefPage(
      {super.key,
      required this.showSearch,
      required this.prefKind,
      required this.user});

  @override
  State<UserPrefPage> createState() => _UserPrefPageState();
}

class _UserPrefPageState extends State<UserPrefPage> {
  late Future<List<UserPrefTag>> tags;
  late Future<List<UserPrefPost>> posts;
  late Future<List<UserPrefUser>> users;
  late Future<List<UserPrefComment>> comments;

  var current = 0;
  var offset = 0;
  var pageSize = 20;
  var count = 0;
  var hasMore = true;
  var isLoading = false;
  FilterBox? filterBox;

  @override
  void initState() {
    super.initState();

    current = widget.prefKind;

    tags = Future(() => []);
    posts = Future(() => []);
    users = Future(() => []);
    comments = Future(() => []);
    if (current == 0) {
      tags = getNewItems<UserPrefTag>().then(updateItemsState);
    } else if (current == 1) {
      posts = getNewItems<UserPrefPost>().then(updateItemsState);
    } else if (current == 2) {
      users = getNewItems<UserPrefUser>().then(updateItemsState);
    } else if (current == 3) {
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
    final sd = filterBox?.currentState?.start;
    final ed = filterBox?.currentState?.end;
    final loc = filterBox?.currentState?.location;
    final src = filterBox?.currentState?.search;
    if (isTypeEqual<T, UserPrefTag>()) {
      return NewSource.getUserPrefTags(
        uid: widget.user.ID,
        offset: offset,
        limit: pageSize,
        order: SortOrder.upvotes, // FIXME: sort by vote date?
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefPost>()) {
      return NewSource.getUserPrefPosts(
        uid: widget.user.ID,
        offset: offset,
        limit: pageSize,
        order: SortOrder.createdAt, // FIXME: sort by vote date?
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefUser>()) {
      return NewSource.getUserPrefUsers(
        uid: widget.user.ID,
        offset: offset,
        limit: pageSize,
        order: SortOrder.upvotes, // FIXME: sort by vote date?
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefComment>()) {
      return NewSource.getUserPrefComments(
        uid: widget.user.ID,
        offset: offset,
        limit: pageSize,
        order: SortOrder.createdAt, // FIXME: sort by vote date?
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
      if (current == 0) {
        tags = getNewItems<UserPrefTag>().then(updateItemsState);
      } else if (current == 1) {
        posts = getNewItems<UserPrefPost>().then(updateItemsState);
      } else if (current == 2) {
        users = getNewItems<UserPrefUser>().then(updateItemsState);
      } else if (current == 3) {
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

  Widget buildList<T>(BuildContext context, Future<List<T>> items) {
    return FutureBuilder<List<T>>(
        future: items,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == null || snapshot.data?.isEmpty == true) {
              return const SizedBox();
            }
            return ListView.builder(
                itemCount: count,
                padding: const EdgeInsets.only(top: 114.0),
                itemBuilder: (context, index) {
                  if (index >= count) {
                    if (isLoading) {
                      return const CircularProgressIndicator();
                    } else if (hasMore) {
                      if (current == 0) {
                        final newItems = getNewItems<UserPrefTag>();
                        _loadMore(newItems, tags);
                      } else if (current == 1) {
                        final newItems = getNewItems<UserPrefPost>();
                        _loadMore(newItems, posts);
                      } else if (current == 2) {
                        final newItems = getNewItems<UserPrefUser>();
                        _loadMore(newItems, users);
                      } else if (current == 3) {
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
                  if (current == 0) {
                    final tag = (item as UserPrefTag).tag;
                    final page = Scaffold(
                      appBar: AppBar(title: Text(tag.Name)),
                      body: PostsPage(tags: [tag.ID]),
                    );
                    return ListTile(
                      title: Text(tag.Name),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => page),
                      ),
                    );
                  } else if (current == 1) {
                    return (item as UserPrefPost)
                        .post
                        .card(context, false, updateState);
                  } else if (current == 2) {
                    // FIXME: Show user profile on tap
                    return ListTile(
                        title: Text((item as UserPrefUser).author.Name));
                  } else if (current == 3) {
                    final comment = (item as UserPrefComment).comment;
                    return comment.card(context, false, 0,
                        (c) => c.showParentPost(context)(), updateState);
                  } else {
                    return const SizedBox();
                  }
                });
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return const CircularProgressIndicator();
        });
  }

  @override
  Widget build(BuildContext context) {
    filterBox = FilterBox(
      search: true,
      valueChanged: (p0) {
        updateFilter(() {});
      },
    );
    late final Widget list;

    if (current == 0) {
      list = buildList(context, tags);
    } else if (current == 1) {
      list = buildList(context, posts);
    } else if (current == 2) {
      list = buildList(context, users);
    } else if (current == 3) {
      list = buildList(context, comments);
    } else {
      list = const SizedBox();
    }

    var stack = <Widget>[list];
    if (filterBox != null) {
      stack.add(filterBox!);
    }

    return Stack(children: stack);
  }
}
