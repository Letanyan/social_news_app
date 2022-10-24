import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/comments_page.dart';
import 'package:social_news_app/model/comment_reply.dart';
import 'package:social_news_app/model/flag.dart';
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
  double Upvotes;
  double Downvotes;
  final int CommentCount;

  Post({
    required this.ID,
    required this.Creator,
    required this.Content,
    required this.Tags,
    required this.CreatedAt,
    required this.Location,
    required this.Upvotes,
    required this.Downvotes,
    required this.CommentCount,
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
      CommentCount: json["CommentCount"],
    );
  }

  void Function() openComments(BuildContext context) {
    final commentsPage = Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: CommentsPage(post: this),
    );
    return () {
      if (User.current != null) {
        NewSource.addUserCont(
            uid: User.current!.ID, kind: UserContKind.viewed, pid: ID);
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => commentsPage),
      );
    };
  }

  Widget card(BuildContext context, bool directLink, VoidCallback updateState,
      {double? up, double? down}) {
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

    final creator = InkWell(
      onTap: () => Creator.showUserPage(context),
      child: Text(Creator.Name),
    );
    final date = Text(formatDateTime(CreatedAt));
    final meta = Padding(
      padding: EdgeInsets.all(8),
      child: Row(children: [
        date,
        Expanded(child: Align(alignment: Alignment.centerRight, child: creator))
      ]),
    );

    final resolvedTags = Tag.getTags(Tags);
    final tags = Tag.chips(context, resolvedTags);

    final reply = TextButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommentReplyPage(post: this),
            )),
        child: const Text("Reply"));
    final upvotesButton = ElevatedButton.icon(
      onPressed: () async {
        if (User.current == null) {
          return;
        }
        Upvotes += 1;
        updateState();
        try {
          final rem = await NewSource.voteForPost(
              postId: ID, userId: User.current!.ID, amount: 1);
          User.current!.Credits = rem;
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
      icon: const Icon(Icons.arrow_upward_rounded),
      label: Text("$Upvotes"),
    );
    final downvotesButton = ElevatedButton.icon(
      onPressed: () async {
        if (User.current == null) {
          return;
        }
        Downvotes += 1;
        updateState();
        try {
          final rem = await NewSource.voteForPost(
              postId: ID, userId: User.current!.ID, amount: -1);
          User.current!.Credits = rem;
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
      icon: const Icon(Icons.arrow_downward_rounded),
      label: Text("$Downvotes"),
    );
    final moreButton = PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
            onTap: () async {
              if (User.current == null) {
                return;
              }
              await NewSource.addUserCont(
                uid: User.current!.ID,
                kind: UserContKind.readLater,
                pid: ID,
              );
            },
            child: const Text("Read Later")),
        PopupMenuItem(
            onTap: () async {
              if (User.current == null) {
                return;
              }
              await NewSource.addUserCont(
                uid: User.current!.ID,
                kind: UserContKind.ignored,
                pid: Creator.ID,
              );
            },
            child: const Text("Ignore User")),
        PopupMenuItem(
          onTap: () {
            showPlatformDialog(
              context: context,
              builder: (context) => FlagDialog(pid: ID, sid: -1),
            );
          },
          child: Text("Report"),
        ),
      ],
    );

    late Widget? personalVotes;
    if (up != null && down != null) {
      personalVotes = Text("$up - $down");
    } else {
      personalVotes = const Text("");
    }

    final buttonRow = Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          upvotesButton,
          const SizedBox(width: 8),
          downvotesButton,
          const SizedBox(width: 8),
          reply,
          Text(CommentCount == 0
              ? ""
              : CommentCount == 1
                  ? "$CommentCount Reply"
                  : "$CommentCount Replies"),
          const SizedBox(width: 8),
          personalVotes,
          Expanded(
              child:
                  Align(alignment: Alignment.centerRight, child: moreButton)),
        ],
      ),
    );

    var items = <Widget>[
      Padding(padding: const EdgeInsets.all(8), child: body),
      const Divider(),
      Padding(padding: const EdgeInsets.all(8), child: meta),
      tags,
    ];
    if (ID != -1) {
      items.add(const Divider());
      items.add(buttonRow);
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

    return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 4), child: card);
  }
}
