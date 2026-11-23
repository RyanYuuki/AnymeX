import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Some app languages (e.g. Hausa, Sanskrit, Somali) have no Material or
/// Cupertino translations in flutter_localizations. Without a delegate for
/// them, Material widgets throw "No MaterialLocalizations found". These serve
/// the English framework strings for exactly those languages.
class EnglishMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const EnglishMaterialDelegate();

  @override
  bool isSupported(Locale locale) =>
      !GlobalMaterialLocalizations.delegate.isSupported(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(EnglishMaterialDelegate old) => false;
}

class EnglishCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const EnglishCupertinoDelegate();

  @override
  bool isSupported(Locale locale) =>
      !GlobalCupertinoLocalizations.delegate.isSupported(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(EnglishCupertinoDelegate old) => false;
}
