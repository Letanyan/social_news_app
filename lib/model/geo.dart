import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class Geo {
  final Map<String, Map<String, String>> regions;
  final Map<String, String> countryMap;
  final List<String> countryNames;

  Geo(this.regions, this.countryMap)
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
    return Geo(mr, mc);
  }

  static late Geo current;
  static init() async {
    Geo.current = await Geo.fromFile("assets/geo.json", "assets/cnames.json");
  }

  List<String> countryCodes() {
    return regions.keys.toList();
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
    return regions[country]?.keys.toList() ?? [];
  }

  String region(String country, String code) {
    return regions[country]?[code] ?? "";
  }

  List<String> regionNames(String country) {
    return regions[country]?.keys.map((e) => region(country, e)).toList() ?? [];
  }
}
