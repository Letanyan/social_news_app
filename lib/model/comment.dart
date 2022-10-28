import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/comments_page.dart';
import 'package:social_news_app/model/comment_reply.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/posts_page.dart';

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
          MaterialPageRoute(builder: (context) => page),
        );
      }));
    };
  }

  Widget card(
      BuildContext context,
      bool showReply,
      double offset,
      void Function(Comment)? onTap,
      VoidCallback updateState,
      Function()? showReplyField,
      {int? postAuthor,
      int? up,
      int? down}) {
    if (trashed) {
      return const SizedBox();
    }
    final text = Text(content);
    final creator = InkWell(
      onTap: () => author.showUserPage(context),
      child: Text(author.Name),
    );
    final date = Text(formatDateTime(createdAt));
    final meta = Padding(
      padding: EdgeInsets.all(8),
      child: Row(children: [
        date,
        Expanded(child: Align(alignment: Alignment.centerRight, child: creator))
      ]),
    );
    final reply = ActionChip(
      onPressed: () {
        showReplyField!();
        print("23456789--------------");
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
      avatar:
          const Icon(Icons.add_comment_rounded, color: Colors.brown, size: 18),
      label: const Text("Reply"),
    );
    final replyCountChip = ActionChip(
      onPressed: onTap == null ? null : () => onTap(this),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      avatar: const Icon(Icons.comment, color: Colors.brown, size: 18),
      label:
          Text(replyCount == 1 ? "$replyCount Reply" : "$replyCount Replies"),
    );
    final upvoteButton = ActionChip(
      onPressed: () async {
        if (User.current == null) {
          return;
        }
        upvotes += 1;
        updateState();
        try {
          final rem = await NewSource.voteForComment(
              postId: postId,
              commentId: id,
              userId: User.current!.ID,
              amount: 1);
          User.current!.Credits = rem;
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
      avatar: const Icon(Icons.speaker, color: Colors.brown, size: 18),
      label: Text("$upvotes"),
    );
    final downvoteButton = ActionChip(
      onPressed: () async {
        if (User.current == null) {
          return;
        }
        downvotes += 1;
        updateState();
        try {
          final rem = await NewSource.voteForComment(
              postId: postId,
              commentId: id,
              userId: User.current!.ID,
              amount: -1);
          User.current!.Credits = rem;
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      avatar: const Icon(Icons.back_hand, color: Colors.brown, size: 18),
      label: Text("$downvotes"),
    );

    var buttonRowItems = <Widget>[
      upvoteButton,
      const SizedBox(width: 1),
      downvoteButton
    ];
    if (showReply) {
      buttonRowItems.add(const SizedBox(width: 8));
      buttonRowItems.add(reply);
      buttonRowItems.add(const SizedBox(width: 1));
      buttonRowItems.add(replyCountChip);
    }

    var items = <Widget>[text, meta];
    var reviewItems = <Widget>[];
    if (up != null && down != null) {
      final upChip = Chip(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
        ),
        avatar: const Icon(Icons.speaker, color: Colors.brown, size: 18),
        label: Text("$up"),
      );
      final downChip = Chip(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        avatar: const Icon(Icons.back_hand, color: Colors.brown, size: 18),
        label: Text("$down"),
      );
      reviewItems.add(upChip);
      reviewItems.add(const SizedBox(width: 1));
      reviewItems.add(downChip);
    }

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
    if (author.ID == User.current?.ID ||
        (User.current?.ID == postAuthor && postAuthor != null)) {
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

    items.add(const Divider());
    items.add(Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: buttonRowItems)));
    if (reviewItems.isNotEmpty) {
      items.add(const Divider());
      items.add(
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: reviewItems,
          ),
        ),
      );
    }

    final body = Column(children: items);

    final intensity = 0xFF - offset.toInt();
    final shade = Color.fromARGB(0xFF, intensity, intensity, intensity);
    final card = Card(color: shade, child: InkWell(onTap: null, child: body));

    return Row(children: [SizedBox(width: offset), Expanded(child: card)]);
  }
}
