import 'package:anymex/screens/extensions/extension_webview.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class SourcePreferenceScreen extends StatefulWidget {
  final Source source;
  const SourcePreferenceScreen({super.key, required this.source});

  @override
  State<SourcePreferenceScreen> createState() => _SourcePreferenceScreenState();
}

class _SourcePreferenceScreenState extends State<SourcePreferenceScreen> {
  Rx<List<SourcePreference>?> preference = Rx(null);
  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    preference.value = await widget.source.methods.getPreference();
  }

  Widget _buildWebViewSection(ColorScheme theme) {
    final baseUrl = widget.source.baseUrl ?? '';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryContainer.opaque(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primary.opaque(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cookie_outlined,
                color: theme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexText(
                      text: 'WebView & Cookies',
                      variant: TextVariant.semiBold,
                      size: 15,
                      color: theme.primary,
                    ),
                    const SizedBox(height: 2),
                    AnymexText(
                      text: 'Login to the source website or pass Cloudflare challenges',
                      size: 11,
                      color: theme.onSurface.opaque(0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionChip(
                  icon: Icons.language_rounded,
                  label: 'Open WebView',
                  color: theme.primary,
                  onColor: theme.onPrimary,
                  containerColor: theme.primary.opaque(0.15),
                  onTap: () {
                    if (baseUrl.isNotEmpty) {
                      context.openExtensionWebView(
                        url: baseUrl,
                        sourceName: widget.source.name ?? 'Extension',
                      );
                    } else {
                      _showManualUrlDialog(theme);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChip(
                  icon: Icons.info_outline_rounded,
                  label: 'View Cookies',
                  color: theme.tertiary,
                  onColor: theme.onTertiary,
                  containerColor: theme.tertiary.opaque(0.15),
                  onTap: () => _showCookieInfo(theme),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChip(
                  icon: Icons.delete_sweep_outlined,
                  label: 'Clear Data',
                  color: theme.error,
                  onColor: theme.onError,
                  containerColor: theme.error.opaque(0.15),
                  onTap: () => _clearCookiesForSource(theme),
                ),
              ),
            ],
          ),
          if (baseUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.surfaceContainerHighest.opaque(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: 14,
                    color: theme.onSurface.opaque(0.5),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      baseUrl,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: theme.onSurface.opaque(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showManualUrlDialog(ColorScheme theme) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.surfaceContainerHigh,
        title: const Text(
          'Open WebView',
          style: TextStyle(fontFamily: 'Poppins-SemiBold'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This extension doesn\'t have a base URL. Enter the website URL:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: theme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'https://example.com',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: theme.onSurface.withOpacity(0.4),
                ),
                filled: true,
                fillColor: theme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.outline),
                ),
                prefixIcon: const Icon(Icons.language_rounded, size: 20),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                String finalUrl = url;
                if (!finalUrl.startsWith('http')) {
                  finalUrl = 'https://$finalUrl';
                }
                context.openExtensionWebView(
                  url: finalUrl,
                  sourceName: widget.source.name ?? 'Extension',
                );
              }
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCookieInfo(ColorScheme theme) async {
    final baseUrl = widget.source.baseUrl ?? '';
    if (baseUrl.isEmpty) {
      return;
    }

    final cookieManager = CookieManager.instance();
    try {
      final cookies = await cookieManager.getCookies(url: WebUri(baseUrl));
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.surfaceContainerHigh,
          title: Text(
            'Cookies (${cookies.length})',
            style: const TextStyle(fontFamily: 'Poppins-SemiBold'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: cookies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cookie_outlined,
                            size: 48, color: theme.onSurface.opaque(0.3)),
                        const SizedBox(height: 12),
                        const Text('No cookies found',
                            style: TextStyle(fontFamily: 'Poppins')),
                        const SizedBox(height: 6),
                        Text(
                          'Open the WebView and login first',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: theme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: cookies.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cookie = cookies[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.cookie_outlined,
                          size: 18,
                          color: theme.primary,
                        ),
                        title: Text(
                          cookie.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(
                          '${cookie.value.substring(0, cookie.value.length > 40 ? 40 : cookie.value.length)}${cookie.value.length > 40 ? '...' : ''}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: theme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
    }
  }

  Future<void> _clearCookiesForSource(ColorScheme theme) async {
    final baseUrl = widget.source.baseUrl ?? '';
    if (baseUrl.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceContainerHigh,
        title: const Text(
          'Clear Cookies',
          style: TextStyle(fontFamily: 'Poppins-SemiBold'),
        ),
        content: Text(
          'Clear all cookies for ${widget.source.name}? You may need to login again.',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final cookieManager = CookieManager.instance();
    final uri = Uri.parse(baseUrl);
    try {
      final cookies = await cookieManager.getCookies(url: WebUri(baseUrl));
      for (final cookie in cookies) {
        await cookieManager.deleteCookie(
          url: WebUri('https://${cookie.domain ?? uri.host}'),
          name: cookie.name,
          domain: cookie.domain,
        );
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = context.colors;
    return Glow(
      child: Scaffold(
        
        body: Column(
          children: [
            NestedHeader(
              title: "${widget.source.name} Settings",
            ),
            _buildWebViewSection(theme),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(
                () {
                  if (preference.value == null) {
                    return const Center(
                      child: ExpressiveLoadingIndicator(),
                    );
                  }
                  if (preference.value!.isEmpty) {
                    return const Center(
                      child: Text("Source doesn't have any settings"),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: preference.value!.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pref = preference.value![index];
                      switch (pref.type) {
                        case 'checkBox':
                          final p = pref.checkBoxPreference!;
                          return _PreferenceTile(
                            title: p.title ?? '',
                            subtitle: p.summary ?? 'Toggle setting',
                            isSelected: p.value ?? false,
                            onTap: () {
                              final newVal = !(p.value ?? false);
                              p.value = newVal;
                              widget.source.methods.setPreference(pref, newVal);
                              setState(() {});
                            },
                            type: _PreferenceType.toggle,
                          );
                        case 'switch':
                          final p = pref.switchPreferenceCompat!;
                          return _PreferenceTile(
                            title: p.title ?? '',
                            subtitle: p.summary ?? 'Toggle setting',
                            isSelected: p.value ?? false,
                            onTap: () {
                              final newVal = !(p.value ?? false);
                              p.value = newVal;
                              widget.source.methods.setPreference(pref, newVal);
                              setState(() {});
                            },
                            type: _PreferenceType.toggle,
                          );
                        case 'list':
                          final p = pref.listPreference!;
                          return _PreferenceTile(
                            title: p.title ?? '',
                            subtitle: p.summary != null && p.summary!.isNotEmpty
                                ? p.summary!
                                : p.entries?[p.valueIndex ?? 0] ?? 'Select option',
                            isSelected: false,
                            onTap: () {
                              int tempIndex = p.valueIndex ?? 0;
                              showDialog(
                                context: context,
                                builder: (context) => StatefulBuilder(
                                  builder: (context, setDialogState) => AnymexDialog(
                                    title: p.title ?? 'Select Option',
                                    onConfirm: () {
                                      p.valueIndex = tempIndex;
                                      final newValue = p.entryValues?[tempIndex];
                                      p.value = newValue;
                                      widget.source.methods.setPreference(pref, newValue);
                                      setState(() {});
                                    },
                                    contentWidget: SizedBox(
                                      height: 300,
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: p.entries?.length ?? 0,
                                        itemBuilder: (context, i) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: _PreferenceTile(
                                            title: p.entries![i],
                                            subtitle: 'Option ${i + 1}',
                                            isSelected: tempIndex == i,
                                            onTap: () {
                                              setDialogState(() {
                                                tempIndex = i;
                                              });
                                            },
                                            type: _PreferenceType.toggle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            type: _PreferenceType.list,
                          );
                        case 'multi_select':
                          final p = pref.multiSelectListPreference!;
                          final selectedOptions = (p.values ?? []);
                          final subtitle = (p.entries ?? [])
                              .asMap()
                              .entries
                              .where((e) => selectedOptions.contains(p.entryValues?[e.key]))
                              .map((e) => e.value)
                              .join(", ");
                          return _PreferenceTile(
                            title: p.title ?? '',
                            subtitle: p.summary != null && p.summary!.isNotEmpty
                                ? p.summary!
                                : subtitle.isEmpty
                                    ? 'Select multiple'
                                    : subtitle,
                            isSelected: false,
                            onTap: () {
                              final tempSelectedValues = (p.values ?? []).toSet();
                              showDialog(
                                context: context,
                                builder: (context) => StatefulBuilder(
                                  builder: (context, setDialogState) => AnymexDialog(
                                    title: p.title ?? 'Select Options',
                                    onConfirm: () {
                                      p.values = tempSelectedValues.toList();
                                      widget.source.methods.setPreference(pref, p.values);
                                      setState(() {});
                                    },
                                    contentWidget: SizedBox(
                                      height: 300,
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: p.entries?.length ?? 0,
                                        itemBuilder: (context, i) {
                                          final val = p.entryValues![i];
                                          final isCurrentlySelected = tempSelectedValues.contains(val);
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: _PreferenceTile(
                                              title: p.entries![i],
                                              subtitle: 'Option ${i + 1}',
                                              isSelected: isCurrentlySelected,
                                              onTap: () {
                                                setDialogState(() {
                                                  if (isCurrentlySelected) {
                                                    tempSelectedValues.remove(val);
                                                  } else {
                                                    tempSelectedValues.add(val);
                                                  }
                                                });
                                              },
                                              type: _PreferenceType.toggle,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            type: _PreferenceType.list,
                          );
                        case 'text':
                          final p = pref.editTextPreference!;
                          return _PreferenceTile(
                            title: p.title ?? '',
                            subtitle: p.value ?? p.text ?? 'Edit text',
                            isSelected: false,
                            onTap: () {
                              String tempValue = p.value ?? p.text ?? '';
                              showDialog(
                                context: context,
                                builder: (context) => AnymexDialog(
                                  title: p.dialogTitle ?? p.title ?? 'Edit Text',
                                  onConfirm: () {
                                    p.value = tempValue;
                                    widget.source.methods.setPreference(pref, tempValue);
                                    setState(() {});
                                  },
                                  contentWidget: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (p.dialogMessage != null) ...[
                                        AnymexText(
                                          text: p.dialogMessage!,
                                          size: 14,
                                          color: theme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      TextField(
                                        controller: TextEditingController(text: tempValue),
                                        onChanged: (val) => tempValue = val,
                                        style: TextStyle(color: theme.onSurface),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: theme.surfaceContainerHighest.opaque(0.3),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: theme.outline),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            type: _PreferenceType.text,
                          );
              
                        default:
                          return _PreferenceTile(
                            title: pref.key ?? 'Unknown Preference',
                            subtitle: 'Unsupported type ${pref.type}',
                            isSelected: false,
                            onTap: () {},
                            type: _PreferenceType.text,
                          );
                      }
                    },
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

enum _PreferenceType { toggle, list, text }

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color onColor;
  final Color containerColor;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onColor,
    required this.containerColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: containerColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.type,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final _PreferenceType type;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.primaryContainer.opaque(0.35)
                : context.colors.surfaceContainerHighest.opaque(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? context.colors.primary.opaque(0.4)
                  : context.colors.outline.opaque(0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexText(
                      text: title,
                      variant: TextVariant.semiBold,
                      color: isSelected ? context.colors.primary : null,
                    ),
                    const SizedBox(height: 4),
                    AnymexText(
                      text: subtitle,
                      size: 11,
                      color: context.colors.onSurface.opaque(0.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (type == _PreferenceType.toggle)
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.onSurface.opaque(0.5),
                )
              else if (type == _PreferenceType.list)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: context.colors.onSurface.opaque(0.5),
                )
              else
                Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: context.colors.onSurface.opaque(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
