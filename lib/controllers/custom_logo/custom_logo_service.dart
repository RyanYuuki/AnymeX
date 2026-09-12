import 'dart:convert';
import 'dart:io';

import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/custom_logo_model.dart';
import 'package:anymex/utils/logger.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CustomLogoService {
  static const int maxFileSizeBytes = 20 * 1024 * 1024; // 20 MB

  static List<CustomLogo> getCustomLogos() {
    try {
      final jsonStr = ThemeKeys.customLogos.get<String>('[]');
      if (jsonStr.isEmpty || jsonStr == '[]') return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .map((e) => CustomLogo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Logger.e('Failed to read custom logos: $e');
      return [];
    }
  }

  static void _saveCustomLogos(List<CustomLogo> logos) {
    try {
      final jsonStr = jsonEncode(logos.map((e) => e.toJson()).toList());
      ThemeKeys.customLogos.set(jsonStr);
    } catch (e) {
      Logger.e('Failed to save custom logos: $e');
    }
  }

  static String getSelectedCustomLogoId() {
    try {
      return ThemeKeys.selectedCustomLogoId.get<String>('');
    } catch (_) {
      return '';
    }
  }

  static CustomLogo? getSelectedCustomLogo() {
    final selectedId = getSelectedCustomLogoId();
    if (selectedId.isEmpty) return null;
    final logos = getCustomLogos();
    try {
      final logo = logos.firstWhere((l) => l.id == selectedId);
      if (File(logo.filePath).existsSync()) {
        return logo;
      }
    } catch (_) {}
    return null;
  }

  static String? getSelectedCustomLogoPath() {
    return getSelectedCustomLogo()?.filePath;
  }

  static void selectCustomLogo(String id) {
    ThemeKeys.selectedCustomLogoId.set(id);
  }

  static void clearCustomLogoSelection() {
    ThemeKeys.selectedCustomLogoId.set('');
  }

  static void setSizeMode(String id, CustomLogoSizeMode sizeMode) {
    final logos = getCustomLogos();
    final index = logos.indexWhere((l) => l.id == id);
    if (index != -1) {
      logos[index] = logos[index].copyWith(sizeMode: sizeMode);
      _saveCustomLogos(logos);
    }
  }

  static void setCustomScale(String id, double scale) {
    final logos = getCustomLogos();
    final index = logos.indexWhere((l) => l.id == id);
    if (index != -1) {
      logos[index] = logos[index].copyWith(customScale: scale);
      _saveCustomLogos(logos);
    }
  }

  static void setOriginalSize(String id, bool useOriginalSize) {
    setSizeMode(
      id,
      useOriginalSize
          ? CustomLogoSizeMode.originalSize
          : CustomLogoSizeMode.defaultSize,
    );
  }

  static bool logoNameExists(String name) {
    final clean = name.trim().toLowerCase();
    if (clean.isEmpty) return false;
    final logos = getCustomLogos();
    return logos.any((l) => l.name.trim().toLowerCase() == clean);
  }

  static Future<PlatformFile?> pickLogoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gif', 'webp', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.path == null) return null;
    if (file.size > maxFileSizeBytes) {
      throw Exception(
          'File size exceeds 20MB limit (${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB)');
    }
    return file;
  }

  static Future<CustomLogo> savePickedLogoFile({
    required PlatformFile file,
    required String name,
    CustomLogoSizeMode sizeMode = CustomLogoSizeMode.defaultSize,
    double customScale = 1.0,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Logo name cannot be empty.');
    }
    if (logoNameExists(trimmedName)) {
      throw Exception('A logo named "$trimmedName" already exists.');
    }

    final originalPath = file.path;
    if (originalPath == null) {
      throw Exception('File path is invalid.');
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final logosDir = Directory(p.join(appDocDir.path, 'custom_logos'));
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }

    final ext = p.extension(originalPath).toLowerCase();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final targetFileName = 'logo_$id$ext';
    final targetPath = p.join(logosDir.path, targetFileName);

    await File(originalPath).copy(targetPath);

    final newLogo = CustomLogo(
      id: id,
      name: trimmedName,
      filePath: targetPath,
      fileSizeBytes: file.size,
      createdAt: DateTime.now(),
      sizeMode: sizeMode,
      customScale: customScale,
    );

    final currentLogos = getCustomLogos();
    currentLogos.insert(0, newLogo);
    _saveCustomLogos(currentLogos);

    // Auto-select newly added logo
    selectCustomLogo(id);

    return newLogo;
  }

  static Future<CustomLogo?> updateCustomLogo(
    String id, {
    String? name,
    CustomLogoSizeMode? sizeMode,
    double? customScale,
  }) async {
    final logos = getCustomLogos();
    final index = logos.indexWhere((l) => l.id == id);
    if (index == -1) return null;

    final current = logos[index];
    if (name != null) {
      final clean = name.trim();
      if (clean.isEmpty) {
        throw Exception('Logo name cannot be empty.');
      }
      final duplicate = logos.any((l) =>
          l.id != id && l.name.trim().toLowerCase() == clean.toLowerCase());
      if (duplicate) {
        throw Exception('A logo named "$clean" already exists.');
      }
    }

    final updated = current.copyWith(
      name: name?.trim(),
      sizeMode: sizeMode,
      customScale: customScale,
    );

    logos[index] = updated;
    _saveCustomLogos(logos);
    return updated;
  }

  static Future<CustomLogo?> pickAndSaveCustomLogo(
    String name, {
    CustomLogoSizeMode sizeMode = CustomLogoSizeMode.defaultSize,
    double customScale = 1.0,
    bool? useOriginalSize,
  }) async {
    final file = await pickLogoFile();
    if (file == null) return null;
    return savePickedLogoFile(
      file: file,
      name: name,
      sizeMode: sizeMode != CustomLogoSizeMode.defaultSize
          ? sizeMode
          : ((useOriginalSize ?? false)
              ? CustomLogoSizeMode.originalSize
              : CustomLogoSizeMode.defaultSize),
      customScale: customScale,
    );
  }

  static Future<void> deleteCustomLogo(String id) async {
    try {
      final logos = getCustomLogos();
      final index = logos.indexWhere((l) => l.id == id);
      if (index != -1) {
        final logo = logos[index];
        final file = File(logo.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        logos.removeAt(index);
        _saveCustomLogos(logos);

        if (getSelectedCustomLogoId() == id) {
          clearCustomLogoSelection();
        }
      }
    } catch (e) {
      Logger.e('Failed to delete custom logo: $e');
    }
  }
}
