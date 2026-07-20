import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OauthHelper {
  static Future<String?> authenticate({
    required BuildContext context,
    required String url,
    required String callbackUrlScheme,
    bool forceWebAuth = false,
  }) async {
    final supportsWebView = !forceWebAuth &&
        (Platform.isAndroid ||
            Platform.isIOS ||
            Platform.isWindows ||
            Platform.isMacOS);

    if (supportsWebView) {
      try {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => OauthWebViewPage(
              url: url,
              callbackUrlScheme: callbackUrlScheme,
            ),
            fullscreenDialog: true,
          ),
        );
        if (result != null) {
          return result;
        }
      } catch (e) {
        debugPrint('WebView login error: $e');
      }
    }

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: callbackUrlScheme,
      );
      if (result.isNotEmpty) {
        return result;
      }
    } catch (e) {
      debugPrint('FlutterWebAuth2 error: $e');
    }

    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('launchUrlString error: $e');
    }

    return null;
  }
}

class OauthWebViewPage extends StatefulWidget {
  final String url;
  final String callbackUrlScheme;

  const OauthWebViewPage({
    super.key,
    required this.url,
    required this.callbackUrlScheme,
  });

  @override
  State<OauthWebViewPage> createState() => _OauthWebViewPageState();
}

class _OauthWebViewPageState extends State<OauthWebViewPage> {
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          databaseEnabled: true,
          useShouldOverrideUrlLoading: true,
        ),
        onLoadStart: (controller, url) {
          if (url != null) {
            final urlString = url.toString();
            if (urlString.startsWith('${widget.callbackUrlScheme}://') ||
                urlString.contains('code=')) {
              if (!_finished) {
                _finished = true;
                Navigator.pop(context, urlString);
              }
            }
          }
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url;
          if (url != null) {
            final urlString = url.toString();
            if (urlString.startsWith('${widget.callbackUrlScheme}://') ||
                urlString.contains('code=')) {
              if (!_finished) {
                _finished = true;
                Navigator.pop(context, urlString);
              }
              return NavigationActionPolicy.CANCEL;
            }
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
