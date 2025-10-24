import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// מחלקה לטיפול בקישורי HTML בתוך הטקסט
class HtmlLinkHandler {
  static OverlayEntry? _currentOverlay;
  static final ItemScrollController _previewScrollController = ItemScrollController();
  /// מנסה לפענח URL בצורה בטוחה, תומך בטקסט רגיל ו-URL encoded
  static String _safeDecode(String text) {
    if (text.isEmpty) return text;
    
    try {
      // אם הטקסט מכיל % זה כנראה מקודד
      if (text.contains('%')) {
        return Uri.decodeComponent(text);
      }
      // אחרת, זה כבר טקסט רגיל
      return text;
    } catch (e) {
      // אם הפענוח נכשל, נחזיר את הטקסט המקורי
      debugPrint('Failed to decode URL component: $text, error: $e');
      return text;
    }
  }

  /// מציג תצוגה מקדימה של קישור
  static Future<void> showPreview(
    BuildContext context,
    String url,
    Offset position,
  ) async {
    // סגירת תצוגה מקדימה קיימת
    hidePreview();

    try {
      String? bookTitle;
      String? headerName;
      int startIndex = 0;

      // פענוח הקישור
      if (url.startsWith('#')) {
        // קישור פנימי - נשתמש בספר הנוכחי
        final textBookBloc = context.read<TextBookBloc>();
        final state = textBookBloc.state;
        if (state is! TextBookLoaded) return;
        
        bookTitle = state.book.title;
        headerName = _safeDecode(url.substring(1));
      } else if (url.startsWith('book://')) {
        final bookUrl = url.substring(7);
        if (bookUrl.contains('#')) {
          final parts = bookUrl.split('#');
          bookTitle = _safeDecode(parts[0]);
          
          // טיפול במבנה תלמודי: ספר#דף#צד
          if (parts.length >= 2) {
            if (parts.length == 3) {
              // מבנה מלא: ספר#דף#צד
              headerName = _safeDecode('${parts[1]} ${parts[2]}');
            } else {
              // מבנה רגיל: ספר#כותרת
              headerName = _safeDecode(parts[1]);
            }
          }
        } else {
          bookTitle = _safeDecode(bookUrl);
        }
      } else {
        return; // לא קישור שאנחנו מטפלים בו
      }

      if (bookTitle == null) return;

      // טעינת הספר
      final library = await DataRepository.instance.library;
      final foundBook = await library.findBookByTitle(bookTitle, TextBook);
      if (foundBook == null || foundBook is! TextBook) return;

      final book = foundBook as TextBook;
      final content = await book.text;
      final lines = content.split('\n');

      // חיפוש האינדקס אם יש כותרת
      if (headerName != null) {
        final headerIndex = await _findHeaderIndex(book, headerName);
        if (headerIndex != null) {
          startIndex = headerIndex;
        }
      }

      // יצירת התצוגה המקדימה
      _currentOverlay = OverlayEntry(
        builder: (context) => _PreviewOverlay(
          position: position,
          bookTitle: bookTitle!,
          lines: lines,
          startIndex: startIndex,
          onClose: hidePreview,
        ),
      );

      Overlay.of(context).insert(_currentOverlay!);
    } catch (e) {
      debugPrint('שגיאה בהצגת תצוגה מקדימה: $e');
    }
  }

