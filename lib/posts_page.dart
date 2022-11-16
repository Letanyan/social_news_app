import 'package:flutter/material.dart';
import 'package:social_news_app/model/helpers.dart';
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

class _PostsPageState extends State<PostsPage> {
  late Future<List<Post>> posts;
  var offset = [0];
  var count = [0];
  var pageSize = 20;
  var isLoading = [true];
  var hasMore = [true];

  @override
  void initState() {
    super.initState();
    posts = Future(() => []);
    updateFilter(() {});
  }

  Future<List<T>> getNewItems<T>() {
    if (widget.postId == null) {
      return NewSource.getPosts(
        userId: widget.userId,
        origin: widget.origin,
        tags: widget.tags,
        popularIn: widget.popularIn,
        upvotes: widget.upvotes,
        downvotes: widget.downvotes,
        order: widget.order,
        offset: offset[0],
        limit: pageSize,
        start: widget.start,
        end: widget.end,
        startCreated: widget.startCreated,
        endCreated: widget.endCreated,
        forUser: widget.forUser,
      ) as Future<List<T>>;
    } else if (widget.forUser != null) {
      return NewSource.getSimilarPost(
        widget.forUser!,
        start: widget.start,
        end: widget.end,
        order: widget.order,
        offset: offset[0],
        limit: pageSize,
        postId: widget.postId,
      ) as Future<List<T>>;
    } else {
      return Future(() => []);
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
      child: Text(isFollowing ? "Unfollow" : "Follow"),
    );
    return [button];
  }

  @override
  Widget build(BuildContext context) {
    // final page = FutureBuilder<List<Post>>(
    //   future: posts,
    //   builder: (context, snapshot) {
    //     if (snapshot.hasData) {
    //       if (snapshot.data == null || snapshot.data?.isEmpty == true) {
    //         return const SizedBox();
    //       }
    //       final list = ListView.builder(
    //         physics: const AlwaysScrollableScrollPhysics(),
    //         itemCount: count[0] + 1,
    //         itemBuilder: (context, index) {
    //           if (index >= count[0]) {
    //             if (isLoading[0]) {
    //               return const CircularProgressIndicator();
    //             } else if (hasMore) {
    //               _loadMorePosts();
    //               isLoading = true;
    //               return const CircularProgressIndicator();
    //             } else {
    //               return const SizedBox();
    //             }
    //           }
    //           final item = snapshot.data![index];
    //           return item.tile(context, updateState);
    //           // return item.card(context, false, updateState);
    //         },
    //       );
    //       return RefreshIndicator(
    //         onRefresh: () async {
    //           if (User.current != null && widget.forUser != null) {
    //             var list = <int>[];
    //             for (final p in await posts) {
    //               list.add(p.id);
    //             }
    //             NewSource.refreshUserContRecommendations(
    //                 User.current!.id, list);
    //           }
    //           offset = 0;
    //           count = 0;
    //           isLoading = true;
    //           await _loadMorePosts();
    //           hasMore = true;
    //           return;
    //         },
    //         child: list,
    //       );
    //     } else if (snapshot.hasError) {
    //       return Text("${snapshot.error}");
    //     }
    //     return const CircularProgressIndicator();
    //   },
    // );
    late final Widget list;
    late final Widget sliver;
    var stack = <Widget>[];
    final filterState = FilterBoxState.zero();

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

    list = buildList(posts);
    sliver = CustomScrollView(
      slivers: [
        list,
      ],
    );
    stack.add(sliver);

    final page = Stack(children: stack);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: buildTagFollow(),
      ),
      body: page,
    );
  }
}
