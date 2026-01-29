import 'dart:convert';

import 'package:anymex/utils/logger.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DubService {
  static const String animeScheduleUrl = 'https://animeschedule.net/';
  static const String liveChartUrl = 'https://www.livechart.me/streams/';
  static const String kuroiruUrl = 'https://kuroiru.co/api/anime';

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  };

  static Future<Map<String, DubAnimeInfo>> fetchDubSources() async {
    final Map<String, DubAnimeInfo> dubMap = {};

    try {
      final lcResponse =
          await http.get(Uri.parse(liveChartUrl), headers: _headers);
      if (lcResponse.statusCode == 200) {
        var document = html_parser.parse(lcResponse.body);

        var streamLists =
            document.querySelectorAll('div[data-controller="stream-list"]');

        for (var list in streamLists) {
          var titleEl = list.querySelector('.grouped-list-heading-title');
          String serviceName = titleEl?.text.trim() ?? "Unknown";

          var imgEl = list.querySelector('.grouped-list-heading-icon img');
          String? serviceIcon = imgEl?.attributes['src'];
          if (serviceIcon != null && serviceIcon.startsWith('/')) {
            serviceIcon = 'https://u.livechart.me$serviceIcon';
          }

          var animeItems = list.querySelectorAll('li.grouped-list-item');

          for (var item in animeItems) {
            String title = item.attributes['data-title'] ?? "";
            var infoDiv = item.querySelector('.info.text-italic');
            String infoText = infoDiv?.text ?? "";

            var linkEl = item.querySelector('a.anime-item__action-button');
            String url = linkEl?.attributes['href'] ?? "";

            if (title.isNotEmpty && infoText.contains("Dub")) {
              String normalizedTitle = _normalizeTitle(title);

              if (!dubMap.containsKey(normalizedTitle)) {
                dubMap[normalizedTitle] = DubAnimeInfo(
                  normalizedTitle: normalizedTitle,
                  streams: [],
                );
              }

              if (!dubMap[normalizedTitle]!
                  .streams
                  .any((e) => e.name == serviceName)) {
                dubMap[normalizedTitle]!.streams.add(StreamingService(
                      name: serviceName,
                      url: url,
                      icon: serviceIcon ?? '',
                    ));
              }
            }
          }
        }
      }

      final asResponse = await http.get(Uri.parse(animeScheduleUrl), headers: {
        ..._headers,
        "Cookie":
            "as_cachedBaseCSS=baseMobile-c234a32dbf.min.css; as_timetableSettingsTimeFormat=24; as_timetableSettingsLayoutMode=large-tile; as_timetableSettingsVisible=false; as_timetableSettingsHideRaw=dub; as_timetableSettingsHideSub=dub; as_timetableSettingsAirTime=dub"
      });
      if (asResponse.statusCode == 200) {
        var document = html_parser.parse(asResponse.body);

        var columns = document.querySelectorAll('.timetable-column');

        for (var column in columns) {
          var dateEl = column.querySelector('.timetable-column-date-format');
          var dayEl = column.querySelector('.timetable-column-day');

          String? dateText = dateEl?.text.trim();
          String? dayText = dayEl?.text.trim();

          DateTime? columnDate;
          if (dateText != null && dateText.isNotEmpty) {
            try {
              columnDate = DateFormat('dd MMM').parse(dateText);
              int currentYear = DateTime.now().year;
              columnDate = DateTime(
                currentYear,
                columnDate.month,
                columnDate.day,
              );

              if (columnDate.isBefore(
                  DateTime.now().subtract(const Duration(days: 180)))) {
                columnDate = DateTime(
                  currentYear + 1,
                  columnDate.month,
                  columnDate.day,
                );
              }
            } catch (e) {
              Logger.i("Error parsing date: $dateText - $e");
            }
          }

          var shows = column.querySelectorAll('.timetable-column-show');

          for (var show in shows) {
            var titleEl = show.querySelector('.show-title-bar');
            var linkEl = show.querySelector('a.show-link');
            var posterEl = show.querySelector('.show-poster');
            var episodeEl = show.querySelector('.show-episode');
            var timeEl = show.querySelector('.show-air-time');

            String title = titleEl?.text.trim() ?? "";
            String link = linkEl?.attributes['href'] ?? "";
            String poster = posterEl?.attributes['src'] ??
                posterEl?.attributes['data-src'] ??
                "";
            String episodeText = episodeEl?.text.trim() ?? "";
            String timeText = timeEl?.text.trim() ?? "";

            if (title.isEmpty) continue;

            if (link.startsWith('/')) {
              link = "https://animeschedule.net$link";
            }

            if (poster.startsWith('/')) {
              poster = "https://animeschedule.net$poster";
            }

            int episode = 1;
            if (episodeText.isNotEmpty) {
              var match = RegExp(r'Ep (\d+)').firstMatch(episodeText);
              if (match != null) {
                episode = int.tryParse(match.group(1) ?? '1') ?? 1;
              }
            }

            DateTime airDateTime = DateTime.now();
            if (columnDate != null && timeText.isNotEmpty) {
              try {
                var timeParts = timeText.split(':');
                if (timeParts.length == 2) {
                  int hour = int.tryParse(timeParts[0]) ?? 0;
                  int minute = int.tryParse(timeParts[1]) ?? 0;
                  airDateTime = DateTime(
                    columnDate.year,
                    columnDate.month,
                    columnDate.day,
                    hour,
                    minute,
                  );
                }
              } catch (e) {
                Logger.i("Error parsing time: $timeText - $e");
              }
            }

            String normalizedTitle = _normalizeTitle(title);

            // Removed dub check - cookies already filter for dub only
            if (!dubMap.containsKey(normalizedTitle)) {
              dubMap[normalizedTitle] = DubAnimeInfo(
                normalizedTitle: normalizedTitle,
                streams: [],
              );
            }

            var scheduleInfo = AnimeScheduleInfo(
              title: title,
              url: link,
              poster: poster,
              episode: episode,
              airDateTime: airDateTime,
              serviceName: 'AnimeSchedule',
              serviceIcon:
                  'https://img.animeschedule.net/production/assets/public/img/logos/as-logo-855bacd96c.png',
            );

            dubMap[normalizedTitle] = DubAnimeInfo(
              normalizedTitle: normalizedTitle,
              streams: dubMap[normalizedTitle]!.streams,
              scheduleInfo: scheduleInfo,
            );

            if (!dubMap[normalizedTitle]!
                .streams
                .any((e) => e.name == 'AnimeSchedule')) {
              dubMap[normalizedTitle]!.streams.add(StreamingService(
                    name: 'AnimeSchedule',
                    url: link,
                    icon: scheduleInfo.serviceIcon,
                  ));
            }
          }
        }
      }
    } catch (e) {
      Logger.i("Error fetching dub data: $e");
    }

    return dubMap;
  }

  static Future<List<StreamingService>> fetchKuroiruLinks(String malId) async {
    if (malId == 'null' || malId.isEmpty) return [];

    try {
      final response =
          await http.get(Uri.parse('$kuroiruUrl/$malId'), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<StreamingService> streams = [];
        if (data['data'] != null && data['data']['streams'] != null) {
          for (var stream in data['data']['streams']) {
            streams.add(StreamingService(
              name: stream['name'] ?? 'Unknown',
              url: stream['url'] ?? '',
              icon: '',
            ));
          }
        }
        return streams;
      }
    } catch (e) {
      Logger.i("Error fetching Kuroiru: $e");
    }
    return [];
  }

  static String _normalizeTitle(String title) {
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class AnimeScheduleInfo {
  final String title;
  final String url;
  final String poster;
  final int episode;
  final DateTime airDateTime;
  final String serviceName;
  final String serviceIcon;

  AnimeScheduleInfo({
    required this.title,
    required this.url,
    required this.poster,
    required this.episode,
    required this.airDateTime,
    required this.serviceName,
    required this.serviceIcon,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'poster': poster,
        'episode': episode,
        'airDateTime': airDateTime.toIso8601String(),
        'serviceName': serviceName,
        'serviceIcon': serviceIcon,
      };

  factory AnimeScheduleInfo.fromJson(Map<String, dynamic> json) =>
      AnimeScheduleInfo(
        title: json['title'],
        url: json['url'],
        poster: json['poster'],
        episode: json['episode'],
        airDateTime: DateTime.parse(json['airDateTime']),
        serviceName: json['serviceName'],
        serviceIcon: json['serviceIcon'],
      );
}

class StreamingService {
  final String name;
  final String url;
  final String icon;

  StreamingService({
    required this.name,
    required this.url,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'icon': icon,
      };

  factory StreamingService.fromJson(Map<String, dynamic> json) =>
      StreamingService(
        name: json['name'],
        url: json['url'],
        icon: json['icon'],
      );
}

class DubAnimeInfo {
  final String normalizedTitle;
  final List<StreamingService> streams;
  final AnimeScheduleInfo? scheduleInfo;

  DubAnimeInfo({
    required this.normalizedTitle,
    required this.streams,
    this.scheduleInfo,
  });

  Map<String, dynamic> toJson() => {
        'normalizedTitle': normalizedTitle,
        'streams': streams.map((s) => s.toJson()).toList(),
        'scheduleInfo': scheduleInfo?.toJson(),
      };

  factory DubAnimeInfo.fromJson(Map<String, dynamic> json) => DubAnimeInfo(
        normalizedTitle: json['normalizedTitle'],
        streams: (json['streams'] as List)
            .map((s) => StreamingService.fromJson(s))
            .toList(),
        scheduleInfo: json['scheduleInfo'] != null
            ? AnimeScheduleInfo.fromJson(json['scheduleInfo'])
            : null,
      );
}
