import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/comments_page.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/widgets/vote_widget.dart';

class Comment {
  final int id;
  final int postId;
  final Author author;
  final int replyId;
  final String content;
  final DateTime createdAt;
  int upvotes;
  int downvotes;
  final int replyCount;
  bool trashed;
  bool isReview;
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
    required this.isReview,
    required this.score,
    required this.cred,
    required this.rank,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json["ID"],
      postId: json["PostID"],
      author: json["Author"] == null
          ? Author.fromInt(json["UserID"])
          : Author.fromJson(json["Author"]),
      replyId: json["ReplyID"],
      content: json["Content"],
      createdAt: DateTime.parse(json["CreatedAt"]),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
      replyCount: json["ReplyCount"],
      trashed: json["Trashed"],
      isReview: json["IsReview"],
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
      final post = NewSource.getPost(postId).then(((value) {
        final page = Scaffold(
          appBar: AppBar(title: const Text("Comments")),
          body: CommentsPage(post: value),
        );
        Navigator.push(
          context,
          route(builder: (context) => page),
        );
      }));
    };
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
      void Function(Comment)? onTap,
      VoidCallback updateState,
      Function()? showReplyField,
      bool isReplyingTo,
      bool highlightedReplies,
      {int? postAuthor,
      int? up,
      int? down}) {
    if (trashed) {
      return const SizedBox();
    }
    final text = Padding(
      padding: const EdgeInsets.all(8),
      child: Align(alignment: Alignment.centerLeft, child: Text(content)),
    );
    final creator = InkWell(
      onTap: () => author.showUserPage(context),
      child: Text(
        author.name,
        style: const TextStyle(color: Colors.grey),
      ),
    );
    final date = Text(
      formatDateTime(createdAt),
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
      replyCount,
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
        NewSource.deleteComment(postId, id).then((value) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Removed")));
          trashed = true;
          updateState();
          return value;
        });
      },
      child: const Text("Remove"),
    );
    final removeCommentList = <PopupMenuItem>[];
    if (author.id == User.current?.id ||
        (User.current?.id == postAuthor && postAuthor != null)) {
      removeCommentList.add(removeComment);
    }

    final moreButton = PopupMenuButton(
      itemBuilder: (context) => [
        ...removeCommentList,
        PopupMenuItem(
          onTap: () {
            showPlatformDialog(
              context: context,
              builder: (context) => FlagDialog(pid: postId, sid: id),
            );
          },
          child: const Text("Report"),
        ),
      ],
    );
    buttonRowItems.add(Expanded(
        child: Align(alignment: Alignment.centerRight, child: moreButton)));

    items.add(Padding(
        padding: const EdgeInsets.all(2),
        child: Row(children: buttonRowItems)));

    if (up != null && down != null) {
      final upChip = Row(children: [
        const Icon(
          size: 12,
          Icons.speaker,
        ),
        Text(" $up"),
      ]);
      final downChip = Row(children: [
        const Icon(
          size: 12,
          Icons.back_hand,
        ),
        Text(" $down"),
      ]);

      items.add(Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          upChip,
          const SizedBox(width: 8),
          downChip,
          const SizedBox(width: 8),
        ],
      ));
    }
    items.add(const SizedBox(height: 8));

    final body = Column(children: items);

    final card = Material(
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
        indent: 8,
        endIndent: 8,
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
