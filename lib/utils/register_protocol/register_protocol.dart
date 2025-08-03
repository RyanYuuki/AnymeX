import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

/// Registers a protocol by [scheme] to allow for links in the form `<scheme>://...`

/// to be processed by this application. By default, opening a link will open

/// the executable that was used to register the scheme with the URL as the first

/// argument passed to the executable.

///

/// If a protocol is already registered for the given scheme, this function will

/// attempt to overwrite the previous handler with the current executable information.

/// However, note that depending on process permissions, this operation may be

/// disallowed by the underlying platform.

///

/// You may pass an [executable] to override the path to the executable to run

/// when accessing the URL.

///

/// [arguments] is a list of arguments to be used when running the executable.

/// If passed, the list must contain at least one element, and at least one of

/// those elements must contain the literal value `%s` to denote the URL to open.

/// Quoting arguments is not necessary, as this will be handled for you.

/// Escaping the `%s` as an unprocessed literal is currently unsupported.

void registerProtocolHandler(
  String scheme, {
  String? executable,
  List<String>? arguments,
}) {
  WindowsProtocolHandler().register(
    scheme,
    executable: executable,
    arguments: arguments,
  );
}

/// Unregisters the protocol handler with the underlying platform. The provided

/// [scheme] will no longer be used in links.

///

/// Note that this will unregister a protocol by scheme regardless of which process

/// had registered it. Unregistering a scheme that was not registered by this

/// application is undefined and depends on platform-specific restrictions.

void unregisterProtocolHandler(String scheme) {
  WindowsProtocolHandler().unregister(scheme);
}

const _hive = HKEY_CURRENT_USER;

class WindowsProtocolHandler extends ProtocolHandler {
  @override
  void register(String scheme, {String? executable, List<String>? arguments}) {
    if (defaultTargetPlatform != TargetPlatform.windows) return;

    final prefix = _regPrefix(scheme);

    final capitalized = scheme[0].toUpperCase() + scheme.substring(1);

    final args = getArguments(arguments).map((a) => _sanitize(a));

    final cmd =
        '${executable ?? Platform.resolvedExecutable} ${args.join(' ')}';

    _regCreateStringKey(_hive, prefix, '', 'URL:$capitalized');

    _regCreateStringKey(_hive, prefix, 'URL Protocol', '');

    _regCreateStringKey(_hive, '$prefix\\shell\\open\\command', '', cmd);
  }

  @override
  void unregister(String scheme) {
    if (defaultTargetPlatform != TargetPlatform.windows) return;

    final txtKey = TEXT(_regPrefix(scheme));

    try {
      RegDeleteTree(HKEY_CURRENT_USER, txtKey);
    } finally {
      free(txtKey);
    }
  }

  String _regPrefix(String scheme) => 'SOFTWARE\\Classes\\$scheme';

  int _regCreateStringKey(int hKey, String key, String valueName, String data) {
    final txtKey = TEXT(key);

    final txtValue = TEXT(valueName);

    final txtData = TEXT(data);

    try {
      return RegSetKeyValue(
        hKey,
        txtKey,
        txtValue,
        REG_SZ,
        txtData,
        txtData.length * 2 + 2,
      );
    } finally {
      free(txtKey);

      free(txtValue);

      free(txtData);
    }
  }

  String _sanitize(String value) {
    value = value.replaceAll(r'%s', '%1').replaceAll(r'"', '\\"');

    return '"$value"';
  }
}

abstract class ProtocolHandler {
  void register(String scheme, {String? executable, List<String>? arguments});

  void unregister(String scheme);

  List<String> getArguments(List<String>? arguments) {
    if (arguments == null) return ['%s'];

    if (arguments.isEmpty && !arguments.any((e) => e.contains('%s'))) {
      throw ArgumentError('arguments must contain at least 1 instance of "%s"');
    }

    return arguments;
  }
}
