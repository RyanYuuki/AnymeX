import 'dart:convert';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.ean13],
  );
  bool isScanning = false;
  bool isFlashOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSearch(String isbn) async {
    if (isScanning) return;
    setState(() => isScanning = true);

    String? foundTitle;

    try {
      try {
         snackBar("Searching for ISBN: $isbn...");
      } catch (_) {}

      //Try Google Books API
      String googleUrl = 'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn';
      final apiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        googleUrl += '&key=$apiKey';
      }

      http.Response? googleRes;
      try {
        googleRes = await http
            .get(Uri.parse(googleUrl))
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        googleRes = null;
      }

      if (googleRes?.statusCode == 200) {
        final data = jsonDecode(googleRes!.body);
        if (data['totalItems'] != null && data['totalItems'] > 0) {
          foundTitle = data['items'][0]['volumeInfo']['title'];
        }
      }

      //Fallback to OpenLibrary if Google failed or found nothing
      if (foundTitle == null) {
        if (googleRes == null || googleRes.statusCode != 200) {
           try { snackBar("Google limit reached, trying OpenLibrary..."); } catch (_) {}
        }
        
        final olUrl = Uri.parse('https://openlibrary.org/search.json?isbn=$isbn');
        final olRes = await http.get(olUrl).timeout(const Duration(seconds: 5));

        if (olRes.statusCode == 200) {
          final data = jsonDecode(olRes.body);
          if (data['numFound'] != null && data['numFound'] > 0) {
            foundTitle = data['docs'][0]['title'];
          }
        }
      }

      if (foundTitle != null) {
        // Clean title: "One Piece, Vol. 1" -> "One Piece"
        String cleanTitle = foundTitle!.split(',')[0].split('(')[0].trim();
        
        if (mounted) {
          Get.off(() => SearchPage(
                searchTerm: cleanTitle,
                isManga: true,
              ));
        }
      } else {
        try { snackBar("Book not found for ISBN: $isbn"); } catch (_) {}
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) setState(() => isScanning = false);
      }
    } catch (e) {
      try { snackBar("Error: ${e.toString()}"); } catch (_) {}
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => isScanning = false);
    }
  }

  void _toggleFlash() {
    controller.toggleTorch();
    setState(() {
      isFlashOn = !isFlashOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Glow(
      child: Scaffold(
        body: Stack(
          children: [
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null && !isScanning) {
                    _fetchAndSearch(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstIn,
                    ),
                  ),
                  Center(
                    child: Container(
                      height: 250,
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                height: 250,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: isScanning
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Get.back(),
                          ),
                        ),
                        AnymexText(
                          text: "Scan Manga/Novel",
                          variant: TextVariant.bold,
                          color: Colors.white,
                          size: 18,
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: Icon(
                              isFlashOn ? Iconsax.flash_15 : Iconsax.flash_1,
                              color: isFlashOn ? Colors.yellow : Colors.white,
                            ),
                            onPressed: _toggleFlash,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.only(bottom: 50),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const AnymexText(
                      text: "Align barcode within the frame",
                      color: Colors.white,
                      variant: TextVariant.semiBold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
