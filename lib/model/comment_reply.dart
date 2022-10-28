import 'package:flutter/cupertino.dart';
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
  bool isReview = false;

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
      final result = NewSource.createComment(widget.comment!.postId,
              widget.comment!.id, controller.text, isReview)
          .then((value) => Navigator.pop(context));
    } else if (widget.post != null) {
      final result =
          NewSource.createComment(widget.post!.ID, 0, controller.text, isReview)
              .then((value) => Navigator.pop(context));
    } else {
      final result = NewSource.createPost(controller.text)
          .then((value) => Navigator.pop(context));
    }
  }

  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    late Widget preview;
    var reviewSelector = <Widget>[];
    if (widget.comment != null) {
      preview =
          widget.comment!.card(context, false, 0, null, updateState, null);
    } else if (widget.post != null) {
      preview = widget.post!.card(context, false, updateState);
      final sel = CupertinoSlidingSegmentedControl(
        children: const {false: Text("Comment"), true: Text("Review")},
        groupValue: isReview,
        onValueChanged: (value) {
          isReview = value ?? false;
          updateState();
        },
      );
      reviewSelector.add(const SizedBox(height: 8));
      reviewSelector.add(Padding(padding: const EdgeInsets.all(8), child: sel));
      reviewSelector.add(const SizedBox(height: 8));
    } else {
      preview = const SizedBox();
    }
    final size = MediaQuery.of(context).size;
    final input = TextField(
        keyboardType: TextInputType.multiline,
        maxLines: null,
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: isReview ? "Review Post" : "Enter a Reply",
        ));

    final body = ListView(
      padding: EdgeInsets.only(bottom: size.height * 0.8),
      children: [
        ...reviewSelector,
        Padding(padding: const EdgeInsets.all(8), child: input),
        const SizedBox(height: 8),
        preview,
      ],
    );

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
      CommentCount: 0,
      Trashed: false,
    );

    final makePost =
        IconButton(onPressed: () {}, icon: const Icon(Icons.send_rounded));

    final page = Scaffold(
      appBar: AppBar(
        title: const Text("Preview"),
        actions: [makePost],
      ),
      body: ListView(children: [previewPost.card(context, false, () {})]),
    );

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  };
}
