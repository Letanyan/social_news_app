import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:social_news_app/comments_page.dart';
import 'package:social_news_app/comment_reply.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/parser.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/posts_page.dart';
import 'package:social_news_app/widgets/vote_widget.dart';

class Post {
  final int id;
  final Author creator;
  final String content;
  final List<int> tags;
  final DateTime createdAt;
  final List<String> location;
  int upvotes;
  int downvotes;
  final int commentCount;
  bool trashed;
  double score;
  double cred;
  double rank;

  String? sourceUrl;

  Post({
    required this.id,
    required this.creator,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.location,
    required this.upvotes,
    required this.downvotes,
    required this.commentCount,
    required this.trashed,
    required this.score,
    required this.cred,
    required this.rank,
  }) : sourceUrl = null;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json["ID"],
      creator: Author.fromJson(json["Author"]),
      content: json["Content"],
      tags: List<int>.from(json["Tags"]),
      createdAt: DateTime.parse(json["CreatedAt"]),
      location: List<String>.from(json["Location"]),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
      commentCount: json["CommentCount"],
      trashed: json["Trashed"],
      score: json["Score"],
      cred: json["Cred"],
      rank: json["Rank"],
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
      body: CommentsPage(post: this, scrollComments: true),
    );
    return () {
      if (User.current != null) {
        NewSource.addUserCont(
            uid: User.current!.id, kind: UserContKind.viewed, pid: id);
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => commentsPage),
      );
    };
  }

  void openSimilar(BuildContext context) {
    final postsPage = PostsPage(
        title: "Similar",
        forUser: User.current!.id,
        postId: id,
        order: SortOrder.score);
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
        upvotes += amount;
      } else {
        downvotes += -amount;
      }
      updateState();
      try {
        NewSource.voteForPost(
                postId: id, userId: User.current!.id, amount: amount)
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

  Widget buildCreator(BuildContext context) {
    return InkWell(
      onTap: () => creator.showUserPage(context),
      child: Text(creator.name),
    );
  }

  Widget buildDate(BuildContext context) {
    return Text(formatDateTime(createdAt));
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
      avatar: Icon(Icons.add_comment_rounded, color: MyTheme.primary, size: 18),
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
      avatar: Icon(Icons.comment, color: MyTheme.primary, size: 18),
      label: Text(
          commentCount == 1 ? "$commentCount Reply" : "$commentCount Replies"),
    );
  }

  PopupMenuItem buildRemove(BuildContext context, VoidCallback updateState) {
    return PopupMenuItem(
      onTap: () {
        NewSource.deletePost(id).then((value) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Removed")));
          trashed = true;
          updateState();
          return value;
        });
      },
      child: const Text("Remove"),
    );
  }

  Future<void> readLater() async {
    if (User.current == null) {
      return;
    }
    await NewSource.addUserCont(
      uid: User.current!.id,
      kind: UserContKind.readLater,
      pid: id,
    );
  }

  PopupMenuItem buildReadLater(BuildContext context) {
    return PopupMenuItem(
      onTap: readLater,
      child: const Text("Read Later"),
    );
  }

  Widget buildReadLaterSlide(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => readLater(),
        child: Material(
          color: Colors.blue,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.watch_later_outlined),
              Text(textAlign: TextAlign.center, "Read Later")
            ],
          ),
        ),
      ),
    );
  }

  Future<void> ignoreUser() async {
    if (User.current == null) {
      return;
    }
    await NewSource.addUserCont(
      uid: User.current!.id,
      kind: UserContKind.ignored,
      pid: creator.id,
    );
  }

  PopupMenuItem buildIgnoreUser(BuildContext context) {
    return PopupMenuItem(
      onTap: ignoreUser,
      child: const Text("Ignore User"),
    );
  }

  Widget buildIgnoreUserSlide(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => ignoreUser(),
        child: Material(
          color: Colors.orange,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.block),
              Text(textAlign: TextAlign.center, "Ignore User")
            ],
          ),
        ),
      ),
    );
  }

  void report(BuildContext context) {
    showPlatformDialog(
      context: context,
      builder: (context) => FlagDialog(pid: id, sid: -1),
    );
  }

  PopupMenuItem buildReport(BuildContext context) {
    return PopupMenuItem(
      onTap: () => report(context),
      child: const Text("Report"),
    );
  }

  Widget buildReportSlide(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => report(context),
        child: Material(
          color: Colors.red,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.flag),
              Text(textAlign: TextAlign.center, "Report")
            ],
          ),
        ),
      ),
    );
  }

  Widget card(BuildContext context, VoidCallback updateState,
      {int? up, int? down}) {
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
    if (firstUrl != null && firstUrl.start == 0) {
      newContent = content.substring(firstUrl.end);
      sourceUrl = content.substring(firstUrl.start, firstUrl.end);
    } else {
      newContent = content;
    }

    final query = MediaQuery.of(context).size;
    final size = <String, dynamic>{"w": query.width, "h": query.height};
    final body = RichText(text: parser.parse(newContent, size));

    final creatorField = buildCreator(context);
    final date = buildDate(context);
    final meta = Padding(
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        creatorField,
        Expanded(child: Align(alignment: Alignment.centerRight, child: date))
      ]),
    );

    final resolvedTags = Tag.getTags(tags);
    final tagsRow = Tag.chips(context, resolvedTags);

    final reply = buildReply(context);
    final replyCount = buildReplyCount(context);
    final upvoteButton = buildUpvoteButton(
        context, upvotes, UserVoteKind.post, updateVote(updateState));
    final downvoteButton = buildDownvoteButton(
        context, downvotes, UserVoteKind.post, updateVote(updateState));
    final removePost = buildRemove(context, updateState);
    final removePostList = <PopupMenuItem>[];
    if (creator.id == User.current?.id) {
      removePostList.add(removePost);
    }
    final moreButton = PopupMenuButton(
      child: const Chip(
        avatar: Icon(Icons.arrow_drop_down),
        label: Text("More"),
      ),
      itemBuilder: (context) => [
        ...removePostList,
        buildReadLater(context),
        buildIgnoreUser(context),
        buildReport(context),
      ],
    );

    var reviewItems = <Widget>[];
    if (up != null && down != null) {
      final upChip = buildUpvoteChip(context, upvotes);
      final downChip = buildDownvoteChip(context, downvotes);
      reviewItems.add(upChip);
      reviewItems.add(downChip);
    }

    final showSimilar = TextButton(
        onPressed: () => openSimilar(context), child: const Text("Similar"));

    final buttonRow = SizedBox(
      width: query.width,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 8),
            upvoteButton,
            const SizedBox(width: 1),
            downvoteButton,
            const SizedBox(width: 8),
            reply,
            const SizedBox(width: 1),
            replyCount,
            const SizedBox(width: 8),
            // showSimilar,
            moreButton,
          ],
        ),
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
      tagsRow,
    ];
    if (id != -1) {
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

    final card = Material(
      child: post,
    );

    return card;
  }

  Widget tile(BuildContext context, VoidCallback updateState,
      {int? up, int? down}) {
    if (trashed) {
      return const SizedBox();
    }

    final urls = RegexPatterns.url.allMatches(content);
    final headline = RegexPatterns.h1.firstMatch(content);
    final lines = content.split("\n");

    Widget title;
    if (headline != null) {
      title = Text(
        content.substring(headline.start + 1, headline.end),
        style: const TextStyle(fontSize: 18),
      );
    } else if (lines.isNotEmpty) {
      if (urls.isNotEmpty && urls.first.start == 0) {
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
      final url = content.substring(match.start, match.end);
      if (url.endsWith(".png") || url.endsWith(".jpg")) {
        // FIXME: handle all image urls
        final img = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            url,
            width: imageWidth,
            fit: BoxFit.fill,
            loadingBuilder: (context, child, loadingProgress) {
              final loaded = loadingProgress?.cumulativeBytesLoaded ?? 0;
              final expect = loadingProgress?.expectedTotalBytes ?? 0;
              if (loaded >= expect) {
                return child;
              } else {
                return const SizedBox(
                  width: imageWidth,
                  child: Icon(Icons.image_rounded),
                );
              }
            },
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                width: imageWidth,
                child: Icon(Icons.broken_image_rounded),
              );
            },
          ),
        );
        image = Padding(padding: const EdgeInsets.all(4), child: img);
        break;
      }
    }
    final date = buildDate(context);
    final creatorField = buildCreator(context);
    final meta = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(padding: const EdgeInsets.all(8), child: creatorField),
        Padding(padding: const EdgeInsets.all(8), child: date),
      ],
    );
    final contentBody = Row(
      children: [
        image ?? const SizedBox(),
        Expanded(
            child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(8), child: title),
            meta
          ],
        )),
      ],
    );

    final reply = buildReply(context);
    final replyCount = buildReplyCount(context);
    final removePost = buildRemove(context, updateState);
    final removePostList = <PopupMenuItem>[];
    if (creator.id == User.current?.id) {
      removePostList.add(removePost);
    }
    final upvoteButton = buildUpvoteButton(
        context, upvotes, UserVoteKind.post, updateVote(updateState));
    final downvoteButton = buildDownvoteButton(
        context, downvotes, UserVoteKind.post, updateVote(updateState));
    final voteBox = SizedBox(
      width: 172,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [upvoteButton, downvoteButton],
        ),
      ),
    );
    final buttonRow = SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            voteBox,
            reply,
            replyCount,
          ],
        ),
      ),
    );

    late Widget personal;
    if (up != null && down != null) {
      final upChip = buildUpvoteChip(context, up);
      final downChip = buildDownvoteChip(context, down);
      personal = Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [upChip, downChip],
          ));
    } else {
      personal = const SizedBox();
    }

    final tile = Material(
      child: InkWell(
        onTap: openComments(context),
        child: Column(
          children: [contentBody, buttonRow, personal],
        ),
      ),
    );

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        closeThreshold: 0.1,
        children: [
          buildReportSlide(context),
          buildIgnoreUserSlide(context),
          buildReadLaterSlide(context),
        ],
      ),
      child: tile,
    );
  }
}
