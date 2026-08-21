import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class CastProxyServer {
  static HttpServer? _server;
  static String? _currentProxyUrl;

  static Future<String?> startProxy({
    required String originalUrl,
    Map<String, String>? headers,
  }) async {
    await stopProxy();
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      final port = _server!.port;
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      String host = '127.0.0.1';
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wlan') || name.contains('eth') || name.contains('ap') || name.contains('rndis')) {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
              host = addr.address;
              break;
            }
          }
        }
      }
      if (host == '127.0.0.1') {
        for (final interface in interfaces) {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
              host = addr.address;
              break;
            }
          }
        }
      }
      _currentProxyUrl = 'http://$host:$port/video';

      _server!.listen((HttpRequest request) async {
        try {
          final isLocal = originalUrl.startsWith('/') || originalUrl.startsWith('file://');
          if (isLocal) {
            final filePath = originalUrl.startsWith('file://')
                ? Uri.parse(originalUrl).toFilePath()
                : originalUrl;
            final file = File(filePath);
            if (await file.exists()) {
              final length = await file.length();
              request.response.statusCode = 200;
              request.response.headers.contentLength = length;
              request.response.headers.set('Accept-Ranges', 'bytes');
              request.response.headers.contentType = ContentType('video', 'mp4');
              await file.openRead().pipe(request.response);
              return;
            }
          }

          final reqHeaders = <String, String>{};
          if (headers != null) {
            reqHeaders.addAll(headers);
          }
          reqHeaders.putIfAbsent('User-Agent', () => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');

          final client = http.Client();
          final clientReq = http.Request('GET', Uri.parse(originalUrl));
          clientReq.headers.addAll(reqHeaders);
          if (request.headers.value('range') != null) {
            clientReq.headers['range'] = request.headers.value('range')!;
          }

          final clientResp = await client.send(clientReq);
          request.response.statusCode = clientResp.statusCode;
          clientResp.headers.forEach((key, value) {
            if (key.toLowerCase() != 'transfer-encoding') {
              request.response.headers.set(key, value);
            }
          });

          await clientResp.stream.pipe(request.response);
        } catch (_) {
          request.response.statusCode = 500;
          await request.response.close();
        }
      });

      return _currentProxyUrl;
    } catch (_) {
      return originalUrl;
    }
  }

  static Future<void> stopProxy() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _currentProxyUrl = null;
    }
  }

  static String? get currentProxyUrl => _currentProxyUrl;
}
