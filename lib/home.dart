import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/model/comment_reply.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/posts_page.dart';
import 'package:social_news_app/model/search.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/theme.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  List<Widget> screens = [];
  List<Widget> loadedScreens = [];
  Map<int, bool> hasLoadedScreen = {};
  List<int> loadedIndices = [];

  final GlobalKey<SearchPageState> trendingPageKey = GlobalKey();
  final GlobalKey<SearchPageState> searchPageKey = GlobalKey();

  int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    screens = [
      PostsPage(order: SortOrder.score, forUser: User.current!.ID),
      SearchPage(key: trendingPageKey, hasSearch: false),
      CommentReplyPage(),
      SearchPage(key: searchPageKey, hasSearch: true),
      AccountPage(user: User.current?.toAuthor() ?? Author.fromInt(-1)),
    ];
    for (int i = 0; i < screens.length; i++) {
      hasLoadedScreen[i] = false;
    }
    hasLoadedScreen[0] = true;
    loadedIndices = [0];
    loadedScreens = [screens.first];
  }

  String _viewName(int index) {
    switch (index) {
      case 0:
        return "For You";
      case 1:
        return "Trending";
      case 2:
        return "Create";
      case 3:
        return "Search";
      case 4:
        return "Profile";
      default:
        return "";
    }
  }

  IconData _viewIconData(int index) {
    final isSelected = index == this.tabIndex;
    switch (index) {
      case 0:
        return isSelected ? Icons.favorite : Icons.favorite_border;
      case 1:
        return isSelected ? Icons.auto_graph : Icons.auto_graph_outlined;
      case 2:
        return isSelected
            ? Icons.add_circle_rounded
            : Icons.add_circle_outline_rounded;
      case 3:
        return isSelected ? Icons.search : Icons.search_outlined;
      case 4:
        return isSelected
            ? Icons.account_circle_rounded
            : Icons.account_circle_outlined;
      default:
        return Icons.circle;
    }
  }

  void _selectedTab(int index) {
    if (hasLoadedScreen[index] == false) {
      loadedIndices.add(index);
      hasLoadedScreen[index] = true;
      loadedIndices.sort();
      loadedScreens = loadedIndices.map((e) => screens[e]).toList();
    }

    setState(() {
      tabIndex = index;
    });
  }

  Widget _buildTabBar() {
    var items = List.generate(5, (index) => _buildTabItem(index, _selectedTab));

    var bar = BottomAppBar(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items,
      ),
    );

    return bar;
  }

  Widget _buildTabItem(int index, ValueChanged<int> onPressed) {
    var color = tabIndex == index
        ? MyTheme.current.primaryColor
        : MyTheme.current.primaryColorLight;
    return Expanded(
      child: SizedBox(
        height: 60,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => onPressed(index),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_viewIconData(index), color: color, size: 24),
                  Text(_viewName(index),
                      style: TextStyle(color: color, fontSize: 12)),
                ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [];
    if (tabIndex == 1) {
      final action = IconButton(
        onPressed: () {
          final page = (screens[1] as SearchPage);
          page.shouldShowFilter = !page.shouldShowFilter;
          trendingPageKey.currentState?.setState(() {});
        },
        icon: Icon(Icons.filter, color: MyTheme.current.primaryColor),
      );
      actions.add(action);
    } else if (tabIndex == 2) {
      final action = IconButton(
        onPressed: () {
          final page = (screens[2] as CommentReplyPage);
          final controller = page.controller;
          final text = controller?.text ?? "";
          previewPost(context, text)();
        },
        icon: Icon(Icons.preview, color: MyTheme.current.primaryColor),
      );
      actions.add(action);
    } else if (tabIndex == 3) {
      final action = IconButton(
        onPressed: () {
          final page = (screens[3] as SearchPage);
          page.shouldShowFilter = !page.shouldShowFilter;
          searchPageKey.currentState?.setState(() {});
        },
        icon: Icon(Icons.filter, color: MyTheme.current.primaryColor),
      );
      actions.add(action);
    }

    return MaterialApp(
      theme: MyTheme.current,
      darkTheme: MyTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: MyTheme.current.backgroundColor,
          title: Text(
            _viewName(tabIndex),
            style: TextStyle(color: MyTheme.current.primaryColor),
          ),
          actions: actions,
        ),
        body: IndexedStack(
          index: loadedIndices.indexOf(tabIndex),
          children: loadedScreens,
        ),
        bottomNavigationBar: _buildTabBar(),
      ),
    );
  }
}
