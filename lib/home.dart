import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/comment_reply.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/iap.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/posts_page.dart';
import 'package:social_news_app/model/search.dart';
import 'package:social_news_app/model/user.dart';
import 'package:social_news_app/model/theme.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  int tabIndex = 0;

  late StreamSubscription<List<PurchaseDetails>> subscription;

  @override
  void initState() {
    super.initState();

    // IAPConnection.instance = TestIAPConnection();
    IAPConnection.instance = !kIsWeb && (Platform.isAndroid || Platform.isIOS)
        ? InAppPurchase.instance
        : TestIAPConnection();
    final purchaseUpdated = IAPConnection.instance.purchaseStream;
    subscription = purchaseUpdated.listen((purchaseDetailsList) {
      handlePurchases(purchaseDetailsList);
    }, onDone: () {
      subscription.cancel();
    }, onError: (error) {
      print(error);
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: MyTheme.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_rounded),
            activeIcon: Icon(Icons.favorite_rounded),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stacked_line_chart_rounded),
            activeIcon: Icon(Icons.stacked_line_chart_rounded),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            activeIcon: Icon(Icons.add_circle_rounded),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle_rounded),
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return PostsPage(
                title: "For You",
                order: SortOrder.score,
                forUser: User.current?.id);

          case 1:
            return const SearchPage(title: "Trending", isTrending: true);
          case 2:
            return const CommentReplyPage(isEdit: false);
          case 3:
            return const SearchPage(title: "Search", isTrending: false);
          case 4:
            return AccountPage(
                homeView: this,
                user: User.current?.toAuthor() ?? Author.fromInt(-1),
                title: "Settings");
        }
        return const SizedBox();
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
        primarySwatch: MyTheme.primary,
        brightness: MyTheme.isDark ? Brightness.dark : Brightness.light,
      ),
      home: page,
    );
  }
}
