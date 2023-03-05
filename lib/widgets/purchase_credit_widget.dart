import 'dart:async';

import 'package:flutter/material.dart';
import 'package:social_news_app/model/iap.dart';
import 'package:social_news_app/model/locale.dart';

class PurchaseCredit extends StatefulWidget {
  const PurchaseCredit({super.key});

  @override
  State<PurchaseCredit> createState() => _PurchaseCreditState();
}

class _PurchaseCreditState extends State<PurchaseCredit> {
  String selectedPurchase = "";
  late StreamSubscription<bool> purchaseViewer;

  @override
  void initState() {
    purchaseViewer = PurchasableCredit.purchaseViewer.stream.listen((event) {
      setState(() {
        selectedPurchase = "";
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadPurchases(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == null || snapshot.data?.isEmpty == true) {
            return AlertDialog(
              content: Text(TRPurchaseCredit.unableToConnect),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(TRGeneral.cancel),
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
                  leading: selectedPurchase == e.id
                      ? CircularProgressIndicator()
                      : null,
                  onTap: () {
                    setState(() {
                      selectedPurchase = e.id;
                    });
                    buyCredit(e);
                  },
                ),
              )
              .toList();

          return AlertDialog(
            title: Text(TRPurchaseCredit.purchaseCredits),
            content: SingleChildScrollView(
              child: Column(children: items),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(TRGeneral.close),
              ),
            ],
          );
        }
        return AlertDialog(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [CircularProgressIndicator()],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(TRGeneral.cancel),
            ),
          ],
        );
      },
    );
  }
}
