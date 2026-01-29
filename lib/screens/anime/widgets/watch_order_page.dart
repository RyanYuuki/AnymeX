import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/watch_order_util.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class WatchOrderPage extends StatefulWidget {
  final String title;
  const WatchOrderPage({super.key, required this.title});

  @override
  State<WatchOrderPage> createState() => _WatchOrderPageState();
}

class _WatchOrderPageState extends State<WatchOrderPage> {
  bool isLoading = true;
  String? error;
  List<WatchOrderItem> watchOrder = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. Search for the series ID
      final searchResults = await WatchOrderUtil.searchWatchOrder(widget.title);
      
      if (searchResults.isEmpty) {
        setState(() {
          isLoading = false;
          error = "Could not find watch order for '${widget.title}'";
        });
        return;
      }

      // 2. Fetch the watch order using the best match (first result)
      final id = searchResults.first.id;
      final order = await WatchOrderUtil.fetchWatchOrder(id);

      setState(() {
        watchOrder = order;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          title: const Text("Watch Order", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(child: AnymexProgressIndicator());
            }
            if (error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(error!, textAlign: TextAlign.center),
                ),
              );
            }
            if (watchOrder.isEmpty) {
              return const Center(child: Text("No watch order found."));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: watchOrder.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = watchOrder[index];
                return _buildWatchOrderItem(context, item, index + 1);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWatchOrderItem(BuildContext context, WatchOrderItem item, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            "$index",
            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.nameEnglish != null && item.nameEnglish != item.name)
              Text(
                item.nameEnglish!,
                style: TextStyle(
                  fontSize: 12, 
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8)
                ),
              ),
            if (item.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 11, 
                    color: colorScheme.primary,
                    fontStyle: FontStyle.italic
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // Navigate to details if Anilist ID exists
          if (item.anilistId.isNotEmpty) {
             // Create a minimal Media object to navigate
             final media = Media(
               id: int.tryParse(item.anilistId) ?? 0,
               title: item.nameEnglish ?? item.name,
               poster: item.image,
             );
             // You might need to fetch full details inside AnimeDetailsPage or 
             // ensure your navigation handles partial media objects
             navigate(() => AnimeDetailsPage(media: media, tag: "wo-${item.id}"));
          }
        },
      ),
    );
  }
}
