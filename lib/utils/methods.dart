import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<dynamic> fetch(String url) async {
  final resp = await http.get(Uri.parse(url));
  final data = resp.body;
  return data;
}

double calculateMultiplier(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  double desktopMultiplier = 0.45;
  double tabletMultiplier = 0.35;

  if (screenWidth >= 1200) {
    return desktopMultiplier;
  } else if (screenWidth >= 1000 && screenWidth < 1200) {
    return desktopMultiplier - ((1200 - screenWidth) / 200) * 0.05;
  } else if (screenWidth >= 600 && screenWidth < 1000) {
    return tabletMultiplier;
  } else {
    double defaultMultiplier = 0.45;
    double multiplier = defaultMultiplier * (screenWidth / 600);
    return multiplier.clamp(0.2, defaultMultiplier);
  }
}
