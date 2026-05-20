import 'dart:collection';

import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class ExtensionWebViewPage extends StatefulWidget {
  final String url;
  final String sourceName;

  const ExtensionWebViewPage({
    super.key,
    required this.url,
    required this.sourceName,
  });

  @override
  State<ExtensionWebViewPage> createState() => _ExtensionWebViewPageState();
}

class _ExtensionWebViewPageState extends State<ExtensionWebViewPage> {
  late InAppWebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;
  String _currentUrl = '';
  bool _cloudflareDetected = false;
  String? _pageTitle;

  static const String _cloudflareDetectScript = '''
    (function() {
      var cfIndicators = [
        document.getElementById('challenge-running'),
        document.getElementById('challenge-stage'),
        document.querySelector('.challenge-platform'),
        document.querySelector('[data-ray]'),
        document.title && document.title.includes('Just a moment'),
        document.title && document.title.includes('Attention Required'),
        document.querySelector('iframe[src*="challenges.cloudflare.com"]'),
        document.body && document.body.innerText && document.body.innerText.includes('Checking your browser'),
        document.body && document.body.innerText && document.body.innerText.includes('Enable JavaScript and cookies to continue'),
      ];
      var detected = cfIndicators.some(function(el) { return !!el; });
      if (detected) {
        window.flutter_inappwebview.callHandler('onCloudflareDetected', true);
      }
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
  }

  Future<void> _clearCookiesForDomain() async {
    final cookieManager = CookieManager.instance();
    final uri = Uri.parse(widget.url);
    final domain = uri.host;

    try {
      final cookies = await cookieManager.getCookies(url: WebUri(widget.url));
      for (final cookie in cookies) {
        await cookieManager.deleteCookie(
          url: WebUri('https://${cookie.domain ?? domain}'),
          name: cookie.name,
          domain: cookie.domain,
        );
      }
      Logger.i('Cleared cookies for $domain');
    } catch (e) {
      Logger.e('Error clearing cookies: $e');
    }
  }

  Future<void> _clearAllData() async {
    try {
      await _controller.evaluateJavascript(source: '''
        try { localStorage.clear(); } catch(e) {}
        try { sessionStorage.clear(); } catch(e) {}
      ''');
      await _controller.clearCache();
      await CookieManager.instance().deleteAllCookies();
      Logger.i('Cleared all WebView data');
    } catch (e) {
      Logger.e('Error clearing all data: $e');
    }

    if (mounted) {
      _controller.loadUrl(
        urlRequest: URLRequest(url: WebUri(widget.url)),
      );
    }
  }

  Future<void> _showCookieInfo() async {
    final cookieManager = CookieManager.instance();
    try {
      final cookies =
          await cookieManager.getCookies(url: WebUri(_currentUrl));
      if (!mounted) return;

      final cookieList = cookies
          .map((c) => '${c.name}=${c.value}${c.domain != null ? ' (${c.domain})' : ''}')
          .toList();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          title: Text(
            'Cookies (${cookies.length})',
            style: const TextStyle(fontFamily: 'Poppins-SemiBold'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: cookies.isEmpty
                ? const Center(
                    child: Text('No cookies found for this domain'))
                : ListView.separated(
                    itemCount: cookieList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cookie = cookies[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.cookie_outlined,
                          size: 18,
                          color: context.colors.primary,
                        ),
                        title: Text(
                          cookie.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(
                          '${cookie.value.substring(0, cookie.value.length > 50 ? 50 : cookie.value.length)}${cookie.value.length > 50 ? '...' : ''}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: context.colors.onSurface.withOpacity(0.6),
                          ),
                        ),
                        trailing: Text(
                          cookie.domain ?? '',
                          style: TextStyle(
                            fontSize: 9,
                            color: context.colors.onSurface.withOpacity(0.4),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Logger.e('Error reading cookies: $e');
    }
  }

  void _onCloudflareDetected(bool detected) {
    if (detected && !_cloudflareDetected) {
      setState(() => _cloudflareDetected = true);
      Logger.i('Cloudflare challenge detected - user can solve it in WebView');
    } else if (!detected && _cloudflareDetected) {
      setState(() => _cloudflareDetected = false);
      Logger.i('Cloudflare challenge passed successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;

    return Scaffold(
      backgroundColor: theme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(theme),

            if (_cloudflareDetected) _buildCloudflareBanner(theme),

            if (_isLoading && _progress > 0 && _progress < 1)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: theme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                minHeight: 3,
              ),

            _buildUrlBar(theme),

            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  supportZoom: true,
                  useWideViewPort: true,
                  loadWithOverviewMode: true,
                  allowUniversalAccessFromFileURLs: true,
                  allowFileAccessFromFileURLs: true,
                  limitsNavigationsToAppBoundDomains: false,
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  thirdPartyCookiesEnabled: true,
                  userAgent:
                      'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
                  cacheEnabled: true,
                  allowFileAccess: true,
                  blockNetworkLoads: false,
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;

                  _controller.addJavaScriptHandler(
                    handlerName: 'onCloudflareDetected',
                    callback: (args) {
                      if (args.isNotEmpty) {
                        _onCloudflareDetected(args[0] as bool);
                      }
                    },
                  );
                },
                onLoadStart: (controller, url) {
                  if (mounted) {
                    setState(() {
                      _isLoading = true;
                      _currentUrl = url?.toString() ?? widget.url;
                    });
                  }
                },
                onLoadStop: (controller, url) async {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                      _progress = 1.0;
                      _currentUrl = url?.toString() ?? widget.url;
                    });
                  }

                  try {
                    final title = await controller.getTitle();
                    if (mounted) {
                      setState(() => _pageTitle = title);
                    }
                  } catch (_) {}

                  try {
                    await controller.evaluateJavascript(
                        source: _cloudflareDetectScript);
                  } catch (_) {}
                },
                onProgressChanged: (controller, progress) {
                  if (mounted) {
                    setState(() => _progress = progress / 100);
                  }
                },
                onUpdateVisitedHistory: (controller, url, isReload) async {
                  if (mounted) {
                    setState(() => _currentUrl = url?.toString() ?? widget.url);
                  }
                  try {
                    await controller.evaluateJavascript(
                        source: _cloudflareDetectScript);
                  } catch (_) {}
                },
                shouldOverrideUrlLoading:
                    (controller, navigationAction) async =>
                        NavigationActionPolicy.ALLOW,
                onReceivedHttpAuthRequest:
                    (controller, challenge) async {
                  return HttpAuthResponse(
                    action: HttpAuthResponseAction.CANCEL,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.outline.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: theme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
          const SizedBox(width: 4),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.language_rounded,
              color: theme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sourceName,
                  style: const TextStyle(
                    fontFamily: 'Poppins-SemiBold',
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'WebView Login & Cookies',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: theme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: Icon(Icons.cookie_outlined, color: theme.onSurface.withOpacity(0.7)),
            onPressed: _showCookieInfo,
            tooltip: 'View Cookies',
          ),

          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: theme.onSurface.withOpacity(0.7)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHigh,
                  title: const Text(
                    'Clear Data',
                    style: TextStyle(fontFamily: 'Poppins-SemiBold'),
                  ),
                  content: const Text(
                    'Clear all cookies and site data? The page will reload.',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearAllData();
                      },
                      child: const Text('Clear & Reload'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Clear Data',
          ),

          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: theme.primary),
              onPressed: () => _controller.reload(),
              tooltip: 'Refresh',
            ),
        ],
      ),
    );
  }

  Widget _buildCloudflareBanner(ColorScheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade900.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.shade900.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cloudflare Challenge Detected',
                  style: TextStyle(
                    fontFamily: 'Poppins-SemiBold',
                    fontSize: 13,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Wait for the challenge to complete automatically',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.orange.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.orange.withOpacity(0.8)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUrlBar(ColorScheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 12,
            color: _currentUrl.startsWith('https')
                ? Colors.green
                : Colors.orange,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _currentUrl,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: theme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

extension ExtensionWebViewNavigation on BuildContext {
  Future<void> openExtensionWebView({
    required String url,
    required String sourceName,
  }) async {
    if (url.isEmpty) {
      return;
    }

    await Navigator.of(this).push(
      MaterialPageRoute(
        builder: (context) => ExtensionWebViewPage(
          url: url,
          sourceName: sourceName,
        ),
      ),
    );
  }
}
