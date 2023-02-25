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

class ChatPage extends StatefulWidget {
  final Post post;
  final Comment? scrollComments;

  const ChatPage({super.key, required this.post, required this.scrollComments});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _IndentedComment {
  final Comment comment;
  final int indent;

  const _IndentedComment(this.comment, this.indent);
}

class _ChatPageState extends State<ChatPage> {
  late Future<List<Comment>> allComments;
  late Future<List<Comment>> reviews;
  late Future<List<Comment>> comments;
  late Map<int, Comment> indexedComments;
  Timer? timer;
  bool isLoading = true;
  int count = 0;
  int reviewCount = 0;
  bool isReview = false;
  SortOrder sortOrder = SortOrder.createdAt;

  final controller = TextEditingController();
  final scroller = ItemScrollController();
  int? commentIndex;
  Comment? replyingTo;
  String? searchString;
  Comment? scrollToComment;
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();

    comments = Future(() => []);
    reviews = Future(() => []);
    indexedComments = {};

    loadComments(-1);
    replyingTo = null;
    searchString = null;
    scrollToComment = widget.scrollComments;
    isReview = widget.scrollComments?.isReview ?? false;

    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((visible) {
      if (!visible) {
        replyingTo = null;
        searchString = null;
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
      if (User.current == null) {
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
    ).catchError((e) {
      displayError(ctx.target, e);
      return <Comment>[];
    });
    sortComments();
  }

  Future<void> sortComments() async {
    var source = await allComments;
    isLoading = false;

    source.sort((a, b) {
      switch (sortOrder) {
        case SortOrder.addedOn:
          return -a.createdAt.compareTo(b.createdAt);
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
          return -a.createdAt.compareTo(b.createdAt);
        case SortOrder.updatedAt:
          return -a.createdAt.compareTo(b.createdAt);
        case SortOrder.updatedOn:
          return -a.createdAt.compareTo(b.createdAt);
        case SortOrder.rank:
          return a.rank.compareTo(b.rank);
      }
    });
    allComments = Future(() => source);
    var reviewSource = <Comment>[];
    var commentSource = <Comment>[];
    for (final c in source) {
      if (c.isReview) {
        if (searchString != null) {
          if (c.content.contains(searchString!)) {
            reviewSource.add(c);
          }
        } else {
          reviewSource.add(c);
        }
      } else {
        if (searchString != null) {
          if (c.content.contains(searchString!)) {
            commentSource.add(c);
            indexedComments[c.id] = c;
          }
        } else {
          commentSource.add(c);
          indexedComments[c.id] = c;
        }
      }
    }
    count = commentSource.length;
    reviewCount = reviewSource.length;
    reviews = Future(() => reviewSource);
    comments = Future(() => commentSource);
    updateState();
  }

  void updateState() {
    setState(() {
      allComments = allComments;
      comments = comments;
      reviews = reviews;
    });
  }

  int indexOfComment(int commentId, List<Comment> source) {
    int i = 0;
    for (final c in source) {
      if (c.id == commentId) {
        return i;
      }
      i += 1;
    }
    return -1;
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
      for (var comment in await comments) {
        if (comment.id == replyId) {
          comment.replyCount += 1;
        }
      }
      (await comments).add(result);
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
        hintText:
            replyingTo != null ? TRCommentsPage.enterReply : TRGeneral.search,
      ),
    );
    final send = Padding(
      padding: const EdgeInsets.all(8),
      child: TextButton(
        onPressed: () {
          if (replyingTo != null) {
            replyToComment();
          } else if (searchString != null) {
            setState(() {
              searchString = controller.text;
              sortComments();
            });
          }
        },
        child: Text(replyingTo != null ? TRGeneral.reply : TRGeneral.search),
      ),
    );
    final cancel = Padding(
      padding: const EdgeInsets.all(8),
      child: TextButton(
        onPressed: () {
          setState(() {
            controller.text = "";
            replyingTo = null;
            if (searchString != null) {
              searchString = null;
              sortComments();
            }
          });
        },
        child: Text(TRGeneral.cancel),
      ),
    );
    final actions = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [send, cancel],
    );

    return Visibility(
      visible: replyingTo != null || searchString != null,
      child: Row(
        children: [Expanded(child: textField), actions],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = FutureBuilder<List<Comment>>(
      future: isReview ? reviews : comments,
      builder: (context, snapshot) {
        final card = widget.post.card(context, updateState);
        final sel = CupertinoSlidingSegmentedControl(
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
        final searchGlass = InkWell(
          onTap: () {
            setState(() {
              scrollToComment = null;
              searchString = "";
            });
          },
          child: Icon(Icons.search_rounded),
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
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: sort,
              ),
              Expanded(child: Center(child: sel)),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: searchGlass,
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          final indicator = isLoading
              ? CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    isReview
                        ? TRCommentsPage.noCritiques
                        : TRCommentsPage.noDiscussion,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
          final empty = SingleChildScrollView(
            child: Column(
              children: [
                ...previewItems,
                indicator,
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
              return Column(children: previewItems);
            }
            if (index - 1 >= dataSource.length) {
              return const SizedBox();
            }
            final item = dataSource[index - 1];
            Comment? itemReply;
            if (item.replyId > 0) {
              itemReply = indexedComments[item.replyId] ?? null;
            }
            return item.tile(
              context,
              !isReview,
              0,
              itemReply,
              item.replyCount,
              isReview
                  ? null
                  : (c) {
                      setState(() {
                        if (itemReply != null) {
                          scrollToComment = itemReply;
                        }
                      });
                    },
              updateState,
              isReview
                  ? null
                  : () => setState(() {
                        scrollToComment = null;
                        replyingTo = item;
                      }),
              replyingTo?.id == item.id,
              false,
              false,
              sourceData: snapshot.data,
              postAuthor: widget.post.creator.id,
              scrolledTo: scrollToComment?.id == item.id,
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

        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (scrollToComment != null) {
            final scrollIndex =
                indexOfComment(scrollToComment!.id, snapshot.data!);
            if (scrollIndex < 0) {
              return;
            }
            scroller.scrollTo(
              index: scrollIndex + 1,
              duration: const Duration(milliseconds: 150),
            );
            Future.delayed(Duration(seconds: 10), () {
              scrollToComment = null;
            });
          }
        });

        return KeyboardDismissOnTap(dismissOnCapturedTaps: true, child: body);
      },
    );

    return list;
  }
}
