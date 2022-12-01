import 'package:flutter/material.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/posts_page.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/widgets/vote_widget.dart';

class Tag {
  final int id;
  final String name;
  final int upvotes;
  final int downvotes;
  final num score;
  final num cred;
  final num rank;

  const Tag({
    required this.id,
    required this.name,
    required this.upvotes,
    required this.downvotes,
    required this.score,
    required this.cred,
    required this.rank,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json["ID"],
      name: json["Name"],
      upvotes: json["Upvotes"],
      downvotes: json["Downvotes"],
      score: json["Score"],
      cred: json["Cred"],
      rank: json["Rank"],
    );
  }

  factory Tag.zero() {
    return const Tag(
      id: 0,
      name: "",
      upvotes: 0,
      downvotes: 0,
      score: 0,
      cred: 0,
      rank: 0,
    );
  }

  static List<Tag> listFromJson(List<dynamic> json) {
    return json.map((e) => Tag.fromJson(e)).toList();
  }

  Widget chip(BuildContext context) {
    final fullPostPage = PostsPage(title: name, tags: [id]);

    return ActionChip(
      label: Text(name),
      onPressed: () =>
          Navigator.push(context, route(builder: (context) => fullPostPage)),
    );
  }

  static Widget chips(BuildContext context, List<Tag> tags) {
    final xs = tags.map((e) => Container(
          padding: const EdgeInsets.all(2),
          color: Colors.transparent,
          child: e.chip(context),
        ));

    late Widget holder;
    if (xs.isEmpty) {
      holder = const SizedBox();
    } else {
      holder = SizedBox(
        height: 48,
        child:
            ListView(scrollDirection: Axis.horizontal, children: xs.toList()),
      );
    }

    return holder;
  }

  static var stored = <int, Tag>{};
  static List<Tag> getTags(List<int> ids) {
    var result = <Tag>[];
    for (final id in ids) {
      final t = stored[id];
      if (t != null) {
        result.add(t);
      }
    }

    return result;
  }

  static Tag getTag(int id) {
    return stored[id] ?? Tag.zero();
  }

  static Future<List<Tag>> cacheTags(List<int> ids) async {
    var uncached = <int>[];
    for (final id in ids) {
      if (stored[id] == null) {
        uncached.add(id);
      }
    }

    final newTags = await NewSource.getTagsFromIds(uncached);

    for (final tag in newTags) {
      stored[tag.id] = tag;
    }

    return newTags;
  }

  void showTagPage(BuildContext context) {
    final page = PostsPage(title: name, tags: [id]);

    Navigator.push(
      context,
      route(builder: (context) => page),
    );
  }

  Widget card(BuildContext context, Function() updateState,
      {int? up, int? down}) {
    final title = Text(name);
    final upChip = buildUpvoteChip(context, upvotes);
    final downChip = buildDownvoteChip(context, downvotes);
    final votes = FittedBox(
        fit: BoxFit.contain, child: Row(children: [upChip, downChip]));

    return ListTile(
      title: title,
      trailing: Padding(padding: const EdgeInsets.all(8), child: votes),
      onTap: () => showTagPage(context),
    );
  }
}
