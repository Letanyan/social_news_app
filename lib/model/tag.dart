import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/posts_page.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/widgets/vote_widget.dart';

class Tag {
  final int ID;
  final String Name;
  final int Upvotes;
  final int Downvotes;
  final double Score;
  final double Cred;
  final double Rank;

  const Tag({
    required this.ID,
    required this.Name,
    required this.Upvotes,
    required this.Downvotes,
    required this.Score,
    required this.Cred,
    required this.Rank,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      ID: json["ID"],
      Name: json["Name"],
      Upvotes: json["Upvotes"],
      Downvotes: json["Downvotes"],
      Score: json["Score"],
      Cred: json["Cred"],
      Rank: json["Rank"],
    );
  }

  static List<Tag> listFromJson(List<dynamic> json) {
    return json.map((e) => Tag.fromJson(e)).toList();
  }

  Widget chip(BuildContext context) {
    final fullPostPage = PostsPage(title: Name, tags: [ID]);

    return ActionChip(
      label: Text(Name),
      onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => fullPostPage,
          )),
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
      holder = Container(
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

  static Future<List<Tag>> cacheTags(List<int> ids) async {
    var uncached = <int>[];
    for (final id in ids) {
      if (stored[id] == null) {
        uncached.add(id);
      }
    }

    final newTags = await NewSource.getTagsFromIds(uncached);

    for (final tag in newTags) {
      stored[tag.ID] = tag;
    }

    return newTags;
  }

  void showTagPage(BuildContext context) {
    final page = PostsPage(title: Name, tags: [ID]);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget card(BuildContext context, Function() updateState,
      {int? up, int? down}) {
    final title = Text(Name);
    final upChip = buildUpvoteChip(context, Upvotes);
    final downChip = buildDownvoteChip(context, Downvotes);
    final votes = FittedBox(
        fit: BoxFit.contain, child: Row(children: [upChip, downChip]));

    return ListTile(
      title: title,
      trailing: Padding(padding: const EdgeInsets.all(8), child: votes),
      onTap: () => showTagPage(context),
    );
  }
}
