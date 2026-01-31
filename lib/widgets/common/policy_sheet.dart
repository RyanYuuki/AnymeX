import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

enum PolicyType { tos, commentPolicy, commentRules }

Future<void> showPolicySheet(BuildContext context, PolicyType type) async {
  final String title = type == PolicyType.tos
      ? "Terms of Service"
      : type == PolicyType.commentPolicy
          ? "Comment Policy"
          : "Comment Rules";

  snackBar('Fetching $title...');

  try {
    const String url =
        'https://raw.githubusercontent.com/RyanYuuki/AnymeX/master/TOS.md';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      String content = response.body;

      if (type == PolicyType.commentPolicy) {
        const startMarker = '## Comments System & Comment Policy';
        const endMarker = 'All moderation decisions are final.';

        final startIndex = content.indexOf(startMarker);
        final endIndex = content.indexOf(endMarker);

        if (startIndex != -1 && endIndex != -1) {
          content = content.substring(startIndex, endIndex + endMarker.length);
        }
      } else if (type == PolicyType.commentRules) {
        const startMarker = '### Comment Rules';
        const endMarker =
            'Failure to follow these rules may result in comment deletion, temporary restrictions, or permanent bans from the commenting system.';

        final startIndex = content.indexOf(startMarker);
        final endIndex = content.indexOf(endMarker);

        if (startIndex != -1 && endIndex != -1) {
          final contentAfterHeading = content.indexOf('\n', startIndex);
          content = content.substring(
              contentAfterHeading != -1 ? contentAfterHeading + 1 : startIndex,
              endIndex + endMarker.length);
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
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: context.colors.outline.opaque(0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.colors.shadow.opaque(0.15),
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
                      context.colors.onSurface.opaque(0.2),
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
                        context.colors.outline.opaque(0.08),
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
                          color: context.colors.onSurface,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .opaque(0.7),
                      size: 20,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Markdown(
                controller: scrollController,
                data: content,
                selectable: true,
                shrinkWrap: false,
                styleSheet: MarkdownStyleSheet(
                  h1: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                  h2: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                  h3: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                  p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        letterSpacing: 0.2,
                        color: context.colors
                            .onSurface
                            .opaque(0.85),
                      ),
                  listBullet: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.colors.onSurface,
                      ),
                  code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        backgroundColor: context.colors
                            .surfaceContainerHighest,
                        color: context.colors.onSurface,
                      ),
                  blockquote: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: context.colors
                            .onSurface
                            .opaque(0.7),
                      ),
                ),
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchUrl(Uri.parse(href),
                        mode: LaunchMode.externalApplication);
                  }
                },
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
