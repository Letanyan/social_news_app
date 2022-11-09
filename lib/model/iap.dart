import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/src/in_app_purchase_platform_addition.dart';
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
    print("Unavailable");
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
  if (credit != null) {
    return await IAPConnection.instance
        .buyConsumable(purchaseParam: purchase, autoConsume: true);
  }
  return false;
}

void handlePurchases(List<PurchaseDetails> purchaseDetailsList) async {
  for (final purchase in purchaseDetailsList) {
    final amount = PurchasableCredit.ids[purchase.productID];
    if (amount != null && purchase.status == PurchaseStatus.purchased) {
      if (User.current != null) {
        // FIXME: verify on server
        final newAmount =
            await NewSource.purchaseCredit(User.current!.ID, amount);
        if (newAmount != null) {
          User.current?.Credits = newAmount;
          IAPConnection.instance.completePurchase(purchase);
        }
      }
    }
  }
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
          serverVerificationData: "server",
          source: "dummy",
        ),
        transactionDate: "${DateTime.now().millisecondsSinceEpoch}",
        status: PurchaseStatus.pending);
    final complete = PurchaseDetails(
        productID: purchaseParam.productDetails.id,
        verificationData: PurchaseVerificationData(
          localVerificationData: "local",
          serverVerificationData: "server",
          source: "dummy",
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
    // TODO: implement getPlatformAddition
    throw UnimplementedError();
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;
  // Stream.value(<PurchaseDetails>[]);

  @override
  Future<void> restorePurchases({String? applicationUserName}) {
    // TODO: implement restorePurchases
    throw UnimplementedError();
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
