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

  static Future<CustomLogo?> pickAndSaveCustomLogo(String name) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gif', 'webp', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      final originalPath = file.path;
      if (originalPath == null) return null;

      final fileSize = file.size;
      if (fileSize > maxFileSizeBytes) {
        throw Exception(
            'File size exceeds 20MB limit (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB)');
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
        name: name.trim().isEmpty ? 'Custom Logo' : name.trim(),
        filePath: targetPath,
        fileSizeBytes: fileSize,
        createdAt: DateTime.now(),
      );

      final currentLogos = getCustomLogos();
      currentLogos.insert(0, newLogo);
      _saveCustomLogos(currentLogos);

      // Auto-select newly added logo
      selectCustomLogo(id);

      return newLogo;
    } catch (e) {
      Logger.e('Failed to pick and save custom logo: $e');
      rethrow;
    }
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
