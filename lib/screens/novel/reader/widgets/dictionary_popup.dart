import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DictionaryPopup extends StatefulWidget {
  final String selectedText;
  final Offset tapPosition;

  const DictionaryPopup({
    super.key,
    required this.selectedText,
    required this.tapPosition,
  });

  @override
  State<DictionaryPopup> createState() => _DictionaryPopupState();
}

class _DictionaryPopupState extends State<DictionaryPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Map<String, dynamic>? _definitionData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
    _fetchDefinition();
  }

  Future<void> _fetchDefinition() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final word = widget.selectedText.trim().toLowerCase();
      final response = await http.get(
        Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _definitionData = data[0];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No definition found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch definition';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.tapPosition.dx - 100,
      top: widget.tapPosition.dy - 200,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 250,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.colors.outline.opaque(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.opaque(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colors.outline.opaque(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.selectedText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.close,
              size: 20,
              color: context.colors.onSurface.opaque(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: context.colors.error,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: context.colors.error,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Flexible(
      child: ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        children: [
          if (_definitionData?['phonetic'] != null)
            _buildPhonetic(context, _definitionData!['phonetic']),
          if (_definitionData?['meanings'] != null)
            ..._buildMeanings(context, _definitionData!['meanings']),
        ],
      ),
    );
  }

  Widget _buildPhonetic(BuildContext context, String phonetic) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.volume_up,
            size: 16,
            color: context.colors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            phonetic,
            style: TextStyle(
              fontSize: 14,
              color: context.colors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMeanings(BuildContext context, List meanings) {
    final widgets = <Widget>[];

    for (final meaning in meanings) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primary.opaque(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  meaning['partOfSpeech'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ..._buildDefinitions(context, meaning['definitions']),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildDefinitions(BuildContext context, List? definitions) {
    if (definitions == null || definitions.isEmpty) {
      return [];
    }

    return definitions.take(2).map<Widget>((def) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ${def['definition'] ?? ''}',
              style: TextStyle(
                fontSize: 13,
                color: context.colors.onSurface,
              ),
            ),
            if (def['example'] != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '"${def['example']}"',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurface.opaque(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }
}
