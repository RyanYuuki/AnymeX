import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dlna_dart/dlna.dart' as dlna_pkg;
import 'package:dlna_dart/xmlParser.dart' as dlna_parser;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'cast_proxy_server.dart';
import 'cast_v2_client.dart';

enum CastProtocol { chromecast, dlna, roku }

class CastDevice {
  final String id;
  final String name;
  final String host;
  final int port;
  final String? serviceUrl;
  final CastProtocol protocol;
  final dlna_pkg.DLNADevice? dlnaDevice;

  CastDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.serviceUrl,
    required this.protocol,
    this.dlnaDevice,
  });
}

class CastService extends GetxController {
  static CastService get instance {
    if (!Get.isRegistered<CastService>()) {
      return Get.put(CastService());
    }
    return Get.find<CastService>();
  }

  final RxList<CastDevice> discoveredDevices = <CastDevice>[].obs;
  final Rxn<CastDevice> connectedDevice = Rxn<CastDevice>();
  final RxBool isSearching = false.obs;
  final RxBool isCasting = false.obs;
  final RxBool isPlaying = true.obs;
  final Rx<Duration> castPosition = Duration.zero.obs;
  final Rx<Duration> castDuration = Duration.zero.obs;

  dlna_pkg.DLNAManager? _dlnaManager;
  dlna_pkg.DLNADevice? _activeDlnaDevice;
  StreamSubscription? _dlnaSubscription;
  StreamSubscription? _dlnaPositionSubscription;
  CastV2Client? _castClient;
  StreamSubscription? _castMessageSubscription;
  StreamSubscription? _castStateSubscription;
  int? _chromecastMediaSessionId;
  RawDatagramSocket? _ssdpSocket;
  RawDatagramSocket? _mdnsSocket;
  Timer? _positionPollTimer;

  Future<void> startDiscovery() async {
    discoveredDevices.clear();
    isSearching.value = true;

    await Future.wait([
      _startDlnaDiscovery(),
      _startChromecastDiscovery(),
      _startRokuAndSsdpDiscovery(),
    ]);

    isSearching.value = false;
  }

  Future<void> _startDlnaDiscovery() async {
    try {
      _dlnaSubscription?.cancel();
      _dlnaManager?.stop();
      _dlnaManager = dlna_pkg.DLNAManager();
      final dm = await _dlnaManager!.start();

      _dlnaSubscription = dm.devices.stream.listen((deviceMap) {
        for (final entry in deviceMap.entries) {
          final dev = entry.value;
          final host = Uri.tryParse(dev.info.URLBase)?.host ?? dev.info.URLBase;
          final friendlyName = dev.info.friendlyName.isNotEmpty
              ? dev.info.friendlyName
              : 'Smart TV ($host)';

          final isRoku = friendlyName.toLowerCase().contains('roku') ||
              dev.info.deviceType.toLowerCase().contains('roku');

          final device = CastDevice(
            id: 'dlna-$host-${dev.info.friendlyName}',
            name: friendlyName,
            host: host,
            port: 1900,
            serviceUrl: dev.info.URLBase,
            protocol: isRoku ? CastProtocol.roku : CastProtocol.dlna,
            dlnaDevice: dev,
          );

          _addDiscoveredDevice(device);
        }
      });
    } catch (_) {}
  }

