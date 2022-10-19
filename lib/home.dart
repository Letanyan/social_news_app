import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:social_news_app/model/comment_reply.dart';
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

  int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    screens = [
      const PostsPage(order: "createdat"),
      const SearchPage(showSearch: false),
      CommentReplyPage(),
      const SearchPage(showSearch: true),
      const Text("Profile")
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
    switch (index) {
      case 0:
        return Icons.home_filled;
      case 1:
        return Icons.auto_graph;
      case 2:
        return Icons.add_circle_outline_rounded;
      case 3:
        return Icons.search;
      case 4:
        return Icons.account_circle_rounded;
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
    if (tabIndex == 2) {
      final action = IconButton(
        onPressed: () {
          final page = (screens[2] as CommentReplyPage);
          final controller = page.controller;
          final text = controller?.text ?? "";
          previewPost(context, text)();
        },
        icon: const Icon(Icons.preview),
      );
      actions.add(action);
    }

    return MaterialApp(
        theme: MyTheme.current,
        darkTheme: MyTheme.dark,
        themeMode: ThemeMode.system,
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
        ));
  }
}
