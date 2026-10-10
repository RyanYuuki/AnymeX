import 'package:anymex/database/isar_models/track.dart';
import 'package:anymex/database/isar_models/video.dart' show Video;

class WatchiumUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final String authProvider;

  WatchiumUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.authProvider,
  });

  factory WatchiumUser.fromJson(Map<String, dynamic> json) => WatchiumUser(
        id: json['id'] as String,
        username: json['username'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        authProvider: json['authProvider'] as String,
      );
}

class WatchiumAnimeServer {
  final String serverId;
  final String serverName;
  final String? quality;
  final String type;

  final String? url;
  final String? originalUrl;
  final Map<String, String>? headers;
  final List<WatchiumTrack>? subtitles;
  final List<WatchiumTrack>? audios;

  WatchiumAnimeServer({
    required this.serverId,
    required this.serverName,
    this.quality,
    required this.type,
    this.url,
    this.originalUrl,
    this.headers,
    this.subtitles,
    this.audios,
  });

  factory WatchiumAnimeServer.fromJson(Map<String, dynamic> json) =>
      WatchiumAnimeServer(
        serverId: json['serverId'] as String,
        serverName: json['serverName'] as String,
        quality: json['quality'] as String?,
        type: json['type'] as String? ?? 'other',
        url: json['url'] as String?,
        originalUrl: json['originalUrl'] as String?,
        headers: (json['headers'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v.toString())),
        subtitles: (json['subtitles'] as List?)
            ?.map((e) => WatchiumTrack.fromJson(e as Map<String, dynamic>))
            .toList(),
        audios: (json['audios'] as List?)
            ?.map((e) => WatchiumTrack.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'serverId': serverId,
        'serverName': serverName,
        'quality': quality,
        'type': type,
        'url': url,
        'originalUrl': originalUrl,
        'headers': headers,
        'subtitles': subtitles?.map((e) => e.toJson()).toList(),
        'audios': audios?.map((e) => e.toJson()).toList(),
      };

  Video toVideo() {
    return Video(
      url: url,
      quality: serverName,
      originalUrl: originalUrl ?? url,
      headerKeys: headers?.keys.toList(),
      headerValues: headers?.values.toList(),
      subtitles:
          subtitles?.map((e) => Track(file: e.file, label: e.label)).toList(),
      audios: audios?.map((e) => Track(file: e.file, label: e.label)).toList(),
    );
  }
}

class WatchiumTrack {
  final String file;
  final String label;
  WatchiumTrack({required this.file, required this.label});
  factory WatchiumTrack.fromJson(Map<String, dynamic> json) => WatchiumTrack(
        file: json['file'] as String,
        label: json['label'] as String,
      );
  Map<String, dynamic> toJson() => {'file': file, 'label': label};
}

class WatchiumAnimeContent {
  final String animeId;
  final String animeTitle;
  final String? animeCoverImage;
  final String? animePosterImage;
  final int episodeNumber;
  final int? seasonNumber;
  final int? totalEpisodes;
  final int? anilistId;
  final int? malId;
  final int? simklId;
  final List<WatchiumAnimeServer> availableServers;

  WatchiumAnimeContent({
    required this.animeId,
    required this.animeTitle,
    this.animeCoverImage,
    this.animePosterImage,
    required this.episodeNumber,
    this.seasonNumber,
    this.totalEpisodes,
    this.anilistId,
    this.malId,
    this.simklId,
    required this.availableServers,
  });

  factory WatchiumAnimeContent.fromJson(Map<String, dynamic> json) =>
      WatchiumAnimeContent(
        animeId: json['animeId'] as String,
        animeTitle: json['animeTitle'] as String,
        animeCoverImage: json['animeCoverImage'] as String?,
        animePosterImage: json['animePosterImage'] as String?,
        episodeNumber: json['episodeNumber'] as int,
        seasonNumber: json['seasonNumber'] as int?,
        totalEpisodes: json['totalEpisodes'] as int?,
        anilistId: json['anilistId'] as int?,
        malId: json['malId'] as int?,
        simklId: json['simklId'] as int?,
        availableServers: (json['availableServers'] as List?)
                ?.map((e) =>
                    WatchiumAnimeServer.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'animeId': animeId,
        'animeTitle': animeTitle,
        'animeCoverImage': animeCoverImage,
        'animePosterImage': animePosterImage,
        'episodeNumber': episodeNumber,
        'seasonNumber': seasonNumber,
        'totalEpisodes': totalEpisodes,
        'anilistId': anilistId,
        'malId': malId,
        'simklId': simklId,
        'availableServers': availableServers.map((e) => e.toJson()).toList(),
      };
}

class WatchiumPlayback {
  double positionSec;
  bool isPlaying;
  double rate;
  int updatedAt;

