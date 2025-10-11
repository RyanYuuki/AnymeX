import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/utils/cookie_manager.dart';

class CaptchaWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String? title;
  final Function(bool success)? onCaptchaComplete;

  const CaptchaWebViewScreen({
    super.key,
    required this.initialUrl,
    this.title,
    this.onCaptchaComplete,
  });

  @override
  State<CaptchaWebViewScreen> createState() => _CaptchaWebViewScreenState();
}

class _CaptchaWebViewScreenState extends State<CaptchaWebViewScreen> {
  InAppWebViewController? webViewController;
  bool isLoading = true;
  String currentUrl = '';
  double progress = 0;
  bool captchaSolved = false;
  final cookieManager = CookieManagerService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Solve Captcha'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () {
            Get.back(result: captchaSolved);
            widget.onCaptchaComplete?.call(captchaSolved);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () => webViewController?.reload(),
          ),
          IconButton(
            icon: const Icon(Iconsax.tick_circle),
            onPressed: () async {
              // Save cookies from WebView before completing
              if (webViewController != null) {
                final currentUri = await webViewController!.getUrl();
                if (currentUri != null) {
                  await cookieManager.saveCookiesFromWebView(currentUri);
                }
              }
              
              setState(() {
                captchaSolved = true;
              });
              Get.back(result: true);
              widget.onCaptchaComplete?.call(true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (isLoading)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                allowsInlineMediaPlayback: true,
                mediaPlaybackRequiresUserGesture: false,
                userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
                useHybridComposition: true,
                allowsLinkPreview: false,
                iframeAllow: "camera; microphone",
                iframeAllowFullscreen: true,
              ),
              onWebViewCreated: (controller) async {
                webViewController = controller;
                
                // Apply any saved cookies for this domain
                final initialUri = WebUri(widget.initialUrl);
                await cookieManager.applyCookiesToWebView(initialUri);
              },
              onLoadStart: (controller, url) {
                setState(() {
                  isLoading = true;
                  currentUrl = url.toString();
                });
              },
              onLoadStop: (controller, url) async {
                setState(() {
                  isLoading = false;
                  currentUrl = url.toString();
                });

                // Check if we've successfully navigated past the captcha
                await _checkCaptchaStatus(controller);
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  this.progress = progress / 100;
                });
              },
              onReceivedError: (controller, request, error) {
                setState(() {
                  isLoading = false;
                });
                
                // Show error message to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load page: ${error.description}'),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () => webViewController?.reload(),
                    ),
                  ),
                );
              },
              onReceivedHttpError: (controller, request, errorResponse) {
                setState(() {
                  isLoading = false;
                });
                
                // Show HTTP error message
                if (errorResponse.statusCode == 403) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Access forbidden - captcha may be required'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Instructions:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Complete any captcha or verification challenge',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                Text(
                  '2. Wait for the page to load successfully',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                Text(
                  '3. Tap the check mark when complete',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkCaptchaStatus(InAppWebViewController controller) async {
    try {
      // Check if the page contains typical signs of successful captcha completion
      final result = await controller.evaluateJavascript(source: """
        (function() {
          // Check for common indicators that captcha is solved
          const captchaElements = document.querySelectorAll('[class*="captcha"], [id*="captcha"], [class*="challenge"], [id*="challenge"]');
          const errorElements = document.querySelectorAll('[class*="error"], [id*="error"]');
          const successElements = document.querySelectorAll('[class*="success"], [id*="success"]');
          
          // Check if page has video or episode content (indicating success)
          const videoElements = document.querySelectorAll('video, [class*="episode"], [class*="player"]');
          
          return {
            hasCaptcha: captchaElements.length > 0,
            hasError: errorElements.length > 0,
            hasSuccess: successElements.length > 0,
            hasVideo: videoElements.length > 0,
            url: window.location.href
          };
        })();
      """);

      if (result != null) {
        final data = result as Map<String, dynamic>?;
        if (data != null) {
          // Auto-detect success if page has video content and no captcha/errors
          if ((data['hasVideo'] == true || data['hasSuccess'] == true) && 
              data['hasCaptcha'] == false && 
              data['hasError'] == false) {
            
            // Save cookies when captcha appears to be solved
            final currentUri = await controller.getUrl();
            if (currentUri != null) {
              await cookieManager.saveCookiesFromWebView(currentUri);
            }
            
            setState(() {
              captchaSolved = true;
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Captcha appears to be solved! Cookies saved. Tap the check mark to continue.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking captcha status: $e');
    }
  }

  @override
  void dispose() {
    webViewController?.dispose();
    super.dispose();
  }
}