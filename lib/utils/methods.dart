import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/main.dart';
import 'package:anymex/utils/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

Future<dynamic> fetch(String url) async {
  final resp = await http.get(Uri.parse(url));
  final data = resp.body;
  return data;
}

double getResponsiveSize(context,
    {required double mobileSize, required double dektopSize}) {
  final currentWidth = MediaQuery.of(context).size.width;
  if (currentWidth > maxMobileWidth) {
    return dektopSize;
  } else {
    return mobileSize;
  }
}

String calcTime(String timestamp, {String format = "dd-MM-yyyy"}) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays <= 14) {
    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        return "${difference.inMinutes} minutes ago";
      }
      return "${difference.inHours} hours ago";
    }
    return "${difference.inDays} days ago";
  }

  return DateFormat(format).format(dateTime);
}

String dateFormatHour(String timestamp) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
  return DateFormat.Hm().format(dateTime);
}

dynamic getResponsiveValue(context,
    {required dynamic mobileValue, required dynamic desktopValue}) {
  final currentWidth = MediaQuery.of(context).size.width;
  if (currentWidth > maxMobileWidth) {
    return desktopValue;
  } else {
    return mobileValue;
  }
}

double calculateMultiplier(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  double desktopMultiplier = 0.45;
  double tabletMultiplier = 0.35;
  double minMultiplier = 0.2;

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

Source? getSource(String lang, String name) {
  try {
    final sourcesList = isar.sources.filter().idIsNotNull().findAllSync();
    return sourcesList.lastWhere(
      (element) =>
          element.name!.toLowerCase() == name.toLowerCase() &&
          element.lang == lang &&
          element.sourceCode != null,
      orElse: () => throw ("Error when getting source"),
    );
  } catch (_) {
    return null;
  }
}
