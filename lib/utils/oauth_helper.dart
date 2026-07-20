import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';

class OauthHelper {
  static Future<String?> authenticate({
    required BuildContext context,
    required String url,
    required String callbackUrlScheme,
    bool forceWebAuth = false,
  }) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AnymexSheet(
          title: 'Select Sign In Method',
          showDragHandle: true,
          contentWidget: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnymexText(
                text: 'Choose how you would like to sign in:',
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.web_rounded, color: theme.colorScheme.primary),
                ),
                title: const Text('Internal Webview', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Sign in inside the app using built-in web browser'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(ctx, 'webview'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.open_in_browser_rounded, color: theme.colorScheme.primary),
                ),
                title: const Text('Login with Browser', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Open system browser and paste authorization code'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(ctx, 'browser'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (method == null) return null;

    if (method == 'webview') {
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
      return null;
    } else {
      return await _fallbackAuthenticate(context, url, callbackUrlScheme);
    }
  }

  static Future<String?> _fallbackAuthenticate(
    BuildContext context,
    String url,
    String callbackUrlScheme,
  ) async {
    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (_) {}

    final textController = TextEditingController();
    final theme = Theme.of(context);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnymexSheet(
        title: 'Authorize App',
        showDragHandle: true,
        contentWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnymexText(
              text: '1. A browser window has been opened for you to sign in and authorize the app.\n\n'
                  '2. Once authorized, you will be redirected to a page that might show a blank screen or a connection error.\n\n'
                  '3. Copy the entire URL of that page from your browser\'s address bar (or just the code) and paste it below:',
              size: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Paste code or redirect URL here...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
              maxLines: 1,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final input = textController.text.trim();
                      if (input.isNotEmpty) {
                        Navigator.pop(ctx, input);
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == null || result.isEmpty) return null;

    if (result.startsWith(callbackUrlScheme)) {
      return result;
    }

    if (result.contains('://')) {
      final parts = result.split('://');
      if (parts.length == 2) {
        return '$callbackUrlScheme://${parts[1]}';
      }
    }

    return '$callbackUrlScheme://callback?code=$result';
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
