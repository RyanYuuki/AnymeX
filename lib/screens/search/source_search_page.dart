import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';

class SourceSearchPage extends StatelessWidget {
  final String? initialTerm;
  final ItemType type;
  final Source? source;

  const SourceSearchPage({
    super.key,
    this.initialTerm = "",
    this.type = ItemType.anime,
    this.source,
  });

  @override
  Widget build(BuildContext context) {
    return SearchPage(
      searchTerm: initialTerm ?? '',
      isManga: type == ItemType.manga,
      type: type,
      source: source,
    );
  }
}
