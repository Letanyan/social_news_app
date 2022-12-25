import 'package:flutter/material.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/widgets/filter_widget.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/user.dart';

class UserContPage extends StatefulWidget {
  final bool showSearch;
  final ContentKind kind;
  final UserContKind playlist;
  final bool isReview;
  final Author user;
  final String title;
  final bool forContent;
  final int? pid;
  final int? sid;

  const UserContPage({
    super.key,
    required this.title,
    required this.showSearch,
    required this.kind,
    required this.playlist,
    required this.isReview,
    required this.user,
    required this.forContent,
    this.pid,
    this.sid,
  });

  @override
  State<UserContPage> createState() => _UserContPageState();
}

class _UserContPageState extends State<UserContPage> {
  late Future<List<Post>> posts;
  late Future<List<Comment>> comments;
  late Future<List<Author>> users;
  late Future<List<Tag>> tags;
  late TextEditingController controller;

  var current = ContentKind.post;
  var offset = [0];
  var pageSize = 20;
  var count = [0];
  var hasMore = [true];
  var isLoading = [false];
  var forContent = false;
  late FilterBoxState filterState;
  var filterKey = GlobalKey();
  bool showingFilter = false;
  double? filterHeight;
  UserContKind playlist = UserContKind.created;
  int? pid;
  int? sid;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController();
    current = widget.kind;
    forContent = widget.forContent;
    playlist = widget.playlist;
    pid = widget.pid;
    sid = widget.sid;
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
              ...(widget.kind == ContentKind.post ? [SortOrder.createdAt] : []),
            ]),
      startDate: forContent ? null : DateTime(2022),
      endDate: forContent ? null : DateTime.now(),
      order: SortOrder.addedOn,
      location: forContent ? null : [],
    );

    posts = Future(() => []);
    comments = Future(() => []);
    users = Future(() => []);
    tags = Future(() => []);
    if (forContent) {
      users = getNewItems<Author>().then(updateItemsState);
    } else if (current == ContentKind.post) {
      posts = getNewItems<Post>().then(updateItemsState);
    } else if (current == ContentKind.comment) {
      comments = getNewItems<Comment>().then(updateItemsState);
    } else if (current == ContentKind.user) {
      users = getNewItems<Author>().then(updateItemsState);
    } else if (current == ContentKind.tag) {
      tags = getNewItems<Tag>().then(updateItemsState);
    }

    offset[0] = pageSize;
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

  Future<int> getItemsCount() async {
    final sd = filterState.startDate;
    final ed = filterState.endDate;
    final loc =
        filterState.location?.isEmpty == true ? null : filterState.location;
    final srt = filterState.order;
    final src = filterState.search?.isEmpty == true ? null : filterState.search;
    if (forContent && pid != null && sid != null) {
      return NewSource.getUserContFor(
        playlist,
        pid!,
        sid!,
        search: src,
        order: srt,
        limit: pageSize,
        offset: offset[0],
        onlyCount: true,
      ).then((value) => value[0].id).catchError((e) {
        displayError(context, e);
      });
    }
    return 0;
  }

  Future<List<T>> getNewItems<T>() async {
    final sd = filterState.startDate;
    final ed = filterState.endDate;
    final loc =
        filterState.location?.isEmpty == true ? null : filterState.location;
    final srt = filterState.order;
    final src = filterState.search?.isEmpty == true ? null : filterState.search;
    try {
      if (forContent && pid != null && sid != null) {
        return NewSource.getUserContFor(
          playlist,
          pid!,
          sid!,
          search: src,
          order: srt,
          limit: pageSize,
          offset: offset[0],
        ) as Future<List<T>>;
      } else if (isTypeEqual<T, Post>()) {
        return NewSource.getUserContPost(
          uid: widget.user.id,
          kind: widget.playlist,
          location: loc,
          startCreated: sd,
          endCreated: ed,
          offset: offset[0],
          limit: pageSize,
          order: srt,
          search: src,
        ) as Future<List<T>>;
      } else if (isTypeEqual<T, Comment>()) {
        return NewSource.getUserContComments(
          uid: widget.user.id,
          startCreated: sd,
          endCreated: ed,
          offset: offset[0],
          limit: pageSize,
          order: srt,
          search: src,
          isReview: widget.isReview,
        ) as Future<List<T>>;
      } else if (isTypeEqual<T, Author>()) {
        if (widget.playlist == UserContKind.userFollow) {
          return NewSource.getUserContUsers(
            widget.user.id,
            UserContKind.userFollow,
            pageSize,
            offset[0],
            startDate: sd,
            endDate: ed,
          ) as Future<List<T>>;
        } else if (widget.playlist == UserContKind.ignored) {
          return NewSource.getUserContUsers(
            widget.user.id,
            UserContKind.ignored,
            pageSize,
            offset[0],
            startDate: sd,
            endDate: ed,
          ) as Future<List<T>>;
        } else {
          return Future(() => <T>[]);
        }
      } else if (isTypeEqual<T, Tag>()) {
        return NewSource.getUserContTag(
                widget.user.id, UserContKind.tagFollow, pageSize, offset[0])
            as Future<List<T>>;
      } else {
        return Future(() => <T>[]);
      }
    } catch (e) {
      displayError(context, e);
      return Future(() => <T>[]);
    }
  }

  Future<List<T>> updateItemsState<T>(List<T> value) async {
    count[0] += value.length;
    isLoading[0] = false;
    if (current == ContentKind.post &&
        isTypeEqual<T, Post>() &&
        widget.playlist == UserContKind.readLater &&
        widget.user.id == User.current?.id) {
      User.current?.readLater = (value as List<Post>).map((e) => e.id).toList();
    }
    return value;
  }

  void updateFilter(void Function() f) {
    setState(() {
      f();
      count[0] = 0;
      offset[0] = 0;
      isLoading[0] = true;
      hasMore[0] = true;
      if (forContent) {
        users = getNewItems<Author>().then(updateItemsState);
      } else if (current == ContentKind.post) {
        posts = getNewItems<Post>().then(updateItemsState);
      } else if (current == ContentKind.comment) {
        comments = getNewItems<Comment>().then(updateItemsState);
      } else if (current == ContentKind.user) {
        users = getNewItems<Author>().then(updateItemsState);
      } else if (current == ContentKind.tag) {
        tags = getNewItems<Tag>().then(updateItemsState);
      }
      offset[0] = pageSize;
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

    late final Widget list;
    late Widget? header = null;
    if (forContent) {
      list = buildList(users);
      header = buildCountItemList(getItemsCount());
    } else if (current == ContentKind.post) {
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
