import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/news_agent_page.dart';

class NewsAgent {
  final int id;
  final String name;
  final String origin;
  final DateTime lastUpdated;
  final List<String> subs;
  bool removed;

  NewsAgent({
    required this.id,
    required this.name,
    required this.origin,
    required this.lastUpdated,
    required this.subs,
  }) : removed = false;

  factory NewsAgent.fromJson(Map<String, dynamic> json) {
    return NewsAgent(
      id: json["ID"],
      name: json["Name"],
      origin: json["Origin"],
      lastUpdated: DateTime.parse(json["LastUpdate"]),
      subs: (json['Subs'] as List).map((item) => item as String).toList(),
    );
  }

  PopupMenuItem buildDeleteAgent(
      BuildContext context, void Function(NewsAgent?) updateState) {
    return PopupMenuItem(
      onTap: () {
        showPlatformDialog(
          context: context,
          builder: (context) {
            final confirm = ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                NewSource.deleteAgent(id).then(
                  (value) {
                    removed = true;
                    updateState(null);
                  },
                );
              },
              child: const Text("DELETE"),
            );
            final cancel = TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            );

            return AlertDialog(
              title: const Text("Delete Agent?"),
              content: Text(
                  "Are you sure you want to delete the agent '$name' with origin '$origin'"),
              actions: [cancel, confirm],
            );
          },
        );
      },
      child:
          Row(children: const [Icon(Icons.restore_from_trash), Text("Delete")]),
    );
  }

  static void editAgent(
    BuildContext context,
    NewsAgent? agent,
    void Function(NewsAgent?) updateState,
  ) {
    showPlatformDialog(
        context: context,
        builder: (context) {
          final nameController = TextEditingController();
          final originController = TextEditingController();
          final name = TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Name"),
          );
          final origin = TextField(
            controller: originController,
            decoration: const InputDecoration(hintText: "Origin"),
          );
          if (agent != null) {
            nameController.text = agent.name;
            originController.text = agent.origin;
          }
          final cancel = TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          );
          final save = ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (agent != null) {
                final result = await NewSource.editAgent(
                  agent.id,
                  nameController.text,
                  originController.text,
                );
                updateState(result);
              } else {
                final result = await NewSource.createAgent(
                  nameController.text,
                  originController.text,
                );
                updateState(result);
              }
            },
            child: const Text("Save"),
          );

          return AlertDialog(
            title: Text(agent == null ? "Create New" : "Edit Agent"),
            content: SingleChildScrollView(
              child: Column(
                children: [name, origin],
              ),
            ),
            actions: [cancel, save],
          );
        });
  }

  PopupMenuItem buildUpdateAgent(BuildContext context) {
    return PopupMenuItem(
      onTap: () {
        NewSource.updateAgent(id);
      },
      child: const Text("Update"),
    );
  }

  PopupMenuItem buildEditAgent(
      BuildContext context, void Function(NewsAgent?) updateState) {
    return PopupMenuItem(
      onTap: () {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          editAgent(context, this, updateState);
        });
      },
      child: const Text("Edit"),
    );
  }

  void showSubAgent(BuildContext context) {
    final page = SubNewsAgentPage(aid: id, subs: subs);
    Navigator.push(context, route(builder: (context) => page));
  }

  Widget tile(BuildContext context, void Function(NewsAgent?) updateState) {
    final moreButton = PopupMenuButton(
      itemBuilder: (context) => [
        buildUpdateAgent(context),
        buildEditAgent(context, updateState),
        buildDeleteAgent(context, updateState),
      ],
    );

    return ListTile(
      title: Text(origin),
      subtitle: Text(name),
      trailing: moreButton,
      onTap: () => showSubAgent(context),
    );
  }
}
