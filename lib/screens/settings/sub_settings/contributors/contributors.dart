import 'dart:convert';

import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/settings/sub_settings/contributors/models/contributor_model.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/animation/staggered_animations.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const Set<String> _excludedGithubIds = {
  '198982749',
  '41898282',
  '65916846',
  '49699333',
};

const int _coreTeamCommitThreshold = 20;

final Map<String, ContributorModel> _curatedContributors = {
  'ryanyuuki': const ContributorModel(
    githubLogin: 'RyanYuuki',
    githubId: '108048963',
    displayName: 'RyanYuuki',
    avatarUrl: 'https://avatars.githubusercontent.com/u/108048963?s=400&v=4',
    profileUrl: 'https://github.com/RyanYuuki',
    roleTitle: 'Lead Developer',
    prCount: 0,
    commitCount: 0,
    bannerUrl: 'https://files.catbox.moe/asy3xu.jpg',
    isPinnedCoreTeam: true,
  ),
  'itsmechinmoy': const ContributorModel(
    githubLogin: 'itsmechinmoy',
    githubId: '167056923',
    displayName: 'itsmechinmoy',
    avatarUrl: 'https://files.catbox.moe/o45l03.gif',
    profileUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    roleTitle: 'Collaborator & Discord Admin',
    prCount: 0,
    commitCount: 0,
    bannerUrl: 'https://files.catbox.moe/gp3m17.gif',
    isPinnedCoreTeam: true,
  ),
  'shebyyy': const ContributorModel(
    githubLogin: 'Shebyyy',
    githubId: '83452219',
    displayName: 'Shebyyy',
    avatarUrl:
        'https://s4.anilist.co/file/anilistcdn/user/avatar/large/b5724017-EKLuuBbOkt8Z.png',
    profileUrl: 'https://anilist.co/user/ASheby/',
    roleTitle: 'Collaborator & Discord Admin',
    prCount: 0,
    commitCount: 0,
    bannerUrl:
        'https://s4.anilist.co/file/anilistcdn/user/banner/b5724017-owslY4fmWD6L.jpg',
    isPinnedCoreTeam: true,
  ),
  'aayush2622': const ContributorModel(
    githubLogin: 'aayush2622',
    githubId: '99584765',
    displayName: 'Aayush',
    avatarUrl:
        'https://s4.anilist.co/file/anilistcdn/user/avatar/large/b5144645-vGCFGixZUVSY.png',
    profileUrl: 'https://github.com/aayush2622',
    roleTitle: 'Extension Bridge Developer',
    prCount: 0,
    commitCount: 0,
    bannerUrl:
        'https://s4.anilist.co/file/anilistcdn/user/banner/b5144645-aRu1A0QFBin4.jpg',
    isSpecialThanks: true,
    roleLinks: {
      'DartotsuExtension Bridge':
          'https://github.com/aayush2622/DartotsuExtensionBridge',
      'Dartotsu': 'https://github.com/aayush2622/Dartotsu',
    },
  ),
  'Xerus': const ContributorModel(
    githubLogin: 'PandaTech-SX',
    githubId: '74928953',
    displayName: 'Xerus',
    avatarUrl: 'https://i.ibb.co/gF6HSFqZ/20250517-100044.png',
    profileUrl: 'https://sxenon.carrd.co/',
    roleTitle: 'UI/UX Designer',
    prCount: 0,
    commitCount: 0,
    bannerUrl: 'https://i.ibb.co/zhy5G1Tv/Walpaper-1.png',
    isSpecialThanks: true,
  ),
};

