import 'dart:convert';
import 'package:flutter/services.dart';

/// מחלקה לניהול מילון מילים לקישורים אוטומטיים
class WordDictionary {
  static WordDictionary? _instance;
  static WordDictionary get instance => _instance ??= WordDictionary._();
  
  WordDictionary._();
  
  Map<String, WordLink>? _dictionary;
  List<String>? _tractates;
  
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
      
      // יצירת מילון ריק - לא נשתמש בו יותר
      _dictionary = {};
    } catch (e) {
      // אם הקובץ לא קיים, נשתמש ברשימת מסכתות ברירת מחדל
      _tractates = _getDefaultTractates();
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
  
  /// מחזיר את רשימת המסכתות
  List<String> getTractates() {
    return List.from(_tractates ?? []);
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