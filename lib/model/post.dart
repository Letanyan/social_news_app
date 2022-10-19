import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/comments_page.dart';
import 'package:social_news_app/model/comment_reply.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/parser.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/user.dart';

class Post {
  final int ID;
  final Author Creator;
  final String Content;
  final List<int> Tags;
  final DateTime CreatedAt;
  final List<String> Location;
  final double Upvotes;
  final double Downvotes;

  const Post({
    required this.ID,
    required this.Creator,
    required this.Content,
    required this.Tags,
    required this.CreatedAt,
    required this.Location,
    required this.Upvotes,
    required this.Downvotes,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      ID: json["ID"],
      Creator: Author.fromJson(json["Author"]),
      Content: json["Content"],
      Tags: List<int>.from(json["Tags"]),
      CreatedAt: DateTime.parse(json["CreatedAt"]),
      Location: List<String>.from(json["Location"]),
      Upvotes: json["Upvotes"],
      Downvotes: json["Downvotes"],
    );
  }

  void Function() openComments(BuildContext context) {
    final commentsPage = Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: CommentsPage(post: this),
    );
    return () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => commentsPage),
      );
    };
  }

  Widget card(BuildContext context, bool directLink) {
    final parser = Parser.basic;
    final urlParser = ParserMapping.url(ParserMapping.defaultMap);

    final firstUrl = urlParser.pattern.firstMatch(Content);
    late String newContent;
    void Function()? onTap;
    if (firstUrl != null && firstUrl.start == 0) {
      newContent = Content.substring(firstUrl.end);
      final sourceUrl = Content.substring(firstUrl.start, firstUrl.end);
      onTap = directLink ? (() => launchURL(sourceUrl)) : openComments(context);
    } else {
      newContent = Content;
      onTap = directLink ? null : openComments(context);
    }
    if (ID == -1) {
      onTap = null;
    }

    final query = MediaQuery.of(context).size;
    final size = <String, dynamic>{"w": query.width, "h": query.height};
    final body = RichText(text: parser.parse(newContent, size));

    final creator = Text(Creator.Name);

    final resolvedTags = Tag.getTags(Tags);
    final tags = Tag.chips(context, resolvedTags);

    final reply = TextButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommentReplyPage(post: this),
            )),
        child: const Text("Reply"));

    var items = <Widget>[
      body,
      creator,
      tags,
    ];
    if (ID != -1) {
      items.add(reply);
    }

    final post = Column(
      children: items,
    );

    final card = Card(
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: onTap,
        child: post,
      ),
    );

    return card;
  }
}
