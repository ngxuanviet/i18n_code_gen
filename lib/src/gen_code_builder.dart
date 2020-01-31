import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:build/build.dart';

class GenCodeBuilder implements Builder {

  @override
  Map<String, List<String>> get buildExtensions => {
    '.json': ['.dart']
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var inputId = buildStep.inputId;
    var contents = await buildStep.readAsString(inputId);
    Map<String, dynamic> data = jsonDecode(contents);

    //build string class
    String content;
    for (var key in data.keys) {
      content = content == null ? _genKey(key, data[key].toString()) : content + _genKey(key, data[key].toString());
    }

    var defaultLang = data['isDefault'] ?? false;
    var currentLangCode = inputId.pathSegments[inputId.pathSegments.length - 1].replaceAll('.json', '');

    if (defaultLang) {
      var languages = _listLanguageFromDir('lib/langs');
      await Directory('lib/langs/gen').create(recursive: false);
      await _createFile('lib/langs/gen/strings.dart', _genDefaultStrings(inputId.package, currentLangCode, languages, content));
    }

    await buildStep.writeAsString(inputId.changeExtension('.dart'), _genContentStrings(inputId.package, currentLangCode, defaultLang ? '' : content));
  }

  List<String> _listLanguageFromDir(String path) {
    var languages = <String>[];
    var dir = Directory(path);
    List contents = dir.listSync();
    for (var fileOrDir in contents) {
      if (fileOrDir is File) {
        var fileName = getFileName(fileOrDir.path);
        print('file: ' + fileOrDir.path);
        if (fileName.contains('.json')) {
          languages.add(fileName.replaceFirst('.json', ''));
        }
      }
    }
    return languages;
  }

  void _createFile(String fileName, String content) {
    File(fileName).writeAsString(content)
        .then((File file) {
      // Stuff to do after file has been created...
    });
  }

  String _genKey(String key, String value) {
    return '''
  String get $key => "$value";
''';
  }

  String _genDefaultStrings(String package, String defaultLanguage, List<String> languages, String content) {
    var import = '';
    var supportedLocales = '';
    var loadInfo = '';
    for(var fileName in languages) {
      //build import
      import = import + '''
import 'package:$package/langs/$fileName.dart';
''';
      //build supportedLocales
      supportedLocales = supportedLocales + '''
      Locale("$fileName", ""),
''';
      // build loadInfo
      var capName = capitalize(fileName);
      loadInfo = loadInfo + '''
        case "$fileName":
          Strings.current = const $capName();
          return SynchronousFuture<Strings>(Strings.current);
''';
    }
    return '''
// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
$import

// ignore_for_file: non_constant_identifier_names
class Strings implements WidgetsLocalizations {

$content

  const Strings();

  static Strings current;

  static const GeneratedLocalizationsDelegate delegate = GeneratedLocalizationsDelegate();

  static Strings of(BuildContext context) => Localizations.of<Strings>(context, Strings);

  @override
  TextDirection get textDirection => TextDirection.ltr;
  
  static Locale localeResolutionCallback(Locale locale, Iterable<Locale> supported) {
    Locale target = _findSupported(locale);
    return target != null ? target : Locale("$defaultLanguage", "");
  }

  static Locale _findSupported(Locale locale) {
    if (locale != null) {
      for (Locale supportedLocale in delegate.supportedLocales) {
        if (locale.languageCode == supportedLocale.languageCode)
          return supportedLocale;
      }
    }
    return null;
  }
}

class GeneratedLocalizationsDelegate extends LocalizationsDelegate<Strings> {
  const GeneratedLocalizationsDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
$supportedLocales
    ];
  }

  LocaleListResolutionCallback listResolution({Locale fallback, bool withCountry = true}) {
    return (List<Locale> locales, Iterable<Locale> supported) {
      if (locales == null || locales.isEmpty) {
        return fallback ?? supported.first;
      } else {
        return _resolve(locales.first, fallback, supported, withCountry);
      }
    };
  }

  LocaleResolutionCallback resolution({Locale fallback, bool withCountry = true}) {
    return (Locale locale, Iterable<Locale> supported) {
      return _resolve(locale, fallback, supported, withCountry);
    };
  }

  @override
  Future<Strings> load(Locale locale) {
    final String lang = getLang(locale);
    if (lang != null) {
      switch (lang) {
$loadInfo
      }
    }
    Strings.current = const Strings();
    return SynchronousFuture<Strings>(Strings.current);
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale, true);

  @override
  bool shouldReload(GeneratedLocalizationsDelegate old) => false;

  ///
  /// Internal method to resolve a locale from a list of locales.
  ///
  Locale _resolve(Locale locale, Locale fallback, Iterable<Locale> supported, bool withCountry) {
    if (locale == null || !_isSupported(locale, withCountry)) {
      return fallback ?? supported.first;
    }

    final Locale languageLocale = Locale(locale.languageCode, "");
    if (supported.contains(locale)) {
      return locale;
    } else if (supported.contains(languageLocale)) {
      return languageLocale;
    } else {
      final Locale fallbackLocale = fallback ?? supported.first;
      return fallbackLocale;
    }
  }

  ///
  /// Returns true if the specified locale is supported, false otherwise.
  ///
  bool _isSupported(Locale locale, bool withCountry) {
    if (locale != null) {
      for (Locale supportedLocale in supportedLocales) {
        // Language must always match both locales.
        if (supportedLocale.languageCode != locale.languageCode) {
          continue;
        }

        // If country code matches, return this locale.
        if (supportedLocale.countryCode == locale.countryCode) {
          return true;
        }

        // If no country requirement is requested, check if this locale has no country.
        if (true != withCountry && (supportedLocale.countryCode == null || supportedLocale.countryCode.isEmpty)) {
          return true;
        }
      }
    }
    return false;
  }
}

String getLang(Locale l) => l == null
    ? null
    : l.countryCode != null && l.countryCode.isEmpty
    ? l.languageCode
    : l.toString();
''';
  }

  String _genContentStrings(String package, String langCode, String content) {
    var className = capitalize(langCode);
    return '''
import 'package:$package/langs/gen/strings.dart';

// ignore_for_file: non_constant_identifier_names
class $className extends Strings {
  const $className();
$content
}''';
  }
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

String getFileName(String path) {
  return path?.split('/')?.last?.split('\\')?.last;
}