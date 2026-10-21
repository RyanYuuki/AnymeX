
import 'package:anymex/controllers/network/dns_manager.dart';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:rhttp/rhttp.dart';

class SettingsNetwork extends StatefulWidget {
  const SettingsNetwork({super.key});

  @override
  State<SettingsNetwork> createState() => _SettingsNetworkState();
}

class _SettingsNetworkState extends State<SettingsNetwork> {
  final NetworkManager _network = Get.find<NetworkManager>();

  String get _currentDnsLabel {
    final customUrl = NetworkKeys.customDnsUrl.get<String>('');
    if (customUrl.isEmpty) {
      return 'Cloudflare (Default)';
    }
    final match = DohProvider.forUrl(customUrl);
    return match?.displayName ?? customUrl;
  }

  String get _currentProxyLabel {
    final proxy = NetworkKeys.proxyUrl.get<String>('');
    return proxy.isEmpty ? 'None' : proxy;
  }

  String get _currentUserAgentLabel {
    final ua = NetworkKeys.customUserAgent.get<String>('');
    return ua.isEmpty ? 'Default' : ua;
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Network',
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            AnymeXHeaderScope.of(ctx),
            16.0,
            30.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnymeXSectionBuilder(
                title: 'Requests',
                children: [
                  AnymeXTile(
                    icon: HugeIcons.strokeRoundedGlobe,
                    title: 'User-Agent',
                    subtitle: _currentUserAgentLabel,
                    onTap: () => _openUserAgentDialog(context),
                  ),
                  AnymeXTile.toggle(
                    icon: Icons.shield_outlined,
                    title: 'Verify TLS certificates',
                    subtitle:
                        'Disabling may bypass captive portals or SSL inspect, but decreases security.',
                    value: _network.verifyTls,
                    onChanged: (val) {
                      NetworkKeys.verifyTls.set(val);
                      _network.reinitialize();
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnymeXSectionBuilder(
                title: 'DNS & Proxy',
                children: [
                  AnymeXTile(
                    icon: Icons.dns_rounded,
                    title: 'DNS-over-HTTPS',
                    subtitle: _currentDnsLabel,
                    onTap: () => _openDnsSheet(context),
                  ),
                  AnymeXTile(
                    icon: HugeIcons.strokeRoundedShield01,
                    title: 'Proxy',
                    subtitle: _currentProxyLabel,
                    onTap: () => _openProxySheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnymeXSectionBuilder(
                title: 'Cache & Storage',
                children: [
                  AnymeXTile(
                    icon: Icons.cookie_outlined,
                    title: 'Clear cookies',
                    subtitle:
                        'Delete all stored HTTP cookies across all domains.',
                    onTap: () => _confirmClearCookies(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearCookies(BuildContext context) {
    AnymeXDialog(
      title: 'Clear Cookies',
      message: 'Are you sure you want to delete all saved cookies?',
      confirmText: 'Clear',
      onConfirm: () {
        _network.cookieManager.clear();
        snackString('Cookies cleared successfully');
      },
    ).show(context);
  }

  Widget _buildSearchStyleInputBar(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
    int? minLines,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer.opaque(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(
              prefixIcon,
              color: colors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: keyboardType,
              obscureText: obscureText,
              maxLines: maxLines,
              minLines: minLines,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Linotte',
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: colors.onSurface.opaque(0.45),
                  fontSize: 13.5,
                  fontFamily: 'Linotte',
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon,
        ],
      ),
    );
  }

  Widget _buildSheetButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
    double height = 44,
  }) {
    final colors = Theme.of(context).colorScheme;
    Color bg;
    Color textCol;
    BoxBorder? border;

    if (isPrimary) {
      bg = colors.primary;
      textCol = colors.onPrimary;
    } else if (isDestructive) {
      bg = colors.error.opaque(0.12, iReallyMeanIt: true);
      textCol = colors.error;
      border =
          Border.all(color: colors.error.opaque(0.2, iReallyMeanIt: true));
    } else {
      bg = colors.surfaceContainerHighest.opaque(0.4, iReallyMeanIt: true);
      textCol = colors.onSurface;
      border = Border.all(
          color: colors.onSurface.opaque(0.06, iReallyMeanIt: true));
    }

    return AnymexOnTap(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: border,
        ),
        child: AnymeXText(
          label,
          size: 13.5,
          variant: TextVariant.bold,
          color: textCol,
        ),
      ),
    );
  }

  void _openUserAgentDialog(BuildContext context) {
    final controller = TextEditingController(
      text: NetworkKeys.customUserAgent.get<String>(''),
    );

    AnymeXDialog(
      title: 'Custom User-Agent',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchStyleInputBar(
            context,
            controller: controller,
            hintText: _network.defaultUserAgent,
            prefixIcon: HugeIcons.strokeRoundedGlobe,
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnymexOnTap(
                onTap: () {
                  controller.clear();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: AnymeXText(
                    'Reset to Default',
                    size: 13,
                    color: Theme.of(context).colorScheme.primary,
                    variant: TextVariant.semiBold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      confirmText: 'Save',
      onConfirm: () {
        final val = controller.text.trim();
        NetworkKeys.customUserAgent.set(val);
        _network.reinitialize();
        setState(() {});
      },
    ).show(context);
  }

  void _openDnsSheet(BuildContext context) {
    final currentVal = NetworkKeys.customDnsUrl.get<String>('');
    final controller = TextEditingController(text: currentVal);
    var testStatus = '';
    var isTesting = false;

    AnymeXSheet.custom(
      StatefulBuilder(
        builder: (ctx, setSheetState) {
          final colors = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              colors.primary.opaque(0.12, iReallyMeanIt: true),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.dns_rounded,
                            color: colors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: AnymeXText(
                          'DNS-over-HTTPS',
                          size: 17,
                          variant: TextVariant.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: AnymeXText(
                      'CUSTOM DOH URL',
                      size: 11,
                      variant: TextVariant.bold,
                      color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                    ),
                  ),
                  _buildSearchStyleInputBar(
                    ctx,
                    controller: controller,
                    hintText: 'https://cloudflare-dns.com/dns-query',
                    prefixIcon: Icons.link_rounded,
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.cancel_rounded,
                              size: 18,
                              color: colors.onSurface
                                  .opaque(0.4, iReallyMeanIt: true),
                            ),
                            onPressed: () {
                              controller.clear();
                              setSheetState(() => testStatus = '');
                            },
                          )
                        : null,
                    onChanged: (_) => setSheetState(() => testStatus = ''),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 13,
                          color:
                              colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                        ),
                        const SizedBox(width: 6),
                        AnymeXText(
                          'PRESET PROVIDERS',
                          size: 11,
                          variant: TextVariant.bold,
                          color:
                              colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                        ),
                      ],
                    ),
                  ),
                  AnymeXPills(
                    wrap: true,
                    style: PillStyle.standalone,
                    items: DohProvider.values.map((p) {
                      final isSelected = controller.text.trim() == p.url;
                      return PillItem(
                        label: p.displayName,
                        isSelected: isSelected,
                        onTap: () {
                          controller.text = p.url;
                          setSheetState(() => testStatus = '');
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow
                          .opaque(0.5, iReallyMeanIt: true),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            colors.onSurface.opaque(0.06, iReallyMeanIt: true),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnymexOnTap(
                          onTap: isTesting
                              ? () {}
                              : () async {
                                  final url = controller.text.trim().isNotEmpty
                                      ? controller.text.trim()
                                      : DohProvider.cloudflare.url;
                                  setSheetState(() {
                                    isTesting = true;
                                    testStatus = 'Testing...';
                                  });
                                  final result = await _testDns(url);
                                  setSheetState(() {
                                    isTesting = false;
                                    testStatus = result.$2;
                                  });
                                },
                          scale: 0.96,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: colors.primary
                                  .opaque(0.12, iReallyMeanIt: true),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colors.primary
                                    .opaque(0.25, iReallyMeanIt: true),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isTesting)
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.primary,
                                    ),
                                  )
                                else
                                  Icon(Icons.bolt_rounded,
                                      size: 16, color: colors.primary),
                                const SizedBox(width: 6),
                                AnymeXText(
                                  'Test',
                                  size: 12,
                                  variant: TextVariant.semiBold,
                                  color: colors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnymeXText(
                            testStatus.isNotEmpty
                                ? testStatus
                                : 'Tap to test DNS latency',
                            size: 12,
                            color: testStatus.isNotEmpty
                                ? colors.primary
                                : colors.onSurface
                                    .opaque(0.45, iReallyMeanIt: true),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildSheetButton(
                        ctx,
                        label: 'Reset',
                        onTap: () {
                          controller.clear();
                          NetworkKeys.customDnsUrl.set('');
                          _network.reinitialize();
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                      ),
                      const Spacer(),
                      _buildSheetButton(
                        ctx,
                        label: 'Cancel',
                        onTap: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(width: 8),
                      _buildSheetButton(
                        ctx,
                        label: 'Save',
                        isPrimary: true,
                        onTap: () {
                          final text = controller.text.trim();
                          NetworkKeys.customDnsUrl.set(text);
                          _network.reinitialize();
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      context,
      showDragHandle: true,
    );
  }

  void _openProxySheet(BuildContext context) {
    final currentProxy = NetworkKeys.proxyUrl.get<String>('');
    final parsed = _parseProxy(currentProxy);

    var protocol = parsed.protocol;
    final hostCtrl = TextEditingController(text: parsed.host);
    final portCtrl = TextEditingController(text: parsed.port);
    final userCtrl = TextEditingController(text: parsed.user);
    final passCtrl = TextEditingController(text: parsed.pass);
    var isObscured = true;
    var testStatus = '';
    var isTesting = false;

    AnymeXSheet.custom(
      StatefulBuilder(
        builder: (ctx, setSheetState) {
          final colors = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              colors.primary.opaque(0.12, iReallyMeanIt: true),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(HugeIcons.strokeRoundedShield01,
                            color: colors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: AnymeXText(
                          'Proxy Configuration',
                          size: 17,
                          variant: TextVariant.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: AnymeXText(
                      'PROTOCOL',
                      size: 11,
                      variant: TextVariant.bold,
                      color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                    ),
                  ),
                  AnymeXPills(
                    style: PillStyle.connective,
                    scrollable: false,
                    expandEqually: true,
                    items: [
                      PillItem(
                        label: 'HTTP',
                        isSelected: protocol == 'http',
                        onTap: () {
                          setSheetState(() {
                            protocol = 'http';
                            testStatus = '';
                          });
                        },
                      ),
                      PillItem(
                        label: 'SOCKS5',
                        isSelected: protocol == 'socks5',
                        onTap: () {
                          setSheetState(() {
                            protocol = 'socks5';
                            testStatus = '';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: AnymeXText(
                      'SERVER DETAILS',
                      size: 11,
                      variant: TextVariant.bold,
                      color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildSearchStyleInputBar(
                          ctx,
                          controller: hostCtrl,
                          hintText: 'Host (e.g. 127.0.0.1)',
                          prefixIcon: Icons.router_rounded,
                          onChanged: (_) =>
                              setSheetState(() => testStatus = ''),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _buildSearchStyleInputBar(
                          ctx,
                          controller: portCtrl,
                          hintText: protocol == 'socks5' ? '1080' : '8080',
                          prefixIcon: Icons.tag_rounded,
                          keyboardType: TextInputType.number,
                          onChanged: (_) =>
                              setSheetState(() => testStatus = ''),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: AnymeXText(
                      'AUTHENTICATION (OPTIONAL)',
                      size: 11,
                      variant: TextVariant.bold,
                      color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSearchStyleInputBar(
                          ctx,
                          controller: userCtrl,
                          hintText: 'Username',
                          prefixIcon: Icons.person_outline_rounded,
                          onChanged: (_) =>
                              setSheetState(() => testStatus = ''),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSearchStyleInputBar(
                          ctx,
                          controller: passCtrl,
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: isObscured,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isObscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: colors.onSurface
                                  .opaque(0.4, iReallyMeanIt: true),
                            ),
                            onPressed: () {
                              setSheetState(() {
                                isObscured = !isObscured;
                              });
                            },
                          ),
                          onChanged: (_) =>
                              setSheetState(() => testStatus = ''),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow
                          .opaque(0.5, iReallyMeanIt: true),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            colors.onSurface.opaque(0.06, iReallyMeanIt: true),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnymexOnTap(
                          onTap: isTesting
                              ? () {}
                              : () async {
                                  final pString = _buildProxyString(
                                    protocol: protocol,
                                    host: hostCtrl.text,
                                    port: portCtrl.text,
                                    user: userCtrl.text,
                                    pass: passCtrl.text,
                                  );
                                  if (pString.isEmpty) {
                                    setSheetState(
                                        () => testStatus = 'Host is required');
                                    return;
                                  }
                                  setSheetState(() {
                                    isTesting = true;
                                    testStatus = 'Connecting...';
                                  });
                                  final result = await _testProxy(pString);
                                  setSheetState(() {
                                    isTesting = false;
                                    testStatus = result.$2;
                                  });
                                },
                          scale: 0.96,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: colors.primary
                                  .opaque(0.12, iReallyMeanIt: true),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colors.primary
                                    .opaque(0.25, iReallyMeanIt: true),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isTesting)
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.primary,
                                    ),
                                  )
                                else
                                  Icon(Icons.wifi_find_rounded,
                                      size: 16, color: colors.primary),
                                const SizedBox(width: 6),
                                AnymeXText(
                                  'Test',
                                  size: 12,
                                  variant: TextVariant.semiBold,
                                  color: colors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnymeXText(
                            testStatus.isNotEmpty
                                ? testStatus
                                : 'Tap to test proxy latency',
                            size: 12,
                            color: testStatus.isNotEmpty
                                ? colors.primary
                                : colors.onSurface
                                    .opaque(0.45, iReallyMeanIt: true),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildSheetButton(
                        ctx,
                        label: 'Clear Proxy',
                        isDestructive: true,
                        onTap: () {
                          NetworkKeys.proxyUrl.set('');
                          _network.reinitialize();
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                      ),
                      const Spacer(),
                      _buildSheetButton(
                        ctx,
                        label: 'Cancel',
                        onTap: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(width: 8),
                      _buildSheetButton(
                        ctx,
                        label: 'Save',
                        isPrimary: true,
                        onTap: () {
                          final pString = _buildProxyString(
                            protocol: protocol,
                            host: hostCtrl.text,
                            port: portCtrl.text,
                            user: userCtrl.text,
                            pass: passCtrl.text,
                          );
                          NetworkKeys.proxyUrl.set(pString);
                          _network.reinitialize();
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      context,
      showDragHandle: true,
    );
  }

  static ({String protocol, String host, String port, String user, String pass})
      _parseProxy(String raw) {
    if (raw.isEmpty) {
      return (protocol: 'http', host: '', port: '', user: '', pass: '');
    }
    try {
      final uri = Uri.parse(raw.contains('://') ? raw : 'http://$raw');
      final protocol = uri.scheme.startsWith('socks') ? 'socks5' : 'http';
      final userInfo = uri.userInfo.split(':');
      return (
        protocol: protocol,
        host: uri.host,
        port: uri.hasPort ? uri.port.toString() : '',
        user: userInfo.isNotEmpty ? userInfo[0] : '',
        pass: userInfo.length > 1 ? userInfo[1] : '',
      );
    } catch (_) {
      return (protocol: 'http', host: raw, port: '', user: '', pass: '');
    }
  }

  static String _buildProxyString({
    required String protocol,
    required String host,
    required String port,
    required String user,
    required String pass,
  }) {
    final h = host.trim();
    if (h.isEmpty) return '';
    final defaultPort = protocol == 'socks5' ? '1080' : '8080';
    final p = port.trim().isEmpty ? defaultPort : port.trim();
    final u = user.trim();
    final pw = pass.trim();
    final auth = u.isNotEmpty
        ? (pw.isNotEmpty
            ? '${Uri.encodeComponent(u)}:${Uri.encodeComponent(pw)}@'
            : '${Uri.encodeComponent(u)}@')
        : '';
    return '$protocol://$auth$h:$p';
  }

  static Future<(bool, String)> _testDns(String url) async {
    final sw = Stopwatch()..start();
    try {
      final addrs = await DnsManager.resolveWithDoh(
        'google.com',
        url,
        bootstrapIps: DohProvider.forUrl(url)?.bootstrapIps ?? const [],
      );
      sw.stop();
      return addrs.isNotEmpty
          ? (true, '${addrs.first} · ${sw.elapsedMilliseconds} ms')
          : (false, 'No records returned');
    } catch (e) {
      sw.stop();
      final msg = e.toString().split('\n').first;
      return (false, msg.length > 40 ? '${msg.substring(0, 40)}…' : msg);
    }
  }

  static Future<(bool, String)> _testProxy(String proxy) async {
    RhttpClient? c;
    final sw = Stopwatch()..start();
    try {
      final proxySettings = proxy.contains('://')
          ? ProxySettings.proxy(proxy)
          : ProxySettings.proxy('http://$proxy');
      c = RhttpClient.createSync(
        settings: ClientSettings(
          throwOnStatusCode: false,
          tlsSettings: const TlsSettings(verifyCertificates: false),
          timeoutSettings: const TimeoutSettings(
            connectTimeout: Duration(seconds: 8),
            timeout: Duration(seconds: 10),
          ),
          proxySettings: proxySettings,
        ),
      );
      final res = await c.get('https://httpbin.org/ip');
      sw.stop();
      return res.statusCode < 400
          ? (true, '${sw.elapsedMilliseconds} ms')
          : (false, 'HTTP ${res.statusCode}');
    } catch (e) {
      sw.stop();
      final msg = e.toString().split('\n').first;
      return (false, msg.length > 40 ? '${msg.substring(0, 40)}…' : msg);
    } finally {
      c?.dispose();
    }
  }
}
