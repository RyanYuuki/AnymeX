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

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.ean13], // ISBNs are usually EAN-13
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

    try {
      snackBar("Searching for ISBN: $isbn...");
      final url =
          Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['totalItems'] != null && data['totalItems'] > 0) {
          String title = data['items'][0]['volumeInfo']['title'];
          // Clean title: "One Piece, Vol. 1" -> "One Piece"
          title = title.split(',')[0].split('(')[0].trim();

          if (mounted) {
            Get.off(() => SearchPage(
                  searchTerm: title,
                  isManga: true,
                ));
          }
        } else {
          snackBar("Book not found for ISBN: $isbn");
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => isScanning = false);
        }
      } else {
        throw Exception("API Error");
      }
    } catch (e) {
      snackBar("Error: ${e.toString()}");
      await Future.delayed(const Duration(seconds: 2));
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

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                  
                  Container(
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
