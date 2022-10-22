import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/posts_page.dart';
import 'package:social_news_app/model/new_source.dart';

class Tag {
  final int ID;
  final String Name;
  final double Upvotes;
  final double Downvotes;

  const Tag({
    required this.ID,
    required this.Name,
    required this.Upvotes,
    required this.Downvotes,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      ID: json["ID"],
      Name: json["Name"],
      Upvotes: json["Upvotes"],
      Downvotes: json["Downvotes"],
    );
  }

  static List<Tag> listFromJson(List<dynamic> json) {
    return json.map((e) => Tag.fromJson(e)).toList();
  }

  Widget chip(BuildContext context) {
    final fullPostPage = Scaffold(
      appBar: AppBar(title: Text(Name)),
      body: PostsPage(
        tags: [ID],
      ),
    );

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
          padding: const EdgeInsets.all(8),
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
}
