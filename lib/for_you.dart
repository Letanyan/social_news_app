import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/tag.dart';

class ForYouPage extends StatefulWidget {
  const ForYouPage({super.key});

  @override
  State<ForYouPage> createState() => _ForYouPageState();
}

class _ForYouPageState extends State<ForYouPage> {
  // late Future<List<Tag>> tags;
  late Future<List<Post>> posts;
  int offset = 0;
  int count = 0;
  int pageSize = 20;
  bool isLoading = true;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    posts =
        NewSource.getPosts(offset: offset, limit: pageSize, order: "createdat")
            .then((value) {
      count += value.length;
      isLoading = false;
      return value;
    });

    // tags = NewSource.getTags(offset: offset, limit: pageSize).then(
    //   (value) {
    //     count += value.length;
    //     isLoading = false;
    //     return value;
    //   },
    // );
    offset = pageSize;
  }

  // void _loadMoreTags() async {
  //   final newTags = await NewSource.getTags(offset: offset, limit: pageSize);
  //   var oldTags = await tags;
  //   offset += newTags.length;
  //   for (final i in newTags) {
  //     print(i);
  //   }
  //   if (newTags.isEmpty) {
  //     hasMore = false;
  //   }
  //   oldTags.addAll(newTags);
  //   tags = Future(() => oldTags);
  //   setState(() {
  //     count = oldTags.length;
  //     isLoading = false;
  //     print("done loading");
  //   });
  // }

  void _loadMorePosts() async {
    final newPosts = await NewSource.getPosts(
        offset: offset, limit: pageSize, order: "createdat");
    var oldPosts = await posts;
    offset += newPosts.length;
    // for (final i in newPosts) {
    //   print(i);
    // }
    if (newPosts.isEmpty) {
      hasMore = false;
    }
    oldPosts.addAll(newPosts);
    posts = Future(() => oldPosts);
    setState(() {
      count = oldPosts.length;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
        future: posts,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == null || snapshot.data?.isEmpty == true) {
              return const SizedBox();
            }
            return ListView.builder(
                itemCount: count + 1,
                itemBuilder: (context, index) {
                  if (index >= count) {
                    if (isLoading) {
                      return const CircularProgressIndicator();
                    } else if (hasMore) {
                      _loadMorePosts();
                      isLoading = true;
                      return const CircularProgressIndicator();
                    } else {
                      return const SizedBox();
                    }
                  }
                  final item = snapshot.data![index];
                  return item.card(context);
                });
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return CircularProgressIndicator();
        });
  }
}
