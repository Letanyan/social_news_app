import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:social_news_app/comments_page.dart';
import 'package:social_news_app/comment_reply.dart';
import 'package:social_news_app/model/flag.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/parser.dart';
import 'package:social_news_app/model/tag.dart';
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
  DateTime edited;
  int flagCount;
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
    required this.flagCount,
    required this.score,
    required this.cred,
    required this.rank,
  })  : sourceUrl = null,
        animated = 0;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: int.parse(json["ID"]),
      creator: Author.fromJson(json["Author"]),
      content: json["Content"],
      tags: List<int>.from(json["Tags"]),
      createdAt: DateTime.parse(json["CreatedAt"]).toLocal(),
      location: List<String>.from(json["Location"]),
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
      commentCount: json["CommentCount"],
      trashed: json["Trashed"],
      edited: DateTime.parse(json["Edited"]).toLocal(),
      flagCount: int.parse(json["FlagCount"]),
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
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(TRPosts.postMarkedRead)));
            markAsRead();
          },
          icon: const Icon(Icons.mark_chat_read),
        ));
      }

      final commentsPage = Scaffold(
        appBar: AppBar(
          title: Text(TRGeneral.comments),
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
        title: TRGeneral.similar,
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
    var words = <InlineSpan>[];
    if (creator.isAgent) {
      words.add(
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.only(left: 4, right: 4),
            child: Icon(
              Icons.smart_toy_outlined,
              size: (theme.bodyText1?.fontSize ?? 12) * 1.25,
            ),
          ),
        ),
      );
    }
    words.addAll([
      TextSpan(
        text: "${creator.name} ",
        style: theme.bodyText1,
      ),
      TextSpan(
        text: "${creator.calculateScore()} ",
        style: const TextStyle(color: Colors.grey),
      ),
      TextSpan(
        text: "(${creator.calculateCred()})",
        style: const TextStyle(color: Colors.grey),
      ),
    ]);
    return InkWell(
      onTap: () => creator.showUserPage(context),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: RichText(
          text: TextSpan(
            children: words,
          ),
        ),
      ),
    );
  }

  Widget buildDate(BuildContext context) {
    if (edited.isAfter(createdAt)) {
      return Text(
          "${TRGeneral.edited.toLowerCase()} ${formatDateTime(edited)}");
    } else {
      return Text(formatDateTime(createdAt));
    }
  }

  PopupMenuItem buildRemove(BuildContext context, VoidCallback updateState) {
    return PopupMenuItem(
      onTap: () {
        trashed = true;
        NewSource.deletePost(id);
        Navigator.of(context).pop();
      },
      child: Text(TRGeneral.remove),
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
            .showSnackBar(SnackBar(content: Text(TRPosts.addedToReadLater)));
        readLater();
      },
      child: Text(TRAccountPage.readLater),
    );
  }

  Widget buildReadLaterSlide(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (context) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(TRPosts.addedToReadLater)));
        readLater();
      },
      backgroundColor: Colors.blue,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.watch_later_outlined),
          Text(TRAccountPage.readLater, textAlign: TextAlign.center)
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(TRPosts.confirmIgnoreUser)));
        ignoreUser();
      },
      child: Text(TRPosts.ignoreUser),
    );
  }

  Widget buildIgnoreUserSlide(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (context) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(TRPosts.confirmIgnoreUser)));
        ignoreUser();
      },
      backgroundColor: Colors.orange,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block),
          Text(TRPosts.ignoreUser, textAlign: TextAlign.center)
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
      child: Text(TRGeneral.report),
    );
  }

  Widget buildReportSlide(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (context) => report(context),
      backgroundColor: Colors.red,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag),
          Text(TRGeneral.report, textAlign: TextAlign.center)
        ],
      ),
    );
  }

  PopupMenuItem buildEdit(BuildContext context, void Function() updateState) {
    return PopupMenuItem(
      value: 3517,
      onTap: () {},
      child: Text(TRGeneral.edit),
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
    if (flagCount >= flagReasonLimit) {
      newContent = TRFlag.flaggedContentMessage;
    } else if (firstUrl != null && firstUrl.start == 0) {
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
      final upChip = buildVoteChip(context, upvotes, true);
      final downChip = buildVoteChip(context, downvotes, false);
      reviewItems.add(upChip);
      reviewItems.add(downChip);
    }

    // final showSimilar = TextButton(
    //     onPressed: () => openSimilar(context), child: const Text("Similar"));

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

    late final card;
    if (flagCount >= flagReasonLimit) {
      card = Material(
        child: InkWell(
          onTap: () {
            flagCount = 0;
            updateState();
          },
          child: particle,
        ),
      );
    } else {
      card = Material(
        child: particle,
      );
    }

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
    if (flagCount >= flagReasonLimit) {
      title = Text(TRFlag.flaggedContentMessage);
    } else if (headline != null) {
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
    final image = FutureBuilder(
      future: Parser.loadableImageWithHeaderRegExps(
        urls,
        content,
        creator.isAgent,
      ),
      builder: (context, snapshot) {
        if (flagCount >= flagReasonLimit) {
          return const SizedBox();
        }
        final canLoad = Parser.loadableImageNoHeaderFromRegExps(
          urls,
          content,
          creator.isAgent,
        );
        if (canLoad == null && (!snapshot.hasData || snapshot.data == null)) {
          return const SizedBox();
        }
        final url = snapshot.data ?? canLoad;
        final clipped = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            url!,
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
        return Padding(padding: const EdgeInsets.all(4), child: clipped);
      },
    );
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
        image,
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
      final upChip = buildVoteChip(context, up, true);
      final downChip = buildVoteChip(context, down, false);
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
