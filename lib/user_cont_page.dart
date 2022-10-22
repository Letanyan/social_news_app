import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/filter_widget.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/location_picker.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/user.dart';

class UserContPage extends StatefulWidget {
  final bool showSearch;
  final bool isPost;
  final int playlist;
  final Author user;

  const UserContPage(
      {super.key,
      required this.showSearch,
      required this.isPost,
      required this.playlist,
      required this.user});

  @override
  State<UserContPage> createState() => _UserContPageState();
}

class _UserContPageState extends State<UserContPage> {
  late Future<List<Post>> posts;
  late Future<List<Comment>> comments;
  late TextEditingController controller;

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

    controller = TextEditingController();
    current = widget.isPost ? 0 : 1;

    posts = Future(() => []);
    comments = Future(() => []);
    if (current == 0) {
      posts = getNewItems<Post>().then(updateItemsState);
    } else if (current == 1) {
      comments = getNewItems<Comment>().then(updateItemsState);
    }

    offset = pageSize;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  int currentIndex<T>() {
    if (isTypeEqual<T, Post>()) {
      return 0;
    } else if (isTypeEqual<T, Comment>()) {
      return 1;
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
    if (isTypeEqual<T, Post>()) {
      return NewSource.getUserContPost(
        uid: widget.user.ID,
        kind: widget.playlist,
        offset: offset,
        limit: pageSize,
        order: "createdat",
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, Comment>()) {
      return NewSource.getUserContComments(
        uid: widget.user.ID,
        offset: offset,
        limit: pageSize,
        order: "createdat",
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
      if (current == 0) {
        posts = getNewItems<Post>().then(updateItemsState);
      } else if (current == 1) {
        comments = getNewItems<Comment>().then(updateItemsState);
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
                        final newItems = getNewItems<Post>();
                        _loadMore(newItems, posts);
                      } else if (current == 1) {
                        final newItems = getNewItems<Comment>();
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
                    return (item as Post).card(context, false, updateState);
                  } else if (current == 1) {
                    final comment = (item as Comment);
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
      list = buildList(context, posts);
    } else if (current == 1) {
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
