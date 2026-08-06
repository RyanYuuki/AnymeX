import 'package:flutter/material.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/activity_composer_sheet.dart';
import 'package:get/get.dart';

String getFollowLabel({bool? isFollowing, bool? isFollower}) {
  if (isFollowing == true && isFollower == true) return 'Mutual';
  if (isFollowing == true) return 'Following';
  if (isFollower == true) return 'Follows you';
  return 'Follow';
}

Future<bool> confirmDiscardComposer(
  BuildContext context, {
  required GlobalKey<ActivityComposerSheetState> composerKey,
  required String discardTitle,
  required String discardMessage,
}) async {
  final hasUnsavedText =
      (composerKey.currentState?.text.trim().isNotEmpty ?? false);
  if (!hasUnsavedText) return true;

  final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(discardTitle),
          content: Text(discardMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      ) ??
      false;

  return discard;
}

Widget buildProfileSheetOption(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: context.theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}

class PlaceholderTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PlaceholderTab({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color:
                  context.theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    context.theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 7 : 8),
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(compact ? 7 : 8),
          ),
          child: Icon(
            icon,
            size: compact ? 15 : 16,
            color: context.theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(width: compact ? 12 : 15),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 12.5 : 14,
              color: context.theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.bold,
            color: context.theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

void showActivityFilterSheet(
  BuildContext context, {
  required List<String> activityFilters,
  required VoidCallback onApply,
}) {
  const availableFilters = {
    'ANIME_LIST': 'Anime progress',
    'MANGA_LIST': 'Manga progress',
    'TEXT': 'Status',
    'MESSAGE': 'Messages',
  };

  showModalBottomSheet(
    context: context,
    backgroundColor: context.theme.colorScheme.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Filter Activity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('All'),
                    value: activityFilters.length == 4,
                    activeColor: context.theme.colorScheme.primary,
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        if (val == true) {
                          activityFilters
                            ..clear()
                            ..addAll(availableFilters.keys);
                        } else {
                          activityFilters.clear();
                        }
                      });
                    },
                  ),
                  ...availableFilters.entries.map((entry) {
                    final isSelected = activityFilters.contains(entry.key);
                    return CheckboxListTile(
                      title: Text(entry.value),
                      value: isSelected,
                      activeColor: context.theme.colorScheme.primary,
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            activityFilters.add(entry.key);
                          } else {
                            activityFilters.remove(entry.key);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.theme.colorScheme.primary,
                        foregroundColor: context.theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onApply();
                      },
                      child: const Text(
                        "Apply Filters",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class ProfileDesktopTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const ProfileDesktopTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = getResponsiveValue(
      context,
      mobileValue: false,
      desktopValue: true,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40.0 : 20.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: context.theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: labels.asMap().entries.map((entry) {
              final isSelected = selectedIndex == entry.key;
              return InkWell(
                onTap: () => onTabSelected(entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? context.theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? context.theme.colorScheme.primary
                          : context.theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
