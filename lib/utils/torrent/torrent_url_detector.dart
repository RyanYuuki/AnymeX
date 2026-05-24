bool isTorrentUrl(String url) {
  if (url.isEmpty) return false;
  if (url.trimLeft().startsWith('magnet:')) return true;
  final lower = url.toLowerCase().split('?').first;
  if (lower.endsWith('.torrent')) return true;
  return false;
}

String getMagnetName(String magnet) {
  final dnMatch = RegExp(r'[?&]dn=([^&]+)').firstMatch(magnet);
  if (dnMatch != null) {
    return Uri.decodeComponent(dnMatch.group(1)!);
  }
  return 'Torrent';
}

String? extractInfoHash(String magnet) {
  final hexMatch = RegExp(r'btih:([a-fA-F0-9]{40})').firstMatch(magnet);
  if (hexMatch != null) return hexMatch.group(1)!.toLowerCase();
  final b32Match = RegExp(r'btih:([A-Z2-7]{32})', caseSensitive: false)
      .firstMatch(magnet);
  if (b32Match != null) return b32Match.group(1)!.toLowerCase();
  return null;
}
