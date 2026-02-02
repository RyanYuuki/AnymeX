import 'dart:io';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AnimeVisualsPage extends StatefulWidget {
  final String animeTitle;
  final String? malId;

  const AnimeVisualsPage({
    super.key,
    required this.animeTitle,
    required this.malId,
  });

  @override
  State<AnimeVisualsPage> createState() => _AnimeVisualsPageState();
}

class _AnimeVisualsPageState extends State<AnimeVisualsPage> {
  bool isLoading = true;
  List<String> liveChartImages = [];
  List<String> malImages = [];

  @override
  void initState() {
    super.initState();
    _fetchAllVisuals();
  }

  Future<void> _fetchAllVisuals() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchLiveChartVisuals(),
      _fetchMalVisuals(),
    ]);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchMalVisuals() async {
    if (widget.malId == null) return;
    try {
      final url = 'https://myanimelist.net/anime/${widget.malId}/_/pics';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final elements = document.querySelectorAll('div.picSurround a');

        final images = elements
            .map((e) => e.attributes['href'])
            .where((href) => href != null && href.contains('.jpg'))
            .cast<String>()
            .toList();

        if (mounted) {
          setState(() {
            malImages = images;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching MAL visuals: $e");
    }
  }

  Future<void> _fetchLiveChartVisuals() async {
    try {
      final searchUrl =
          'https://www.livechart.me/search?q=${Uri.encodeComponent(widget.animeTitle)}';
      final searchResponse = await http.get(Uri.parse(searchUrl));

      if (searchResponse.statusCode == 200) {
        final searchDoc = parser.parse(searchResponse.body);
        final firstResult = searchDoc.querySelector('.anime-item');
        
        final linkElement = firstResult?.querySelector('.anime-item__body__title a');
        final animePath = linkElement?.attributes['href'];

        if (animePath != null) {
          final visualsUrl = 'https://www.livechart.me$animePath/visuals';
          final visualResponse = await http.get(Uri.parse(visualsUrl));

          if (visualResponse.statusCode == 200) {
            final visualDoc = parser.parse(visualResponse.body);
            final visualCards = visualDoc.querySelectorAll('[data-anime-visual-url-value]');
            
            final images = visualCards
                .map((e) => e.attributes['data-anime-visual-url-value'])
                .where((url) => url != null)
                .cast<String>()
                .toList();

            if (mounted) {
              setState(() {
                liveChartImages = images;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching LiveChart visuals: $e");
    }
  }

  Future<void> _saveImage(String url) async {
    try {
      snackBar("Downloading image...");
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        snackBar("Failed to download image");
        return;
      }

      final bytes = response.bodyBytes;
      final fileName = "anymex_${DateTime.now().millisecondsSinceEpoch}.jpg";

      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        
        final downloadsDir = await getDownloadsDirectory(); 
        final saveDir = Directory('${downloadsDir?.path ?? '.'}/AnymeX');
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }
        
        final file = File('${saveDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        snackBar("Saved to: ${file.path}");
      } else {
       
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: "Visual from AnymeX");
      }
    } catch (e) {
      snackBar("Error saving image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            NestedHeader(title: 'Visuals'),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (liveChartImages.isNotEmpty) ...[
                            _buildSourceHeader(
                              context, 
                              "LiveChart.me", 
                              "https://www.livechart.me/favicon_32x32.png"
                            ),
                            const SizedBox(height: 10),
                            _buildImageGrid(liveChartImages),
                            const SizedBox(height: 30),
                          ],
                          if (malImages.isNotEmpty) ...[
                            _buildSourceHeader(
                              context, 
                              "MyAnimeList", 
                              "https://cdn.myanimelist.net/images/favicon.ico"
                            ),
                            const SizedBox(height: 10),
                            _buildImageGrid(malImages),
                            const SizedBox(height: 30),
                          ],
                          if (liveChartImages.isEmpty && malImages.isEmpty)
                             const Center(
                               child: Padding(
                                 padding: EdgeInsets.only(top: 50.0),
                                 child: AnymexText(
                                   text: "No visuals found.",
                                   variant: TextVariant.bold,
                                   size: 16,
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
    );
  }

  Widget _buildSourceHeader(BuildContext context, String title, String iconUrl) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: CachedNetworkImage(
            imageUrl: iconUrl, 
            height: 20, 
            width: 20,
            errorWidget: (context, url, error) => const Icon(Icons.image, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        AnymexText(
          text: title,
          size: 18,
          variant: TextVariant.bold,
        ),
      ],
    );
  }

  Widget _buildImageGrid(List<String> images) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 5 : 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onLongPress: () => _saveImage(images[index]),
          onSecondaryTap: () => _saveImage(images[index]),
          onTap: () {
            Get.to(
              () => _FullScreenImageViewer(
                imageUrl: images[index],
                onSave: () => _saveImage(images[index]),
              ),
              transition: Transition.fadeIn,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onSave;

  const _FullScreenImageViewer({required this.imageUrl, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            onPressed: onSave,
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Save Image',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