Future<void> _openExternalLink(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

bool _isBotAccount(dynamic rawContributor) {
  final login = ((rawContributor['login'] as String?) ?? '').toLowerCase();
  final accountType = (rawContributor['type'] as String?) ?? '';
  final id = rawContributor['id']?.toString() ?? '';
  if (_excludedGithubIds.contains(id)) return true;
  if (accountType == 'Bot') return true;
  return login.endsWith('[bot]') || login.endsWith('-bot');
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Future<Map<String, ContributorModel>> _fetchContributorProfiles() async {
  const endpoint =
      'https://api.github.com/repos/RyanYuuki/AnymeX/contributors?per_page=100';
  final Map<String, ContributorModel> profilesByLogin = {};
  var page = 1;

  while (true) {
    final response = await http.get(
      Uri.parse('$endpoint&page=$page'),
      headers: {'Accept': 'application/vnd.github.v3+json'},
    );
    if (response.statusCode != 200) break;

    final List<dynamic> pageData = jsonDecode(response.body) as List<dynamic>;
    if (pageData.isEmpty) break;

    for (final rawContributor in pageData) {
      if (_isBotAccount(rawContributor)) continue;
      final login = ((rawContributor['login'] as String?) ?? '').trim();
      if (login.isEmpty) continue;
      profilesByLogin[login.toLowerCase()] = ContributorModel(
        githubLogin: login,
        githubId: rawContributor['id']?.toString() ?? login,
        displayName: login,
        avatarUrl: (rawContributor['avatar_url'] as String?) ?? '',
        profileUrl: (rawContributor['html_url'] as String?) ??
            'https://github.com/$login',
        roleTitle: 'Contributor',
        prCount: 0,
        commitCount: _toInt(rawContributor['contributions']),
        bannerUrl: '',
      );
    }

    page += 1;
  }

  return profilesByLogin;
}

Future<Map<String, int>> _fetchPullRequestCounts() async {
  const endpoint =
      'https://api.github.com/repos/RyanYuuki/AnymeX/pulls?state=all&per_page=100';
  final Map<String, int> pullRequestCounts = {};
  var page = 1;

  while (true) {
    final response = await http.get(
      Uri.parse('$endpoint&page=$page'),
      headers: {'Accept': 'application/vnd.github.v3+json'},
    );
    if (response.statusCode != 200) break;

    final List<dynamic> pageData = jsonDecode(response.body) as List<dynamic>;
    if (pageData.isEmpty) break;

    for (final rawPullRequest in pageData) {
      final dynamic rawAuthor = rawPullRequest['user'];
      if (rawAuthor == null || _isBotAccount(rawAuthor)) continue;
      final login = ((rawAuthor['login'] as String?) ?? '').trim();
      if (login.isEmpty) continue;
      final normalizedLogin = login.toLowerCase();
      pullRequestCounts[normalizedLogin] =
          (pullRequestCounts[normalizedLogin] ?? 0) + 1;
    }

    page += 1;
  }

  return pullRequestCounts;
}

Future<List<StaffModel>> _fetchStaff() async {
  try {
    final response = await http.get(
      Uri.parse(
          'https://github.com/Shebyyy/AnymeX/raw/refs/heads/beta/staff.json'),
    );
    if (response.statusCode != 200) return [];
    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> list = (data['staff'] as List<dynamic>?) ?? [];
    return list
        .map((e) => StaffModel(
              displayName: (e['displayName'] as String?) ?? '',
              role: (e['role'] as String?) ?? '',
              avatarUrl: (e['avatarUrl'] as String?) ?? '',
              profileUrl: (e['profileUrl'] as String?) ?? '',
              platforms: List<String>.from(
                  (e['platforms'] as List<dynamic>?) ?? []),
            ))
        .where((s) => s.displayName.isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}

Future<List<ContributorModel>> fetchContributors() async {
  final profilesByLogin = await _fetchContributorProfiles();
  final pullRequestCounts = await _fetchPullRequestCounts();
  final allLogins = <String>{
    ...profilesByLogin.keys,
    ..._curatedContributors.keys,
  };

  final contributors = <ContributorModel>[];
  for (final normalizedLogin in allLogins) {
    final curatedContributor = _curatedContributors[normalizedLogin];
    final profileContributor = profilesByLogin[normalizedLogin];

    final commitCount = profileContributor?.commitCount ?? 0;
    if (!(curatedContributor?.isPinnedCoreTeam == true ||
            curatedContributor?.isSpecialThanks == true) &&
        commitCount == 0) {
      continue;
    }

    final login = curatedContributor?.githubLogin ??
        profileContributor?.githubLogin ??
        normalizedLogin;

    contributors.add(ContributorModel(
      githubLogin: login,
      githubId:
          curatedContributor?.githubId ?? profileContributor?.githubId ?? login,
      displayName: curatedContributor?.displayName ??
          profileContributor?.displayName ??
          login,
      avatarUrl: curatedContributor?.avatarUrl ??
          profileContributor?.avatarUrl ??
          'https://avatars.githubusercontent.com/$login',
      profileUrl: curatedContributor?.profileUrl ??
          profileContributor?.profileUrl ??
          'https://github.com/$login',
      roleTitle: curatedContributor?.roleTitle ?? 'Contributor',
      prCount: pullRequestCounts[normalizedLogin] ?? 0,
      commitCount: commitCount,
      bannerUrl:
          curatedContributor?.bannerUrl ?? profileContributor?.bannerUrl ?? '',
      roleLinks: curatedContributor?.roleLinks ?? const <String, String>{},
      isPinnedCoreTeam: curatedContributor?.isPinnedCoreTeam ?? false,
      isSpecialThanks: curatedContributor?.isSpecialThanks ?? false,
    ));
  }

  contributors.sort((left, right) {
    final byCommits = right.commitCount.compareTo(left.commitCount);
    if (byCommits != 0) return byCommits;
    return left.displayName
        .toLowerCase()
        .compareTo(right.displayName.toLowerCase());
  });

  return contributors;
}

class StaffModel {
  final String displayName;
  final String role;
  final String avatarUrl;
  final String profileUrl;
  final List<String> platforms;

  const StaffModel({
    required this.displayName,
    required this.role,
    required this.avatarUrl,
    required this.profileUrl,
    required this.platforms,
  });
}

class ContributorsPage extends StatefulWidget {
  const ContributorsPage({super.key});

  @override
  State<ContributorsPage> createState() => _ContributorsPageState();
}

class _ContributorsPageState extends State<ContributorsPage> {
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxList<ContributorModel> coreTeam = <ContributorModel>[].obs;
  final RxList<ContributorModel> specialThanks = <ContributorModel>[].obs;
  final RxList<ContributorModel> communityContributors =
      <ContributorModel>[].obs;
  final RxList<StaffModel> staff = <StaffModel>[].obs;

  @override
  void initState() {
    super.initState();
    _loadContributors();
  }

  bool _isRyanYuuki(ContributorModel contributor) {
    return contributor.githubId == '108048963' ||
        contributor.githubLogin.toLowerCase() == 'ryanyuuki';
  }

  Future<void> _loadContributors() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final results = await Future.wait([
        fetchContributors(),
        _fetchStaff(),
      ]);

      final allContributors = results[0] as List<ContributorModel>;
      final staffList = results[1] as List<StaffModel>;

      final coreTeamList = allContributors
          .where(
            (c) =>
                !c.isSpecialThanks &&
                (c.isPinnedCoreTeam ||
                    c.commitCount >= _coreTeamCommitThreshold),
          )
          .toList();
      coreTeamList.sort((left, right) {
        final leftIsRyan = _isRyanYuuki(left);
        final rightIsRyan = _isRyanYuuki(right);
        if (leftIsRyan && !rightIsRyan) return -1;
        if (!leftIsRyan && rightIsRyan) return 1;
        final byCommits = right.commitCount.compareTo(left.commitCount);
        if (byCommits != 0) return byCommits;
        return right.prCount.compareTo(left.prCount);
      });

      final specialThanksList =
          allContributors.where((c) => c.isSpecialThanks).toList();

      final communityList = allContributors
          .where(
            (c) =>
                !c.isSpecialThanks &&
                !c.isPinnedCoreTeam &&
                c.commitCount < _coreTeamCommitThreshold,
          )
          .toList();

      coreTeam.assignAll(coreTeamList);
      specialThanks.assignAll(specialThanksList);
      communityContributors.assignAll(communityList);
      staff.assignAll(staffList);
    } catch (error) {
      errorMessage.value = 'Failed to load contributors';
      debugPrint('Contributors fetch error: $error');
    } finally {
      isLoading.value = false;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    final colors = context.colors;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Divider(
                color: colors.outlineVariant.withOpacity(0.45),
                thickness: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(
    BuildContext context, {
    required String title,
    required List<ContributorModel> contributors,
    String? subtitle,
  }) {
    final colors = context.colors;
    if (contributors.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurface.withOpacity(0.45),
                ),
              ),
            ),
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: contributors.length,
              itemBuilder: (context, index) => _buildFeaturedCard(
                context,
                contributor: contributors[index],
                index: index,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context, {
    required ContributorModel contributor,
    required int index,
  }) {
    final colors = context.colors;

    return StaggeredFadeScale(
      index: index,
      child: GestureDetector(
        onTap: () => _openExternalLink(contributor.profileUrl),
        child: Container(
          width: 155,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colors.surfaceContainerHighest.opaque(0.4),
            border: Border.all(
              color: colors.outlineVariant.withOpacity(0.45),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if ((contributor.bannerUrl ?? '').isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: contributor.bannerUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: colors.primaryContainer),
                      )
                    else
                      Container(color: colors.primaryContainer),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            colors.surfaceContainerHighest.withOpacity(0.45),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surfaceContainerHighest,
                          border: Border.all(
                            color: colors.primary.withOpacity(0.45),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: contributor.avatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  contributor.avatarUrl)
                              : null,
                          backgroundColor: colors.primaryContainer,
                          child: contributor.avatarUrl.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 22,
                                  color: colors.onPrimaryContainer,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contributor.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contributor.roleTitle,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: colors.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          contributor.commitCount == 1
                              ? '1 commit • ${contributor.prCount} PRs'
                              : '${contributor.commitCount} commits • ${contributor.prCount} PRs',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContributorsList(
    BuildContext context,
    List<ContributorModel> contributors,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildContributorRow(
            context,
            contributor: contributors[index],
            index: index,
          ),
          childCount: contributors.length,
        ),
      ),
    );
  }

  Widget _buildContributorRow(
    BuildContext context, {
    required ContributorModel contributor,
    required int index,
  }) {
    final colors = context.colors;

    return StaggeredFadeSlide(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openExternalLink(contributor.profileUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: colors.surfaceContainerLow.opaque(0.5),
                border: Border.all(
                  color: colors.outlineVariant.withOpacity(0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: index < 3
                            ? colors.primary
                            : colors.onSurface.opaque(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: contributor.avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(contributor.avatarUrl)
                        : null,
                    backgroundColor: colors.primaryContainer,
                    child: contributor.avatarUrl.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: colors.onPrimaryContainer,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      contributor.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      contributor.commitCount == 1
                          ? '1 commit'
                          : '${contributor.commitCount} commits',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                  if (contributor.prCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${contributor.prCount} PRs',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colors.onSurface.withOpacity(0.35),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffSection(BuildContext context) {
    final colors = context.colors;
    if (staff.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final member = staff[index];
            return StaggeredFadeSlide(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openExternalLink(member.profileUrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: colors.surfaceContainerLow.opaque(0.5),
                        border: Border.all(
                          color: colors.outlineVariant.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: member.avatarUrl.isNotEmpty
                                ? CachedNetworkImageProvider(member.avatarUrl)
                                : null,
                            backgroundColor: colors.primaryContainer,
                            child: member.avatarUrl.isEmpty
                                ? Icon(Icons.person_rounded,
                                    size: 18,
                                    color: colors.onPrimaryContainer)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.displayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  member.role,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurface.withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: colors.onSurface.withOpacity(0.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: staff.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Glow(
      child: Scaffold(
        body: Obx(
          () => CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                  child: NestedHeader(title: 'Contributors')),
              if (isLoading.value)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorMessage.value.isNotEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      errorMessage.value,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                )
              else if (coreTeam.isEmpty &&
                  specialThanks.isEmpty &&
                  communityContributors.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No contributors found.')),
                )
              else ...[
                _buildFeaturedSection(
                  context,
                  title: 'Core Team',
                  contributors: coreTeam,
                ),
                if (specialThanks.isNotEmpty)
                  _buildFeaturedSection(
                    context,
                    title: 'Special Thanks',
                    subtitle:
                        'The extension system is available thanks to Aayush.',
                    contributors: specialThanks,
                  ),
                _buildSectionHeader(context, 'Community Contributors'),
                _buildContributorsList(context, communityContributors),
                _buildSectionHeader(context, 'Staff'),
                _buildStaffSection(context),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
