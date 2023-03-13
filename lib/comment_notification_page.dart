import 'package:flutter/material.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/widgets/filter_widget.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/user.dart';

class CommentNotificationPage extends StatefulWidget {
  final bool showSearch;
  final Author user;
  final String title;

  const CommentNotificationPage({
    super.key,
    required this.title,
    required this.showSearch,
    required this.user,
  });

  @override
  State<CommentNotificationPage> createState() =>
      _CommentNotificationPageState();
}

class _CommentNotificationPageState extends State<CommentNotificationPage> {
  late Future<List<Comment>> comments;
  late TextEditingController controller;

  var offset = [0];
  var pageSize = [20];
  var count = [0];
  var hasMore = [true];
  var isLoading = [false];
  var forContent = false;
  late FilterBoxState filterState;
  var filterKey = GlobalKey();
  bool showingFilter = false;
  double? filterHeight;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController();
    filterState = FilterBoxState(
      current: 0,
      search: "",
      displaySelector: null,
      displaySorting: forContent
          ? [
              SortOrder.addedOn,
              SortOrder.controversial,
              SortOrder.upvotes,
              SortOrder.downvotes,
            ]
          : sortOrdersIncluding([
              SortOrder.addedOn,
            ]),
      startDate: forContent ? null : DateTime(2022),
      endDate: forContent ? null : DateTime.now(),
      order: SortOrder.addedOn,
      location: forContent ? null : [],
    );

    comments = getNewItems<Comment>().then(updateItemsState);
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
    } else if (isTypeEqual<T, Tag>()) {
      return 3;
    } else if (forContent) {
      return 4;
    } else {
      return 100;
    }
  }

  Future<List<T>> getNewItems<T>() async {
    try {
      return NewSource.getCommentNotifications(
          widget.user.id, pageSize[0], offset[0]) as Future<List<T>>;
    } catch (e) {
      displayError(context, e);
      return Future(() => <T>[]);
    }
  }

  Future<List<T>> updateItemsState<T>(List<T> value) async {
    count[0] += value.length;
    isLoading[0] = false;
    return value;
  }

  void updateFilter(void Function() f) {
    setState(() {
      f();
      count[0] = 0;
      offset[0] = 0;
      isLoading[0] = true;
      hasMore[0] = true;
      comments = getNewItems<Comment>().then(updateItemsState);
      offset = pageSize;
    });
  }

  void updateFilterState(FilterBoxState state) {
    filterState = state;
    updateFilter(() {});
  }

  void _loadMore<T>(Future<List<T>> newItems, Future<List<T>> oldItems) async {
    final newPosts = await newItems;
    var oldPosts = await oldItems;
    offset[0] += newPosts.length;
    if (newPosts.isEmpty) {
      hasMore[0] = false;
    }
    oldPosts.addAll(newPosts);
    setState(() {
      count[0] = oldPosts.length;
      isLoading[0] = false;
    });
    oldItems = Future(() => oldPosts);
  }

  void updateState() {
    setState(() {});
  }

  EdgeInsets listViewInsets() {
    final size = filterKey.currentContext?.findRenderObject() as RenderBox?;
    final h = size?.size.height;
    if (filterHeight == null && h != 0) {
      filterHeight = h;
    }
    return EdgeInsets.only(
      top: !showingFilter ? 0 : filterHeight!,
      bottom: 48,
    );
  }

  @override
  Widget build(BuildContext context) {
    final buildList = buildFutureList(
      context,
      _loadMore,
      filterState,
      count,
      isLoading,
      hasMore,
      getNewItems,
      updateState,
      Future(() => []),
      Future(() => []),
      Future(() => []),
      comments,
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
    );

    final Widget list = buildList(comments);
    late Widget? header = null;
    final page = buildFilteredList(
      list,
      filterState,
      updateFilterState,
      showingFilter,
      updateFilter,
      header,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
