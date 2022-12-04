import 'package:flutter/material.dart';
import 'package:social_news_app/email_verification_page.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/theme.dart';
import 'package:social_news_app/model/user.dart';

class Onboard extends StatefulWidget {
  const Onboard({super.key});

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  late Set<int> selectedTags;
  late Set<int> selectedAgents;

  @override
  void initState() {
    selectedTags = <int>{};
    selectedAgents = <int>{};
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tags = FutureBuilder(
      future: NewSource.onboardTags(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [CircularProgressIndicator()],
          );
        }
        if (snapshot.data == null) {
          return const SizedBox();
        }
        var keys = snapshot.data!.keys.toList();
        keys.sort();
        return Wrap(
          direction: Axis.horizontal,
          children: keys.map((name) {
            final id = snapshot.data![name]!;
            return Padding(
              padding: const EdgeInsets.all(4),
              child: FilterChip(
                label: Text(name),
                selected: selectedTags.contains(id),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      selectedTags.add(id);
                    } else {
                      selectedTags.remove(id);
                    }
                  });
                },
              ),
            );
          }).toList(),
        );
      },
    );
    final agents = FutureBuilder(
      future: NewSource.onboardAgents(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [CircularProgressIndicator()],
          );
        }
        if (snapshot.data == null) {
          return const SizedBox();
        }
        var keys = snapshot.data!.keys.toList();
        keys.sort();
        return Wrap(
          direction: Axis.horizontal,
          children: keys.map((name) {
            final id = snapshot.data![name]!;
            return Padding(
              padding: const EdgeInsets.all(4),
              child: FilterChip(
                label: Text(name),
                selected: selectedAgents.contains(id),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      selectedAgents.add(id);
                    } else {
                      selectedAgents.remove(id);
                    }
                  });
                },
              ),
            );
          }).toList(),
        );
      },
    );

    final list = ListView(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            TROnboard.followTags,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        tags,
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            TROnboard.followSources,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        agents,
      ],
    );

    final done = TextButton(
      onPressed: () {
        NewSource.onboardCurrentUser(
          selectedTags.toList(),
          selectedAgents.toList(),
        );
        Navigator.pop(context);
        final page = User.current?.validationKey == 0
            ? const EmailVerificationPage()
            : const HomeView();
        Navigator.push(
          context,
          route(builder: (context) => page),
        );
      },
      child: Text(TRGeneral.done),
    );

    final page = Scaffold(
      appBar: AppBar(
        title: Text(TRGeneral.gettingStarted),
        actions: selectedAgents.isEmpty && selectedTags.isEmpty ? [] : [done],
      ),
      body: list,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: TouchAndMouseScrollBehaviour(),
      theme: ThemeData(
        primarySwatch: MyTheme.primary,
        brightness: MyTheme.isDark ? Brightness.dark : Brightness.light,
      ),
      home: page,
    );
  }
}
