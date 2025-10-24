import 'package:otzaria/utils/word_dictionary.dart';

/// מעבד טקסט והוסף קישורים אוטומטיים למילים במילון
class AutoLinkProcessor {
  static AutoLinkProcessor? _instance;
  static AutoLinkProcessor get instance => _instance ??= AutoLinkProcessor._();
  
  AutoLinkProcessor._();
  
  bool _initialized = false;
  
  /// מאתחל את המעבד
  Future<void> initialize() async {
    if (_initialized) return;
    
    await WordDictionary.instance.loadDictionary();
    _initialized = true;
  }
  
  /// מעבד טקסט HTML ומוסיף קישורים אוטומטיים למילים במילון
  String processText(
    String htmlText, {
    bool enableAutoLinks = true,
    bool excludeExistingLinks = true,
  }) {
    if (!enableAutoLinks || !_initialized) {
      return htmlText;
    }
    
    // אם הטקסט כבר מכיל קישורים ואנחנו רוצים לא לגעת בהם
    if (excludeExistingLinks && htmlText.contains('<a ')) {
      return _processTextWithExistingLinks(htmlText);
    }
    
    return _processTextSimple(htmlText);
  }
  
  /// מעבד טקסט פשוט ללא קישורים קיימים
  String _processTextSimple(String htmlText) {
    String result = htmlText;
    final dictionary = WordDictionary.instance.getAllWords();
    
    // עובר על כל המילים במילון
    dictionary.forEach((word, link) {
      // בונה ביטוי רגולרי בהתאם להגדרות
      String pattern;
      if (link.wholeWordOnly) {
        // התאמה למילה שלמה בלבד
        pattern = '\\b$word\\b';
      } else {
        // התאמה חלקית
        pattern = word;
      }
      
      final regex = RegExp(
        pattern,
        caseSensitive: link.caseSensitive,
        unicode: true,
      );
      
      // מחליף את המילה בקישור
      result = result.replaceAllMapped(regex, (match) {
        final matchedText = match.group(0)!;
        final url = link.createUrl();
        return '<a href="$url" class="auto-link">$matchedText</a>';
      });
    });
    
    return result;
  }
  
  /// מעבד טקסט עם קישורים קיימים (לא נוגע בתוכן של תגי <a>)
  String _processTextWithExistingLinks(String htmlText) {
    final buffer = StringBuffer();
    int lastIndex = 0;
    
    // מוצא את כל תגי ה-<a>
    final linkPattern = RegExp(r'<a\s[^>]*>.*?</a>', dotAll: true);
    final matches = linkPattern.allMatches(htmlText);
    
    for (final match in matches) {
      // מעבד את הטקסט לפני הקישור
      final textBefore = htmlText.substring(lastIndex, match.start);
      buffer.write(_processTextSimple(textBefore));
      
      // מוסיף את הקישור הקיים כמו שהוא
      buffer.write(match.group(0));
      
      lastIndex = match.end;
    }
    
    // מעבד את הטקסט אחרי הקישור האחרון
    if (lastIndex < htmlText.length) {
      final textAfter = htmlText.substring(lastIndex);
      buffer.write(_processTextSimple(textAfter));
    }
    
    return buffer.toString();
  }
}
