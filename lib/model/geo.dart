import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:social_news_app/model/new_source.dart';

class Geo {
  final Map<String, Map<String, String>> regions;
  final Map<String, String> countryMap;
  final List<String> countryNames;
  final String myCountry;
  final String myRegion;

  Geo(this.regions, this.countryMap, this.myCountry, this.myRegion)
      : countryNames = Geo.mapCountryNames(regions, countryMap);

  static Future<Geo> fromFile(String regionPath, String countryPath) async {
    var r = await rootBundle
        .loadString(regionPath)
        .then((value) => jsonDecode(value) as Map);
    var c = await rootBundle
        .loadString(countryPath)
        .then((value) => jsonDecode(value) as Map);
    final mr = r.map((key, value) => MapEntry(
        key as String,
        (value as Map)
            .map((key, value) => MapEntry(key as String, value as String))));
    final mc = c.map((key, value) => MapEntry(key as String, value as String));

    final myLocation = await NewSource.getCurrentLocation();
    final myCountry = myLocation.isNotEmpty ? myLocation[0] : "";
    final myRegion = myLocation.length > 1 ? myLocation[1] : "";

    return Geo(mr, mc, myCountry, myRegion);
  }

  static late Geo current;
  static init() async {
    Geo.current = await Geo.fromFile("assets/geo.json", "assets/cnames.json");
  }

  List<String> countryCodes() {
    var result = regions.keys.toList();
    result.sort((a, b) {
      if (a == myCountry) return -1;
      if (b == myCountry) return 1;
      return country(a).compareTo(country(b));
    });
    return result;
  }

  String country(String code) {
    return countryMap[code] ?? "";
  }

  static List<String> mapCountryNames(
    Map<String, Map<String, String>> regions,
    Map<String, String> map,
  ) {
    var result = <String>[];
    for (final e in regions.keys) {
      final name = map[e];
      if (name != null) {
        result.add(name);
      }
    }
    return result;
  }

  List<String> regionCodes(String country) {
    var result = regions[country]?.keys.toList() ?? [];
    result.sort((a, b) {
      final x = region(country, a);
      final y = region(country, b);
      if (x == myRegion) return -1;
      if (y == myRegion) return 1;
      return x.compareTo(y);
    });
    return result;
  }

  String region(String country, String code) {
    return regions[country]?[code] ?? "";
  }

  List<String> regionNames(String country) {
    return regions[country]?.keys.map((e) => region(country, e)).toList() ?? [];
  }
}
