import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class Contributors {
  static const List<String> excludedContributorIds = [
    '198982749', // copilot-pull-request-reviewer
    '15368', // github-actions
    '65916846', // actions-user
  ];

  static const List<String> defaultBanners = [
    'https://files.catbox.moe/zduba9.jpg',
    'https://files.catbox.moe/hqmdfx.png',
    'https://files.catbox.moe/n8pdqc.png',
  ];

  static Future<List<Contributor>> get getContributorsList async {
    final List<Contributor> hardcodedContributors = [
      Contributor(
        name: 'RyanYuuki',
        githubId: '108048963',
        pfp: 'https://avatars.githubusercontent.com/u/108048963?s=400&u=7f67531c27c5ebbbcde943f9576a0bfdb98909c8&v=4',
        banner: 'https://files.catbox.moe/mdn05t.png',
        uri: 'https://github.com/RyanYuuki',
        role: 'Lead Developer',
        contributions: 0,
      ),
      Contributor(
        name: 'aayush262',
        githubId: '99584765',
        pfp: 'https://s4.anilist.co/file/anilistcdn/user/avatar/large/b5144645-vGCFGixZUVSY.png',
        banner: 'https://s4.anilist.co/file/anilistcdn/user/banner/b5144645-aRu1A0QFBin4.jpg',
        uri: 'https://github.com/aayush2622',
        role: 'Lead Dev of Dartotsu & DartotsuExtension Bridge',
        contributions: 0,
        roleLinks: {
          'Dartotsu': 'https://github.com/aayush2622/Dartotsu',
          'DartotsuExtension Bridge': 'https://github.com/aayush2622/DartotsuExtensionBridge',
        },
      ),
      Contributor(
        name: 'itsmechinmoy',
        githubId: '167056923',
        pfp: 'https://files.catbox.moe/o45l03.gif',
        banner: 'https://files.catbox.moe/gp3m17.gif',
        uri: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        role: 'Collaborator & Discord Admin',
        contributions: 0,
      ),
      Contributor(
        name: 'Sheby',
        githubId: '83452219',
        pfp: 'https://s4.anilist.co/file/anilistcdn/user/avatar/large/b5724017-EKLuuBbOkt8Z.png',
        banner: 'https://s4.anilist.co/file/anilistcdn/user/banner/b5724017-owslY4fmWD6L.jpg',
        uri: 'https://anilist.co/user/ASheby/',
        role: 'Collaborator & Discord Admin',
        contributions: 0,
      ),
      Contributor(
        name: 'Xerus',
        githubId: '74928953',
        pfp: 'https://i.ibb.co/gF6HSFqZ/20250517-100044.png',
        banner: 'https://i.ibb.co/zhy5G1Tv/Walpaper-1.png',
        uri: 'https://sxenon.carrd.co/',
        role: 'Designer',
        contributions: 0,
      ),
    ];

    final List<Contributor> fetchedContributors =
        await _fetchGitHubContributors();

    final Map<String, int> contributionMap = {
      for (final c in fetchedContributors) c.githubId: c.contributions,
    };

    final updatedHardcoded = [
      for (final dev in hardcodedContributors)
        dev
          ..contributions =
              contributionMap[dev.githubId] ?? dev.contributions
    ];

    final hardcodedIds = updatedHardcoded
        .map((dev) => dev.githubId)
        .where((id) => id.isNotEmpty)
        .toSet();

    fetchedContributors
        .sort((a, b) => b.contributions.compareTo(a.contributions));

    final List<Contributor> combinedList = [
      ...updatedHardcoded,
      ...fetchedContributors
          .where((dev) => !hardcodedIds.contains(dev.githubId)),
    ];

    return combinedList;
  }

  static Future<List<Contributor>> _fetchGitHubContributors() async {
    final List<Contributor> contributors = [];
    int page = 1;
    const String apiUrl =
        'https://api.github.com/repos/RyanYuuki/AnymeX/contributors?per_page=100';
    final random = Random();

    try {
      while (true) {
        final response = await http.get(
          Uri.parse('$apiUrl&page=$page'),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        );

        if (response.statusCode != 200) {
          debugPrint('Error fetching contributors: ${response.statusCode}');
          break;
        }

        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) break;

        for (var contributor in data) {
          final String githubId = contributor['id'].toString();
          if (excludedContributorIds.contains(githubId)) continue;

          contributors.add(Contributor(
            name: contributor['login'],
            githubId: githubId,
            pfp: contributor['avatar_url'] ?? '',
            banner: defaultBanners[random.nextInt(defaultBanners.length)],
            uri: contributor['html_url'] ?? 'https://github.com',
            role: 'Contributor',
            contributions: contributor['contributions'] ?? 0,
          ));
        }

        page++;
      }
    } catch (e) {
      debugPrint('Error fetching contributors: $e');
    }

    return contributors;
  }

  static TextSpan _buildRoleTextSpan(
    String role,
    Map<String, String>? roleLinks,
  ) {
    const baseStyle = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: Colors.white70,
    );

    if (roleLinks == null || roleLinks.isEmpty) {
      return TextSpan(text: role, style: baseStyle);
    }

    final List<TextSpan> spans = [];
    String remaining = role;

    final sortedKeys = roleLinks.keys.toList()
      ..sort(
          (a, b) => remaining.indexOf(a).compareTo(remaining.indexOf(b)));

    for (final key in sortedKeys) {
      final idx = remaining.indexOf(key);
      if (idx == -1) continue;
      if (idx > 0) {
        spans.add(TextSpan(
          text: remaining.substring(0, idx),
          style: baseStyle,
        ));
      }
      final url = roleLinks[key]!;
      spans.add(TextSpan(
        text: key,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Colors.lightBlueAccent,
          decoration: TextDecoration.underline,
          decorationColor: Colors.lightBlueAccent,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
      ));

      remaining = remaining.substring(idx + key.length);
    }

    // Any trailing plain text.
    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining, style: baseStyle));
    }

    return TextSpan(children: spans);
  }

  static Widget getContributorsWidget(BuildContext context) {
    return FutureBuilder(
      future: getContributorsList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No contributors found.'));
        } else {
          final contributors = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: contributors.length,
            itemBuilder: (context, index) {
              final dev = contributors[index];
              final card = InkWell(
                onTap: () async {
                  final url = Uri.parse(dev.uri);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    clipBehavior: Clip.antiAlias,
                    children: [
                      if (dev.banner != null)
                        Image.network(
                          dev.banner!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 86,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 86,
                            width: double.infinity,
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        height: 86,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      SizedBox(
                        height: 86,
                        width: double.infinity,
                        child: Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: dev.pfp.isNotEmpty
                                      ? CachedNetworkImageProvider(dev.pfp)
                                      : null,
                                  backgroundColor: Colors.transparent,
                                  child: dev.pfp.isEmpty
                                      ? Icon(
                                          Icons.person,
                                          size: 28,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dev.name,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text.rich(
                                        _buildRoleTextSpan(
                                            dev.role, dev.roleLinks),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (dev.contributions > 0)
                                        Text(
                                          '${dev.contributions} contribution${dev.contributions == 1 ? '' : 's'}',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: Colors.white60,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              return card
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                  .slide(begin: const Offset(0, 0.1));
            },
          );
        }
      },
    );
  }
}

class Contributor {
  final String name;
  final String githubId;
  final String pfp;
  final String? banner;
  final String uri;
  final String role;
  int contributions;
  final Map<String, String>? roleLinks;

  Contributor({
    required this.name,
    required this.githubId,
    required this.pfp,
    this.banner,
    required this.uri,
    required this.role,
    required this.contributions,
    this.roleLinks,
  });
}
