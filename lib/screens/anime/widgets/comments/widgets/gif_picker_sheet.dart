import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GifPickerSheet extends StatefulWidget {
  final Function(String gifUrl) onGifSelected;

  const GifPickerSheet({
    super.key,
    required this.onGifSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(String gifUrl) onGifSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GifPickerSheet(onGifSelected: onGifSelected),
    );
  }

  @override
  State<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<GifPickerSheet> {
  static const String _defaultKlipyApiKey =
      'S3eJXjTQNah5hZ1lltk12pgldrbUHY7vGW7mSyAuRnXHjcGGHMrTyW55BmYYB4KX';

  static String get _klipyApiKey =>
      dotenv.env['KLIPY_API_KEY']?.isNotEmpty == true
          ? dotenv.env['KLIPY_API_KEY']!
          : _defaultKlipyApiKey;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = false;
  String? _error;
  List<Map<String, String>> _gifs = [];
  bool _showUrlTab = false;

  @override
  void initState() {
    super.initState();
    _fetchTrending();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        _fetchTrending();
      } else {
        _searchGifs(trimmed);
      }
    });
  }

  Future<void> _fetchTrending() async {
    if (_klipyApiKey.isEmpty) {
      setState(() {
        _gifs = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
        'https://api.klipy.com/api/v1/$_klipyApiKey/gifs/trending?limit=30',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];
        final parsed = <Map<String, String>>[];

        for (final item in data) {
          final file = item['file'];
          final images = item['images'] ?? item['media'];
          String gifUrl = '';
          String previewUrl = '';

          if (file != null && file is Map) {
            gifUrl = file['hd']?['gif']?['url'] ??
                file['md']?['gif']?['url'] ??
                file['sm']?['gif']?['url'] ??
                '';
            previewUrl = file['sm']?['gif']?['url'] ??
                file['sm']?['webp']?['url'] ??
                file['xs']?['gif']?['url'] ??
                gifUrl;
          } else if (images != null && images is Map) {
            gifUrl = images['original']?['url'] ??
                images['fixed_height']?['url'] ??
                images['url'] ??
                '';
            previewUrl = images['preview']?['url'] ??
                images['fixed_height_small']?['url'] ??
                gifUrl;
          }

          if (gifUrl.isNotEmpty) {
            parsed.add({
              'url': gifUrl,
              'preview': previewUrl,
            });
          }
        }

        if (mounted) {
          setState(() {
            _gifs = parsed;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load GIFs (${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error connecting to GIF service';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchGifs(String query) async {
    if (_klipyApiKey.isEmpty) {
      setState(() {
        _gifs = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final encoded = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://api.klipy.com/api/v1/$_klipyApiKey/gifs/search?q=$encoded&limit=30',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];
        final parsed = <Map<String, String>>[];

        for (final item in data) {
          final file = item['file'];
          final images = item['images'] ?? item['media'];
          String gifUrl = '';
          String previewUrl = '';

          if (file != null && file is Map) {
            gifUrl = file['hd']?['gif']?['url'] ??
                file['md']?['gif']?['url'] ??
                file['sm']?['gif']?['url'] ??
                '';
            previewUrl = file['sm']?['gif']?['url'] ??
                file['sm']?['webp']?['url'] ??
                file['xs']?['gif']?['url'] ??
                gifUrl;
          } else if (images != null && images is Map) {
            gifUrl = images['original']?['url'] ??
                images['fixed_height']?['url'] ??
                images['url'] ??
                '';
            previewUrl = images['preview']?['url'] ??
                images['fixed_height_small']?['url'] ??
                gifUrl;
          }

          if (gifUrl.isNotEmpty) {
            parsed.add({
              'url': gifUrl,
              'preview': previewUrl,
            });
          }
        }

        if (mounted) {
          setState(() {
            _gifs = parsed;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Search failed (${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error connecting to GIF service';
          _isLoading = false;
        });
      }
    }
  }

  void _selectGif(String url) {
    HapticFeedback.lightImpact();
    widget.onGifSelected(url);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72 + keyboardHeight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header: Title & Direct URL Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'GIF Search',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showUrlTab = !_showUrlTab;
                      });
                    },
                    icon: Icon(
                      _showUrlTab ? Icons.grid_view_rounded : Icons.link_rounded,
                      size: 16,
                    ),
                    label: Text(_showUrlTab ? 'Browse GIFs' : 'Paste Link'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar or Direct Link View
            if (!_showUrlTab)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search anime GIFs, reactions...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _fetchTrending();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _urlController,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Paste direct GIF or image URL...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final val = _urlController.text.trim();
                        if (val.isNotEmpty) {
                          _selectGif(val);
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Insert'),
                    ),
                  ],
                ),
              ),

            // Grid of GIFs
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sentiment_dissatisfied_rounded,
                                size: 40,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _fetchTrending,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _gifs.isEmpty
                          ? Center(
                              child: Text(
                                'No GIFs found',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.35,
                              ),
                              itemCount: _gifs.length,
                              itemBuilder: (context, index) {
                                final gif = _gifs[index];
                                final url = gif['url'] ?? '';
                                final preview = gif['preview'] ?? url;

                                return GestureDetector(
                                  onTap: () => _selectGif(url),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      color: colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                      child: CachedNetworkImage(
                                        imageUrl: preview,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.2),
                                        ),
                                        errorWidget: (context, url, err) =>
                                            const Center(
                                          child: Icon(Icons.broken_image_rounded,
                                              size: 24),
                                        ),
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
  }
}
