import 'dart:convert';
import 'dart:io';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';

class ListExporterPage extends StatefulWidget {
  final bool isManga;
  const ListExporterPage({super.key, required this.isManga});

  @override
  State<ListExporterPage> createState() => _ListExporterPageState();
}

class _ListExporterPageState extends State<ListExporterPage> {
  final serviceHandler = Get.find<ServiceHandler>();
  bool _isLoading = false;

  Future<String?> _getMalCsrfToken() async {
    try {
      final sessionId = AuthKeys.malSessionId.get<String?>();
      if (sessionId == null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Session Expired'),
              content: const Text('Your MAL session has expired. Please login again to export your list.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await serviceHandler.malService.login(context);
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          );
        }
        return null;
      }

      final response = await http.get(
        Uri.parse('https://myanimelist.net/'),
        headers: {
          'Cookie': 'MALHLOGSESSID=$sessionId',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
      );

      if (response.statusCode == 200) {
        final RegExp csrfRegex = RegExp(r'<meta[^>]*name="csrf_token"[^>]*content="([^"]+)"');
        final match = csrfRegex.firstMatch(response.body);
        return match?.group(1);
      }
    } catch (e) {
      Logger.i('Error fetching MAL CSRF token: $e');
    }
    return null;
  }

  Future<void> _exportMalList() async {
    final token = AuthKeys.malAuthToken.get<String?>();
    final sessionId = AuthKeys.malSessionId.get<String?>();
    
    if (token == null || sessionId == null) {
      throw Exception('Not properly logged into MyAnimeList. Please login again.');
    }

    final csrfToken = await _getMalCsrfToken();
    if (csrfToken == null) {
      throw Exception('Failed to get CSRF token. Please try logging in again.');
    }

    final response = await http.post(
      Uri.parse('https://myanimelist.net/panel.php?go=export2'),
      headers: {
        'Cookie': 'MALHLOGSESSID=$sessionId',
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
      body: {
        'type': widget.isManga ? '2' : '1',
        'subexport': 'Export My List',
        'csrf_token': csrfToken,
      },
    );

    if (response.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final fileName = '${serviceHandler.profileData.value.name}_${widget.isManga ? 'manga' : 'anime'}_list.xml';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(response.body, flush: true);
      
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Here is your exported ${widget.isManga ? "Manga" : "Anime"} list from MyAnimeList.',
      );
    } else if (response.statusCode == 403) {
      final body = response.body;
      if (body.contains('badresult')) {
        if (body.contains('Your username or password is incorrect')) {
          throw Exception('Invalid credentials. Please login again.');
        } else if (body.contains('Too many failed login attempts')) {
          throw Exception('Too many failed attempts. Please try again later.');
        }
      }
      throw Exception('Failed to export MAL list. Please try again.');
    } else {
      throw Exception('Failed to export MAL list: ${response.statusCode}');
    }
  }

  Future<void> _exportAnilistList() async {
    final token = AuthKeys.authToken.get<String?>();
    
    if (token == null) {
      throw Exception('Not logged into AniList');
    }

    final anilistAuth = Get.find<AnilistAuth>();
    
    if (widget.isManga) {
      await anilistAuth.fetchUserMangaList();
    } else {
      await anilistAuth.fetchUserAnimeList();
    }

    final trackedList = widget.isManga 
        ? anilistAuth.mangaList 
        : anilistAuth.animeList;

    if (trackedList.isEmpty) {
      throw Exception('No ${widget.isManga ? 'manga' : 'anime'} found in your list');
    }

    final xml = _convertAnilistToMalXml(trackedList, widget.isManga);
    
    final tempDir = await getTemporaryDirectory();
    final fileName = '${serviceHandler.profileData.value.name}_${widget.isManga ? 'manga' : 'anime'}_list.xml';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(xml, flush: true);
    
    await Share.shareXFiles(
      [XFile(file.path)], 
      text: 'Here is your exported ${widget.isManga ? "Manga" : "Anime"} list from AniList.',
    );
  }

  String _convertAnilistToMalXml(RxList<TrackedMedia> trackedList, bool isManga) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE myanimelist SYSTEM "myanimelist.dtd">');
    buffer.writeln('<myanimelist>');
    
