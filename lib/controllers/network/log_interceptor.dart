import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cloudflare_webview.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhttp/rhttp.dart';

class LogInterceptor extends Interceptor {
  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    request.additionalData['startTime'] = DateTime.now();
    debugPrint('→ ${request.method.value} ${request.url}');
    return Interceptor.next(request);
  }

  @override
  Future<InterceptorResult<HttpResponse>> afterResponse(
    HttpResponse response,
  ) async {
    final start = response.request.additionalData['startTime'];
    final ms = start is DateTime
        ? DateTime.now().difference(start).inMilliseconds
        : null;
    final remaining = response.headerMap['x-ratelimit-remaining'];
    final parts = <String>[
      '← ${response.statusCode}',
      response.request.url.toString(),
    ];

    if (ms != null) {
      parts.add('(${ms}ms)');
    }

    if (remaining != null) {
      parts.add('Remaining: $remaining');
    }

    debugPrint(parts.join(' '));

    final cloudflare = [403, 503].contains(response.statusCode) &&
        ["cloudflare-nginx", "cloudflare"]
            .contains(response.headerMap['server']?.toLowerCase());

    if (cloudflare) {
      snackBar(
        '⚠️ Detected Cloudflare protection (Tap to solve)',
        title: 'Cloudflare',
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFFB74D),
        onTap: () {
          navigate(() => CloudflareBypassWebView(url: response.request.url.toString()));
        },
      );
    }

    return Interceptor.next();
  }

  @override
  Future<InterceptorResult<RhttpException>> onError(
    RhttpException exception,
  ) async {
    final req = exception.request;
    final start = req.additionalData['startTime'];
    final ms = start is DateTime
        ? DateTime.now().difference(start).inMilliseconds
        : null;

    debugPrint(
      '× ${req.method.value} ${req.url}'
      '${ms != null ? ' (${ms}ms)' : ''}\n'
      '  $exception',
    );

    return Interceptor.next();
  }
}
