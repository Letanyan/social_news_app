import 'dart:convert';
import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:social_news_app/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Source',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.brown),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('New Source'),
        ),
        body: const LoginPage(),
      ),
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({super.key});

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _biggerFont = const TextStyle(fontSize: 18);
  late Future<List<NewsAgent>> futureAgents;

  Future<List<NewsAgent>> fetchAgents() async {
    final response =
        await http.get(Uri.parse("http://localhost:8080/apih/v1/agents"));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<NewsAgent> result = [];
      for (final item in body["payload"]) {
        result.add(NewsAgent.fromJson(item));
      }
      return result;
    } else {
      throw Exception('Failed to load news agent');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    futureAgents = fetchAgents();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsAgent>>(
      future: futureAgents,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(itemBuilder: (context, i) {
            if (i >= snapshot.data!.length) {
              return const Text("");
            }
            final item = snapshot.data![i];
            return ListTile(
              title: Text(item.name),
              subtitle: Text(
                item.origin,
                style: const TextStyle(fontSize: 15),
              ),
            );
          });
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }

        return const CircularProgressIndicator();
      },
    );
    // return ListView.builder(
    //     padding: const EdgeInsets.all(8.0),
    //     itemBuilder: (context, i) {
    //       if (i.isOdd) return const Divider();

    //       final index = i ~/ 2;
    //       if (index >= _suggestions.length) {
    //         _suggestions.addAll(generateWordPairs().take(10));
    //       }
    //       return ListTile(
    //           title:
    //               Text(_suggestions[index].asPascalCase, style: _biggerFont));
    //     });
  }
}

class NewsAgent {
  final int id;
  final String name;
  final String origin;
  final DateTime lastUpdated;

  const NewsAgent({
    required this.id,
    required this.name,
    required this.origin,
    required this.lastUpdated,
  });

  factory NewsAgent.fromJson(Map<String, dynamic> json) {
    return NewsAgent(
      id: json["ID"],
      name: json["Name"],
      origin: json["Origin"],
      lastUpdated: DateTime.parse(json["LastUpdate"]),
    );
  }
}
