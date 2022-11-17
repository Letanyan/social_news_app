import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:social_news_app/model/user.dart';

class CommentsPage extends StatefulWidget {
  final Post post;
  final bool scrollComments;

  const CommentsPage(
      {super.key, required this.post, this.scrollComments = false});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _IndentedComment {
  final Comment comment;
  final int indent;

  const _IndentedComment(this.comment, this.indent);
}

class _CommentsPageState extends State<CommentsPage> {
  late Future<Map<int, List<Comment>>> comments;
  late Future<List<Comment>> allComments;
  late Future<List<_IndentedComment>> visibleComments;
  late Future<List<_IndentedComment>> reviews;
  late HashSet<int> visibleReplyIds;
  final selectorKey = GlobalKey();
  Timer? timer;
  bool isLoading = true;
  int count = 0;
  int reviewCount = 0;
  bool isReview = false;
  SortOrder sortOrder = SortOrder.upvotes;

  final controller = TextEditingController();
  Comment? replyingTo;
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();
    loadComments(-1);
    loadReviews();
    replyingTo = null;
    visibleReplyIds = HashSet();
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((visible) {
      if (!visible) {
        replyingTo = null;
        updateState();
      }
    });
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   if (widget.scrollComments && selectorKey.currentContext != null) {
    //     Scrollable.ensureVisible(selectorKey.currentContext!);
    //   }
    // });

    timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (User.current == null) {
        return;
      }
      NewSource.watchPost(User.current!.id, widget.post.id, 1);
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadComments(int commentId) async {
    allComments = NewSource.getComments(
      postId: widget.post.id,
      replyId: commentId,
      order: SortOrder.createdAt,
      isReview: false,
    );

    // sortComments uses the keys from comments to decide which comments to
    // show. So we include the 0 key here so the top level comments are shown
    // after sorting.
    comments = Future(() => <int, List<Comment>>{0: []});

    visibleComments = Future(() => <_IndentedComment>[]);
    reviews = Future(() => []);
    sortComments();
  }

  Future<void> loadReviews() async {
    final raw = await NewSource.getComments(
      postId: widget.post.id,
      replyId: 0,
      order: SortOrder.createdAt,
      isReview: true,
    );
    reviewCount = raw.length;
    reviews = Future(
        () => raw.map((e) => _IndentedComment(e, 0)).toList(growable: false));
  }

  Future<void> flattenComments(Map<int, List<Comment>> result) async {
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
    await flattenComments(result);
  }

  Future<void> hideComments(int replyId) async {
    var result = await comments;
    final len = result[replyId]?.length ?? 0;
    result.remove(replyId);
    count -= len;
    await flattenComments(result);
  }

  Future<void> toggleComments(int replyId) async {
    final result = await comments;
    if (result.containsKey(replyId)) {
      visibleReplyIds.remove(replyId);
      await hideComments(replyId);
    } else {
      visibleReplyIds.add(replyId);
      await showComments(replyId);
    }
  }

  Future<void> sortComments() async {
    var keys = await comments;
    var source = await allComments;

    source.sort((a, b) {
      switch (sortOrder) {
        case SortOrder.addedOn:
          return a.createdAt.compareTo(b.createdAt);
        case SortOrder.score:
          return -a.score.compareTo(b.score);
        case SortOrder.cred:
          return -a.cred.compareTo(b.cred);
        case SortOrder.upvotes:
          return -a.upvotes.compareTo(b.upvotes);
        case SortOrder.downvotes:
          return -a.downvotes.compareTo(b.downvotes);
        case SortOrder.controversial:
          return -controversial(a.cred).compareTo(controversial(b.cred));
        case SortOrder.createdAt:
          return a.createdAt.compareTo(b.createdAt);
        case SortOrder.updatedAt:
          return a.createdAt.compareTo(b.createdAt);
        case SortOrder.updatedOn:
          return a.createdAt.compareTo(b.createdAt);
        case SortOrder.rank:
          return a.rank.compareTo(b.rank);
      }
    });
    allComments = Future(() => source);

    var result = <int, List<Comment>>{};
    count = 0;
    for (final c in await allComments) {
      if (keys.keys.contains(c.replyId)) {
        if (result.containsKey(c.replyId)) {
          result[c.replyId]?.add(c);
        } else {
          result[c.replyId] = [c];
        }
        count += 1;
      }
    }

    await flattenComments(result);
  }

  Future<void> sortReview() async {
    var result = await reviews;
    result.sort(
      (x, y) {
        final a = x.comment;
        final b = y.comment;
        switch (sortOrder) {
          case SortOrder.addedOn:
            return a.createdAt.compareTo(b.createdAt);
          case SortOrder.score:
            return -a.score.compareTo(b.score);
          case SortOrder.cred:
            return -a.cred.compareTo(b.cred);
          case SortOrder.upvotes:
            return -a.upvotes.compareTo(b.upvotes);
          case SortOrder.downvotes:
            return -a.downvotes.compareTo(b.downvotes);
          case SortOrder.controversial:
            return -controversial(a.cred).compareTo(controversial(b.cred));
          case SortOrder.createdAt:
            return a.createdAt.compareTo(b.createdAt);
          case SortOrder.updatedAt:
            return a.createdAt.compareTo(b.createdAt);
          case SortOrder.updatedOn:
            return a.createdAt.compareTo(b.createdAt);
          case SortOrder.rank:
            return a.rank.compareTo(b.rank);
        }
      },
    );

    reviews = Future(() => result);
    setState(() {});
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

  Widget buildReplyField(BuildContext context) {
    final textField = TextField(
      keyboardType: TextInputType.text,
      maxLines: 1,
      autofocus: true,
      controller: controller,
      onSubmitted: (value) => replyToComment(),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter a reply',
      ),
    );
    final send = Padding(
      padding: const EdgeInsets.all(8),
      child: TextButton(
        onPressed: () => replyToComment(),
        child: const Text("Reply"),
      ),
    );
    final cancel = Padding(
      padding: const EdgeInsets.all(8),
      child: TextButton(
        onPressed: () {
          replyingTo = null;
          updateState();
        },
        child: const Text("Cancel"),
      ),
    );
    final actions = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [send, cancel],
    );

    return Visibility(
      visible: replyingTo != null,
      child: Row(
        children: [Expanded(child: textField), actions],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.post.card(context, updateState);
    final sel = CupertinoSlidingSegmentedControl(
      key: selectorKey,
      children: const {false: Text("Comments"), true: Text("Reviews")},
      groupValue: isReview,
      onValueChanged: (value) {
        final didChange = value != isReview && value != null;
        isReview = value ?? false;
        if (didChange) {
          updateState();
        }
      },
    );
    final sort = PopupMenuButton(
      itemBuilder: (context) {
        final sortItems = <SortOrder>[
          SortOrder.score,
          SortOrder.createdAt,
          SortOrder.upvotes,
          SortOrder.downvotes,
          SortOrder.cred,
          SortOrder.controversial,
        ];
        return sortItems.map((e) {
          return PopupMenuItem(
            child: Text(sortOrderPresentation(e)),
            onTap: () {
              sortOrder = e;
              sortComments();
            },
          );
        }).toList();
      },
      child: const Icon(Icons.sort_rounded),
    );
    final previewItems = <Widget>[
      card,
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Center(
              child: sel,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: sort,
          ),
        ],
      ),
      const SizedBox(height: 4),
    ];

    final list = FutureBuilder<List<_IndentedComment>>(
      future: isReview ? reviews : visibleComments,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return RefreshIndicator(
            onRefresh: () async {
              loadComments(-1);
              return;
            },
            child: Column(children: [
              ...previewItems,
              const CircularProgressIndicator(),
            ]),
          );
        }

        if (snapshot.data == null || snapshot.data?.isEmpty == true) {
          return SingleChildScrollView(
              child: Column(children: [
            ...previewItems,
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                "No ${isReview ? "Reviews" : "Comments"}. Reply to be the First!",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ]));
        }

        final list = ListView.builder(
          itemCount: (isReview ? reviewCount : count) + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return SingleChildScrollView(
                child: Column(children: previewItems),
              );
            }
            if (index - 1 >= snapshot.data!.length) {
              return const SizedBox();
            }
            final item = snapshot.data![index - 1];
            return item.comment.card(
              context,
              true,
              item.indent,
              (c) {
                toggleComments(c.id);
                setState(() {});
              },
              updateState,
              () => setState(() {
                replyingTo = item.comment;
              }),
              replyingTo?.id == item.comment.id,
              visibleReplyIds.contains(item.comment.id),
              postAuthor: widget.post.creator.id,
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
        final replyField = buildReplyField(context);

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: refresh),
            replyField,
          ],
        );

        return KeyboardDismissOnTap(dismissOnCapturedTaps: true, child: body);
      },
    );

    return list;
  }
}
