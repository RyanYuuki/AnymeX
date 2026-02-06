import 'package:anymex/models/reader/tap_zones.dart';
import 'package:anymex/repositories/tap_zone_repository.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';

import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TapZoneSettingsScreen extends StatefulWidget {
  const TapZoneSettingsScreen({super.key});

  @override
  State<TapZoneSettingsScreen> createState() => _TapZoneSettingsScreenState();
}

class _TapZoneSettingsScreenState extends State<TapZoneSettingsScreen> {
  final TapZoneRepository _repo = TapZoneRepository();
  late TapZoneLayout _pagedLayout;
  late TapZoneLayout _pagedVerticalLayout;
  late TapZoneLayout _webtoonLayout;
  late TapZoneLayout _webtoonHorizontalLayout;
  final ReaderController _readerController = Get.find<ReaderController>();

  bool _isWebtoon = false;
  bool _isVertical = false;
  
  @override
  void initState() {
    super.initState();
    _pagedLayout = _repo.getPagedLayout();
    _pagedVerticalLayout = _repo.getPagedVerticalLayout();
    _webtoonLayout = _repo.getWebtoonLayout();
    _webtoonHorizontalLayout = _repo.getWebtoonHorizontalLayout();
    
    
  }

  void _savePaged(TapZoneLayout layout) {
    setState(() => _pagedLayout = layout);
    _repo.savePagedLayout(layout);
    _readerController.pagedProfile.value = layout;
  }

  void _savePagedVertical(TapZoneLayout layout) {
    setState(() => _pagedVerticalLayout = layout);
    _repo.savePagedVerticalLayout(layout);
    _readerController.pagedVerticalProfile.value = layout;
  }

  void _saveWebtoon(TapZoneLayout layout) {
    setState(() => _webtoonLayout = layout);
    _repo.saveWebtoonLayout(layout);
    _readerController.webtoonProfile.value = layout;
  }

  void _saveWebtoonHorizontal(TapZoneLayout layout) {
    setState(() => _webtoonHorizontalLayout = layout);
    _repo.saveWebtoonHorizontalLayout(layout);
    _readerController.webtoonHorizontalProfile.value = layout;
  }

  void _resetDefaults() {

    if (!_isWebtoon && !_isVertical) {
       _savePaged(TapZoneLayout.defaultPaged);
    } else if (!_isWebtoon && _isVertical) {
       _savePagedVertical(TapZoneLayout.defaultPagedVertical);
    } else if (_isWebtoon && _isVertical) {
       _saveWebtoon(TapZoneLayout.defaultWebtoon);
    } else {
       _saveWebtoonHorizontal(TapZoneLayout.defaultWebtoonHorizontal);
    }
  }

  TapZoneLayout _getCurrentLayout() {
    if (!_isWebtoon) {
      return _isVertical ? _pagedVerticalLayout : _pagedLayout;
    } else {
      return _isVertical ? _webtoonLayout : _webtoonHorizontalLayout;
    }
  }

