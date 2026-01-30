import 'package:anymex/utils/logger.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DubService {
  static const String animeScheduleUrl = 'https://animeschedule.net/';

  static Future<List<DubAnimeInfo>> fetchDubSources() async {
    final List<DubAnimeInfo> dubs = [];

    try {
      final asResponse = await http.get(Uri.parse(animeScheduleUrl), headers: {
        "User-Agent":
            "Mozilla/5.0 (X11; Linux x86_64; rv:146.0) Gecko/20100101 Firefox/146.0",
        "Cookie":
            "as_cachedBaseCSS=baseMobile-c234a32dbf.min.css; as_timezone=Asia/Kolkata; as_timetableSettingsTimeFormat=12; as_timetableSettingsLayoutMode=large-tile; as_timetableSettingsVisible=false; as_timetableSettingsHideRaw=dub; as_timetableSettingsHideSub=dub; as_timetableSettingsAirTime=dub; as_timetableSettingsFilters=%5B%5D; as_timetableSettingsStreamFilters=%5B%22%5C%22crunchyroll-filter%5C%22%22%5D; as_timetableSettingsMediaFilters=%5B%22%5C%22tv-filter%5C%22%22,%22%5C%22ona-filter%5C%22%22,%22%5C%22ova-filter%5C%22%22,%22%5C%22special-filter%5C%22%22,%22%5C%22movie-filter%5C%22%22,%22%5C%22tv-short-filter%5C%22%22%5D; as_timetableSettingsFilterToFilters=%5B%22%5C%22always-show-anime-list-anime-filter%5C%22%22%5D; as_timetableSettingsFilterType=inclusive; as_timetableShowChinese=false; as_timetableSettingsHideDub=; as_disableTimetableImages=false; as_timetableSettingsSortBy=popularity; as_timetableSettingsWeekType=rotating"
      });

      if (asResponse.statusCode == 200) {
        var document = html_parser.parse(asResponse.body);
        var columns = document.querySelectorAll('.timetable-column');

        for (var column in columns) {
          var dateEl = column.querySelector('.timetable-column-date-format');

          String? dateText = dateEl?.text.trim();

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
            print(title);

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

            List<StreamingService> streamingServices = [];
            var streamsContainer = show.querySelector('.show-streams');

            if (streamsContainer != null) {
              var streamLinks =
                  streamsContainer.querySelectorAll('a.stream-link');

              for (var streamLink in streamLinks) {
                String streamUrl = streamLink.attributes['href'] ?? "";
                String streamTitle = streamLink.attributes['title'] ?? "";

                var iconEl = streamLink.querySelector('img.stream-icon');
                String streamIcon = iconEl?.attributes['data-src'] ??
                    iconEl?.attributes['src'] ??
                    "";

                if (streamIcon.startsWith('/')) {
                  streamIcon = "https://animeschedule.net$streamIcon";
                }

                if (streamUrl.startsWith('//')) {
                  streamUrl = 'https:$streamUrl';
                }

                if (streamTitle.isNotEmpty && streamUrl.isNotEmpty) {
                  streamingServices.add(StreamingService(
                    name: streamTitle,
                    url: streamUrl,
                    icon: streamIcon,
                  ));
                }
              }

              final Set<String> icons = {};
              final List<StreamingService> filteredServices = [];

              for (final service in streamingServices) {
                if (icons.add(service.icon)) {
                  filteredServices.add(service);
                }
              }

              streamingServices = filteredServices;
            }

            dubs.add(DubAnimeInfo(
              title: title,
              animeUrl: link,
              poster: poster,
              episode: episode,
              airDateTime: airDateTime,
              streams: streamingServices,
            ));
          }
        }
      }
    } catch (e) {
      Logger.i("Error fetching dub data: $e");
    }

    return dubs;
  }
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
  final String title;
  final String animeUrl;
  final String poster;
  final int episode;
  final DateTime airDateTime;
  final List<StreamingService> streams;

  DubAnimeInfo({
    required this.title,
    required this.animeUrl,
    required this.poster,
    required this.episode,
    required this.airDateTime,
    required this.streams,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'animeUrl': animeUrl,
        'poster': poster,
        'episode': episode,
        'airDateTime': airDateTime.toIso8601String(),
        'streams': streams.map((s) => s.toJson()).toList(),
      };

  factory DubAnimeInfo.fromJson(Map<String, dynamic> json) => DubAnimeInfo(
        title: json['title'],
        animeUrl: json['animeUrl'],
        poster: json['poster'],
        episode: json['episode'],
        airDateTime: DateTime.parse(json['airDateTime']),
        streams: (json['streams'] as List)
            .map((s) => StreamingService.fromJson(s))
            .toList(),
      );
}
