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
import 'package:social_news_app/posts_page.dart';

class Post {
  final int ID;
  final Author Creator;
  final String Content;
  final List<int> Tags;
  final DateTime CreatedAt;
  final List<String> Location;
  int Upvotes;
  int Downvotes;
  final int CommentCount;
  bool Trashed;

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
    required this.Trashed,
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
      Trashed: json["Trashed"],
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

  void openSimilar(BuildContext context) {
    final postsPage = Scaffold(
      appBar: AppBar(title: const Text("Similar")),
      body: PostsPage(
          forUser: User.current!.ID, postId: ID, order: SortOrder.score),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => postsPage),
    );
  }

  Widget card(BuildContext context, bool directLink, VoidCallback updateState,
      {int? up, int? down}) {
    if (Trashed) {
      return const SizedBox();
    }
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

    final reply = ActionChip(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommentReplyPage(post: this),
            )),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
        ),
        avatar: const Icon(Icons.add_comment_rounded,
            color: Colors.brown, size: 18),
        label: const Text("Reply"));
    final replyCount = ActionChip(
      onPressed: openComments(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      avatar: const Icon(Icons.comment, color: Colors.brown, size: 18),
      label: Text(
          CommentCount == 1 ? "$CommentCount Reply" : "$CommentCount Replies"),
    );
    final upvotesButton = ActionChip(
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
      avatar: const Icon(Icons.speaker, color: Colors.brown, size: 18),
      label: Text("$Upvotes"),
    );
    final downvotesButton = ActionChip(
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      avatar: const Icon(Icons.back_hand, color: Colors.brown, size: 18),
      label: Text("$Downvotes"),
    );
    final removePost = PopupMenuItem(
      onTap: () {
        NewSource.deletePost(ID).then((value) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Removed")));
          Trashed = true;
          updateState();
          return value;
        });
      },
      child: const Text("Remove"),
    );
    final removePostList = <PopupMenuItem>[];
    if (Creator.ID == User.current?.ID) {
      removePostList.add(removePost);
    }
    final moreButton = PopupMenuButton(
      itemBuilder: (context) => [
        ...removePostList,
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
          child: const Text("Report"),
        ),
      ],
    );

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

    final showSimilar = TextButton(
        onPressed: () => openSimilar(context), child: const Text("Similar"));

    final buttonRow = Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          upvotesButton,
          const SizedBox(width: 1),
          downvotesButton,
          const SizedBox(width: 8),
          reply,
          const SizedBox(width: 1),
          replyCount,
          const SizedBox(width: 8),
          // showSimilar,
          Expanded(
              child:
                  Align(alignment: Alignment.centerRight, child: moreButton)),
        ],
      ),
    );

    var items = <Widget>[
      Padding(padding: const EdgeInsets.all(8), child: body),
      const Divider(),
      Padding(padding: const EdgeInsets.all(0), child: meta),
      tags,
    ];
    if (ID != -1) {
      items.add(const Divider());
      items.add(buttonRow);
    }
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
