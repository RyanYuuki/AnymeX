import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Anilist/anilist_search_results.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';

import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum SearchTab { users, staff, characters, anime, manga }

class SocialSearchPage extends StatefulWidget {
  const SocialSearchPage({super.key});

  @override
  State<SocialSearchPage> createState() => _SocialSearchPageState();
}

class _SocialSearchPageState extends State<SocialSearchPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final _auth = Get.find<AnilistAuth>();

  SearchTab _currentTab = SearchTab.users;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: SearchTab.values.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab = SearchTab.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            NestedHeader(
              title: 'Search',
              action: null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _triggerSearch(),
                decoration: InputDecoration(
                  hintText: 'Search ${_currentTab.name}...',
                  prefixIcon:
                      Icon(Icons.search, color: theme.onSurfaceVariant),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: theme.onSurfaceVariant),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.surfaceContainer,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: theme.primary,
              unselectedLabelColor: theme.onSurfaceVariant,
              indicatorColor: theme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: const [
                Tab(text: 'Users'),
                Tab(text: 'Staff'),
                Tab(text: 'Characters'),
                Tab(text: 'Anime'),
                Tab(text: 'Manga'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _UserSearchTab(auth: _auth, searchController: _searchController),
                  _StaffSearchTab(auth: _auth, searchController: _searchController),
                  _CharacterSearchTab(auth: _auth, searchController: _searchController),
                  _MediaSearchTab(auth: _auth, searchController: _searchController, type: 'ANIME'),
                  _MediaSearchTab(auth: _auth, searchController: _searchController, type: 'MANGA'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerSearch() {
    setState(() {});
  }
}

class _UserSearchTab extends StatefulWidget {
  final AnilistAuth auth;
  final TextEditingController searchController;
  const _UserSearchTab({required this.auth, required this.searchController});

  @override
  State<_UserSearchTab> createState() => _UserSearchTabState();
}

class _UserSearchTabState extends State<_UserSearchTab>
    with AutomaticKeepAliveClientMixin {
  List<SearchUser> _results = [];
  bool _isLoading = false;
  bool _hasNextPage = false;
  int _page = 1;
  String _lastQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = widget.searchController.text.trim();
    if (query != _lastQuery && query.isNotEmpty) {
      _search();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasNextPage) {
      _loadMore();
    }
  }

  Future<void> _search() async {
    final query = widget.searchController.text.trim();
    if (query.isEmpty) return;
    if (query == _lastQuery && _results.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _page = 1;
      _lastQuery = query;
    });

    final (results, hasNext) =
        await widget.auth.searchUsers(query: query, page: 1);
    if (mounted) {
      setState(() {
        _results = results;
        _hasNextPage = hasNext;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasNextPage) return;
    setState(() => _isLoading = true);
    _page++;
    final (results, hasNext) =
        await widget.auth.searchUsers(query: _lastQuery, page: _page);
    if (mounted) {
      setState(() {
        _results.addAll(results);
        _hasNextPage = hasNext;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.colors;

    if (_isLoading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: AnymexText(
          text: _lastQuery.isEmpty
              ? 'Search for users on AniList'
              : 'No users found',
          color: theme.onSurfaceVariant,
          size: 14,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _results.length + (_hasNextPage ? 1 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        if (index == _results.length && _hasNextPage) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _isLoading
                  ? CircularProgressIndicator(
                      color: theme.primary, strokeWidth: 2)
                  : TextButton(
                      onPressed: _loadMore,
                      child: AnymexText(
                          text: 'Load More', color: theme.primary),
                    ),
            ),
          );
        }
        return _buildUserCard(_results[index], theme);
      },
    );
  }

  Widget _buildUserCard(SearchUser user, ColorScheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => navigate(() => UserProfilePage(userId: user.id)),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surfaceContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.outline.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? const Icon(Icons.person, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymexText(
                        text: user.name,
                        variant: TextVariant.semiBold,
                        size: 15,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (user.animeStats != null) ...[
                            Icon(Icons.play_circle_outline,
                                size: 12, color: theme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            AnymexText(
                              text: '${user.animeStats!.count} anime',
                              size: 11,
                              color: theme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (user.mangaStats != null) ...[
                            Icon(Icons.book_outlined,
                                size: 12, color: theme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            AnymexText(
                              text: '${user.mangaStats!.count} manga',
                              size: 11,
                              color: theme.onSurfaceVariant,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (user.isFollowing)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AnymexText(
                      text: 'Following',
                      size: 10,
                      variant: TextVariant.semiBold,
                      color: theme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _StaffSearchTab extends StatefulWidget {
  final AnilistAuth auth;
  final TextEditingController searchController;
  const _StaffSearchTab({required this.auth, required this.searchController});

  @override
  State<_StaffSearchTab> createState() => _StaffSearchTabState();
}

class _StaffSearchTabState extends State<_StaffSearchTab>
    with AutomaticKeepAliveClientMixin {
  List<SearchStaff> _results = [];
  bool _isLoading = false;
  bool _hasNextPage = false;
  int _page = 1;
  String _lastQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = widget.searchController.text.trim();
    if (query != _lastQuery && query.isNotEmpty) {
      _search();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasNextPage) {
      _loadMore();
    }
  }

  Future<void> _search() async {
    final query = widget.searchController.text.trim();
    if (query.isEmpty) return;
    if (query == _lastQuery && _results.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _page = 1;
      _lastQuery = query;
    });

    final (results, hasNext) =
        await widget.auth.searchStaff(query: query, page: 1);
    if (mounted) {
      setState(() {
        _results = results;
        _hasNextPage = hasNext;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasNextPage) return;
    setState(() => _isLoading = true);
    _page++;
    final (results, hasNext) =
        await widget.auth.searchStaff(query: _lastQuery, page: _page);
    if (mounted) {
      setState(() {
        _results.addAll(results);
        _hasNextPage = hasNext;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.colors;

    if (_isLoading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: AnymexText(
          text: _lastQuery.isEmpty
              ? 'Search for staff on AniList'
              : 'No staff found',
          color: theme.onSurfaceVariant,
          size: 14,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _results.length + (_hasNextPage ? 1 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        if (index == _results.length && _hasNextPage) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _isLoading
                  ? CircularProgressIndicator(
                      color: theme.primary, strokeWidth: 2)
                  : TextButton(
                      onPressed: _loadMore,
                      child: AnymexText(
                          text: 'Load More', color: theme.primary),
                    ),
            ),
          );
        }
        return _buildStaffCard(_results[index], theme);
      },
    );
  }

  Widget _buildStaffCard(SearchStaff staff, ColorScheme theme) {
    final occupations = staff.occupations.take(2).join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => launchUrlString('https://anilist.co/staff/${staff.id}'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surfaceContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.outline.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: staff.imageUrl ?? '',
                    width: 48,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 60,
                      color: theme.surfaceContainerHighest,
                      child: const Icon(Icons.person, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymexText(
                        text: staff.name,
                        variant: TextVariant.semiBold,
                        size: 14,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (staff.nativeName != null &&
                          staff.nativeName!.isNotEmpty)
                        AnymexText(
                          text: staff.nativeName!,
                          size: 12,
                          color: theme.onSurfaceVariant,
                        ),
                      if (occupations.isNotEmpty)
                        AnymexText(
                          text: occupations,
                          size: 11,
                          color: theme.primary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (staff.isFavourite)
                  Icon(Icons.favorite, size: 16, color: Colors.redAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _CharacterSearchTab extends StatefulWidget {
  final AnilistAuth auth;
  final TextEditingController searchController;
  const _CharacterSearchTab(
      {required this.auth, required this.searchController});

  @override
  State<_CharacterSearchTab> createState() => _CharacterSearchTabState();
}

class _CharacterSearchTabState extends State<_CharacterSearchTab>
    with AutomaticKeepAliveClientMixin {
  List<SearchCharacter> _results = [];
  bool _isLoading = false;
  bool _hasNextPage = false;
  int _page = 1;
  String _lastQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = widget.searchController.text.trim();
    if (query != _lastQuery && query.isNotEmpty) {
      _search();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasNextPage) {
      _loadMore();
    }
  }

  Future<void> _search() async {
    final query = widget.searchController.text.trim();
    if (query.isEmpty) return;
    if (query == _lastQuery && _results.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _page = 1;
      _lastQuery = query;
    });

    final (results, hasNext) =
        await widget.auth.searchCharacters(query: query, page: 1);
    if (mounted) {
      setState(() {
        _results = results;
        _hasNextPage = hasNext;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasNextPage) return;
    setState(() => _isLoading = true);
    _page++;
    final (results, hasNext) =
        await widget.auth.searchCharacters(query: _lastQuery, page: _page);
    if (mounted) {
      setState(() {
        _results.addAll(results);
        _hasNextPage = hasNext;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.colors;

    if (_isLoading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: AnymexText(
          text: _lastQuery.isEmpty
              ? 'Search for characters on AniList'
              : 'No characters found',
          color: theme.onSurfaceVariant,
          size: 14,
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _results.length + (_hasNextPage ? 6 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        if (index >= _results.length) {
          if (_isLoading) {
            return Center(
              child: CircularProgressIndicator(
                  color: theme.primary, strokeWidth: 2),
            );
          }
          if (_hasNextPage) _loadMore();
          return const SizedBox.shrink();
        }
        return _buildCharacterCard(_results[index], theme);
      },
    );
  }

  Widget _buildCharacterCard(SearchCharacter character, ColorScheme theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => launchUrlString('https://anilist.co/character/${character.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: character.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: theme.surfaceContainerHighest,
                        child: const Icon(Icons.person, size: 32),
                      ),
                    ),
                    if (character.isFavourite)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite,
                              size: 12, color: Colors.redAccent),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnymexText(
              text: character.name,
              variant: TextVariant.semiBold,
              size: 12,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (character.media.isNotEmpty)
              AnymexText(
                text: character.media.first.title ?? '',
                size: 10,
                color: theme.onSurfaceVariant,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _MediaSearchTab extends StatefulWidget {
  final AnilistAuth auth;
  final TextEditingController searchController;
  final String type;
  const _MediaSearchTab({
    required this.auth,
    required this.searchController,
    required this.type,
  });

  @override
  State<_MediaSearchTab> createState() => _MediaSearchTabState();
}

class _MediaSearchTabState extends State<_MediaSearchTab>
    with AutomaticKeepAliveClientMixin {
  List<SearchMediaResult> _results = [];
  bool _isLoading = false;
  bool _hasNextPage = false;
  int _page = 1;
  String _lastQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = widget.searchController.text.trim();
    if (query != _lastQuery && query.isNotEmpty) {
      _search();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasNextPage) {
      _loadMore();
    }
  }

  Future<void> _search() async {
    final query = widget.searchController.text.trim();
    if (query.isEmpty) return;
    if (query == _lastQuery && _results.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _page = 1;
      _lastQuery = query;
    });

    final (results, hasNext) = await widget.auth.searchMedia(
        query: query, type: widget.type, page: 1);
    if (mounted) {
      setState(() {
        _results = results;
        _hasNextPage = hasNext;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasNextPage) return;
    setState(() => _isLoading = true);
    _page++;
    final (results, hasNext) = await widget.auth.searchMedia(
        query: _lastQuery, type: widget.type, page: _page);
    if (mounted) {
      setState(() {
        _results.addAll(results);
        _hasNextPage = hasNext;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.colors;

    if (_isLoading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: AnymexText(
          text: _lastQuery.isEmpty
              ? 'Search for ${widget.type.toLowerCase()} on AniList'
              : 'No ${widget.type.toLowerCase()} found',
          color: theme.onSurfaceVariant,
          size: 14,
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.52,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _results.length + (_hasNextPage ? 6 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        if (index >= _results.length) {
          if (_isLoading) {
            return Center(
              child: CircularProgressIndicator(
                  color: theme.primary, strokeWidth: 2),
            );
          }
          if (_hasNextPage) _loadMore();
          return const SizedBox.shrink();
        }
        return _buildMediaCard(_results[index], theme);
      },
    );
  }

  Widget _buildMediaCard(SearchMediaResult media, ColorScheme theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          launchUrlString('https://anilist.co/${media.type.toLowerCase()}/${media.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: media.coverUrl ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: theme.surfaceContainerHighest,
                        child: const Icon(Icons.movie, size: 32),
                      ),
                    ),
                    if (media.averageScore != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (media.averageScore! >= 70
                                    ? Colors.green
                                    : media.averageScore! >= 40
                                        ? Colors.amber
                                        : Colors.red)
                                .withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AnymexText(
                            text: '${media.averageScore}',
                            size: 10,
                            variant: TextVariant.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (media.isFavourite)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite,
                              size: 12, color: Colors.redAccent),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnymexText(
              text: media.title,
              variant: TextVariant.semiBold,
              size: 12,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            AnymexText(
              text: [
                media.format != null
                    ? _formatToString(media.format!)
                    : null,
                media.seasonYear?.toString(),
                media.type == 'ANIME'
                    ? media.episodes != null
                        ? '${media.episodes} eps'
                        : null
                    : media.chapters != null
                        ? '${media.chapters} ch'
                        : null,
              ].where((e) => e != null).join(' · '),
              size: 10,
              color: theme.onSurfaceVariant,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatToString(String format) {
    const map = {
      'TV': 'TV',
      'TV_SHORT': 'TV Short',
      'MOVIE': 'Movie',
      'SPECIAL': 'Special',
      'OVA': 'OVA',
      'ONA': 'ONA',
      'MUSIC': 'Music',
      'MANGA': 'Manga',
      'NOVEL': 'Novel',
      'ONE_SHOT': 'One Shot',
    };
    return map[format] ?? format;
  }

  @override
  bool get wantKeepAlive => true;
}
