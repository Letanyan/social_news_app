import 'dart:math';

import 'package:english_words/english_words.dart';
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
  late Future<List<Comment>> allComments;
  bool isLoading = true;
  int count = 0;

  @override
  void initState() {
    super.initState();
    loadComments(-1);
  }

  Future<void> loadComments(int commentId) async {
    allComments = NewSource.getComments(
      postId: widget.post.ID,
      replyId: commentId,
    );
    comments = Future(() => <int, List<Comment>>{});
    showComments(0);
  }

  Future<void> showComments(int replyId) async {
    var list = <Comment>[];
    for (final c in await allComments) {
      if (c.replyId == replyId) {
        list.add(c);
      }
    }
    var result = await comments;
    result[replyId] = list;
    count += list.length;
    comments = Future(() => result);
    setState(() {});
  }

  Future<void> hideComments(int replyId) async {
    var result = await comments;
    final len = result[replyId]?.length ?? 0;
    result.remove(replyId);
    count -= len;
    comments = Future(() => result);
    setState(() {});
  }

  Future<void> toggleComments(int replyId) async {
    final result = await comments;
    if (result.containsKey(replyId)) {
      await hideComments(replyId);
    } else {
      await showComments(replyId);
    }
  }

  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = FutureBuilder<Map<int, List<Comment>>>(
      future: comments,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            return ListView(
                children: [widget.post.card(context, true, updateState)]);
          }
          var path = <int>[0];
          var pathCount = <int>[0];
          final list = ListView.builder(
            itemCount: count + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return widget.post.card(context, true, updateState);
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
              if (snapshot.data![item.id] != null) {
                path.add(item.id);
                pathCount.add(0);
              } else {
                pathCount[pathCount.length - 1] += 1;
              }
              return item.card(context, true, indent, (c) {
                toggleComments(c.id);
                setState(() {});
              }, updateState);
            },
          );

          return RefreshIndicator(
            onRefresh: () async {
              loadComments(-1);
              return;
            },
            child: list,
          );
        }

        final list = ListView(
          children: [
            widget.post.card(context, true, updateState),
            const CircularProgressIndicator()
          ],
        );
        return RefreshIndicator(
          onRefresh: () async {
            loadComments(-1);
            return;
          },
          child: list,
        );
      },
    );

    return list;
  }
}
