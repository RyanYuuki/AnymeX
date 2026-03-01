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
      final result = await _controller.evaluateJavascript(source: '''
        (function() {
          try {
            var token = null;

            try {
              token = localStorage.getItem('token');
              if (token) return token;
            } catch(e) {}

            try {
              token = window.LOCAL_STORAGE && window.LOCAL_STORAGE.getItem('token');
              if (token) return token;
            } catch(e) {}

            try {
              var iframe = document.querySelector('iframe');
              if (iframe && iframe.contentWindow) {
                token = iframe.contentWindow.localStorage.getItem('token');
                if (token) return token;
              }
            } catch(e) {}

            try {
              for (var key in Object.keys(localStorage)) {
                if (key === 'token') {
                  token = localStorage[key];
                  if (token) return token;
                }
              }
            } catch(e) {}

            return null;
          } catch(e) {
            return null;
          }
        })()
      ''');

      if (result != null && result != 'null' && result.toString().isNotEmpty) {
        _tokenExtracted = true;
        final token = result.toString().trim().replaceAll('"', '');
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
        try { window.LOCAL_STORAGE && window.LOCAL_STORAGE.clear(); } catch(e) {}
        try { window.sessionStorage.clear(); } catch(e) {}
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
                  ),
                  onLoadStart: (controller, url) async {
                    await controller.evaluateJavascript(source: '''
                      try {
                        window.LOCAL_STORAGE = localStorage;
                      } catch (e) {}
                    ''');
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
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
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
