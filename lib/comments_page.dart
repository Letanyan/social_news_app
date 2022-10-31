import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:english_words/english_words.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class CommentsPage extends StatefulWidget {
  final Post post;

  const CommentsPage({super.key, required this.post});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _IndentedComment {
  final Comment comment;
  final int indent;

  const _IndentedComment(this.comment, this.indent);
}

class _CommentsPageState extends State<CommentsPage> {
  late Future<SplayTreeMap<int, List<Comment>>> comments;
  late Future<List<Comment>> allComments;
  late Future<List<_IndentedComment>> visibleComments;
  late Future<List<_IndentedComment>> reviews;
  bool isLoading = true;
  int count = 0;
  int reviewCount = 0;
  bool isReview = false;

  final controller = TextEditingController();
  Comment? replyingTo;
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();
    loadComments(-1);
    loadReviews();
    replyingTo = null;
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((visible) {
      if (!visible) {
        replyingTo = null;
        updateState();
      }
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    super.dispose();
  }

  Future<void> loadComments(int commentId) async {
    allComments = NewSource.getComments(
      postId: widget.post.ID,
      replyId: commentId,
      order: SortOrder.createdAt,
      isReview: false,
    );
    comments = Future(() => SplayTreeMap<int, List<Comment>>());
    visibleComments = Future(() => <_IndentedComment>[]);
    // reviews = Future(() => []);
    showComments(0);
  }

  Future<void> loadReviews() async {
    final raw = await NewSource.getComments(
      postId: widget.post.ID,
      replyId: 0,
      order: SortOrder.createdAt,
      isReview: true,
    );
    reviewCount = raw.length;
    reviews = Future(
        () => raw.map((e) => _IndentedComment(e, 0)).toList(growable: false));
  }

  Future<void> showComments(int replyId) async {
    var list = <Comment>[];
    for (final c in await allComments) {
      if (c.replyId == replyId) {
        list.add(c);
      }
    }
    list.sort((a, b) => a.id.compareTo(b.id));
    var result = await comments;
    result[replyId] = list;
    count += list.length;

    var path = <int>[0];
    var pathCount = <int>[0];
    var indents = <_IndentedComment>[];
    loop:
    for (var i = 0; i < count; i++) {
      var currentReplies = result[path.last];
      while (
          currentReplies == null || pathCount.last >= currentReplies.length) {
        path.removeLast();
        pathCount.removeLast();
        if (path.isEmpty) {
          continue loop;
        }
        pathCount[pathCount.length - 1] += 1;
        currentReplies = result[path.last];
      }
      final item = result[path.last]![pathCount.last];
      final indent = path.length - 1;
      if (result[item.id] != null) {
        path.add(item.id);
        pathCount.add(0);
      } else {
        pathCount[pathCount.length - 1] += 1;
      }
      indents.add(_IndentedComment(item, indent));
    }

    comments = Future(() => result);
    visibleComments = Future(() => indents).then((value) {
      setState(() {});
      return value;
    });
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

  void replyToComment() async {
    if (replyingTo == null) {
      return;
    }
    final postId = replyingTo!.postId;
    final replyId = replyingTo!.id;
    final result = await NewSource.createComment(
      postId,
      replyId,
      controller.text,
      false,
    );
    var all = await allComments;
    all.add(result);
    allComments = Future(() => all);
    showComments(replyId);
    replyingTo = null;
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    final list = FutureBuilder<List<_IndentedComment>>(
      future: isReview ? reviews : visibleComments,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            return ListView(children: [widget.post.card(context, updateState)]);
          }
          final list = ListView.builder(
            itemCount: (isReview ? reviewCount : count) + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final card = widget.post.card(context, updateState);
                final sel = CupertinoSlidingSegmentedControl(
                  children: const {
                    false: Text("Comments"),
                    true: Text("Reviews")
                  },
                  groupValue: isReview,
                  onValueChanged: (value) {
                    final didChange = value != isReview && value != null;
                    isReview = value ?? false;
                    updateState();
                  },
                );
                return Column(children: [
                  card,
                  const SizedBox(height: 4),
                  sel,
                  const SizedBox(height: 4),
                ]);
              }
              if (index - 1 >= snapshot.data!.length) {
                return const SizedBox();
              }
              final item = snapshot.data![index - 1];
              return item.comment.card(
                context,
                true,
                min(item.indent.toDouble() * 16, 160),
                (c) {
                  toggleComments(c.id);
                  setState(() {});
                },
                updateState,
                () => setState(() => replyingTo = item.comment),
                postAuthor: widget.post.Creator.ID,
              );
            },
          );

          final refresh = RefreshIndicator(
            onRefresh: () async {
              loadComments(-1);
              return;
            },
            child: list,
          );
          final replyField = Visibility(
            visible: replyingTo != null,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 180, minHeight: 45),
              child: TextField(
                keyboardType: TextInputType.text,
                maxLines: 1,
                autofocus: true,
                controller: controller,
                onSubmitted: (value) => replyToComment(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a reply',
                ),
              ),
            ),
          );

          final body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: refresh),
              replyField,
            ],
          );

          return KeyboardDismissOnTap(dismissOnCapturedTaps: true, child: body);
        }

        final list = ListView(
          children: [
            widget.post.card(context, updateState),
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
