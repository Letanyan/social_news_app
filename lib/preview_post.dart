import 'package:flutter/material.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/parser.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/user.dart';

class PostPreview extends StatefulWidget {
  final String content;
  final bool isEdit;
  final bool isReview;
  final Post? post;
  final Comment? comment;
  const PostPreview(this.content, this.isEdit, this.isReview,
      {super.key, this.post, this.comment});

  @override
  State<PostPreview> createState() => _PostPreviewState();
}

class _PostPreviewState extends State<PostPreview> {
  Post? toBePosted;
  var isLoading = false;
  var controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void replyToComment() {
    setState(() {
      isLoading = true;
    });
    _replyToComment().then((value) => setState(() => isLoading = false));
  }

  Future<void> _replyToComment() async {
    try {
      if (widget.isEdit) {
        if (widget.comment != null) {
          widget.comment?.content = controller.text;
          widget.comment?.edited = DateTime.now();
          await NewSource.updateComment(
            widget.comment!.postId,
            widget.comment!.id,
            controller.text,
          ).then((value) {
            displayString(context, TRPreviewPosts.updatedComment);
            Navigator.pop(context);
          });
        } else if (widget.post != null) {
          int count = 0;
          widget.post?.content = controller.text;
          widget.post?.edited = DateTime.now();
          await NewSource.updatePost(widget.post!.id, controller.text)
              .then((value) {
            displayString(context, TRPreviewPosts.updatedPost);
            Navigator.popUntil(context, (route) => count++ >= 2);
          });
        }
      } else {
        if (widget.comment != null) {
          await NewSource.createComment(
            widget.comment!.postId,
            widget.comment!.id,
            controller.text,
            widget.isReview,
          ).then((value) {
            displayString(context, TRPreviewPosts.commented);
            Navigator.pop(context);
          });
        } else if (widget.post != null) {
          await NewSource.createComment(
                  widget.post!.id, 0, controller.text, widget.isReview)
              .then((value) {
            displayString(context, TRPreviewPosts.commented);
            Navigator.pop(context);
          });
        } else if (toBePosted != null) {
          await NewSource.createPost(toBePosted!.content, false).then((value) {
            displayString(context, TRPreviewPosts.posted);
            Navigator.pop(context, "posted");
          });
        }
      }
    } catch (e) {
      displayError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.now();
    final previewPost = Post(
      id: -1,
      creator: User.current!.toAuthor(),
      content: widget.content,
      tags: [],
      createdAt: currentTime,
      location: [],
      upvotes: 0,
      downvotes: 0,
      commentCount: 0,
      trashed: false,
      edited: currentTime,
      flagCount: 0,
      views: 0,
      score: 0,
      cred: 0,
      rank: 0,
    );
    final progressCircle = Center(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
      ),
    );
    Widget makePost;
    if (isLoading) {
      makePost = progressCircle;
    } else {
      makePost = TextButton(
        onPressed: replyToComment,
        child: Text(TRGeneral.postVerb),
      );
    }

    final trimContent = widget.content.trim();
    final urls = RegexPatterns.url.allMatches(trimContent);
    late Widget preview;
    if (urls.isNotEmpty &&
        urls.first.start == 0 &&
        urls.first.end == trimContent.length) {
      preview = FutureBuilder(
        future: NewSource.createPost(trimContent, true).catchError((e) {
          displayError(context, e);
          return Post.zero();
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
              ],
            );
          }
          if (snapshot.data == null) {
            return ListTile(title: Text(TRGeneral.errorOccurred));
          }
          toBePosted = snapshot.data!;
          return snapshot.data!.card(context, () {});
        },
      );
    } else {
      toBePosted = previewPost;
      preview = previewPost.card(context, () {});
    }

    final page = Scaffold(
      appBar: AppBar(
        title: Text(TRGeneral.preview),
        actions: [makePost],
      ),
      body: ListView(children: [preview]),
    );

    return page;
  }
}
