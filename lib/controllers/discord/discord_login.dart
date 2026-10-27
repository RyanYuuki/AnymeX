import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

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
  late final WebViewController _controller;
  bool _tokenExtracted = false;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _isResetting = false;
  Timer? _pollingTimer;

  static const String _interceptScript = r'''
    (function() {
      if (window.__tokenListenerInstalled) return;
      window.__tokenListenerInstalled = true;

      function sendToken(token) {
        if (!token || typeof token !== 'string') return;
        token = token.trim().replace(/^"|"$/g, '');
        if (token.indexOf('Bearer ') === 0) {
          token = token.substring(7).trim();
        }
        if (token.length < 25 || token === 'null' || token === 'undefined') return;
        window.__discordToken = token;
        try {
          if (window.onTokenFound && window.onTokenFound.postMessage) {
            window.onTokenFound.postMessage(token);
          }
        } catch(e) {}
      }

      function getFromIframe() {
        try {
          var iframe = document.createElement('iframe');
          iframe.style.display = 'none';
          document.body.appendChild(iframe);
          var t = iframe.contentWindow.localStorage.getItem('token');
          iframe.remove();
          if (t) sendToken(t);
        } catch(e) {}
      }

      function getFromWebpack() {
        try {
          var req;
          if (window.webpackChunkdiscord_app && Array.isArray(window.webpackChunkdiscord_app)) {
            window.webpackChunkdiscord_app.push([
              [Symbol()],
              {},
              function(r) { req = r; }
            ]);
          } else if (window.__webpack_require__) {
            req = window.__webpack_require__;
          }
          if (req && req.c) {
            for (var id in req.c) {
              try {
                var exp = req.c[id] && req.c[id].exports;
                if (!exp) continue;
                if (exp.default && typeof exp.default.getToken === 'function') {
                  var t = exp.default.getToken();
                  if (t) sendToken(t);
                }
                if (typeof exp.getToken === 'function') {
                  var t = exp.getToken();
                  if (t) sendToken(t);
                }
              } catch(e) {}
            }
          }
        } catch(e) {}
      }

      function getFromStorage() {
        try {
          var t = localStorage.getItem('token');
          if (t) sendToken(t);
        } catch(e) {}
        try {
          for (var i = 0; i < localStorage.length; i++) {
            var val = localStorage.getItem(localStorage.key(i));
            if (val && val.length > 25 && (val.indexOf('.') > -1 || val.indexOf('mfa.') === 0)) {
              sendToken(val);
            }
          }
        } catch(e) {}
      }

      try {
        var _fetch = window.fetch;
        if (_fetch) {
          window.fetch = function(input, init) {
            try {
              if (init && init.headers) {
                var auth;
                if (typeof Headers !== 'undefined' && init.headers instanceof Headers) {
                  auth = init.headers.get('authorization') || init.headers.get('Authorization');
                } else if (Array.isArray(init.headers)) {
                  for (var i = 0; i < init.headers.length; i++) {
                    if (init.headers[i][0].toLowerCase() === 'authorization') {
                      auth = init.headers[i][1];
                      break;
                    }
                  }
                } else if (typeof init.headers === 'object') {
                  auth = init.headers['Authorization'] || init.headers['authorization'];
                }
                if (auth) sendToken(auth);
              }
            } catch(e) {}
            return _fetch.apply(this, arguments).then(function(res) {
              try {
                var clone = res.clone();
                clone.json().then(function(json) {
                  if (json && json.token) sendToken(json.token);
                }).catch(function(){});
              } catch(e) {}
              return res;
            });
          };
        }
      } catch(e) {}

      try {
        var _setRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
        XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
          try {
            if (header && header.toLowerCase() === 'authorization' && value) {
              sendToken(value);
            }
          } catch(e) {}
          return _setRequestHeader.apply(this, arguments);
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
      } catch(e) {}

      var attempts = 0;
      var interval = setInterval(function() {
        attempts++;
        if (window.__discordToken) {
          sendToken(window.__discordToken);
        }
        getFromIframe();
        getFromWebpack();
        getFromStorage();
        if (attempts > 120 && !window.__discordToken) {
          clearInterval(interval);
        }
      }, 400);
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _initController();
    _startPolling();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'onTokenFound',
        onMessageReceived: (message) {
          if (message.message.isNotEmpty) {
            _handleToken(message.message);
          }
        },
      )
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
            await _controller.runJavaScript(_interceptScript);
            await _checkAndExtractToken();
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress / 100);
          },
          onUrlChange: (change) async {
            await _controller.runJavaScript(_interceptScript);
            await _checkAndExtractToken();
          },
          onNavigationRequest: (request) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse('https://discord.com/login'));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) async {
      if (_tokenExtracted || !mounted) {
        timer.cancel();
        return;
      }
      await _checkAndExtractToken();
    });
  }

  Future<void> _checkAndExtractToken() async {
    if (_tokenExtracted) return;
    try {
      final result = await _controller.runJavaScriptReturningResult(r'''
        (function() {
          if (window.__discordToken) return window.__discordToken;
          try {
            var iframe = document.createElement('iframe');
            iframe.style.display = 'none';
            document.body.appendChild(iframe);
            var t = iframe.contentWindow.localStorage.getItem('token');
            iframe.remove();
            if (t && t !== 'null' && t.length > 25) return t.replace(/"/g, '');
          } catch(e) {}
          try {
            var req;
            if (window.webpackChunkdiscord_app && Array.isArray(window.webpackChunkdiscord_app)) {
              window.webpackChunkdiscord_app.push([[Symbol()], {}, function(r) { req = r; }]);
            } else if (window.__webpack_require__) {
              req = window.__webpack_require__;
            }
            if (req && req.c) {
              for (var id in req.c) {
                var exp = req.c[id] && req.c[id].exports;
                if (!exp) continue;
                if (exp.default && typeof exp.default.getToken === 'function') {
                  var tok = exp.default.getToken();
                  if (tok && typeof tok === 'string' && tok.length > 25) return tok.replace(/"/g, '');
                }
                if (typeof exp.getToken === 'function') {
                  var tok = exp.getToken();
                  if (tok && typeof tok === 'string' && tok.length > 25) return tok.replace(/"/g, '');
                }
              }
            }
          } catch(e) {}
          try {
            var t2 = localStorage.getItem('token');
            if (t2 && t2 !== 'null' && t2.length > 25) return t2.replace(/"/g, '');
          } catch(e) {}
          return null;
        })();
      ''');
      if (result.toString().isNotEmpty && result.toString() != 'null') {
        _handleToken(result.toString());
      }
    } catch (_) {}
  }

  void _handleToken(String raw) {
    if (_tokenExtracted) return;
    var token = raw.trim().replaceAll('"', '');
    if (token.startsWith('Bearer ')) {
      token = token.substring(7).trim();
    }
    if (token.isEmpty || token == 'null' || token == 'undefined' || token.length < 25) return;
    _tokenExtracted = true;
    _pollingTimer?.cancel();
    widget.onTokenExtracted(token);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _resetSession() async {
    _pollingTimer?.cancel();
    setState(() => _isResetting = true);

    try {
      await _controller.runJavaScript(r'''
        try { localStorage.clear(); } catch(e) {}
        try { sessionStorage.clear(); } catch(e) {}
        try { window.__tokenListenerInstalled = false; } catch(e) {}
        try { window.__discordToken = null; } catch(e) {}
      ''');

      await _controller.clearCache();

      await WebViewCookieManager().clearCookies();

      _tokenExtracted = false;

      await _controller.loadRequest(
        Uri.parse('https://discord.com/login'),
      );
    } catch (e) {
      debugPrint('Reset error: $e');
    } finally {
      if (mounted) {
        setState(() => _isResetting = false);
        _startPolling();
      }
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
                        AnymeXText(
                          'Login to Discord',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AnymeXText(
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
                child: WebViewWidget(
                  controller: _controller,
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
