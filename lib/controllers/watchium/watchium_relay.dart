import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Host-side relay for Watchium.
///
/// Some extensions hand out stream URLs that only work on the host's device:
///   http://127.0.0.1:<port>/proxy?url=...   (a local proxy, with an
///   IP-locked token inside).
/// Joiners can never open those. This class lets the host act as the network
/// egress for the room, through the Watchium backend:
///
///   joiner -> backend /relay -> WebSocket -> host app -> 127.0.0.1:<port>
///
/// The host's own proxy makes the real request with the host's IP, so the
/// token stays valid. The backend caches responses, so the host only uploads
/// each playlist / segment once however many people are watching.
///
/// The relay only starts when a server URL is actually device-local, so hosts
/// whose extension returns normal public URLs are not affected at all. It is
/// stopped when the room is left, and the backend also revokes it as soon as
/// the room closes.
///
/// Only the HOST uses this. Joiners just play the rewritten URLs.
class WatchiumRelay extends GetxService {
  static const _tag = 'WATCHIUM_RELAY';

  /// Matches a device-local proxy origin at the start of a URL.
  static final _localOrigin =
      RegExp(r'^http://(?:127\.0\.0\.1|localhost):(\d+)', caseSensitive: false);

  /// Only these local paths are ever forwarded. Stops the backend (or anyone
  /// holding a relay URL) from reaching other local endpoints on the phone.
  static const _allowedPathPrefix = '/proxy';

  static const _requestTimeout = Duration(seconds: 18);
  static const _maxConcurrent = 6;

  final RxBool active = false.obs;

  WatchiumService get _watchium => Get.find<WatchiumService>();

  String? _id;
  String? _rt;
  int? _localPort;

  WebSocket? _ws;
  Timer? _reconnectTimer;
  int _retry = 0;
  bool _stopping = false;
  bool _starting = false;
  int _inFlight = 0;
  final List<String> _queue = [];

  final http.Client _client = http.Client();

  String get _serverUrl => _watchium.serverUrl.replaceAll(RegExp(r'/+$'), '');

  String get _wsBase => _serverUrl.replaceFirst(RegExp(r'^http'), 'ws');

  Map<String, String> get _authHeaders => {
        if (_watchium.authToken != null)
          'Authorization': 'Bearer ${_watchium.authToken}',
        if (_watchium.apiToken.isNotEmpty) 'X-API-Token': _watchium.apiToken,
      };

  /// Public origin joiners use in place of `http://127.0.0.1:<port>`.
  String? get publicBase => (active.value && _id != null && _rt != null)
      ? '$_serverUrl/relay/r/$_id/$_rt'
      : null;

  // ---------------------------------------------------------------------------
  // lifecycle
  // ---------------------------------------------------------------------------

  /// True if any URL in [servers] only works on this device.
  bool needsRelay(List<WatchiumAnimeServer> servers) {
    bool local(String? u) => u != null && _localOrigin.hasMatch(u);
    return servers.any((s) =>
        local(s.url) ||
        local(s.originalUrl) ||
        (s.subtitles?.any((t) => local(t.file)) ?? false) ||
        (s.audios?.any((t) => local(t.file)) ?? false));
  }

  /// Starts the relay if (and only if) [servers] contain device-local URLs.
  /// Returns true when the relay is active afterwards.
  Future<bool> startIfNeeded(List<WatchiumAnimeServer> servers) async {
    if (active.value) return true;
    if (!needsRelay(servers)) return false;
    return start();
  }

  /// Registers a relay session on the backend and opens the host socket.
  /// Safe to call repeatedly; returns true when the relay is ready.
  Future<bool> start() async {
    if (active.value && _ws != null) return true;
    if (_starting) return false;
    _starting = true;
    _stopping = false;
    try {
      // Needs a JWT; login() also refreshes it if it has gone stale.
      if (_watchium.authToken == null && !await _watchium.login()) return false;

      var res = await _createSession();
      if (res.statusCode == 401 && await _watchium.login()) {
        res = await _createSession(); // token expired: retry once
      }
      if (res.statusCode != 200) {
        Logger.w('Relay session create failed: HTTP ${res.statusCode}', _tag);
        return false;
      }
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      _id = j['id'] as String;
      _rt = j['rt'] as String;

      if (!await _connect()) {
        _reset();
        return false;
      }
      active.value = true;
      Logger.i('Relay started: session=$_id', _tag);
      return true;
    } catch (e) {
      Logger.e('Relay start failed', error: e, loggerName: _tag);
      _reset();
      return false;
    } finally {
      _starting = false;
    }
  }

  Future<http.Response> _createSession() => _client
      .post(
        Uri.parse('$_serverUrl/api/relay'),
        headers: {'Content-Type': 'application/json', ..._authHeaders},
        body: '{}',
      )
      .timeout(const Duration(seconds: 10));

  void stop() {
    if (!active.value && _ws == null && _id == null) return;
    Logger.i('Relay stopped (session=$_id)', _tag);
    _stopping = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _ws?.close();
    _reset();
  }

