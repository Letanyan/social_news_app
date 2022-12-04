import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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
    with SingleTickerProviderStateMixin {
  int tabIndex = 0;

  late StreamSubscription<List<PurchaseDetails>> subscription;
  late final StreamSubscription<StreakMessage> streakSubscription;
  StreakMessage? streakAmount;

  @override
  void initState() {
    super.initState();

    // IAPConnection.instance = TestIAPConnection();
    IAPConnection.instance = !kIsWeb && (Platform.isAndroid || Platform.isIOS)
        ? InAppPurchase.instance
        : TestIAPConnection();
    final purchaseUpdated = IAPConnection.instance.purchaseStream;
    subscription = purchaseUpdated.listen((purchaseDetailsList) {
      if (purchaseDetailsList.isNotEmpty) {
        print(purchaseDetailsList);
      }
      handlePurchases(purchaseDetailsList);
    }, onDone: () {
      subscription.cancel();
    }, onError: (error) {
      print(error);
    });

    streakSubscription = User.streakMessage.stream.listen((event) {
      setState(() {
        streakAmount = event;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    streakSubscription.cancel();
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
        if (streakAmount != null && streakAmount?.current != 0) {
          final amount = streakAmount!.current;
          final nextAmount = streakAmount!.next;
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            streakAmount = null;
            showPlatformDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(TRHome.addCreditsTitle(amount)),
                content: Text(TRHome.addCreditsBody(amount, nextAmount)),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(TRGeneral.gotIt),
                  )
                ],
              ),
            );
          });
        }
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
