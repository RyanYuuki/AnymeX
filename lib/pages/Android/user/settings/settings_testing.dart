import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TestingPage extends StatefulWidget {
  const TestingPage({super.key});

  @override
  State<TestingPage> createState() => _TestingPageState();
}

class _TestingPageState extends State<TestingPage> {
  Future<Uint8List?> fetchChapterImage() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse(
            'https://mn2.mkklcdnv6temp.com/img/tab_27/05/08/93/yp1002250/chapter_7/6-1730000382-o.webp'),
      );
      request.headers.add('Referer', 'https://chapmanganato.to/');

      final response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        return await consolidateHttpClientResponseBytes(response);
      } else {
        log('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching image: $e');
    } finally {
      client.close();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Uint8List?>(
        future: fetchChapterImage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Failed to load image'));
          } else {
            return Image.memory(
              snapshot.data!,
              width: double.infinity,
              fit: BoxFit.cover,
            );
          }
        },
      ),
    );
  }
}
