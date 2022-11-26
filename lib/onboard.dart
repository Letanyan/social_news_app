import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/email_verification_page.dart';
import 'package:social_news_app/home.dart';
import 'package:social_news_app/model/helpers.dart';
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
    final tags = Wrap(
      direction: Axis.horizontal,
      children: OnboardItems.tags.keys.map((id) {
        return Padding(
          padding: const EdgeInsets.all(4),
          child: FilterChip(
            label: Text(OnboardItems.tags[id]!),
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
    final agents = Wrap(
      direction: Axis.horizontal,
      children: OnboardItems.agents.keys.map((id) {
        return Padding(
          padding: const EdgeInsets.all(4),
          child: FilterChip(
            label: Text(OnboardItems.agents[id]!),
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

    final list = ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Follow Tags",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        tags,
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Follow Sources",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        agents,
      ],
    );

    final done = TextButton(
      style: ButtonStyle(
        foregroundColor: MaterialStatePropertyAll(
          MyTheme.isDark ? MyTheme.primary : Colors.white,
        ),
      ),
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
      child: const Text("Done"),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Getting Started"),
        actions: selectedAgents.isEmpty && selectedTags.isEmpty ? [] : [done],
      ),
      body: list,
    );
  }
}

class OnboardItems {
  static final tags = {
    48: "money",
    103: "crime",
    369: "energy",
    386: "health",
    421: "ufc",
    880: "basketball",
    1391: "travel",
    1499: "cricket",
    2736: "golf",
    2771: "baseball",
    3005: "snooker",
    4138: "boxing",
    4145: "china",
    4219: "tennis",
    5139: "athletics",
    5272: "europe",
    5294: "tv",
    15510: "environment",
    6: "football",
    16008: "family",
    16439: "india",
    18987: "f1",
    22352: "africa",
    28025: "film",
    444: "politics",
    35322: "gaming",
    35386: "world",
    35466: "finance",
    35584: "business",
    35631: "us",
    35840: "tech",
    36032: "uk",
    40895: "americas",
    81: "news",
    65430: "darts",
    73445: "science",
    94249: "rugby",
    94693: "racing",
    97494: "middle-east",
    100039: "weird-news",
    112802: "dieting",
    131571: "celebrity",
    14606: "sport",
    3031: "lifestyle",
    35635: "asia",
    134999: "movies",
    97189: "asia-pacific",
    135857: "sex",
    141693: "weird",
    4832: "technology",
  };

  static final agents = {
    57: "BBC News",
    48: "Mirror",
    58: "CNN US",
    61: "FOX News",
  };
}
