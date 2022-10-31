import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/model/user.dart';

class VoteWidget extends StatefulWidget {
  final bool isPromote;
  final bool isPost;
  final void Function(BuildContext, int) confirmVote;
  const VoteWidget(
      {super.key,
      required this.isPromote,
      required this.isPost,
      required this.confirmVote});

  @override
  State<VoteWidget> createState() => _VoteWidgetState();
}

class _VoteWidgetState extends State<VoteWidget> {
  int voteAmount = 1;
  Timer? voteTimer;

  @override
  void initState() {
    super.initState();
    voteAmount = 1;
    voteTimer = null;
  }

  void updateAmount(int amount) {
    final newAmount = voteAmount + amount;
    if (newAmount > 0 && newAmount <= User.current!.Credits) {
      setState(() => voteAmount += amount);
    }
  }

  void startVoteUpdate(bool isIncrease) {
    voteTimer = Timer.periodic(const Duration(milliseconds: 333), (timer) {
      updateAmount(isIncrease ? 1 : -1);
    });
  }

  void endVoteUpdate() {
    if (voteTimer != null) {
      voteTimer!.cancel();
      voteTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.isPromote ? "Promote" : "Demote";
    final actionDescription = widget.isPromote ? "Promotion" : "Demotion";
    final content = widget.isPost ? "Post" : "Review";
    if (User.current == null || User.current?.ValidationKey != 0) {
      return AlertDialog(
        title: Text("Sign in to $action $content"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Okay"),
          ),
        ],
      );
    }

    final title = Text("$action $content");
    final subtitle = Text("Credits Available: ${User.current!.Credits}");
    final heading = ListTile(title: title, subtitle: subtitle);

    final amountDesciption = Text("$actionDescription Amount");
    final amount = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () => updateAmount(-1),
          onLongPressStart: (details) => startVoteUpdate(false),
          onLongPressEnd: (details) => endVoteUpdate(),
          child: const Icon(Icons.remove_circle_rounded),
        ),
        Text("$voteAmount"),
        GestureDetector(
          onTap: () => updateAmount(1),
          onLongPressStart: (details) => startVoteUpdate(true),
          onLongPressEnd: (details) => endVoteUpdate(),
          child: const Icon(Icons.add_circle_rounded),
        ),
      ],
    );

    return AlertDialog(
      title: heading,
      content: SingleChildScrollView(
        child: Column(
          children: [
            amountDesciption,
            amount,
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            widget.confirmVote(
              context,
              voteAmount * (widget.isPromote ? 1 : -1),
            );
            Navigator.pop(context);
          },
          child: const Text("Confirm"),
        ),
      ],
    );
  }
}

Widget buildDownvoteButton(BuildContext context, int downvotes,
    void Function(BuildContext, int) confirmVote) {
  return ActionChip(
    onPressed: () async {
      showPlatformDialog(
        context: context,
        builder: (context) => VoteWidget(
          isPromote: false,
          isPost: true,
          confirmVote: confirmVote,
        ),
      );
    },
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
    ),
    avatar: const Icon(Icons.back_hand, color: Colors.pink, size: 18),
    label: Text("$downvotes"),
  );
}

Widget buildUpvoteButton(BuildContext context, int upvotes,
    void Function(BuildContext, int) confirmVote) {
  return ActionChip(
    onPressed: () {
      showPlatformDialog(
        context: context,
        builder: (context) => VoteWidget(
          isPromote: true,
          isPost: true,
          confirmVote: confirmVote,
        ),
      );
    },
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
    ),
    avatar: const Icon(Icons.speaker, color: Colors.pink, size: 18),
    label: Text("$upvotes"),
  );
}

Widget buildDownvoteChip(BuildContext context, int downvotes) {
  return Chip(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
    ),
    visualDensity: VisualDensity.compact,
    avatar: const Icon(Icons.back_hand, color: Colors.pink, size: 12),
    labelStyle: const TextStyle(fontSize: 12),
    label: Text("$downvotes"),
  );
}

Widget buildUpvoteChip(BuildContext context, int upvotes) {
  return Chip(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
    ),
    visualDensity: VisualDensity.compact,
    avatar: const Icon(Icons.speaker, color: Colors.pink, size: 12),
    labelStyle: const TextStyle(fontSize: 12),
    label: Text("$upvotes"),
  );
}
