import 'dart:convert';
import 'dart:io';

import 'package:anymex/models/sauce/sauce_result.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class SauceFinder {
  /// Pick an image using the gallery
  static Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  /// Send image to trace.moe and get sauce result
  static Future<SauceResult?> findSauce(File imageFile) async {
    final url = Uri.parse('https://api.trace.moe/search?cutBorders=true');

    try {
      final request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonData = json.decode(respStr);

        if (jsonData['result'] != null && jsonData['result'].isNotEmpty) {
          return SauceResult.fromJson(jsonData['result'][0]);
        } else {
          throw Exception("No result found in response.");
        }
      } else {
        throw HttpException(
          "Trace.moe request failed with status: ${response.statusCode}",
        );
      }
    } catch (e) {
      print('Error in findSauce: $e');
      return null;
    }
  }
}
