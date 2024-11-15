import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

enum MediaType { anime, manga, novel }

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => DownloadPageState();
}

class DownloadPageState extends State<DownloadPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int currentIndex = 0;
  final _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      setState(() {
        currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getSearchPlaceholder() {
    switch (currentIndex) {
      case 0:
        return 'Search Anime...';
      case 1:
        return 'Search Manga...';
      case 2:
        return 'Search Novel...';
      default:
        return 'Search...';
    }
  }

  Widget _buildAnimeDownloadList(List<dynamic> animeDownloads) {
    if (animeDownloads.isEmpty) {
      return const Center(
        child: Text(
          'No Anime Downloads',
          style: TextStyle(fontSize: 18),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: animeDownloads.length,
      itemBuilder: (context, index) {
        final anime = animeDownloads[index];
        final episodeNumber = anime['episodeNumber'];
        final episodeTitle = anime['episodeTitle'];
        final episodeImage = anime['episodeImage'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Theme.of(context).colorScheme.surface,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: episodeImage,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[800]!,
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[800],
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            title: Text(
              'Episode $episodeNumber',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              episodeTitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Icon(
              Icons.play_arrow_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderSection(String text) {
    return Center(
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
            expandedHeight: 150,
            floating: true,
            pinned: true,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'Downloads',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
          ),
        ],
        body: ValueListenableBuilder(
          valueListenable: Hive.box('app-data').listenable(),
          builder: (context, appBox, child) {
            final dynamic animeDownloads = [];
            final dynamic mangaDownloads =
                appBox.get('mangaDownloads')?.reversed.toList() ?? [];
            final dynamic novelDownloads =
                appBox.get('novelDownloads')?.reversed.toList() ?? [];

            return TabBarView(
              controller: _tabController,
              children: [
                _buildAnimeDownloadList(animeDownloads),
                _buildPlaceholderSection('Manga downloads will be added soon.'),
                _buildPlaceholderSection('Novel downloads will be added soon.'),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: TabBar(
        padding: const EdgeInsets.only(bottom: 15),
        splashBorderRadius: BorderRadius.circular(12),
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.white,
        tabs: const [
          Tab(
            icon: Icon(
              Icons.movie_outlined,
            ),
            text: 'Anime',
          ),
          Tab(
            icon: Icon(
              Iconsax.book,
            ),
            text: 'Manga',
          ),
          Tab(
            icon: Icon(
              Icons.menu_book_outlined,
            ),
            text: 'Novel',
          ),
        ],
      ),
    );
  }
}
