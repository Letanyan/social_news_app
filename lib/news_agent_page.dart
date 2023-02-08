import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/news_agent.dart';

class NewsAgentPage extends StatefulWidget {
  const NewsAgentPage({
    super.key,
  });

  @override
  State<NewsAgentPage> createState() => _NewsAgentPageState();
}

class _NewsAgentPageState extends State<NewsAgentPage> {
  late Future<List<NewsAgent>> agents;

  bool isLoading = true;
  var count = 0;

  @override
  void initState() {
    super.initState();
    final ctx = WeakReference(context);
    agents = loadAgents().then((value) {
      isLoading = false;
      count = value.length;
      return value;
    }).catchError((e) {
      displayError(ctx.target, e);
      return <NewsAgent>[];
    });
    count = 0;
  }

  Future<List<NewsAgent>> loadAgents() {
    return NewSource.getAgents();
  }

  void updateState() {
    setState(() {});
  }

  Future<void> updateAgentList(NewsAgent agent) async {
    var result = await agents;
    for (var i = 0; i < result.length; i++) {
      if (result[i].id == agent.id) {
        result[i] = agent;
        break;
      }
    }
    agents = Future(() => result);
  }

  @override
  Widget build(BuildContext context) {
    final page = FutureBuilder<List<NewsAgent>>(
      future: agents,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            return const SizedBox();
          }
          final list = ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: count,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return item.tile(context, (a) async {
                if (a != null) {
                  await updateAgentList(a);
                }
                setState(() {});
              });
            },
          );
          return list;
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return const CircularProgressIndicator();
      },
    );

    final createAgent = IconButton(
      onPressed: () {
        NewsAgent.editAgent(context, null, (a) {
          setState(() async {
            if (a != null) {
              var result = await agents;
              result.add(a);
              agents = Future(() => result);
            }
          });
        });
      },
      icon: const Icon(Icons.add),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Agents"),
        actions: [createAgent],
      ),
      body: page,
    );
  }
}

class SubNewsAgentPage extends StatefulWidget {
  final List<String> subs;
  final int aid;
  const SubNewsAgentPage({super.key, required this.aid, required this.subs});

  @override
  State<SubNewsAgentPage> createState() => _SubNewsAgentPageState();
}

class _SubNewsAgentPageState extends State<SubNewsAgentPage> {
  late List<String> subs;
  late int aid;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    subs = widget.subs;
    aid = widget.aid;
  }

  void updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final page = ListView.builder(
      itemCount: subs.length,
      itemBuilder: (context, index) {
        final remove = TextButton(
          onPressed: () {
            showPlatformDialog(
              context: context,
              builder: (context) {
                final cancel = TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                );
                final confirm = ElevatedButton(
                  onPressed: () {
                    final sub = subs[index];
                    subs.removeAt(index);
                    updateState();
                    Navigator.pop(context);
                    final ctx = WeakReference(context);
                    NewSource.editSubAgent(aid, sub, add: false)
                        .catchError((e) {
                      displayError(ctx.target, e);
                      return NewsAgent.zero();
                    });
                  },
                  child: const Text("Remove"),
                );
                return AlertDialog(
                  title: Text("Remove Sub ${subs[index]}"),
                  actions: [cancel, confirm],
                );
              },
            );
          },
          child: const Text("Remove"),
        );

        return ListTile(title: Text(subs[index]), trailing: remove);
      },
    );

    final createAgent = IconButton(
      onPressed: () {
        showPlatformDialog(
            context: context,
            builder: (context) {
              final nameController = TextEditingController();
              final name = TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "Name"),
              );
              final add = ElevatedButton(
                onPressed: () {
                  final sub = nameController.text;
                  subs.add(sub);
                  updateState();
                  Navigator.pop(context);
                  final ctx = WeakReference(context);
                  NewSource.editSubAgent(aid, sub, add: true).catchError((e) {
                    displayError(ctx.target, e);
                    return NewsAgent.zero();
                  });
                },
                child: const Text("Add"),
              );
              final cancel = TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              );

              return AlertDialog(
                title: const Text("Create Sub "),
                content: name,
                actions: [cancel, add],
              );
            });
      },
      icon: const Icon(Icons.add),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Agents"),
        actions: [createAgent],
      ),
      body: page,
    );
  }
}
