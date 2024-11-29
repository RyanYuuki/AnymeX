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
  double minMultiplier = 0.2; // Set a minimum multiplier value

  if (screenWidth >= 1200) {
    return desktopMultiplier;
  } else if (screenWidth >= 1000 && screenWidth < 1200) {
    return desktopMultiplier -
        ((1200 - screenWidth) / 200) * (desktopMultiplier - tabletMultiplier);
  } else if (screenWidth >= 600 && screenWidth < 1000) {
    double transitionMultiplier = tabletMultiplier -
        ((1000 - screenWidth) / 400) * (tabletMultiplier - minMultiplier);
    return transitionMultiplier;
  } else {
    double transitionMultiplier = minMultiplier +
        (screenWidth / 600) * (tabletMultiplier - minMultiplier);
    return transitionMultiplier.clamp(minMultiplier, tabletMultiplier);
  }
}
