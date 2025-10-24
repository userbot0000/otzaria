import 'dart:convert';
import 'package:flutter/services.dart';

/// מחלקה לניהול מילון מילים לקישורים אוטומטיים
class WordDictionary {
  static WordDictionary? _instance;
  static WordDictionary get instance => _instance ??= WordDictionary._();
  
  WordDictionary._();
  
  Map<String, WordLink>? _dictionary;
  
  /// טוען את המילון מקובץ JSON
  Future<void> loadDictionary() async {
    if (_dictionary != null) return;
    
    try {
      // ניסיון לטעון מקובץ assets
      final String jsonString = await rootBundle.loadString('assets/word_dictionary.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _dictionary = {};
      jsonData.forEach((word, linkData) {
        _dictionary![word] = WordLink.fromJson(linkData);
      });
    } catch (e) {
      // אם הקובץ לא קיים, ניצור מילון ברירת מחדל
      _dictionary = _createDefaultDictionary();
    }
  }
  
  /// יוצר מילון ברירת מחדל עם מילים נפוצות
  Map<String, WordLink> _createDefaultDictionary() {
    return {
      // מסכתות תלמוד
      'ברכות': WordLink(
        bookTitle: 'ברכות',
        type: LinkType.book,
        description: 'מסכת ברכות',
      ),
      'שבת': WordLink(
        bookTitle: 'שבת',
        type: LinkType.book,
        description: 'מסכת שבת',
      ),
      'עירובין': WordLink(
        bookTitle: 'עירובין',
        type: LinkType.book,
        description: 'מסכת עירובין',
      ),
      'פסחים': WordLink(
        bookTitle: 'פסחים',
        type: LinkType.book,
        description: 'מסכת פסחים',
      ),
      'יומא': WordLink(
        bookTitle: 'יומא',
        type: LinkType.book,
        description: 'מסכת יומא',
      ),
      'סוכה': WordLink(
        bookTitle: 'סוכה',
        type: LinkType.book,
        description: 'מסכת סוכה',
      ),
      'ביצה': WordLink(
        bookTitle: 'ביצה',
        type: LinkType.book,
        description: 'מסכת ביצה',
      ),
      'ראש השנה': WordLink(
        bookTitle: 'ראש השנה',
        type: LinkType.book,
        description: 'מסכת ראש השנה',
      ),
      'תענית': WordLink(
        bookTitle: 'תענית',
        type: LinkType.book,
        description: 'מסכת תענית',
      ),
      'מגילה': WordLink(
        bookTitle: 'מגילה',
        type: LinkType.book,
        description: 'מסכת מגילה',
      ),
      
      // פרשנים
      'רש"י': WordLink(
        bookTitle: 'רש"י',
        type: LinkType.commentary,
        description: 'פירוש רש"י',
      ),
      'תוספות': WordLink(
        bookTitle: 'תוספות',
        type: LinkType.commentary,
        description: 'פירוש התוספות',
      ),
      'רמב"ם': WordLink(
        bookTitle: 'רמב"ם',
        type: LinkType.book,
        description: 'הרמב"ם',
      ),
      'שולחן ערוך': WordLink(
        bookTitle: 'שולחן ערוך',
        type: LinkType.book,
        description: 'שולחן ערוך',
      ),
      
      // ספרי תנ"ך
      'בראשית': WordLink(
        bookTitle: 'בראשית',
        type: LinkType.book,
        description: 'ספר בראשית',
      ),
      'שמות': WordLink(
        bookTitle: 'שמות',
        type: LinkType.book,
        description: 'ספר שמות',
      ),
      'ויקרא': WordLink(
        bookTitle: 'ויקרא',
        type: LinkType.book,
        description: 'ספר ויקרא',
      ),
      'במדבר': WordLink(
        bookTitle: 'במדבר',
        type: LinkType.book,
        description: 'ספר במדבר',
      ),
      'דברים': WordLink(
        bookTitle: 'דברים',
        type: LinkType.book,
        description: 'ספר דברים',
      ),
      
      // מושגים נפוצים
      'הלכה': WordLink(
        bookTitle: 'הלכה',
        type: LinkType.concept,
        description: 'מושג ההלכה',
        searchQuery: 'הלכה',
      ),
      'אגדה': WordLink(
        bookTitle: 'אגדה',
        type: LinkType.concept,
        description: 'מושג האגדה',
        searchQuery: 'אגדה',
      ),
      'מצוה': WordLink(
        bookTitle: 'מצוה',
        type: LinkType.concept,
        description: 'מושג המצוה',
        searchQuery: 'מצוה',
      ),
    };
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