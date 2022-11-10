import 'package:flutter/material.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/widgets/filter_widget.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/user.dart';

class UserContPage extends StatefulWidget {
  final bool showSearch;
  final ContentKind kind;
  final UserContKind playlist;
  final Author user;
  String title;

  UserContPage(
      {super.key,
      required this.title,
      required this.showSearch,
      required this.kind,
      required this.playlist,
      required this.user});

  @override
  State<UserContPage> createState() => _UserContPageState();
}

class _UserContPageState extends State<UserContPage> {
  late Future<List<Post>> posts;
  late Future<List<Comment>> comments;
  late Future<List<Author>> users;
  late TextEditingController controller;

  var current = ContentKind.post;
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

    controller = TextEditingController();
    current = widget.kind;
    filterBox = FilterBox(
      search: "",
      sorting: sortOrdersIncluding([SortOrder.addedOn]),
      startDate: DateTime.utc(1970),
      endDate: DateTime.now(),
      location: "",
      valueChanged: (p0) {
        updateFilter(() {});
      },
    );

    posts = Future(() => []);
    comments = Future(() => []);
    users = Future(() => []);
    if (current == ContentKind.post) {
      posts = getNewItems<Post>().then(updateItemsState);
    } else if (current == ContentKind.comment) {
      comments = getNewItems<Comment>().then(updateItemsState);
    } else if (current == ContentKind.user) {
      users = getNewItems<Author>().then(updateItemsState);
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
    } else if (isTypeEqual<T, Author>()) {
      return 2;
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
    if (isTypeEqual<T, Post>()) {
      return NewSource.getUserContPost(
        uid: widget.user.id,
        kind: widget.playlist,
        location: loc,
        startCreated: sd,
        endCreated: ed,
        offset: offset,
        limit: pageSize,
        order: srt,
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, Comment>()) {
      return NewSource.getUserContComments(
        uid: widget.user.id,
        startCreated: sd,
        endCreated: ed,
        offset: offset,
        limit: pageSize,
        order: srt,
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, Author>()) {
      if (widget.playlist == UserContKind.userFollow) {
        return NewSource.getUserContUsers(
          widget.user.id,
          UserContKind.userFollow,
          startDate: sd,
          endDate: ed,
        ) as Future<List<T>>;
      } else if (widget.playlist == UserContKind.ignored) {
        return NewSource.getUserContUsers(
          widget.user.id,
          UserContKind.ignored,
          startDate: sd,
          endDate: ed,
        ) as Future<List<T>>;
      } else {
        return Future(() => <T>[]);
      }
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
      if (current == ContentKind.post) {
        posts = getNewItems<Post>().then(updateItemsState);
      } else if (current == ContentKind.comment) {
        comments = getNewItems<Comment>().then(updateItemsState);
      } else if (current == ContentKind.user) {
        users = getNewItems<Author>().then(updateItemsState);
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
                    if (current == ContentKind.post) {
                      final newItems = getNewItems<Post>();
                      _loadMore(newItems, posts);
                    } else if (current == ContentKind.comment) {
                      final newItems = getNewItems<Comment>();
                      _loadMore(newItems, comments);
                    } else if (current == ContentKind.user) {
                      final newItems = getNewItems<Author>();
                      _loadMore(newItems, users);
                    }
                    isLoading = true;
                    return const CircularProgressIndicator();
                  } else {
                    return const SizedBox();
                  }
                }
                final item = snapshot.data![index];
                if (current == ContentKind.post) {
                  return (item as Post).tile(context, updateState);
                } else if (current == ContentKind.comment) {
                  final comment = (item as Comment);
                  return comment.card(
                      context,
                      false,
                      0,
                      (c) => c.showParentPost(context)(),
                      updateState,
                      null,
                      false);
                } else if (current == ContentKind.user) {
                  final user = item as Author;
                  return user.card(context, updateState);
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

    if (current == ContentKind.post) {
      list = buildList(context, posts);
    } else if (current == ContentKind.comment) {
      list = buildList(context, comments);
    } else if (current == ContentKind.user) {
      list = buildList(context, users);
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
