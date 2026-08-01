import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rhttp/rhttp.dart';

import 'cookie_manager.dart';
import 'dns_manager.dart';
import 'log_interceptor.dart';

class NetworkManager extends GetxController {
  final String _userAgent = _buildUserAgent();
  late RhttpClient _client;

  RhttpClient get client => _client;

  RhttpCompatibleClient get compatibleClient =>
      RhttpCompatibleClient.of(_client);

  @override
  void onInit() {
    _initClient();
    super.onInit();
  }

  final cookieManager = CookieManager();

  RhttpClient _initClient() {
    try {
      var dns = DohProvider.cloudflare.url;

      var interceptors = [LogInterceptor(), cookieManager];

      var clientSettings = ClientSettings(
        userAgent: _userAgent,
        throwOnStatusCode: false,
        tlsSettings: const TlsSettings(
          verifyCertificates: false,
        ),
        timeoutSettings: const TimeoutSettings(
          connectTimeout: Duration(seconds: 15),
          timeout: Duration(seconds: 30),
        ),
        dnsSettings: DnsSettings.dynamic(
          resolver: (host) async {
            try {
              return await DnsManager.resolveWithDoh(host, dns);
            } catch (e) {
              debugPrint('DoH failed for $host → fallback');

              try {
                final res = await InternetAddress.lookup(host);

                return res.map((e) => e.address).toList();
              } catch (e) {
                debugPrint('Fallback DNS failed for $host');
                return [];
              }
            }
          },
        ),
      );

      _client = RhttpClient.createSync(
        interceptors: interceptors,
        settings: clientSettings,
      );

      return _client;
    } catch (_) {
      rethrow;
    }
  }

  static String _buildUserAgent() {
    final platform = Platform.operatingSystem;
    final os = Platform.operatingSystemVersion.split(' ').first;
    final arch = Platform.version.split(' ').first;
    return 'AnymeX ($platform $os; $arch)';
  }

  @override
  void onClose() {
    _client.dispose();
    super.onClose();
  }
}
