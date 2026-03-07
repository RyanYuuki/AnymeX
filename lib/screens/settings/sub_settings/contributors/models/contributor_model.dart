class ContributorModel {
  const ContributorModel({
    required this.githubLogin,
    required this.githubId,
    required this.displayName,
    required this.avatarUrl,
    required this.profileUrl,
    required this.roleTitle,
    required this.prCount,
    required this.commitCount,
    this.bannerUrl,
    this.roleLinks = const <String, String>{},
    this.isPinnedCoreTeam = false,
    this.isSpecialThanks = false,
  });

  final String githubLogin;
  final String githubId;
  final String displayName;
  final String avatarUrl;
  final String profileUrl;
  final String roleTitle;
  final int prCount;
  final int commitCount;
  final String? bannerUrl;
  final Map<String, String> roleLinks;
  final bool isPinnedCoreTeam;
  final bool isSpecialThanks;
}
