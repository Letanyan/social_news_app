import 'package:flutter/material.dart';
import 'package:social_news_app/model/iap.dart';

class PurchaseCredit extends StatefulWidget {
  const PurchaseCredit({super.key});

  @override
  State<PurchaseCredit> createState() => _PurchaseCreditState();
}

class _PurchaseCreditState extends State<PurchaseCredit> {
  void purchaseCredits() {
    // IAPConnection.instance = TestIAPConnection();
    //       final purchaseUpdated = IAPConnection.instance.purchaseStream;
    // final subscription = purchaseUpdated.listen((purchaseDetailsList) {
    //   handlePurchases(purchaseDetailsList);
    // }, onDone: () {
    //   print("Done");
    // }, onError: (error) {
    //   print(error);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadPurchases(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            return AlertDialog(
              content: const Text("Unable to Connect to Store"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ],
            );
          }
          final items = snapshot.data!
              .map(
                (e) => ListTile(
                  title: Text(e.title),
                  subtitle: Text(e.description),
                  trailing: Text(e.price),
                  onTap: () => buyCredit(e),
                ),
              )
              .toList();

          return AlertDialog(
            title: const Text("Purchase Credits"),
            content: SingleChildScrollView(
              child: Column(children: items),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Close"),
              ),
            ],
          );
        }
        return AlertDialog(
          content: const CircularProgressIndicator(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}
