import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/widgets/filter_widget.dart';
import 'package:social_news_app/widgets/location_picker.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/posts_page.dart';
import 'helpers.dart';

class SearchPage extends StatefulWidget {
  final bool hasSearch;
  bool shouldShowFilter;

  SearchPage({super.key, required this.hasSearch}) : shouldShowFilter = true;

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  late Future<List<Tag>> tags;
  late Future<List<Post>> posts;
  late Future<List<Author>> users;
  late Future<List<Comment>> comments;

  var current = 0;
  var offset = [0, 0, 0, 0];
  var pageSize = 20;
  var count = [0, 0, 0, 0];
  var hasMore = [true, true, true, true];
  var isLoading = [true, true, true, true];
  late final FilterBox filterBox;

  @override
  void initState() {
    super.initState();

    posts = Future(() => []);
    users = Future(() => []);
    comments = Future(() => []);

    const selector = <int, String>{
      0: "Tags",
      1: "Posts",
      2: "Users",
      3: "Comments"
    };
    final search = widget.hasSearch;
    const sortOrder = SortOrder.values;
    final date = !widget.hasSearch;
    final location = !widget.hasSearch;

    filterBox = FilterBox(
      selector: selector,
      sorting: sortOrder,
      search: search,
      date: date,
      location: location,
      valueChanged: (FilterBoxState fb) {
        updateFilter(() {
          current = fb.current;
        });
      },
    );

    if (widget.hasSearch) {
      tags = Future(() => []);
    } else {
      updateFilter(() {
        current = 0;
      });
    }
  }

  int currentIndex<T>() {
    if (isTypeEqual<T, Tag>()) {
      return 0;
    } else if (isTypeEqual<T, Post>()) {
      return 1;
    } else if (isTypeEqual<T, Author>()) {
      return 2;
    } else if (isTypeEqual<T, Comment>()) {
      return 3;
    } else {
      return 100;
    }
  }

  Future<List<T>> getNewItems<T>() async {
    final idx = currentIndex<T>();
    final sd = widget.hasSearch ? null : filterBox.currentState?.start;
    final ed = widget.hasSearch ? null : filterBox.currentState?.end;
    final loc = filterBox.currentState?.location;
    final src = filterBox.currentState?.search;
    final so = filterBox.currentState?.order;
    if (isTypeEqual<T, Tag>()) {
      return NewSource.getTags(
        offset: offset[idx],
        limit: pageSize,
        order: so,
        start: sd,
        end: ed,
        location: loc,
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, Post>()) {
      return NewSource.getPosts(
        offset: offset[idx],
        limit: pageSize,
        order: so,
        start: sd,
        end: ed,
        popularIn: loc,
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, Author>()) {
      return NewSource.getUsers(
        offset: offset[idx],
        limit: pageSize,
        order: so,
        start: sd,
        end: ed,
        popularIn: loc,
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, Comment>()) {
      return NewSource.getComments(
        offset: offset[idx],
        limit: pageSize,
        order: so,
        start: sd,
        end: ed,
        popularIn: loc,
        search: src,
      ) as Future<List<T>>;
    } else {
      return Future(() => <T>[]);
    }
  }

  Future<List<T>> updateItemsState<T>(List<T> value) async {
    count[current] += value.length;
    isLoading[current] = false;
    return value;
  }

  void updateFilter(void Function() f) {
    setState(() {
      f();
      count[current] = 0;
      offset[current] = 0;
      isLoading[current] = true;
      if (current == 0) {
        tags = getNewItems<Tag>().then(updateItemsState);
      } else if (current == 1) {
        posts = getNewItems<Post>().then(updateItemsState);
      } else if (current == 2) {
        users = getNewItems<Author>().then(updateItemsState);
      } else if (current == 3) {
        comments = getNewItems<Comment>().then(updateItemsState);
      }
      offset[current] = pageSize;
    });
  }

  void _loadMore<T>(Future<List<T>> newItems, Future<List<T>> oldItems) async {
    final newPosts = await newItems;
    var oldPosts = await oldItems;
    offset[current] += newPosts.length;
    if (newPosts.isEmpty) {
      hasMore[current] = false;
    }
    oldPosts.addAll(newPosts);
    count[current] = oldPosts.length;
    setState(() {
      isLoading[current] = false;
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
        top: !widget.shouldShowFilter ? 0 : filterBox.getWidgetSize().height);
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
              itemCount: count[current] + 1,
              padding: listViewInsets(),
              itemBuilder: (context, index) {
                if (index >= count[current]) {
                  if (isLoading[current]) {
                    return const CircularProgressIndicator();
                  } else if (hasMore[current]) {
                    if (current == 0) {
                      final newItems = getNewItems<Tag>();
                      _loadMore(newItems, tags);
                    } else if (current == 1) {
                      final newItems = getNewItems<Post>();
                      _loadMore(newItems, posts);
                    } else if (current == 2) {
                      final newItems = getNewItems<Author>();
                      _loadMore(newItems, users);
                    } else if (current == 3) {
                      final newItems = getNewItems<Comment>();
                      _loadMore(newItems, comments);
                    }
                    isLoading[current] = true;
                    return const CircularProgressIndicator();
                  } else {
                    return const SizedBox();
                  }
                }
                final item = snapshot.data![index];
                if (current == 0) {
                  final tag = item as Tag;
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
                  return (item as Post).tile(context, updateState);
                } else if (current == 2) {
                  final user = item as Author;
                  return ListTile(
                      title: Text(user.Name),
                      onTap: () => user.showUserPage(context));
                } else if (current == 3) {
                  final comment = item as Comment;
                  return comment.card(context, false, 0,
                      (c) => c.showParentPost(context)(), updateState, null);
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
      stack.add(Visibility(
        visible: widget.shouldShowFilter,
        maintainState: true,
        child: filterBox,
      ));
    }

    return Stack(children: stack);
  }
}
