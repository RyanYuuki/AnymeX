import 'dart:convert';
import 'dart:io';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
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

enum ExportService { anilist, mal }

class ListExporterPage extends StatefulWidget {
  final bool isManga;
  const ListExporterPage({super.key, required this.isManga});

  @override
  State<ListExporterPage> createState() => _ListExporterPageState();
}

class _ListExporterPageState extends State<ListExporterPage> {
  final serviceHandler = Get.find<ServiceHandler>();
  final TextEditingController _usernameController = TextEditingController();
  
  ExportService _selectedService = ExportService.anilist;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoFillDetails();
  }

  void _autoFillDetails() {
    if (serviceHandler.isLoggedIn.value) {
      final currentService = serviceHandler.serviceType.value;
      
      if (currentService == ServicesType.mal) {
        _selectedService = ExportService.mal;
      } else {
        _selectedService = ExportService.anilist;
      }

      if (serviceHandler.profileData.value.name != null) {
        _usernameController.text = serviceHandler.profileData.value.name!;
      }
    }
  }

  Future<String?> _getMalCsrfToken() async {
    try {
      final response = await http.get(
        Uri.parse('https://myanimelist.net/panel.php?go=export'),
        headers: {
          'Cookie': 'MALHLOGSESSID=${AuthKeys.malSessionId.get<String?>() ?? ''}',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
      );

      if (response.statusCode == 200) {
        final RegExp tokenRegex = RegExp(r'name="csrf_token" value="([^"]+)"');
        final match = tokenRegex.firstMatch(response.body);
        return match?.group(1);
      }
    } catch (e) {
      Logger.i('Error fetching MAL CSRF token: $e');
    }
    return null;
  }

  Future<void> _exportMalList() async {
    final token = AuthKeys.malAuthToken.get<String?>();
    
    if (token == null) {
      throw Exception('Not logged into MyAnimeList');
    }

    final csrfToken = await _getMalCsrfToken();
    if (csrfToken == null) {
      throw Exception('Failed to get CSRF token');
    }

    final response = await http.post(
      Uri.parse('https://myanimelist.net/panel.php?go=export2'),
      headers: {
        'Cookie': 'MALHLOGSESSID=${AuthKeys.malSessionId.get<String?>() ?? ''}',
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
      await file.writeAsString(response.body);
      
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Here is your exported ${widget.isManga ? "Manga" : "Anime"} list from MyAnimeList.',
      );
    } else {
      throw Exception('Failed to export MAL list: ${response.statusCode}');
    }
  }

  Future<void> _exportAnilistList() async {
    final token = AuthKeys.authToken.get<String?>();
    
    if (token == null) {
      throw Exception('Not logged into AniList');
    }

    final userId = serviceHandler.profileData.value.id;
    if (userId == null) {
      throw Exception('Could not get user ID');
    }

    final query = '''
    query(\$userId: Int, \$type: MediaType) {
      MediaListCollection(userId: \$userId, type: \$type) {
        lists {
          name
          entries {
            media {
              id
              idMal
              title {
                romaji
                english
                native
              }
              format
              episodes
              chapters
              volumes
              status
              averageScore
              coverImage {
                large
              }
              startDate {
                year
                month
                day
              }
              endDate {
                year
                month
                day
              }
            }
            progress
            progressVolumes
            status
            score
            startedAt {
              year
              month
              day
            }
            completedAt {
              year
              month
              day
            }
            updatedAt
            createdAt
          }
        }
      }
    }
    ''';

    final response = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'query': query,
        'variables': {
          'userId': int.parse(userId),
          'type': widget.isManga ? 'MANGA' : 'ANIME',
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      final xml = _convertAnilistToXml(data['data']['MediaListCollection'], widget.isManga);
      
      final tempDir = await getTemporaryDirectory();
      final fileName = '${serviceHandler.profileData.value.name}_${widget.isManga ? 'manga' : 'anime'}_list.xml';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(xml);
      
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Here is your exported ${widget.isManga ? "Manga" : "Anime"} list from AniList.',
      );
    } else {
      throw Exception('Failed to fetch AniList: ${response.statusCode}');
    }
  }

  String _convertAnilistToXml(Map<String, dynamic> data, bool isManga) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<myanimelist>');
    
    final lists = data['lists'] as List<dynamic>? ?? [];
    
    for (final list in lists) {
      final entries = list['entries'] as List<dynamic>? ?? [];
      for (final entry in entries) {
        final media = entry['media'];
        final myStatus = entry['status'];
        
        String malStatus;
        switch (myStatus) {
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
            malStatus = isManga ? 'Plan to Read' : 'Plan to Watch';
            break;
          default:
            malStatus = isManga ? 'Reading' : 'Watching';
        }

        buffer.writeln('  <anime>');
        buffer.writeln('    <series_animedb_id>${media['idMal'] ?? media['id']}</series_animedb_id>');
        buffer.writeln('    <series_title>${_escapeXml(media['title']['english'] ?? media['title']['romaji'] ?? media['title']['native'])}</series_title>');
        buffer.writeln('    <series_type>${_getFormat(media['format'])}</series_type>');
        buffer.writeln('    <series_episodes>${isManga ? (media['chapters'] ?? 0) : (media['episodes'] ?? 0)}</series_episodes>');
        buffer.writeln('    <my_id>${media['id']}</my_id>');
        buffer.writeln('    <my_watched_episodes>${entry['progress'] ?? 0}</my_watched_episodes>');
        buffer.writeln('    <my_start_date>${_formatDate(entry['startedAt'])}</my_start_date>');
        buffer.writeln('    <my_finish_date>${_formatDate(entry['completedAt'])}</my_finish_date>');
        buffer.writeln('    <my_score>${entry['score']?.round() ?? 0}</my_score>');
        buffer.writeln('    <my_status>$malStatus</my_status>');
        buffer.writeln('    <my_rewatching>0</my_rewatching>');
        buffer.writeln('    <my_rewatching_ep>0</my_rewatching_ep>');
        buffer.writeln('    <update_on_import>1</update_on_import>');
        buffer.writeln('  </anime>');
      }
    }
    
    buffer.writeln('</myanimelist>');
    return buffer.toString();
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

  String _getFormat(String? format) {
    switch (format) {
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

  String _formatDate(Map<String, dynamic>? date) {
    if (date == null) return '0000-00-00';
    final year = date['year']?.toString() ?? '0000';
    final month = date['month']?.toString().padLeft(2, '0') ?? '00';
    final day = date['day']?.toString().padLeft(2, '0') ?? '00';
    return '$year-$month-$day';
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
      if (_selectedService == ExportService.mal) {
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
                    const AnymexText(
                      text: "Select Source",
                      variant: TextVariant.bold,
                      size: 16,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _buildRadio(ExportService.anilist, "AniList"),
                        const SizedBox(width: 15),
                        _buildRadio(ExportService.mal, "MyAnimeList"),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const AnymexText(
                      text: "Username",
                      variant: TextVariant.bold,
                      size: 16,
                    ),
                    const SizedBox(height: 10),
                    AbsorbPointer(
                      absorbing: true,
                      child: CustomSearchBar(
                        controller: _usernameController,
                        hintText: serviceHandler.profileData.value.name ?? "Enter username",
                        disableIcons: true,
                        onSubmitted: (_) {},
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!isLoggedIn)
                      const AnymexText(
                        text: "Note: Please login first to export your list.",
                        size: 12,
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      )
                    else
                      const AnymexText(
                        text: "Note: Your list will be exported from your account.",
                        size: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
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
                               text: "Export ${_selectedService == ExportService.anilist ? 'AniList' : 'MAL'} XML",
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

  Widget _buildRadio(ExportService value, String label) {
    final isSelected = _selectedService == value;
    final colorScheme = Theme.of(context).colorScheme;
    final isLoggedIn = serviceHandler.isLoggedIn.value;

    bool isAvailable = true;
    if (value == ExportService.mal) {
      isAvailable = serviceHandler.serviceType.value == ServicesType.mal && isLoggedIn;
    } else {
      isAvailable = serviceHandler.serviceType.value == ServicesType.anilist && isLoggedIn;
    }

    return Expanded(
      child: GestureDetector(
        onTap: isAvailable ? () => setState(() => _selectedService = value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? colorScheme.primary 
                  : colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Center(
            child: AnymexText(
              text: label,
              variant: TextVariant.semiBold,
              color: isSelected ? Colors.white : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
