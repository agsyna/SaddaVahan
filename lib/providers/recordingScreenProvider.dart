import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saadibus/providers/languageProvider.dart';
import 'package:saadibus/utils/globals.dart';
import 'package:saadibus/utils/keywords.dart';

class RecordingScreenProvider extends ChangeNotifier {
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
  
  String get listeningText{
    final lang = language;
    return applicationText[lang]?['listening'] ?? applicationText['eng']!['listening']!;
  }

  String get listeningHintText{
    final lang = language;
    return applicationText[lang]?['listeningHint'] ?? applicationText['eng']!['listeningHint']!;
  }
  String get tapToStopText{
    final lang = language;
    return applicationText[lang]?['tapToStop'] ?? applicationText['eng']!['tapToStop']!;
  }
  String get processingText{
    final lang = language;
    return applicationText[lang]?['processing'] ?? applicationText['eng']!['processing']!;
  }
  String get understandingText{
    final lang = language;
    return applicationText[lang]?['understanding'] ?? applicationText['eng']!['understanding']!;
  }
  String get signInButtonText{
    final lang = language;
    return applicationText[lang]?['signInButtonText'] ?? applicationText['eng']!['signInButtonText']!;
  }
  String get appTitle{
    final lang = language;
    return applicationText[lang]?['appTitle'] ?? applicationText['eng']!['appTitle']!;
  }
  String get goingHint{
    final lang = language;
    return applicationText[lang]?['goingHint'] ?? applicationText['eng']!['goingHint']!;
  }
  String get departure{
    final lang = language;
    return applicationText[lang]?['departure'] ?? applicationText['eng']!['departure']!;
  }
  String get goToHomeButtonText{
    final lang = language;
    return applicationText[lang]?['goToHomeButtonText'] ?? applicationText['eng']!['goToHomeButtonText']!;
  }

  String get recordingSuccessText{
    final lang = language;
    return applicationText[lang]?['recordingSuccess'] ?? applicationText['eng']!['recordingSuccess']!;
  }
  String get recordingFailedText{
    final lang = language;
    return applicationText[lang]?['recordingFailed'] ?? applicationText['eng']!['recordingFailed']!;
  }

  String get recordingCompleteText{
    final lang = language;
    return applicationText[lang]?['recordingComplete'] ?? applicationText['eng']!['recordingComplete']!;
  }

}
