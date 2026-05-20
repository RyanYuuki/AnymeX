import 'package:anymex/screens/extensions/extension_webview.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';

class CloudflareHelper {
  static const _cloudflarePatterns = [
    'cloudflare',
    'just a moment',
    'attention required',
    'checking your browser',
    'enable javascript and cookies',
    'challenge-platform',
    'ddos-guard',
    'cf-browser-verification',
    'ray id',
    'access denied',
    'error 1020',
    'error 1015',
    'error 1010',
    'error 1005',
    'blocked',
  ];

  static const _authPatterns = [
    'login required',
    'sign in',
    'unauthorized',
    'authentication required',
    'please log in',
    'log in to continue',
    'premium only',
    'subscription required',
  ];

  static bool isCloudflareError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return _cloudflarePatterns.any((pattern) => errorStr.contains(pattern));
  }

  static bool isAuthError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return _authPatterns.any((pattern) => errorStr.contains(pattern));
  }

  static bool isBlockStatusCode(int? statusCode) {
    if (statusCode == null) return false;
    return statusCode == 403 ||
        statusCode == 503 ||
        statusCode == 502 ||
        statusCode == 429;
  }

  static void promptWebView(BuildContext context, Source source, dynamic error) {
    final isCf = isCloudflareError(error);
    final isAuth = isAuthError(error);
    final baseUrl = source.baseUrl ?? '';

    if (!isCf && !isAuth) return;
    if (baseUrl.isEmpty) return;

    final message = isCf
        ? 'Cloudflare detected for ${source.name}. Open WebView to pass the challenge?'
        : 'Login may be required for ${source.name}. Open WebView to login?';

    Logger.i('Challenge detected for ${source.name}: ${error.toString()}');

    snackBar(
      message,
      duration: 5000,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: Row(
          children: [
            Icon(
              isCf ? Icons.shield_outlined : Icons.login_rounded,
              color: isCf ? Colors.orange : Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isCf ? 'Cloudflare Challenge' : 'Login Required',
                style: const TextStyle(fontFamily: 'Poppins-SemiBold', fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          isCf
              ? '${source.name} is protected by Cloudflare. You need to pass the challenge in WebView before using this extension.'
              : '${source.name} may require you to login. Open WebView to authenticate?',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.openExtensionWebView(
                url: baseUrl,
                sourceName: source.name ?? 'Extension',
              );
            },
            child: const Text('Open WebView'),
          ),
        ],
      ),
    );
  }
}
