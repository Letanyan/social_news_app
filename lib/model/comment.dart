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
  double upvotes;
  double downvotes;
  final int replyCount;

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

  Widget card(BuildContext context, bool showReply, double offset,
      void Function(Comment)? onTap, VoidCallback updateState) {
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
    final reply = TextButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommentReplyPage(comment: this),
            )),
        child: const Text("Reply"));
    final upvoteButton = ElevatedButton.icon(
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
      icon: const Icon(Icons.arrow_upward_rounded),
      label: Text("$upvotes"),
    );
    final downvoteButton = ElevatedButton.icon(
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
      icon: const Icon(Icons.arrow_downward_rounded),
      label: Text("$downvotes"),
    );

    var buttonRowItems = <Widget>[
      upvoteButton,
      const SizedBox(width: 8),
      downvoteButton
    ];
    if (showReply) {
      buttonRowItems.add(const SizedBox(width: 8));
      buttonRowItems.add(reply);
    }

    var items = <Widget>[text, meta];
    void Function()? finalOnTap;
    if (replyCount > 0 || !showReply) {
      buttonRowItems.add(const SizedBox(width: 8));
      buttonRowItems.add(Text("$replyCount Replies"));
      if (onTap != null) {
        finalOnTap = () => onTap(this);
      }
    }
    final moreButton = PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () {
            showPlatformDialog(
              context: context,
              builder: (context) => FlagDialog(pid: postId, sid: id),
            );
          },
          child: Text("Report"),
        ),
      ],
    );
    buttonRowItems.add(Expanded(
        child: Align(alignment: Alignment.centerRight, child: moreButton)));

    items.add(const Divider());
    items.add(Padding(
        padding: EdgeInsets.all(8), child: Row(children: buttonRowItems)));

    final body = Column(children: items);

    final card = Card(child: InkWell(onTap: finalOnTap, child: body));

    return Row(children: [SizedBox(width: offset), Expanded(child: card)]);
  }
}
