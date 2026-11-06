import 'package:anymex/controllers/services/anilist/anilist_rate_limiter.dart';
import 'package:rhttp/rhttp.dart';

class AnilistInterceptor extends Interceptor {
  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri != null && uri.host.contains('anilist.co')) {
      await AnilistRateLimiter.instance.acquire();
      final headers = (request.headers ?? HttpHeaders.empty)
          .copyWithoutRaw('Origin')
          .copyWithoutRaw('origin')
          .copyWithoutRaw('Referer')
          .copyWithoutRaw('referer')
          .copyWithRaw(name: 'Origin', value: 'https://anilist.co')
          .copyWithRaw(name: 'Referer', value: 'https://anilist.co/');
      return Interceptor.next(request.copyWith(headers: headers));
    }
    return Interceptor.next(request);
  }

  @override
  Future<InterceptorResult<HttpResponse>> afterResponse(
    HttpResponse response,
  ) async {
    final uri = Uri.tryParse(response.request.url);
    if (uri != null && uri.host.contains('anilist.co')) {
      AnilistRateLimiter.instance.onResponse(
        statusCode: response.statusCode,
        headers: response.headerMap,
      );
    }
    return Interceptor.next();
  }

  @override
  Future<InterceptorResult<RhttpException>> onError(
    RhttpException exception,
  ) async {
    final url = exception.request.url;
    if (url.contains('anilist.co') && exception is RhttpStatusCodeException) {
      AnilistRateLimiter.instance.onResponse(
        statusCode: exception.statusCode,
        headers: exception.headerMap,
      );
    }
    return Interceptor.next();
  }
}
