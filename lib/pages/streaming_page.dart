import 'dart:convert';
import 'dart:developer';

import 'package:aurora/components/video_player.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StreamingPage extends StatefulWidget {
  final String? id;
  const StreamingPage({super.key, this.id});

  @override
  State<StreamingPage> createState() => _StreamingPageState();
}

class _StreamingPageState extends State<StreamingPage> {
  dynamic episodesData;
  dynamic episodeSrc;
  final String baseUrl = 'https://aniwatch-ryan.vercel.app/anime/episodes/';
  final String episodeUrl =
      'https://aniwatch-ryan.vercel.app/anime/episode-srcs?id=';

  @override
  void initState() {
    super.initState();
    FetchAnimeData();
  }

  Future<void> FetchAnimeData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl${widget.id}'));
      if (response.statusCode == 200) {
        final tempData = jsonDecode(response.body);
        setState(() {
          episodesData = tempData['episodes'];
        });
        final episodeSrcsResponse = await http
            .get(Uri.parse(episodeUrl + tempData['episodes'][0]['episodeId']));
        if (episodeSrcsResponse.statusCode == 200) {
          final episodeSrcs = jsonDecode(episodeSrcsResponse.body);
          setState(() {
            episodeSrc = episodeSrcs['sources'][0]['url'];
          });
        } else {
          throw Exception('Failed to load episode sources');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
      ),
      body: episodeSrc == null
          ? const Center(child: Text('Loading...'))
          : Column(
              children: [VideoPlayer(videoUrl: episodeSrc)],
            ),
    );
  }
}
