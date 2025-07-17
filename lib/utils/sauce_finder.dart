import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class SauceFinder {
  File? _imageFile;
  Map<String, dynamic>? _animeData;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      _animeData = null;
      await searchAnime(_imageFile!);
    }
  }

  Future<void> searchAnime(File imageFile) async {
    final url = Uri.parse('https://api.trace.moe/search');
    final request = http.MultipartRequest('POST', url);
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonData = json.decode(respStr);

      _animeData = jsonData['result'][0];
    } else {
      // Handle error
      throw Exception('Failed to search: ${response.statusCode}');
    }

    if (_animeData != null) {
      final regex = RegExp(r'\] (.*?) - ');

      final anilist_id = _animeData!['anilist'] ?? 0;
      final title = _animeData!['filename'] ?? 'Unknown';
      final name = regex.firstMatch(title)!.group(1) ?? 'Unknown';
      final episode = _animeData!['episode'] ?? 'N/A';
      final similarity = (_animeData!['similarity'] * 100).toStringAsFixed(2);
    }
  }
}
