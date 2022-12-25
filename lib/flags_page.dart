import 'package:flutter/material.dart';
import 'package:social_news_app/widgets/filter_widget.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';

class FlagsPage extends StatefulWidget {
  final bool isPosts;
  const FlagsPage({super.key, required this.isPosts});

  @override
  State<FlagsPage> createState() => _FlagsPageState();
}

class _FlagsPageState extends State<FlagsPage> {
  late Future<List<FlaggedPost>> posts;
  late Future<List<FlaggedComment>> comments;
  late TextEditingController controller;

  var offset = flagSet().keys.map((e) => 0).toList();
  var pageSize = 20;
  var count = flagSet().keys.map((e) => 0).toList();
  var hasMore = flagSet().keys.map((e) => true).toList();
  var isLoading = flagSet().keys.map((e) => false).toList();
  late FilterBoxState filterState;
  bool showingFilter = false;
  double? filterHeight;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController();
    filterState = FilterBoxState(
      current: 0,
      displaySelector: flagSet(),
    );

    posts = Future(() => []);
    comments = Future(() => []);
    if (widget.isPosts) {
      posts = getNewItems<FlaggedPost>().then(updateItemsState);
    } else {
      comments = getNewItems<FlaggedComment>().then(updateItemsState);
    }

    offset[filterState.current] = pageSize;
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
    // final idx = currentIndex<T>();
    // final sd = filterState.startDate;
    // final ed = filterState.endDate;
    // final loc =
    //     filterState.location?.isEmpty == true ? null : filterState.location;
    // final src = filterState.search?.isEmpty == true ? null : filterState.search;
    final rsn = filterState.current;
    try {
      if (isTypeEqual<T, FlaggedPost>()) {
        return NewSource.getFlaggedPosts(
          FlagReason.values[rsn],
          pageSize,
          offset[filterState.current],
        ) as Future<List<T>>;
      } else if (isTypeEqual<T, FlaggedComment>()) {
        return NewSource.getFlaggedComments(
          FlagReason.values[rsn],
          pageSize,
          offset[filterState.current],
        ) as Future<List<T>>;
      } else {
        return Future(() => <T>[]);
      }
    } catch (e) {
      displayError(context, e);
      return Future(() => <T>[]);
    }
  }

  Future<List<T>> updateItemsState<T>(List<T> value) async {
    count[filterState.current] += value.length;
    isLoading[filterState.current] = false;
    return value;
  }

  void updateFilter(void Function() f) {
    setState(() {
      f();
      count[filterState.current] = 0;
      offset[filterState.current] = 0;
      isLoading[filterState.current] = true;
      if (widget.isPosts) {
        posts = getNewItems<FlaggedPost>().then(updateItemsState);
      } else {
        comments = getNewItems<FlaggedComment>().then(updateItemsState);
      }
      offset[filterState.current] = pageSize;
    });
  }

  void updateFilterState(FilterBoxState state) {
    filterState = state;
    updateFilter(() {});
  }

  void loadMore<T>(Future<List<T>> newItems, Future<List<T>> oldItems) async {
    final newPosts = await newItems;
    var oldPosts = await oldItems;
    offset[filterState.current] += newPosts.length;
    if (newPosts.isEmpty) {
      hasMore[filterState.current] = false;
    }
    oldPosts.addAll(newPosts);
    setState(() {
      count[filterState.current] = oldPosts.length;
      isLoading[filterState.current] = false;
    });
    oldItems = Future(() => oldPosts);
  }

  void updateState() {
    setState(() {});
  }

  EdgeInsets listViewInsets() {
    // final h = filterBox.getWidgetSize().height;
    // if (filterHeight == null && h != 0) {
    //   filterHeight = h;
    // }
    return EdgeInsets.only(
      top: !showingFilter ? 0 : filterHeight!,
      bottom: 48,
    );
  }

  @override
  Widget build(BuildContext context) {
    late final Widget list;
    late final Widget sliver;

    final buildList = buildFutureList(
      context,
      loadMore,
      filterState,
      count,
      isLoading,
      hasMore,
      getNewItems,
      updateState,
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
      posts,
      comments,
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
    );

    if (widget.isPosts) {
      list = buildList(posts);
    } else {
      list = buildList(comments);
    }
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
      stack.add(sliver);
      stack.add(filterBox);
    } else {
      sliver = CustomScrollView(
        slivers: [
          SliverList(delegate: SliverChildListDelegate([filterBox])),
          list,
        ],
      );
      stack.add(sliver);
    }

    final page = Stack(children: stack);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPosts ? "Flagged Posts" : "Flagged Comments"),
        actions: [
          IconButton(
            onPressed: () {
              showingFilter = !showingFilter;
              updateState();
            },
            icon: showingFilter
                ? const Icon(Icons.filter_alt_rounded)
                : const Icon(Icons.filter_alt_outlined),
          )
        ],
      ),
      body: page,
    );
  }
}
