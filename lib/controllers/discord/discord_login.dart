import 'dart:collection';

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
  late InAppWebViewController _controller;
  bool _tokenExtracted = false;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _isResetting = false;

  static const String _interceptScript = '''
    (function() {
      if (window.__tokenListenerInstalled) return;
      window.__tokenListenerInstalled = true;

      function sendToken(token) {
        if (!token || token === 'null') return;
        try {
          window.flutter_inappwebview.callHandler('onTokenFound', token);
        } catch(e) {
          window.__discordToken = token;
        }
      }

      function patchWebpack() {
        try {
          var chunks = window.webpackChunkdiscord_app;
          if (!chunks) return false;
          var _push = chunks.push.bind(chunks);
          chunks.push = function(chunk) {
            var result = _push(chunk);
            try {
              var req = window.__webpack_require__ || webpackChunkdiscord_app.__webpack_require__;
              if (req) {
                var tokenModule = req('MuTa') || req('./node_modules/discord-api-types/v9.js');
                if (tokenModule && tokenModule.getToken) {
                  var t = tokenModule.getToken();
                  if (t) sendToken(t);
                }
              }
            } catch(e) {}
            return result;
          };
          return true;
        } catch(e) { return false; }
      }

      function scanWebpackModules() {
        try {
          var req = window.webpackChunkdiscord_app &&
                    window.webpackChunkdiscord_app.__webpack_require__;
          if (!req || !req.m) return;
          Object.values(req.m).forEach(function(mod) {
            try {
              var m = { exports: {} };
              mod(m, m.exports, req);
              if (m.exports && typeof m.exports.getToken === 'function') {
                var t = m.exports.getToken();
                if (t) sendToken(t);
              }
            } catch(e) {}
          });
        } catch(e) {}
      }

      function sweepStorage() {
        try {
          var t = localStorage.getItem('token');
          if (t && t !== 'null') { sendToken(t.replace(/"/g,'')); return; }
        } catch(e) {}
        try {
          var keys = Object.keys(localStorage);
          for (var i = 0; i < keys.length; i++) {
            var val = localStorage.getItem(keys[i]);
            if (val && /^[\\w-]{50,100}\$/.test(val.replace(/"/g,''))) {
              sendToken(val.replace(/"/g,''));
              return;
            }
          }
        } catch(e) {}
      }

      (function patchNetwork() {
        var _fetch = window.fetch;
        window.fetch = function() {
          return _fetch.apply(this, arguments).then(function(res) {
            var clone = res.clone();
            clone.json().then(function(json) {
              if (json && json.token) sendToken(json.token);
            }).catch(function(){});
            return res;
          });
        };

        var _open = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function() {
          this.addEventListener('load', function() {
            try {
              var json = JSON.parse(this.responseText);
              if (json && json.token) sendToken(json.token);
            } catch(e) {}
          });
          return _open.apply(this, arguments);
        };
      })();

      var attempts = 0;
      var interval = setInterval(function() {
        attempts++;
        if (attempts > 60) { clearInterval(interval); return; }
        if (window.__discordToken) { sendToken(window.__discordToken); }
        patchWebpack();
        scanWebpackModules();
        sweepStorage();
      }, 500);
    })();
  ''';

  void _handleToken(String raw) {
    if (_tokenExtracted) return;
    final token = raw.trim().replaceAll('"', '');
    if (token.isEmpty || token == 'null') return;
    _tokenExtracted = true;
    widget.onTokenExtracted(token);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _resetSession() async {
    setState(() => _isResetting = true);

    try {
      await _controller.evaluateJavascript(source: '''
        try { localStorage.clear(); } catch(e) {}
        try { sessionStorage.clear(); } catch(e) {}
        try { window.__tokenListenerInstalled = false; } catch(e) {}
        try { window.__discordToken = null; } catch(e) {}
      ''');

      await _controller.clearCache();

      final cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();

      _tokenExtracted = false;

      await _controller.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://discord.com/login')),
      );
    } catch (e) {
      debugPrint('Reset error: $e');
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
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
                  if (_isLoading || _isResetting)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isResetting
                              ? const Color(0xFFED4245)
                              : const Color(0xFF5865F2),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFB5BAC1),
                      ),
                      onPressed: _resetSession,
                      tooltip: 'Reset & re-login',
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
                  initialUserScripts: UnmodifiableListView([
                    UserScript(
                      source: _interceptScript,
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
                    limitsNavigationsToAppBoundDomains: false,
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    _controller.addJavaScriptHandler(
                      handlerName: 'onTokenFound',
                      callback: (args) {
                        if (args.isNotEmpty) {
                          _handleToken(args[0].toString());
                        }
                      },
                    );
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
                    await controller.evaluateJavascript(
                        source: _interceptScript);
                  },
                  onProgressChanged: (controller, progress) {
                    if (mounted) setState(() => _progress = progress / 100);
                  },
                  onUpdateVisitedHistory: (controller, url, isReload) async {
                    await controller.evaluateJavascript(
                        source: _interceptScript);
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async =>
                          NavigationActionPolicy.ALLOW,
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