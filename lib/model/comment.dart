import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/comment_reply.dart';
import 'package:social_news_app/comments_page.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/parser.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';
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
      NewSource.getPost(postId).then(((value) {
        final page = Scaffold(
          appBar: AppBar(title: Text(TRGeneral.comments)),
          body: CommentsPage(post: value, scrollComments: this),
        );
        Navigator.push(
          context,
          route(builder: (context) => page),
        );
      }));
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
        }).onError((error, stackTrace) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.toString())));
        });
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
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
    if (flagCount >= 0) {
      newContent = TRFlag.flaggedContentMessage;
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

    var items = <Widget>[text, meta];

    final removeComment = PopupMenuItem(
      onTap: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(TRGeneral.removed)));
        trashed = true;
        updateState();
        NewSource.deleteComment(postId, id);
      },
      child: Text(TRGeneral.remove),
    );
    final editComment = PopupMenuItem(
      value: 3517,
      onTap: () {},
      child: Text(TRGeneral.edit),
    );
    final userActionsList = <PopupMenuItem>[];
    if (author.id == User.current?.id ||
        (User.current?.id == postAuthor && postAuthor != null)) {
      userActionsList.add(removeComment);
      userActionsList.add(editComment);
    }

    final moreButton = PopupMenuButton(
      onSelected: (value) {
        final page = CommentReplyPage(comment: this, isEdit: true);
        Navigator.of(context)
            .push(
              route(builder: (context) => page),
            )
            .then((value) => updateState());
      },
      itemBuilder: (context) => [
        ...userActionsList,
        PopupMenuItem(
          onTap: () {
            showPlatformDialog(
              context: context,
              builder: (context) => FlagDialog(pid: postId, sid: id),
            );
          },
          child: Text(TRGeneral.report),
        ),
      ],
    );
    buttonRowItems.add(Expanded(
        child: Align(alignment: Alignment.centerRight, child: moreButton)));

    items.add(Padding(
        padding: const EdgeInsets.all(2),
        child: Row(children: buttonRowItems)));

    if (up != null && down != null) {
      final upChip = buildVoteChip(context, up, true);
      final downChip = buildVoteChip(context, down, false);

      items.add(Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          upChip,
          downChip,
          const SizedBox(width: 8),
        ],
      ));
    }
    items.add(const SizedBox(height: 8));

    final body = Column(children: items);

    final card = Material(
      color: scrolledTo == true ? MyTheme.primary.withAlpha(20) : null,
      child: InkWell(
        onTap: showReplyField != null
            ? () => showReplyField()
            : showParentPost(context),
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
}
