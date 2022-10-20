import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/location_picker.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/model/user_pref.dart';
import 'package:social_news_app/posts_page.dart';

class UserPrefPage extends StatefulWidget {
  final bool showSearch;
  final int prefKind;
  final Author user;

  const UserPrefPage(
      {super.key,
      required this.showSearch,
      required this.prefKind,
      required this.user});

  @override
  State<UserPrefPage> createState() => _UserPrefPageState();
}

class _UserPrefPageState extends State<UserPrefPage> {
  late Future<List<UserPrefTag>> tags;
  late Future<List<UserPrefPost>> posts;
  late Future<List<UserPrefUser>> users;
  late Future<List<UserPrefComment>> comments;
  late TextEditingController controller;

  var current = 0;
  var offset = 0;
  var pageSize = 20;
  var location = "";
  var count = 0;
  var startDate = DateTime.now().add(const Duration(days: -7));
  var endDate = DateTime.now();
  var searchString = "";
  var hasMore = true;
  var isLoading = false;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController();
    current = widget.prefKind;

    tags = Future(() => []);
    posts = Future(() => []);
    users = Future(() => []);
    comments = Future(() => []);
    if (current == 0) {
      tags = getNewItems<UserPrefTag>().then(updateItemsState);
    } else if (current == 1) {
      posts = getNewItems<UserPrefPost>().then(updateItemsState);
    } else if (current == 2) {
      users = getNewItems<UserPrefUser>().then(updateItemsState);
    } else if (current == 3) {
      comments = getNewItems<UserPrefComment>().then(updateItemsState);
    }

    offset = pageSize;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  int currentIndex<T>() {
    if (isTypeEqual<T, UserPrefTag>()) {
      return 0;
    } else if (isTypeEqual<T, UserPrefPost>()) {
      return 1;
    } else if (isTypeEqual<T, UserPrefUser>()) {
      return 2;
    } else if (isTypeEqual<T, UserPrefComment>()) {
      return 3;
    } else {
      return 100;
    }
  }

  Future<List<T>> getNewItems<T>() async {
    final idx = currentIndex<T>();
    final sd = widget.showSearch ? null : startDate;
    final ed = widget.showSearch ? null : endDate;
    final loc = getLocationArg();
    final src = getSearchString();
    if (isTypeEqual<T, UserPrefTag>()) {
      return NewSource.getUserPrefTags(
        uid: widget.user.ID,
        offset: offset,
        limit: pageSize,
        order: "createdat", // FIXME: sort by vote date?
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefPost>()) {
      return NewSource.getUserPrefPosts(
        uid: widget.user.ID,
        offset: offset,
        limit: pageSize,
        order: "createdat", // FIXME: sort by vote date?
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefUser>()) {
      return NewSource.getUserPrefUsers(
        uid: widget.user.ID,
        offset: offset,
        limit: pageSize,
        order: "createdat", // FIXME: sort by vote date?
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, UserPrefComment>()) {
      return NewSource.getUserPrefComments(
        uid: widget.user.ID,
        offset: offset,
        limit: pageSize,
        order: "createdat", // FIXME: sort by vote date?
      ) as Future<List<T>>;
    } else {
      return Future(() => <T>[]);
    }
  }

  Future<List<T>> updateItemsState<T>(List<T> value) async {
    count += value.length;
    isLoading = false;
    return value;
  }

  void updateFilter(void Function() f) {
    setState(() {
      f();
      count = 0;
      offset = 0;
      if (current == 0) {
        tags = getNewItems<UserPrefTag>().then(updateItemsState);
      } else if (current == 1) {
        posts = getNewItems<UserPrefPost>().then(updateItemsState);
      } else if (current == 2) {
        users = getNewItems<UserPrefUser>().then(updateItemsState);
      } else if (current == 3) {
        comments = getNewItems<UserPrefComment>().then(updateItemsState);
      }
      offset = pageSize;
    });
  }

  List<String>? getLocationArg() {
    if (location == "") {
      return null;
    } else {
      return location.split(",");
    }
  }

  String? getSearchString() {
    if (searchString == "") {
      return null;
    } else {
      return searchString;
    }
  }

  String getLocationPresentation() {
    if (location == "") {
      return "Everywhere";
    } else {
      final args = location.split(",");
      return args.join(", ");
    }
  }

  Widget buildFilter() {
    final startChip = ActionChip(
      label: Text("From: ${formatDate(startDate)}"),
      onPressed: () async {
        final date = await showDatePicker(
            context: context,
            initialDate: startDate,
            firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
            lastDate: DateTime.now());
        if (date == null) {
          return;
        }
        updateFilter(() {
          startDate = date;
        });
      },
    );
    final endChip = ActionChip(
        label: Text("To: ${formatDate(endDate)}"),
        onPressed: () async {
          final date = await showDatePicker(
              context: context,
              initialDate: endDate,
              firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
              lastDate: DateTime.now());
          if (date == null) {
            return;
          }
          updateFilter(() {
            endDate = date;
          });
        });
    final dateRange = Row(
      children: [
        Expanded(
            child: Align(alignment: Alignment.centerRight, child: startChip)),
        const SizedBox(width: 8),
        Expanded(child: Align(alignment: Alignment.centerLeft, child: endChip)),
      ],
    );

    final area = ActionChip(
      label: Text("Location: ${getLocationPresentation()}"),
      onPressed: () async {
        var loc = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LocationPickerPage(),
            ));
        if (loc == null) {
          return;
        }
        updateFilter(() {
          location = loc;
        });
      },
    );

    final selector = CupertinoSlidingSegmentedControl<int>(
      // padding: const EdgeInsets.all(15),
      children: const {
        0: Text("Tags"),
        1: Text("Posts"),
        2: Text("Users"),
        3: Text("Comments"),
      },
      onValueChanged: (int? index) {
        updateFilter(() => current = index ?? 0);
        controller.text = searchString;
      },
      groupValue: current,
    );

    final searchBox = TextField(
      keyboardType: TextInputType.text,
      maxLines: 1,
      controller: controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Search',
      ),
      onSubmitted: (value) async {
        updateFilter(() {
          searchString = value;
        });
      },
    );

    var filterItems = <Widget>[
      const SizedBox(height: 4),
      selector,
      const SizedBox(height: 4),
    ];

    if (widget.showSearch) {
      filterItems.add(searchBox);
    } else {
      filterItems.addAll([
        dateRange,
        const SizedBox(height: 4),
        area,
      ]);
    }
    filterItems.add(const SizedBox(height: 4));

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: filterItems,
    );

