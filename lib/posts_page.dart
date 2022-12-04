import 'package:flutter/material.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/widgets/filter_widget.dart';

class PostsPage extends StatefulWidget {
  final int? userId;
  final List<String>? origin;
  final List<int>? tags;
  final List<String>? popularIn;
  final int? upvotes;
  final int? downvotes;
  final SortOrder? order;
  final DateTime? start;
  final DateTime? end;
  final DateTime? startCreated;
  final DateTime? endCreated;
  final int? forUser;
  final int? postId;
  final String title;

  const PostsPage({
    super.key,
    required this.title,
    this.userId,
    this.origin,
    this.tags,
    this.popularIn,
    this.upvotes,
    this.downvotes,
    this.order,
    this.start,
    this.end,
    this.startCreated,
    this.endCreated,
    this.forUser,
    this.postId,
  });

  @override
  State<PostsPage> createState() => _PostsPageState();
}

enum _PostsPageKind { similar, forYou, basic }

class _PostsPageState extends State<PostsPage> with TickerProviderStateMixin {
  late Future<List<Post>> posts;
  var offset = [0];
  var count = [0];
  var pageSize = 20;
  var isLoading = [true];
  var hasMore = [true];
  late FilterBoxState filterState;
  var showingFilter = false;
  var filterKey = GlobalKey();
  double? filterHeight;
  late final _PostsPageKind pageKind;

  @override
  void initState() {
    super.initState();
    posts = Future(() => []);
    if (widget.forUser != 0) {
      if (widget.postId == null) {
        pageKind = _PostsPageKind.forYou;
      } else {
        pageKind = _PostsPageKind.similar;
      }
    } else {
      pageKind = _PostsPageKind.basic;
    }

    filterState = FilterBoxState(
      displaySorting: widget.forUser == null
          ? sortOrdersIncluding([SortOrder.createdAt])
          : null,
      current: 0,
      order: widget.forUser == null
          ? (widget.order ?? SortOrder.createdAt)
          : SortOrder.score,
      search: widget.forUser == null ? "" : null,
    );

    updateFilter(() {});
  }

  Future<List<T>> getNewItems<T>() {
    final src = filterState.search?.isEmpty == true ? null : filterState.search;
    final so = filterState.order;
    if (pageKind == _PostsPageKind.similar) {
      return NewSource.getSimilarPost(
        widget.forUser!,
        start: widget.start,
        end: widget.end,
        order: so,
        offset: offset[0],
        limit: pageSize,
        postId: widget.postId,
      ) as Future<List<T>>;
    } else {
      return NewSource.getPosts(
        userId: widget.userId,
        origin: widget.origin,
        tags: widget.tags,
        popularIn: widget.popularIn,
        upvotes: widget.upvotes,
        downvotes: widget.downvotes,
        order: so,
        offset: offset[0],
        limit: pageSize,
        start: widget.start,
        end: widget.end,
        startCreated: widget.startCreated,
        endCreated: widget.endCreated,
        search: src,
        forUser: widget.forUser,
      ) as Future<List<T>>;
    }
  }

  void loadMore<T>(Future<List<T>> newItems, Future<List<T>> oldItems) async {
    final newPosts = await newItems;
    var oldPosts = await oldItems;
    offset[0] += newPosts.length;
    if (newPosts.isEmpty) {
      hasMore[0] = false;
    }
    oldPosts.addAll(newPosts);
    count[0] = oldPosts.length;
    setState(() {
      isLoading[0] = false;
    });
    oldItems = Future(() => oldPosts);
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
      isLoading[0] = true;
      hasMore[0] = true;

      offset[0] = 0;
      posts = getNewItems<Post>().then(updateItemsState);
      offset[0] = pageSize;
    });
  }

  void updateFilterState(FilterBoxState state) {
    filterState = state;
    updateFilter(() {});
  }

  void updateState() {
    setState(() {});
  }

  List<Widget> buildTagFollow() {
    if (User.current == null) {
      return [];
    }
    if (widget.tags?.length != 1) {
      return [];
    }
    final tag = widget.tags![0];
    final isFollowing = User.current!.favourites
            .firstWhere(
              (element) => element.id == tag,
              orElse: () => Tag.zero(),
            )
            .id !=
        0;
    final button = TextButton(
      onPressed: () {
        if (User.current == null) {
          return;
        }
        if (isFollowing) {
          User.current?.favourites.removeWhere((t) => t.id == tag);
          NewSource.deleteUserCont(
            User.current!.id,
            tag,
            UserContKind.tagFollow,
          );
        } else {
          final t = Tag.getTag(tag);
          User.current?.favourites.add(t);
          NewSource.addUserCont(
            uid: User.current!.id,
            kind: UserContKind.tagFollow,
            pid: tag,
          );
        }
        setState(() {});
      },
      child: Text(isFollowing ? TRGeneral.unfollow : TRGeneral.follow),
    );
    return [button];
  }

  @override
  Widget build(BuildContext context) {
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
      posts,
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
      Future(() => []),
    );

    final list = buildList(posts);
    final page = buildFilteredList(
      list,
      filterState,
      updateFilterState,
      showingFilter,
      updateFilter,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        ...buildTagFollow(),
        IconButton(
          onPressed: () {
            showingFilter = !showingFilter;
            updateState();
          },
          icon: showingFilter
              ? const Icon(Icons.filter_alt_rounded)
              : const Icon(Icons.filter_alt_outlined),
        ),
      ]),
      body: page,
    );
  }
}
