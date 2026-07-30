import 'dart:convert';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart' as webview;
import 'package:rhttp/rhttp.dart';
import 'package:anymex/database/kv_helper.dart';

class CookieManager extends Interceptor {
  static const _storageKey = "cookies";

  Map<String, StoredCookie>? _cache;

  final Map<String, StoredCookie> _sessionCookies = {};

  Map<String, StoredCookie> _loadAll() {
    if (_cache != null) {
      return _cache!;
    }

    final raw = KvHelper.get<String>(_storageKey, defaultVal: '');

    if (raw.isEmpty) {
      return _cache = {};
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final cookies = decoded.map(
        (k, v) =>
            MapEntry(k, StoredCookie.fromJson(Map<String, dynamic>.from(v))),
      );

      cookies.removeWhere((_, cookie) => cookie.isExpired);

      _cache = cookies;

      return cookies;
    } catch (_) {
      return _cache = {};
    }
  }

  void _saveAll(Map<String, StoredCookie> cookies) {
    cookies.removeWhere((_, cookie) => cookie.isExpired);

    _cache = cookies;

    KvHelper.set<String>(
      _storageKey,
      jsonEncode(cookies.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  void _cleanup() {
    final persistent = _loadAll();

    persistent.removeWhere((_, cookie) => cookie.isExpired);

    _sessionCookies.removeWhere((_, cookie) => cookie.isExpired);

    _saveAll(persistent);
  }

  Iterable<StoredCookie> get _allCookies sync* {
    yield* _loadAll().values;
    yield* _sessionCookies.values;
  }

  List<StoredCookie> get allCookies {
    _cleanup();

    return _allCookies.toList();
  }

  List<StoredCookie> getValidCookies(Uri uri) {
    _cleanup();

    final path = uri.path.isEmpty ? "/" : uri.path;

    final result = <StoredCookie>[];

    for (final cookie in _allCookies) {
      if (cookie.isExpired) continue;

      if (!domainMatches(uri.host, cookie.domain, cookie.hostOnly)) {
        continue;
      }

      if (!pathMatches(path, cookie.path)) {
        continue;
      }

      if (cookie.secure && uri.scheme != "https") {
        continue;
      }

      result.add(cookie.touch());

      if (cookie.session) {
        _sessionCookies[cookie.id] = cookie.touch();
      } else {
        _cache?[cookie.id] = cookie.touch();
      }
    }

    result.sort((a, b) {
      final cmp = b.path.length.compareTo(a.path.length);

      if (cmp != 0) {
        return cmp;
      }

      return a.created.compareTo(b.created);
    });

    if (_cache != null) {
      _saveAll(_cache!);
    }

    return result;
  }

  void setCookies(Iterable<StoredCookie> cookies) {
    final persistent = _loadAll();

    for (final cookie in cookies) {
      if (cookie.isExpired) {
        persistent.remove(cookie.id);
        _sessionCookies.remove(cookie.id);
        continue;
      }

      if (cookie.session) {
        final old = _sessionCookies[cookie.id];

        _sessionCookies[cookie.id] = old == null
            ? cookie
            : cookie.copyWith(created: old.created);
        persistent.remove(cookie.id);
      } else {
        final old = persistent[cookie.id];

        persistent[cookie.id] = old == null
            ? cookie
            : cookie.copyWith(created: old.created);
        _sessionCookies.remove(cookie.id);
      }
    }

    _saveAll(persistent);
  }

  void clear() {
    _cache = {};
    _sessionCookies.clear();

    KvHelper.set<String>(_storageKey, "{}");
  }

  Future<void> deleteCookiesForDomain(String domain) async {
    domain = normalizeDomain(domain);

    final persistent = _loadAll();

    persistent.removeWhere((_, cookie) {
      return domainMatches(
        normalizeDomain(domain),
        normalizeDomain(cookie.domain),
        cookie.hostOnly,
      );
    });

    _sessionCookies.removeWhere((_, cookie) {
      return domainMatches(
        normalizeDomain(domain),
        normalizeDomain(cookie.domain),
        cookie.hostOnly,
      );
    });

    _saveAll(persistent);

    final manager = webview.CookieManager.instance();

    await manager.deleteCookies(url: webview.WebUri("https://$domain"));

    await manager.deleteCookies(url: webview.WebUri("http://$domain"));
  }

  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    final uri = Uri.parse(request.url);

    final cookies = getValidCookies(uri);

    if (cookies.isEmpty) {
      return Interceptor.next(request);
    }

    final header = cookies.map((e) => "${e.name}=${e.value}").join("; ");

    final headers = (request.headers ?? HttpHeaders.empty)
        .copyWithoutRaw("cookie")
        .copyWithRaw(name: "cookie", value: header);

    return Interceptor.next(request.copyWith(headers: headers));
  }

  @override
  Future<InterceptorResult<HttpResponse>> afterResponse(
    HttpResponse response,
  ) async {
    final uri = Uri.parse(response.request.url);

    final headers =
        response.headerMapList["set-cookie"] ??
        response.headerMapList["Set-Cookie"] ??
        const <String>[];

    if (headers.isEmpty) {
      return Interceptor.next();
    }

    final parsed = <StoredCookie>[];

    for (final header in headers) {
      final cookie = parseSingleCookie(header, uri);

      if (cookie != null) {
        parsed.add(cookie);
      }
    }

    if (parsed.isNotEmpty) {
      setCookies(parsed);
    }

    return Interceptor.next();
  }

  StoredCookie? parseSingleCookie(String header, Uri requestUri) {
    final parts = header.split(";");

    if (parts.isEmpty) {
      return null;
    }

    final first = parts.first.trim();

    final eq = first.indexOf("=");

    if (eq <= 0) {
      return null;
    }

    final name = first.substring(0, eq).trim();
    if (name.isEmpty) {
      return null;
    }
    var value = first.substring(eq + 1).trim();

    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    var domain = normalizeDomain(requestUri.host);

    var hostOnly = true;

    var path = defaultCookiePath(requestUri);

    DateTime? expires;

    Duration? maxAge;

    var secure = false;

    var httpOnly = false;

    CookieSameSite? sameSite;

    var priority = CookiePriority.medium;

    var partitioned = false;

    for (final attribute in parts.skip(1)) {
      final text = attribute.trim();

      if (text.isEmpty) {
        continue;
      }

      final idx = text.indexOf("=");

      final key = idx == -1
          ? text.toLowerCase()
          : text.substring(0, idx).trim().toLowerCase();

      final valuePart = idx == -1 ? "" : text.substring(idx + 1).trim();

      switch (key) {
        case "domain":
          if (valuePart.isEmpty) {
            break;
          }

          final normalized = normalizeDomain(valuePart);

          if (!isDomainAllowed(requestUri.host, normalized)) {
            return null;
          }

          domain = normalized;

          hostOnly = false;

          break;

        case "path":
          if (valuePart.startsWith("/")) {
            path = valuePart;
          } else {
            path = "/";
          }
          break;
        case "expires":
          try {
            expires = HttpDate.parse(valuePart);
          } catch (_) {}

          break;

        case "max-age":
          final seconds = int.tryParse(valuePart);

          if (seconds != null) {
            if (seconds <= 0) {
              expires = DateTime.fromMillisecondsSinceEpoch(0);
            } else {
              maxAge = Duration(seconds: seconds);
            }
          }

          break;

        case "secure":
          secure = true;

          break;

        case "httponly":
          httpOnly = true;

          break;

        case "samesite":
          switch (valuePart.toLowerCase()) {
            case "none":
              sameSite = CookieSameSite.none;
              break;

            case "strict":
              sameSite = CookieSameSite.strict;
              break;

            default:
              sameSite = CookieSameSite.lax;
          }

          break;

        case "priority":
          switch (valuePart.toLowerCase()) {
            case "high":
              priority = CookiePriority.high;
              break;

            case "low":
              priority = CookiePriority.low;
              break;

            default:
              priority = CookiePriority.medium;
          }

          break;

        case "partitioned":
          partitioned = true;

          break;
      }
    }

    if (maxAge != null) {
      expires = DateTime.now().add(maxAge);
    }

    return StoredCookie(
      name: name,
      value: value,
      domain: domain,
      hostOnly: hostOnly,
      path: path,
      expires: expires,
      secure: secure,
      httpOnly: httpOnly,
      sameSite: sameSite,
      priority: priority,
      partitioned: partitioned,
      session: expires == null && maxAge == null,
      created: DateTime.now(),
      lastAccessed: DateTime.now(),
    );
  }

  Future<void> readCookiesFromWebView(
    webview.WebUri url,
    webview.InAppWebViewController? controller,
  ) async {
    final manager = webview.CookieManager.instance();

    final cookies = await manager.getCookies(
      url: url,
      webViewController: controller,
    );

    final uri = Uri.parse(url.toString());

    final converted = cookies.map((c) {
      final domain = normalizeDomain(c.domain ?? uri.host);

      return StoredCookie(
        name: c.name,
        value: c.value,
        domain: domain,
        hostOnly: c.domain == null,
        path: c.path?.isNotEmpty == true ? c.path! : defaultCookiePath(uri),
        expires: c.expiresDate == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(c.expiresDate!),
        secure: c.isSecure ?? false,
        httpOnly: c.isHttpOnly ?? false,
        sameSite: null,
        priority: CookiePriority.medium,
        partitioned: false,
        session: c.expiresDate == null,
        created: DateTime.now(),
        lastAccessed: DateTime.now(),
      );
    });

    setCookies(converted);
  }

  Future<void> applyCookiesToWebView(
    webview.InAppWebViewController? controller,
  ) async {
    final manager = webview.CookieManager.instance();

    final cookies = allCookies;

    for (final cookie in cookies) {
      if (cookie.isExpired) {
        continue;
      }

      final scheme = cookie.secure ? "https" : "http";

      await manager.setCookie(
        url: webview.WebUri("$scheme://${cookie.domain}"),
        name: cookie.name,
        value: cookie.value,
        domain: ".${cookie.domain}",
        path: cookie.path,
        expiresDate: cookie.session
            ? null
            : cookie.expires?.millisecondsSinceEpoch,
        isSecure: cookie.secure,
        isHttpOnly: cookie.httpOnly,
        webViewController: controller,
      );
    }
  }

  void clearExpired() {
    final persistent = _loadAll();

    persistent.removeWhere((_, cookie) => cookie.isExpired);

    _sessionCookies.removeWhere((_, cookie) => cookie.isExpired);

    _saveAll(persistent);
  }

  void clearSessionCookies() {
    _sessionCookies.clear();
  }

  void clearPersistentCookies() {
    _cache?.clear();

    KvHelper.set<String>(_storageKey, "{}");
  }

  List<StoredCookie> getCookiesForDomain(String domain) {
    domain = normalizeDomain(domain);

    return _allCookies.where((cookie) {
      return domainMatches(domain, cookie.domain, cookie.hostOnly);
    }).toList();
  }

  bool hasCookie(String domain, String name) {
    domain = normalizeDomain(domain);

    return _allCookies.any(
      (cookie) =>
          cookie.name == name &&
          domainMatches(domain, cookie.domain, cookie.hostOnly),
    );
  }

  StoredCookie? getCookie(String domain, String name) {
    domain = normalizeDomain(domain);

    try {
      return _allCookies.firstWhere(
        (cookie) =>
            cookie.name == name &&
            domainMatches(domain, cookie.domain, cookie.hostOnly),
      );
    } catch (_) {
      return null;
    }
  }

  void deleteCookie(String domain, String name, {String path = "/"}) {
    domain = normalizeDomain(domain);

    final persistent = _loadAll();

    final id = "$domain|$path|$name";

    persistent.remove(id);
    _sessionCookies.remove(id);

    _saveAll(persistent);
  }

  Future<void> deleteAll() async {
    _cache = {};
    _sessionCookies.clear();

    KvHelper.set<String>(_storageKey, "{}");

    await webview.CookieManager.instance().deleteAllCookies();
  }
}

enum CookieSameSite { none, lax, strict }

enum CookiePriority { low, medium, high }

class StoredCookie {
  final String name;
  final String value;

  final String domain;
  final bool hostOnly;

  final String path;

  final DateTime? expires;

  final bool secure;
  final bool httpOnly;

  final CookieSameSite? sameSite;
  final CookiePriority priority;
  final bool partitioned;

  final bool session;

  final DateTime created;

  final DateTime lastAccessed;

  const StoredCookie({
    required this.name,
    required this.value,
    required this.domain,
    required this.hostOnly,
    required this.path,
    required this.created,
    required this.lastAccessed,
    this.expires,
    this.secure = false,
    this.httpOnly = false,
    this.sameSite,
    this.priority = CookiePriority.medium,
    this.partitioned = false,
    this.session = false,
  });

  bool get isExpired {
    if (expires == null) return false;
    return !expires!.isAfter(DateTime.now());
  }

  String get id => "$domain|$path|$name";

  StoredCookie touch() => copyWith(lastAccessed: DateTime.now());

  Map<String, dynamic> toJson() => {
    "name": name,
    "value": value,
    "domain": domain,
    "hostOnly": hostOnly,
    "path": path,
    "expires": expires?.toUtc().toIso8601String(),
    "secure": secure,
    "httpOnly": httpOnly,
    "sameSite": sameSite?.name,
    "priority": priority.name,
    "partitioned": partitioned,
    "session": session,
    "created": created.toUtc().toIso8601String(),
    "lastAccessed": lastAccessed.toUtc().toIso8601String(),
  };

  factory StoredCookie.fromJson(Map<String, dynamic> json) {
    return StoredCookie(
      name: json["name"],
      value: json["value"],
      domain: json["domain"],
      hostOnly: json["hostOnly"] ?? false,
      path: json["path"] ?? "/",
      expires: json["expires"] == null
          ? null
          : DateTime.tryParse(json["expires"])?.toUtc(),
      secure: json["secure"] ?? false,
      httpOnly: json["httpOnly"] ?? false,
      sameSite: json["sameSite"] == null
          ? null
          : CookieSameSite.values.firstWhere(
              (e) => e.name == json["sameSite"],
              orElse: () => CookieSameSite.lax,
            ),
      priority: CookiePriority.values.firstWhere(
        (e) => e.name == json["priority"],
        orElse: () => CookiePriority.medium,
      ),
      partitioned: json["partitioned"] ?? false,
      session: json["session"] ?? false,
      created: json["created"] == null
          ? DateTime.now()
          : DateTime.parse(json["created"]).toUtc(),
      lastAccessed: json["lastAccessed"] == null
          ? DateTime.now()
          : DateTime.parse(json["lastAccessed"]).toUtc(),
    );
  }

  StoredCookie copyWith({
    String? name,
    String? value,
    String? domain,
    bool? hostOnly,
    String? path,
    DateTime? expires,
    bool? secure,
    bool? httpOnly,
    CookieSameSite? sameSite,
    CookiePriority? priority,
    bool? partitioned,
    bool? session,
    DateTime? created,
    DateTime? lastAccessed,
  }) {
    return StoredCookie(
      name: name ?? this.name,
      value: value ?? this.value,
      domain: domain ?? this.domain,
      hostOnly: hostOnly ?? this.hostOnly,
      path: path ?? this.path,
      expires: expires ?? this.expires,
      secure: secure ?? this.secure,
      httpOnly: httpOnly ?? this.httpOnly,
      sameSite: sameSite ?? this.sameSite,
      priority: priority ?? this.priority,
      partitioned: partitioned ?? this.partitioned,
      session: session ?? this.session,
      created: created ?? this.created,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }
}

String normalizeDomain(String domain) {
  return domain.trim().toLowerCase().replaceFirst(RegExp(r'^\.'), '');
}

bool domainMatches(String host, String cookieDomain, bool hostOnly) {
  host = normalizeDomain(host);
  cookieDomain = normalizeDomain(cookieDomain);

  if (hostOnly) {
    return host == cookieDomain;
  }

  return host == cookieDomain || host.endsWith(".$cookieDomain");
}

bool pathMatches(String requestPath, String cookiePath) {
  if (requestPath == cookiePath) {
    return true;
  }

  if (!requestPath.startsWith(cookiePath)) {
    return false;
  }

  if (cookiePath.endsWith("/")) {
    return true;
  }

  return requestPath.length > cookiePath.length &&
      requestPath[cookiePath.length] == "/";
}

String defaultCookiePath(Uri uri) {
  final path = uri.path;

  if (path.isEmpty || !path.startsWith("/")) {
    return "/";
  }

  final index = path.lastIndexOf("/");

  if (index <= 0) {
    return "/";
  }

  return path.substring(0, index);
}

bool isDomainAllowed(String requestHost, String cookieDomain) {
  requestHost = normalizeDomain(requestHost);
  cookieDomain = normalizeDomain(cookieDomain);

  return requestHost == cookieDomain || requestHost.endsWith(".$cookieDomain");
}
