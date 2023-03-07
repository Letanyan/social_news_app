import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/chat_page.dart';
import 'package:social_news_app/comment_reply.dart';
import 'package:social_news_app/comments_page.dart';
import 'package:social_news_app/comments_thread_page.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/parser.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/user_pref_page.dart';
import 'package:social_news_app/widgets/vote_widget.dart';

class Comment {
  final int id;
  final int postId;
  final Author author;
  final int replyId;
  String content;
  final DateTime createdAt;
  int upvotes;
  int downvotes;
  int replyCount;
  bool trashed;
  DateTime edited;
  bool isReview;
  int flagCount;
  num score;
  num cred;
  num rank;

  Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.replyId,
    required this.content,
    required this.createdAt,
    required this.upvotes,
    required this.downvotes,
    required this.replyCount,
    required this.trashed,
    required this.edited,
    required this.isReview,
    required this.flagCount,
    required this.score,
    required this.cred,
    required this.rank,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: int.parse(json["ID"]),
      postId: json["PostID"],
      author: json["Author"] == null
          ? Author.fromInt(json["UserID"])
          : Author.fromJson(json["Author"]),
      replyId: json["ReplyID"],
      content: json["Content"],
      createdAt: DateTime.parse(json["CreatedAt"]).toLocal(),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
      replyCount: json["ReplyCount"],
      trashed: json["Trashed"],
      edited: DateTime.parse(json["Edited"]).toLocal(),
      isReview: json["IsReview"],
      flagCount: int.parse(json["FlagCount"]),
      score: json["Score"],
      cred: json["Cred"],
      rank: json["Rank"],
    );
  }

  static List<Comment> listFromJson(List<dynamic> json) {
    return json.map((e) => Comment.fromJson(e)).toList();
  }

  void Function() showParentPost(BuildContext context) {
    return () {
      NewSource.getPost(postId).then(
        (value) {
          value.openComments(context, () {}, this)();
        },
      ).catchError((e) {
        displayError(context, e);
        return;
      });
    };
  }

  Widget buildCreator(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => author.showUserPage(context),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: RichText(
          text: TextSpan(
            text: "${author.name} ",
            style: theme.bodyText1,
            children: [
              TextSpan(
                text: "${author.calculateScore()} ",
                style: const TextStyle(color: Colors.grey),
              ),
              TextSpan(
                text: "(${author.calculateCred()})",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void Function(BuildContext, int) updateVote(VoidCallback updateState) {
    return (BuildContext context, int amount) {
      if (User.current == null) {
        return;
      }
      if (amount > 0) {
        upvotes += amount;
      } else {
        downvotes += -amount;
      }
      updateState();
      try {
        NewSource.voteForComment(
                postId: postId,
                commentId: id,
                userId: User.current!.id,
                amount: amount)
            .then((value) {
          User.current!.credits = value;
        }).catchError((e) {
          displayError(context, e);
          return;
        });
      } catch (e) {
        displayError(context, e);
      }
    };
  }

  Function() showCommentThread(
      BuildContext context, List<Comment>? sourceData, Function() showReply) {
    return () {
      final body = CommentsThreadPage(
        origin: this,
        sourceData: sourceData ?? [],
        scrollComments: null,
      );
      WidgetsBinding.instance.addPostFrameCallback((ts) {
        Navigator.push(
          context,
          route(builder: (context) => body),
        );
      });
    };
  }

  Widget card(
    BuildContext context,
    bool showReply,
    int offset,
    int? replyCount,
    void Function(Comment)? onTap,
    VoidCallback updateState,
    Function()? showReplyField,
    bool isReplyingTo,
    bool highlightedReplies, {
    int? postAuthor,
    int? up,
    int? down,
    bool? scrolledTo,
  }) {
    if (trashed) {
      return const SizedBox();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontFamily: "Helvetica",
      fontWeight: FontWeight.normal,
    );
    final parser = Parser.basic(defaultStyle);
    final urlParser = ParserMapping.url(ParserMapping.defaultMap);
    final firstUrl = urlParser.pattern.firstMatch(content);
    late String newContent;
    if (flagCount >= flagReasonLimit) {
      if (showReplyField != null) {
        newContent = TRFlag.flaggedContentMessageShowReport;
      } else {
        newContent = TRFlag.flaggedContentMessage;
      }
    } else if (firstUrl != null && firstUrl.start == 0) {
      newContent = content.substring(firstUrl.end);
    } else {
      newContent = content;
    }
    final query = MediaQuery.of(context).size;
    final size = <String, dynamic>{
      "w": query.width,
      "h": query.height,
      "img": author.isAgent
    };
    final text = RichText(text: parser.parse(newContent, size));
    final creator = buildCreator(context);
    final date = Text(
      edited.isAfter(createdAt)
          ? "${TRGeneral.edited} ${formatDateTime(edited)}"
          : formatDateTime(createdAt),
      style: const TextStyle(color: Colors.grey),
    );
    final meta = Padding(
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        creator,
        Expanded(child: Align(alignment: Alignment.centerRight, child: date))
      ]),
    );
    final reply = buildReplyButton(context, isReplyingTo, () {
      if (showReplyField != null) {
        showReplyField();
      }
    });
    final replyCountChip = buildReplyCountButton(
      context,
      replyCount ?? this.replyCount,
      highlightedReplies,
      onTap == null || replyCount == 0 ? null : () => onTap(this),
    );
    final kind = isReview ? UserVoteKind.review : UserVoteKind.comment;
    final upvoteButton = buildVoteButton(
      context,
      upvotes,
      true,
      kind,
      updateVote(updateState),
    );
    final downvoteButton = buildVoteButton(
      context,
      downvotes,
      false,
      kind,
      updateVote(updateState),
    );

    var buttonRowItems = <Widget>[
      const SizedBox(width: 8),
      upvoteButton,
      const SizedBox(width: 8),
      downvoteButton
    ];
    if (showReply) {
      buttonRowItems.add(const SizedBox(width: 16));
      buttonRowItems.add(reply);
      buttonRowItems.add(const SizedBox(width: 1));
      buttonRowItems.add(replyCountChip);
    }

    var items = <Widget>[
      Padding(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: text,
        ),
      ),
      meta,
    ];

    final removeComment = PopupMenuItem(
      onTap: () {
        displayString(context, TRGeneral.removed);
        trashed = true;
        updateState();
        NewSource.deleteComment(postId, id).catchError((e) {
          displayError(context, e);
          return false;
        });
      },
      child: Text(TRGeneral.remove),
    );
    final editComment = PopupMenuItem(
      value: 3517,
      onTap: () {},
      child: Text(TRGeneral.edit),
    );

    final votedFor = PopupMenuItem(
      onTap: () {
        final title = contentKindToString(ContentKind.user);

        final body = UserPrefPage(
          title: title,
          showSearch: true,
          prefKind: ContentKind.comment,
          user: User.current?.toAuthor(),
          isViewed: false,
          pid: postId,
          sid: id,
        );
        WidgetsBinding.instance.addPostFrameCallback((ts) {
          Navigator.push(
            context,
            route(builder: (context) => body),
          );
        });
      },
      child: Text(TRGeneral.votedBy),
    );
    final userActionsList = <PopupMenuItem>[];
    userActionsList.add(votedFor);
    if (author.id == User.current?.id ||
        (User.current?.id == postAuthor && postAuthor != null)) {
      userActionsList.add(removeComment);
      userActionsList.add(editComment);
    }

    final report = PopupMenuItem(
      onTap: () {
        showPlatformDialog(
          context: context,
          builder: (context) => FlagDialog(pid: postId, sid: id),
        );
      },
      child: Text(TRGeneral.report),
    );
    final reportReasons = PopupMenuItem(
      onTap: () => showPlatformDialog(
        context: context,
        builder: (context) => FlagReasonDialog(pid: postId, sid: id),
      ),
      child: Text(TRGeneral.showReport),
    );
    var reportItems = <PopupMenuItem>[report];
    if (flagCount >= flagReasonLimit) {
      reportItems.add(reportReasons);
    }

    final moreButton = PopupMenuButton(
      onSelected: (value) {
        final page = CreatePage(comment: this, isEdit: true);
        Navigator.of(context)
            .push(
              route(builder: (context) => page),
            )
            .then((value) => updateState());
      },
      itemBuilder: (context) => [
        ...userActionsList,
        ...reportItems,
      ],
    );
    buttonRowItems.add(moreButton);

    items.add(
      Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: buttonRowItems,
        ),
      ),
    );

    if (up != null && down != null) {
      final upChip = buildVoteChip(context, up, true);
      final downChip = buildVoteChip(context, down, false);
      final desc = Padding(
        padding: EdgeInsets.all(4),
        child: Text(TRGeneral.votesFromUser),
      );

      items.add(Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          desc,
          const SizedBox(width: 4),
          upChip,
          downChip,
          const SizedBox(width: 8),
        ],
      ));
    }
    items.add(const SizedBox(height: 8));
    items.insert(0, Divider(height: 2));

    final body = Column(children: items);

    Function()? cardTap = null;
    if (showReplyField != null) {
      if (flagCount >= flagReasonLimit) {
        cardTap = () {
          flagCount = -1;
          updateState();
        };
      } else {
        if (onTap == null || replyCount == 0) {
          cardTap = () => showReplyField();
        } else {
          cardTap = () => onTap(this);
        }
      }
    } else if (onTap != null) {
      cardTap = showParentPost(context);
    }

    final card = Material(
      color: scrolledTo == true ? MyTheme.primary.withAlpha(20) : null,
      child: InkWell(
        onTap: cardTap,
        child: body,
      ),
    );

    var indents = <Widget>[];
    for (var i = 0; i < offset; i++) {
      const div = VerticalDivider(
        width: 6,
        thickness: 1,
        color: Colors.white,
        indent: 0,
        endIndent: 0,
      );
      indents.add(div);
    }

    return IntrinsicHeight(
      child: Row(children: [
        ...indents,
        Expanded(child: card),
      ]),
    );
  }

  Widget tile(
    BuildContext context,
    bool showReply,
    int offset,
    Comment? replyTo,
    int? replyCount,
    void Function(Comment)? onTap,
    VoidCallback updateState,
    Function()? showReplyField,
    bool isReplyingTo,
    bool highlightedReplies,
    bool isPreview, {
    List<Comment>? sourceData,
    int? postAuthor,
    int? up,
    int? down,
    bool? scrolledTo,
  }) {
    if (trashed) {
      return const SizedBox();
    }
    final isDark = MyTheme.isDark;
    final defaultStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontFamily: "Helvetica",
      fontWeight: FontWeight.normal,
    );
    final parser = Parser.basic(defaultStyle);
    final urlParser = ParserMapping.url(ParserMapping.defaultMap);
    final firstUrl = urlParser.pattern.firstMatch(content);
    late String newContent;
    if (flagCount >= flagReasonLimit) {
      if (showReplyField != null) {
        newContent = TRFlag.flaggedContentMessageShowReport;
      } else {
        newContent = TRFlag.flaggedContentMessage;
      }
    } else if (firstUrl != null && firstUrl.start == 0) {
      newContent = content.substring(firstUrl.end);
    } else {
      newContent = content;
    }
    if (isPreview && newContent.length > 256) {
      newContent = newContent.substring(0, 256);
    }
    final query = MediaQuery.of(context).size;
    final size = <String, dynamic>{
      "w": query.width,
      "h": query.height,
      "img": author.isAgent
    };
    final text = RichText(text: parser.parse(newContent, size));
    final creator = buildCreator(context);
    final date = Text(
      (edited.isAfter(createdAt)
              ? "${TRGeneral.edited} ${formatDateTime(edited)}"
              : formatDateTime(createdAt)) +
          " ",
      style: const TextStyle(color: Colors.grey),
    );
    final meta = Padding(
      padding: const EdgeInsets.all(2),
      child: Row(children: [
        creator,
        Expanded(child: Align(alignment: Alignment.centerRight, child: date))
      ]),
    );
    final reply = buildReplyButton(context, isReplyingTo, () {
      if (showReplyField != null) {
        showReplyField();
      }
    });
    final replyCountChip = buildReplyCountButton(
      context,
      replyCount ?? this.replyCount,
      highlightedReplies,
      onTap == null || replyCount == 0
          ? null
          : showCommentThread(context, sourceData, showReplyField ?? () {}),
    );
    final kind = isReview ? UserVoteKind.review : UserVoteKind.comment;
    final upvoteButton = buildVoteButton(
      context,
      upvotes,
      true,
      kind,
      updateVote(updateState),
    );
    final downvoteButton = buildVoteButton(
      context,
      downvotes,
      false,
      kind,
      updateVote(updateState),
    );

    var buttonRowItems = <Widget>[
      const SizedBox(width: 8),
      upvoteButton,
      const SizedBox(width: 2),
      downvoteButton
    ];
    if (showReply) {
      buttonRowItems.add(const SizedBox(width: 4));
      buttonRowItems.add(reply);
      buttonRowItems.add(const SizedBox(width: 1));
      buttonRowItems.add(replyCountChip);
    }

    var replyingTo = <Widget>[];
    if (replyTo != null) {
      final preview = replyTo.tile(
        context,
        false,
        0,
        null,
        null,
        onTap,
        () {},
        () => null,
        false,
        false,
        true,
      );
      replyingTo.add(preview);
    }

    var items = <Widget>[
      ...replyingTo,
      Padding(
        padding: const EdgeInsets.only(left: 8, top: 8, bottom: 2, right: 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: text,
        ),
      ),
      meta,
    ];

    if (!isPreview) {
      items.insert(0, Divider(height: 2));
    }

    final removeComment = PopupMenuItem(
      onTap: () {
        displayString(context, TRGeneral.removed);
        trashed = true;
        updateState();
        NewSource.deleteComment(postId, id).catchError((e) {
          displayError(context, e);
          return false;
        });
      },
      child: Text(TRGeneral.remove),
    );
    final editComment = PopupMenuItem(
      value: 3517,
      onTap: () {},
      child: Text(TRGeneral.edit),
    );

    final votedFor = PopupMenuItem(
      onTap: () {
        final title = contentKindToString(ContentKind.user);

        final body = UserPrefPage(
          title: title,
          showSearch: true,
          prefKind: ContentKind.comment,
          user: User.current?.toAuthor(),
          isViewed: false,
          pid: postId,
          sid: id,
        );
        WidgetsBinding.instance.addPostFrameCallback((ts) {
          Navigator.push(
            context,
            route(builder: (context) => body),
          );
        });
      },
      child: Text(TRGeneral.votedBy),
    );
    final threadView = PopupMenuItem(
      onTap: showCommentThread(context, sourceData, showReplyField ?? () {}),
      child: Text(TRGeneral.thread),
    );
    final userActionsList = <PopupMenuItem>[];
    userActionsList.add(threadView);
    userActionsList.add(votedFor);
    if (author.id == User.current?.id ||
        (User.current?.id == postAuthor && postAuthor != null)) {
      userActionsList.add(removeComment);
      userActionsList.add(editComment);
    }

    final report = PopupMenuItem(
      onTap: () {
        showPlatformDialog(
          context: context,
          builder: (context) => FlagDialog(pid: postId, sid: id),
        );
      },
      child: Text(TRGeneral.report),
    );
    final reportReasons = PopupMenuItem(
      onTap: () => showPlatformDialog(
        context: context,
        builder: (context) => FlagReasonDialog(pid: postId, sid: id),
      ),
      child: Text(TRGeneral.showReport),
    );
    var reportItems = <PopupMenuItem>[report];
    if (flagCount >= flagReasonLimit) {
      reportItems.add(reportReasons);
    }

    final moreButton = PopupMenuButton(
      onSelected: (value) {
        final page = CreatePage(comment: this, isEdit: true);
        Navigator.of(context)
            .push(
              route(builder: (context) => page),
            )
            .then((value) => updateState());
      },
      itemBuilder: (context) => [
        ...userActionsList,
        ...reportItems,
      ],
    );
    buttonRowItems.add(moreButton);

    if (!isPreview) {
      items.add(
        Padding(
          padding: const EdgeInsets.all(0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: buttonRowItems,
          ),
        ),
      );
    }

    if (!isPreview && up != null && down != null) {
      final upChip = buildVoteChip(context, up, true);
      final downChip = buildVoteChip(context, down, false);
      final desc = Padding(
        padding: EdgeInsets.all(4),
        child: Text(TRGeneral.votesFromUser),
      );

      items.add(Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          desc,
          const SizedBox(width: 4),
          upChip,
          downChip,
          const SizedBox(width: 8),
        ],
      ));
    }
    items.add(const SizedBox(height: 8));

    final body = Column(children: items);

    Function()? cardTap = null;
    if (isPreview) {
      if (onTap != null) {
        cardTap = () => onTap(this);
      }
    } else if (showReplyField != null) {
      if (flagCount >= flagReasonLimit) {
        cardTap = () {
          flagCount = -1;
          updateState();
        };
      } else {
        cardTap = () => showReplyField();
      }
    } else if (onTap != null) {
      cardTap = showParentPost(context);
    }

    final card = Material(
      color: scrolledTo == true
          ? MyTheme.primary.withAlpha(20)
          : isPreview
              ? isDark
                  ? Colors.black.withAlpha(20)
                  : Colors.black.withAlpha(10)
              : null,
      child: InkWell(
        onTap: cardTap,
        child: body,
      ),
    );

    if (isPreview) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: card,
        ),
      );
    }

    return card;
  }
}
