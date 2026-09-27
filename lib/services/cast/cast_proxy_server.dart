import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class CastProxyServer {
  static HttpServer? _server;
  static String? _currentProxyUrl;
  static String? _currentSubtitleUrl;
  static String? _originalVideoUrl;
  static String? _originalSubtitleUrl;
  static Map<String, String>? _videoHeaders;
  static String? _subtitleLabel;
  static int _serverPort = 0;
  static String _serverHost = '127.0.0.1';

  static Future<String?> startProxy({
    required String originalUrl,
    Map<String, String>? headers,
    String? subtitleUrl,
    String? subtitleLabel,
  }) async {
    await stopProxy();
    try {
      _originalVideoUrl = originalUrl;
      _originalSubtitleUrl = subtitleUrl;
      _videoHeaders = headers;
      _subtitleLabel = subtitleLabel ?? 'English';

      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _serverPort = _server!.port;
      _serverHost = await _resolveLocalIp();

      final isHls = _isHlsUrl(originalUrl);
      if (isHls) {
        _currentProxyUrl = 'http://$_serverHost:$_serverPort/hls/master.m3u8';
      } else {
        _currentProxyUrl = 'http://$_serverHost:$_serverPort/video';
      }

      if (subtitleUrl != null && subtitleUrl.isNotEmpty) {
        _currentSubtitleUrl = 'http://$_serverHost:$_serverPort/subtitles.vtt';
      } else {
        _currentSubtitleUrl = null;
      }

      _server!.listen(_handleRequest);
      return _currentProxyUrl;
    } catch (_) {
      return originalUrl;
    }
  }

  static String? get currentProxyUrl => _currentProxyUrl;
  static String? get currentSubtitleUrl => _currentSubtitleUrl;

  static bool _isHlsUrl(String url) {
    final clean = url.split('?').first.toLowerCase();
    return clean.endsWith('.m3u8') || url.contains('.m3u8');
  }

  static Future<String> _resolveLocalIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    for (final interface in interfaces) {
      final name = interface.name.toLowerCase();
      if (name.contains('wlan') ||
          name.contains('eth') ||
          name.contains('ap') ||
          name.contains('rndis') ||
          name.contains('en') ||
          name.contains('wl')) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    }

    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    }

    return '127.0.0.1';
  }

  static void _applyCorsHeaders(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS, POST');
    response.headers.set('Access-Control-Allow-Headers', '*');
    response.headers.set('Access-Control-Expose-Headers', '*');
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    _applyCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    try {
      if (path == '/video') {
        await _serveVideo(request);
      } else if (path == '/hls/master.m3u8') {
        await _serveHlsMaster(request);
      } else if (path == '/hls/variant.m3u8') {
        await _serveHlsVariant(request);
      } else if (path == '/hls/segment') {
        await _serveHlsSegment(request);
      } else if (path == '/subtitles.vtt') {
        await _serveSubtitleVtt(request);
      } else if (path == '/hls/subtitles.m3u8') {
        await _serveHlsSubtitlePlaylist(request);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    } catch (_) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  static Future<void> _serveVideo(HttpRequest request) async {
    final originalUrl = _originalVideoUrl;
    if (originalUrl == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final isLocal = originalUrl.startsWith('/') || originalUrl.startsWith('file://');
    if (isLocal) {
      await _serveLocalFile(request, originalUrl);
      return;
    }

    await _proxyRemoteStream(request, originalUrl);
  }

  static Future<void> _serveLocalFile(HttpRequest request, String filePath) async {
    final resolvedPath = filePath.startsWith('file://')
        ? Uri.parse(filePath).toFilePath()
        : filePath;
    final file = File(resolvedPath);

    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final totalLength = await file.length();
    final rangeHeader = request.headers.value('range');

    request.response.headers.set('Accept-Ranges', 'bytes');
    request.response.headers.contentType = ContentType('video', 'mp4');

    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final range = rangeHeader.substring(6).split('-');
      final start = int.tryParse(range[0]) ?? 0;
      final end = (range.length > 1 && range[1].isNotEmpty)
          ? int.tryParse(range[1]) ?? (totalLength - 1)
          : totalLength - 1;

      if (start >= totalLength || end >= totalLength || start > end) {
        request.response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        request.response.headers.set('Content-Range', 'bytes */$totalLength');
        await request.response.close();
        return;
      }

      final contentLength = end - start + 1;
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.contentLength = contentLength;
      request.response.headers.set('Content-Range', 'bytes $start-$end/$totalLength');

      await file.openRead(start, end + 1).pipe(request.response);
    } else {
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentLength = totalLength;
      await file.openRead().pipe(request.response);
    }
  }

  static Future<void> _proxyRemoteStream(HttpRequest request, String remoteUrl) async {
    final reqHeaders = <String, String>{};
    if (_videoHeaders != null) {
      reqHeaders.addAll(_videoHeaders!);
    }
    reqHeaders.putIfAbsent('User-Agent', () => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');

    final rangeHeader = request.headers.value('range');
    if (rangeHeader != null) {
      reqHeaders['range'] = rangeHeader;
    }

    final client = http.Client();
    final clientReq = http.Request(request.method, Uri.parse(remoteUrl));
    clientReq.headers.addAll(reqHeaders);

    final clientResp = await client.send(clientReq);
    request.response.statusCode = clientResp.statusCode;

    clientResp.headers.forEach((key, value) {
      final lower = key.toLowerCase();
      if (lower != 'transfer-encoding' && lower != 'access-control-allow-origin') {
        request.response.headers.set(key, value);
      }
    });

    request.response.headers.contentType ??= ContentType('video', 'mp4');

    await clientResp.stream.pipe(request.response);
  }

  static Future<void> _serveHlsMaster(HttpRequest request) async {
    final originalUrl = _originalVideoUrl;
    if (originalUrl == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final reqHeaders = <String, String>{};
    if (_videoHeaders != null) {
      reqHeaders.addAll(_videoHeaders!);
    }
    reqHeaders.putIfAbsent('User-Agent', () => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');

    final resp = await http.get(Uri.parse(originalUrl), headers: reqHeaders);
    if (resp.statusCode != 200) {
      request.response.statusCode = resp.statusCode;
      await request.response.close();
      return;
    }

    final originalManifest = resp.body;
    final baseUri = Uri.parse(originalUrl);
    final rewritten = _rewriteHlsMasterManifest(originalManifest, baseUri);

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType('application', 'vnd.apple.mpegurl', charset: 'utf-8');
    request.response.write(rewritten);
    await request.response.close();
  }

  static String _rewriteHlsMasterManifest(String manifest, Uri baseUri) {
    final lines = manifest.split('\n');
    final output = <String>[];
    final hasSubtitles = _originalSubtitleUrl != null && _originalSubtitleUrl!.isNotEmpty;
    bool hasInjectedSubtitles = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTM3U')) {
        output.add(line);
        if (hasSubtitles && !hasInjectedSubtitles) {
          final subName = _subtitleLabel ?? 'English';
          final subUri = 'http://$_serverHost:$_serverPort/hls/subtitles.m3u8';
          output.add(
            '#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="$subName",DEFAULT=YES,AUTOSELECT=YES,FORCED=NO,LANGUAGE="en",URI="$subUri"',
          );
          hasInjectedSubtitles = true;
        }
        continue;
      }

      if (line.startsWith('#EXT-X-STREAM-INF')) {
        var streamInf = line;
        if (hasSubtitles && !streamInf.contains('SUBTITLES=')) {
          streamInf = '$streamInf,SUBTITLES="subs"';
        }
        output.add(streamInf);
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (!nextLine.startsWith('#') && nextLine.isNotEmpty) {
            final absoluteUri = baseUri.resolve(nextLine).toString();
            final proxyVariantUrl = 'http://$_serverHost:$_serverPort/hls/variant.m3u8?url=${Uri.encodeComponent(absoluteUri)}';
            output.add(proxyVariantUrl);
            i++;
          }
        }
        continue;
      }

      if (!line.startsWith('#')) {
        final absoluteUri = baseUri.resolve(line).toString();
        final proxyVariantUrl = 'http://$_serverHost:$_serverPort/hls/variant.m3u8?url=${Uri.encodeComponent(absoluteUri)}';
        output.add(proxyVariantUrl);
        continue;
      }

      output.add(line);
    }

    return output.join('\n');
  }

  static Future<void> _serveHlsVariant(HttpRequest request) async {
    final targetUrl = request.uri.queryParameters['url'];
    if (targetUrl == null) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final reqHeaders = <String, String>{};
    if (_videoHeaders != null) {
      reqHeaders.addAll(_videoHeaders!);
    }
    reqHeaders.putIfAbsent('User-Agent', () => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');

    final resp = await http.get(Uri.parse(targetUrl), headers: reqHeaders);
    if (resp.statusCode != 200) {
      request.response.statusCode = resp.statusCode;
      await request.response.close();
      return;
    }

    final baseUri = Uri.parse(targetUrl);
    final rewritten = _rewriteHlsVariantManifest(resp.body, baseUri);

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType('application', 'vnd.apple.mpegurl', charset: 'utf-8');
    request.response.write(rewritten);
    await request.response.close();
  }

  static String _rewriteHlsVariantManifest(String manifest, Uri baseUri) {
    final lines = manifest.split('\n');
    final output = <String>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXT-X-KEY:')) {
        final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
        if (uriMatch != null) {
          final keyUri = uriMatch.group(1)!;
          final resolvedKey = baseUri.resolve(keyUri).toString();
          final proxyKey = 'http://$_serverHost:$_serverPort/hls/segment?url=${Uri.encodeComponent(resolvedKey)}';
          final rewrittenLine = line.replaceFirst('URI="$keyUri"', 'URI="$proxyKey"');
          output.add(rewrittenLine);
          continue;
        }
      }

      if (!line.startsWith('#')) {
        final absoluteUri = baseUri.resolve(line).toString();
        final proxySegmentUrl = 'http://$_serverHost:$_serverPort/hls/segment?url=${Uri.encodeComponent(absoluteUri)}';
        output.add(proxySegmentUrl);
        continue;
      }

      output.add(line);
    }

    return output.join('\n');
  }

  static Future<void> _serveHlsSegment(HttpRequest request) async {
    final targetUrl = request.uri.queryParameters['url'];
    if (targetUrl == null) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final reqHeaders = <String, String>{};
    if (_videoHeaders != null) {
      reqHeaders.addAll(_videoHeaders!);
    }
    reqHeaders.putIfAbsent('User-Agent', () => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');

    final rangeHeader = request.headers.value('range');
    if (rangeHeader != null) {
      reqHeaders['range'] = rangeHeader;
    }

    final client = http.Client();
    final clientReq = http.Request('GET', Uri.parse(targetUrl));
    clientReq.headers.addAll(reqHeaders);

    final clientResp = await client.send(clientReq);
    request.response.statusCode = clientResp.statusCode;

    clientResp.headers.forEach((key, value) {
      final lower = key.toLowerCase();
      if (lower != 'transfer-encoding' && lower != 'access-control-allow-origin') {
        request.response.headers.set(key, value);
      }
    });

    await clientResp.stream.pipe(request.response);
  }

  static Future<void> _serveHlsSubtitlePlaylist(HttpRequest request) async {
    final subVttUrl = 'http://$_serverHost:$_serverPort/subtitles.vtt';
    final playlist =
        '#EXTM3U\n'
        '#EXT-X-TARGETDURATION:7200\n'
        '#EXT-X-VERSION:3\n'
        '#EXT-X-MEDIA-SEQUENCE:0\n'
        '#EXTINF:7200.0,\n'
        '$subVttUrl\n'
        '#EXT-X-ENDLIST\n';

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType('application', 'vnd.apple.mpegurl', charset: 'utf-8');
    request.response.write(playlist);
    await request.response.close();
  }

  static Future<void> _serveSubtitleVtt(HttpRequest request) async {
    final subUrl = _originalSubtitleUrl;
    if (subUrl == null || subUrl.isEmpty) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    String content = '';
    final isLocal = subUrl.startsWith('/') || subUrl.startsWith('file://');
    if (isLocal) {
      final resolvedPath = subUrl.startsWith('file://') ? Uri.parse(subUrl).toFilePath() : subUrl;
      final file = File(resolvedPath);
      if (await file.exists()) {
        content = await file.readAsString();
      }
    } else {
      final resp = await http.get(Uri.parse(subUrl));
      if (resp.statusCode == 200) {
        content = resp.body;
      }
    }

    if (content.isEmpty) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final vttContent = _formatToVtt(content);
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType('text', 'vtt', charset: 'utf-8');
    request.response.write(vttContent);
    await request.response.close();
  }

  static String _formatToVtt(String raw) {
    var trimmed = raw.trim();
    if (trimmed.startsWith('WEBVTT')) {
      return trimmed;
    }

    trimmed = trimmed.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = trimmed.split('\n');
    final srtTimeRegex = RegExp(r'(\d{2}:\d{2}:\d{2}),(\d{3})');

    final converted = lines.map((line) {
      return line.replaceAllMapped(srtTimeRegex, (match) {
        return '${match.group(1)}.${match.group(2)}';
      });
    }).join('\n');

    return 'WEBVTT\n\n$converted';
  }

  static Future<void> stopProxy() async {
    if (_server != null) {
      try {
        await _server!.close(force: true);
      } catch (_) {}
      _server = null;
      _currentProxyUrl = null;
      _currentSubtitleUrl = null;
      _originalVideoUrl = null;
      _originalSubtitleUrl = null;
      _videoHeaders = null;
      _subtitleLabel = null;
    }
  }
}