    final filter = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: body,
    );

    return ClipRect(child: filter);
  }

  void _loadMore<T>(Future<List<T>> newItems, Future<List<T>> oldItems) async {
    final newPosts = await newItems;
    var oldPosts = await oldItems;
    offset += newPosts.length;
    if (newPosts.isEmpty) {
      hasMore = false;
    }
    oldPosts.addAll(newPosts);
    setState(() {
      count = oldPosts.length;
      isLoading = false;
    });
    oldItems = Future(() => oldPosts);
  }

  Widget makeList() {
    return ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return const ListTile(title: Text("Test"));
        });
  }

  void updateState() {
    setState(() {});
  }

  Widget buildList<T>(BuildContext context, Future<List<T>> items) {
    return FutureBuilder<List<T>>(
        future: items,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == null || snapshot.data?.isEmpty == true) {
              return const SizedBox();
            }
            return ListView.builder(
                itemCount: count,
                // padding: const EdgeInsets.only(top: 106.0),
                itemBuilder: (context, index) {
                  if (index >= count) {
                    if (isLoading) {
                      return const CircularProgressIndicator();
                    } else if (hasMore) {
                      if (current == 0) {
                        final newItems = getNewItems<UserPrefTag>();
                        _loadMore(newItems, tags);
                      } else if (current == 1) {
                        final newItems = getNewItems<UserPrefPost>();
                        _loadMore(newItems, posts);
                      } else if (current == 2) {
                        final newItems = getNewItems<UserPrefUser>();
                        _loadMore(newItems, users);
                      } else if (current == 3) {
                        final newItems = getNewItems<UserPrefComment>();
                        _loadMore(newItems, comments);
                      }
                      isLoading = true;
                      return const CircularProgressIndicator();
                    } else {
                      return const SizedBox();
                    }
                  }
                  final item = snapshot.data![index];
                  if (current == 0) {
                    final tag = (item as UserPrefTag).tag;
                    final page = Scaffold(
                      appBar: AppBar(title: Text(tag.Name)),
                      body: PostsPage(tags: [tag.ID]),
                    );
                    return ListTile(
                      title: Text(tag.Name),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => page),
                      ),
                    );
                  } else if (current == 1) {
                    return (item as UserPrefPost)
                        .post
                        .card(context, false, updateState);
                  } else if (current == 2) {
                    // FIXME: Show user profile on tap
                    return ListTile(
                        title: Text((item as UserPrefUser).author.Name));
                  } else if (current == 3) {
                    final comment = (item as UserPrefComment).comment;
                    return comment.card(context, false, 0,
                        (c) => c.showParentPost(context)(), updateState);
                  } else {
                    return const SizedBox();
                  }
                });
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return const CircularProgressIndicator();
        });
  }

  @override
  Widget build(BuildContext context) {
    // final filter = buildFilter();
    late final Widget list;
    // final list = makeList();

    if (current == 0) {
      list = buildList(context, tags);
    } else if (current == 1) {
      list = buildList(context, posts);
    } else if (current == 2) {
      list = buildList(context, users);
    } else if (current == 3) {
      list = buildList(context, comments);
    } else {
      list = const SizedBox();
    }

    return list;
  }
}
