

import 'package:flutter/material.dart';
import 'package:saadibus/api/shared_preferences.dart';
import 'package:saadibus/utils/globals.dart';
import 'package:saadibus/utils/keywords.dart';

class LanguageProvider extends ChangeNotifier {
  String _language = currentLanguage;
  String get language => _language;
  String get languageText {
    return applicationText[_language]!["language"]!;
  }

  void setAppLanguage(String lang) async {
    setLanguage(lang);
    debugPrint("Setting language to: $lang");
    _language = currentLanguage;
    await MySharedPrefs.setValue("lang", lang);
    debugPrint("Language set to: $_language");
    notifyListeners();
  }
}