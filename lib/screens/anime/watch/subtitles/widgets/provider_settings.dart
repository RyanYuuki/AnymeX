import 'package:anymex/screens/anime/watch/subtitles/repository/subtitle_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubtitleProviderSettings extends StatefulWidget {
  const SubtitleProviderSettings({super.key});

  @override
  State<SubtitleProviderSettings> createState() => _SubtitleProviderSettingsState();
}

class _SubtitleProviderSettingsState extends State<SubtitleProviderSettings> {
  final SubtitleRepository _repo = SubtitleRepository();
  final Map<SubtitleProvider, TextEditingController> _apiControllers = {};

  @override
  void initState() {
    super.initState();
    for (final provider in SubtitleProvider.values) {
      if (provider.requiresApiKey) {
        _apiControllers[provider] = TextEditingController();
      }
    }
  }

  Future<void> _showApiKeyDialog(SubtitleProvider provider) async {
    final controller = _apiControllers[provider]!;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${provider.displayName} API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your API key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _repo.setProviderEnabled(provider, true, apiKey: controller.text);
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Subtitle Providers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...SubtitleProvider.values.map((provider) {
          final isEnabled = _repo.enabledProviders.contains(provider);
          
          return ListTile(
            leading: Icon(
              isEnabled ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isEnabled ? Colors.green : null,
            ),
            title: Text(provider.displayName),
            subtitle: provider.requiresApiKey 
                ? const Text('Requires API key') 
                : const Text('Free to use'),
            trailing: provider == SubtitleProvider.wyzie
                ? null
                : Switch(
                    value: isEnabled,
                    onChanged: (enabled) async {
                      if (enabled && provider.requiresApiKey) {
                        await _showApiKeyDialog(provider);
                      } else if (!enabled) {
                        await _repo.setProviderEnabled(provider, false);
                        setState(() {});
                      } else {
                        await _repo.setProviderEnabled(provider, true);
                        setState(() {});
                      }
                    },
                  ),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    for (final controller in _apiControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
