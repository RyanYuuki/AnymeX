import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CloudflareBypassWebView extends StatefulWidget {
  final String url;

  const CloudflareBypassWebView({super.key, required this.url});

  @override
  State<CloudflareBypassWebView> createState() =>
      _CloudflareBypassWebViewState();
}

class _CloudflareBypassWebViewState extends State<CloudflareBypassWebView> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _synced = false;

  Uri get _parsedUri => Uri.parse(widget.url);

  String get _displayHost =>
      _parsedUri.host.isNotEmpty ? _parsedUri.host : widget.url;

  Future<void> _syncCookiesAndUserAgent() async {
    if (_controller == null) return;
    final currentUrlObj = await _controller!.getUrl();
    final currentUrl = currentUrlObj?.toString() ?? widget.url;

    final uri = Uri.tryParse(currentUrl);
    final origin = (uri != null && uri.hasScheme && uri.host.isNotEmpty)
        ? '${uri.scheme}://${uri.host}'
        : currentUrl;

    final cookieManager = CookieManager.instance();
    final cookies = await cookieManager.getCookies(url: WebUri(origin));

    if (cookies.isNotEmpty) {
      final cookieString =
          cookies.map((c) => '${c.name}=${c.value}').join('; ');
      await AnymeXRuntimeBridge.setCookies(origin, cookieString);
    }

    final uaResult =
        await _controller!.evaluateJavascript(source: 'navigator.userAgent');

    if (uaResult != null) {
      final ua = uaResult.toString().replaceAll('"', '');
      if (ua.isNotEmpty) {
        await AnymeXRuntimeBridge.setUserAgent(origin, ua);
      }
    }
  }

  void _onSyncPressed() async {
    await _syncCookiesAndUserAgent();
    if (mounted) {
      setState(() => _synced = true);
      snackBar('Cookies & User-Agent synced! You can now close this view.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 12),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.onSurface),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      color: colors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bypass Cloudflare',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _displayHost,
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.55),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isLoading
                        ? Padding(
                            key: const ValueKey('loading'),
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            ),
                          )
                        : TextButton.icon(
                            key: ValueKey(_synced),
                            onPressed: _onSyncPressed,
                            icon: Icon(
                              _synced
                                  ? Icons.check_circle_rounded
                                  : Icons.sync_rounded,
                              size: 18,
                              color:
                                  _synced ? colors.primary : colors.onSurface,
                            ),
                            label: Text(
                              _synced ? 'Synced!' : 'Sync Cookies',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    _synced ? colors.primary : colors.onSurface,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            if (_progress > 0 && _progress < 1)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: colors.surfaceContainerHighest,
                color: colors.primary,
                minHeight: 2,
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colors.primaryContainer.withValues(alpha: 0.35),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14,
                      color: colors.onPrimaryContainer.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete any Cloudflare challenge, then tap "Sync Cookies" to pass the session to extensions.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                initialUserScripts: null,
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  useWideViewPort: true,
                  loadWithOverviewMode: true,
                  thirdPartyCookiesEnabled: true,
                  limitsNavigationsToAppBoundDomains: false,
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                },
                onLoadStart: (controller, url) {
                  if (mounted) setState(() => _isLoading = true);
                },
                onLoadStop: (controller, url) async {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                      _progress = 1.0;
                    });
                  }

                  await _syncCookiesAndUserAgent();
                },
                onProgressChanged: (controller, progress) {
                  if (mounted) {
                    setState(() => _progress = progress / 100);
                  }
                },
                shouldOverrideUrlLoading:
                    (controller, navigationAction) async =>
                        NavigationActionPolicy.ALLOW,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension CloudflareBypassNavigation on BuildContext {
  Future<void> openCloudflareBypass(String url) async {
    await Navigator.of(this).push(
      MaterialPageRoute(
        builder: (_) => CloudflareBypassWebView(url: url),
        fullscreenDialog: true,
      ),
    );
  }
}
