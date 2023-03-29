import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:social_news_app/model/user.dart';

class CommentsPage extends StatefulWidget {
  final Post post;
  final Comment? scrollComments;

  const CommentsPage(
      {super.key, required this.post, required this.scrollComments});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _IndentedComment {
  final Comment comment;
  final int indent;

  const _IndentedComment(this.comment, this.indent);
}

class _CommentsPageState extends State<CommentsPage> {
  late Map<int, List<Comment>> comments;
  late List<Comment> allCommentsLoaded;
  late Future<List<Comment>> allComments;
  late Future<List<_IndentedComment>> visibleComments;
  List<_IndentedComment>? reviews;
  late Future<List<_IndentedComment>> visibleReviews;
  late HashSet<int> visibleReplyIds;
  final selectorKey = GlobalKey();
  Timer? timer;
  bool isLoading = true;
  int count = 0;
  int reviewCount = 0;
  bool isReview = false;
  SortOrder sortOrder = SortOrder.upvotes;

  final controller = TextEditingController();
  final scroller = ItemScrollController();
  int? commentIndex;
  Comment? replyingTo;
  Comment? scrollToComment;
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();
    loadComments(-1);
    replyingTo = null;
    scrollToComment = widget.scrollComments;
    isReview = widget.scrollComments?.isReview ?? false;
    visibleReplyIds = HashSet();
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((visible) {
      if (!visible) {
        replyingTo = null;
        updateState();
      }
    });

    if (User.current != null) {
      NewSource.addUserCont(
        uid: User.current!.id,
        kind: UserContKind.viewed,
        pid: widget.post.id,
      ).catchError((e) {
        displayError(context, e);
        return false;
      });
    }

    timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (User.current == null ||
          User.current?.email == "temp@new-source.app") {
        return;
      }
      final isTop = ModalRoute.of(context)?.isCurrent ?? false;
      if (!isTop) {
        return;
      }
      final ctx = WeakReference(context);
      NewSource.watchPost(User.current!.id, widget.post.id, 1).catchError((e) {
        displayError(ctx.target, e);
        return false;
      });
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    controller.dispose();
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadComments(int commentId) async {
    final ctx = WeakReference(context);
    allComments = NewSource.getComments(
      postId: widget.post.id,
      replyId: commentId,
      order: SortOrder.createdAt,
      isReview: -1,
      usersIgnoredBy: User.current?.id ?? 0,
    ).catchError((e) {
      displayError(ctx.target, e);
      return <Comment>[];
    });

    // sortComments uses the keys from comments to decide which comments to
    // show. So we include the 0 key here so the top level comments are shown
    // after sorting.
    comments = <int, List<Comment>>{0: []};

    visibleComments = Future(() => []);
    visibleReviews = Future(() => []);
    sortComments();
  }

  void flattenComments() {
    var path = <int>[0];
    var pathCount = <int>[0];
    var indents = <_IndentedComment>[];
    loop:
    for (var i = 0; i < count; i++) {
      var currentReplies = comments[path.last];
      while (
          currentReplies == null || pathCount.last >= currentReplies.length) {
        path.removeLast();
        pathCount.removeLast();
        if (path.isEmpty) {
          continue loop;
        }
        pathCount[pathCount.length - 1] += 1;
        currentReplies = comments[path.last];
      }
      var item = comments[path.last]![pathCount.last];
      item.replyCount = comments[item.id]
              ?.fold(0, (p, e) => (p ?? 0) + (e.trashed ? 0 : 1)) ??
          item.replyCount;
      final indent = path.length - 1;
      if (comments[item.id] != null) {
        path.add(item.id);
        pathCount.add(0);
      } else {
        pathCount[pathCount.length - 1] += 1;
      }
      indents.add(_IndentedComment(item, indent));
    }

    visibleComments = Future(() => indents).then((value) {
      setState(() {});
      return value;
    });
  }

  void showComments(int replyId) {
    var list = <Comment>[];
    final oldCount = comments[replyId]?.length ?? 0;
    for (final c in allCommentsLoaded) {
      if (c.replyId == replyId) {
        list.add(c);
      }
    }
    comments[replyId] = list;
    count += list.length - oldCount;
    flattenComments();
  }

  void hideComments(int replyId) {
    final len = comments[replyId]?.length ?? 0;
    comments.remove(replyId);
    count -= len;
    flattenComments();
  }

  void toggleComments(int replyId) {
    if (comments.containsKey(replyId)) {
      visibleReplyIds.remove(replyId);
      hideComments(replyId);
    } else {
      visibleReplyIds.add(replyId);
      showComments(replyId);
    }
  }

