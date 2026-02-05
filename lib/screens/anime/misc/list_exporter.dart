import 'dart:io';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ExportService { anilist, mal }

class ListExporterPage extends StatefulWidget {
  final bool isManga;
  const ListExporterPage({super.key, required this.isManga});

  @override
  State<ListExporterPage> createState() => _ListExporterPageState();
}

class _ListExporterPageState extends State<ListExporterPage> {
  final serviceHandler = Get.find<ServiceHandler>();
  final TextEditingController _usernameController = TextEditingController();
  
  ExportService _selectedService = ExportService.anilist;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoFillDetails();
  }

  void _autoFillDetails() {
    if (serviceHandler.isLoggedIn.value) {
      final currentService = serviceHandler.serviceType.value;
      
      if (currentService == ServicesType.mal) {
        _selectedService = ExportService.mal;
      } else {
        _selectedService = ExportService.anilist;
      }

      if (serviceHandler.profileData.value.name != null) {
        _usernameController.text = serviceHandler.profileData.value.name!;
      }
    }
  }

  Future<void> _exportList() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a username")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String listType = '';
      if (widget.isManga) {
        listType = _selectedService == ExportService.anilist ? 'anilistmanga' : 'manga';
      } else {
        listType = _selectedService == ExportService.anilist ? 'anilistanime' : 'anime';
      }

      final body = {
        'username': username,
        'listtype': listType,
        'update_on_import': 'on',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Generating XML list... this may take a moment.")),
      );
      final response = await http.post(
        Uri.parse('https://malscraper.azurewebsites.net/scrape'),
        body: body,
      );

      if (response.statusCode == 200) {
        final xmlContent = response.body;
        
        if (xmlContent.isEmpty || xmlContent.contains('error')) {
             throw Exception("Invalid response from server. Check username/privacy settings.");
        }

        final tempDir = await getTemporaryDirectory();
        final fileName = '${username}_${listType}_list.xml';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(xmlContent);

        setState(() => _isLoading = false);
        
        // Using Share Plus to let user save to Downloads/Drive/etc.
        // This avoids Android 11+ Scoped Storage permission headaches
        await Share.shareXFiles(
          [XFile(file.path)], 
          text: 'Here is your exported ${widget.isManga ? "Manga" : "Anime"} list.',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Export ready! Choose where to save it.")),
          );
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export Failed: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Glow(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          title: AnymexText(
            text: "${widget.isManga ? "Manga" : "Anime"} List Exporter",
            variant: TextVariant.bold,
            size: 18,
            color: colorScheme.primary,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AnymexText(
                      text: "Select Source",
                      variant: TextVariant.bold,
                      size: 16,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _buildRadio(ExportService.anilist, "AniList"),
                        const SizedBox(width: 15),
                        _buildRadio(ExportService.mal, "MyAnimeList"),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const AnymexText(
                      text: "Username",
                      variant: TextVariant.bold,
                      size: 16,
                    ),
                    const SizedBox(height: 10),
                    CustomSearchBar(
                      controller: _usernameController,
                      hintText: "Enter username",
                      disableIcons: true,
                      onSubmitted: (_) {},
                    ),
                     const SizedBox(height: 10),
                    const AnymexText(
                      text: "Note: Your list must be public.",
                      size: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: AnymexButton(
                  onTap: _exportList,
                  radius: 100,
                  height: 55,
                  child: _isLoading
                      ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             const Icon(HugeIcons.strokeRoundedDownload01, color: Colors.white),
                             const SizedBox(width: 10),
                             AnymexText(
                               text: "Export ${_selectedService == ExportService.anilist ? 'AniList' : 'MAL'} XML",
                               variant: TextVariant.bold,
                               color: Colors.white,
                               size: 16,
                             ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(ExportService value, String label) {
    final isSelected = _selectedService == value;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedService = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? colorScheme.primary 
                  : colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Center(
            child: AnymexText(
              text: label,
              variant: TextVariant.semiBold,
              color: isSelected ? Colors.white : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}