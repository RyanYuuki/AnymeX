import 'package:anymex/utils/logger.dart';
import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
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
      return Directory('/storage/emulated/0/AnymeX');
    } else {
      final documentsDir = await getApplicationDocumentsDirectory();
      return Directory('${documentsDir.path}/AnymeX');
    }
  }

  static Future<String> getMpvPath() async {
    final dir = await _getAppDirectory();
    return '${dir.path}/mpv/';
  }

  static String getShaderBasePath() {
    final path = settingsController.mpvPath.value;
    return '${path}Shaders/';
  }

  static Future<List<String>> getShaderPathsForProfile(
      String configName) async {
    final shaderFiles = getShaderByName(configName);
    final shaderFolderPath = PlayerShaders.getShaderBasePath();

    return shaderFiles.map((file) => '$shaderFolderPath$file').toList();
  }

  static void setShaders(dynamic player, String shader) async {
    settingsController.selectedShader = shader;
    var paths =
        (await PlayerShaders.getShaderPathsForProfile(shader)).join(';');
    Logger.i('Paths: $paths');
    (player.platform as dynamic).setProperty('glsl-shaders', paths);
  }

  static Future<bool> areShadersDownloaded() async {
    try {
      final basePath = getShaderBasePath();
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
      final mpvPath = await getMpvPath();
      final configDir = Directory(mpvPath);

      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
        debugPrint('Created MPV directory: ${configDir.path}');
      }

      final configFile = File('${configDir.path}mpv.conf');

      if (!await configFile.exists()) {
        await configFile.writeAsString('');
        debugPrint('Created empty MPV config file: ${configFile.path}');
      }

      return true;
    } catch (e) {
      debugPrint('Error creating MPV config folder/file: $e');
      return false;
    }
  }

  static Future<String> getMpvConfigPath() async {
    final mpvPath = await getMpvPath();
    return '${mpvPath}mpv.conf';
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
