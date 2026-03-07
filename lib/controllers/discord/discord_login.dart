import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class DiscordLoginPage extends StatefulWidget {
  final Function(String) onTokenExtracted;

  const DiscordLoginPage({
    super.key,
    required this.onTokenExtracted,
  });

  @override
  State<DiscordLoginPage> createState() => _DiscordLoginPageState();
}

class _DiscordLoginPageState extends State<DiscordLoginPage> {
  InAppWebViewController? _controller;
  bool _tokenExtracted = false;
  bool _isLoading = true;
  double _progress = 0.0;

  static const String _interceptorScript = """
    (function() {
      function sendToken(token) {
        if (token && token.length > 20 && !token.includes(' ')) {
          window.flutter_inappwebview.callHandler('onTokenFound', token);
        }
      }

      function extractFromAuth(value) {
        if (!value) return;
        var t = value.replace(/^Bot\\s+|^Bearer\\s+/i, '').trim();
        if (t.length > 20) sendToken(t);
      }

      var _fetch = window.fetch;
      window.fetch = function(input, init) {
        try {
          var headers = (init && init.headers) ? init.headers : {};
          if (headers instanceof Headers) {
            var auth = headers.get('Authorization');
            if (auth) extractFromAuth(auth);
          } else if (typeof headers === 'object') {
            Object.keys(headers).forEach(function(k) {
              if (k.toLowerCase() === 'authorization') extractFromAuth(headers[k]);
            });
          }
        } catch(e) {}
        return _fetch.apply(this, arguments);
      };

      var _open = XMLHttpRequest.prototype.open;
      var _setHeader = XMLHttpRequest.prototype.setRequestHeader;
      XMLHttpRequest.prototype.setRequestHeader = function(name, value) {
        try {
          if (name.toLowerCase() === 'authorization') extractFromAuth(value);
        } catch(e) {}
        return _setHeader.apply(this, arguments);
      };
    })();
  """;

  @override
  void dispose() {
    _controller?.removeJavaScriptHandler(handlerName: 'onTokenFound');
    super.dispose();
  }

  void _handleToken(String token) {
    if (_tokenExtracted) return;
    final clean = token.trim().replaceAll('"', '');
    if (clean.isEmpty || clean == 'null' || clean.length < 20) return;
    _tokenExtracted = true;
    widget.onTokenExtracted(clean);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF313338),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2D31),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFB5BAC1)),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5865F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.discord,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Login to Discord',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            color: Color(0xFFB5BAC1),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF5865F2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_isLoading && _progress > 0 && _progress < 1)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: const Color(0xFF2B2D31),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF5865F2),
                ),
                minHeight: 3,
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF1E1F22),
                    width: 1,
                  ),
                ),
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri('https://discord.com/login'),
                  ),
                  initialUserScripts: UnmodifiableListView<UserScript>([
                    UserScript(
                      source: _interceptorScript,
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                    ),
                  ]),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    supportZoom: false,
                    useWideViewPort: true,
                    loadWithOverviewMode: true,
                    allowUniversalAccessFromFileURLs: true,
                    allowFileAccessFromFileURLs: true,
                    sharedCookiesEnabled: true,
                    thirdPartyCookiesEnabled: true,
                    limitsNavigationsToAppBoundDomains: false,
                    useShouldInterceptFetchRequest: Platform.isIOS,
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    controller.addJavaScriptHandler(
                      handlerName: 'onTokenFound',
                      callback: (args) {
                        if (args.isNotEmpty) {
                          _handleToken(args[0].toString());
                        }
                      },
                    );
                  },
                  onLoadStart: (controller, url) {
                    if (mounted) {
                      setState(() => _isLoading = true);
                    }
                  },
                  onLoadStop: (controller, url) async {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                        _progress = 1.0;
                      });
                    }
                    await controller.evaluateJavascript(source: _interceptorScript);
                  },
                  onProgressChanged: (controller, progress) {
                    if (mounted) {
                      setState(() => _progress = progress / 100);
                    }
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    return NavigationActionPolicy.ALLOW;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension DiscordLoginNavigation on BuildContext {
  Future<void> showDiscordLogin(Function(String) onTokenExtracted) async {
    await Navigator.of(this).push(
      MaterialPageRoute(
        builder: (context) => DiscordLoginPage(
          onTokenExtracted: onTokenExtracted,
        ),
      ),
    );
  }
}