  Future<void> sortComments() async {
    var keys = comments;
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
    allCommentsLoaded = source.map((e) => e).toList();

    // Add the comment chain to the comment selected by the user from scrollToComment
    var chain = scrollToComment?.replyId;
    while (chain != null && chain != 0) {
      final oldChain = chain;
      for (final c in allCommentsLoaded) {
        if (c.id == chain) {
          chain = c.replyId;
          break;
        }
      }
      if (chain == scrollToComment?.replyId) {
        // some parent comment was deleted so impossible to show thread
        scrollToComment = null;
        displayString(context, TRCommentsPage.threadWasDeleted);
        break;
      }
      comments[oldChain] = [];
    }

    comments = <int, List<Comment>>{};
    reviews = [];
    count = 0;
    for (final c in allCommentsLoaded) {
      if (c.isReview) {
        reviews?.add(_IndentedComment(c, 0));
      } else if (keys.keys.contains(c.replyId)) {
        if (comments.containsKey(c.replyId)) {
          comments[c.replyId]?.add(c);
        } else {
          comments[c.replyId] = [c];
        }
        count += 1;
      }
    }
    reviewCount = reviews?.length ?? 0;
    visibleReviews = Future(() => reviews ?? []);

    flattenComments();
  }

  void updateState() {
    setState(() {
      visibleComments = visibleComments;
      visibleReviews = visibleReviews;
      reviews = reviews;
    });
  }

  void replyToComment() async {
    if (replyingTo == null) {
      return;
    }
    final postId = replyingTo!.postId;
    final replyId = replyingTo!.id;
    try {
      final result = await NewSource.createComment(
        postId,
        replyId,
        controller.text,
        false,
      );
      for (var comment in allCommentsLoaded) {
        if (comment.id == replyId) {
          comment.replyCount += 1;
        }
      }
      allCommentsLoaded.add(result);
      allComments = Future(() => allCommentsLoaded);
      showComments(replyId);
      replyingTo = null;
      controller.text = "";
    } catch (e) {
      displayError(context, e);
    }
  }

  Widget buildReplyField(BuildContext context) {
    final textField = TextField(
      keyboardType: TextInputType.text,
      maxLines: 1,
      autofocus: true,
      controller: controller,
      onSubmitted: (value) => replyToComment(),
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: TRCommentsPage.enterReply,
      ),
    );
    final send = Padding(
      padding: const EdgeInsets.all(8),
      child: TextButton(
        onPressed: () => replyToComment(),
        child: Text(TRGeneral.reply),
      ),
    );
    final cancel = Padding(
      padding: const EdgeInsets.all(8),
      child: TextButton(
        onPressed: () {
          replyingTo = null;
          updateState();
        },
        child: Text(TRGeneral.cancel),
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
    final list = FutureBuilder<List<_IndentedComment>>(
      future: isReview ? visibleReviews : visibleComments,
      builder: (context, snapshot) {
        final card = widget.post.card(context, updateState);
        final sel = CupertinoSlidingSegmentedControl(
          key: selectorKey,
          children: {
            false: Text(TRGeneral.discussion),
            true: Text(TRGeneral.critique),
          },
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
              Expanded(child: Center(child: sel)),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: sort,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ];
        if (!snapshot.hasData) {
          return RefreshIndicator(
            onRefresh: () async {
              loadComments(-1);
              return;
            },
            child: Column(children: [
              ...previewItems,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [CircularProgressIndicator()],
              ),
            ]),
          );
        }

        if (snapshot.data == null || snapshot.data?.isEmpty == true) {
          final empty = SingleChildScrollView(
            child: Column(
              children: [
                ...previewItems,
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    isReview
                        ? TRCommentsPage.noCritiques
                        : TRCommentsPage.noDiscussion,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
          return RefreshIndicator(
            onRefresh: () async {
              loadComments(-1);
              return;
            },
            child: empty,
          );
        }

        final dataSource = snapshot.data!.toList();
        final list = ScrollablePositionedList.builder(
          itemCount: (isReview ? reviewCount : count) + 1,
          itemScrollController: scroller,
          itemBuilder: (context, index) {
            if (index == 0) {
              return SingleChildScrollView(
                child: Column(children: previewItems),
              );
            }
            if (index - 1 >= dataSource.length) {
              return const SizedBox();
            }

            if (index == (isReview ? reviewCount : count)) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                if (commentIndex != null && scrollToComment != null) {
                  scrollToComment = null;
                  scroller.scrollTo(
                    index: commentIndex!,
                    duration: const Duration(milliseconds: 150),
                  );
                }
              });
            }
            final item = dataSource[index - 1];
            if (item.comment.id == scrollToComment?.id) {
              commentIndex = index;
            }
            return item.comment.tile(
              context,
              !isReview,
              item.indent,
              null,
              item.comment.replyCount,
              isReview
                  ? null
                  : (c) {
                      toggleComments(c.id);
                      setState(() {});
                    },
              updateState,
              isReview
                  ? null
                  : () => setState(() {
                        replyingTo = item.comment;
                      }),
              replyingTo?.id == item.comment.id,
              visibleReplyIds.contains(item.comment.id),
              false,
              postAuthor: widget.post.creator.id,
              scrolledTo: scrollToComment?.id == item.comment.id,
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
