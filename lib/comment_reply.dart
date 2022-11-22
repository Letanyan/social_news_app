import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';

class CommentReplyPage extends StatefulWidget {
  final Comment? comment;
  final Post? post;
  final bool isEdit;
  const CommentReplyPage(
      {super.key, this.comment, this.post, required this.isEdit});

  @override
  State<CommentReplyPage> createState() => _CommentReplyPageState();
}

class _CommentReplyPageState extends State<CommentReplyPage> {
  late TextEditingController controller;
  late FocusNode focus;
  bool isReview = false;
  late StreamSubscription<bool> keyboardSubscription;
  double bottomOffset = 48;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    focus = FocusNode();
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((visible) {
      bottomOffset = visible ? 0 : 48;
      if (!visible) {
        updateState();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();
    keyboardSubscription.cancel();
    super.dispose();
  }

  void replyToComment() {
    // TODO: Show progress indicator
    try {
      if (widget.isEdit) {
        if (widget.comment != null) {
          Navigator.pop(context);
          widget.comment?.content = controller.text;
          widget.comment?.edited = true;
          NewSource.updateComment(
            widget.comment!.postId,
            widget.comment!.id,
            controller.text,
          );
        } else if (widget.post != null) {
          int count = 0;
          Navigator.popUntil(context, (route) => count++ >= 2);
          widget.post?.content = controller.text;
          widget.post?.edited = true;
          NewSource.updatePost(widget.post!.id, controller.text);
        }
      } else {
        if (widget.comment != null) {
          Navigator.pop(context);
          NewSource.createComment(
            widget.comment!.postId,
            widget.comment!.id,
            controller.text,
            isReview,
          );
        } else if (widget.post != null) {
          Navigator.pop(context);
          NewSource.createComment(
              widget.post!.id, 0, controller.text, isReview);
        } else {
          Navigator.pop(context, "posted");
          NewSource.createPost(controller.text);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void updateState() {
    setState(() {});
  }

  void insertText(String prefix, String suffix) {
    final startPos = controller.selection.base;
    final endPos = controller.selection.extent;
    late final int start;
    late final int end;
    if (endPos.offset < startPos.offset) {
      start = endPos.offset;
      end = startPos.offset;
    } else {
      start = startPos.offset;
      end = endPos.offset;
    }
    final source = controller.text;
    if (start == end) {
      controller.text = source.substring(0, start) +
          prefix +
          suffix +
          source.substring(start);
      final pos = start + prefix.length;
      controller.selection = TextSelection(baseOffset: pos, extentOffset: pos);
      focus.requestFocus();
    } else {
      controller.text = source.substring(0, start) +
          prefix +
          source.substring(start, end) +
          suffix +
          source.substring(end);
      controller.selection = TextSelection(
          baseOffset: start, extentOffset: end + prefix.length + suffix.length);
      focus.requestFocus();
    }

    updateState();
  }

  void prependText(String prefix) {
    final startPos = controller.selection.base;
    final endPos = controller.selection.extent;
    var start = 0;
    if (endPos.offset < startPos.offset) {
      start = endPos.offset;
    } else {
      start = startPos.offset;
    }
    final source = controller.text;
    while (start > 0 && source[start - 1] != '\n') {
      start -= 1;
    }
    controller.text =
        source.substring(0, start) + prefix + source.substring(start);

    controller.selection = TextSelection(
        baseOffset: startPos.offset + 1, extentOffset: endPos.offset + 1);
  }

  @override
  Widget build(BuildContext context) {
    late Widget preview;
    var reviewSelector = <Widget>[];
    final isCreation = widget.post == null && widget.comment == null;
    if (!widget.isEdit) {
      if (widget.comment != null) {
        preview = widget.comment!.card(
            context, false, 0, null, null, updateState, null, false, false);
      } else if (widget.post != null) {
        preview = widget.post!.card(context, updateState);
        final sel = CupertinoSlidingSegmentedControl(
          children: const {false: Text("Comment"), true: Text("Critique")},
          groupValue: isReview,
          onValueChanged: (value) {
            isReview = value ?? false;
            updateState();
          },
        );
        reviewSelector.add(const SizedBox(height: 8));
        reviewSelector
            .add(Padding(padding: const EdgeInsets.all(8), child: sel));
        reviewSelector.add(const SizedBox(height: 8));
      } else {
        preview = const SizedBox();
      }
    } else {
      preview = const SizedBox();
    }
    String hintText = isCreation
        ? "Create Post"
        : isReview
            ? "Critique Post"
            : "Enter a Reply";
    final editingKind = widget.post != null ? "Post" : "Comment";
    if (widget.isEdit) {
      hintText = "Edit $editingKind";
    }
    final input = TextField(
      keyboardType: TextInputType.multiline,
      maxLines: null,
      controller: controller,
      focusNode: focus,
      autofocus: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: hintText,
      ),
    );
    if (widget.isEdit) {
      if (widget.post != null) {
        controller.text = widget.post!.content;
      } else if (widget.comment != null) {
        controller.text = widget.comment!.content;
      }
    }

    final body = ListView(
      children: [
        ...reviewSelector,
        Padding(padding: const EdgeInsets.all(8), child: input),
        const SizedBox(height: 8),
        preview,
      ],
    );

    late AppBar? bar;
    if (widget.isEdit) {
      Widget action;
      if (widget.post != null) {
        action = TextButton(
          onPressed: () {
            final text = controller.text;
            previewPost(context, text)();
          },
          child: const Text("Preview"),
        );
      } else {
        action =
            IconButton(onPressed: replyToComment, icon: const Icon(Icons.edit));
      }
      bar = AppBar(
        title: Text("Edit $editingKind"),
        actions: [action],
      );
    } else if (widget.comment == null && widget.post == null) {
      bar = AppBar(
        title: const Text("Create Post"),
        actions: [
          TextButton(
            onPressed: () {
              final text = controller.text;
              previewPost(context, text)();
            },
            child: const Text("Preview"),
          )
        ],
      );
    } else {
      final action = IconButton(
          onPressed: replyToComment, icon: const Icon(Icons.send_rounded));
      bar = AppBar(
        title: const Text("Reply"),
        actions: [action],
      );
    }

    final formatting = Container(
      color: Colors.grey[MyTheme.isDark ? 800 : 200]?.withAlpha(192),
      child: Row(
        children: [
          TextButton(
            onPressed: () => prependText("!"),
            child: const Icon(Icons.title_rounded),
          ),
          TextButton(
            onPressed: () => insertText("**", "**"),
            child: const Icon(Icons.format_bold_rounded),
          ),
          TextButton(
            onPressed: () => insertText("__", "__"),
            child: const Icon(Icons.format_underline_rounded),
          ),
          TextButton(
            onPressed: () => insertText("~~", "~~"),
            child: const Icon(Icons.format_italic_rounded),
          ),
          TextButton(
            onPressed: () => insertText("--", "--"),
            child: const Icon(Icons.strikethrough_s_rounded),
          ),
        ],
      ),
    );
    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: body),
        Visibility(
          visible: isReview || isCreation,
          child: Column(
            children: [formatting, SizedBox(height: bottomOffset)],
          ),
        ),
      ],
    );

    final keyHandler =
        KeyboardDismissOnTap(dismissOnCapturedTaps: false, child: page);

    return Scaffold(
      appBar: bar,
      body: keyHandler,
    );
  }

  void Function() previewPost(BuildContext context, String content) {
    return () {
      if (User.current == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You must sign in to make a post")));
        return;
      }

      final previewPost = Post(
        id: -1,
        creator: User.current!.toAuthor(),
        content: content,
        tags: [],
        createdAt: DateTime.now(),
        location: [],
        upvotes: 0,
        downvotes: 0,
        commentCount: 0,
        trashed: false,
        edited: false,
        score: 0,
        cred: 0,
        rank: 0,
      );

      final makePost =
          TextButton(onPressed: replyToComment, child: const Text("Post"));

      final page = Scaffold(
        appBar: AppBar(
          title: const Text("Preview"),
          actions: [makePost],
        ),
        body: ListView(children: [previewPost.card(context, () {})]),
      );

      Navigator.push(context, route(builder: (context) => page)).then((value) {
        if (value == "posted") {
          controller.text = "";
        }
      });
    };
  }
}
