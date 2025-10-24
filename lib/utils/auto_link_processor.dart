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
    
    print('AutoLinkProcessor: Starting initialization...');
    await WordDictionary.instance.loadDictionary();
    final wordCount = WordDictionary.instance.getAllWords().length;
    print('AutoLinkProcessor: Initialized with $wordCount words');
    _initialized = true;
  }
  
  /// מעבד טקסט HTML ומוסיף קישורים אוטומטיים למילים במילון
  String processText(
    String htmlText, {
    bool enableAutoLinks = true,
    bool excludeExistingLinks = true,
  }) {
    if (!enableAutoLinks) {
      return htmlText;
    }
    
    // אם לא מאותחל, לא נעשה כלום
    if (!_initialized) {
      return htmlText;
    }
    
    // בדיקה שיש מילים במילון
    final dictionary = WordDictionary.instance.getAllWords();
    if (dictionary.isEmpty) {
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
    try {
      String result = htmlText;
      final dictionary = WordDictionary.instance.getAllWords();
      
      // ממיין את המילים לפי אורך (הארוכות ביותר קודם) כדי למנוע התנגשויות
      final sortedWords = dictionary.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      
      // עובר על כל המילים במילון
      for (final word in sortedWords) {
        final link = dictionary[word]!;
        
        // escape תווים מיוחדים ב-regex
        final escapedWord = RegExp.escape(word);
        
        // בונה ביטוי רגולרי פשוט יותר
        String pattern;
        if (link.wholeWordOnly) {
          // התאמה למילה שלמה - מוקפת ברווחים, סימני פיסוק או תחילת/סוף
          pattern = '(^|[\\s>])($escapedWord)([\\s<,.;:!?"\']|\$)';
        } else {
          // התאמה חלקית
          pattern = escapedWord;
        }
        
        try {
          final regex = RegExp(
            pattern,
            caseSensitive: link.caseSensitive,
            unicode: true,
            multiLine: true,
          );
          
          // מחליף את המילה בקישור
          result = result.replaceAllMapped(regex, (match) {
            if (link.wholeWordOnly) {
              // יש לנו 3 קבוצות: prefix, word, suffix
              final prefix = match.group(1) ?? '';
              final matchedText = match.group(2) ?? word;
              final suffix = match.group(3) ?? '';
              
              // בודק שהמילה לא כבר בתוך קישור
              final beforeMatch = result.substring(0, match.start);
              if (beforeMatch.contains('<a ') && 
                  beforeMatch.lastIndexOf('<a ') > beforeMatch.lastIndexOf('</a>')) {
                return match.group(0)!;
              }
              
              final url = link.createUrl();
              return '$prefix<a href="$url" class="auto-link">$matchedText</a>$suffix';
            } else {
              final matchedText = match.group(0)!;
              final url = link.createUrl();
              return '<a href="$url" class="auto-link">$matchedText</a>';
            }
          });
        } catch (e) {
          print('Error processing word "$word": $e');
          continue;
        }
      }
      
      return result;
    } catch (e) {
      print('Error in _processTextSimple: $e');
      return htmlText; // במקרה של שגיאה, מחזיר את הטקסט המקורי
    }
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
