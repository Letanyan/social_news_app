import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/model/locale.dart';
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
    late String titleText;
    if (widget.isPromote) {
      switch (widget.kind) {
        case UserVoteKind.post:
          titleText = TRVoteWidget.promotePost;
          break;
        case UserVoteKind.review:
          titleText = TRVoteWidget.promoteReview;
          break;
        case UserVoteKind.comment:
          titleText = TRVoteWidget.promoteComment;
          break;
      }
    } else {
      switch (widget.kind) {
        case UserVoteKind.post:
          titleText = TRVoteWidget.demotePost;
          break;
        case UserVoteKind.review:
          titleText = TRVoteWidget.demoteReview;
          break;
        case UserVoteKind.comment:
          titleText = TRVoteWidget.demoteComment;
          break;
      }
    }

    if (User.current == null || User.current?.validationKey != 0) {
      return AlertDialog(
        title: Text(TRGeneral.signInRequired),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TRGeneral.okay),
          ),
        ],
      );
    }

    final title = Text(titleText);
    final subtitle = Text(
        "${TRVoteWidget.creditsAvailable}: ${User.current!.creditAmount()}");
    final heading = ListTile(title: title, subtitle: subtitle);

    final amountDescription = Text(widget.isPromote
        ? TRVoteWidget.promotionAmount
        : TRVoteWidget.demotionAmount);
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
          child: Text(TRGeneral.cancel),
        ),
        TextButton(
          onPressed: () {
            widget.confirmVote(
              context,
              voteAmount * (widget.isPromote ? 1 : -1),
            );
            Navigator.pop(context);
          },
          child: Text(TRGeneral.confirm),
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
        if ((User.current?.credits ?? 0) <= 0 && !kIsWeb) {
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

Widget buildVoteChip(BuildContext context, int votes, bool isUpvote) {
  final double leftRounding = isUpvote ? 16 : 0;
  final double rightRounding = isUpvote ? 0 : 16;
  return Chip(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(leftRounding),
        bottomLeft: Radius.circular(leftRounding),
        topRight: Radius.circular(rightRounding),
        bottomRight: Radius.circular(rightRounding),
      ),
    ),
    visualDensity: VisualDensity.compact,
    avatar: Icon(
      isUpvote
          ? Icons.keyboard_double_arrow_up_rounded
          : Icons.keyboard_double_arrow_down_rounded,
      color: MyTheme.primary,
      size: 12,
    ),
    labelStyle: const TextStyle(fontSize: 12),
    label: Text("$votes"),
  );
}

Widget buildVoteButton(
  BuildContext context,
  int votes,
  bool isUpvote,
  UserVoteKind kind,
  void Function(BuildContext, int)? confirmVote,
) {
  return InkWell(
    onTap: confirmVote != null
        ? showVoteDialog(context, isUpvote, kind, confirmVote)
        : null,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        Icon(
          size: 16,
          isUpvote
              ? Icons.keyboard_double_arrow_up_rounded
              : Icons.keyboard_double_arrow_down_rounded,
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
        replyCount == 1
            ? " $replyCount ${TRGeneral.reply}"
            : " $replyCount ${TRGeneral.replies}",
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
