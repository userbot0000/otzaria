import 'package:otzaria/utils/word_dictionary.dart';
import 'package:otzaria/utils/index_mapper.dart';

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
    
    // טעינה מוקדמת של ספרים פופולריים ברקע
    _preloadPopularBooksInBackground();
    
    _initialized = true;
  }
  
  /// טוען ספרים פופולריים ברקע (לא חוסם את האתחול)
  void _preloadPopularBooksInBackground() {
    Future.delayed(Duration(seconds: 1), () async {
      try {
        print('AutoLinkProcessor: Starting background preload...');
        await IndexMapper.instance.preloadPopularBooks();
        final stats = IndexMapper.instance.getCacheStats();
        print('AutoLinkProcessor: Preloaded ${stats['books_cached']} books with ${stats['total_ref_mappings']} mappings');
      } catch (e) {
        print('AutoLinkProcessor: Background preload failed: $e');
      }
    });
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
    
    // זיהוי הפניות לתנ"ך (ספר+פרק+פסוק)
    result = _processTanakhReferences(result, excludeExistingLinks);
    
    // זיהוי הפניות למשנה (מסכת+פרק+משנה)
    result = _processMishnaReferences(result, excludeExistingLinks);
    
    return result;
  }
  
  /// משדרג קישורים קיימים עם אינדקסים מדויקים (אסינכרוני)
  /// 
  /// פונקציה זו לוקחת HTML עם קישורים בפורמט fallback ומשדרגת אותם
  /// לקישורים מקצועיים עם אינדקסים מדויקים
  Future<String> upgradeLinksWithIndices(String htmlText) async {
    try {
      String result = htmlText;
      
      // שדרוג קישורי תלמוד
      result = await _upgradeLinksWithIndicesInternal(
        result, 
        r'<a href="book://([^#]+)#([^"]+)" class="talmud-ref"',
        _upgradeTalmudLink
      );
      
      // שדרוג קישורי תנ"ך
      result = await _upgradeLinksWithIndicesInternal(
        result, 
        r'<a href="book://([^#]+)#([^"]+)" class="tanakh-ref"',
        _upgradeTanakhLink
      );
      
      // שדרוג קישורי משנה
      result = await _upgradeLinksWithIndicesInternal(
        result, 
        r'<a href="book://([^#]+)#([^"]+)" class="mishna-ref"',
        _upgradeMishnaLink
      );
      
      return result;
    } catch (e) {
      return htmlText; // במקרה של שגיאה, נחזיר את הטקסט המקורי
    }
  }
  
  /// פונקציה עזר לשדרוג קישורים
  Future<String> _upgradeLinksWithIndicesInternal(
    String htmlText, 
    String pattern, 
    Future<String?> Function(String bookTitle, String ref) upgradeFunction
  ) async {
    final regex = RegExp(pattern);
    final matches = regex.allMatches(htmlText).toList();
    
    String result = htmlText;
    
    // עיבוד בסדר הפוך כדי לא לפגוע באינדקסים
    for (int i = matches.length - 1; i >= 0; i--) {
      final match = matches[i];
      final bookTitle = match.group(1)!;
      final ref = match.group(2)!;
      
      final upgradedUrl = await upgradeFunction(bookTitle, ref);
      if (upgradedUrl != null) {
        // החלפת ה-URL בקישור
        final oldHref = 'book://$bookTitle#$ref';
        final newHref = upgradedUrl;
        
        result = result.replaceRange(
          match.start, 
          match.end, 
          match.group(0)!.replaceFirst(oldHref, newHref)
        );
      }
    }
    
    return result;
  }
  
  /// משדרג קישור תלמודי עם אינדקס מדויק
  Future<String?> _upgradeTalmudLink(String tractate, String ref) async {
    try {
      final index = await IndexMapper.instance.getIndexFromRef(tractate, ref);
      if (index != null) {
        return 'book://$tractate@$index#$ref';
      }
    } catch (e) {
      // שגיאה - נשאיר את הקישור הישן
    }
    return null;
  }
  
  /// משדרג קישור תנ"ך עם אינדקס מדויק
  Future<String?> _upgradeTanakhLink(String bookName, String ref) async {
    try {
      final index = await IndexMapper.instance.getIndexFromRef(bookName, ref);
      if (index != null) {
        return 'book://$bookName@$index#$ref';
      }
    } catch (e) {
      // שגיאה - נשאיר את הקישור הישן
    }
    return null;
  }
  
  /// משדרג קישור משנה עם אינדקס מדויק
  Future<String?> _upgradeMishnaLink(String tractate, String ref) async {
    try {
      final index = await IndexMapper.instance.getIndexFromRef(tractate, ref);
      if (index != null) {
        return 'book://$tractate@$index#$ref';
      }
    } catch (e) {
      // שגיאה - נשאיר את הקישור הישן
    }
    return null;
  }
  
  /// מזהה ומקשר הפניות תלמודיות בפורמטים שונים
  String _processTalmudReferences(String htmlText, bool excludeExistingLinks) {
    try {
      // אם הטקסט כבר מכיל קישורים תלמודיים (class="talmud-ref"), נפצל ונעבד רק חלקים ללא קישורים
      if (excludeExistingLinks && htmlText.contains('class="talmud-ref"')) {
        return _processTalmudWithExistingLinks(htmlText);
      }
      
      final tractates = WordDictionary.instance.getTractates();
      if (tractates.isEmpty) {
        return htmlText;
      }
      
      // בניית regex לזיהוי כל הפורמטים
      final tractatePattern = tractates.map((t) => RegExp.escape(t)).join('|');
      
      // דפוס מורחב - מחפש מסכת + מספר דף + עמוד אופציונלי
      // תומך בפורמטים: 
      // - "ברכות ב", "בברכות דף ב", "ברכות ב א", "ברכות ב."
      // - "ברכות ב, א" (עם פסיק), "ברכות (ב, א)" (בסוגריים)
      // - "חגיגה (יד,ג)", "ביצה כז, ב"
      final pattern = RegExp(
        '(?:[בדו]?ב)?\\s*' +  // תחילית אופציונלית
        '(' + tractatePattern + ')' +  // שם המסכת (קבוצה 1)
        '(?![א-ת])' +  // ודא שזו מילה שלמה
        '(?:' +  // התחלת קבוצה לא לוכדת עבור כל הפורמטים
          // פורמט עם סוגריים: מסכת (דף, עמוד) או מסכת (דף עמוד) או מסכת (דף)
          '\\s*\\(\\s*' +  // סוגר פותח עם רווחים אופציונליים
          '(?:(דף)\\s+)?' +  // "דף" אופציונלי (קבוצה 2)
          '([א-ת]{1,3}(?:[\"\\x27]\\s*[א-ת])?)' +  // מספר דף (קבוצה 3)
          '(?:(?:,\\s*|\\s+)([א-ב]|ע[\"\\x27]\\s*[אב]))?' +  // עמוד אופציונלי עם פסיק או רווח (קבוצה 4)
          '\\s*\\)' +  // סוגר סוגר
        '|' +  // או
          // פורמט רגיל: מסכת דף, עמוד או מסכת דף עמוד
          '\\s+' +  // רווח חובה
          '(?:(דף)\\s+)?' +  // "דף" אופציונלי (קבוצה 5)
          '([א-ת]{1,3}(?:[\"\\x27]\\s*[א-ת])?)' +  // מספר דף (קבוצה 6)
          '(?:(?:,\\s*|\\s+)([א-ב]|ע[\"\\x27]\\s*[אב]))?' +  // עמוד אופציונלי עם פסיק או רווח (קבוצה 7)
        ')' +
        '(?=\\s|\\.|,|:|;|\\)|\\]|<|\$)',  // סוף - רווח או סימן פיסוק או תג HTML
        unicode: true,
        multiLine: true,
      );
      
      String result = htmlText;
      result = result.replaceAllMapped(pattern, (match) {
        // בדיקה שזה לא בתוך תג HTML או קישור קיים
        final beforeMatch = result.substring(0, match.start);
        if (beforeMatch.contains('<a ') && 
            beforeMatch.lastIndexOf('<a ') > beforeMatch.lastIndexOf('</a>')) {
          return match.group(0)!;
        }
        
        final fullMatch = match.group(0)!;
        final tractate = match.group(1)!;
        
        // זיהוי פורמט: אם קבוצה 6 קיימת = פורמט רגיל, אחרת = פורמט עם סוגריים
        final isParenthesesFormat = match.group(6) == null;
        
        final hasDafWord = isParenthesesFormat ? (match.group(2) != null) : (match.group(5) != null);
        String pageNum = isParenthesesFormat ? match.group(3)! : match.group(6)!;
        final sideStr = isParenthesesFormat ? match.group(4) : match.group(7);
        
        // ניקוי גרשיים ורווחים ממספר הדף
        pageNum = _cleanPageNumber(pageNum);
        
        // בדיקה שמספר הדף תקין
        if (!_isValidPageNumber(pageNum)) {
          return fullMatch;
        }
        
        // קביעת העמוד - ניקוי גרשיים וזיהוי ע"א/ע"ב
        String? side;
        if (sideStr != null) {
          final cleanSide = sideStr.replaceAll(RegExp(r'["\x27\s]'), '');
          if (cleanSide == 'עא') {
            side = 'א';
          } else if (cleanSide == 'עב') {
            side = 'ב';
          } else if (cleanSide == 'א' || cleanSide == 'ב') {
            side = cleanSide;
          }
        }
        
        // בניית URL מקצועי עם fallback לכותרת
        String fallbackRef = 'דף $pageNum';
        if (side != null) {
          if (side == 'א') {
            fallbackRef = 'דף $pageNum.';
          } else if (side == 'ב') {
            fallbackRef = 'דף $pageNum:';
          }
        }
        
        // ניסיון לקבל אינדקס מדויק (אסינכרוני - נעשה בעתיד)
        // לעת עתה נשתמש בפורמט עם fallback
        final url = 'book://$tractate#$fallbackRef';
        
        // החזרת הטקסט המקורי עם קישור
        final linkText = fullMatch.trim();
        return '<a href="$url" class="talmud-ref" data-ref="$fallbackRef">$linkText</a>';
      });
      
      return result;
    } catch (e) {
      return htmlText;
    }
  }
  
  /// מנקה מספר דף מגרשיים ורווחים (כ"ג -> כג)
  String _cleanPageNumber(String pageNum) {
    // מסיר גרשיים ורווחים, אבל שומר על המבנה של מספרים עבריים
    return pageNum.replaceAll(RegExp(r'["\x27\s]'), '');
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

  /// מקבל את האינדקס המדויק של דף תלמודי (מקצועי)
  Future<int?> _getTalmudPageIndex(String tractate, String pageNum, String? side) async {
    try {
      // בניית הפניה המדויקת
      String ref = 'דף $pageNum';
      if (side != null) {
        if (side == 'א') {
          ref = 'דף $pageNum.';
        } else if (side == 'ב') {
          ref = 'דף $pageNum:';
        }
      }
      
      // שימוש ב-IndexMapper המקצועי
      return await IndexMapper.instance.getIndexFromRef(tractate, ref);
    } catch (e) {
      return null;
    }
  }

  /// מקבל את האינדקס המדויק של פרק תנ"ך (מקצועי)
  Future<int?> _getTanakhChapterIndex(String bookName, String chapter) async {
    try {
      // בניית הפניה המדויקת
      final ref = 'פרק $chapter';
      
      // שימוש ב-IndexMapper המקצועי
      return await IndexMapper.instance.getIndexFromRef(bookName, ref);
    } catch (e) {
      return null;
    }
  }

  /// מקבל את האינדקס המדויק של פרק משנה (מקצועי)
  Future<int?> _getMishnaChapterIndex(String tractate, String chapter) async {
    try {
      // בניית הפניה המדויקת
      final ref = 'פרק $chapter';
      
      // שימוש ב-IndexMapper המקצועי
      return await IndexMapper.instance.getIndexFromRef(tractate, ref);
    } catch (e) {
      return null;
    }
  }

  /// בודק אם מחרוזת היא מספר פרק תקין
  bool _isValidChapterNumber(String chapterNum) {
    // קבלת רשימת מספרי הפרקים התקינים מהמילון
    final validChapters = WordDictionary.instance.getValidChapterNumbers();
    
    // בדיקה אם זה מספר עברי תקין
    if (validChapters.contains(chapterNum)) {
      return true;
    }
    
    // בדיקה אם זה מספר ערבי (1-150 בערך)
    final numPattern = RegExp(r'^[0-9]+$');
    if (numPattern.hasMatch(chapterNum)) {
      final num = int.tryParse(chapterNum);
      return num != null && num >= 1 && num <= 150;
    }
    
    return false;
  }

  /// ממפה שמות ספרים חלופיים לשם הקובץ הנכון
  String _mapBookNameToFileName(String bookName) {
    // מיפוי שמות חלופיים לשמות קבצים
    final Map<String, String> bookNameMapping = {
      'תהלים': 'תהילים',  // תהלים -> תהילים
      'שה"ש': 'שיר השירים',
      'ש"א': 'שמואל א',
      'ש"ב': 'שמואל ב',
      'מ"א': 'מלכים א',
      'מ"ב': 'מלכים ב',
      'דה"א': 'דברי הימים א',
      'דה"ב': 'דברי הימים ב',
    };
    
    return bookNameMapping[bookName] ?? bookName;
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

  /// מזהה ומקשר הפניות לתנ"ך בפורמטים שונים
  String _processTanakhReferences(String htmlText, bool excludeExistingLinks) {
    try {
      if (excludeExistingLinks && htmlText.contains('class="tanakh-ref"')) {
        return _processTanakhWithExistingLinks(htmlText);
      }
      
      final tanakhBooks = WordDictionary.instance.getTanakhBooks();
      if (tanakhBooks.isEmpty) {
        return htmlText;
      }
      
      // בניית regex לזיהוי כל הפורמטים
      final bookPattern = tanakhBooks.map((b) => RegExp.escape(b)).join('|');
      
      // דפוס מורחב לתנ"ך - תומך בפורמטים:
      // - "אסתר ב,ט", "אסתר פרק ב פסוק ט", "אסתר פ"ב פ"ט"
      // - "בראשית א,א", "תהלים כג,ד", "ויקרא יד כב"
      final pattern = RegExp(
        r'(?<![א-ת])' +  // לא אחרי אות עברית (גבול מילה שמאלי)
        '(' + bookPattern + ')' +  // שם הספר (קבוצה 1)
        r'(?![א-ת])' +  // לא לפני אות עברית (גבול מילה ימני)
        r'\s+' +  // רווח חובה
        r'(?:' +  // התחלת קבוצה לא לוכדת עבור כל הפורמטים
          // פורמט עם "פרק" ו"פסוק" מפורש
          r'פרק\s+([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3})' +  // פרק (קבוצה 2)
          r'(?:\s+פסוק\s+([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3}))?' +  // פסוק אופציונלי (קבוצה 3)
        r'|' +  // או
          // פורמט עם קיצורים פ"א פ"ב
          r'פ"([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3})' +  // פרק מקוצר (קבוצה 4)
          r'(?:\s+פ"([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3}))?' +  // פסוק מקוצר אופציונלי (קבוצה 5)
        r'|' +  // או
          // פורמט פשוט עם פסיק או רווח - כולל גרשיים
          r'([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3})' +  // פרק (קבוצה 6)
          r'(?:(?:,\s*|\s+)([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3}))?' +  // פסוק אופציונלי (קבוצה 7)
        r')' +
        r'(?=\s|\.|,|:|;|\)|\]|<|$)',  // סוף - רווח או סימן פיסוק או תג HTML
        unicode: true,
        multiLine: true,
      );
      
      String result = htmlText;
      result = result.replaceAllMapped(pattern, (match) {
        // בדיקה שזה לא בתוך תג HTML או קישור קיים
        final beforeMatch = result.substring(0, match.start);
        if (beforeMatch.contains('<a ') && 
            beforeMatch.lastIndexOf('<a ') > beforeMatch.lastIndexOf('</a>')) {
          return match.group(0)!;
        }
        
        final fullMatch = match.group(0)!;
        final bookName = match.group(1)!;
        
        // זיהוי פורמט ופרק/פסוק
        String? chapter, verse;
        
        if (match.group(2) != null) {
          // פורמט עם "פרק" ו"פסוק" מפורש
          chapter = _cleanPageNumber(match.group(2)!);
          verse = match.group(3) != null ? _cleanPageNumber(match.group(3)!) : null;
        } else if (match.group(4) != null) {
          // פורמט עם קיצורים פ"א פ"ב
          chapter = _cleanPageNumber(match.group(4)!);
          verse = match.group(5) != null ? _cleanPageNumber(match.group(5)!) : null;
        } else if (match.group(6) != null) {
          // פורמט פשוט
          chapter = _cleanPageNumber(match.group(6)!);
          verse = match.group(7) != null ? _cleanPageNumber(match.group(7)!) : null;
        }
        
        if (chapter == null) {
          return fullMatch;
        }
        
        // בדיקה שמספר הפרק תקין
        if (!_isValidChapterNumber(chapter)) {
          return fullMatch;
        }
        
        // מיפוי שמות חלופיים לשם הקובץ הנכון
        String actualBookName = _mapBookNameToFileName(bookName);
        
        // בניית URL עם fallback לכותרת
        // לעת עתה נשתמש בפורמט עם fallback בלבד (מיפוי האינדקסים יתווסף בעתיד)
        final fallbackRef = 'פרק $chapter';
        
        // קישור עם fallback (האינדקס המדויק יתווסף בעתיד)
        final url = 'book://$actualBookName#$fallbackRef';
        
        // החזרת הטקסט המקורי עם קישור
        final linkText = fullMatch.trim();
        return '<a href="$url" class="tanakh-ref" data-ref="$fallbackRef">$linkText</a>';
      });
      
      return result;
    } catch (e) {
      return htmlText;
    }
  }

  /// מזהה ומקשר הפניות למשנה בפורמטים שונים
  String _processMishnaReferences(String htmlText, bool excludeExistingLinks) {
    try {
      // אם יש כבר קישורים קיימים (תלמוד או משנה), נעבד בזהירות
      if (excludeExistingLinks && (htmlText.contains('class="mishna-ref"') || htmlText.contains('class="talmud-ref"'))) {
        return _processMishnaWithExistingLinks(htmlText);
      }
      
      final mishnaOrders = WordDictionary.instance.getMishnaOrders();
      if (mishnaOrders.isEmpty) {
        return htmlText;
      }
      
      // בניית regex לזיהוי כל הפורמטים
      final orderPattern = mishnaOrders.map((o) => RegExp.escape(o)).join('|');
      
      // דפוס מורחב למשנה - תומך בפורמטים:
      // - "ביצה פ"ב מ"ה", "ביצה פרק ה משנה ג"
      // - "ברכות א,א", "שבת ב ג"
      final pattern = RegExp(
        r'(?<![א-ת])' +  // לא אחרי אות עברית (גבול מילה שמאלי)
        '(' + orderPattern + ')' +  // שם המסכת (קבוצה 1)
        r'(?![א-ת])' +  // לא לפני אות עברית (גבול מילה ימני)
        r'\s+' +  // רווח חובה
        r'(?:' +  // התחלת קבוצה לא לוכדת עבור כל הפורמטים
          // פורמט עם "פרק" ו"משנה" מפורש
          r'פרק\s+([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3})' +  // פרק (קבוצה 2)
          r'(?:\s+משנה\s+([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3}))?' +  // משנה אופציונלית (קבוצה 3)
        r'|' +  // או
          // פורמט עם קיצורים פ"א מ"ב
          r'פ"([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3})' +  // פרק מקוצר (קבוצה 4)
          r'(?:\s+מ"([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3}))?' +  // משנה מקוצרת אופציונלית (קבוצה 5)
        r'|' +  // או
          // פורמט פשוט עם פסיק או רווח - כולל גרשיים
          r'([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3})' +  // פרק (קבוצה 6)
          r'(?:(?:,\s*|\s+)([א-ת]{1,3}(?:["\u0027]\s*[א-ת])?|[0-9]{1,3}))?' +  // משנה אופציונלית (קבוצה 7)
        r')' +
        r'(?=\s|\.|,|:|;|\)|\]|<|$)',  // סוף - רווח או סימן פיסוק או תג HTML
        unicode: true,
        multiLine: true,
      );
      
      String result = htmlText;
      result = result.replaceAllMapped(pattern, (match) {
        // בדיקה שזה לא בתוך תג HTML או קישור קיים
        final beforeMatch = result.substring(0, match.start);
        if (beforeMatch.contains('<a ') && 
            beforeMatch.lastIndexOf('<a ') > beforeMatch.lastIndexOf('</a>')) {
          return match.group(0)!;
        }
        
        final fullMatch = match.group(0)!;
        final tractate = match.group(1)!;
        
        // בדיקה נוספת: אם המסכת הזו קיימת גם בתלמוד, נבדוק אם זה נראה כמו הפניה תלמודית
        final talmudTractates = WordDictionary.instance.getTractates();
        if (talmudTractates.contains(tractate)) {
          // זיהוי פורמט זמני כדי לבדוק אם זה יכול להיות תלמוד
          String? tempChapter, tempMishna;
          
          if (match.group(2) != null) {
            tempChapter = match.group(2)!;
            tempMishna = match.group(3);
          } else if (match.group(4) != null) {
            tempChapter = match.group(4)!;
            tempMishna = match.group(5);
          } else if (match.group(6) != null) {
            tempChapter = match.group(6)!;
            tempMishna = match.group(7);
          }
          
          if (tempChapter != null) {
            // בדיקה אם מספר הפרק יכול להיות מספר דף תלמודי
            final validPageNumbers = WordDictionary.instance.getValidPageNumbers();
            if (validPageNumbers.contains(tempChapter)) {
              // אם יש גם עמוד (משנה) שיכול להיות עמוד תלמודי (א/ב)
              if (tempMishna != null && (tempMishna == 'א' || tempMishna == 'ב')) {
                // זה כנראה הפניה תלמודית שלא נתפסה, לא ניצור קישור משנה
                return fullMatch;
              }
            }
          }
        }
        
        // זיהוי פורמט ופרק/משנה
        String? chapter, mishna;
        
        if (match.group(2) != null) {
          // פורמט עם "פרק" ו"משנה" מפורש
          chapter = _cleanPageNumber(match.group(2)!);
          mishna = match.group(3) != null ? _cleanPageNumber(match.group(3)!) : null;
        } else if (match.group(4) != null) {
          // פורמט עם קיצורים פ"א מ"ב
          chapter = _cleanPageNumber(match.group(4)!);
          mishna = match.group(5) != null ? _cleanPageNumber(match.group(5)!) : null;
        } else if (match.group(6) != null) {
          // פורמט פשוט
          chapter = _cleanPageNumber(match.group(6)!);
          mishna = match.group(7) != null ? _cleanPageNumber(match.group(7)!) : null;
        }
        
        if (chapter == null) {
          return fullMatch;
        }
        
        // בדיקה שמספר הפרק תקין
        if (!_isValidChapterNumber(chapter)) {
          return fullMatch;
        }
        
        // הוספת "משנה" לפני שם המסכת
        String actualTractate = 'משנה $tractate';
        
        // בניית URL עם fallback לכותרת
        // לעת עתה נשתמש בפורמט עם fallback בלבד (מיפוי האינדקסים יתווסף בעתיד)
        final fallbackRef = 'פרק $chapter';
        
        // קישור עם fallback (האינדקס המדויק יתווסף בעתיד)
        final url = 'book://$actualTractate#$fallbackRef';
        
        // החזרת הטקסט המקורי עם קישור
        final linkText = fullMatch.trim();
        return '<a href="$url" class="mishna-ref" data-ref="$fallbackRef">$linkText</a>';
      });
      
      return result;
    } catch (e) {
      return htmlText;
    }
  }

  /// מעבד טקסט תנ"ך עם קישורים קיימים - לא נוגע בתוכן של תגי <a>
  String _processTanakhWithExistingLinks(String htmlText) {
    final buffer = StringBuffer();
    int lastIndex = 0;
    
    // מוצא את כל תגי ה-<a>
    final linkPattern = RegExp(r'<a\s[^>]*>.*?</a>', dotAll: true);
    final matches = linkPattern.allMatches(htmlText);
    
    for (final match in matches) {
      // מעבד את הטקסט לפני הקישור
      final textBefore = htmlText.substring(lastIndex, match.start);
      buffer.write(_processTanakhReferences(textBefore, false));
      
      // מוסיף את הקישור הקיים כמו שהוא
      buffer.write(match.group(0));
      
      lastIndex = match.end;
    }
    
    // מעבד את הטקסט אחרי הקישור האחרון
    if (lastIndex < htmlText.length) {
      final textAfter = htmlText.substring(lastIndex);
      buffer.write(_processTanakhReferences(textAfter, false));
    }
    
    return buffer.toString();
  }

  /// מעבד טקסט משנה עם קישורים קיימים - לא נוגע בתוכן של תגי <a>
  /// גם לא יוצר קישורי משנה במקומות שכבר יש קישורי תלמוד
  String _processMishnaWithExistingLinks(String htmlText) {
    final buffer = StringBuffer();
    int lastIndex = 0;
    
    // מוצא את כל תגי ה-<a> (כולל תלמוד ומשנה)
    final linkPattern = RegExp(r'<a\s[^>]*>.*?</a>', dotAll: true);
    final matches = linkPattern.allMatches(htmlText);
    
    for (final match in matches) {
      // מעבד את הטקסט לפני הקישור - רק אם זה לא קישור תלמודי
      final textBefore = htmlText.substring(lastIndex, match.start);
      buffer.write(_processMishnaReferences(textBefore, false));
      
      // מוסיף את הקישור הקיים כמו שהוא
      buffer.write(match.group(0));
      
      lastIndex = match.end;
    }
    
    // מעבד את הטקסט אחרי הקישור האחרון
    if (lastIndex < htmlText.length) {
      final textAfter = htmlText.substring(lastIndex);
      buffer.write(_processMishnaReferences(textAfter, false));
    }
    
    return buffer.toString();
  }
}