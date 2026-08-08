import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'cast_proxy_server.dart';

enum CastProtocol { chromecast, dlna, airplay }

class CastDevice {
  final String id;
  final String name;
  final String host;
  final int port;
  final String? serviceUrl;
  final CastProtocol protocol;

  CastDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.serviceUrl,
    required this.protocol,
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

  RawDatagramSocket? _udpSocket;

  Future<void> startDiscovery() async {
    discoveredDevices.clear();
    isSearching.value = true;
    try {
      await _searchSSDP();
      await _searchMDNS();
    } catch (_) {}
    isSearching.value = false;
  }

  Future<void> _searchSSDP() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpSocket!.broadcastEnabled = true;

      const ssdpQuery =
          'M-SEARCH * HTTP/1.1\r\n'
          'HOST: 239.255.255.250:1900\r\n'
          'MAN: "ssdp:discover"\r\n'
          'MX: 3\r\n'
          'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n\r\n';

      _udpSocket!.send(
        ssdpQuery.codeUnits,
        InternetAddress('239.255.255.250'),
        1900,
      );

      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket!.receive();
          if (datagram != null) {
            final response = String.fromCharCodes(datagram.data);
            if (response.contains('MediaRenderer') || response.contains('LOCATION')) {
              final host = datagram.address.address;
              final locMatch = RegExp(r'LOCATION:\s*(http://[^\r\n]+)', caseSensitive: false).firstMatch(response);
              final locUrl = locMatch?.group(1)?.trim();
              final name = _parseDeviceName(response) ?? 'Smart TV ($host)';
              final device = CastDevice(
                id: '$host-dlna',
                name: name,
                host: host,
                port: 1900,
                serviceUrl: locUrl,
                protocol: CastProtocol.dlna,
              );
              if (!discoveredDevices.any((d) => d.host == host)) {
                discoveredDevices.add(device);
              }
            }
          }
        }
      });

      await Future.delayed(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> _searchMDNS() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
              for (int i = 1; i <= 254; i++) {
                final targetHost = '$subnet.$i';
                if (targetHost == addr.address) continue;
                _checkHostServices(targetHost);
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  void _checkHostServices(String host) async {
    try {
      final socket = await Socket.connect(host, 8008, timeout: const Duration(milliseconds: 500));
      socket.destroy();
      final device = CastDevice(
        id: '$host-chromecast',
        name: 'Chromecast ($host)',
        host: host,
        port: 8008,
        protocol: CastProtocol.chromecast,
      );
      if (!discoveredDevices.any((d) => d.host == host)) {
        discoveredDevices.add(device);
      }
    } catch (_) {}
  }

  String? _parseDeviceName(String response) {
    final lines = response.split('\r\n');
    for (var line in lines) {
      if (line.toLowerCase().startsWith('server:')) {
        return line.substring(7).trim();
      }
    }
    return null;
  }

  Future<bool> castMedia({
    required String videoUrl,
    Map<String, String>? headers,
    required CastDevice device,
  }) async {
    try {
      final proxyUrl = await CastProxyServer.startProxy(
        originalUrl: videoUrl,
        headers: headers,
      );

      final mediaUrl = proxyUrl ?? videoUrl;
      connectedDevice.value = device;

      if (device.protocol == CastProtocol.dlna) {
        await _sendDLNAPlay(device, mediaUrl);
      } else {
        await _sendGenericCast(device, mediaUrl);
      }

      isCasting.value = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _sendDLNAPlay(CastDevice device, String mediaUrl) async {
    final urls = <String>[
      if (device.serviceUrl != null && device.serviceUrl!.isNotEmpty) device.serviceUrl!,
      'http://${device.host}:${device.port}/xml/AVTransport2.xml',
      'http://${device.host}:1400/xml/AVTransport2.xml',
      'http://${device.host}:8008/xml/AVTransport2.xml',
      'http://${device.host}:8008/apps/YouTube',
      'http://${device.host}:8008/',
    ];

    final body =
        '<?xml version="1.0" encoding="utf-8"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        '<s:Body>'
        '<u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">'
        '<InstanceID>0</InstanceID>'
        '<CurrentURI>$mediaUrl</CurrentURI>'
        '<CurrentURIMetaData></CurrentURIMetaData>'
        '</u:SetAVTransportURI>'
        '</s:Body>'
        '</s:Envelope>';

    const playBody =
        '<?xml version="1.0" encoding="utf-8"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        '<s:Body>'
        '<u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">'
        '<InstanceID>0</InstanceID>'
        '<Speed>1</Speed>'
        '</u:Play>'
        '</s:Body>'
        '</s:Envelope>';

    for (var url in urls) {
      try {
        await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'text/xml; charset="utf-8"',
            'SOAPACTION': '"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI"',
          },
          body: body,
        );
        await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'text/xml; charset="utf-8"',
            'SOAPACTION': '"urn:schemas-upnp-org:service:AVTransport:1#Play"',
          },
          body: playBody,
        );
        await http.post(
          Uri.parse(url),
          body: {'url': mediaUrl},
        );
      } catch (_) {}
    }
  }

  Future<void> _sendGenericCast(CastDevice device, String mediaUrl) async {
    final urls = <String>[
      'http://${device.host}:${device.port}/apps/YouTube',
      'http://${device.host}:${device.port}/',
      'http://${device.host}:8008/apps/YouTube',
      'http://${device.host}:8008/',
    ];

    final body =
        '<?xml version="1.0" encoding="utf-8"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        '<s:Body>'
        '<u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">'
        '<InstanceID>0</InstanceID>'
        '<CurrentURI>$mediaUrl</CurrentURI>'
        '<CurrentURIMetaData></CurrentURIMetaData>'
        '</u:SetAVTransportURI>'
        '</s:Body>'
        '</s:Envelope>';

    for (var url in urls) {
      try {
        await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'text/xml; charset="utf-8"',
            'SOAPACTION': '"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI"',
          },
          body: body,
        );
        await http.post(
          Uri.parse(url),
          body: {'url': mediaUrl},
        );
      } catch (_) {}
    }
  }

  Future<void> stopCasting() async {
    await CastProxyServer.stopProxy();
    connectedDevice.value = null;
    isCasting.value = false;
  }

  @override
  void onClose() {
    _udpSocket?.close();
    CastProxyServer.stopProxy();
    super.onClose();
  }
}
