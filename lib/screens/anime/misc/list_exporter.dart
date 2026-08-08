import 'dart:convert';
import 'dart:io';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anymex/database/data_keys/keys.dart';
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
  bool _updateOnImport = true;
  bool _roundUp = true;

  Future<String?> _exportMalList() async {
    final token = AuthKeys.malAuthToken.get<String?>();
    if (token == null || token.isEmpty) {
      throw Exception('Not logged into MyAnimeList. Please login again.');
    }

    if (widget.isManga) {
      await serviceHandler.malService.fetchUserMangaList();
    } else {
      await serviceHandler.malService.fetchUserAnimeList();
    }

    final trackedList = widget.isManga
        ? serviceHandler.malService.mangaList
        : serviceHandler.malService.animeList;

    if (trackedList.isEmpty) {
      throw Exception(
          'No ${widget.isManga ? 'manga' : 'anime'} found in your list');
    }

    final xml = _convertTrackedListToMalXml(trackedList, widget.isManga);
    return _saveExportXmlWithPicker(xml);
  }

  Future<String?> _exportAnilistList() async {
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

    final trackedList =
        widget.isManga ? anilistAuth.mangaList : anilistAuth.animeList;

    if (trackedList.isEmpty) {
      throw Exception(
          'No ${widget.isManga ? 'manga' : 'anime'} found in your list');
    }

    final xml = _convertTrackedListToMalXml(trackedList, widget.isManga);
    return _saveExportXmlWithPicker(xml);
  }

  String _convertTrackedListToMalXml(
      Iterable<TrackedMedia> trackedList, bool isManga) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE myanimelist SYSTEM "myanimelist.dtd">');
    buffer.writeln('<myanimelist>');

    for (final entry in trackedList) {
      final exportId = entry.servicesType == ServicesType.anilist
          ? entry.idMal
          : (entry.idMal ?? entry.id);
      if (exportId == null || exportId.isEmpty) continue;

      final malStatus =
          _mapStatusToMalExport(entry.watchingStatus, isManga: isManga);
      final malScore = _normalizeScore(entry);
      final progress = _resolveProgress(entry, isManga: isManga);
      final totalCount = isManga
          ? (_parseInt(entry.totalEpisodes) ??
              (entry.servicesType == ServicesType.anilist
                  ? _parseInt(entry.chapterCount)
                  : null) ??
              0)
          : (_parseInt(entry.totalEpisodes) ?? 0);
      final updateOnImportValue = _updateOnImport ? '1' : '0';

      if (isManga) {
        buffer.writeln('  <manga>');
        buffer.writeln(
            '    <manga_mangadb_id>${_escapeXml(exportId)}</manga_mangadb_id>');
        buffer.writeln(
            '    <manga_title>${_escapeXml(entry.title ?? 'Unknown')}</manga_title>');
        buffer.writeln('    <manga_chapters>$totalCount</manga_chapters>');
        buffer.writeln('    <my_read_chapters>$progress</my_read_chapters>');
        buffer.writeln('    <my_score>$malScore</my_score>');
        buffer.writeln('    <my_status>${_escapeXml(malStatus)}</my_status>');
        buffer.writeln(
            '    <update_on_import>$updateOnImportValue</update_on_import>');
        buffer.writeln('  </manga>');
        continue;
      }

      buffer.writeln('  <anime>');
      buffer.writeln(
          '    <series_animedb_id>${_escapeXml(exportId)}</series_animedb_id>');
      buffer.writeln(
          '    <series_title>${_escapeXml(entry.title ?? 'Unknown')}</series_title>');

      if (entry.format != null && entry.format!.isNotEmpty) {
        buffer.writeln(
            '    <series_type>${_escapeXml(_getMalFormat(entry.format!))}</series_type>');
      }

      buffer.writeln('    <series_episodes>$totalCount</series_episodes>');
      buffer
          .writeln('    <my_watched_episodes>$progress</my_watched_episodes>');
      buffer.writeln('    <my_score>$malScore</my_score>');
      buffer.writeln('    <my_status>${_escapeXml(malStatus)}</my_status>');

      if (entry.mediaListId != null) {
        buffer.writeln('    <my_id>${_escapeXml(entry.mediaListId)}</my_id>');
      }

      buffer.writeln('    <my_rewatching>0</my_rewatching>');
      buffer.writeln('    <my_rewatching_ep>0</my_rewatching_ep>');
      buffer.writeln(
          '    <update_on_import>$updateOnImportValue</update_on_import>');
      buffer.writeln('  </anime>');
    }

    buffer.writeln('</myanimelist>');
    return buffer.toString();
  }

  String _mapStatusToMalExport(String? status, {required bool isManga}) {
    switch (status?.toUpperCase().trim()) {
      case 'CURRENT':
        return isManga ? 'Reading' : 'Watching';
      case 'COMPLETED':
        return 'Completed';
      case 'PAUSED':
        return 'On-Hold';
      case 'DROPPED':
        return 'Dropped';
      case 'PLANNING':
      case 'PLAN_TO_WATCH':
      case 'PLAN_TO_READ':
        return isManga ? 'Plan to Read' : 'Plan to Watch';
      default:
        return isManga ? 'Reading' : 'Watching';
    }
  }

  int _normalizeScore(TrackedMedia entry) {
    final isAnilist = serviceHandler.serviceType.value != ServicesType.mal;

    if (entry.userScore != null) {
      final score = entry.userScore!;
      final normalized = score <= 10 ? score.toDouble() : score / 10;
      return isAnilist
          ? (_roundUp ? normalized.ceil() : normalized.floor()).clamp(0, 10)
          : normalized.round().clamp(0, 10);
    }

    final parsed = double.tryParse(entry.score ?? '');
    if (parsed == null) return 0;
    final normalized = parsed <= 10 ? parsed : parsed / 10;
    return isAnilist
        ? (_roundUp ? normalized.ceil() : normalized.floor()).clamp(0, 10)
        : normalized.round().clamp(0, 10);
  }

  int _resolveProgress(TrackedMedia entry, {required bool isManga}) {
    if (entry.userProgress != null && entry.userProgress! >= 0) {
      return entry.userProgress!;
    }

    if (isManga) {
      return _parseInt(entry.episodeCount) ??
          _parseInt(entry.chapterCount) ??
          0;
    }

    return _parseInt(entry.episodeCount) ?? 0;
  }

  int? _parseInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value.trim());
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

  Future<String?> _saveExportXmlWithPicker(String xml) async {
    final userName = _sanitizeFileName(serviceHandler.profileData.value.name);
    final fileName =
        '${userName}_${widget.isManga ? 'manga' : 'anime'}_list.xml';

    if (Platform.isAndroid || Platform.isIOS) {
      return await FilePicker.platform.saveFile(
        dialogTitle: 'Save Export XML',
        fileName: fileName,
        bytes: utf8.encode(xml),
        type: FileType.custom,
        allowedExtensions: ['xml'],
      );
    }

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Export XML',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );

    if (outputPath == null || outputPath.isEmpty) {
      return null;
    }

    final finalPath = outputPath.toLowerCase().endsWith('.xml')
        ? outputPath
        : '$outputPath.xml';
    final output = File(finalPath);
    await output.writeAsString(xml, flush: true);

    return output.path;
  }

  String _sanitizeFileName(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'user';

    final cleaned = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'user' : cleaned;
  }

  Future<void> _exportList() async {
    if (!serviceHandler.isLoggedIn.value) {
      errorSnackBar('Please login first to export your list.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final savedPath = serviceHandler.serviceType.value == ServicesType.mal
          ? await _exportMalList()
          : await _exportAnilistList();
      if (savedPath == null || savedPath.isEmpty) {
        infoSnackBar('Export cancelled.');
        return;
      }

      if (serviceHandler.serviceType.value == ServicesType.mal) {
        successSnackBar('MAL list exported to:\n$savedPath', duration: 5000);
      } else {
        successSnackBar('AniList XML exported to:\n$savedPath', duration: 5000);
      }
    } catch (e) {
      errorSnackBar("Export failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnymexText(
                text: title,
                variant: TextVariant.semiBold,
                size: 15,
              ),
              const SizedBox(height: 3),
              AnymexText(
                text: subtitle,
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: colorScheme.primary,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final colorScheme = Theme.of(context).colorScheme;
      final isLoggedIn = serviceHandler.isLoggedIn.value;
      final serviceType = serviceHandler.serviceType.value;
      final serviceName =
          serviceType == ServicesType.mal ? 'MyAnimeList' : 'AniList';
      final isAnilist = serviceType != ServicesType.mal;

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
                              backgroundImage: serviceHandler
                                          .profileData.value.avatar !=
                                      null
                                  ? NetworkImage(
                                      serviceHandler.profileData.value.avatar!)
                                  : null,
                              radius: 25,
                              child: serviceHandler.profileData.value.avatar ==
                                      null
                                  ? Text(serviceHandler
                                          .profileData.value.name?[0]
                                          .toUpperCase() ??
                                      '?')
                                  : null,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnymexText(
                                    text:
                                        serviceHandler.profileData.value.name ??
                                            'User',
                                    variant: TextVariant.bold,
                                    size: 16,
                                  ),
                                  const SizedBox(height: 5),
                                  AnymexText(
                                    text:
                                        "Exporting your ${widget.isManga ? 'manga' : 'anime'} list...",
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
                        text: "Export Settings",
                        variant: TextVariant.bold,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      _buildSettingsTile(
                        title: "Update on Import",
                        subtitle:
                            "Automatically update entries when importing the XML",
                        value: _updateOnImport,
                        onChanged: (val) =>
                            setState(() => _updateOnImport = val),
                      ),
                      if (isAnilist) ...[
                        const SizedBox(height: 12),
                        Divider(
                          color: colorScheme.outlineVariant.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsTile(
                          title: "Round Up Scores",
                          subtitle: _roundUp
                              ? "Scores will be rounded up (e.g. 7.5 → 8)"
                              : "Scores will be rounded down (e.g. 7.5 → 7)",
                          value: _roundUp,
                          onChanged: (val) => setState(() => _roundUp = val),
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
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(HugeIcons.strokeRoundedDownload01,
                                  color: Colors.white),
                              const SizedBox(width: 10),
                              AnymexText(
                                text:
                                    "Export ${serviceType == ServicesType.mal ? 'MAL' : 'AniList'} XML",
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
    });
  }
}
