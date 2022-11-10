import 'package:flutter/material.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/user.dart';

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
  int offset = 0;
  int count = 0;
  int pageSize = 20;
  bool isLoading = true;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    posts = loadPosts().then((value) {
      count += value.length;
      isLoading = false;
      return value;
    });

    offset = pageSize;
  }

  Future<List<Post>> loadPosts() {
    if (widget.postId == null) {
      return NewSource.getPosts(
        userId: widget.userId,
        origin: widget.origin,
        tags: widget.tags,
        popularIn: widget.popularIn,
        upvotes: widget.upvotes,
        downvotes: widget.downvotes,
        order: widget.order,
        offset: offset,
        limit: pageSize,
        start: widget.start,
        end: widget.end,
        startCreated: widget.startCreated,
        endCreated: widget.endCreated,
        forUser: widget.forUser,
      );
    } else if (widget.forUser != null) {
      return NewSource.getSimilarPost(
        widget.forUser!,
        start: widget.start,
        end: widget.end,
        order: widget.order,
        offset: offset,
        limit: pageSize,
        postId: widget.postId,
      );
    } else {
      return Future(() => []);
    }
  }

  Future<void> _loadMorePosts() async {
    final newPosts = await loadPosts();
    var oldPosts = await posts;
    offset += newPosts.length;
    if (newPosts.isEmpty) {
      hasMore = false;
    }
    oldPosts.addAll(newPosts);
    posts = Future(() => oldPosts);
    setState(() {
      count = oldPosts.length;
      isLoading = false;
    });
  }

  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final page = FutureBuilder<List<Post>>(
      future: posts,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            return const SizedBox();
          }
          final list = ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: count + 1,
            itemBuilder: (context, index) {
              if (index >= count) {
                if (isLoading) {
                  return const CircularProgressIndicator();
                } else if (hasMore) {
                  _loadMorePosts();
                  isLoading = true;
                  return const CircularProgressIndicator();
                } else {
                  return const SizedBox();
                }
              }
              final item = snapshot.data![index];
              return item.tile(context, updateState);
              // return item.card(context, false, updateState);
            },
          );
          return RefreshIndicator(
            onRefresh: () async {
              if (User.current != null && widget.forUser != null) {
                var list = <int>[];
                for (final p in await posts) {
                  list.add(p.id);
                }
                NewSource.refreshUserContRecommendations(
                    User.current!.id, list);
              }
              offset = 0;
              count = 0;
              isLoading = true;
              await _loadMorePosts();
              hasMore = true;
              return;
            },
            child: list,
          );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return const CircularProgressIndicator();
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: page,
    );
  }
}
