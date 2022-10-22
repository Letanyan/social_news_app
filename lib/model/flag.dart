import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/user.dart';

class FlagDialog extends StatefulWidget {
  final int pid;
  final int sid;
  const FlagDialog({super.key, required this.pid, required this.sid});

  @override
  State<FlagDialog> createState() => _FlagDialogState();
}

class _FlagDialogState extends State<FlagDialog> {
  String selectReason = "";
  List<String> kinds = [
    "Sexual Content",
    "Violent Content",
    "Hateful Content",
    "Harassing Content",
    "Harmful Content",
    "Abusive Content",
    "Spam",
    "Other",
  ];
  var controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void updateReason(String? s) {
    setState(() {
      selectReason = s ?? "";
    });
  }

  int indexOfKind(String s) {
    int i = 0;
    for (final k in kinds) {
      if (k == s) {
        return i;
      }
      i++;
    }
    return kinds.length;
  }

  RadioListTile radioTile(String s) {
    return RadioListTile<String>(
      value: s,
      groupValue: selectReason,
      onChanged: updateReason,
      title: Text(s),
    );
  }

  @override
  Widget build(BuildContext context) {
    var items = <Widget>[];
    for (final s in kinds) {
      items.add(radioTile(s));
    }
    items.add(const Text(
        "Please provide a detailed description of why the content violates the community guidelines"));
    items.add(
      TextField(
        controller: controller,
        maxLines: null,
        decoration: InputDecoration(labelText: "Rational"),
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
                User.current!.ID,
                widget.pid,
                widget.sid,
                indexOfKind(selectReason),
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
