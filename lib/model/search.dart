import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/widgets/filter_widget.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/posts_page.dart';
import 'helpers.dart';

class SearchPage extends StatefulWidget {
  final bool isTrending;
  final String title;

  const SearchPage({super.key, required this.isTrending, required this.title});

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  late Future<List<Tag>> tags;
  late Future<List<Post>> posts;
  late Future<List<Author>> users;
  late Future<List<Comment>> comments;

  var offset = [0, 0, 0, 0];
  var pageSize = 20;
  var count = [0, 0, 0, 0];
  var hasMore = [true, true, true, true];
  var isLoading = [true, true, true, true];
  late FilterBoxState filterState;
  var showingFilter = false;
  var filterKey = GlobalKey();
  double? filterHeight;

  @override
  void initState() {
    super.initState();

    tags = Future(() => []);
    posts = Future(() => []);
    users = Future(() => []);
    comments = Future(() => []);

    const selector = <int, String>{
      0: "Posts",
      1: "Tags",
      2: "Users",
      3: "Comments"
    };
    final search = widget.isTrending ? null : "";
    final List<SortOrder> rank =
        widget.isTrending ? [] : [SortOrder.createdAt, SortOrder.rank];
    var sortOrder = sortOrdersIncluding(rank);
    final List<String>? location = widget.isTrending ? [] : null;
    final startDate = widget.isTrending
        ? DateTime.now().add(const Duration(days: -7))
        : DateTime.utc(2020);
    final endDate = DateTime.now();

    filterState = FilterBoxState(
      displaySelector: selector,
      displaySorting: sortOrder,
      current: 0,
      order: widget.isTrending ? SortOrder.score : SortOrder.rank,
      search: search,
      startDate: startDate,
      endDate: endDate,
      location: location,
    );

    updateFilter(() {});
  }

  int currentIndex<T>() {
    if (isTypeEqual<T, Post>()) {
      return 0;
    } else if (isTypeEqual<T, Tag>()) {
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
    final sd = widget.isTrending ? filterState.startDate : null;
    final ed = widget.isTrending ? filterState.endDate : null;
    final ssd = !widget.isTrending ? filterState.startDate : null;
    final sed = !widget.isTrending ? filterState.endDate : null;
    final loc = !widget.isTrending ? null : filterState.location;
    final are = !widget.isTrending ? filterState.location : null;
    final src = filterState.search?.isEmpty == true ? null : filterState.search;
    final so = filterState.order;
    if (src == null && !widget.isTrending) {
      return Future(() => []);
    }
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
        origin: are,
        startCreated: ssd,
        endCreated: sed,
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
        startCreated: ssd,
        endCreated: sed,
        popularIn: loc,
        search: src,
      ) as Future<List<T>>;
    } else {
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
      isLoading[filterState.current] = true;
      hasMore[filterState.current] = true;

      offset[filterState.current] = 0;
      if (filterState.current == 0) {
        posts = getNewItems<Post>().then(updateItemsState);
      } else if (filterState.current == 1) {
        tags = getNewItems<Tag>().then(updateItemsState);
      } else if (filterState.current == 2) {
        users = getNewItems<Author>().then(updateItemsState);
      } else if (filterState.current == 3) {
        comments = getNewItems<Comment>().then(updateItemsState);
      }
      offset[filterState.current] = pageSize;
    });
  }

  void loadMore<T>(Future<List<T>> newItems, Future<List<T>> oldItems) async {
    final newPosts = await newItems;
    var oldPosts = await oldItems;
    offset[filterState.current] += newPosts.length;
    if (newPosts.isEmpty) {
      hasMore[filterState.current] = false;
    }
    oldPosts.addAll(newPosts);
    count[filterState.current] = oldPosts.length;
    setState(() {
      isLoading[filterState.current] = false;
    });
    oldItems = Future(() => oldPosts);
  }

  void updateFilterState(FilterBoxState state) {
    filterState = state;
    if (filterState.current == 1 && !widget.isTrending) {
      filterState.location = filterState.location ?? [];
    }
    List<SortOrder> rank = widget.isTrending ? [] : [SortOrder.rank];
    if (filterState.current == 0 || filterState.current == 3) {
      if (!widget.isTrending) {
        rank.add(SortOrder.createdAt);
      }
      filterState.displaySorting = sortOrdersIncluding(rank);
    } else if (filterState.current == 1 || filterState.current == 2) {
      if (!widget.isTrending) {
        filterState.location = null;
      }
      filterState.displaySorting = sortOrdersIncluding(rank);
    }
    updateFilter(() {});
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
      tags,
      posts,
      users,
      comments,
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
    );

    if (filterState.current == 0) {
      list = buildList(posts);
    } else if (filterState.current == 1) {
      list = buildList(tags);
    } else if (filterState.current == 2) {
      list = buildList(users);
    } else if (filterState.current == 3) {
      list = buildList(comments);
    } else {
      list = const SizedBox();
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
