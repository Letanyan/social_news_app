import 'package:flutter/material.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/widgets/filter_widget.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/model/user_pref.dart';

class UserPrefPage extends StatefulWidget {
  final bool showSearch;
  final ContentKind prefKind;
  final Author user;
  final bool isViewed;
  final String title;

  const UserPrefPage(
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
  var offset = [0];
  var pageSize = 20;
  var count = [0];
  var hasMore = [true];
  var isLoading = [false];
  late FilterBoxState filterState;
  bool showingFilter = false;
  double? filterHeight;

  @override
  void initState() {
    super.initState();

    current = widget.prefKind;
    filterState = FilterBoxState(
      current: 0,
      search: "",
      startDate: DateTime.utc(1970),
      endDate: DateTime.now(),
      location: widget.prefKind == ContentKind.post ? [] : null,
      displaySorting: sortOrdersIncluding([SortOrder.updatedOn]),
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

    offset[0] = pageSize;
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
    final sd = filterState.startDate;
    final ed = filterState.endDate;
    final loc =
        filterState.location?.isEmpty == true ? null : filterState.location;
    final srt = filterState.order;
    final src = filterState.search?.isEmpty == true ? null : filterState.search;
    if (isTypeEqual<T, UserPrefTag>()) {
      return NewSource.getUserPrefTags(
        uid: widget.user.id,
        startVoted: sd,
        endVoted: ed,
        offset: offset[0],
        limit: pageSize,
        order: srt,
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefPost>()) {
      return NewSource.getUserPrefPosts(
        uid: widget.user.id,
        location: loc,
        startVoted: sd,
        endVoted: ed,
        offset: offset[0],
        limit: pageSize,
        order: srt,
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefUser>()) {
      return NewSource.getUserPrefUsers(
        uid: widget.user.id,
        startVoted: sd,
        endVoted: ed,
        offset: offset[0],
        limit: pageSize,
        order: srt,
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefComment>()) {
      return NewSource.getUserPrefComments(
        uid: widget.user.id,
        startVoted: sd,
        endVoted: ed,
        offset: offset[0],
        limit: pageSize,
        order: srt,
        search: src,
      ) as Future<List<T>>;
    } else {
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
      if (current == ContentKind.tag) {
        tags = getNewItems<UserPrefTag>().then(updateItemsState);
      } else if (current == ContentKind.post) {
        posts = getNewItems<UserPrefPost>().then(updateItemsState);
      } else if (current == ContentKind.user) {
        users = getNewItems<UserPrefUser>().then(updateItemsState);
      } else if (current == ContentKind.comment) {
        comments = getNewItems<UserPrefComment>().then(updateItemsState);
      }
      offset[0] = pageSize;
    });
  }

  void updateFilterState(FilterBoxState state) {
    filterState = state;
    updateFilter(() {});
  }

  void loadMore<T>(Future<List<T>> newItems, Future<List<T>> oldItems) async {
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
      Future(() => []),
      Future(() => []),
      tags,
      posts,
      users,
      comments,
    );

    if (current == ContentKind.post) {
      list = buildList(posts);
    } else if (current == ContentKind.comment) {
      list = buildList(comments);
    } else if (current == ContentKind.user) {
      list = buildList(users);
    } else if (current == ContentKind.tag) {
      list = buildList(tags);
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
