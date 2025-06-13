// ignore_for_file: deprecated_member_use

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/custom_list.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class CustomListDialog extends StatefulWidget {
  final Media original;
  final List<CustomList> customLists;
  final bool isManga;

  const CustomListDialog({
    super.key,
    required this.original,
    required this.customLists,
    required this.isManga,
  });

  @override
  State<CustomListDialog> createState() => _CustomListDialogState();
}

class _CustomListDialogState extends State<CustomListDialog>
    with SingleTickerProviderStateMixin {
  late List<CustomList> modifiedLists;
  late Map<String, bool> initialState;
  final storage = Get.find<OfflineStorageController>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Track check/uncheck animations
  final Map<String, bool> _recentlyChanged = {};

  @override
  void initState() {
    super.initState();
    modifiedLists = widget.customLists;

    initialState = {
      for (var list in widget.customLists)
        list.listName ?? '':
            list.mediaIds?.contains(widget.original.id) ?? false
    };

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleCheckboxChanged(bool? checked, CustomList list) {
    setState(() {
      final listName = list.listName ?? '';

      if (checked ?? false) {
        if (!list.mediaIds!.contains(widget.original.id)) {
          list.mediaIds!.add(widget.original.id);
          _recentlyChanged[listName] = true;
        }
      } else {
        list.mediaIds!.remove(widget.original.id);
        _recentlyChanged[listName] = false;
      }

      // Clear animation status after some time
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _recentlyChanged.remove(listName);
          });
        }
      });
    });
  }

  Future<void> _showCreateListDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final TextEditingController textController = TextEditingController();
    bool isButtonEnabled = false;

    String? newListName = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 8,
            shadowColor: colorScheme.shadow.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New List',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a name for your new collection',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        isButtonEnabled = value.trim().isNotEmpty;
                      });
                    },
                    style: textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'List Name',
                      hintText: 'My Favorites, Watch Later, etc.',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      prefixIcon: Icon(
                        widget.isManga ? Icons.menu_book : Icons.movie,
                        color: colorScheme.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: isButtonEnabled
                            ? () => Navigator.of(context)
                                .pop(textController.text.trim())
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Create',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    if (newListName != null && newListName.isNotEmpty) {
      setState(() {
        storage.addCustomList(newListName,
            mediaType: widget.isManga ? MediaType.manga : MediaType.anime);
        initialState[newListName] = false;
        modifiedLists = widget.customLists
            .map((list) => CustomList(
                  listName: list.listName,
                  mediaIds: List<String>.from(list.mediaIds ?? []),
                ))
            .toList();

        // Mark newly created list for animation
        _recentlyChanged[newListName] = false;

        // Clear animation status after some time
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _recentlyChanged.remove(newListName);
            });
          }
        });
      });
    }
  }

  void _handleOkPress() {
    // Add a small delay for the ripple effect to complete
    Future.delayed(const Duration(milliseconds: 200), () {
      for (var list in modifiedLists) {
        final listName = list.listName ?? '';
        final wasChecked = initialState[listName] ?? false;
        final isCheckedNow =
            list.mediaIds?.contains(widget.original.id) ?? false;

        if (wasChecked != isCheckedNow) {
          if (isCheckedNow) {
            storage.addMedia(listName, widget.original, widget.isManga);
          } else {
            storage.removeMedia(listName, widget.original.id, widget.isManga);
          }
        }
      }

      // Animate out before popping
      _animationController.reverse().then((_) {
        Navigator.of(context).pop();
      });
    });
  }

  List<CustomList> get filteredLists {
    if (_searchQuery.isEmpty) {
      return modifiedLists;
    }
    return modifiedLists
        .where((list) =>
            (list.listName?.toLowerCase() ?? '').contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mediaTitle = widget.original.title;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: colorScheme.surface,
        elevation: 8,
        shadowColor: colorScheme.shadow.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    if (widget.original.cover != null)
                      ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.3),
                            ],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.darken,
                        child: Image.network(
                          widget.original.cover!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 140,
                            color: widget.isManga
                                ? Colors.blue.withOpacity(0.8)
                                : Colors.purple.withOpacity(0.8),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 140,
                        color: widget.isManga
                            ? Colors.blue.withOpacity(0.8)
                            : Colors.purple.withOpacity(0.8),
                      ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    spreadRadius: 0,
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.original.poster,
                                  width: 70,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 70,
                                    height: 100,
                                    color: colorScheme.surfaceVariant,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Title info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      widget.isManga ? 'MANGA' : 'ANIME',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    mediaTitle,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add to your collections',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Content section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomSearchBar(
                        padding: const EdgeInsets.all(0),
                        disableIcons: true,
                        onSubmitted: (_) {},
                        controller: _searchController,
                        focusNode: _searchFocus,
                      ),

                      // Lists section header
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20.0, bottom: 12.0, left: 4.0),
                        child: Row(
                          children: [
                            Text(
                              'Your Collections',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (filteredLists.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${filteredLists.length}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Lists section
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.35,
                          minHeight: 100,
                        ),
                        child: filteredLists.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchQuery.isNotEmpty
                                          ? Icons.search_off
                                          : Icons.playlist_add,
                                      size: 48,
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.4),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'No lists match "$_searchQuery"'
                                          : 'No collections created yet',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant
                                            .withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : Material(
                                color: Colors.transparent,
                                child: SuperListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: filteredLists.length,
                                  itemBuilder: (context, index) {
                                    final list = filteredLists[index];
                                    final listName =
                                        list.listName ?? 'Unnamed List';
                                    final isChecked = list.mediaIds
                                            ?.contains(widget.original.id) ??
                                        false;
                                    final isRecentlyChanged =
                                        _recentlyChanged.containsKey(listName);

                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isChecked
                                            ? colorScheme.primaryContainer
                                                .withOpacity(0.4)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isChecked
                                              ? colorScheme.primary
                                                  .withOpacity(0.5)
                                              : Colors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _handleCheckboxChanged(
                                                !isChecked, list),
                                            splashColor: colorScheme.primary
                                                .withOpacity(0.1),
                                            highlightColor: Colors.transparent,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: Row(
                                                children: [
                                                  // Checkbox
                                                  Transform.scale(
                                                    scale: 0.9,
                                                    child: Checkbox(
                                                      value: isChecked,
                                                      onChanged: (checked) =>
                                                          _handleCheckboxChanged(
                                                              checked, list),
                                                      activeColor:
                                                          colorScheme.primary,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      side: BorderSide(
                                                        color:
                                                            colorScheme.outline,
                                                        width: 1.5,
                                                      ),
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                  ),

                                                  // List info
                                                  Expanded(
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                listName,
                                                                style: textTheme
                                                                    .bodyLarge
                                                                    ?.copyWith(
                                                                  fontWeight: isChecked
                                                                      ? FontWeight
                                                                          .w600
                                                                      : FontWeight
                                                                          .normal,
                                                                  color: isChecked
                                                                      ? colorScheme
                                                                          .primary
                                                                      : colorScheme
                                                                          .onSurface,
                                                                ),
                                                              ),
                                                              if (isRecentlyChanged)
                                                                AnimatedContainer(
                                                                  duration: const Duration(
                                                                      milliseconds:
                                                                          300),
                                                                  margin:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              8),
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          2),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: isChecked
                                                                        ? colorScheme
                                                                            .primary
                                                                        : colorScheme
                                                                            .surfaceVariant,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            12),
                                                                  ),
                                                                  child: Text(
                                                                    isChecked
                                                                        ? 'Added'
                                                                        : 'Removed',
                                                                    style: textTheme
                                                                        .labelSmall
                                                                        ?.copyWith(
                                                                      color: isChecked
                                                                          ? colorScheme
                                                                              .onPrimary
                                                                          : colorScheme
                                                                              .onSurfaceVariant,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                          if ((list.mediaIds
                                                                          ?.length ??
                                                                      0) >
                                                                  0 &&
                                                              list.mediaIds!
                                                                      .length >
                                                                  (isChecked
                                                                      ? 1
                                                                      : 0))
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 4.0),
                                                              child: Text(
                                                                '${list.mediaIds!.length - (isChecked ? 1 : 0)} ${widget.isManga ? 'manga' : 'anime'} in this collection',
                                                                style: textTheme
                                                                    .bodySmall
                                                                    ?.copyWith(
                                                                  color: colorScheme
                                                                      .onSurfaceVariant,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  // Status icon
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 300),
                                                    height: 34,
                                                    width: 34,
                                                    decoration: BoxDecoration(
                                                      color: isChecked
                                                          ? colorScheme
                                                              .primaryContainer
                                                          : colorScheme
                                                              .surfaceVariant
                                                              .withOpacity(0.4),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        isChecked
                                                            ? Icons
                                                                .check_rounded
                                                            : Icons.add_rounded,
                                                        size: 20,
                                                        color: isChecked
                                                            ? colorScheme
                                                                .primary
                                                            : colorScheme
                                                                .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),

                      // Create new list button
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
                        child: InkWell(
                          onTap: _showCreateListDialog,
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer
                                  .withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14.0, horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary
                                          .withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Create New Collection',
                                    style: textTheme.titleSmall?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom action buttons
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel button
                      TextButton(
                        onPressed: () {
                          _animationController.reverse().then((_) {
                            Navigator.of(context).pop();
                          });
                        },
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        child: Text(
                          'Cancel',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Save button
                      FilledButton.tonal(
                        onPressed: _handleOkPress,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.secondaryContainer,
                          foregroundColor: colorScheme.onSecondaryContainer,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Save',
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showCustomListDialog(
    BuildContext context, Media media, List<CustomList> lists, bool isManga) {
  showDialog(
    context: context,
    builder: (context) => CustomListDialog(
      original: media,
      customLists: lists,
      isManga: isManga,
    ),
  );
}
