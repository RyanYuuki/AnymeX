import 'dart:developer';

import 'package:anymex/widgets/custom_widgets/custom_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class UpdateChecker {
  static const String _repoUrl =
      'https://api.github.com/repos/RyanYuuki/AnymeX/releases/latest';

  Future<void> checkForUpdates(
      BuildContext context, RxBool canShowUpdate) async {
    if (canShowUpdate.value) {
      canShowUpdate.value = false;
      try {
        final currentVersion = await _getCurrentVersion();
        final latestRelease = await _fetchLatestRelease();

        if (latestRelease != null &&
            _shouldUpdate(currentVersion, latestRelease['tag_name'])) {
          _showUpdateBottomSheet(
            context,
            currentVersion,
            latestRelease['tag_name'],
            latestRelease['body'],
            latestRelease['html_url'],
          );
        }
      } catch (e) {
        debugPrint('Error checking for updates: $e');
      }
    } else {
      snackBar("Skipping Update Popup");
    }
  }

  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(_repoUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching latest release: $e');
    }
    return null;
  }

  bool _shouldUpdate(String currentVersion, String latestVersion) {
  latestVersion = latestVersion.replaceAll(RegExp(r'v|-.*$'), '');
  log("Current Ver: $currentVersion, Latest Ver: $latestVersion");
  return currentVersion != latestVersion;
}

  void _showUpdateBottomSheet(
    BuildContext context,
    String currentVersion,
    String newVersion,
    String changelog,
    String downloadUrl,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => UpdateBottomSheet(
          currentVersion: currentVersion,
          newVersion: newVersion,
          changelog: changelog,
          downloadUrl: downloadUrl,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class UpdateBottomSheet extends StatelessWidget {
  final String currentVersion;
  final String newVersion;
  final String changelog;
  final String downloadUrl;
  final ScrollController scrollController;

  const UpdateBottomSheet({
    super.key,
    required this.currentVersion,
    required this.newVersion,
    required this.changelog,
    required this.downloadUrl,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Update Available! ($newVersion)',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Text(
                    'What\'s New:',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: Markdown(
                        controller: scrollController,
                        data: changelog,
                        selectable: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: AnymeXButton(
                            borderRadius: BorderRadius.circular(30),
                            variant: ButtonVariant.outline,
                            height: 50,
                            width: double.infinity,
                            onTap: () => Navigator.pop(context),
                            child: const AnymexText(
                              text: 'Later',
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnymeXButton(
                            borderRadius: BorderRadius.circular(30),
                            height: 50,
                            width: double.infinity,
                            variant: ButtonVariant.outline,
                            backgroundColor: Colors.transparent,
                            onTap: () async {
                              final Uri url = Uri.parse(downloadUrl);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            child: const AnymexText(
                              text: 'Update Now',
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
