import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/src/in_app_purchase_platform_addition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_news_app/model/locale.dart';
import 'package:social_news_app/model/new_source.dart';
import 'package:social_news_app/model/user.dart';

enum ProductStatus {
  purchasable,
  purchased,
  pending,
}

class PurchasableCredit {
  static const ids = <String, int>{
    'credit5': 5,
    'credit15': 15,
    'credit30': 30,
    'credit50': 50,
    'credit100': 100,
  };
  static final purchaseViewer = StreamController<bool>.broadcast();

  String get id => details.id;
  String get title => details.title;
  String get description => details.description;
  String get price => details.price;
  ProductStatus status;
  ProductDetails details;

  PurchasableCredit(this.details) : status = ProductStatus.purchasable;
}

Future<List<PurchasableCredit>> loadPurchases() async {
  final iap = IAPConnection.instance;
  if (!await iap.isAvailable()) {
    return [];
  }
  if (!await NewSource.isAvailable().catchError((e) => false)) {
    return [];
  }
  final response =
      await iap.queryProductDetails(PurchasableCredit.ids.keys.toSet());
  if (response.notFoundIDs.isNotEmpty) {
    print(response.notFoundIDs);
    return [];
  }
  final products =
      response.productDetails.map((e) => PurchasableCredit(e)).toList();
  return products;
}

Future<bool> buyCredit(PurchasableCredit product) async {
  final purchase = PurchaseParam(productDetails: product.details);
  final credit = PurchasableCredit.ids[product.id];
  final available = await NewSource.isAvailable().catchError((e) => false);
  if (credit != null && available) {
    return await IAPConnection.instance
        .buyConsumable(purchaseParam: purchase, autoConsume: true);
  }
  return false;
}

