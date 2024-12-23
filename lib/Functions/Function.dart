import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class _RefreshController {
  var activity = <int, bool>{};

  void all() {
    activity.forEach((key, value) {
      activity[key] = true;
    });
  }

  void refreshService(RefreshId group) {
    for (var id in group.ids) {
      activity[id] = true;
    }
  }

  void allButNot(int k) {
    activity.forEach((key, value) {
      if (k == key) return;
      activity[key] = true;
    });
  }

  bool getOrPut(int key, bool initialValue) {
    return activity.putIfAbsent(key, () => initialValue);
  }
}

enum RefreshId {
  Anilist,
  Mal,
  Kitsu;

  List<int> get ids => List.generate(3, (index) => baseId + index);

  int get baseId {
    switch (this) {
      case RefreshId.Anilist:
        return 10;
      case RefreshId.Mal:
        return 20;
      case RefreshId.Kitsu:
        return 30;
    }
  }

  int get animePage => baseId;

  int get mangaPage => baseId + 1;

  int get homePage => baseId + 2;
}

// Manually create an instance of _RefreshController
final Refresh = _RefreshController();

Future<void> snackString(
  String? s, {
  String? clipboard,
}) async {
  var context = navigatorKey.currentContext;

  if (context != null && s != null && s.isNotEmpty) {
    var theme = Theme.of(context).colorScheme;

    try {
      final snackBar = SnackBar(
        content: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          onLongPress: () => copyToClipboard(clipboard ?? s),
          child: Text(
            s,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: theme.onSurface,
            ),
          ),
        ),
        backgroundColor: theme.surface,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 32,
          right: 32,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e, stackTrace) {
      debugPrint('Error showing SnackBar: $e');
      debugPrint(stackTrace.toString());
    }
  } else {
    debugPrint('No valid context or string provided.');
  }
}

void copyToClipboard(String text) {
  var context = navigatorKey.currentContext;
  if (context != null) {
    var theme = Theme.of(context).colorScheme;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: theme.onSurface,
          ),
        ),
        backgroundColor: theme.surface,
        duration: const Duration(milliseconds: 450),
      ),
    );
  }
}

Future<void> openLinkInBrowser(String url) async {
  var uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    debugPrint('Opening $url in your browser!');
  } else {
    debugPrint('Oops! I couldn\'t open $url. Maybe it\'s broken?');
  }
}

void navigateToPage(BuildContext context, Widget page) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}

void shareLink(String link) {
  // Simple implementation for sharing a link
  Clipboard.setData(ClipboardData(text: link));
  var context = navigatorKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard!'),
      ),
    );
  }
}
