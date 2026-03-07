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

  Future<void> _extractToken() async {
    if (!mounted || _tokenExtracted) return;

    await Future.delayed(const Duration(seconds: 2));

    try {
      final result = await _controller.callAsyncJavaScript(functionBody: '''
        return new Promise((resolve) => {
          try {
            var token = localStorage.getItem('token');
            if (token) { resolve(token); return; }
          } catch(e) {}

          try {
            var request = indexedDB.open('localforage');
            request.onsuccess = function(event) {
              try {
                var db = event.target.result;
                var storeNames = Array.from(db.objectStoreNames);
                if (storeNames.length === 0) { resolve(null); return; }

                var tx = db.transaction(storeNames[0], 'readonly');
                var store = tx.objectStore(storeNames[0]);
                var getReq = store.get('token');
                getReq.onsuccess = function() {
                  if (getReq.result) {
                    resolve(getReq.result);
                  } else {
                    var cursorReq = store.openCursor();
                    cursorReq.onsuccess = function(e) {
                      var cursor = e.target.result;
                      if (cursor) {
                        if (cursor.key === 'token' ||
                            (typeof cursor.value === 'string' && cursor.value.length > 50)) {
                          resolve(cursor.value);
                          return;
                        }
                        cursor.continue();
                      } else {
                        resolve(null);
                      }
                    };
                    cursorReq.onerror = function() { resolve(null); };
                  }
                };
                getReq.onerror = function() { resolve(null); };
              } catch(e) { resolve(null); }
            };
            request.onerror = function() { resolve(null); };
          } catch(e) {
            resolve(null);
          }
        });
      ''');

      final value = result?.value;

      if (value != null && value.toString() != 'null' && value.toString().isNotEmpty) {
        _tokenExtracted = true;
        final token = value.toString().trim().replaceAll('"', '');
        if (token.isNotEmpty && token != 'null') {
          widget.onTokenExtracted(token);
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      print('Error extracting token: $e');
    }
  }

  Future<void> _clearDiscordData() async {
    await _controller.evaluateJavascript(source: '''
      if (window.location.hostname === 'discord.com') {
        try { localStorage.clear(); } catch(e) {}
        try { window.sessionStorage.clear(); } catch(e) {}
        try {
          var req = indexedDB.open('localforage');
          req.onsuccess = function(e) {
            var db = e.target.result;
            var names = Array.from(db.objectStoreNames);
            if (names.length > 0) {
              var tx = db.transaction(names[0], 'readwrite');
              tx.objectStore(names[0]).clear();
            }
          };
        } catch(e) {}
      }
    ''');
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
                  ),
                  onLoadStart: (controller, url) async {
                    if (mounted) {
                      setState(() {
                        _isLoading = true;
                      });
                    }
                  },
                  onLoadStop: (controller, url) async {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                        _progress = 1.0;
                      });
                    }
                    final urlStr = url?.toString() ?? '';
                    if (urlStr.isNotEmpty &&
                        urlStr != 'https://discord.com/login' &&
                        urlStr != 'about:blank') {
                      await _extractToken();
                    }
                  },
                  onProgressChanged: (controller, progress) {
                    if (mounted) {
                      setState(() {
                        _progress = progress / 100;
                      });
                    }
                  },
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    _clearDiscordData();
                  },
                  onUpdateVisitedHistory: (controller, url, isReload) async {
                    if (url.toString() != 'https://discord.com/login' &&
                        url.toString() != 'about:blank') {
                      await _extractToken();
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
