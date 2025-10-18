import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saadibus/providers/languageProvider.dart';
import 'package:saadibus/utils/globals.dart';

class LoginScreenProvider extends ChangeNotifier {
  String lang = currentLanguage;

  BuildContext? _context;
  void updateContext(BuildContext context) {
    _context = context;
    notifyListeners();
  }

  String get language {
    try {
      if (_context == null) return currentLanguage;
      return Provider.of<LanguageProvider>(_context!, listen: true).language;
    } catch (e) {
      return currentLanguage;
    }
  }

}
