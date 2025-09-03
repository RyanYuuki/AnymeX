import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class CookieManagerService extends GetxController {
  static CookieManagerService get instance => Get.find();
  
  late Box _cookieBox;
  
  @override
  void onInit() {
    super.onInit();
    _initializeCookieBox();
  }
  
  Future<void> _initializeCookieBox() async {
    try {
      _cookieBox = await Hive.openBox('captcha_cookies');
    } catch (e) {
      print('Error initializing cookie box: $e');
    }
  }
  
  /// Extract cookies from WebView and store them for domain
  Future<void> saveCookiesFromWebView(WebUri url) async {
    try {
      await _initializeCookieBox();
      final domain = url.host;
      if (domain.isEmpty) return;
      
      final cookieManager = CookieManager.instance();
      final cookies = await cookieManager.getCookies(url: url);
      
      if (cookies.isNotEmpty) {
        final cookieMap = <String, dynamic>{};
        for (final cookie in cookies) {
          cookieMap[cookie.name] = {
            'value': cookie.value,
            'domain': cookie.domain ?? domain,
            'path': cookie.path ?? '/',
            'httpOnly': cookie.isHttpOnly,
            'secure': cookie.isSecure,
            'sameSite': cookie.sameSite?.toString(),
            'expiresDate': cookie.expiresDate?.millisecondsSinceEpoch,
          };
        }
        
        // Store cookies for this domain
        await _cookieBox.put(domain, jsonEncode(cookieMap));
        print('Saved ${cookies.length} cookies for domain: $domain');
        
        // Also save with base domain (for subdomains)
        final baseDomain = _extractBaseDomain(domain);
        if (baseDomain != domain) {
          await _cookieBox.put(baseDomain, jsonEncode(cookieMap));
        }
      }
    } catch (e) {
      print('Error saving cookies from WebView: $e');
    }
  }
  
  /// Get cookie header string for HTTP requests
  String? getCookieHeaderForDomain(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      final baseDomain = _extractBaseDomain(domain);
      
      // Try exact domain first, then base domain
      final cookiesJson = _cookieBox.get(domain) ?? _cookieBox.get(baseDomain);
      if (cookiesJson == null) return null;
      
      final cookieMap = jsonDecode(cookiesJson) as Map<String, dynamic>;
      final cookieStrings = <String>[];
      
      final now = DateTime.now();
      
      for (final entry in cookieMap.entries) {
        final cookieData = entry.value as Map<String, dynamic>;
        final expiresDate = cookieData['expiresDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(cookieData['expiresDate'])
            : null;
        
        // Skip expired cookies
        if (expiresDate != null && expiresDate.isBefore(now)) {
          continue;
        }
        
        // Check if cookie is for current path
        final cookiePath = cookieData['path'] as String? ?? '/';
        if (!uri.path.startsWith(cookiePath)) {
          continue;
        }
        
        cookieStrings.add('${entry.key}=${cookieData['value']}');
      }
      
      return cookieStrings.isNotEmpty ? cookieStrings.join('; ') : null;
    } catch (e) {
      print('Error getting cookie header: $e');
      return null;
    }
  }
  
  /// Apply saved cookies to WebView for a domain
  Future<void> applyCookiesToWebView(WebUri url) async {
    try {
      final domain = url.host;
      final baseDomain = _extractBaseDomain(domain);
      
      // Try exact domain first, then base domain
      final cookiesJson = _cookieBox.get(domain) ?? _cookieBox.get(baseDomain);
      if (cookiesJson == null) return;
      
      final cookieMap = jsonDecode(cookiesJson) as Map<String, dynamic>;
      final cookieManager = CookieManager.instance();
      
      final now = DateTime.now();
      
      for (final entry in cookieMap.entries) {
        final cookieData = entry.value as Map<String, dynamic>;
        final expiresDate = cookieData['expiresDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(cookieData['expiresDate'])
            : null;
        
        // Skip expired cookies
        if (expiresDate != null && expiresDate.isBefore(now)) {
          continue;
        }
        
        final cookie = Cookie(
          name: entry.key,
          value: cookieData['value'],
          domain: cookieData['domain'] ?? domain,
          path: cookieData['path'] ?? '/',
          expiresDate: expiresDate,
          isHttpOnly: cookieData['httpOnly'] ?? false,
          isSecure: cookieData['secure'] ?? false,
          sameSite: _parseSameSite(cookieData['sameSite']),
        );
        
        await cookieManager.setCookie(url: url, cookie: cookie);
      }
      
      print('Applied saved cookies to WebView for domain: $domain');
    } catch (e) {
      print('Error applying cookies to WebView: $e');
    }
  }
  
  /// Check if we have valid cookies for a domain
  bool hasCookiesForDomain(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      final baseDomain = _extractBaseDomain(domain);
      
      final cookiesJson = _cookieBox.get(domain) ?? _cookieBox.get(baseDomain);
      if (cookiesJson == null) return false;
      
      final cookieMap = jsonDecode(cookiesJson) as Map<String, dynamic>;
      
      // Check if we have any non-expired cookies
      final now = DateTime.now();
      return cookieMap.values.any((cookieData) {
        final expiresDate = cookieData['expiresDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(cookieData['expiresDate'])
            : null;
        return expiresDate == null || expiresDate.isAfter(now);
      });
    } catch (e) {
      return false;
    }
  }
  
  /// Clear cookies for a domain
  Future<void> clearCookiesForDomain(String url) async {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      final baseDomain = _extractBaseDomain(domain);
      
      await _cookieBox.delete(domain);
      await _cookieBox.delete(baseDomain);
      
      // Also clear from WebView
      final cookieManager = CookieManager.instance();
      await cookieManager.deleteCookies(url: WebUri(url));
      
      print('Cleared cookies for domain: $domain');
    } catch (e) {
      print('Error clearing cookies: $e');
    }
  }
  
  /// Extract base domain from hostname (e.g., sub.example.com -> example.com)
  String _extractBaseDomain(String domain) {
    final parts = domain.split('.');
    if (parts.length <= 2) return domain;
    
    // Return last two parts for base domain
    return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
  }
  
  /// Parse SameSite attribute
  HTTPCookieSameSitePolicy? _parseSameSite(String? sameSite) {
    if (sameSite == null) return null;
    switch (sameSite.toLowerCase()) {
      case 'lax':
        return HTTPCookieSameSitePolicy.LAX;
      case 'strict':
        return HTTPCookieSameSitePolicy.STRICT;
      case 'none':
        return HTTPCookieSameSitePolicy.NONE;
      default:
        return null;
    }
  }
}