  /// מסתיר את התצוגה המקדימה
  static void hidePreview() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// מטפל בלחיצה על קישור HTML
  /// 
  /// הפונקציה מפרשת קישורים בפורמטים הבאים:
  /// - book://שם_הספר - פותח ספר בתחילת הספר
  /// - book://שם_הספר#כותרת - פותח ספר ומנווט לכותרת ספציפית
  /// - #כותרת - מנווט לכותרת באותו ספר
  /// - search://שאילתה - מבצע חיפוש
  /// 
  /// דוגמאות:
  /// - <a href="book://ברכות">ברכות</a>
  /// - <a href="book://ברכות#דף ב">ברכות דף ב</a>
  /// - <a href="#דף ג">דף ג</a>
  /// - <a href="search://הלכה">הלכה</a>
  static Future<bool> handleLink(
    BuildContext context,
    String url,
    Function(TextBookTab) openBookCallback,
  ) async {
    try {
      // בדיקה אם זה קישור פנימי לכותרת באותו ספר
      if (url.startsWith('#')) {
        final headerName = _safeDecode(url.substring(1));
        await _navigateToHeader(context, headerName);
        return true;
      }

      // בדיקה אם זה קישור חיפוש
      if (url.startsWith('search://')) {
        final searchQuery = _safeDecode(url.substring(9)); // הסרת "search://"
        await _performSearch(context, searchQuery);
        return true;
      }

      // בדיקה אם זה קישור לספר
      if (url.startsWith('book://')) {
        final bookUrl = url.substring(7); // הסרת "book://"
        
        String bookTitle;
        String? headerName;
        
        // בדיקה אם יש כותרת ספציפית
        if (bookUrl.contains('#')) {
          final parts = bookUrl.split('#');
          bookTitle = _safeDecode(parts[0]);
          
          // טיפול במבנה תלמודי: ספר#דף#צד
          if (parts.length >= 2) {
            if (parts.length == 3) {
              // מבנה מלא: ספר#דף#צד
              headerName = _safeDecode('${parts[1]} ${parts[2]}');
            } else {
              // מבנה רגיל: ספר#כותרת
              headerName = _safeDecode(parts[1]);
            }
          }
        } else {
          bookTitle = _safeDecode(bookUrl);
        }
        
        await _openBookWithHeader(context, bookTitle, headerName, openBookCallback);
        return true;
      }

      // אם זה לא קישור שאנחנו מטפלים בו, נחזיר false
      return false;
    } catch (e, stackTrace) {
      debugPrint('שגיאה בטיפול בקישור: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // הצגת הודעת שגיאה למשתמש
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בפתיחת הקישור: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      return false;
    }
  }

  /// מנווט לכותרת באותו ספר הנוכחי
  static Future<void> _navigateToHeader(BuildContext context, String headerName) async {
    try {
      // נקבל את הספר הנוכחי מה-BLoC
      final textBookBloc = context.read<TextBookBloc>();
      final state = textBookBloc.state;
      
      if (state is! TextBookLoaded) {
        throw Exception('לא ניתן לנווט - הספר לא נטען');
      }

      // חיפוש הכותרת בתוכן הספציפי
      final index = await _findHeaderIndex(state.book, headerName);
      
      if (index != null) {
        // ניווט לאינדקס שנמצא
        state.scrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.ease,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('נווט ל: $headerName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('לא נמצאה הכותרת: $headerName');
      }
    } catch (e) {
      debugPrint('שגיאה בניווט לכותרת: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('לא ניתן לנווט לכותרת: $headerName'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// פותח ספר ומנווט לכותרת ספציפית (אם צוינה)
  static Future<void> _openBookWithHeader(
    BuildContext context,
    String bookTitle,
    String? headerName,
    Function(TextBookTab) openBookCallback,
  ) async {
    try {
      // חיפוש הספר בספרייה
      final library = await DataRepository.instance.library;
      
      // קבלת רשימת כל הספרים לבדיקה
      final allBooks = await library.getAllBooks();
      
      final foundBook = await library.findBookByTitle(bookTitle, TextBook);
      
      if (foundBook == null) {
        // נסה לחפש בלי להגביל לטיפוס TextBook
        final anyBook = await library.findBookByTitle(bookTitle, null);
        
        if (anyBook != null) {
          throw Exception('הספר "$bookTitle" נמצא אבל הוא מטיפוס ${anyBook.runtimeType}, לא TextBook');
        }
        
        // הצגת רשימת ספרים זמינים למשתמש
        final availableBooks = allBooks.take(10).map((b) => b.title).join(', ');
        throw Exception('לא נמצא ספר בשם: "$bookTitle".\nספרים זמינים (דוגמאות): $availableBooks');
      }

      // וידוא שזה TextBook
      if (foundBook is! TextBook) {
        throw Exception('הספר $bookTitle אינו ספר טקסט');
      }

      final book = foundBook as TextBook;
      int startIndex = 0;
      
      // אם צוינה כותרת, נחפש את האינדקס שלה
      if (headerName != null && headerName.isNotEmpty) {
        final headerIndex = await _findHeaderIndex(book, headerName);
        if (headerIndex != null) {
          startIndex = headerIndex;
        } else {
          // אם לא נמצאה הכותרת, נציג אזהרה אבל עדיין נפתח את הספר
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('לא נמצאה הכותרת "$headerName" בספר $bookTitle, פותח את תחילת הספר'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      // פתיחת הספר
      final tab = TextBookTab(
        book: book,
        index: startIndex,
        openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
            (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
      );
      
      openBookCallback(tab);
      
      if (context.mounted && headerName != null && headerName.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('פתח ספר: $bookTitle${headerName != null ? ' - $headerName' : ''}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('שגיאה בפתיחת ספר: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('לא ניתן לפתוח את הספר: $bookTitle'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// מחפש את האינדקס של כותרת בספר
  static Future<int?> _findHeaderIndex(TextBook book, String headerName) async {
    try {
      // קבלת תוכן הספציפי
      final tableOfContents = await book.tableOfContents;
      
      // חיפוש בתוכן העניינים
      for (final entry in tableOfContents) {
        if (isHeaderMatch(entry.text, headerName)) {
          return entry.index;
        }
      }

      // אם לא נמצא בתוכן העניינים, נחפש בתוכן הספר עצמו
      final content = await book.text;
      final lines = content.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        // הסרת תגי HTML לחיפוש נקי
        final cleanLine = line.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        
        if (isHeaderMatch(cleanLine, headerName)) {
          return i;
        }
      }

      return null;
    } catch (e) {
      debugPrint('שגיאה בחיפוש כותרת: $e');
      return null;
    }
  }

  /// מבצע חיפוש במערכת
  static Future<void> _performSearch(BuildContext context, String query) async {
    try {
      // כאן נוכל להשתמש במערכת החיפוש הקיימת
      // לעת עתה נציג הודעה פשוטה
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('מחפש: $query'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'פתח חיפוש',
              onPressed: () {
                // כאן ניתן לפתוח את מסך החיפוש עם השאילתה
                // Navigator.of(context).pushNamed('/search', arguments: query);
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('שגיאה בחיפוש: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בחיפוש: $query'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// בדיקה אם טקסט תואם לכותרת המבוקשת
  static bool isHeaderMatch(String text, String headerName) {
    // ניקוי הטקסטים לצורך השוואה
    final cleanText = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cleanHeader = headerName.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // השוואה מדויקת
    if (cleanText == cleanHeader) {
      return true;
    }
    
    // השוואה ללא רגישות לרווחים
    if (cleanText.replaceAll(' ', '') == cleanHeader.replaceAll(' ', '')) {
      return true;
    }
    
    // בדיקה אם הכותרת מכילה את הטקסט המבוקש
    if (cleanText.contains(cleanHeader)) {
      return true;
    }
    
    // בדיקה הפוכה - אם הטקסט המבוקש מכיל את הכותרת
    if (cleanHeader.contains(cleanText)) {
      return true;
    }
    
    return false;
  }
}

/// Widget לתצוגה מקדימה של קישור
class _PreviewOverlay extends StatefulWidget {
  final Offset position;
  final String bookTitle;
  final List<String> lines;
  final int startIndex;
  final VoidCallback onClose;

  const _PreviewOverlay({
    required this.position,
    required this.bookTitle,
    required this.lines,
    required this.startIndex,
    required this.onClose,
  });

  @override
  State<_PreviewOverlay> createState() => _PreviewOverlayState();
}

class _PreviewOverlayState extends State<_PreviewOverlay> {
  final ItemScrollController _scrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    // ניווט לאינדקס הנכון אחרי בניית הווידג'ט
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.isAttached && widget.startIndex > 0) {
        _scrollController.jumpTo(index: widget.startIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const overlayWidth = 400.0;
    const overlayHeight = 500.0;

    // חישוב מיקום החלון
    double left = widget.position.dx;
    double top = widget.position.dy;

    // וידוא שהחלון לא יוצא מהמסך
    if (left + overlayWidth > screenSize.width) {
      left = screenSize.width - overlayWidth - 20;
    }
    if (top + overlayHeight > screenSize.height) {
      top = screenSize.height - overlayHeight - 20;
    }
    if (left < 20) left = 20;
    if (top < 20) top = 20;

    return Stack(
      children: [
        // רקע שקוף לסגירה בלחיצה
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        // החלון המרחף
        Positioned(
          left: left,
          top: top,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: overlayWidth,
              height: overlayHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  // כותרת
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.bookTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                  // תוכן
                  Expanded(
                    child: ScrollablePositionedList.builder(
                      itemScrollController: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.lines.length,
                      itemBuilder: (context, index) {
                        final line = widget.lines[index];
                        if (line.trim().isEmpty) {
                          return const SizedBox(height: 8);
                        }

                        // הדגשת השורה הנוכחית
                        final isHighlighted = index == widget.startIndex;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: isHighlighted
                              ? BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  ),
                                )
                              : null,
                          child: HtmlWidget(
                            '''
                            <div style="text-align: justify; direction: rtl;">
                              ${utils.formatTextWithParentheses(line)}
                            </div>
                            ''',
                            textStyle: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: isHighlighted 
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}