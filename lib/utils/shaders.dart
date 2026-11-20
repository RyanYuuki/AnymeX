import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PlayerShaders {
  static final shaderProfiles = {
    "MID-END": {
      'Anime4K: Mode A (Fast)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Restore_CNN_M.glsl',
        'Anime4K_Upscale_CNN_x2_M.glsl',
      ],
      'Anime4K: Mode B (Fast)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Restore_CNN_Soft_M.glsl',
        'Anime4K_Upscale_CNN_x2_M.glsl',
      ],
      'Anime4K: Mode C (Fast)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Upscale_Denoise_CNN_x2_M.glsl',
      ],
      'Anime4K: Mode A+A (Fast)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Restore_CNN_VL.glsl',
        'Anime4K_Upscale_CNN_x2_VL.glsl',
        'Anime4K_Restore_CNN_M.glsl',
        'Anime4K_Upscale_CNN_x2_M.glsl',
      ],
      'Anime4K: Mode B+B (Fast)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Restore_CNN_Soft_VL.glsl',
        'Anime4K_Upscale_CNN_x2_VL.glsl',
        'Anime4K_Restore_CNN_Soft_M.glsl',
        'Anime4K_Upscale_CNN_x2_M.glsl',
      ],
      'Anime4K: Mode C+A (Fast)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Upscale_Denoise_CNN_x2_VL.glsl',
        'Anime4K_Restore_CNN_M.glsl',
        'Anime4K_Upscale_CNN_x2_M.glsl',
      ],
    },
    "HIGH-END": {
      'Anime4K: Mode A (HQ)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Restore_CNN_VL.glsl',
        'Anime4K_Upscale_CNN_x2_VL.glsl',
        'Anime4K_AutoDownscalePre_x2.glsl',
        'Anime4K_AutoDownscalePre_x4.glsl',
        'Anime4K_Upscale_CNN_x2_M.glsl',
      ],
      'Anime4K: Mode B (HQ)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Restore_CNN_Soft_VL.glsl',
        'Anime4K_Upscale_CNN_x2_VL.glsl',
        'Anime4K_AutoDownscalePre_x2.glsl',
        'Anime4K_AutoDownscalePre_x4.glsl',
        'Anime4K_Upscale_CNN_x2_M.glsl',
      ],
      'Anime4K: Mode C (HQ)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Upscale_Denoise_CNN_x2_VL.glsl',
        'Anime4K_AutoDownscalePre_x2.glsl',
        'Anime4K_AutoDownscalePre_x4.glsl',
        'Anime4K_Upscale_CNN_x2_M.glsl',
      ],
      'Anime4K: Mode A+A (HQ)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Restore_CNN_VL.glsl',
        'Anime4K_Upscale_CNN_x2_VL.glsl',
        'Anime4K_Restore_CNN_M.glsl',
        'Anime4K_AutoDownscalePre_x2.glsl',
        'Anime4K_AutoDownscalePre_x4.glsl',
        'Anime4K_Upscale_CNN_x2_M.glsl',
      ],
      'Anime4K: Mode B+B (HQ)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Restore_CNN_Soft_VL.glsl',
        'Anime4K_Upscale_CNN_x2_VL.glsl',
        'Anime4K_AutoDownscalePre_x2.glsl',
        'Anime4K_AutoDownscalePre_x4.glsl',
        'Anime4K_Restore_CNN_Soft_M.glsl',
        'Anime4K_Upscale_CNN_x2_M.glsl',
      ],
      'Anime4K: Mode C+A (HQ)': [
        'Anime4K_Clamp_Highlights.glsl',
        'Anime4K_Upscale_Denoise_CNN_x2_VL.glsl',
        'Anime4K_AutoDownscalePre_x2.glsl',
        'Anime4K_AutoDownscalePre_x4.glsl',
        'Anime4K_Restore_CNN_M.glsl',
        'Anime4K_Upscale_CNN_x2_M.glsl',
      ],
    }
  };

  static List<String> getShaderProfiles() => shaderProfiles.keys.toList();

  static List<String> getShaders() {
    final selectedProfile = settingsController.selectedProfile;
    return shaderProfiles[selectedProfile]?.keys.toList() ?? [];
  }

  static List<String> getShaderByName(String configName) {
    final selectedProfile = settingsController.selectedProfile;
    final shaders = shaderProfiles[selectedProfile]?[configName] ?? <String>[];

    Logger.i(
        'Profile: $selectedProfile, Config: $configName, Shaders: $shaders');
    return shaders;
  }

  static Future<Directory> _getAppDirectory() async {
    if (Platform.isAndroid) {
      final primary = Directory('/storage/emulated/0/AnymeX');
      try {
        if (!await primary.exists()) {
          await primary.create(recursive: true);
        }
        return primary;
      } catch (_) {
        try {
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            final rootMatch =
                RegExp(r'^/storage/[^/]+/[^/]+').firstMatch(ext.path);
            if (rootMatch != null) {
              final rootDir = Directory('${rootMatch.group(0)}/AnymeX');
              if (!await rootDir.exists()) {
                await rootDir.create(recursive: true);
              }
              return rootDir;
            }
          }
        } catch (_) {}
      }
    }
    final documentsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${documentsDir.path}/AnymeX');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> getMpvPath() async {
    final dir = await _getAppDirectory();
    final subDir = Directory('${dir.path}/mpv');
    if (await subDir.exists()) {
      return '${dir.path}/mpv/';
    }
    return '${dir.path}/';
  }

  static Future<String> getShaderBasePath() async {
    final dir = await _getAppDirectory();
    final subDir = Directory('${dir.path}/mpv/Shaders');
    if (await subDir.exists()) {
      return '${dir.path}/mpv/Shaders/';
    }
    final mainShaders = Directory('${dir.path}/Shaders');
    if (!await mainShaders.exists()) {
      await mainShaders.create(recursive: true);
    }
    return '${dir.path}/Shaders/';
  }

  static Future<List<String>> getShaderPathsForProfile(
      String configName) async {
    final shaderFiles = getShaderByName(configName);
    final shaderFolderPath = await PlayerShaders.getShaderBasePath();

    return shaderFiles.map((file) => '$shaderFolderPath$file').toList();
  }

  static Future<void> setShaders(dynamic player, String shader) async {
    settingsController.selectedShader = shader;
    final separator = Platform.isWindows ? ';' : ':';
    var paths =
        (await PlayerShaders.getShaderPathsForProfile(shader)).join(separator);
    Logger.i('Paths: $paths');
    (player.platform as dynamic).setProperty('glsl-shaders', paths);
  }

  static Future<bool> areShadersDownloaded() async {
    try {
      final basePath = await getShaderBasePath();
      final dir = Directory(basePath);

      if (!await dir.exists()) return false;

      final items = await dir.list().toList();
      return items.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking shader directories: $e');
      return false;
    }
  }

  static Future<bool> createMpvConfigFolder() async {
    try {
      final configPath = await getMpvConfigPath();
      final configFile = File(configPath);
      final configDir = configFile.parent;

      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }

      if (!await configFile.exists()) {
        try {
          final oldDocsDir = await getApplicationDocumentsDirectory();
          final oldFile = File('${oldDocsDir.path}/AnymeX/mpv/mpv.conf');
          if (await oldFile.exists()) {
            final content = await oldFile.readAsString();
            await configFile.writeAsString(content);
            return true;
          }
        } catch (_) {}
        await configFile.writeAsString('');
      }

      return true;
    } catch (e) {
      debugPrint('Error creating MPV config folder/file: $e');
      return false;
    }
  }

  static Future<String> getMpvConfigPath() async {
    final dir = await _getAppDirectory();
    final directFile = File('${dir.path}/mpv.conf');
    final subFile = File('${dir.path}/mpv/mpv.conf');
    if (await subFile.exists() && !await directFile.exists()) {
      return subFile.path;
    }
    return directFile.path;
  }

  static Future<bool> doesMpvConfigExist() async {
    try {
      final configPath = await getMpvConfigPath();
      final configFile = File(configPath);
      return await configFile.exists();
    } catch (e) {
      debugPrint('Error checking MPV config existence: $e');
      return false;
    }
  }
}
