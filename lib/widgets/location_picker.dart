import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  String location = "";

  @override
  Widget build(BuildContext context) {
    final countries = [
      "South Africa",
      "Germany",
      "Spain",
      "Egypt",
      "Brazil",
    ];
    var list = ListView.builder(
        itemCount: countries.length,
        itemBuilder: ((context, index) {
          return RadioListTile(
            title: Text(countries[index]),
            value: countries[index],
            groupValue: location,
            onChanged: (v) => setState(() => location = v ?? ""),
          );
        }));

    var body = Scaffold(
      appBar: AppBar(
        title: Text("Select Location: $location"),
      ),
      body: list,
    );

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, location);
        return true;
      },
      child: body,
    );
  }
}
