import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';

class CommentsPage extends StatefulWidget {
  final Post post;

  const CommentsPage({super.key, required this.post});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  late Future<Map<int, List<Comment>>> comments;
  bool isLoading = true;
  int count = 0;

  @override
  void initState() {
    super.initState();
    comments = Future(() => <int, List<Comment>>{});
    _loadMoreComments(0);
  }

  Future<List<Comment>> loadComments(int commentId) {
    return NewSource.getComments(
      postId: widget.post.ID,
      replyId: commentId,
    );
  }

  void _loadMoreComments(int commentId) async {
    final newPosts = await loadComments(commentId);
    var oldPosts = await comments;
    final oldCount = oldPosts[commentId]?.length ?? 0;
    oldPosts[commentId] = newPosts;
    comments = Future(() => oldPosts);
    setState(() {
      count += newPosts.length - oldCount;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = FutureBuilder<Map<int, List<Comment>>>(
      future: comments,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            return ListView(children: [widget.post.card(context, true)]);
          }
          var path = <int>[0];
          var pathCount = <int>[0];
          return ListView.builder(
            itemCount: count + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return widget.post.card(context, true);
              }
              if (path.isEmpty) {
                return const SizedBox();
              }
              var currentReplies = snapshot.data![path.last];
              while (currentReplies == null ||
                  pathCount.last >= currentReplies.length) {
                path.removeLast();
                pathCount.removeLast();
                if (path.isEmpty) {
                  return const SizedBox();
                }
                pathCount[pathCount.length - 1] += 1;
                currentReplies = snapshot.data![path.last];
              }
              final item = snapshot.data![path.last]![pathCount.last];
              final indent =
                  min((path.length.toDouble() - 1) * 16, 160).toDouble();
              if (snapshot.data![item.ID] != null) {
                path.add(item.ID);
                pathCount.add(0);
              } else {
                pathCount[pathCount.length - 1] += 1;
              }
              return item.card(context, true, indent, (c) {
                _loadMoreComments(c.ID);
              });
            },
          );
        }

        return ListView(
          children: [
            widget.post.card(context, true),
            const CircularProgressIndicator()
          ],
        );
      },
    );

    return list;
  }
}
