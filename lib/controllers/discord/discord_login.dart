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

  Future<void> _extractToken() async {
    if (!mounted || _tokenExtracted || _controller == null) return;

    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      final result = await _controller!.evaluateJavascript(source: '''
        (function() {
          try {
            var token = localStorage.getItem('token');
            if (token) {
              return token;
            }
            // Try alternative storage locations
            for (var i = 0; i < localStorage.length; i++) {
              var key = localStorage.key(i);
              if (key && key.includes('token')) {
                return localStorage.getItem(key);
              }
            }
            return null;
          } catch (e) {
            return null;
          }
        })()
      ''');

      if (result != null &&
          result.toString() != 'null' &&
          result.toString().isNotEmpty) {
        _tokenExtracted = true;
        final token = result.toString().trim().replaceAll('"', '');
        widget.onTokenExtracted(token);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error extracting token: $e');
    }
  }

  Future<void> _clearDiscordData() async {
    if (_controller == null) return;

    try {
      await _controller!.evaluateJavascript(source: '''
        (function() {
          try {
            localStorage.clear();
            sessionStorage.clear();
          } catch (e) {
            console.log('Error clearing storage:', e);
          }
        })()
      ''');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return Scaffold(
      backgroundColor: const Color(0xFF313338),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                  8, isMobile ? 12 : kToolbarHeight + 12, 8, 12),
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
                      Icons.discord_rounded,
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
            // Loading progress bar
            if (_isLoading && _progress > 0 && _progress < 1)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: const Color(0xFF2B2D31),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF5865F2),
                ),
                minHeight: 3,
              ),
            // WebView
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
                    allowsInlineMediaPlayback: true,
                    mediaPlaybackRequiresUserGesture: false,
                    cacheEnabled: true,
                    clearCache: false,
                    limitsNavigationsToAppBoundDomains: false,
                    thirdPartyCookiesEnabled: true,
                  ),
                  onWebViewCreated: (controller) async {
                    _controller = controller;
                    await _clearDiscordData();
                  },
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

                    final currentUrl = url.toString();
                    if (currentUrl.contains('discord.com/channels') ||
                        currentUrl.contains('discord.com/app')) {
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
                  onUpdateVisitedHistory: (controller, url, isReload) async {
                    final urlString = url.toString();
                    if (urlString.contains('discord.com/channels') ||
                        urlString.contains('discord.com/app')) {
                      await _extractToken();
                    }
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    return NavigationActionPolicy.ALLOW;
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    print('Console: ${consoleMessage.message}');
                  },
                  onReceivedError: (controller, request, error) {
                    print('WebView Error: ${error.description}');
                  },
                  onReceivedHttpError: (controller, request, errorResponse) {
                    print('HTTP Error: ${errorResponse.statusCode}');
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
        fullscreenDialog: true,
        builder: (context) => DiscordLoginPage(
          onTokenExtracted: onTokenExtracted,
        ),
      ),
    );
  }
}