  Future<void> _startChromecastDiscovery() async {
    try {
      _mdnsSocket?.close();
      _mdnsSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _mdnsSocket!.broadcastEnabled = true;

      final mdnsQuery = _buildMdnsQuery('_googlecast._tcp.local');
      _mdnsSocket!.send(mdnsQuery, InternetAddress('224.0.0.251'), 5353);

      _mdnsSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _mdnsSocket?.receive();
          if (datagram != null) {
            final host = datagram.address.address;
            final text = String.fromCharCodes(datagram.data);
            if (text.contains('googlecast') || text.contains('Chromecast') || text.contains('Google Cast')) {
              final friendlyName = _extractMdnsName(text, 'Chromecast ($host)');
              final device = CastDevice(
                id: 'chromecast-$host-8009',
                name: friendlyName,
                host: host,
                port: 8009,
                protocol: CastProtocol.chromecast,
              );
              _addDiscoveredDevice(device);
            }
          }
        }
      });
    } catch (_) {}
  }

  String _extractMdnsName(String raw, String defaultName) {
    final fnMatch = RegExp(r'fn=([^\x00-\x1f\r\n]+)').firstMatch(raw);
    if (fnMatch != null && fnMatch.group(1) != null) {
      final name = fnMatch.group(1)!.trim();
      if (name.isNotEmpty) return name;
    }
    final mdMatch = RegExp(r'md=([^\x00-\x1f\r\n]+)').firstMatch(raw);
    if (mdMatch != null && mdMatch.group(1) != null) {
      final model = mdMatch.group(1)!.trim();
      if (model.isNotEmpty) return model;
    }
    return defaultName;
  }

  List<int> _buildMdnsQuery(String serviceName) {
    final builder = BytesBuilder();
    builder.add([0x00, 0x00]);
    builder.add([0x00, 0x00]);
    builder.add([0x00, 0x01]);
    builder.add([0x00, 0x00]);
    builder.add([0x00, 0x00]);
    builder.add([0x00, 0x00]);

    for (final part in serviceName.split('.')) {
      final bytes = utf8.encode(part);
      builder.addByte(bytes.length);
      builder.add(bytes);
    }
    builder.addByte(0x00);
    builder.add([0x00, 0x0c]);
    builder.add([0x00, 0x01]);

    return builder.toBytes();
  }

  Future<void> _startRokuAndSsdpDiscovery() async {
    try {
      _ssdpSocket?.close();
      _ssdpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _ssdpSocket!.broadcastEnabled = true;

      const queries = [
        'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 3\r\nST: roku:ecp\r\n\r\n',
        'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 3\r\nST: urn:roku-com:device:player:1-0\r\n\r\n',
        'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: "ssdp:discover"\r\nMX: 3\r\nST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n\r\n',
      ];

      for (final q in queries) {
        _ssdpSocket!.send(q.codeUnits, InternetAddress('239.255.255.250'), 1900);
      }

      _ssdpSocket!.listen((event) async {
        if (event == RawSocketEvent.read) {
          final datagram = _ssdpSocket?.receive();
          if (datagram != null) {
            final text = String.fromCharCodes(datagram.data);
            final host = datagram.address.address;

            if (text.contains('roku') || text.contains('Roku')) {
              await _resolveRokuDevice(host);
            } else if (text.contains('MediaRenderer') || text.contains('AVTransport')) {
              final locMatch = RegExp(r'LOCATION:\s*(http://[^\r\n]+)', caseSensitive: false).firstMatch(text);
              final locUrl = locMatch?.group(1)?.trim();
              if (locUrl != null) {
                await _resolveUpnpDevice(locUrl, host);
              }
            }
          }
        }
      });

      await Future.delayed(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> _resolveRokuDevice(String host) async {
    try {
      final resp = await http.get(Uri.parse('http://$host:8060/query/device-info')).timeout(const Duration(seconds: 2));
      String name = 'Roku ($host)';
      if (resp.statusCode == 200) {
        final doc = XmlDocument.parse(resp.body);
        final userDeviceName = doc.findAllElements('user-given-device-name').firstOrNull?.innerText;
        final modelName = doc.findAllElements('model-name').firstOrNull?.innerText;
        final friendly = doc.findAllElements('friendly-device-name').firstOrNull?.innerText;
        name = userDeviceName ?? friendly ?? modelName ?? 'Roku ($host)';
      }

      final device = CastDevice(
        id: 'roku-$host',
        name: name,
        host: host,
        port: 8060,
        protocol: CastProtocol.roku,
      );
      _addDiscoveredDevice(device);
    } catch (_) {
      final device = CastDevice(
        id: 'roku-$host',
        name: 'Roku ($host)',
        host: host,
        port: 8060,
        protocol: CastProtocol.roku,
      );
      _addDiscoveredDevice(device);
    }
  }

  Future<void> _resolveUpnpDevice(String locationUrl, String host) async {
    try {
      final resp = await http.get(Uri.parse(locationUrl)).timeout(const Duration(seconds: 2));
      if (resp.statusCode == 200) {
        final info = dlna_parser.DeviceInfoParser(resp.body).parse(Uri.parse(locationUrl));
        final dev = dlna_pkg.DLNADevice(info);
        final device = CastDevice(
          id: 'dlna-$host-${info.friendlyName}',
          name: info.friendlyName.isNotEmpty ? info.friendlyName : 'Smart TV ($host)',
          host: host,
          port: 1900,
          serviceUrl: locationUrl,
          protocol: CastProtocol.dlna,
          dlnaDevice: dev,
        );
        _addDiscoveredDevice(device);
      }
    } catch (_) {}
  }

  void _addDiscoveredDevice(CastDevice device) {
    final existingIndex = discoveredDevices.indexWhere((d) => d.host == device.host && d.protocol == device.protocol);
    if (existingIndex == -1) {
      discoveredDevices.add(device);
    } else {
      discoveredDevices[existingIndex] = device;
    }
  }

  Future<bool> castMedia({
    required String videoUrl,
    Map<String, String>? headers,
    String? subtitleUrl,
    String? subtitleLabel,
    String? title,
    Duration? startPosition,
    required CastDevice device,
  }) async {
    try {
      final proxyUrl = await CastProxyServer.startProxy(
        originalUrl: videoUrl,
        headers: headers,
        subtitleUrl: subtitleUrl,
        subtitleLabel: subtitleLabel,
      );

      final mediaUrl = proxyUrl ?? videoUrl;
      final subUrl = CastProxyServer.currentSubtitleUrl ?? subtitleUrl;
      final isHls = videoUrl.contains('.m3u8');
      final mediaTitle = title ?? 'AnymeX Video';

      connectedDevice.value = device;
      isCasting.value = true;
      isPlaying.value = true;
      castPosition.value = startPosition ?? Duration.zero;

      if (device.protocol == CastProtocol.chromecast) {
        await _castChromecast(
          device: device,
          mediaUrl: mediaUrl,
          subtitleUrl: subUrl,
          subtitleLabel: subtitleLabel,
          title: mediaTitle,
          isHls: isHls,
          startPosition: startPosition,
        );
      } else if (device.protocol == CastProtocol.dlna) {
        await _castDlna(
          device: device,
          mediaUrl: mediaUrl,
          subtitleUrl: subUrl,
          title: mediaTitle,
          isHls: isHls,
          startPosition: startPosition,
        );
      } else if (device.protocol == CastProtocol.roku) {
        await _castRoku(
          device: device,
          mediaUrl: mediaUrl,
          isHls: isHls,
        );
      }

      return true;
    } catch (_) {
      isCasting.value = false;
      connectedDevice.value = null;
      return false;
    }
  }

  Future<void> _castChromecast({
    required CastDevice device,
    required String mediaUrl,
    String? subtitleUrl,
    String? subtitleLabel,
    required String title,
    required bool isHls,
    Duration? startPosition,
  }) async {
    await _cleanupChromecast();

    final client = await CastV2Client.connect(device.host, device.port);
    _castClient = client;

    _castStateSubscription = client.stateStream.listen((connected) {
      if (!connected) {
        stopCasting();
      }
    });

    _castMessageSubscription = client.messageStream.listen((msg) {
      if (msg['type'] == 'MEDIA_STATUS') {
        final statuses = msg['status'] as List<dynamic>?;
        if (statuses != null && statuses.isNotEmpty) {
          final first = statuses.first as Map<String, dynamic>;
          _chromecastMediaSessionId = first['mediaSessionId'] as int?;
          final stateStr = first['playerState'] as String?;
          if (stateStr != null) {
            isPlaying.value = stateStr == 'PLAYING' || stateStr == 'BUFFERING';
          }
          final currentSec = (first['currentTime'] as num?)?.toDouble();
          if (currentSec != null) {
            castPosition.value = Duration(milliseconds: (currentSec * 1000).round());
          }
          final mediaInfo = first['media'] as Map<String, dynamic>?;
          final durationSec = (mediaInfo?['duration'] as num?)?.toDouble();
          if (durationSec != null && durationSec > 0) {
            castDuration.value = Duration(milliseconds: (durationSec * 1000).round());
          }
        }
      }
    });

    client.sendMessage(
      namespace: CastV2Client.kNamespaceReceiver,
      payload: {
        'type': 'LAUNCH',
        'appId': 'CC1AD845',
        'requestId': 1,
      },
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    final tracks = <Map<String, dynamic>>[];
    final activeTrackIds = <int>[];
    if (subtitleUrl != null && subtitleUrl.isNotEmpty) {
      tracks.add({
        'trackId': 1,
        'type': 'TEXT',
        'trackContentId': subtitleUrl,
        'trackContentType': 'text/vtt',
        'name': subtitleLabel ?? 'English',
        'language': 'en-US',
        'subtype': 'SUBTITLES',
      });
      activeTrackIds.add(1);
    }

    final startSeconds = (startPosition?.inMilliseconds ?? 0) / 1000.0;

    client.sendMessage(
      namespace: CastV2Client.kNamespaceMedia,
      payload: {
        'type': 'LOAD',
        'autoPlay': true,
        'currentTime': startSeconds,
        'media': {
          'contentId': mediaUrl,
          'contentType': isHls ? 'application/x-mpegURL' : 'video/mp4',
          'streamType': 'BUFFERED',
          'metadata': {
            'type': 0,
            'metadataType': 0,
            'title': title,
          },
          if (tracks.isNotEmpty) 'tracks': tracks,
        },
        if (activeTrackIds.isNotEmpty) 'activeTrackIds': activeTrackIds,
        'requestId': 2,
      },
    );
  }

  Future<void> _castDlna({
    required CastDevice device,
    required String mediaUrl,
    String? subtitleUrl,
    required String title,
    required bool isHls,
    Duration? startPosition,
  }) async {
    final dev = device.dlnaDevice;
    if (dev != null) {
      final didlXml = _buildDlnaDidlMetadata(
        mediaUrl: mediaUrl,
        subtitleUrl: subtitleUrl,
        title: title,
        isHls: isHls,
      );

      final envelope =
          '<?xml version="1.0" encoding="utf-8"?>\n'
          '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">\n'
          '  <s:Body>\n'
          '    <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">\n'
          '      <InstanceID>0</InstanceID>\n'
          '      <CurrentURI>${_xmlEscape(mediaUrl)}</CurrentURI>\n'
          '      <CurrentURIMetaData>${_xmlEscape(didlXml)}</CurrentURIMetaData>\n'
          '    </u:SetAVTransportURI>\n'
          '  </s:Body>\n'
          '</s:Envelope>';

      try {
        await dev.request('SetAVTransportURI', utf8.encode(envelope));
      } catch (_) {
        await dev.setUrl(
          mediaUrl,
          title: title,
          type: isHls ? dlna_parser.VideoMime.hls : dlna_parser.VideoMime.mp4,
        );
      }

      await dev.play();

      if (startPosition != null && startPosition > Duration.zero) {
        final posStr = _formatDuration(startPosition);
        try {
          await dev.seek(posStr);
        } catch (_) {}
      }

      _startDlnaPositionTracking(dev);
    }
  }

  String _buildDlnaDidlMetadata({
    required String mediaUrl,
    String? subtitleUrl,
    required String title,
    required bool isHls,
  }) {
    final protocolInfo = isHls ? 'http-get:*:application/vnd.apple.mpegurl:*' : 'http-get:*:video/mp4:*';

    final subTag = (subtitleUrl != null && subtitleUrl.isNotEmpty)
        ? '<res protocolInfo="http-get:*:text/vtt:*">${_xmlEscape(subtitleUrl)}</res>\n'
          '<res protocolInfo="http-get:*:text/srt:*">${_xmlEscape(subtitleUrl)}</res>\n'
          '<sec:CaptionInfo xmlns:sec="http://www.sec.co.kr/" sec:type="vtt">${_xmlEscape(subtitleUrl)}</sec:CaptionInfo>\n'
          '<sec:CaptionInfoEx xmlns:sec="http://www.sec.co.kr/" sec:type="vtt">${_xmlEscape(subtitleUrl)}</sec:CaptionInfoEx>'
        : '';

    return '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" '
        'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" '
        'xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/" '
        'xmlns:sec="http://www.sec.co.kr/">\n'
        '  <item id="1" parentID="0" restricted="1">\n'
        '    <dc:title>${_xmlEscape(title)}</dc:title>\n'
        '    <upnp:class>object.item.videoItem</upnp:class>\n'
        '    <res protocolInfo="$protocolInfo">${_xmlEscape(mediaUrl)}</res>\n'
        '    $subTag\n'
        '  </item>\n'
        '</DIDL-Lite>';
  }

  String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  void _startDlnaPositionTracking(dlna_pkg.DLNADevice dev) {
    _cleanupDlnaTracking();
    _activeDlnaDevice = dev;
    dev.positionPoller.start();
    _dlnaPositionSubscription = dev.currPosition.stream.listen((pos) {
      if (pos.RelTimeInt > 0) {
        castPosition.value = Duration(seconds: pos.RelTimeInt);
      }
      if (pos.TrackDurationInt > 0) {
        castDuration.value = Duration(seconds: pos.TrackDurationInt);
      }
    });
  }

  void _cleanupDlnaTracking() {
    _dlnaPositionSubscription?.cancel();
    _dlnaPositionSubscription = null;
    try {
      _activeDlnaDevice?.positionPoller.stop();
    } catch (_) {}
    _activeDlnaDevice = null;
  }

  Future<void> _castRoku({
    required CastDevice device,
    required String mediaUrl,
    required bool isHls,
  }) async {
    final format = isHls ? 'hls' : 'mp4';
    final launchUrl = 'http://${device.host}:${device.port}/launch/15985?u=${Uri.encodeComponent(mediaUrl)}&videoFormat=$format&t=v';
    try {
      await http.post(Uri.parse(launchUrl));
    } catch (_) {
      final inputUrl = 'http://${device.host}:${device.port}/input/15985?u=${Uri.encodeComponent(mediaUrl)}&videoFormat=$format&t=v';
      await http.post(Uri.parse(inputUrl));
    }

    _startSimulatedPositionTracking();
  }

  void _startSimulatedPositionTracking() {
    _positionPollTimer?.cancel();
    _positionPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isCasting.value && isPlaying.value) {
        castPosition.value += const Duration(seconds: 1);
      }
    });
  }

  Future<void> play() async {
    isPlaying.value = true;
    final device = connectedDevice.value;
    if (device == null) return;

    if (device.protocol == CastProtocol.chromecast && _castClient != null) {
      _castClient!.sendMessage(
        namespace: CastV2Client.kNamespaceMedia,
        payload: {
          'type': 'PLAY',
          if (_chromecastMediaSessionId != null) 'mediaSessionId': _chromecastMediaSessionId,
          'requestId': 10,
        },
      );
    } else if (device.protocol == CastProtocol.dlna && device.dlnaDevice != null) {
      await device.dlnaDevice!.play();
    } else if (device.protocol == CastProtocol.roku) {
      await http.post(Uri.parse('http://${device.host}:${device.port}/keypress/Play'));
    }
  }

  Future<void> pause() async {
    isPlaying.value = false;
    final device = connectedDevice.value;
    if (device == null) return;

    if (device.protocol == CastProtocol.chromecast && _castClient != null) {
      _castClient!.sendMessage(
        namespace: CastV2Client.kNamespaceMedia,
        payload: {
          'type': 'PAUSE',
          if (_chromecastMediaSessionId != null) 'mediaSessionId': _chromecastMediaSessionId,
          'requestId': 11,
        },
      );
    } else if (device.protocol == CastProtocol.dlna && device.dlnaDevice != null) {
      await device.dlnaDevice!.pause();
    } else if (device.protocol == CastProtocol.roku) {
      await http.post(Uri.parse('http://${device.host}:${device.port}/keypress/Play'));
    }
  }

  Future<void> seek(Duration position) async {
    castPosition.value = position;
    final device = connectedDevice.value;
    if (device == null) return;

    if (device.protocol == CastProtocol.chromecast && _castClient != null) {
      _castClient!.sendMessage(
        namespace: CastV2Client.kNamespaceMedia,
        payload: {
          'type': 'SEEK',
          'currentTime': position.inMilliseconds / 1000.0,
          if (_chromecastMediaSessionId != null) 'mediaSessionId': _chromecastMediaSessionId,
          'requestId': 12,
        },
      );
    } else if (device.protocol == CastProtocol.dlna && device.dlnaDevice != null) {
      final posStr = _formatDuration(position);
      await device.dlnaDevice!.seek(posStr);
    }
  }

  Future<void> seekRelative(int seconds) async {
    final target = castPosition.value + Duration(seconds: seconds);
    final maxDur = castDuration.value;
    final Duration clamped;
    if (maxDur > Duration.zero && target > maxDur) {
      clamped = maxDur;
    } else if (target < Duration.zero) {
      clamped = Duration.zero;
    } else {
      clamped = target;
    }
    await seek(clamped);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> stopCasting() async {
    final device = connectedDevice.value;
    if (device != null) {
      if (device.protocol == CastProtocol.chromecast && _castClient != null) {
        try {
          _castClient!.sendMessage(
            namespace: CastV2Client.kNamespaceMedia,
            payload: {
              'type': 'STOP',
              if (_chromecastMediaSessionId != null) 'mediaSessionId': _chromecastMediaSessionId,
              'requestId': 99,
            },
          );
        } catch (_) {}
      } else if (device.protocol == CastProtocol.dlna && device.dlnaDevice != null) {
        try {
          await device.dlnaDevice!.stop();
        } catch (_) {}
      } else if (device.protocol == CastProtocol.roku) {
        try {
          await http.post(Uri.parse('http://${device.host}:${device.port}/keypress/Home'));
        } catch (_) {}
      }
    }

    _cleanupDlnaTracking();
    await _cleanupChromecast();
    _positionPollTimer?.cancel();
    await CastProxyServer.stopProxy();

    connectedDevice.value = null;
    isCasting.value = false;
    castPosition.value = Duration.zero;
    castDuration.value = Duration.zero;
  }

  Future<void> _cleanupChromecast() async {
    _castMessageSubscription?.cancel();
    _castStateSubscription?.cancel();
    if (_castClient != null) {
      try {
        await _castClient!.close();
      } catch (_) {}
      _castClient = null;
    }
    _chromecastMediaSessionId = null;
  }

  @override
  void onClose() {
    _cleanupDlnaTracking();
    _dlnaSubscription?.cancel();
    _dlnaManager?.stop();
    _ssdpSocket?.close();
    _mdnsSocket?.close();
    stopCasting();
    super.onClose();
  }
}

