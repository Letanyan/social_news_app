import 'package:flutter/material.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/post.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';

class FlagDialog extends StatefulWidget {
  final int pid;
  final int sid;
  const FlagDialog({super.key, required this.pid, required this.sid});

  @override
  State<FlagDialog> createState() => _FlagDialogState();
}

class _FlagDialogState extends State<FlagDialog> {
  FlagReason selectReason = FlagReason.other;

  var controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void updateReason(FlagReason? fr) {
    setState(() {
      selectReason = fr ?? FlagReason.other;
    });
  }

  RadioListTile radioTile(FlagReason fr) {
    return RadioListTile<FlagReason>(
      value: fr,
      groupValue: selectReason,
      onChanged: updateReason,
      title: Text(flagReasonToString(fr)),
    );
  }

  @override
  Widget build(BuildContext context) {
    var items = <Widget>[];
    for (final s in FlagReason.values) {
      items.add(radioTile(s));
    }
    items.add(const Text(
        "Please provide a detailed description of why the content violates the community guidelines"));
    items.add(
      TextField(
        controller: controller,
        maxLines: null,
        decoration: const InputDecoration(labelText: "Rational"),
      ),
    );

    return AlertDialog(
      title: const Text("Report Content"),
      content: SingleChildScrollView(
        child: Column(children: items),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            if (User.current != null) {
              NewSource.createFlag(
                User.current!.id,
                widget.pid,
                widget.sid,
                selectReason,
                controller.text,
              );
            }
            Navigator.pop(context);
          },
          child: const Text("Report"),
        ),
      ],
    );
  }
}

class FlaggedPost {
  final int id;
  final Post content;
  final FlagReason kind;
  final String reason;
  final DateTime createdAt;
  final int count;
  bool handled;

  FlaggedPost({
    required this.id,
    required this.content,
    required this.kind,
    required this.reason,
    required this.createdAt,
    required this.count,
  }) : handled = false;

  factory FlaggedPost.fromJson(Map<String, dynamic> json) {
    return FlaggedPost(
      id: json["ID"],
      content: Post.fromJson(json["Content"]),
      kind: FlagReason.values[json["Kind"]],
      reason: json["Reason"],
      createdAt: DateTime.parse(json["CreatedAt"]),
      count: json["Count"],
    );
  }

  void handleFlag(
      BuildContext context, FlagHandle handle, Function() updateState) {
    NewSource.handleFlag(id, content.id, -1, handle).then((value) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(flagHandleKind(handle))));
      handled = true;
      updateState();
      return value;
    });
  }

  Widget card(BuildContext context, Function() updateState) {
    final body = Text(reason);

    final total = Text("$count Reports");
    final report = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.report, updateState),
      child: const Text("Report"),
    );
    final remove = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.remove, updateState),
      child: const Text("Remove"),
    );
    final ignore = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.ignore, updateState),
      child: const Text("Ignore"),
    );
    final ignoreAll = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.ignoreAll, updateState),
      child: const Text("Ignore All"),
    );

    final buttonRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        total,
        report,
        remove,
        ignore,
        ignoreAll,
      ],
    );

    final baseColor = Colors.grey[MyTheme.isDark ? 800 : 200]?.withAlpha(192);
    final result = Card(
      color: handled ? Colors.green : baseColor,
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: body),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(8), child: buttonRow),
        ],
      ),
    );

    return result;
  }
}

class FlaggedComment {
  final int id;
  final Comment content;
  final FlagReason kind;
  final String reason;
  final DateTime createdAt;
  final int count;
  bool handled;

  FlaggedComment({
    required this.id,
    required this.content,
    required this.kind,
    required this.reason,
    required this.createdAt,
    required this.count,
  }) : handled = false;

  factory FlaggedComment.fromJson(Map<String, dynamic> json) {
    return FlaggedComment(
      id: json["ID"],
      content: Comment.fromJson(json["Content"]),
      kind: FlagReason.values[json["Kind"]],
      reason: json["Reason"],
      createdAt: DateTime.parse(json["CreatedAt"]),
      count: json["Count"],
    );
  }

  void handleFlag(
      BuildContext context, FlagHandle handle, Function() updateState) {
    NewSource.handleFlag(id, content.postId, content.id, handle).then((value) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(flagHandleKind(handle))));
      handled = true;
      updateState();
      return value;
    });
  }

  Widget card(BuildContext context, Function() updateState) {
    final body = Text(reason);

    final total = Text("$count Reports");
    final report = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.report, updateState),
      child: const Text("Report"),
    );
    final remove = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.remove, updateState),
      child: const Text("Remove"),
    );
    final ignore = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.ignore, updateState),
      child: const Text("Ignore Flag"),
    );
    final ignoreAll = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.ignoreAll, updateState),
      child: const Text("Ignore All"),
    );

    final buttonRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [total, report, remove, ignore, ignoreAll],
    );

    final baseColor = Colors.grey[MyTheme.isDark ? 800 : 200]?.withAlpha(192);
    final result = Card(
      color: handled ? Colors.green : baseColor,
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: body),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(8), child: buttonRow),
        ],
      ),
    );

    return result;
  }
}
