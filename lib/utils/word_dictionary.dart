import 'dart:convert';
import 'package:flutter/services.dart';

/// מחלקה לניהול מילון מילים לקישורים אוטומטיים
class WordDictionary {
  static WordDictionary? _instance;
  static WordDictionary get instance => _instance ??= WordDictionary._();
  
  WordDictionary._();
  
  Map<String, WordLink>? _dictionary;
  List<String>? _tractates;
  List<String>? _validPageNumbers;
  List<String>? _tanakhBooks;
  List<String>? _mishnaOrders;
  List<String>? _validChapterNumbers;
  
  /// טוען את המילון מקובץ JSON
  Future<void> loadDictionary() async {
    if (_tractates != null) return;
    
    try {
      // ניסיון לטעון מקובץ assets
      final String jsonString = await rootBundle.loadString('assets/word_dictionary.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      if (jsonData.containsKey('tractates')) {
        _tractates = List<String>.from(jsonData['tractates']);
      } else {
        _tractates = _getDefaultTractates();
      }
      
      if (jsonData.containsKey('valid_page_numbers')) {
        _validPageNumbers = List<String>.from(jsonData['valid_page_numbers']);
      } else {
        _validPageNumbers = _getDefaultValidPageNumbers();
      }
      
      if (jsonData.containsKey('tanakh_books')) {
        _tanakhBooks = List<String>.from(jsonData['tanakh_books']);
      } else {
        _tanakhBooks = _getDefaultTanakhBooks();
      }
      
      if (jsonData.containsKey('mishna_orders')) {
        _mishnaOrders = List<String>.from(jsonData['mishna_orders']);
      } else {
        _mishnaOrders = _getDefaultMishnaOrders();
      }
      
      if (jsonData.containsKey('valid_chapter_numbers')) {
        _validChapterNumbers = List<String>.from(jsonData['valid_chapter_numbers']);
      } else {
        _validChapterNumbers = _getDefaultValidChapterNumbers();
      }
      
      // יצירת מילון ריק - לא נשתמש בו יותר
      _dictionary = {};
    } catch (e) {
      // אם הקובץ לא קיים, נשתמש ברשימות ברירת מחדל
      _tractates = _getDefaultTractates();
      _validPageNumbers = _getDefaultValidPageNumbers();
      _tanakhBooks = _getDefaultTanakhBooks();
      _mishnaOrders = _getDefaultMishnaOrders();
      _validChapterNumbers = _getDefaultValidChapterNumbers();
      _dictionary = {};
    }
  }
  
  /// מחזיר רשימת מסכתות ברירת מחדל
  List<String> _getDefaultTractates() {
    return [
      'ברכות', 'שבת', 'עירובין', 'פסחים', 'יומא', 'סוכה', 'ביצה',
      'ראש השנה', 'תענית', 'מגילה', 'מועד קטן', 'חגיגה', 'יבמות',
      'כתובות', 'נדרים', 'נזיר', 'סוטה', 'גיטין', 'קידושין',
      'בבא קמא', 'בבא מציעא', 'בבא בתרא', 'סנהדרין', 'מכות',
      'שבועות', 'עבודה זרה', 'הוריות', 'זבחים', 'מנחות', 'חולין',
      'בכורות', 'ערכין', 'תמורה', 'כריתות', 'מעילה', 'תמיד', 'נדה'
    ];
  }
  
  /// מחזיר רשימת מספרי דפים תקינים ברירת מחדל (א-קעז)
  List<String> _getDefaultValidPageNumbers() {
    return [
      'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט', 'י',
      'יא', 'יב', 'יג', 'יד', 'טו', 'טז', 'יז', 'יח', 'יט', 'כ',
      'כא', 'כב', 'כג', 'כד', 'כה', 'כו', 'כז', 'כח', 'כט', 'ל',
      'לא', 'לב', 'לג', 'לד', 'לה', 'לו', 'לז', 'לח', 'לט', 'מ',
      'מא', 'מב', 'מג', 'מד', 'מה', 'מו', 'מז', 'מח', 'מט', 'נ',
      'נא', 'נב', 'נג', 'נד', 'נה', 'נו', 'נז', 'נח', 'נט', 'ס',
      'סא', 'סב', 'סג', 'סד', 'סה', 'סו', 'סז', 'סח', 'סט', 'ע',
      'עא', 'עב', 'עג', 'עד', 'עה', 'עו', 'עז', 'עח', 'עט', 'פ',
      'פא', 'פב', 'פג', 'פד', 'פה', 'פו', 'פז', 'פח', 'פט', 'צ',
      'צא', 'צב', 'צג', 'צד', 'צה', 'צו', 'צז', 'צח', 'צט', 'ק',
      'קא', 'קב', 'קג', 'קד', 'קה', 'קו', 'קז', 'קח', 'קט', 'קי',
      'קיא', 'קיב', 'קיג', 'קיד', 'קטו', 'קטז', 'קיז', 'קיח', 'קיט', 'קכ',
      'קכא', 'קכב', 'קכג', 'קכד', 'קכה', 'קכו', 'קכז', 'קכח', 'קכט', 'קל',
      'קלא', 'קלב', 'קלג', 'קלד', 'קלה', 'קלו', 'קלז', 'קלח', 'קלט', 'קמ',
      'קמא', 'קמב', 'קמג', 'קמד', 'קמה', 'קמו', 'קמז', 'קמח', 'קמט', 'קן',
      'קנא', 'קנב', 'קנג', 'קנד', 'קנה', 'קנו', 'קנז', 'קנח', 'קנט', 'קס',
      'קסא', 'קסב', 'קסג', 'קסד', 'קסה', 'קסו', 'קסז', 'קסח', 'קסט', 'קע',
      'קעא', 'קעב', 'קעג', 'קעד', 'קעה', 'קעו', 'קעז'
    ];
  }