  WatchiumPlayback({
    required this.positionSec,
    required this.isPlaying,
    required this.rate,
    required this.updatedAt,
  });

  factory WatchiumPlayback.fromJson(Map<String, dynamic> json) =>
      WatchiumPlayback(
        positionSec: (json['positionSec'] as num).toDouble(),
        isPlaying: json['isPlaying'] as bool,
        rate: (json['rate'] as num).toDouble(),
        updatedAt: json['updatedAt'] as int,
      );
}

class WatchiumMember {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String role;
  final bool online;
  final String? selectedServerId;

  WatchiumMember({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.role,
    required this.online,
    this.selectedServerId,
  });

  factory WatchiumMember.fromJson(Map<String, dynamic> json) => WatchiumMember(
        userId: json['userId'] as String,
        username: json['username'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        role: json['role'] as String,
        online: json['online'] as bool,
        selectedServerId: json['selectedServerId'] as String?,
      );
}

class WatchiumRoomState {
  final String code;
  final String hostUserId;
  final List<WatchiumMember> members;
  final WatchiumAnimeContent? content;
  final WatchiumPlayback? playback;
  final bool onlyHostControls;
  final bool chatDisabled;
  final bool announcementMode;
  final int maxMembers;
  final int createdAt;
  final bool hasPassword;

  WatchiumRoomState({
    required this.code,
    required this.hostUserId,
    required this.members,
    this.content,
    this.playback,
    required this.onlyHostControls,
    required this.chatDisabled,
    required this.announcementMode,
    required this.maxMembers,
    required this.createdAt,
    this.hasPassword = false,
  });

  factory WatchiumRoomState.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>?;
    return WatchiumRoomState(
      code: json['code'] as String,
      hostUserId: json['hostUserId'] as String,
      members: (json['members'] as List?)
              ?.map((e) => WatchiumMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      content: json['content'] != null
          ? WatchiumAnimeContent.fromJson(
              json['content'] as Map<String, dynamic>)
          : null,
      playback: json['playback'] != null
          ? WatchiumPlayback.fromJson(json['playback'] as Map<String, dynamic>)
          : null,
      onlyHostControls: settings?['onlyHostControls'] as bool? ?? true,
      chatDisabled: settings?['chatDisabled'] as bool? ?? false,
      announcementMode: settings?['announcementMode'] as bool? ?? false,
      maxMembers: json['maxMembers'] as int? ?? 10,
      createdAt: json['createdAt'] as int? ?? 0,
      hasPassword: json['hasPassword'] as bool? ?? false,
    );
  }
}

class WatchiumChatMessage {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String text;
  final int ts;
  final String clientId;

  WatchiumChatMessage({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.text,
    required this.ts,
    required this.clientId,
  });

  factory WatchiumChatMessage.fromJson(Map<String, dynamic> json) =>
      WatchiumChatMessage(
        userId: (json['user'] as Map<String, dynamic>)['id'] as String,
        username: (json['user'] as Map<String, dynamic>)['username'] as String,
        avatarUrl:
            (json['user'] as Map<String, dynamic>)['avatarUrl'] as String?,
        text: json['text'] as String,
        ts: json['ts'] as int,
        clientId: json['clientId'] as String,
      );
}

class WatchiumReaction {
  final String userId;
  final String username;
  final String? avatarUrl;
  final String emoji;
  final int ts;

  WatchiumReaction({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.emoji,
    required this.ts,
  });

  factory WatchiumReaction.fromJson(Map<String, dynamic> json) =>
      WatchiumReaction(
        userId: (json['user'] as Map<String, dynamic>)['id'] as String,
        username: (json['user'] as Map<String, dynamic>)['username'] as String,
        avatarUrl:
            (json['user'] as Map<String, dynamic>)['avatarUrl'] as String?,
        emoji: json['emoji'] as String,
        ts: json['ts'] as int,
      );
}
