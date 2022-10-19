import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/comments_page.dart';
import 'package:social_news_app/model/comment_reply.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/posts_page.dart';

class Comment {
  final int ID;
  final int PostID;
  final Author User;
  final int ReplyID;
  final String Content;
  final DateTime CreatedAt;
  final double Upvotes;
  final double Downvotes;
  final int ReplyCount;

  const Comment({
    required this.ID,
    required this.PostID,
    required this.User,
    required this.ReplyID,
    required this.Content,
    required this.CreatedAt,
    required this.Upvotes,
    required this.Downvotes,
    required this.ReplyCount,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      ID: json["ID"],
      PostID: json["PostID"],
      User: json["Author"] == null
          ? Author.fromInt(json["UserID"])
          : Author.fromJson(json["Author"]),
      ReplyID: json["ReplyID"],
      Content: json["Content"],
      CreatedAt: DateTime.parse(json["CreatedAt"]),
      Upvotes: json["Upvotes"],
      Downvotes: json["Downvotes"],
      ReplyCount: json["ReplyCount"],
    );
  }

  static List<Comment> listFromJson(List<dynamic> json) {
    return json.map((e) => Comment.fromJson(e)).toList();
  }

  void Function() showParentPost(BuildContext context) {
    return () {
      final post = NewSource.getPost(PostID).then(((value) {
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
      void Function(Comment)? onTap) {
    final text = Text(Content);
    final user = Text(User.Name);
    final replies = Text("$ReplyCount Replies");
    print(onTap);
    final reply = TextButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommentReplyPage(comment: this),
            )),
        child: const Text("Reply"));

    var items = <Widget>[text, user];
    void Function()? finalOnTap;
    if (ReplyCount > 0 || !showReply) {
      items.add(replies);
      if (onTap != null) {
        finalOnTap = () => onTap(this);
      }
    }
    if (showReply) {
      items.add(reply);
    }

    final body = Column(children: items);

    final card = Card(child: InkWell(onTap: finalOnTap, child: body));

    return Row(children: [SizedBox(width: offset), Expanded(child: card)]);
  }
}
