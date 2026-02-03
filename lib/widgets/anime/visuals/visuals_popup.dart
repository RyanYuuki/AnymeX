import 'dart:ui';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum VisualSource { anilist, livechart, mal }

class VisualsPopup extends StatefulWidget {
  final String animeTitle;
  final String? malId;
  final String originalCover;

  const VisualsPopup({
    super.key,
    required this.animeTitle,
    required this.malId,
    required this.originalCover,
  });

  @override
  State<VisualsPopup> createState() => _VisualsPopupState();
}

class _VisualsPopupState extends State<VisualsPopup> {
  VisualSource currentSource = VisualSource.anilist;
  Map<VisualSource, List<String>> images = {
    VisualSource.anilist: [],
    VisualSource.livechart: [],
    VisualSource.mal: [],
  };

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    images[VisualSource.anilist] = [widget.originalCover];
    _fetchLiveChartVisuals();
    _fetchMalVisuals();
  }

  Future<void> _fetchMalVisuals() async {
    if (widget.malId == null) return;
    try {
      final url = 'https://myanimelist.net/anime/${widget.malId}/_/pics';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final elements = document.querySelectorAll('div.picSurround a');

        final scrapedImages = elements
            .map((e) => e.attributes['href'])
            .where((href) => href != null && (href.contains('.jpg') || href.contains('.png') || href.contains('.webp')))
            .map((href) {
               
                var clean = href!;
                if (clean.contains('/r/') && clean.contains('/images/')) {
                  
                   final regex = RegExp(r'/r/\d+x\d+');
                   clean = clean.replaceAll(regex, '');
                }
                if (clean.contains('?')) {
                  clean = clean.split('?').first;
                }
                return clean;
            })
            .cast<String>()
            .toList();

        if (mounted) {
          setState(() {
            images[VisualSource.mal] = scrapedImages;
          });
        }
      }
    } catch (e) {
      Logger.e("MAL Visuals Error", error: e);
    }
  }

  Future<void> _fetchLiveChartVisuals() async {
    try {
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'Accept-Language': 'en-US,en;q=0.9',
        'Referer': 'https://www.google.com/',
        'Upgrade-Insecure-Requests': '1',
      };

      final searchUrl =
          'https://www.livechart.me/search?q=${Uri.encodeComponent(widget.animeTitle)}';
      final searchResponse =
          await http.get(Uri.parse(searchUrl), headers: headers);

      if (searchResponse.statusCode == 200) {
        final searchDoc = parser.parse(searchResponse.body);
        var linkElement =
            searchDoc.querySelector('.anime-item .anime-item__body__title a') ??
                searchDoc.querySelector('.callout .media-body a');

        final animePath = linkElement?.attributes['href'];

        if (animePath != null) {
          final visualsUrl = 'https://www.livechart.me$animePath/visuals';
          final visualResponse =
              await http.get(Uri.parse(visualsUrl), headers: headers);

          if (visualResponse.statusCode == 200) {
            final visualDoc = parser.parse(visualResponse.body);
            final visualCards =
                visualDoc.querySelectorAll('[data-anime-visual-url-value]');

            final scrapedImages = visualCards
                .map((e) => e.attributes['data-anime-visual-url-value'])
                .where((url) => url != null)
                .cast<String>()
                .toList();

            if (mounted) {
              setState(() {
                images[VisualSource.livechart] = scrapedImages;
              });
            }
          }
        }
      }
    } catch (e) {
      Logger.e("LiveChart Visuals Error", error: e);
    }
  }

  Future<void> _saveImage(String url) async {
    try {
      snackBar("Downloading image...", context: context);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        snackBar("Failed to download image", context: context);
        return;
      }

      final bytes = response.bodyBytes;
      
      String extension = "jpg";
      try {
        final uri = Uri.parse(url);
        final path = uri.path;
        if (path.contains('.')) {
          extension = path.split('.').last;
          if (extension.length > 4 || extension.contains('/')) extension = "jpg";
        }
      } catch (_) {}
      
      final fileName = "anymex_${DateTime.now().millisecondsSinceEpoch}.$extension";

      if (Platform.isAndroid) {
         Future<bool> check(Permission p) async {
            var status = await p.status;
            if (!status.isGranted) {
               status = await p.request();
            }
            return status.isGranted;
         }

         await check(Permission.storage);
         await check(Permission.photos);
         await check(Permission.manageExternalStorage);

        try {
          final directory = Directory('/storage/emulated/0/Download/AnymeX');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(bytes);
          
          try {
            const platform = MethodChannel('com.ryan.anymex/utils');
            await platform.invokeMethod('scanFile', {'path': file.path});
          } catch(_) {}

          snackBar("Saved to Downloads/AnymeX/$fileName", context: context);
          
        } catch (e) {
           // Fallback
           final tempDir = await getTemporaryDirectory();
           final file = File('${tempDir.path}/$fileName');
           await file.writeAsBytes(bytes);
           await Share.shareXFiles([XFile(file.path)], text: "Visual from AnymeX");
        }
      } else if (Platform.isIOS) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: "Visual from AnymeX");
      } else {
        // pc
        String? downloadPath = (await getDownloadsDirectory())?.path;

       
        if (Platform.isLinux || Platform.isMacOS) {
          final home = Platform.environment['HOME'];
          if (home != null) {
           
            final cleanDownload = downloadPath?.replaceAll(RegExp(r'/$'), '');
            final cleanHome = home.replaceAll(RegExp(r'/$'), '');
            
            if (cleanDownload == null || cleanDownload == cleanHome) {
              downloadPath = '$cleanHome/Downloads';
            }
          }
        } 
        
        else if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
           if (userProfile != null && (downloadPath == null || downloadPath == userProfile)) {
             downloadPath = '$userProfile\\Downloads';
           }
        }

        final path = downloadPath ?? '.';
        final saveDir = Directory('$path/AnymeX');
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }

        final file = File('${saveDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        snackBar("Saved to $path/AnymeX", context: context);
      }
    } catch (e) {
      snackBar("Error saving image", context: context); 
    }
  }

  void _switchSource(VisualSource source) {
    setState(() {
      currentSource = source;
      currentIndex = 0;
    });
  }

  void _nextImage() {
    final currentList = images[currentSource] ?? [];
    if (currentList.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex + 1) % currentList.length;
    });
  }

  void _prevImage() {
    final currentList = images[currentSource] ?? [];
    if (currentList.isEmpty) return;
    setState(() {
      currentIndex =
          (currentIndex - 1 + currentList.length) % currentList.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentList = images[currentSource] ?? [];
   
    final effectiveIndex = (currentIndex < currentList.length) ? currentIndex : 0;
    final currentImage =
        currentList.isNotEmpty ? currentList[effectiveIndex] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
         
          Positioned.fill(
            child: Container(
              color: Colors.black,
            ),
          ),
          
          // Main thing
          Positioned.fill(
              child: GestureDetector(
            onTapUp: (details) {
              final width = MediaQuery.of(context).size.width;
              if (width > 0) {
                if (details.localPosition.dx < width / 3) {
                  _prevImage();
                } else {
                  _nextImage();
                }
              }
            },
            onLongPress: () {
              if (currentImage != null) _saveImage(currentImage);
            },
            child: (currentImage != null && currentImage.isNotEmpty)
                ? SizedBox.expand(
                    child: ClipRect(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: currentImage,
                          key: ValueKey(currentImage), 
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image,
                                    color: Colors.white, size: 50),
                                const SizedBox(height: 10),
                                AnymexText(
                                  text: "Failed to load image",
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: AnymexText(
                      text: "No Visuals found for this Anime (╥﹏╥)",
                      color: Colors.white,
                    ),
                  ),
          )),

          // top 
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(10, MediaQuery.of(context).padding.top + 10, 10, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                 _buildCircleButton(
                    icon: Icons.close,
                    onTap: () => Get.back(),
                  ),
                  if (currentList.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                          )
                        ]
                      ),
                      child: AnymexText(
                        text: "${effectiveIndex + 1} / ${currentList.length}",
                        color: Colors.white,
                        variant: TextVariant.bold,
                      ),
                    ),
                  if (currentImage != null)
                   _buildCircleButton(
                    icon: Icons.download_rounded,
                    onTap: () => _saveImage(currentImage),
                  ),
                ],
              ),
            ),
          ),

         
          // Bottom 3 
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                       boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ]
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSourceButton(
                              "Anilist", VisualSource.anilist, "https://anilist.co/img/icons/android-chrome-192x192.png", const Color(0xFF02A9FF)),
                          _buildSourceButton(
                              "LiveChart", VisualSource.livechart, "https://www.livechart.me/favicon_32x32.png", const Color(0xFF5ABF16)),
                          _buildSourceButton(
                              "MAL", VisualSource.mal, "https://cdn.myanimelist.net/img/sp/icon/apple-touch-icon-256.png", const Color(0xFF2E51A2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildSourceButton(
      String label, VisualSource source, String iconUrl, Color brandColor) {
    final isSelected = currentSource == source;
    return GestureDetector(
      onTap: () => _switchSource(source),

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? brandColor : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isSelected ? brandColor.withOpacity(0.5) : Colors.transparent
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandColor.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            CachedNetworkImage(
                imageUrl: iconUrl,
                height: 24,
                width: 24,
                errorWidget: (context, url, error) => Icon(Icons.image, size: 24, color: isSelected ? Colors.white : Colors.white.withOpacity(0.7)),
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              AnymexText(
                text: label,
                color: Colors.white,
                variant: TextVariant.bold,
                size: 14,
              ),
            ]
          ],
        ),
      ),
    );
  }



}