  void _reset() {
    _ws = null;
    _id = null;
    _rt = null;
    _localPort = null;
    _retry = 0;
    _queue.clear();
    active.value = false;
  }

  Future<bool> _connect() async {
    try {
      final ws = await WebSocket.connect(
        '$_wsBase/relay/host?id=$_id',
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));
      ws.pingInterval = const Duration(seconds: 20);
      _ws = ws;
      _retry = 0;

      ws.listen(
        (data) {
          if (data is String) _enqueue(data);
        },
        onDone: () => _onSocketClosed(ws),
        onError: (e) {
          Logger.w('Relay socket error: $e', _tag);
          _onSocketClosed(ws);
        },
        cancelOnError: true,
      );
      return true;
    } catch (e) {
      Logger.w('Relay connect failed: $e', _tag);
      return false;
    }
  }

  void _onSocketClosed(WebSocket ws) {
    if (!identical(_ws, ws)) return; // a newer socket already replaced it
    _ws = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_stopping || _id == null) return;

    _retry++;
    final delay = Duration(seconds: (_retry * 2).clamp(2, 15));
    Logger.w('Relay socket down, retrying in ${delay.inSeconds}s', _tag);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (_stopping || _id == null) return;
      final ok = await _connect();
      if (!ok) _scheduleReconnect();
    });
  }

  // ---------------------------------------------------------------------------
  // answering requests from the backend
  // ---------------------------------------------------------------------------

  void _enqueue(String msg) {
    _queue.add(msg);
    _pump();
  }

  void _pump() {
    while (_inFlight < _maxConcurrent && _queue.isNotEmpty) {
      final msg = _queue.removeAt(0);
      _inFlight++;
      _handle(msg).whenComplete(() {
        _inFlight--;
        _pump();
      });
    }
  }

  Future<void> _handle(String msg) async {
    String id = '';
    try {
      final m = jsonDecode(msg) as Map<String, dynamic>;
      id = (m['id'] as String?) ?? '';
      final path = (m['path'] as String?) ?? '';

      // The id is sent back as exactly 8 ASCII bytes in front of the body.
      if (id.length != 8) return;

      final port = _localPort;
      if (port == null || !path.startsWith(_allowedPathPrefix)) {
        _reply(id, 403, 'text/plain', Uint8List(0));
        return;
      }

      final req = http.Request('GET', Uri.parse('http://127.0.0.1:$port$path'));
      final streamed = await _client.send(req).timeout(_requestTimeout);
      final body = await streamed.stream.toBytes().timeout(_requestTimeout);
      _reply(
        id,
        streamed.statusCode,
        streamed.headers['content-type'] ?? 'application/octet-stream',
        body,
      );
    } catch (e) {
      Logger.w('Relay request failed: $e', _tag);
      if (id.length == 8) _reply(id, 502, 'text/plain', Uint8List(0));
    }
  }

  void _reply(String id, int status, String contentType, Uint8List body) {
    final ws = _ws;
    if (ws == null || ws.readyState != WebSocket.open) return;

    ws.add(jsonEncode({
      'id': id,
      'status': status,
      'headers': {'content-type': contentType},
    }));

    final frame = BytesBuilder(copy: false)
      ..add(ascii.encode(id))
      ..add(body);
    ws.add(frame.takeBytes());
  }

  // ---------------------------------------------------------------------------
  // URL rewriting (host -> what gets shared with the room)
  // ---------------------------------------------------------------------------

  /// Swaps `http://127.0.0.1:<port>` for the relay's public base.
  /// URLs that are already public are returned unchanged.
  String swapUrl(String url) {
    final base = publicBase;
    if (base == null) return url;
    final m = _localOrigin.firstMatch(url);
    if (m == null) return url;
    _localPort = int.tryParse(m.group(1)!);
    return '$base${url.substring(m.end)}';
  }

  /// Rewrites every device-local URL in [servers] so joiners can play them.
  ///
  /// - When the relay is not active, [servers] is returned untouched, so
  ///   behaviour is identical to before this feature existed.
  /// - Servers with an empty `url` (e.g. the "Download" entries) are dropped.
  List<WatchiumAnimeServer> rewriteServers(List<WatchiumAnimeServer> servers) {
    if (publicBase == null) return servers;

    WatchiumTrack swapTrack(WatchiumTrack t) =>
        WatchiumTrack(file: swapUrl(t.file), label: t.label);

    return servers
        .where((s) => (s.url ?? '').isNotEmpty)
        .map((s) => WatchiumAnimeServer(
              serverId: s.serverId,
              serverName: s.serverName,
              quality: s.quality,
              type: s.type,
              url: swapUrl(s.url!),
              originalUrl: s.originalUrl == null ? null : swapUrl(s.originalUrl!),
              headers: s.headers,
              subtitles: s.subtitles?.map(swapTrack).toList(),
              audios: s.audios?.map(swapTrack).toList(),
            ))
        .toList();
  }

  @override
  void onClose() {
    stop();
    _client.close();
    super.onClose();
  }
}
