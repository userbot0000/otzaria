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
    print('AutoLinkProcessor.processText called: enableAutoLinks=$enableAutoLinks, initialized=$_initialized');
    
    if (!enableAutoLinks) {
      print('AutoLinkProcessor: Auto links disabled');
      return htmlText;
    }
    
    // אם לא מאותחל, לא נעשה כלום
    if (!_initialized) {
      print('AutoLinkProcessor: Not initialized!');
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
      print('AutoLinkProcessor: Processing text, tractates count: ${tractates.length}');
      if (tractates.isEmpty) {
        print('AutoLinkProcessor: No tractates found!');
        return htmlText;
      }
      
      // בניית regex לזיהוי כל הפורמטים
      final tractatePattern = tractates.map((t) => RegExp.escape(t)).join('|');
      
      // דפוס פשוט יותר - מחפש מסכת + מספר דף
      // תומך בפורמטים: "ברכות ב", "בברכות דף ב", "ברכות ב א", "ברכות ב."
      final pattern = RegExp(
        '(?:[בדו]?ב)?\\s*' +  // תחילית אופציונלית
        '(' + tractatePattern + ')' +  // שם המסכת (קבוצה 1)
        '(?![א-ת])' +  // ודא שזו מילה שלמה
        '\\s+' +  // רווח חובה
        '(?:(דף)\\s+)?' +  // "דף" אופציונלי (קבוצה 2)
        '([א-ת]{1,3}(?:["\']\\s*[א-ת])?)' +  // מספר דף (קבוצה 3)
        '(?:\\s+([א-ב]|ע["\']\\s*[אב]))?' +  // עמוד אופציונלי (קבוצה 4)
        '(?=\\s|\\.|,|:|;|\\)|\\]|<|\$)',  // סוף - רווח או סימן פיסוק או תג HTML
        unicode: true,
        multiLine: true,
      );
      
      String result = htmlText;
      int matchCount = 0;
      result = result.replaceAllMapped(pattern, (match) {
        matchCount++;
        print('AutoLinkProcessor: Found match #$matchCount: ${match.group(0)}');
        
        // בדיקה שזה לא בתוך קישור קיים
        final beforeMatch = result.substring(0, match.start);
        if (beforeMatch.contains('<a ') && 
            beforeMatch.lastIndexOf('<a ') > beforeMatch.lastIndexOf('</a>')) {
          print('AutoLinkProcessor: Skipping - inside existing link');
          return match.group(0)!;
        }
        
        final fullMatch = match.group(0)!;
        final tractate = match.group(1)!;
        final hasDafWord = match.group(2) != null;
        String pageNum = match.group(3)!;
        final sideStr = match.group(4);
        
        print('AutoLinkProcessor: Tractate=$tractate, Page=$pageNum, Side=$sideStr');
        
        // ניקוי גרשיים ורווחים ממספר הדף
        pageNum = _cleanPageNumber(pageNum);
        
        // בדיקה שמספר הדף תקין
        if (!_isValidPageNumber(pageNum)) {
          print('AutoLinkProcessor: Invalid page number: $pageNum');
          return fullMatch;
        }
        
        // קביעת העמוד - ניקוי גרשיים וזיהוי ע"א/ע"ב
        String? side;
        if (sideStr != null) {
          final cleanSide = sideStr.replaceAll(RegExp("[\"'\\s]"), '');
          if (cleanSide == 'עא') {
            side = 'א';
          } else if (cleanSide == 'עב') {
            side = 'ב';
          } else if (sideStr == 'א' || sideStr == 'ב') {
            side = sideStr;
          }
        }
        
        // בניית URL עם "דף" - תמיד נשתמש רק במספר הדף ללא עמוד
        // כך שאם העמוד לא נכון, עדיין נפתח את הדף הנכון
        String url = 'book://$tractate#דף $pageNum';
        
        // החזרת הטקסט המקורי עם קישור
        final linkText = fullMatch.trim();
        final linkedText = '<a href="$url" class="talmud-ref">$linkText</a>';
        print('AutoLinkProcessor: Created link: $linkedText');
        return linkedText;
      });
      
      print('AutoLinkProcessor: Total matches found: $matchCount');
      return result;
    } catch (e) {
      print('Error in _processTalmudReferences: $e');
      return htmlText;
    }
  }
  
  /// מנקה מספר דף מגרשיים ורווחים (כ"ג -> כג)
  String _cleanPageNumber(String pageNum) {
    return pageNum.replaceAll(RegExp("[\"'\\s]"), '');
  }
  
  /// בודק אם מחרוזת היא מספר דף תקין
  bool _isValidPageNumber(String pageNum) {
    // קבלת רשימת מספרי הדפים התקינים מהמילון
    final validPages = WordDictionary.instance.getValidPageNumbers();
    
    // בדיקה אם זה מספר עברי תקין
    if (validPages.contains(pageNum)) {
      return true;
    }
    
    // בדיקה אם זה מספר ערבי (1-120 בערך)
    final numPattern = RegExp(r'^[0-9]+$');
    if (numPattern.hasMatch(pageNum)) {
      final num = int.tryParse(pageNum);
      return num != null && num >= 1 && num <= 120;
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
}