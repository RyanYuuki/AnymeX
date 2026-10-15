import 'dart:convert';
import 'dart:io';
import 'package:anymex/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'cloud_sync_provider.dart';

class WebDavProvider implements CloudSyncProvider {
  static const String syncFileName = 'anymex_cloud_sync.json.gz';
  final String serverUrl;
  final String username;
  final String password;
  final String subDirectory;

  WebDavProvider({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.subDirectory = 'AnymeX',
  });

  @override
  String get id => 'webdav';

  @override
  String get displayName => 'WebDAV';

  String get _normalizedBaseUrl {
    var url = serverUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  String get _authHeader {
    final credentials = '$username:$password';
    return 'Basic ${base64Encode(utf8.encode(credentials))}';
  }

  Map<String, String> get _headers => {
        'Authorization': _authHeader,
        'User-Agent': 'AnymeX-CloudSync/1.0',
      };

  Uri _buildUri([String? path]) {
    final base = _normalizedBaseUrl;
    if (path == null || path.isEmpty) {
      return Uri.parse(base);
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$base/$cleanPath');
  }

  @override
  Future<bool> testConnection() async {
    try {
      final uri = _buildUri();
      final request = http.Request('PROPFIND', uri)
        ..headers.addAll(_headers)
        ..headers['Depth'] = '0';

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 15));
      final status = streamedResponse.statusCode;

      if (status == 200 || status == 207 || status == 204) {
        return true;
      }

      // Fallback: try GET / HEAD if server restricts PROPFIND at root
      final headResponse = await http
          .head(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      return headResponse.statusCode < 400;
    } catch (e) {
      Logger.e('WebDAV test connection failed: $e');
      return false;
    }
  }

  Future<void> _ensureDirectory(String folder) async {
    try {
      final uri = _buildUri(folder);
      final checkReq = http.Request('PROPFIND', uri)
        ..headers.addAll(_headers)
        ..headers['Depth'] = '0';
      final checkRes =
          await checkReq.send().timeout(const Duration(seconds: 10));

      if (checkRes.statusCode == 404) {
        final mkcolReq = http.Request('MKCOL', uri)..headers.addAll(_headers);
        final mkcolRes =
            await mkcolReq.send().timeout(const Duration(seconds: 10));
        Logger.i('WebDAV MKCOL $folder returned: ${mkcolRes.statusCode}');
      }
    } catch (e) {
      Logger.w('WebDAV ensureDirectory error: $e');
    }
  }

  @override
  Future<void> uploadFile(String remoteFileName, List<int> bytes) async {
    await _ensureDirectory(subDirectory);

    final targetPath = '$subDirectory/$remoteFileName';
    final uri = _buildUri(targetPath);

    final response = await http
        .put(
          uri,
          headers: {
            ..._headers,
            'Content-Type': 'application/octet-stream',
            'Content-Length': bytes.length.toString(),
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'WebDAV upload failed with status ${response.statusCode}: ${response.body}',
      );
    }
  }

  @override
  Future<List<int>?> downloadFile(String remoteFileName) async {
    final targetPath = '$subDirectory/$remoteFileName';
    final uri = _buildUri(targetPath);

    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'WebDAV download failed with status ${response.statusCode}',
      );
    }

    return response.bodyBytes;
  }

  @override
  Future<CloudFileMetadata?> getFileMetadata(String remoteFileName) async {
    try {
      final targetPath = '$subDirectory/$remoteFileName';
      final uri = _buildUri(targetPath);

      final request = http.Request('PROPFIND', uri)
        ..headers.addAll(_headers)
        ..headers['Depth'] = '0';

      final streamedRes =
          await request.send().timeout(const Duration(seconds: 15));
      if (streamedRes.statusCode == 404) return null;

      final body = await streamedRes.stream.bytesToString();
      return _parsePropfindResponse(remoteFileName, body);
    } catch (e) {
      Logger.w('WebDAV getFileMetadata error: $e');
      return null;
    }
  }

  @override
  Future<void> uploadData(Map<String, dynamic> data) async {
    final compressed = gzip.encode(utf8.encode(jsonEncode(data)));
    await uploadFile(syncFileName, compressed);
  }

  @override
  Future<Map<String, dynamic>?> downloadData() async {
    final bytes = await downloadFile(syncFileName);
    if (bytes == null || bytes.isEmpty) return null;
    final decompressed = utf8.decode(gzip.decode(bytes));
    return jsonDecode(decompressed) as Map<String, dynamic>;
  }

  @override
  Future<CloudFileMetadata?> getMetadata() async {
    return getFileMetadata(syncFileName);
  }

  @override
  Future<bool> deleteFile([String? remoteFileName]) async {
    final fileName = remoteFileName ?? syncFileName;
    try {
      final targetPath = '$subDirectory/$fileName';
      final uri = _buildUri(targetPath);

      final response = await http
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 404;
    } catch (e) {
      Logger.e('WebDAV deleteFile error: $e');
      return false;
    }
  }

  CloudFileMetadata _parsePropfindResponse(String fileName, String xml) {
    int size = 0;
    DateTime? modified;

    // Fast regex extraction for XML properties without heavy external XML parser
    final lengthMatch =
        RegExp(r'<[^:]*:?getcontentlength[^>]*>(\d+)</', caseSensitive: false)
            .firstMatch(xml);
    if (lengthMatch != null) {
      size = int.tryParse(lengthMatch.group(1) ?? '') ?? 0;
    }

    final dateMatch = RegExp(
            r'<[^:]*:?getlastmodified[^>]*>([^<]+)</',
            caseSensitive: false)
        .firstMatch(xml);
    if (dateMatch != null) {
      final rawDate = dateMatch.group(1)?.trim();
      if (rawDate != null) {
        modified = DateTime.tryParse(rawDate) ?? _tryParseHttpDate(rawDate);
      }
    }

    final etagMatch =
        RegExp(r'<[^:]*:?getetag[^>]*>([^<]+)</', caseSensitive: false)
            .firstMatch(xml);

    return CloudFileMetadata(
      name: fileName,
      sizeBytes: size,
      modifiedTime: modified,
      etag: etagMatch?.group(1)?.replaceAll('"', ''),
    );
  }

  DateTime? _tryParseHttpDate(String httpDate) {
    try {
      // RFC 1123 / RFC 850 format e.g. "Wed, 21 Oct 2026 07:28:00 GMT"
      final parts = httpDate.split(' ');
      if (parts.length >= 5) {
        final day = int.tryParse(parts[1]) ?? 1;
        final monthStr = parts[2].toLowerCase();
        final year = int.tryParse(parts[3]) ?? DateTime.now().year;
        final timeParts = parts[4].split(':');
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute =
            timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
        final second =
            timeParts.length > 2 ? int.tryParse(timeParts[2]) ?? 0 : 0;

        const months = {
          'jan': 1,
          'feb': 2,
          'mar': 3,
          'apr': 4,
          'may': 5,
          'jun': 6,
          'jul': 7,
          'aug': 8,
          'sep': 9,
          'oct': 10,
          'nov': 11,
          'dec': 12,
        };
        final month = months[monthStr] ?? 1;
        return DateTime.utc(year, month, day, hour, minute, second);
      }
    } catch (_) {}
    return null;
  }
}
