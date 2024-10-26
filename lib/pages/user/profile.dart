import 'dart:io';
import 'dart:ui';
import 'package:aurora/auth/auth_provider.dart';
import 'package:aurora/components/anilistExclusive/animeListCarousels.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _avatarImage;

  // var box = Hive.box('login-data');
  // final userInfo =
  //     box.get('userInfo', defaultValue: ['Guest', 'Guest', 'null']);
  // final userName = userInfo?[0] ?? 'Guest';
  // final avatarImagePath = userInfo?[2] ?? 'null';
  // final isLoggedIn = userName != 'Guest';
  // final hasAvatarImage = avatarImagePath != 'null';
  // final totalWatchedAnimes =
  //     Provider.of<AppData>(context).watchedAnimes?.length.toString() ?? '00';
  // final totalReadManga =
  //     Provider.of<AppData>(context).readMangas?.length.toString() ?? '00';
  // final hiveBox = Hive.box('app-data');
  // final List<dynamic>? watchingAnimeList = hiveBox.get('currently-watching');
  // final List<dynamic>? readingMangaList = hiveBox.get('currently-reading');

  dynamic filterData(dynamic animeList) {
    if (animeList != null) {
      return animeList.where((anime) => anime['status'] == 'CURRENT').toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AniListProvider>(
        builder: (context, anilistProvider, child) {
          final isLoggedIn = anilistProvider.userData?['user']?['id'] != null;
          final userName =
              isLoggedIn ? anilistProvider.userData?['user']?['name'] : 'Guest';
          final avatarUrl = isLoggedIn
              ? (anilistProvider.userData?['user']?['avatar']?['large'])
              : null;
          final totalWatchedAnimes = isLoggedIn
              ? anilistProvider.userData?['user']?['statistics']?['anime']
                  ?['count']
              : 0;
          final totalReadManga = isLoggedIn
              ? anilistProvider.userData?['user']?['statistics']?['manga']
                  ?['count']
              : 0;
          final followers = isLoggedIn ? 0 : 0;
          final following = isLoggedIn ? 0 : 0;
          final hasAvatarImage = avatarUrl != null;
          final animeList = filterData(anilistProvider.userData['animeList']);
          // final mangaList = filterData(anilistProvider.userData['mangaList']);

          return ListView(
            children: [
              Stack(
                children: [
                  Positioned(
                    height: 200,
                    width: MediaQuery.of(context).size.width,
                    child: Stack(
                      children: [
                        if (hasAvatarImage)
                          ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: SizedBox.expand(
                                child: Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.8),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Theme.of(context).colorScheme.surface,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0, 1],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 15,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(IconlyBold.arrow_left),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainer
                            .withOpacity(0.7),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 70),
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainer,
                          backgroundImage:
                              hasAvatarImage ? NetworkImage(avatarUrl) : null,
                          child: !hasAvatarImage
                              ? Icon(
                                  Icons.person,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inverseSurface,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatContainer(
                            isFirst: true,
                            isLast: false,
                            label: 'Followers',
                            value: followers.toString(),
                          ),
                          _buildStatContainer(
                            isFirst: false,
                            isLast: false,
                            label: 'Following',
                            value: following.toString(),
                          ),
                          _buildStatContainer(
                            isFirst: false,
                            isLast: false,
                            label: 'Anime',
                            value: totalWatchedAnimes.toString(),
                          ),
                          _buildStatContainer(
                            isFirst: false,
                            isLast: true,
                            label: 'Manga',
                            value: totalReadManga.toString(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stats',
                              style: TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              margin: const EdgeInsets.all(5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                              ),
                              child: Column(
                                children: [
                                  StatsRow(
                                    name: 'Episodes Watched',
                                    value: anilistProvider.userData['user']
                                                ?['statistics']?['anime']
                                                ?['episodesWatched']
                                            ?.toString() ??
                                        '0',
                                  ),
                                  StatsRow(
                                    name: 'Minutes Watched',
                                    value: anilistProvider.userData['user']
                                                ?['statistics']?['anime']
                                                ?['minutesWatched']
                                            ?.toString() ??
                                        '0',
                                  ),
                                  StatsRow(
                                      name: 'Anime Mean Score',
                                      value: anilistProvider.userData['user']
                                                  ?['statistics']?['anime']
                                                  ?['meanScore']
                                              ?.toString() ??
                                          '0.0'),
                                  StatsRow(
                                    name: 'Chapters Read',
                                    value: anilistProvider.userData['user']
                                                ?['statistics']?['manga']
                                                ?['chaptersRead']
                                            ?.toString() ??
                                        '0',
                                  ),
                                  StatsRow(
                                    name: 'Volume Read',
                                    value: anilistProvider.userData['user']
                                                ?['statistics']?['manga']
                                                ?['volumeRead']
                                            ?.toString() ??
                                        '0',
                                  ),
                                  StatsRow(
                                    name: 'Manga Mean Score',
                                    value: anilistProvider.userData['user']
                                                ?['statistics']?['manga']
                                                ?['meanScore']
                                            ?.toString() ??
                                        '0.0',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      anilistCarousel(
                        title: 'Currently Watching',
                        carouselData: animeList,
                        tag: 'currently-watching',
                      ),
                      // anilistCarousel(
                      //   title: 'Currently Reading',
                      //   carouselData: mangaList,
                      //   tag: 'currently-reading',
                      //   rawData: rawDataManga,
                      //   isManga: true,
                      // ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUsernameDialog(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          content: TextFormField(
            controller: usernameController,
            decoration: InputDecoration(
                hintText: 'Username',
                fillColor: Theme.of(context).colorScheme.surfaceContainer),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              width: 2,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryFixedVariant)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      _submitUsername(usernameController.text);
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  void _submitUsername(String newUsername) {
    if (newUsername.isNotEmpty) {
      var box = Hive.box('login-data');
      var userInfo =
          box.get('userInfo', defaultValue: ['Guest', 'Guest', 'null']);
      userInfo[0] = newUsername;
      box.put('userInfo', userInfo);
      setState(() {});
    }
  }

  Widget _buildStatContainer({
    required String label,
    required String value,
    required bool isFirst,
    required bool isLast,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.23,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(10) : Radius.zero,
          bottomLeft: isFirst ? const Radius.circular(10) : Radius.zero,
          topRight: isLast ? const Radius.circular(10) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(10) : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showAvatarSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AvatarModal(
          onAvatarSelected: (File avatar) {
            setState(() {
              _avatarImage = avatar;
            });
            Hive.box('login-data').put('userInfo', [
              Hive.box('login-data').get('userInfo')[0],
              Hive.box('login-data').get('userInfo')[1],
              _avatarImage?.path ?? 'null',
            ]);
          },
        );
      },
    );
  }
}

class StatsRow extends StatelessWidget {
  final String name;
  final String value;
  const StatsRow({
    super.key,
    required this.name,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.inverseSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class AvatarModal extends StatefulWidget {
  final Function(File) onAvatarSelected;

  const AvatarModal({required this.onAvatarSelected, super.key});

  @override
  State<AvatarModal> createState() => _AvatarModalState();
}

class _AvatarModalState extends State<AvatarModal> {
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage =
          await File(pickedFile.path).copy('${directory.path}/$fileName');

      widget.onAvatarSelected(savedImage);
      Navigator.pop(context);
    }
  }

  Future<void> _selectAvatar(String assetPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = path.basename(assetPath);
    final byteData = await DefaultAssetBundle.of(context).load(assetPath);
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    widget.onAvatarSelected(file);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Choose your avatar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(IconlyBold.image, size: 50),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _selectAvatar('assets/images/avatars/avatar1.png'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/avatars/avatar1.png',
                        fit: BoxFit.cover,
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _selectAvatar('assets/images/avatars/avatar2.png'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/avatars/avatar2.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _selectAvatar('assets/images/avatars/avatar3.png'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/avatars/avatar3.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _selectAvatar('assets/images/avatars/avatar4.png'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/avatars/avatar4.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _selectAvatar('assets/images/avatars/avatar5.png'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/avatars/avatar5.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
