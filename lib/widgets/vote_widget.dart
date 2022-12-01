import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/widgets/purchase_credit_widget.dart';

class VoteWidget extends StatefulWidget {
  final bool isPromote;
  final UserVoteKind kind;
  final void Function(BuildContext, int) confirmVote;
  const VoteWidget(
      {super.key,
      required this.isPromote,
      required this.kind,
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
    if (newAmount > 0 && newAmount <= User.current!.credits) {
      setState(() => voteAmount += amount);
    }
  }

  void startVoteUpdate(bool isIncrease) {
    voteTimer = Timer.periodic(const Duration(milliseconds: 333), (timer) {
      updateAmount(isIncrease ? 5 : -5);
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
    final content = userVoteKindToString(widget.kind);
    if (User.current == null || User.current?.validationKey != 0) {
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
    final subtitle = Text("Credits Available: ${User.current!.creditAmount()}");
    final heading = ListTile(title: title, subtitle: subtitle);

    final amountDescription = Text("$actionDescription Amount");
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
            amountDescription,
            const SizedBox(height: 8),
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

void Function() showVoteDialog(
  BuildContext context,
  bool isUpvote,
  UserVoteKind kind,
  void Function(BuildContext, int) confirmVote,
) {
  return () {
    showPlatformDialog(
      context: context,
      builder: (context) {
        late final StatefulWidget page;
        if ((User.current?.credits ?? 0) <= 0) {
          page = const PurchaseCredit();
        } else {
          page = VoteWidget(
            isPromote: isUpvote,
            kind: kind,
            confirmVote: confirmVote,
          );
        }
        return page;
      },
    );
  };
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
    avatar: Icon(Icons.back_hand, color: MyTheme.primary, size: 12),
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
    avatar: Icon(Icons.speaker, color: MyTheme.primary, size: 12),
    labelStyle: const TextStyle(fontSize: 12),
    label: Text("$upvotes"),
  );
}

Widget buildVoteButton(
  BuildContext context,
  int votes,
  bool isUpvote,
  UserVoteKind kind,
  void Function(BuildContext, int) confirmVote,
) {
  return InkWell(
    onTap: showVoteDialog(context, isUpvote, kind, confirmVote),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        Icon(
          size: 16,
          isUpvote ? Icons.speaker : Icons.back_hand,
        ),
        Text(" $votes"),
      ]),
    ),
  );
}

Widget buildReplyButton(
    BuildContext context, bool isReplyingTo, void Function() onTap) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(
        size: 16,
        Icons.add_comment_rounded,
        color: isReplyingTo
            ? MyTheme.primary
            : MyTheme.isDark
                ? Colors.white
                : Colors.black,
      ),
    ),
  );
}

Widget buildReplyCountButton(BuildContext context, int replyCount,
    bool highlightedReplies, void Function()? onTap) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
      child: Text(
        replyCount == 1 ? " $replyCount Reply" : " $replyCount Replies",
        style: TextStyle(
            color: highlightedReplies
                ? MyTheme.primary
                : MyTheme.isDark
                    ? Colors.white
                    : Colors.black),
      ),
    ),
  );
}
