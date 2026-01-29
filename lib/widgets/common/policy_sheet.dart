import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum PolicyType { tos, commentPolicy }

Future<void> showPolicySheet(BuildContext context, PolicyType type) async {
  final String title =
      type == PolicyType.tos ? "Terms of Service" : "Comment Policy";
  
  snackBar('Fetching $title...');

  try {
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/RyanYuuki/AnymeX/master/TOS.md'));

    if (response.statusCode == 200) {
      String content = response.body;

      // Logic to extract specific section for Comment Policy
      if (type == PolicyType.commentPolicy) {
        const startMarker = '## Comments System & Comment Policy';
        final startIndex = content.indexOf(startMarker);

        if (startIndex != -1) {
          // Find the next header (##) to end the selection
          final nextHeaderIndex =
              content.indexOf('## ', startIndex + startMarker.length);

          if (nextHeaderIndex != -1) {
            content = content.substring(startIndex, nextHeaderIndex).trim();
          } else {
            content = content.substring(startIndex).trim();
          }
        } else {
          snackBar("Could not find policy section.", duration: 2000);
          return;
        }
      }

      if (context.mounted) {
        _showBottomSheetUI(context, title, content);
      }
    } else {
      snackBar("Failed to fetch policy.", duration: 2000);
    }
  } catch (e) {
    snackBar("Error fetching policy: $e", duration: 2000);
  }
}

void _showBottomSheetUI(BuildContext context, String title, String content) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.15),
              blurRadius: 32,
              offset: const Offset(0, -8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      size: 20,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  radius: const Radius.circular(8),
                  thickness: 6,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Text(
                      content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            letterSpacing: 0.2,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.85),
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
