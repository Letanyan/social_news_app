import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/widgets/filter_widget.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';

class FlagsPage extends StatefulWidget {
  final bool isPosts;
  bool shouldShowFilter;
  FlagsPage({super.key, required this.isPosts}) : shouldShowFilter = true;

  @override
  State<FlagsPage> createState() => _FlagsPageState();
}

class _FlagsPageState extends State<FlagsPage> {
  late Future<List<FlaggedPost>> posts;
  late Future<List<FlaggedComment>> comments;
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
    current = widget.isPosts ? 0 : 1;

    posts = Future(() => []);
    comments = Future(() => []);
    if (current == 0) {
      posts = getNewItems<FlaggedPost>().then(updateItemsState);
    } else if (current == 1) {
      comments = getNewItems<FlaggedComment>().then(updateItemsState);
    }

    offset = pageSize;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  int currentIndex<T>() {
    if (isTypeEqual<T, FlaggedPost>()) {
      return 0;
    } else if (isTypeEqual<T, FlaggedComment>()) {
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
    final rsn = filterBox?.currentState?.current ?? 0;
    if (isTypeEqual<T, FlaggedPost>()) {
      return NewSource.getFlaggedPosts(FlagReason.values[rsn], pageSize, offset)
          as Future<List<T>>;
    } else if (isTypeEqual<T, FlaggedComment>()) {
      return NewSource.getFlaggedComments(
          FlagReason.values[rsn], pageSize, offset) as Future<List<T>>;
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
        posts = getNewItems<FlaggedPost>().then(updateItemsState);
      } else if (current == 1) {
        comments = getNewItems<FlaggedComment>().then(updateItemsState);
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
        top: !widget.shouldShowFilter
            ? 0
            : filterBox?.getWidgetSize().height ?? 0);
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
                    if (current == 0) {
                      final newItems = getNewItems<FlaggedPost>();
                      _loadMore(newItems, posts);
                    } else if (current == 1) {
                      final newItems = getNewItems<FlaggedComment>();
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
                  final flag = item as FlaggedPost;
                  final content = flag.content.tile(context, updateState);
                  final review = flag.card(context, () => setState(() {}));
                  return Column(children: [content, review]);
                } else if (current == 1) {
                  final flag = (item as FlaggedComment);
                  final content = flag.content.card(
                    context,
                    false,
                    0,
                    (c) => c.showParentPost(context)(),
                    updateState,
                    null,
                  );
                  final review = flag.card(context, () => setState(() {}));
                  return Column(children: [content, review]);
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
    filterBox = FilterBox(
      selector: flagSet(),
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
