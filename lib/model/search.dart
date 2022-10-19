import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/location_picker.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/tag.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/posts_page.dart';
import 'helpers.dart';

class SearchPage extends StatefulWidget {
  final bool showSearch;

  const SearchPage({super.key, required this.showSearch});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late Future<List<Tag>> tags;
  late Future<List<Post>> posts;
  late Future<List<Author>> users;
  late Future<List<Comment>> comments;
  late TextEditingController controller;

  var current = 0;
  var offset = [0, 0, 0, 0];
  var pageSize = 20;
  var location = ["", "", "", ""];
  var count = [0, 0, 0, 0];
  var startDate = [
    DateTime.now().add(const Duration(days: -7)),
    DateTime.now().add(const Duration(days: -7)),
    DateTime.now().add(const Duration(days: -7)),
    DateTime.now().add(const Duration(days: -7)),
  ];
  var endDate = [
    DateTime.now(),
    DateTime.now(),
    DateTime.now(),
    DateTime.now()
  ];
  var searchString = ["", "", "", ""];
  var hasMore = [true, true, true, true];
  var isLoading = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    print("Created Search ${widget.showSearch}");

    controller = TextEditingController();

    if (widget.showSearch) {
      tags = Future(() => []);
    } else {
      tags = getNewItems<Tag>().then(updateItemsState);
      offset[0] = pageSize;
    }

    posts = Future(() => []);
    users = Future(() => []);
    comments = Future(() => []);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  int currentIndex<T>() {
    if (isTypeEqual<T, Tag>()) {
      return 0;
    } else if (isTypeEqual<T, Post>()) {
      return 1;
    } else if (isTypeEqual<T, Author>()) {
      return 2;
    } else if (isTypeEqual<T, Comment>()) {
      return 3;
    } else {
      return 100;
    }
  }

  Future<List<T>> getNewItems<T>() async {
    final idx = currentIndex<T>();
    final sd = widget.showSearch ? null : startDate[idx];
    final ed = widget.showSearch ? null : endDate[idx];
    final loc = getLocationArg();
    final src = getSearchString();
    if (isTypeEqual<T, Tag>()) {
      return NewSource.getTags(
        offset: offset[idx],
        limit: pageSize,
        order: "upvotes",
        start: sd,
        end: ed,
        location: loc,
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, Post>()) {
      return NewSource.getPosts(
        offset: offset[idx],
        limit: pageSize,
        order: "upvotes",
        start: sd,
        end: ed,
        popularIn: loc,
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, Author>()) {
      return NewSource.getUsers(
        offset: offset[idx],
        limit: pageSize,
        order: "upvotes",
        start: sd,
        end: ed,
        popularIn: loc,
        search: src,
      ) as Future<List<T>>;
    } else if (isTypeEqual<T, Comment>()) {
      return NewSource.getComments(
        offset: offset[idx],
        limit: pageSize,
        order: "upvotes",
        start: sd,
        end: ed,
        popularIn: loc,
        search: src,
      ) as Future<List<T>>;
    } else {
      return Future(() => <T>[]);
    }
  }

  Future<List<T>> updateItemsState<T>(List<T> value) async {
    count[current] += value.length;
    isLoading[current] = false;
    return value;
  }

  void updateFilter(void Function() f) {
    setState(() {
      f();
      count[current] = 0;
      offset[current] = 0;
      if (current == 0) {
        tags = getNewItems<Tag>().then(updateItemsState);
      } else if (current == 1) {
        posts = getNewItems<Post>().then(updateItemsState);
      } else if (current == 2) {
        users = getNewItems<Author>().then(updateItemsState);
      } else if (current == 3) {
        comments = getNewItems<Comment>().then(updateItemsState);
      }
      offset[current] = pageSize;
    });
  }

  List<String>? getLocationArg() {
    if (location[current] == "") {
      return null;
    } else {
      return location[current].split(",");
    }
  }

  String? getSearchString() {
    if (searchString[current] == "") {
      return null;
    } else {
      return searchString[current];
    }
  }

  String getLocationPresentation() {
    if (location[current] == "") {
      return "Everywhere";
    } else {
      final args = location[current].split(",");
      return args.join(", ");
    }
  }

  Widget buildFilter() {
    final startChip = ActionChip(
      label: Text("From: ${formatDate(startDate[current])}"),
      onPressed: () async {
        final date = await showDatePicker(
            context: context,
            initialDate: startDate[current],
            firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
            lastDate: DateTime.now());
        if (date == null) {
          return;
        }
        updateFilter(() {
          startDate[current] = date;
        });
      },
    );
    final endChip = ActionChip(
        label: Text("To: ${formatDate(endDate[current])}"),
        onPressed: () async {
          final date = await showDatePicker(
              context: context,
              initialDate: endDate[current],
              firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
              lastDate: DateTime.now());
          if (date == null) {
            return;
          }
          updateFilter(() {
            endDate[current] = date;
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
          location[current] = loc;
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
        controller.text = searchString[current];
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
          searchString[current] = value;
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
    offset[current] += newPosts.length;
    if (newPosts.isEmpty) {
      hasMore[current] = false;
    }
    oldPosts.addAll(newPosts);
    setState(() {
      count[current] = oldPosts.length;
      isLoading[current] = false;
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

  Widget buildList<T>(BuildContext context, Future<List<T>> items) {
    return FutureBuilder<List<T>>(
        future: items,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == null || snapshot.data?.isEmpty == true) {
              return const SizedBox();
            }
            return ListView.builder(
                itemCount: count[current] + 1,
                padding: const EdgeInsets.only(top: 106.0),
                itemBuilder: (context, index) {
                  if (index >= count[current]) {
                    if (isLoading[current]) {
                      return const CircularProgressIndicator();
                    } else if (hasMore[current]) {
                      if (current == 0) {
                        final newItems = getNewItems<Tag>();
                        _loadMore(newItems, tags);
                      } else if (current == 1) {
                        final newItems = getNewItems<Post>();
                        _loadMore(newItems, posts);
                      } else if (current == 2) {
                        final newItems = getNewItems<Author>();
                        _loadMore(newItems, users);
                      } else if (current == 3) {
                        final newItems = getNewItems<Comment>();
                        _loadMore(newItems, comments);
                      }
                      isLoading[current] = true;
                      return const CircularProgressIndicator();
                    } else {
                      return const SizedBox();
                    }
                  }
                  final item = snapshot.data![index];
                  if (current == 0) {
                    final tag = item as Tag;
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
                    return (item as Post).card(context, false);
                  } else if (current == 2) {
                    // FIXME: Show user profile on tap
                    return ListTile(title: Text((item as Author).Name));
                  } else if (current == 3) {
                    // FIXME: tap should open post (add a static method in the comment.dart)
                    final comment = item as Comment;
                    return comment.card(
                        context, false, 0, (c) => c.showParentPost(context)());
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
    final filter = buildFilter();
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

    return Stack(children: [
      // filter,
      list,
      filter,
    ]);
  }
}
