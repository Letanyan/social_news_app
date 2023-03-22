import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/preview_post.dart';

class CreatePage extends StatefulWidget {
  final Comment? comment;
  final Post? post;
  final bool isEdit;
  const CreatePage({super.key, this.comment, this.post, required this.isEdit});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  late TextEditingController controller;
  late FocusNode focus;
  bool isReview = false;
  late StreamSubscription<bool> keyboardSubscription;
  Post? toBePosted;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    focus = FocusNode();
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((visible) {
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
          final newContent = controller.text;
          await NewSource.updateComment(
            widget.comment!.postId,
            widget.comment!.id,
            newContent,
          ).then((value) {
            var result = widget.comment;
            result?.content = newContent;
            Navigator.pop(context, result);
          });
        } else if (widget.post != null) {
          int count = 0;
          widget.post?.content = controller.text;
          widget.post?.edited = DateTime.now();
          final newContent = controller.text;
          await NewSource.updatePost(widget.post!.id, newContent).then((value) {
            Navigator.popUntil(context, (route) => count++ >= 2);
          });
        }
      } else {
        if (widget.comment != null) {
          await NewSource.createComment(
            widget.comment!.postId,
            widget.comment!.id,
            controller.text,
            isReview,
          ).then((value) {
            Navigator.pop(context, value);
          });
        } else if (widget.post != null) {
          await NewSource.createComment(
            widget.post!.id,
            0,
            controller.text,
            isReview,
          ).then((value) {
            Navigator.pop(context, value);
          });
        } else if (toBePosted != null) {
          await NewSource.createPost(toBePosted!.content, false).then((value) {
            Navigator.pop(context, "posted");
          });
        }
      }
    } catch (e) {
      displayError(context, e);
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
        preview = widget.comment!.tile(
          context,
          false,
          0,
          null,
          null,
          null,
          updateState,
          null,
          false,
          false,
          false,
        );
      } else if (widget.post != null) {
        preview = widget.post!.card(context, updateState);
        final sel = CupertinoSlidingSegmentedControl(
          children: {
            false: Text(TRGeneral.discussion),
            true: Text(TRGeneral.critique)
          },
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
        ? TRCommentsPage.createPost
        : isReview
            ? TRCommentsPage.critiquePost
            : TRCommentsPage.enterReply;
    if (widget.isEdit) {
      hintText = widget.post != null
          ? TRCommentsPage.editPost
          : TRCommentsPage.editComment;
    }
    final input = TextField(
      keyboardType: TextInputType.multiline,
      maxLines: null,
      controller: controller,
      scrollPhysics: NeverScrollableScrollPhysics(),
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
    final progressCircle = Center(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
      ),
    );
    late AppBar? bar;
    if (widget.isEdit) {
      Widget action;
      if (isLoading) {
        action = progressCircle;
      } else if (widget.post != null) {
        action = TextButton(
          onPressed: () {
            final text = controller.text;
            previewPost(context, text)();
          },
          child: Text(TRGeneral.preview),
        );
      } else {
        action =
            IconButton(onPressed: replyToComment, icon: const Icon(Icons.edit));
      }
      bar = AppBar(
        title: Text(hintText),
        actions: [action],
      );
    } else if (widget.comment == null && widget.post == null) {
      Widget action;
      if (isLoading) {
        action = progressCircle;
      } else {
        action = TextButton(
          onPressed: () {
            final text = controller.text;
            previewPost(context, text)();
          },
          child: Text(TRGeneral.preview),
        );
      }
      bar = AppBar(
        title: Text(TRCommentsPage.createPost),
        actions: [action],
      );
    } else {
      Widget action;
      if (isLoading) {
        action = progressCircle;
      } else {
        action = IconButton(
          onPressed: replyToComment,
          icon: const Icon(Icons.send_rounded),
        );
      }

      bar = AppBar(
        title: Text(TRGeneral.reply),
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
            children: [formatting],
          ),
        ),
      ],
    );

    final keyHandler =
        KeyboardDismissOnTap(dismissOnCapturedTaps: false, child: page);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: bar,
      body: keyHandler,
    );
  }

  void Function() previewPost(BuildContext context, String content) {
    return () {
      if (User.current == null) {
        displayString(context, TRCommentsPage.mustSignIn);
        return;
      }
      Navigator.push(
        context,
        route(
          builder: (context) => PostPreview(
            content,
            widget.isEdit,
            isReview,
          ),
        ),
      ).then((value) {
        if (value == "posted") {
          controller.text = "";
        }
        toBePosted = null;
      });
    };
  }
}