  Function(TapZoneLayout) _getCurrentSaveCallback() {
    if (!_isWebtoon) {
      return _isVertical ? _savePagedVertical : _savePaged;
    } else {
      return _isVertical ? _saveWebtoon : _saveWebtoonHorizontal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLayout = _getCurrentLayout();
    final onSave = _getCurrentSaveCallback();

    return Glow(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tap Zones"),
          actions: [
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: 'Reset to Default',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                    title: const Text('Reset Layout?', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('This will revert the current layout to its original settings.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                      ),
                      TextButton(
                        onPressed: () {
                          _resetDefaults();
                          Navigator.pop(context);
                        },
                        child: Text('Reset', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Modes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _ElegantSegmentedControl(
                options: [
                  (title: "Paged", icon: Transform.rotate(angle: 1.5708, child: const Icon(Icons.view_day_rounded, size: 18))),
                  (title: "Webtoon", icon: const Icon(Icons.view_day_rounded, size: 18)),
                ],
                selectedIndex: _isWebtoon ? 1 : 0,
                onChanged: (index) => setState(() => _isWebtoon = index == 1),
              ),
            ),
             
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: _ElegantSegmentedControl(
                options: const [
                  (title: "Horizontal", icon: Icon(Icons.swap_horiz_rounded, size: 18)),
                  (title: "Vertical", icon: Icon(Icons.swap_vert_rounded, size: 18)),
                ],
                selectedIndex: _isVertical ? 1 : 0,
                onChanged: (index) => setState(() => _isVertical = index == 1),
              ),
            ),
            
            const Divider(),

            Obx(() => SwitchListTile(
              title: const Text("Enable Tap Zones"),
              subtitle: const Text("Use custom gestures"),
              value: _readerController.tapZonesEnabled.value,
              onChanged: (val) => _readerController.toggleTapZones(val),
              activeColor: Theme.of(context).colorScheme.primary,
            )),
            
            Expanded(
              child: Obx(() => IgnorePointer(
                ignoring: !_readerController.tapZonesEnabled.value,
                child: AnimatedOpacity(
                  opacity: _readerController.tapZonesEnabled.value ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: _buildEditor(currentLayout, onSave),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(
      TapZoneLayout layout, Function(TapZoneLayout) onSave) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Tap a zone to change its action",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: VisualZoneEditor(
                    layout: layout,
                    onUpdate: onSave,
                    isWebtoon: _isWebtoon,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class VisualZoneEditor extends StatelessWidget {
  final TapZoneLayout layout;
  final Function(TapZoneLayout) onUpdate;
  final bool isWebtoon;

  const VisualZoneEditor({
    super.key,
    required this.layout,
    required this.onUpdate,
    required this.isWebtoon,
  });

  void _editZone(BuildContext context, int index) async {
    final zone = layout.zones[index];
    final selectedAction = await showModalBottomSheet<ReaderAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
             
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.touch_app_rounded, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      "Tap Action",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // tap actions
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: ReaderAction.values.where((action) {
                    if (isWebtoon) {
                      return action != ReaderAction.nextPage && action != ReaderAction.prevPage;
                    } else {
                      return action != ReaderAction.scrollUp && action != ReaderAction.scrollDown;
                    }
                  }).map((action) {
                    final isSelected = action == zone.action;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: Icon(
                        _getActionIcon(action),
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        action.displayName,
                        style: TextStyle(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => Navigator.pop(context, action),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selectedAction != null && selectedAction != zone.action) {
      final newZones = List<TapZone>.from(layout.zones);
      newZones[index] = TapZone(bounds: zone.bounds, action: selectedAction);
      
      final newLayout = TapZoneLayout(
        id: layout.id, 
        name: layout.name, 
        zones: newZones
      );
      onUpdate(newLayout);
    }
  }

  IconData _getActionIcon(ReaderAction action) {
    switch (action) {
      case ReaderAction.nextPage:
        return Icons.arrow_forward_rounded;
      case ReaderAction.prevPage:
        return Icons.arrow_back_rounded;
      case ReaderAction.toggleMenu:
        return Icons.visibility_rounded;
      case ReaderAction.scrollUp:
        return Icons.keyboard_arrow_up_rounded;
      case ReaderAction.scrollDown:
        return Icons.keyboard_arrow_down_rounded;
      case ReaderAction.nextChapter:
        return Icons.skip_next_rounded;
      case ReaderAction.prevChapter:
        return Icons.skip_previous_rounded;
      case ReaderAction.none:
        return Icons.block_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
    
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            
            Container(color: Colors.black.withOpacity(0.05)),
            
            // elegant feel ahhh
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(
                   color: Theme.of(context).dividerColor.withOpacity(0.05),
                ),
              ),
            ),

           
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(
                   color: Theme.of(context).dividerColor.withOpacity(0.05),
                ),
              ),
            ),

            // Zones 
            ...layout.zones.asMap().entries.map((entry) {
               
               final index = entry.key;
              final zone = entry.value;
              final rect = zone.bounds;

              return Positioned(
                left: rect.left * w,
                top: rect.top * h,
                width: rect.width * w,
                height: rect.height * h,
                child: GestureDetector(
                  onTap: () => _editZone(context, index),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_rounded, 
                               size: 28, 
                               color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              zone.action.displayName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
     final paint = Paint()..color = color..strokeWidth = 1;
     const spacing = 40.0;
     for (var x = 0.0; x <= size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
     }
     for (var y = 0.0; y <= size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
     }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ElegantSegmentedControl extends StatelessWidget {
  final List<({String title, Widget icon})> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ElegantSegmentedControl({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / options.length;
          
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutExpo,
                left: width * selectedIndex,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                children: options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconTheme(
                              data: IconThemeData(
                                size: 18,
                                color: isSelected 
                                  ? Theme.of(context).colorScheme.onPrimary 
                                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                              child: item.icon,
                            ),
                            const SizedBox(width: 8),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.onPrimary 
                                    : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                              child: Text(item.title),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}


