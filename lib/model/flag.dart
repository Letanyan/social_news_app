import 'package:flutter/material.dart';
import 'package:social_news_app/model/comment.dart';
import 'package:social_news_app/model/locale.dart';
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
    items.add(Text(TRFlag.rationalDescription));
    items.add(
      TextField(
        controller: controller,
        maxLines: null,
        decoration: InputDecoration(labelText: TRFlag.rational),
      ),
    );

    return AlertDialog(
      title: Text(TRFlag.reportContent),
      content: SingleChildScrollView(
        child: Column(children: items),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(TRGeneral.cancel),
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
          child: Text(TRGeneral.report),
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
  bool handled;

  FlaggedPost({
    required this.id,
    required this.content,
    required this.kind,
    required this.reason,
    required this.createdAt,
  }) : handled = false;

  factory FlaggedPost.fromJson(Map<String, dynamic> json) {
    return FlaggedPost(
      id: json["ID"],
      content: Post.fromJson(json["Content"]),
      kind: FlagReason.values[json["Kind"]],
      reason: json["Reason"],
      createdAt: DateTime.parse(json["CreatedAt"]).toLocal(),
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

    final total = Text("${content.flagCount} Reports");
    final report = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.report, updateState),
      child: const Text("Police"),
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
    final block1 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block1, updateState),
      child: const Text("Block 1 Day"),
    );
    final block2 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block2, updateState),
      child: const Text("Block 2 Days"),
    );
    final block7 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block7, updateState),
      child: const Text("Block 1 Week"),
    );
    final block14 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block14, updateState),
      child: const Text("Block 2 Weeks"),
    );
    final block21 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block21, updateState),
      child: const Text("Block 3 Weeks"),
    );
    final block28 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block28, updateState),
      child: const Text("Block 4 Weeks"),
    );
    final perm = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.perm, updateState),
      child: const Text("Permanent"),
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
    final bansRow = SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          block1,
          SizedBox(width: 4),
          block2,
          SizedBox(width: 4),
          block7,
          SizedBox(width: 4),
          block14,
          SizedBox(width: 4),
          block21,
          SizedBox(width: 4),
          block28,
          SizedBox(width: 4),
          perm
        ]),
      ),
    );

    final baseColor = Colors.grey[MyTheme.isDark ? 800 : 200]?.withAlpha(192);
    final result = Card(
      color: handled ? Colors.green : baseColor,
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: body),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(8), child: buttonRow),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(8), child: bansRow),
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
  bool handled;

  FlaggedComment({
    required this.id,
    required this.content,
    required this.kind,
    required this.reason,
    required this.createdAt,
  }) : handled = false;

  factory FlaggedComment.fromJson(Map<String, dynamic> json) {
    return FlaggedComment(
      id: json["ID"],
      content: Comment.fromJson(json["Content"]),
      kind: FlagReason.values[json["Kind"]],
      reason: json["Reason"],
      createdAt: DateTime.parse(json["CreatedAt"]).toLocal(),
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

    final total = Text("${content.flagCount} Reports");
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
    final block1 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block1, updateState),
      child: const Text("Block 1 Day"),
    );
    final block2 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block2, updateState),
      child: const Text("Block 2 Days"),
    );
    final block7 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block7, updateState),
      child: const Text("Block 1 Week"),
    );
    final block14 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block14, updateState),
      child: const Text("Block 2 Weeks"),
    );
    final block21 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block21, updateState),
      child: const Text("Block 3 Weeks"),
    );
    final block28 = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.block28, updateState),
      child: const Text("Block 4 Weeks"),
    );
    final perm = ElevatedButton(
      onPressed: () => handleFlag(context, FlagHandle.perm, updateState),
      child: const Text("Permanent"),
    );

    final buttonRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [total, report, remove, ignore, ignoreAll],
    );
    final bansRow = ListView(
      scrollDirection: Axis.horizontal,
      children: [block1, block2, block7, block14, block21, block28, perm],
    );

    final baseColor = Colors.grey[MyTheme.isDark ? 800 : 200]?.withAlpha(192);
    final result = Card(
      color: handled ? Colors.green : baseColor,
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: body),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(8), child: buttonRow),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(8), child: bansRow),
        ],
      ),
    );

    return result;
  }
}