void handlePurchases(
    BuildContext? context, List<PurchaseDetails> purchaseDetailsList) async {
  for (final purchase in purchaseDetailsList) {
    final amount = PurchasableCredit.ids[purchase.productID];
    if (purchase.status == PurchaseStatus.canceled) {
      IAPConnection.instance.completePurchase(purchase);
    }
    if (amount != null && purchase.status == PurchaseStatus.purchased) {
      if (User.current != null) {
        final platform = purchase.verificationData.source;
        final verifyKey = purchase.verificationData.serverVerificationData;
        final productId = purchase.productID;
        final oldAmount = User.current?.credits;
        try {
          final newAmount = await NewSource.authenticateIAP(
              platform, User.current!.id, verifyKey, productId);
          if (newAmount != -1 && newAmount != oldAmount) {
            final diff = newAmount - (User.current?.credits ?? 0);
            User.current?.credits = newAmount;
            IAPConnection.instance.completePurchase(purchase);
            PurchasableCredit.purchaseViewer.add(true);
            if (context != null) {
              showPlatformDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(TRHome.addCreditsTitle(diff)),
                    content: Text(TRHome.addCreditsBody(diff, diff)),
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
          }
        } catch (e) {
          cachePurchaseDetails(User.current!.id, purchase);
          print("Failed");
        }
      }
    }
    if (purchase.status != PurchaseStatus.pending) {
      PurchasableCredit.purchaseViewer.add(true);
    }
  }
}

class IAPConnection {
  static InAppPurchase? _instance;
  static set instance(InAppPurchase value) {
    _instance = value;
  }

  static InAppPurchase get instance {
    _instance ??= InAppPurchase.instance;
    return _instance!;
  }
}

void handleCachePurchases(BuildContext? context) async {
  final pref = await SharedPreferences.getInstance();
  final len = pref.getInt("iap:len");
  if (len == null) {
    return;
  }
  var purchases = <UserPurchaseDetails>[];
  for (var i = 0; i < len; i += 1) {
    final purchase = await getCachedPurchaseDetails(i);
    if (User.current != null && User.current?.id == purchase.userId) {
      final oldAmount = User.current?.credits;
      final platform = purchase.details.verificationData.source;
      final verifyKey =
          purchase.details.verificationData.serverVerificationData;
      final productId = purchase.details.productID;
      try {
        final newAmount = await NewSource.authenticateIAP(
            platform, User.current!.id, verifyKey, productId);
        if (newAmount != -1 && newAmount != oldAmount) {
          final diff = newAmount - (User.current?.credits ?? 0);
          User.current?.credits = newAmount;
          PurchasableCredit.purchaseViewer.add(true);
          if (context != null) {
            showPlatformDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(TRHome.addCreditsTitle(diff)),
                  content: Text(TRHome.addCreditsBody(diff, diff)),
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
        }
      } catch (e) {
        PurchasableCredit.purchaseViewer.add(true);
        purchases.add(purchase);
      }
      if (purchase.details.status != PurchaseStatus.pending) {
        PurchasableCredit.purchaseViewer.add(true);
      }
    }
  }
  clearCachePurchaseDetails();
  for (final p in purchases) {
    cachePurchaseDetails(p.userId, p.details);
  }
}

void cachePurchaseDetails(int userId, PurchaseDetails details) async {
  final pref = await SharedPreferences.getInstance();
  final len = pref.getInt("iap:len") ?? 0;
  pref.setInt("iap:user_id:$len", userId);

  pref.setString(
    "iap:source:$len",
    details.verificationData.source,
  );
  pref.setString(
    "iap:server:$len",
    details.verificationData.serverVerificationData,
  );
  pref.setString(
    "iap:local:$len",
    details.verificationData.localVerificationData,
  );

  pref.setString("iap:product_id:$len", details.productID);

  if (details.purchaseID != null) {
    pref.setString("iap:purchase_id:$len", details.purchaseID ?? "");
  }
  if (details.transactionDate != null) {
    pref.setString("iap:transaction_date:$len", details.transactionDate!);
  }

  pref.setInt("iap:len", len + 1);
}

class UserPurchaseDetails {
  final int userId;
  final PurchaseDetails details;

  const UserPurchaseDetails(this.userId, this.details);
}

Future<UserPurchaseDetails> getCachedPurchaseDetails(int index) async {
  final pref = await SharedPreferences.getInstance();
  final userId = pref.getInt("iap:user_id:$index") ?? 0;

  final source = pref.getString("iap:source:$index") ?? "";
  final server = pref.getString("iap:server:$index") ?? "";
  final local = pref.getString("iap:local:$index") ?? "";

  final productId = pref.getString("iap:product_id:$index") ?? "";
  final date = pref.getString("iap:transaction_date:$index");
  final purchaseId = pref.getString("iap:purchase_id:$index");

  final details = PurchaseDetails(
    purchaseID: purchaseId,
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: local,
      serverVerificationData: server,
      source: source,
    ),
    transactionDate: date,
    status: PurchaseStatus.purchased,
  );
  return UserPurchaseDetails(userId, details);
}

void clearCachePurchaseDetails() async {
  final pref = await SharedPreferences.getInstance();
  final len = pref.getInt("iap:len") ?? 0;
  for (int i = 0; i < len; i += 1) {
    pref.remove("iap:user_id:$i");
    pref.remove("iap:source:$i");
    pref.remove("iap:server:$i");
    pref.remove("iap:local:$i");
    pref.remove("iap:transaction_date:$i");

    pref.remove("iap:product_id:$i");
    pref.remove("iap:purchase_id:$i");
  }
  pref.remove("iap:len");
}

class TestIAPConnection implements InAppPurchase {
  var controller = StreamController<List<PurchaseDetails>>();

  @override
  Future<bool> buyConsumable(
      {required PurchaseParam purchaseParam, bool autoConsume = true}) {
    final pending = PurchaseDetails(
        productID: purchaseParam.productDetails.id,
        verificationData: PurchaseVerificationData(
          localVerificationData: "local",
          serverVerificationData:
              "paomfafbchbflobidmidloef.AO-J1OwiqNsoiKp72bKaSxYN5p2BWGJdCvYqNaXjyM3PPJpR2BinkNbAlHB0kUpddnxtcm-vjSGwECxBDxdSqhNkKqRFdoSKxJSmSXDhYqTcPOetjJ2bPXQ",
          source: "google_play",
        ),
        transactionDate: "${DateTime.now().millisecondsSinceEpoch}",
        status: PurchaseStatus.pending);
    final complete = PurchaseDetails(
        productID: purchaseParam.productDetails.id,
        verificationData: PurchaseVerificationData(
          localVerificationData: "local",
          serverVerificationData:
              "paomfafbchbflobidmidloef.AO-J1OwiqNsoiKp72bKaSxYN5p2BWGJdCvYqNaXjyM3PPJpR2BinkNbAlHB0kUpddnxtcm-vjSGwECxBDxdSqhNkKqRFdoSKxJSmSXDhYqTcPOetjJ2bPXQ",
          source: "google_play",
        ),
        transactionDate: "${DateTime.now().millisecondsSinceEpoch}",
        status: PurchaseStatus.purchased);
    controller.add([pending, complete]);
    return Future.value(true);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) {
    return Future.value(false);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    return Future.value();
  }

  @override
  Future<bool> isAvailable() {
    return Future.value(true);
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    return Future.value(ProductDetailsResponse(
      productDetails: [
        ProductDetails(
          id: "credit5",
          title: "5 Credits",
          description: "Purchase 5 Credits",
          price: "\$0.99",
          rawPrice: 0.99,
          currencyCode: "USD",
        ),
        ProductDetails(
          id: "credit15",
          title: "15 Credits",
          description: "Purchase 15 Credits",
          price: "\$1.99",
          rawPrice: 1.99,
          currencyCode: "USD",
        ),
        ProductDetails(
          id: "credit30",
          title: "30 Credits",
          description: "Purchase 30 Credits",
          price: "\$2.99",
          rawPrice: 2.99,
          currencyCode: "USD",
        ),
        ProductDetails(
          id: "credit50",
          title: "50 Credits",
          description: "Purchase 50 Credits",
          price: "\$4.99",
          rawPrice: 4.99,
          currencyCode: "USD",
        ),
        ProductDetails(
          id: "credit100",
          title: "100 Credits",
          description: "Purchase 100 Credits",
          price: "\$8.99",
          rawPrice: 8.99,
          currencyCode: "USD",
        ),
      ],
      notFoundIDs: [],
    ));
  }

  @override
  T getPlatformAddition<T extends InAppPurchasePlatformAddition?>() {
    throw UnimplementedError();
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;
  // Stream.value(<PurchaseDetails>[]);

  @override
  Future<void> restorePurchases({String? applicationUserName}) {
    throw UnimplementedError();
  }
}
