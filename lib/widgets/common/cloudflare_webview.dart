import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class CloudflareBypassWebView extends StatefulWidget {
  final String url;

  const CloudflareBypassWebView({super.key, required this.url});

  @override
  State<CloudflareBypassWebView> createState() =>
      _CloudflareBypassWebViewState();
}

class _CloudflareBypassWebViewState extends State<CloudflareBypassWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _synced = false;
  bool _initialLoad = true;
  String? _initialClearance;

  Uri get _parsedUri => Uri.parse(widget.url);

  String get _displayHost =>
      _parsedUri.host.isNotEmpty ? _parsedUri.host : widget.url;

  @override
  void initState() {
    super.initState();
    _initCookieBaseline();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) async {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _progress = 1.0;
              });
            }

            final cleared = await _syncCookiesAndUserAgent();
            _initialLoad = false;
            if (cleared && mounted) {
              setState(() => _synced = true);
              snackBar('Cloudflare challenge solved!');
              await Future.delayed(const Duration(milliseconds: 600));
              if (!context.mounted) return;
              Navigator.of(context).pop(true);
            }
          },
          onProgress: (progress) {
            if (mounted) {
              setState(() => _progress = progress / 100);
            }
          },
          onNavigationRequest: (action) => NavigationDecision.navigate,
        ),
      );

    final userAgent = AnymeXRuntimeBridge.userAgentMap[_parsedUri.host] ??
        AnymeXRuntimeBridge.userAgentMap[
            _parsedUri.host.replaceFirst('www.', '')];
    if (userAgent != null && userAgent.isNotEmpty) {
      _controller.setUserAgent(userAgent);
    }

    _controller.loadRequest(Uri.parse(widget.url));
  }

  Future<void> _initCookieBaseline() async {
    try {
      final uri = _parsedUri;
      if (uri.hasScheme && uri.host.isNotEmpty) {
        final origin = '${uri.scheme}://${uri.host}';
        final cookieManager = WebViewCookieManager();
        final cookies = await cookieManager.getCookies(domain: Uri.parse(origin));
        for (final c in cookies) {
          if (c.name == 'cf_clearance') {
            _initialClearance = c.value.toString();
            break;
          }
        }
      }
    } catch (_) {}
  }

  Future<bool> _isChallengeActive() async {
    try {
      final result = await _controller.runJavaScriptReturningResult('''
        (function() {
          var title = (document.title || "").toLowerCase();
          if (title.indexOf("just a moment") !== -1 ||
              title.indexOf("attention required") !== -1 ||
              title.indexOf("checking your browser") !== -1) {
            return true;
          }
          if (document.querySelector("#challenge-stage, #cf-challenge-running, #challenge-form, .challenge-form, #challenge-platform, iframe[src*='cloudflare'], iframe[src*='turnstile']")) {
            return true;
          }
          return false;
        })()
      ''');
      return result == true || result == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<bool> _syncCookiesAndUserAgent() async {
    final currentUrl = await _controller.currentUrl() ?? widget.url;

    final uri = Uri.tryParse(currentUrl);
    final origin = (uri != null && uri.hasScheme && uri.host.isNotEmpty)
        ? '${uri.scheme}://${uri.host}'
        : currentUrl;

    final cookieManager = WebViewCookieManager();
    List<WebViewCookie> cookies = [];
    try {
      cookies = await cookieManager.getCookies(domain: Uri.parse(origin));
    } catch (_) {}

    bool hasFreshClearance = false;
    if (cookies.isNotEmpty) {
      final cookieString =
          cookies.map((c) => '${c.name}=${c.value}').join('; ');
      await AnymeXRuntimeBridge.setCookies(origin, cookieString);
      try {
        await Get.find<NetworkManager>()
            .cookieManager
            .readCookiesFromWebView(Uri.parse(origin), _controller);
      } catch (_) {}
      for (final c in cookies) {
        if (c.name == 'cf_clearance') {
          final val = c.value.toString();
          if (_initialClearance == null || val != _initialClearance) {
            hasFreshClearance = true;
          }
          break;
        }
      }
    }

    final uaResult =
        await _controller.runJavaScriptReturningResult('navigator.userAgent');

    final ua = uaResult.toString().replaceAll('"', '');
    if (ua.isNotEmpty && ua != 'null') {
      await AnymeXRuntimeBridge.setUserAgent(origin, ua);
    }
    final isChallenging = await _isChallengeActive();
    return hasFreshClearance && !isChallenging && !_initialLoad;
  }

  void _onSyncPressed() async {
    await _syncCookiesAndUserAgent();
    if (mounted) {
      setState(() => _synced = true);
      snackBar('Cookies & User-Agent synced!');
      Navigator.of(context).pop(true);
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
                        AnymeXText(
                          'Bypass Cloudflare',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AnymeXText(
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
                            label: AnymeXText(
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
                    child: AnymeXText(
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
              child: WebViewWidget(
                controller: _controller,
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
    navigate(
      () => CloudflareBypassWebView(url: url),
    );
  }
}
