import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/user.dart';

class CommentReplyPage extends StatefulWidget {
  final Comment? comment;
  final Post? post;
  TextEditingController? controller;
  CommentReplyPage({super.key, this.comment, this.post, this.controller});

  @override
  State<CommentReplyPage> createState() => _CommentReplyPageState();
}

class _CommentReplyPageState extends State<CommentReplyPage> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    widget.controller = controller;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void replyToComment() {
    // TODO: Show progress indicator
    if (widget.comment != null) {
      final result = NewSource.createComment(
              widget.comment!.PostID, widget.comment!.ID, controller.text)
          .then((value) => Navigator.pop(context));
    } else if (widget.post != null) {
      final result =
          NewSource.createComment(widget.post!.ID, 0, controller.text)
              .then((value) => Navigator.pop(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    late Widget preview;
    if (widget.comment != null) {
      preview = widget.comment!.card(context, false, 0, null);
    } else if (widget.post != null) {
      preview = widget.post!.card(context, false);
    } else {
      preview = const SizedBox();
    }

    final input = TextField(
        keyboardType: TextInputType.multiline,
        maxLines: null,
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter a reply',
        ));

    final body = ListView(children: [preview, SizedBox(height: 8), input]);

    late AppBar? bar;
    if (widget.comment == null && widget.post == null) {
      bar = null;
    } else {
      final action = IconButton(
          onPressed: replyToComment, icon: const Icon(Icons.send_rounded));
      bar = AppBar(
        title: const Text("Reply"),
        actions: [action],
      );
    }

    return Scaffold(
      appBar: bar,
      body: body,
    );
  }
}

void Function() previewPost(BuildContext context, String content) {
  return () {
    final previewPost = Post(
      ID: -1,
      Creator: User.current!.toAuthor(),
      Content: content,
      Tags: [],
      CreatedAt: DateTime.now(),
      Location: [],
      Upvotes: 0,
      Downvotes: 0,
    );

    final makePost =
        IconButton(onPressed: () {}, icon: const Icon(Icons.send_rounded));

    final page = Scaffold(
      appBar: AppBar(
        title: const Text("Preview"),
        actions: [makePost],
      ),
      body: ListView(children: [previewPost.card(context, false)]),
    );

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  };
}
