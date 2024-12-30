import 'package:anymex/api/Mangayomi/Eval/dart/model/video.dart' as model;
import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/Settings/adaptors/player/player_adaptor.dart';
import 'package:anymex/controllers/Settings/settings.dart';
import 'package:anymex/models/Anilist/anilist_media_full.dart';
import 'package:anymex/models/Episode/episode.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:anymex/widgets/minor_widgets/custom_textspan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

class WatchPage extends StatefulWidget {
  final model.Video episodeSrc;
  final Episode currentEpisode;
  final List<Episode?> episodeList;
  final AnilistMediaData anilistData;
  final List<model.Video> episodeTracks;
  const WatchPage(
      {super.key,
      required this.episodeSrc,
      required this.episodeList,
      required this.anilistData,
      required this.currentEpisode,
      required this.episodeTracks});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  late Rx<model.Video> episode;
  late Rx<Episode> currentEpisode;
  late RxList<model.Video> episodeTracks;
  late RxList<Episode?> episodeList;
  late Rx<AnilistMediaData> anilistData;

  // Player Related Stuff
  late Player player;
  late VideoController playerController;
  final isPlaying = true.obs;
  final currentPosition = const Duration(milliseconds: 0).obs;
  final episodeDuration = const Duration(minutes: 24).obs;
  final formattedTime = "00:00".obs;
  final formattedDuration = "24:00".obs;
  final showControls = true.obs;
  final isBuffering = true.obs;
  final bufferred = const Duration(milliseconds: 0).obs;
  final isFullscreen = false.obs;
  final selectedSubIndex = 0.obs;
  final settings = Get.find<Settings>();
  late PlayerSettings playerSettings;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _initRxVariables();
    _initHiveVariables();
    _initPlayer();
    _attachListeners();
  }

  void _initPlayer() {
    player = Player(
        configuration: const PlayerConfiguration(bufferSize: 1024 * 1024 * 64));
    playerController = VideoController(player);
    player.open(Media(episode.value.url));
  }

  void _attachListeners() {
    player.stream.playing.listen((e) {
      isPlaying.value = e;
    });
    player.stream.position.listen((e) {
      currentPosition.value = e;
      formattedTime.value = formatDuration(e);
    });
    player.stream.duration.listen((e) {
      episodeDuration.value = e;
      formattedDuration.value = formatDuration(e);
    });
    player.stream.buffering.listen((e) {
      isBuffering.value = e;
    });
    player.stream.buffer.listen((e) {
      bufferred.value = e;
    });
  }

  void _initRxVariables() {
    episode = Rx<model.Video>(widget.episodeSrc);
    episodeList = RxList<Episode?>(widget.episodeList);
    anilistData = Rx<AnilistMediaData>(widget.anilistData);
    currentEpisode = Rx<Episode>(widget.currentEpisode);
    episodeTracks = RxList<model.Video>(widget.episodeTracks);
  }

  void _initHiveVariables() {
    playerSettings = settings.playerSettings.value;
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String extractQuality(String quality) {
    final extractedQuality =
        quality.split(" ").firstWhere((e) => e.contains("p"));
    return extractedQuality;
  }

  @override
  void dispose() {
    player.dispose();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () => showControls.value = !showControls.value,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Video(
              controller: playerController,
              controls: null,
              fit: resizeModes[playerSettings.resizeMode]!,
            ),
            Positioned.fill(
                child: Obx(() => AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: showControls.value ? 1 : 0,
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ))),
            Positioned.fill(
                child: Obx(
              () => IgnorePointer(
                  ignoring: !showControls.value,
                  child: AnimatedOpacity(
                      opacity: showControls.value ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: _buildControls())),
            )),
          ],
        ),
      ),
    );
  }

  showTrackSelector() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const AnymexText(
                  text: "Choose Track",
                  size: 18,
                  variant: TextVariant.bold,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: episodeTracks.length,
                    itemBuilder: (context, index) {
                      final e = episodeTracks[index];
                      final isSelected = episode.value == e;
                      return GestureDetector(
                        onTap: () {
                          episode.value = e;
                          player.open(Media(e.url,
                              start: currentPosition.value,
                              end: episodeDuration.value));
                          Get.back();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 2.5, horizontal: 10),
                            title: AnymexText(
                              text: e.quality,
                              variant: TextVariant.bold,
                              size: 16,
                              color: isSelected
                                  ? Colors.black
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            tileColor: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            trailing: Icon(
                              Iconsax.play5,
                              color: isSelected
                                  ? Colors.black
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }

  showSubtitleSelector() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (context) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const AnymexText(
                    text: "Choose Subtitle",
                    size: 18,
                    variant: TextVariant.bold,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: episode.value.subtitles?.length ?? 1,
                      itemBuilder: (context, index) {
                        final e = episode.value.subtitles?[index];
                        final isSelected = selectedSubIndex.value == index;
                        return GestureDetector(
                          onTap: () {
                            selectedSubIndex.value = index;
                            player
                                .setSubtitleTrack(SubtitleTrack.uri(e!.file!));
                            Get.back();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 2.5, horizontal: 10),
                              title: AnymexText(
                                text: e?.label ?? 'None',
                                variant: TextVariant.bold,
                                size: 16,
                                color: isSelected
                                    ? Colors.black
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              tileColor: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              trailing: Icon(
                                Iconsax.subtitle5,
                                color: isSelected
                                    ? Colors.black
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildControls() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded)),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(top: 3.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexText(
                      text: (currentEpisode.value.title ??
                                  "Episode ${currentEpisode.value.number}")
                              .contains("Episode")
                          ? '${anilistData.value.name}: ${currentEpisode.value.title ?? "Episode ${currentEpisode.value.number}"}'
                          : currentEpisode.value.title ?? '?',
                      variant: TextVariant.semiBold,
                    ),
                    AnymexText(
                      text: anilistData.value.name,
                      variant: TextVariant.bold,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                children: [
                  Row(
                    children: [
                      _buildIcon(
                          onTap: () {
                            player.pause();
                          },
                          icon: HugeIcons.strokeRoundedPlayList),
                      _buildIcon(
                          onTap: () {}, icon: HugeIcons.strokeRoundedTimer01),
                      _buildIcon(
                          onTap: () {},
                          icon: HugeIcons.strokeRoundedCircleLock01),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnymexText(
                    text:
                        'Quality: ${extractQuality(episode.value.quality).toUpperCase()}',
                    variant: TextVariant.regular,
                    size: 16,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  )
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlaybackButton(icon: Iconsax.previous5, onTap: () {}),
            isBuffering.value
                ? _buildBufferingIndicator()
                : _buildPlaybackButton(
                    icon: isPlaying.value ? Iconsax.pause5 : Iconsax.play5,
                    onTap: () {
                      player.playOrPause();
                    }),
            _buildPlaybackButton(icon: Iconsax.next5, onTap: () {}),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 25.0),
              child: AnymexTextSpans(
                spans: [
                  AnymexTextSpan(
                    text: '${formattedTime.value} ',
                  ),
                  AnymexTextSpan(
                      text: ' /  ${formattedDuration.value}',
                      color: Colors.white54),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 1.3,
                  thumbColor: Theme.of(context).colorScheme.primary,
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: const Color.fromARGB(255, 121, 121, 121),
                  secondaryActiveTrackColor:
                      const Color.fromARGB(255, 167, 167, 167),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: SliderComponentShape.noThumb,
                ),
                child: Slider(
                    min: 0,
                    value: currentPosition.value.inMilliseconds.toDouble(),
                    max: episodeDuration.value.inMilliseconds.toDouble(),
                    secondaryTrackValue:
                        bufferred.value.inMilliseconds.toDouble(),
                    onChangeEnd: (val) {},
                    onChanged: (val) {
                      currentPosition.value =
                          Duration(milliseconds: val.toInt());
                      player.seek(Duration(milliseconds: val.toInt()));
                    }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildIcon(
                      onTap: () {
                        showTrackSelector();
                      },
                      icon: HugeIcons.strokeRoundedFolderDetails),
                  _buildIcon(
                      onTap: () {
                        showSubtitleSelector();
                      },
                      icon: HugeIcons.strokeRoundedSubtitle),
                  const Spacer(),
                  _buildIcon(onTap: () {}, icon: Icons.aspect_ratio_rounded),
                  _buildIcon(
                      onTap: () async {
                        await windowManager.setFullScreen(!isFullscreen.value);
                        isFullscreen.value = !isFullscreen.value;
                      },
                      icon: !isFullscreen.value
                          ? Icons.fullscreen
                          : Icons.fullscreen_exit_rounded),
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  InkWell _buildPlaybackButton(
      {required Function() onTap, IconData? icon, double size = 60}) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 50.0 : 25),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: isDesktop ? size : 50),
        ),
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 50.0 : 25),
      child: const SizedBox(
          height: 70, width: 70, child: CircularProgressIndicator()),
    );
  }

  Widget _buildIcon({VoidCallback? onTap, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: IconButton(onPressed: onTap, icon: Icon(icon)),
    );
  }
}