  /// מחזיר רשימת ספרי תנ"ך ברירת מחדל
  List<String> _getDefaultTanakhBooks() {
    return [
      // תורה
      'בראשית', 'שמות', 'ויקרא', 'במדבר', 'דברים',
      // נביאים ראשונים
      'יהושע', 'שופטים', 'שמואל א', 'שמואל ב', 'מלכים א', 'מלכים ב',
      // נביאים אחרונים
      'ישעיה', 'ירמיה', 'יחזקאל',
      'הושע', 'יואל', 'עמוס', 'עובדיה', 'יונה', 'מיכה', 'נחום', 'חבקוק', 'צפניה', 'חגי', 'זכריה', 'מלאכי',
      // כתובים
      'תהלים', 'תהילים', 'משלי', 'איוב', 'שיר השירים', 'רות', 'איכה', 'קהלת', 'אסתר', 'דניאל', 'עזרא', 'נחמיה', 'דברי הימים א', 'דברי הימים ב',
      // שמות חלופיים נפוצים
      'שה"ש', 'ש"א', 'ש"ב', 'מ"א', 'מ"ב', 'דה"א', 'דה"ב'
    ];
  }

  /// מחזיר רשימת מסכתות משנה ברירת מחדל
  List<String> _getDefaultMishnaOrders() {
    return [
      // סדר זרעים
      'ברכות', 'פאה', 'דמאי', 'כלאים', 'שביעית', 'תרומות', 'מעשרות', 'מעשר שני', 'חלה', 'ערלה', 'בכורים',
      // סדר מועד
      'שבת', 'עירובין', 'פסחים', 'שקלים', 'יומא', 'סוכה', 'ביצה', 'ראש השנה', 'תענית', 'מגילה', 'מועד קטן', 'חגיגה',
      // סדר נשים
      'יבמות', 'כתובות', 'נדרים', 'נזיר', 'סוטה', 'גיטין', 'קידושין',
      // סדר נזיקין
      'בבא קמא', 'בבא מציעא', 'בבא בתרא', 'סנהדרין', 'מכות', 'שבועות', 'עדויות', 'עבודה זרה', 'אבות', 'הוריות',
      // סדר קדשים
      'זבחים', 'מנחות', 'חולין', 'בכורות', 'ערכין', 'תמורה', 'כריתות', 'מעילה', 'תמיד', 'מדות', 'קינים',
      // סדר טהרות
      'כלים', 'אהלות', 'נגעים', 'פרה', 'טהרות', 'מקואות', 'נדה', 'מכשירין', 'זבים', 'טבול יום', 'ידים', 'עוקצין'
    ];
  }

  /// מחזיר רשימת מספרי פרקים תקינים ברירת מחדל (א-קיט)
  List<String> _getDefaultValidChapterNumbers() {
    return [
      'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט', 'י',
      'יא', 'יב', 'יג', 'יד', 'טו', 'טז', 'יז', 'יח', 'יט', 'כ',
      'כא', 'כב', 'כג', 'כד', 'כה', 'כו', 'כז', 'כח', 'כט', 'ל',
      'לא', 'לב', 'לג', 'לד', 'לה', 'לו', 'לז', 'לח', 'לט', 'מ',
      'מא', 'מב', 'מג', 'מד', 'מה', 'מו', 'מז', 'מח', 'מט', 'נ',
      'נא', 'נב', 'נג', 'נד', 'נה', 'נו', 'נז', 'נח', 'נט', 'ס',
      'סא', 'סב', 'סג', 'סד', 'סה', 'סו', 'סז', 'סח', 'סט', 'ע',
      'עא', 'עב', 'עג', 'עד', 'עה', 'עו', 'עז', 'עח', 'עט', 'פ',
      'פא', 'פב', 'פג', 'פד', 'פה', 'פו', 'פז', 'פח', 'פט', 'צ',
      'צא', 'צב', 'צג', 'צד', 'צה', 'צו', 'צז', 'צח', 'צט', 'ק',
      'קא', 'קב', 'קג', 'קד', 'קה', 'קו', 'קז', 'קח', 'קט', 'קי',
      'קיא', 'קיב', 'קיג', 'קיד', 'קטו', 'קטז', 'קיז', 'קיח', 'קיט', 'קכ',
      'קכא', 'קכב', 'קכג', 'קכד', 'קכה', 'קכו', 'קכז', 'קכח', 'קכט', 'קל',
      'קלא', 'קלב', 'קלג', 'קלד', 'קלה', 'קלו', 'קלז', 'קלח', 'קלט', 'קמ',
      'קמא', 'קמב', 'קמג', 'קמד', 'קמה', 'קמו', 'קמז', 'קמח', 'קמט', 'קן'
    ];
  }