    for (final entry in trackedList) {
      if (entry.id == null || entry.id!.isEmpty) continue;

      String malStatus;
      switch (entry.watchingStatus?.toUpperCase()) {
        case 'CURRENT':
          malStatus = isManga ? 'Reading' : 'Watching';
          break;
        case 'COMPLETED':
          malStatus = 'Completed';
          break;
        case 'PAUSED':
          malStatus = 'On-Hold';
          break;
        case 'DROPPED':
          malStatus = 'Dropped';
          break;
        case 'PLANNING':
        case 'PLAN_TO_WATCH':
        case 'PLAN_TO_READ':
          malStatus = isManga ? 'Plan to Read' : 'Plan to Watch';
          break;
        default:
          malStatus = isManga ? 'Reading' : 'Watching';
      }

      int malScore = 0;
      if (entry.userScore != null) {
        if (entry.userScore! <= 10) {
          malScore = entry.userScore!.round();
        } else {
          malScore = (entry.userScore! / 10).round();
        }
      } else if (entry.score != null) {
        final score = double.tryParse(entry.score!);
        if (score != null) {
          if (score <= 10) {
            malScore = score.round();
          } else {
            malScore = (score / 10).round();
          }
        }
      }

      malScore = malScore.clamp(0, 10);

      final totalEpisodes = isManga 
          ? (entry.chapterCount?.isNotEmpty == true ? entry.chapterCount : entry.totalEpisodes)
          : (entry.episodeCount?.isNotEmpty == true ? entry.episodeCount : entry.totalEpisodes);

      buffer.writeln('  <anime>');
      buffer.writeln('    <series_animedb_id>${_escapeXml(entry.id)}</series_animedb_id>');
      buffer.writeln('    <series_title>${_escapeXml(entry.title ?? 'Unknown')}</series_title>');
    
      if (entry.format != null && entry.format!.isNotEmpty) {
        buffer.writeln('    <series_type>${_escapeXml(_getMalFormat(entry.format!))}</series_type>');
      }
      
      buffer.writeln('    <series_episodes>${_escapeXml(totalEpisodes ?? '0')}</series_episodes>');
      buffer.writeln('    <my_watched_episodes>${entry.userProgress ?? 0}</my_watched_episodes>');
      buffer.writeln('    <my_score>$malScore</my_score>');
      buffer.writeln('    <my_status>${_escapeXml(malStatus)}</my_status>');
      
      if (entry.mediaListId != null) {
        buffer.writeln('    <my_id>${_escapeXml(entry.mediaListId)}</my_id>');
      }
      
      buffer.writeln('    <my_rewatching>0</my_rewatching>');
      buffer.writeln('    <my_rewatching_ep>0</my_rewatching_ep>');
      buffer.writeln('    <update_on_import>1</update_on_import>');
      buffer.writeln('  </anime>');
    }
    
    buffer.writeln('</myanimelist>');
    return buffer.toString();
  }

  String _getMalFormat(String format) {
    switch (format.toUpperCase()) {
      case 'TV':
        return 'TV';
      case 'TV_SHORT':
        return 'TV';
      case 'MOVIE':
        return 'Movie';
      case 'SPECIAL':
        return 'Special';
      case 'OVA':
        return 'OVA';
      case 'ONA':
        return 'ONA';
      case 'MUSIC':
        return 'Music';
      case 'MANGA':
        return 'Manga';
      case 'NOVEL':
        return 'Novel';
      case 'ONE_SHOT':
        return 'One Shot';
      default:
        return 'Unknown';
    }
  }

  String _escapeXml(String? text) {
    if (text == null) return '';
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<void> _exportList() async {
    if (!serviceHandler.isLoggedIn.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first to export your list")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (serviceHandler.serviceType.value == ServicesType.mal) {
        await _exportMalList();
      } else {
        await _exportAnilistList();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Export ready! Choose where to save it.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export Failed: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoggedIn = serviceHandler.isLoggedIn.value;
    final serviceType = serviceHandler.serviceType.value;
    final serviceName = serviceType == ServicesType.mal ? 'MyAnimeList' : 'AniList';

    return Glow(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          title: AnymexText(
            text: "${widget.isManga ? "Manga" : "Anime"} List Exporter",
            variant: TextVariant.bold,
            size: 18,
            color: colorScheme.primary,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexText(
                      text: isLoggedIn 
                          ? "Ready to export your $serviceName ${widget.isManga ? 'Manga' : 'Anime'} list?"
                          : "Please login to export your list",
                      variant: TextVariant.bold,
                      size: 18,
                      color: isLoggedIn ? colorScheme.primary : Colors.red,
                    ),
                    const SizedBox(height: 20),
                    if (isLoggedIn) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: serviceHandler.profileData.value.avatar != null
                                ? NetworkImage(serviceHandler.profileData.value.avatar!)
                                : null,
                            radius: 25,
                            child: serviceHandler.profileData.value.avatar == null
                                ? Text(serviceHandler.profileData.value.name?[0].toUpperCase() ?? '?')
                                : null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnymexText(
                                  text: serviceHandler.profileData.value.name ?? 'User',
                                  variant: TextVariant.bold,
                                  size: 16,
                                ),
                                const SizedBox(height: 5),
                                AnymexText(
                                  text: "Exporting your ${widget.isManga ? 'manga' : 'anime'} list...",
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: AnymexButton(
                  onTap: isLoggedIn ? _exportList : null,
                  radius: 100,
                  height: 55,
                  color: isLoggedIn ? null : Colors.grey,
                  child: _isLoading
                      ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             const Icon(HugeIcons.strokeRoundedDownload01, color: Colors.white),
                             const SizedBox(width: 10),
                             AnymexText(
                               text: "Export ${serviceType == ServicesType.mal ? 'MAL' : 'AniList'} XML",
                               variant: TextVariant.bold,
                               color: Colors.white,
                               size: 16,
                             ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
