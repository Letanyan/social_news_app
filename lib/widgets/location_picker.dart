import 'package:flutter/material.dart';
import 'package:social_news_app/model/geo.dart';

class LocationCountryPickerPage extends StatefulWidget {
  final String country;
  final String region;
  const LocationCountryPickerPage(
      {super.key, required this.country, required this.region});

  @override
  State<LocationCountryPickerPage> createState() =>
      _LocationCountryPickerPageState();
}

class _LocationCountryPickerPageState extends State<LocationCountryPickerPage> {
  String country = "";
  String region = "";

  @override
  void initState() {
    country = widget.country;
    region = widget.region;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final countries = Geo.current.countryCodes();
    var list = ListView.builder(
        itemCount: countries.length,
        itemBuilder: ((context, index) {
          return RadioListTile(
            secondary: IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded),
              onPressed: () async {
                country = countries[index];
                var loc = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationRegionPickerPage(
                          country: country, region: region),
                    ));
                if (loc == null) {
                  return;
                }
                region = loc;
                setState(() {});
              },
            ),
            title: Text(Geo.current.country(countries[index])),
            value: countries[index],
            groupValue: country,
            onChanged: (v) => setState(() {
              country = v ?? "";
              region = "";
            }),
          );
        }));

    var title = "";
    if (country.isNotEmpty) {
      title += Geo.current.country(country);
    } else {
      title = "Everywhere";
    }
    if (region.isNotEmpty) {
      title += ", ${Geo.current.region(country, region)}";
    }
    var body = Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: list,
    );

    return WillPopScope(
      onWillPop: () async {
        var result = country;
        if (region.isNotEmpty) {
          result += ",$region";
        }
        Navigator.pop(context, result);
        return true;
      },
      child: body,
    );
  }
}

class LocationRegionPickerPage extends StatefulWidget {
  final String country;
  final String region;
  const LocationRegionPickerPage(
      {super.key, required this.country, required this.region});

  @override
  State<LocationRegionPickerPage> createState() =>
      _LocationRegionPickerPageState();
}

class _LocationRegionPickerPageState extends State<LocationRegionPickerPage> {
  String country = "";
  String region = "";

  @override
  void initState() {
    country = widget.country;
    region = widget.region;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final regions = Geo.current.regionCodes(widget.country);
    var list = ListView.builder(
        itemCount: regions.length,
        itemBuilder: ((context, index) {
          return RadioListTile(
            title: Text(Geo.current.region(widget.country, regions[index])),
            value: regions[index],
            groupValue: region,
            onChanged: (v) => setState(() => region = v ?? ""),
          );
        }));

    var body = Scaffold(
      appBar: AppBar(
        title: Text(Geo.current.region(country, region)),
      ),
      body: list,
    );

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, region);
        return true;
      },
      child: body,
    );
  }
}
