import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PlayerShaders {
  static final shaderProfiles = {
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
  };

  static List<String> getShaders() => shaderProfiles.keys.toList();

  static List<String> getShaderByProfile(String profile) {
    return shaderProfiles[profile] ?? [''];
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

  static Future<String> getShaderBasePath() async {
    final dir = await _getAppDirectory();
    return '${dir.path}/mpv/Shaders/';
  }

  static Future<String> getShaderPathForProfile(String shaderProfile) async {
    final basePath = await getShaderBasePath();

    return '$basePath$shaderProfile/';
  }

  static Future<List<String>> getShaderPathsForProfile(
      String profile, String shaderProfile) async {
    final shaderFiles = getShaderByProfile(profile);
    final shaderFolderPath = await getShaderPathForProfile(shaderProfile);

    return shaderFiles.map((file) => '$shaderFolderPath$file').toList();
  }

  static Future<bool> areShadersDownloaded() async {
    try {
      final basePath = await getShaderBasePath();
      final midEndDir = Directory('${basePath}MID-END');
      final highEndDir = Directory('${basePath}HIGH-END');

      return await midEndDir.exists() && await highEndDir.exists();
    } catch (e) {
      debugPrint('Error checking shader directories: $e');
      return false;
    }
  }
}
