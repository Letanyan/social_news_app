import 'dart:math';

import 'package:flutter/cupertino.dart';
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
import 'package:social_news_app/widgets/particle_widget.dart';
import 'package:social_news_app/widgets/vote_widget.dart';

class Post {
  final int id;
  final Author creator;
  String content;
  final List<int> tags;
  final DateTime createdAt;
  final List<String> location;
  int upvotes;
  int downvotes;
  final int commentCount;
  bool trashed;
  bool edited;
  num score;
  num cred;
  num rank;

  String? sourceUrl;
  int animated;

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
    required this.edited,
    required this.score,
    required this.cred,
    required this.rank,
  })  : sourceUrl = null,
        animated = 0;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json["ID"],
      creator: Author.fromJson(json["Author"]),
      content: json["Content"],
      tags: List<int>.from(json["Tags"]),
      createdAt: DateTime.parse(json["CreatedAt"]).toLocal(),
      location: List<String>.from(json["Location"]),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
      commentCount: json["CommentCount"],
      trashed: json["Trashed"],
      edited: json["Edited"],
      score: json["Score"],
      cred: json["Cred"],
      rank: json["Rank"],
    );
  }

  void Function() openComments(
    BuildContext context,
    void Function() updateState,
  ) {
    return () {
      var actions = <Widget>[];
      if (sourceUrl != null) {
        actions.add(IconButton(
          onPressed: () => launchURL(sourceUrl ?? ""),
          icon: const Icon(Icons.open_in_browser_rounded),
        ));
      }
      if (User.current?.readLater.contains(id) ?? false) {
        actions.add(IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Post Marked as Read")));
            markAsRead();
          },
          icon: const Icon(Icons.mark_chat_read),
        ));
      }

      final commentsPage = Scaffold(
        appBar: AppBar(
          title: const Text("Comments"),
          actions: actions,
        ),
        body: CommentsPage(post: this, scrollComments: null),
      );
      if (User.current != null) {
        NewSource.addUserCont(
            uid: User.current!.id, kind: UserContKind.viewed, pid: id);
      }
      Navigator.push(
        context,
        route(
          builder: (context) => commentsPage,
          settings: const RouteSettings(name: "temp"),
        ),
      ).then((value) => updateState());
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
      route(builder: (context) => postsPage),
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
      animated = amount;
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
    final theme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => creator.showUserPage(context),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: RichText(
          text: TextSpan(
            text: "${creator.name} ",
            style: theme.bodyText1,
            children: [
              TextSpan(
                text: "${creator.calculateScore()} ",
                style: const TextStyle(color: Colors.grey),
              ),
              TextSpan(
                text: "(${creator.calculateCred()})",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDate(BuildContext context) {
    return Text(formatDateTime(createdAt) + (edited ? " • edited" : ""));
  }

  PopupMenuItem buildRemove(BuildContext context, VoidCallback updateState) {
    return PopupMenuItem(
      onTap: () {
        trashed = true;
        NewSource.deletePost(id);
        Navigator.of(context).pop();
      },
      child: const Text("Remove"),
    );
  }

  Future<void> markAsRead() async {
    if (User.current == null) {
      return;
    }
    User.current?.readLater.removeWhere((element) => element == id);
    await NewSource.deleteUserCont(
      User.current!.id,
      id,
      UserContKind.readLater,
    );
  }

  Future<void> readLater() async {
    if (User.current == null) {
      return;
    }
    User.current?.readLater.add(id);
    await NewSource.addUserCont(
      uid: User.current!.id,
      kind: UserContKind.readLater,
      pid: id,
    );
  }

  PopupMenuItem buildReadLater(BuildContext context) {
    return PopupMenuItem(
      onTap: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Added to Read Later")));
        readLater();
      },
      child: const Text("Read Later"),
    );
  }

  Widget buildReadLaterSlide(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (context) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Added to Read Later")));
        readLater();
      },
      backgroundColor: Colors.blue,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.watch_later_outlined),
          Text(textAlign: TextAlign.center, "Read Later")
        ],
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
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Posts From This User Will Be Ignored")));
        ignoreUser();
      },
      child: const Text("Ignore User"),
    );
  }

  Widget buildIgnoreUserSlide(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (context) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Posts From This User Will Be Ignored")));
        ignoreUser();
      },
      backgroundColor: Colors.orange,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.block),
          Text(textAlign: TextAlign.center, "Ignore User")
        ],
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
    return CustomSlidableAction(
      onPressed: (context) => report(context),
      backgroundColor: Colors.red,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.flag),
          Text(textAlign: TextAlign.center, "Report")
        ],
      ),
    );
  }

  PopupMenuItem buildEdit(BuildContext context, void Function() updateState) {
    return PopupMenuItem(
      value: 3517,
      onTap: () {},
      child: const Text("Edit"),
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
    final size = <String, dynamic>{
      "w": query.width,
      "h": query.height,
      "img": creator.isAgent
    };
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

    final reply = buildReplyButton(
      context,
      false,
      () => Navigator.push(
        context,
        route(
          builder: (context) => CommentReplyPage(post: this, isEdit: false),
        ),
      ),
    );
    final replyCount =
        buildReplyCountButton(context, commentCount, false, null);
    final upvoteButton = buildVoteButton(
        context, upvotes, true, UserVoteKind.post, updateVote(updateState));
    final downvoteButton = buildVoteButton(
        context, downvotes, false, UserVoteKind.post, updateVote(updateState));
    final removePost = buildRemove(context, updateState);
    final userActionsList = <PopupMenuItem>[];
    if (creator.id == User.current?.id) {
      userActionsList.add(removePost);
      userActionsList.add(buildEdit(context, updateState));
    }
    final moreButton = Padding(
      padding: const EdgeInsets.all(8),
      child: PopupMenuButton(
        child: const Icon(Icons.more_horiz),
        onSelected: (value) {
          if (value == 3517) {
            final page = CommentReplyPage(post: this, isEdit: true);
            Navigator.of(context)
                .push(
                  route(builder: (context) => page),
                )
                .then((value) => updateState());
          }
        },
        itemBuilder: (context) => [
          ...userActionsList,
          buildReadLater(context),
          buildIgnoreUser(context),
          buildReport(context),
        ],
      ),
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

    final voteItems = Row(children: [
      upvoteButton,
      downvoteButton,
    ]);
    final replyItems = Row(
      children: [
        reply,
        replyCount,
      ],
    );

    final buttonRow = SizedBox(
      width: query.width,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: max(query.width, 320),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              voteItems,
              replyItems,
              // showSimilar,
              moreButton,
            ],
          ),
        ),
      ),
    );

    var items = <Widget>[
      Padding(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: body,
        ),
      ),
      const Divider(),
      Padding(padding: const EdgeInsets.all(0), child: meta),
      tagsRow,
    ];
    if (id != -1) {
      items.add(const Divider(thickness: 2));
      items.add(buttonRow);
    }
    if (reviewItems.isNotEmpty) {
      items.add(const Divider(thickness: 2));
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
    items.add(const Divider(thickness: 2));

    final post = Column(
      children: items,
    );

    final particle = ParticleWidget(animated: animated, child: post);
    animated = 0;

    final card = Material(
      child: particle,
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
      if (urls.isNotEmpty && urls.first.start == 0 && lines.length > 1) {
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
      title = Text(content.substring(0, min(30, content.length)));
    }
    if (urls.isNotEmpty && urls.first.start == 0) {
      sourceUrl = content.substring(urls.first.start, urls.first.end);
    }
    const imageWidth = 164.0;
    Widget? image;
    for (final match in urls) {
      final url = content.substring(match.start, match.end);
      if (Parser.canLoadImage(url, creator.isAgent)) {
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
    final meta = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(padding: const EdgeInsets.all(8), child: creatorField),
          Padding(padding: const EdgeInsets.all(8), child: date),
        ],
      ),
    );
    final contentBody = Row(
      children: [
        image ?? const SizedBox(),
        Expanded(
            child: Column(
          children: [Padding(padding: const EdgeInsets.all(8), child: title)],
        )),
      ],
    );

    final reply = buildReplyButton(
      context,
      false,
      () => Navigator.push(
        context,
        route(
          builder: (context) => CommentReplyPage(post: this, isEdit: false),
        ),
      ),
    );
    final replyCount = buildReplyCountButton(
        context, commentCount, false, openComments(context, updateState));
    final removePost = buildRemove(context, updateState);
    final removePostList = <PopupMenuItem>[];
    if (creator.id == User.current?.id) {
      removePostList.add(removePost);
    }
    final upvoteButton = buildVoteButton(
        context, upvotes, true, UserVoteKind.post, updateVote(updateState));
    final downvoteButton = buildVoteButton(
        context, downvotes, false, UserVoteKind.post, updateVote(updateState));
    final buttonRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Row(children: [upvoteButton, downvoteButton]),
        Row(children: [reply, replyCount]),
        Flexible(child: meta),
      ],
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
        onTap: openComments(context, updateState),
        child: Column(
          children: [
            const Divider(),
            contentBody,
            buttonRow,
            personal,
          ],
        ),
      ),
    );

    final animatedTile = ParticleWidget(animated: animated, child: tile);
    animated = 0;

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
      child: animatedTile,
    );
  }
}
