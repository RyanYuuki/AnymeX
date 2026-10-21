import 'dart:math';
import 'dart:typed_data';

import 'package:rhttp/rhttp.dart';

class DnsManager {
  static Future<List<String>> resolveWithDoh(
    String host,
    String dnsUrl, {
    List<String> bootstrapIps = const [],
  }) async {
    final query = _buildDnsQuery(host);
    final dnsHost = Uri.parse(dnsUrl).host;

    Object? lastError;
    for (final url in [
      dnsUrl,
      ...bootstrapIps.map((ip) => _withHost(dnsUrl, ip)),
    ]) {
      try {
        final res = await Rhttp.requestBytes(
          method: HttpMethod.post,
          url: url,
          headers: HttpHeaders.map({
            HttpHeaderName.contentType: 'application/dns-message',
            HttpHeaderName.accept: 'application/dns-message',
            if (url != dnsUrl) HttpHeaderName.host: dnsHost,
          }),
          body: HttpBody.bytes(query),
        );

        final bytes = res.body;
        if (bytes.isEmpty) {
          throw Exception('Empty DoH response');
        }

        final answers = _parseDnsResponse(bytes);
        if (answers.isEmpty) {
          throw Exception('No A records for $host');
        }

        return answers;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('No A records for $host');
  }

  static String _withHost(String url, String ip) =>
      Uri.parse(url).replace(host: ip).toString();

  static List<String> _parseDnsResponse(Uint8List data) {
    int offset = 12;

    while (data[offset] != 0) {
      offset += data[offset] + 1;
    }
    offset += 5;

    final results = <String>[];

    while (offset < data.length) {
      if ((data[offset] & 0xC0) == 0xC0) {
        offset += 2;
      } else {
        while (data[offset] != 0) {
          offset += data[offset] + 1;
        }
        offset++;
      }

      final type = (data[offset] << 8) | data[offset + 1];
      offset += 8;
      final rdLength = (data[offset] << 8) | data[offset + 1];
      offset += 2;

      if (type == 1 && rdLength == 4) {
        results.add(
          '${data[offset]}.${data[offset + 1]}.${data[offset + 2]}.${data[offset + 3]}',
        );
      }

      offset += rdLength;
    }

    return results;
  }

  static Uint8List _buildDnsQuery(String host) {
    final rand = Random.secure();
    final bytes = BytesBuilder();

    bytes.add([
      rand.nextInt(256), rand.nextInt(256),
      0x01, 0x00,
      0x00, 0x01,
      0x00, 0x00,
      0x00, 0x00,
      0x00, 0x00,
    ]);

    for (final label in host.split('.')) {
      bytes.add([label.length]);
      bytes.add(label.codeUnits);
    }
    bytes.add([0x00]);
    bytes.add([0x00, 0x01]);
    bytes.add([0x00, 0x01]);

    return bytes.toBytes();
  }
}

enum DohProvider {
  cloudflare('Cloudflare', 'https://cloudflare-dns.com/dns-query', ['1.1.1.1', '1.0.0.1']),
  google('Google', 'https://dns.google/dns-query', ['8.8.8.8', '8.8.4.4']),
  adguard('AdGuard', 'https://dns-unfiltered.adguard.com/dns-query', ['94.140.14.140', '94.140.14.141']),
  quad9('Quad9', 'https://dns.quad9.net/dns-query', ['9.9.9.9', '149.112.112.112']),
  alidns('AliDNS', 'https://dns.alidns.com/dns-query', ['223.5.5.5', '223.6.6.6']),
  dnspod('DNSPod', 'https://doh.pub/dns-query', ['1.12.12.12', '120.53.53.53']),
  dns360('360', 'https://doh.360.cn/dns-query'),
  quad101('Quad 101', 'https://dns.twnic.tw/dns-query', ['101.101.101.101', '101.102.103.104']),
  mullvad('Mullvad', 'https://doh.mullvad.net/dns-query', ['194.242.2.2']),
  controld('Control D', 'https://freedns.controld.com/p0', ['76.76.2.0', '76.76.10.0']),
  njalla('Njalla', 'https://dns.njal.la/dns-query'),
  shecan('Shecan', 'https://free.shecan.ir/dns-query'),
  libredns('LibreDNS', 'https://doh.libredns.gr/dns-query');

  const DohProvider(this.displayName, this.url, [this.bootstrapIps = const []]);
  final String displayName;
  final String url;
  final List<String> bootstrapIps;

  static DohProvider? forUrl(String url) {
    for (final p in values) {
      if (p.url == url) return p;
    }
    return null;
  }
}
