import 'package:rhttp/rhttp.dart';

class AnilistInterceptor extends Interceptor {
  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri != null && uri.host.contains('anilist.co')) {
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
}
