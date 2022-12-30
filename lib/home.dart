import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart';
import 'package:social_news_app/account_page.dart';
import 'package:social_news_app/comment_reply.dart';
import 'package:social_news_app/model/helpers.dart';
import 'package:social_news_app/model/iap.dart';
import 'package:social_news_app/model/locale.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int tabIndex = 0;
  bool showingStreakMessage = false;

  late StreamSubscription<List<PurchaseDetails>> subscription;
  late final StreamSubscription<StreakMessage> streakSubscription;
  StreakMessage? streakAmount;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // IAPConnection.instance = TestIAPConnection();
    IAPConnection.instance = !kIsWeb && (Platform.isAndroid || Platform.isIOS)
        ? InAppPurchase.instance
        : TestIAPConnection();
    final purchaseUpdated = IAPConnection.instance.purchaseStream;
    handleCachePurchases();
    subscription = purchaseUpdated.listen((purchaseDetailsList) {
      handlePurchases(purchaseDetailsList);
      handleCachePurchases();
    }, onDone: () {
      subscription.cancel();
    }, onError: (error) {
      print(error);
    });

    WidgetsBinding.instance.addPostFrameCallback((ts) {
      streakSubscription = User.streakMessage.stream.listen((event) {
        setState(() {
          streakAmount = event;
        });
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription.cancel();
    streakSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (User.current != null) {
        if (User.current?.streakUpdate != null) {
          User.current?.streakUpdate?.timeout(
            Duration(seconds: 0),
            onTimeout: () {},
          );
        }
        User.updateStreak();
      }
    }

    super.didChangeAppLifecycleState(state);
  }

  void showStreakAmount() {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        if (streakAmount != null && streakAmount?.current != 0) {
          final amount = streakAmount!.current;
          final nextAmount = streakAmount!.next;
          streakAmount = null;
          // Credits 76
          // Check if multiple pop ups
          showPlatformDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(TRHome.addCreditsTitle(amount)),
                content: Text(TRHome.addCreditsBody(amount, nextAmount)),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(TRGeneral.gotIt),
                  )
                ],
              );
            },
          );
        }
      },
    );
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
                title: TRGeneral.forYou,
                order: SortOrder.score,
                forUser: User.current?.id);

          case 1:
            return SearchPage(title: TRGeneral.trending, isTrending: true);
          case 2:
            return const CommentReplyPage(isEdit: false);
          case 3:
            return SearchPage(title: TRGeneral.search, isTrending: false);
          case 4:
            return AccountPage(
                homeView: this,
                user: User.current?.toAuthor() ?? Author.fromInt(-1),
                title: TRGeneral.settings);
        }
        return const SizedBox();
      },
    );
    showStreakAmount();

    return MaterialApp(
      title: TRGeneral.newSource,
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
