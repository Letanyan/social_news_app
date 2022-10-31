import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/comments_page.dart';
import 'package:social_news_app/comment_reply.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/parser.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/posts_page.dart';
import 'package:social_news_app/widgets/vote_widget.dart';

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

  String? sourceUrl;

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
  }) : sourceUrl = null;

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
      appBar: AppBar(
        title: const Text("Comments"),
        actions: [
          IconButton(
            onPressed: () => launchURL(sourceUrl ?? ""),
            icon: const Icon(Icons.open_in_browser_rounded),
          )
        ],
      ),
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

  void Function(BuildContext, int) updateVote(VoidCallback updateState) {
    return (BuildContext context, int amount) {
      if (User.current == null) {
        return;
      }
      if (amount > 0) {
        Upvotes += amount;
      } else {
        Downvotes += -amount;
      }
      updateState();
      try {
        NewSource.voteForPost(
                postId: ID, userId: User.current!.ID, amount: amount)
            .then((value) {
          User.current!.Credits = value;
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

  Widget buildCreator(BuildContext context) {
    return InkWell(
      onTap: () => Creator.showUserPage(context),
      child: Text(Creator.Name),
    );
  }

  Widget buildDate(BuildContext context) {
    return Text(formatDateTime(CreatedAt));
  }

  Widget buildReply(BuildContext context) {
    return ActionChip(
      onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommentReplyPage(post: this),
          )),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      avatar:
          const Icon(Icons.add_comment_rounded, color: Colors.pink, size: 18),
      label: const Text("Reply"),
    );
  }

  Widget buildReplyCount(BuildContext context) {
    return ActionChip(
      onPressed: openComments(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      avatar: const Icon(Icons.comment, color: Colors.pink, size: 18),
      label: Text(
          CommentCount == 1 ? "$CommentCount Reply" : "$CommentCount Replies"),
    );
  }

  PopupMenuItem buildRemove(BuildContext context, VoidCallback updateState) {
    return PopupMenuItem(
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
  }

  PopupMenuItem buildReadLater(BuildContext context) {
    return PopupMenuItem(
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
      child: const Text("Read Later"),
    );
  }

  PopupMenuItem buildIgnoreUser(BuildContext context) {
    return PopupMenuItem(
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
      child: const Text("Ignore User"),
    );
  }

  PopupMenuItem buildReport(BuildContext context) {
    return PopupMenuItem(
      onTap: () {
        showPlatformDialog(
          context: context,
          builder: (context) => FlagDialog(pid: ID, sid: -1),
        );
      },
      child: const Text("Report"),
    );
  }

  Widget card(BuildContext context, VoidCallback updateState,
      {int? up, int? down}) {
    if (Trashed) {
      return const SizedBox();
    }
    final parser = Parser.basic;
    final urlParser = ParserMapping.url(ParserMapping.defaultMap);

    final firstUrl = urlParser.pattern.firstMatch(Content);
    late String newContent;
    if (firstUrl != null && firstUrl.start == 0) {
      newContent = Content.substring(firstUrl.end);
      sourceUrl = Content.substring(firstUrl.start, firstUrl.end);
    } else {
      newContent = Content;
    }

    final query = MediaQuery.of(context).size;
    final size = <String, dynamic>{"w": query.width, "h": query.height};
    final body = RichText(text: parser.parse(newContent, size));

    final creator = buildCreator(context);
    final date = buildDate(context);
    final meta = Padding(
      padding: EdgeInsets.all(8),
      child: Row(children: [
        creator,
        Expanded(child: Align(alignment: Alignment.centerRight, child: date))
      ]),
    );

    final resolvedTags = Tag.getTags(Tags);
    final tags = Tag.chips(context, resolvedTags);

    final reply = buildReply(context);
    final replyCount = buildReplyCount(context);
    final upvoteButton =
        buildUpvoteButton(context, Upvotes, updateVote(updateState));
    final downvoteButton =
        buildDownvoteButton(context, Downvotes, updateVote(updateState));
    final removePost = buildRemove(context, updateState);
    final removePostList = <PopupMenuItem>[];
    if (Creator.ID == User.current?.ID) {
      removePostList.add(removePost);
    }
    final moreButton = PopupMenuButton(
      itemBuilder: (context) => [
        ...removePostList,
        buildReadLater(context),
        buildIgnoreUser(context),
        buildReport(context),
      ],
    );

    var reviewItems = <Widget>[];
    if (up != null && down != null) {
      final upChip = buildUpvoteChip(context, Upvotes);
      final downChip = buildDownvoteChip(context, Downvotes);
      reviewItems.add(upChip);
      reviewItems.add(downChip);
    }

    final showSimilar = TextButton(
        onPressed: () => openSimilar(context), child: const Text("Similar"));

    final buttonRow = Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          upvoteButton,
          const SizedBox(width: 1),
          downvoteButton,
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
      Padding(
          padding: const EdgeInsets.all(8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: body,
          )),
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
      child: post,
    );

    return Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 4), child: card);
  }

  Widget tile(BuildContext context, VoidCallback updateState,
      {int? up, int? down}) {
    if (Trashed) {
      return const SizedBox();
    }

    final urls = RegexPatterns.url.allMatches(Content);
    final headline = RegexPatterns.h1.firstMatch(Content);
    final lines = Content.split("\n");

    Widget title;
    if (headline != null) {
      title = Text(
        Content.substring(headline.start + 1, headline.end),
        style: const TextStyle(fontSize: 18),
      );
    } else if (lines.isNotEmpty) {
      if (urls != null && urls.isNotEmpty && urls.first.start == 0) {
        title = Text(
          lines[1],
          style: const TextStyle(fontSize: 18),
        );
      } else {
        title = Text(
          lines[0],
          style: const TextStyle(fontSize: 18),
        );
      }
    } else {
      title = const Text("Title"); // FIXME: get first line as title
    }
    const imageWidth = 164.0;
    Widget? image;
    for (final match in urls) {
      final url = Content.substring(match.start, match.end);
      if (url.endsWith(".png") || url.endsWith(".jpg")) {
        // FIXME: handle all image urls
        final img = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          clipBehavior: Clip.antiAlias,
          child: Image.network(url, width: imageWidth, fit: BoxFit.fill),
        );
        image = Padding(padding: const EdgeInsets.all(4), child: img);
        break;
      }
    }
    final date = buildDate(context);
    final creator = buildCreator(context);
    final meta = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(padding: const EdgeInsets.all(8), child: creator),
        Padding(padding: const EdgeInsets.all(8), child: date),
      ],
    );
    final content = Row(
      children: [
        image ?? const SizedBox(),
        Expanded(
            child: Column(
          children: [Padding(padding: EdgeInsets.all(8), child: title), meta],
        )),
      ],
    );

    final reply = buildReply(context);
    final replyCount = buildReplyCount(context);
    final removePost = buildRemove(context, updateState);
    final removePostList = <PopupMenuItem>[];
    if (Creator.ID == User.current?.ID) {
      removePostList.add(removePost);
    }
    final moreButton = PopupMenuButton(
      itemBuilder: (context) => [
        ...removePostList,
        buildReadLater(context),
        buildIgnoreUser(context),
        buildReport(context),
      ],
    );
    final actions = Row(children: [
      reply,
      replyCount,
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: moreButton,
        ),
      ),
    ]);
    final upvoteButton =
        buildUpvoteButton(context, Upvotes, updateVote(updateState));
    final downvoteButton =
        buildDownvoteButton(context, Downvotes, updateVote(updateState));
    final voteBox = SizedBox(
      width: 172,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [upvoteButton, downvoteButton],
        ),
      ),
    );
    final buttonRow = Row(
      children: [
        voteBox,
        reply,
        replyCount,
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: moreButton,
          ),
        )
      ],
    );

    late Widget personal;
    if (up != null && down != null) {
      final upChip = buildUpvoteChip(context, up);
      final downChip = buildDownvoteChip(context, down);
      personal = Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [upChip, downChip],
          ));
    } else {
      personal = const SizedBox();
    }

    return Card(
      child: InkWell(
        onTap: openComments(context),
        child: Column(
          children: [content, buttonRow, personal],
        ),
      ),
    );
  }
}
