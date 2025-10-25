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
    
    // קודם כל, נזהה הפניות תלמודיות (מסכת+דף+עמוד)
    String result = _processTalmudReferences(htmlText, excludeExistingLinks);
    
    return result;
  }
  
  /// מזהה ומקשר הפניות תלמודיות בפורמטים שונים
  String _processTalmudReferences(String htmlText, bool excludeExistingLinks) {
    try {
      // אם הטקסט כבר מכיל קישורים, נפצל ונעבד רק חלקים ללא קישורים
      if (excludeExistingLinks && htmlText.contains('<a ')) {
        return _processTalmudWithExistingLinks(htmlText);
      }
      
      final tractates = WordDictionary.instance.getTractates();
      if (tractates.isEmpty) return htmlText;
      
      // בניית regex לזיהוי כל הפורמטים
      final tractatePattern = tractates.map((t) => RegExp.escape(t)).join('|');
      
      // דפוס מורכב שמזהה את כל הפורמטים:
      // 1. (ברכות ב, ב) - עם סוגריים ופסיק
      // 2. ברכות דף ב ע"א - עם "דף" ועמוד
      // 3. ברכות ט"ז ע"ב - עם גרשיים במספר ועמוד
      // 4. ברכות דף ג. או ברכות דף ה: - עם נקודה/נקודתיים
      final pattern = RegExp(
        r'\(?\s*(' + tractatePattern + r')\s+'  // שם המסכת
        r'(?:(דף)\s+)?'  // "דף" אופציונלי
        r'([א-ת]{1,2}"?[א-ת]{0,2}|[0-9]{1,3})'  // מספר דף: עברי (עם או בלי גרשיים) או ערבי
        r'(?:\s*[,:;]\s*|\s+)'  // מפריד (פסיק, נקודתיים, או רווח)
        r'(?:'  // התחלת קבוצת עמוד אופציונלית
          r'([א-ת](?:"[א-ת])?)|'  // עמוד עברי (א, ב, ע"א, ע"ב)
          r'(ע"[אב])|'  // ע"א או ע"ב
          r'([\.:])'  // נקודה או נקודתיים
        r')?'  // סוף קבוצת עמוד אופציונלית
        r'\)?',  // סוגר אופציונלי
        unicode: true,
        multiLine: true,
      );
      
      String result = htmlText;
      result = result.replaceAllMapped(pattern, (match) {
        // בדיקה שזה לא בתוך קישור קיים
        final beforeMatch = result.substring(0, match.start);
        if (beforeMatch.contains('<a ') && 
            beforeMatch.lastIndexOf('<a ') > beforeMatch.lastIndexOf('</a>')) {
          return match.group(0)!;
        }
        
        final tractate = match.group(1)!;
        final hasDafWord = match.group(2) != null;  // האם יש המילה "דף"
        final pageNum = match.group(3)!;
        final sideHebrew = match.group(4);  // א, ב, או עם גרשיים
        final sideWithQuotes = match.group(5);  // ע"א, ע"ב
        final punctuation = match.group(6);  // . או :
        
        // קביעת העמוד
        String? side;
        if (sideWithQuotes != null) {
          side = sideWithQuotes == 'ע"א' ? 'א' : 'ב';
        } else if (sideHebrew != null) {
          // הסרת גרשיים אם יש
          side = sideHebrew.replaceAll('"', '').replaceAll("'", '');
        } else if (punctuation == '.') {
          side = 'א';
        } else if (punctuation == ':') {
          side = 'ב';
        }
        
        // אם אין עמוד מפורש, נדרוש שתהיה המילה "דף"
        if (side == null && !hasDafWord) {
          // ייתכן שזה לא הפניה תלמודית (למשל: "ברכות בזמן")
          // נבדוק אם מה שאחרי זה נראה כמו מספר
          if (!_isValidPageNumber(pageNum)) {
            return match.group(0)!;
          }
        }
        
        // בניית ה-URL
        final cleanPageNum = pageNum.replaceAll('"', '').replaceAll("'", '');
        String url;
        if (side != null) {
          url = 'book://$tractate#$cleanPageNum $side';
        } else {
          url = 'book://$tractate#$cleanPageNum';
        }
        
        final originalText = match.group(0)!;
        return '<a href="$url" class="talmud-ref">$originalText</a>';
      });
      
      return result;
    } catch (e) {
      print('Error in _processTalmudReferences: $e');
      return htmlText;
    }
  }
  
  /// בודק אם מחרוזת היא מספר דף תקין
  bool _isValidPageNumber(String pageNum) {
    // בדיקה אם זה מספר עברי (אותיות עבריות)
    if (RegExp(r'^[א-ת]+$', unicode: true).hasMatch(pageNum)) {
      return true;
    }
    // בדיקה אם זה מספר ערבי
    if (RegExp(r'^[0-9]+$').hasMatch(pageNum)) {
      return true;
    }
    return false;
  }
  
  /// מעבד טקסט עם קישורים קיימים - לא נוגע בתוכן של תגי <a>
  String _processTalmudWithExistingLinks(String htmlText) {
    final buffer = StringBuffer();
    int lastIndex = 0;
    
    // מוצא את כל תגי ה-<a>
    final linkPattern = RegExp(r'<a\s[^>]*>.*?</a>', dotAll: true);
    final matches = linkPattern.allMatches(htmlText);
    
    for (final match in matches) {
      // מעבד את הטקסט לפני הקישור
      final textBefore = htmlText.substring(lastIndex, match.start);
      buffer.write(_processTalmudReferences(textBefore, false));
      
      // מוסיף את הקישור הקיים כמו שהוא
      buffer.write(match.group(0));
      
      lastIndex = match.end;
    }
    
    // מעבד את הטקסט אחרי הקישור האחרון
    if (lastIndex < htmlText.length) {
      final textAfter = htmlText.substring(lastIndex);
      buffer.write(_processTalmudReferences(textAfter, false));
    }
    
    return buffer.toString();
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
