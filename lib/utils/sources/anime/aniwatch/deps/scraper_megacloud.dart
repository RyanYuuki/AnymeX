import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class MegaCloud {
  final String _serverName = 'megacloud';
  final Map<String, String> _megacloud = {
    'script': 'https://megacloud.tv/js/player/a/prod/e1-player.min.js?v=',
    'sources': 'https://megacloud.tv/embed-2/ajax/e-1/getSources?id=',
  };

  Future<dynamic> extract(Uri videoUrl) async {
    try {
      Map<String, dynamic> extractedData = {
        'tracks': [],
        'intro': {'start': 0, 'end': 0},
        'outro': {'start': 0, 'end': 0},
        'sources': [],
      };

      String? videoId = videoUrl.pathSegments.last.split('?').first;
      final response = await http.get(
        Uri.parse(_megacloud['sources']! + (videoId)),
        headers: {
          'Accept': '*/*',
          'X-Requested-With': 'XMLHttpRequest',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36',
          'Referer': videoUrl.toString(),
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Url may have an invalid video id');
      }

      final srcsData = json.decode(response.body);

      if (!srcsData['encrypted'] && srcsData['sources'] is List) {
        extractedData['intro'] = srcsData['intro'];
        extractedData['outro'] = srcsData['outro'];
        extractedData['tracks'] = srcsData['tracks'];
        extractedData['sources'] = (srcsData['sources'] as List)
            .map((s) => {
                  'url': s['file'],
                  'type': s['type'],
                })
            .toList();

        return extractedData;
      }

      final scriptResponse = await http.get(Uri.parse(_megacloud['script']! +
          DateTime.now().millisecondsSinceEpoch.toString()));

      if (scriptResponse.statusCode != 200) {
        throw Exception("Couldn't fetch script to decrypt resource");
      }

      String text = scriptResponse.body;
      List<List<int>> vars = _extractVariables(text);
      if (vars.isEmpty) {
        throw Exception(
            "Can't find variables. Perhaps the extractor is outdated.");
      }

      final secretData = _getSecret(srcsData['sources'], vars);
      final decrypted =
          _decrypt(secretData['encryptedSource']!, secretData['secret']!);

      try {
        final sources = json.decode(decrypted);
        extractedData['intro'] = srcsData['intro'];
        extractedData['outro'] = srcsData['outro'];
        extractedData['tracks'] = srcsData['tracks'];
        extractedData['sources'] = (sources as List)
            .map((s) => {
                  'url': s['file'],
                  'type': s['type'],
                })
            .toList();

        return extractedData;
      } catch (error) {
        throw Exception('Failed to decrypt resource');
      }
    } catch (err) {
      log('Error in MegaCloud extract: $err');
      rethrow;
    }
  }

  List<List<int>> _extractVariables(String text) {
    final regex = RegExp(
        r'case\s*0x[0-9a-f]+:(?![^;]*=partKey)\s*\w+\s*=\s*(\w+)\s*,\s*\w+\s*=\s*(\w+);',
        multiLine: true);
    final matches = regex.allMatches(text);

    return matches
        .map((match) {
          final matchKey1 = _matchingKey(match.group(1)!, text);
          final matchKey2 = _matchingKey(match.group(2)!, text);
          try {
            return [
              int.parse(matchKey1, radix: 16),
              int.parse(matchKey2, radix: 16)
            ];
          } catch (e) {
            return <int>[];
          }
        })
        .where((pair) => pair.isNotEmpty)
        .toList();
  }

  Map<String, String> _getSecret(
      String encryptedString, List<List<int>> values) {
    String secret = '';
    String encryptedSource = '';
    List<String> encryptedSourceArray = encryptedString.split('');
    int currentIndex = 0;

    for (final index in values) {
      final start = index[0] + currentIndex;
      final end = start + index[1];

      for (int i = start; i < end; i++) {
        secret += encryptedString[i];
        encryptedSourceArray[i] = '';
      }
      currentIndex += index[1];
    }

    encryptedSource = encryptedSourceArray.join('');

    return {'secret': secret, 'encryptedSource': encryptedSource};
  }

  String _decrypt(String encrypted, String keyOrSecret) {
    final cypher = base64.decode(encrypted);
    final salt = cypher.sublist(8, 16);
    final password = Uint8List.fromList([...utf8.encode(keyOrSecret), ...salt]);
    final md5Hashes = List.generate(3, (_) => Uint8List(16));

    var digest = password;
    for (int i = 0; i < 3; i++) {
      md5Hashes[i] = Uint8List.fromList(md5.convert(digest).bytes);
      digest = Uint8List.fromList([...md5Hashes[i], ...password]);
    }

    final key = Uint8List.fromList([...md5Hashes[0], ...md5Hashes[1]]);
    final iv = md5Hashes[2];
    final contents = cypher.sublist(16);

    return _decryptAES(contents, key, iv);
  }

  String _decryptAES(Uint8List encrypted, Uint8List key, Uint8List iv) {
    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), iv));

    final paddedPlaintext = Uint8List(encrypted.length);
    var offset = 0;
    while (offset < encrypted.length) {
      offset += cipher.processBlock(encrypted, offset, paddedPlaintext, offset);
    }

    int padLength = paddedPlaintext.last;
    if (padLength > 0 && padLength <= 16) {
      for (int i = 1; i <= padLength; i++) {
        if (paddedPlaintext[paddedPlaintext.length - i] != padLength) {
          throw Exception('Invalid PKCS7 padding');
        }
      }
      final plaintext =
          paddedPlaintext.sublist(0, paddedPlaintext.length - padLength);
      return utf8.decode(plaintext);
    } else {
      throw Exception('Invalid PKCS7 padding length');
    }
  }

  String _matchingKey(String value, String script) {
    final regex = RegExp(',$value=((?:0x)?([0-9a-fA-F]+))');
    final match = regex.firstMatch(script);
    if (match != null) {
      return match.group(1)!.replaceFirst(RegExp(r'^0x'), '');
    } else {
      throw Exception('Failed to match the key');
    }
  }
}
