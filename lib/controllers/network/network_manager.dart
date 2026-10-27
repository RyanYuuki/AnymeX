import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:webview_all/webview_all.dart'
    hide CookieManager;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:rhttp/rhttp.dart';
import 'package:anymex_extension_runtime_bridge/AnymeXBridge.dart';
import 'package:anymex_extension_runtime_bridge/ExtensionBridge.dart';

import 'package:anymex/database/data_keys/keys.dart';

import 'anilist_interceptor.dart';
import 'cookie_manager.dart';
import 'dns_manager.dart';
import 'log_interceptor.dart';

class DelegatingHttpClient extends http.BaseClient {
  final NetworkManager _manager;
  DelegatingHttpClient(this._manager);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await _manager._compatibleClient.send(request);
    } on RhttpClientDisposedException {
      return await _manager._compatibleClient.send(request);
    }
  }

  @override
  void close() {}
}

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find<NetworkManager>();

  late RhttpClient _client;
  late RhttpCompatibleClient _compatibleClient;
  late final http.Client _delegatingClient = DelegatingHttpClient(this);

  RhttpClient get client => _client;

  http.Client get compatibleClient => _delegatingClient;
  RhttpCompatibleClient get rawCompatibleClient => _compatibleClient;

  String get userAgent {
    final custom = NetworkKeys.customUserAgent.get<String>('');
    return custom.isNotEmpty ? custom : defaultUserAgent;
  }

  String get defaultUserAgent {
    final fetched = NetworkKeys.fetchedUserAgent.get<String>('');
    return fetched.isNotEmpty ? fetched : _buildUserAgent();
  }

  String get dnsUrl {
    final custom = NetworkKeys.customDnsUrl.get<String>('');
    return custom.isNotEmpty ? custom : DohProvider.cloudflare.url;
  }

  String? get proxyUrl {
    final v = NetworkKeys.proxyUrl.get<String>('');
    return v.isEmpty ? null : v;
  }

  bool get verifyTls => NetworkKeys.verifyTls.get<bool>(false);

  @override
  void onInit() {
    _initClient();
    _captureWebViewUserAgent();
    super.onInit();
  }

  Future<void> _captureWebViewUserAgent() async {
    if (NetworkKeys.fetchedUserAgent.get<String>('').isNotEmpty) return;
    try {
      final ua = await WebViewController().getUserAgent();
      if (ua != null && ua.isNotEmpty) {
        NetworkKeys.fetchedUserAgent.set(ua);
        reinitialize();
        try {
          await AnymeXRuntimeBridge.setUserAgent('', ua);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Failed to extract default WebView user-agent: $e');
    }
  }

  final cookieManager = CookieManager();

  void reinitialize() {
    try {
      _compatibleClient.close();
      _client.dispose();
    } catch (_) {}
    _initClient();
    try {
      AnymeXExtensionBridge.updateHttpClient(_delegatingClient);
    } catch (_) {}
  }

  RhttpClient _initClient() {
    try {
      final dns = dnsUrl;
      final currentProxy = proxyUrl;

      final interceptors = [
        LogInterceptor(),
        cookieManager,
        AnilistInterceptor(),
      ];

      final clientSettings = ClientSettings(
        userAgent: userAgent,
        throwOnStatusCode: false,
        tlsSettings: TlsSettings(
          verifyCertificates: verifyTls,
        ),
        timeoutSettings: const TimeoutSettings(
          connectTimeout: Duration(seconds: 15),
          timeout: Duration(seconds: 30),
        ),
        dnsSettings: DnsSettings.dynamic(
          resolver: (host) async {
            try {
              return await DnsManager.resolveWithDoh(
                host,
                dns,
                bootstrapIps: DohProvider.forUrl(dns)?.bootstrapIps ?? const [],
              );
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
        proxySettings: currentProxy == null ? null : _buildProxySettings(currentProxy),
      );

      _client = RhttpClient.createSync(
        interceptors: interceptors,
        settings: clientSettings,
      );

      _compatibleClient = RhttpCompatibleClient.of(_client);

      return _client;
    } catch (_) {
      rethrow;
    }
  }

  static ProxySettings _buildProxySettings(String proxy) {
    if (!proxy.contains('://')) {
      return ProxySettings.proxy('http://$proxy');
    }
    return ProxySettings.proxy(proxy);
  }

  static String _buildUserAgent() {
    final platform = Platform.operatingSystem;
    final os = Platform.operatingSystemVersion.split(' ').first;
    final arch = Platform.version.split(' ').first;
    return 'AnymeX ($platform $os; $arch)';
  }

  @override
  void onClose() {
    _compatibleClient.close();
    _client.dispose();
    super.onClose();
  }
}
