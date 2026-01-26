import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'extension_test_controller.dart';
import 'extension_test_settings_sheet.dart';

class ExtensionTestPage extends StatefulWidget {
  const ExtensionTestPage({super.key});

  @override
  State<ExtensionTestPage> createState() => _ExtensionTestPageState();
}

class _ExtensionTestPageState extends State<ExtensionTestPage> {
  late ExtensionTestController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ExtensionTestController());
  }

  @override
  void dispose() {
    Get.delete<ExtensionTestController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;

    return Glow(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: getResponsiveValue(context,
              mobileValue: Center(
                child: AnymexOnTap(
                  onTap: () => Get.back(),
                  child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color:
                              Theme.of(context).colorScheme.surfaceContainer),
                      child: const Icon(Icons.arrow_back_ios_new_rounded)),
                ),
              ),
              desktopValue: const SizedBox.shrink()),
          leadingWidth: getResponsiveValue(context,
              mobileValue: null, desktopValue: 0.0),
          title: Text(
            "Extension Test",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: theme.primary,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: const Text(
                    "View Options",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(Icons.settings, color: theme.primary),
                  onTap: () => _showTestSettings(context),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => ElevatedButton.icon(
                    onPressed: controller.selectedExtensions.isEmpty
                        ? null
                        : () => controller.startTests(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Start Test"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: theme.onPrimary,
                      disabledBackgroundColor:
                          theme.primary.withOpacity(0.5),
                    ),
                  )),
              const SizedBox(height: 24),
              Expanded(
                child: Obx(() => controller.testResults.isEmpty
                    ? Center(
                        child: Text(
                          "No tests running",
                          style: TextStyle(
                            color: theme.onSurface,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: controller.testResults.length,
                        itemBuilder: (context, index) {
                          return controller.testResults[index];
                        },
                      )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTestSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExtensionTestSettingsSheet(
        controller: controller,
      ),
    );
  }
}