import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/utils/ref_helper.dart';

/// מחלקה למיפוי מקצועי בין הפניות לאינדקסים
/// 
/// המחלקה הזו מחליפה את החיפוש הטקסטואלי האיטי בגישה מקצועית
/// המבוססת על מבנה ה-TOC הקיים ומסד הנתונים
class IndexMapper {
  static IndexMapper? _instance;
  static IndexMapper get instance => _instance ??= IndexMapper._();
  
  IndexMapper._();
  
  // Cache למיפויים שכבר נמצאו
  final Map<String, Map<String, int>> _bookRefToIndexCache = {};
  final Map<String, Map<int, String>> _bookIndexToRefCache = {};
  
  /// מקבל אינדקס מדויק מהפניה (סינכרוני - רק מ-cache)
  /// 
  /// פונקציה מהירה שמחזירה אינדקס רק אם הוא כבר קיים ב-cache
  /// לשימוש במקומות שבהם אנחנו לא יכולים לחכות לטעינה אסינכרונית
  int? getIndexFromRefSync(String bookTitle, String ref) {
    final bookCache = _bookRefToIndexCache[bookTitle];
    return bookCache?[ref];
  }
  
  /// מקבל אינדקס מדויק מהפניה (מקצועי)
  /// 
  /// דוגמאות:
  /// - getIndexFromRef('ברכות', 'דף ב.') -> 142
  /// - getIndexFromRef('בראשית', 'פרק א') -> 25
  /// - getIndexFromRef('משנה ברכות', 'פרק ב') -> 67
  Future<int?> getIndexFromRef(String bookTitle, String ref) async {
    try {
      // בדיקה ב-cache
      final bookCache = _bookRefToIndexCache[bookTitle];
      if (bookCache != null && bookCache.containsKey(ref)) {
        return bookCache[ref];
      }
      
      // טעינת הספר
      final library = await DataRepository.instance.library;
      final book = await library.findBookByTitle(bookTitle, TextBook);
      if (book == null || book is! TextBook) {
        return null;
      }
      
      // בניית מיפוי מ-TOC (יעיל - פעם אחת לספר)
      await _buildBookMapping(book);
      
      // חיפוש במיפוי
      final updatedCache = _bookRefToIndexCache[bookTitle];
      return updatedCache?[ref];
      
    } catch (e) {
      return null;
    }
  }
  
  /// מקבל הפניה מאינדקס (מקצועי)
  /// 
  /// דוגמאות:
  /// - getRefFromIndex('ברכות', 142) -> 'דף ב.'
  /// - getRefFromIndex('בראשית', 25) -> 'פרק א'
  Future<String?> getRefFromIndex(String bookTitle, int index) async {
    try {
      // בדיקה ב-cache
      final bookCache = _bookIndexToRefCache[bookTitle];
      if (bookCache != null && bookCache.containsKey(index)) {
        return bookCache[index];
      }
      
      // טעינת הספר
      final library = await DataRepository.instance.library;
      final book = await library.findBookByTitle(bookTitle, TextBook);
      if (book == null || book is! TextBook) {
        return null;
      }
      
      // שימוש בפונקציה הקיימת (יעילה)
      final ref = await refFromIndex(index, book.tableOfContents);
      
      // שמירה ב-cache
      _bookIndexToRefCache[bookTitle] ??= {};
      _bookIndexToRefCache[bookTitle]![index] = ref;
      
      // אם הפניה ריקה או זהה לשם הספר, נחזיר null
      if (ref.isEmpty || ref == bookTitle) {
        return null;
      }
      
      return ref;
      
    } catch (e) {
      return null;
    }
  }
  
  /// בונה מיפוי מלא לספר (פעם אחת לספר)
  Future<void> _buildBookMapping(TextBook book) async {
    if (_bookRefToIndexCache.containsKey(book.title)) {
      return; // כבר נבנה
    }
    
    try {
      final toc = await book.tableOfContents;
      final refToIndex = <String, int>{};
      final indexToRef = <int, String>{};
      
      // מעבר על כל הכניסות ב-TOC
      void processTocEntries(List<TocEntry> entries, [String prefix = '']) {
        for (final entry in entries) {
          final fullRef = prefix.isEmpty ? entry.text : '$prefix, ${entry.text}';
          
          // מיפוי דו-כיווני
          refToIndex[entry.text] = entry.index;
          refToIndex[fullRef] = entry.index;
          indexToRef[entry.index] = entry.text;
          
          // עיבוד ילדים
          processTocEntries(entry.children, fullRef);
        }
      }
      
      processTocEntries(toc);
      
      // שמירה ב-cache
      _bookRefToIndexCache[book.title] = refToIndex;
      _bookIndexToRefCache[book.title] = indexToRef;
      
    } catch (e) {
      // במקרה של שגיאה, נשמור cache ריק כדי לא לנסות שוב
      _bookRefToIndexCache[book.title] = {};
      _bookIndexToRefCache[book.title] = {};
    }
  }
  
  /// מנקה cache לספר ספציפי (לשימוש כשהספר משתנה)
  void clearBookCache(String bookTitle) {
    _bookRefToIndexCache.remove(bookTitle);
    _bookIndexToRefCache.remove(bookTitle);
  }
  
  /// מנקה את כל ה-cache
  void clearAllCache() {
    _bookRefToIndexCache.clear();
    _bookIndexToRefCache.clear();
  }
  
  /// טוען מראש ספרים פופולריים לשיפור ביצועים
  Future<void> preloadPopularBooks() async {
    const popularBooks = [
      'ברכות', 'שבת', 'עירובין', 'פסחים', 'יומא', 'סוכה', 'ביצה', 'ראש השנה',
      'בראשית', 'שמות', 'ויקרא', 'במדבר', 'דברים',
      'תהילים', 'משלי', 'איוב', 'אסתר', 'דניאל',
      'משנה ברכות', 'משנה שבת', 'משנה פסחים'
    ];
    
    try {
      final library = await DataRepository.instance.library;
      
      for (final bookTitle in popularBooks) {
        try {
          final book = await library.findBookByTitle(bookTitle, TextBook);
          if (book != null && book is TextBook) {
            await _buildBookMapping(book);
          }
        } catch (e) {
          // אם ספר ספציפי נכשל, נמשיך לבאים
          continue;
        }
      }
    } catch (e) {
      // שגיאה כללית - לא נעשה כלום
    }
  }
  
  /// מקבל סטטיסטיקות על ה-cache (לדיבוג)
  Map<String, dynamic> getCacheStats() {
    return {
      'books_cached': _bookRefToIndexCache.length,
      'total_ref_mappings': _bookRefToIndexCache.values
          .map((cache) => cache.length)
          .fold(0, (a, b) => a + b),
      'total_index_mappings': _bookIndexToRefCache.values
          .map((cache) => cache.length)
          .fold(0, (a, b) => a + b),
    };
  }
}