  /// מחזיר את רשימת המסכתות
  List<String> getTractates() {
    return List.from(_tractates ?? []);
  }
  
  /// מחזיר את רשימת מספרי הדפים התקינים
  List<String> getValidPageNumbers() {
    return List.from(_validPageNumbers ?? []);
  }

  /// מחזיר את רשימת ספרי התנ"ך
  List<String> getTanakhBooks() {
    return List.from(_tanakhBooks ?? []);
  }

  /// מחזיר את רשימת מסכתות המשנה
  List<String> getMishnaOrders() {
    return List.from(_mishnaOrders ?? []);
  }

  /// מחזיר את רשימת מספרי הפרקים התקינים
  List<String> getValidChapterNumbers() {
    return List.from(_validChapterNumbers ?? []);
  }
  
  /// מחפש קישור למילה
  WordLink? findWordLink(String word) {
    if (_dictionary == null) return null;
    
    // חיפוש מדויק
    if (_dictionary!.containsKey(word)) {
      return _dictionary![word];
    }
    
    // חיפוש חלקי (למילים עם סיומות)
    for (String dictWord in _dictionary!.keys) {
      if (word.contains(dictWord) || dictWord.contains(word)) {
        return _dictionary![dictWord];
      }
    }
    
    return null;
  }
  
  /// מוסיף מילה חדשה למילון
  void addWord(String word, WordLink link) {
    _dictionary ??= {};
    _dictionary![word] = link;
  }
  
  /// מסיר מילה מהמילון
  void removeWord(String word) {
    _dictionary?.remove(word);
  }
  
  /// מחזיר את כל המילים במילון
  Map<String, WordLink> getAllWords() {
    return Map.from(_dictionary ?? {});
  }
  
  /// שומר את המילון לקובץ (לשימוש עתידי)
  Future<void> saveDictionary() async {
    if (_dictionary == null) return;
    
    final Map<String, dynamic> jsonData = {};
    _dictionary!.forEach((word, link) {
      jsonData[word] = link.toJson();
    });
    
    // כאן ניתן להוסיף שמירה לקובץ מקומי
    // לעת עתה נשמור רק בזיכרון
  }
}

/// סוגי קישורים
enum LinkType {
  book,        // קישור לספר
  commentary,  // קישור לפירוש
  concept,     // קישור למושג (חיפוש)
  reference,   // קישור להפניה ספציפית
}

/// מחלקה המייצגת קישור למילה
class WordLink {
  final String bookTitle;
  final LinkType type;
  final String description;
  final String? reference;      // הפניה ספציפית (דף, פרק וכו')
  final String? searchQuery;    // שאילתת חיפוש למושגים
  final bool caseSensitive;     // האם רגיש לאותיות גדולות/קטנות
  final bool wholeWordOnly;     // האם להתאים רק מילים שלמות
  
  WordLink({
    required this.bookTitle,
    required this.type,
    required this.description,
    this.reference,
    this.searchQuery,
    this.caseSensitive = false,
    this.wholeWordOnly = true,
  });
  
  /// יוצר WordLink מ-JSON
  factory WordLink.fromJson(Map<String, dynamic> json) {
    return WordLink(
      bookTitle: json['bookTitle'] ?? '',
      type: LinkType.values.firstWhere(
        (e) => e.toString() == 'LinkType.${json['type']}',
        orElse: () => LinkType.book,
      ),
      description: json['description'] ?? '',
      reference: json['reference'],
      searchQuery: json['searchQuery'],
      caseSensitive: json['caseSensitive'] ?? false,
      wholeWordOnly: json['wholeWordOnly'] ?? true,
    );
  }
  
  /// ממיר ל-JSON
  Map<String, dynamic> toJson() {
    return {
      'bookTitle': bookTitle,
      'type': type.toString().split('.').last,
      'description': description,
      'reference': reference,
      'searchQuery': searchQuery,
      'caseSensitive': caseSensitive,
      'wholeWordOnly': wholeWordOnly,
    };
  }
  
  /// יוצר URL לקישור
  String createUrl() {
    switch (type) {
      case LinkType.book:
        if (reference != null) {
          return 'book://$bookTitle#$reference';
        }
        return 'book://$bookTitle';
      
      case LinkType.commentary:
        if (reference != null) {
          return 'book://$bookTitle#$reference';
        }
        return 'book://$bookTitle';
      
      case LinkType.concept:
        if (searchQuery != null) {
          return 'search://$searchQuery';
        }
        return 'search://$bookTitle';
      
      case LinkType.reference:
        return 'book://$bookTitle#$reference';
    }
  }
}