import 'package:flutter/material.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:otzaria/models/books.dart';

class LibraryListView extends StatelessWidget {
  final Future<List<Widget>> items;
  final Function(Book)? onBookSelected;

  const LibraryListView({
    super.key,
    required this.items,
    this.onBookSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: items,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Row(
            children: [
              // רשימת הספרים - שליש מהמסך
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final item = snapshot.data![index];
                      if (item is BookListItem) {
                        return item;
                      } else if (item is CategoryListItem) {
                        return item;
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              // פרטי הספר - שני שליש מהמסך
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const BookPlaceholderPanel(),
                ),
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class BookListItem extends StatelessWidget {
  final Book book;
  final VoidCallback onBookClickCallback;
  final bool showTopics;
  final Function(Book)? onBookSelected;

  const BookListItem({
    super.key,
    required this.book,
    required this.onBookClickCallback,
    this.showTopics = false,
    this.onBookSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: GestureDetector(
        onTap: () {
          // לחיצה אחת - רק בחירה לתצוגה מקדימה
          onBookSelected?.call(book);
        },
        onDoubleTap: () {
          // לחיצה כפולה - פתיחה בעיון
          onBookClickCallback();
        },
        child: ListTile(
          leading: _buildBookIcon(context),
          title: Text(
            book.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (book.author != null && book.author!.isNotEmpty)
                Text(
                  book.author!,
                  style: const TextStyle(fontSize: 12),
                ),
              if (showTopics && book.topics.isNotEmpty)
                Text(
                  book.topics,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          trailing: book.heShortDesc != null && book.heShortDesc!.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {},
                  tooltip: book.heShortDesc,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBookIcon(BuildContext context) {
    if (book is PdfBook) {
      return Icon(
        Icons.picture_as_pdf,
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
      );
    } else if (book is ExternalBook) {
      final externalBook = book as ExternalBook;
      return Image.asset(
        externalBook.link.toString().contains('tablet.otzar.org')
            ? 'assets/logos/otzar.ico'
            : 'assets/logos/hebrew_books.png',
        width: 20,
        height: 20,
        fit: BoxFit.contain,
      );
    } else {
      return Icon(
        Icons.article,
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
      );
    }
  }
}

class CategoryListItem extends StatefulWidget {
  final Category category;
  final VoidCallback onCategoryClickCallback;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.onCategoryClickCallback,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  @override
  State<CategoryListItem> createState() => _CategoryListItemState();
}

class _CategoryListItemState extends State<CategoryListItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          widget.isExpanded ? Icons.folder_open : Icons.folder,
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
        ),
        title: Text(
          widget.category.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.category.shortDescription.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {},
                tooltip: widget.category.shortDescription,
              ),
            Icon(
              widget.isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
          ],
        ),
        onTap: () {
          if (widget.onToggleExpanded != null) {
            widget.onToggleExpanded!();
          } else {
            widget.onCategoryClickCallback();
          }
        },
      ),
    );
  }
}

class BookViewerPanel extends StatelessWidget {
  final Book book;
  final VoidCallback? onOpenBook;

  const BookViewerPanel({
    super.key,
    required this.book,
    this.onOpenBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // כותרת הספר
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (book.author != null && book.author!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    book.author!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          // תוכן הספר
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'תצוגה מקדימה של הספר',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: BookContentPreview(book: book),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // כפתור פתיחה מלאה
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onOpenBook,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('פתח במסך עיון'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookContentPreview extends StatefulWidget {
  final Book book;

  const BookContentPreview({
    super.key,
    required this.book,
  });

  @override
  State<BookContentPreview> createState() => _BookContentPreviewState();
}

class _BookContentPreviewState extends State<BookContentPreview> {
  List<String>? _bookContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookContent();
  }

  @override
  void didUpdateWidget(BookContentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book != widget.book) {
      _loadBookContent();
    }
  }

  Future<void> _loadBookContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.book is TextBook) {
        final textBook = widget.book as TextBook;
        // נטען רק את התחלת הספר (50 שורות ראשונות)
        final content = await _loadTextBookContent(textBook);
        setState(() {
          _bookContent = content;
          _isLoading = false;
        });
      } else if (widget.book is PdfBook) {
        setState(() {
          _bookContent = ['זהו ספר PDF. לא ניתן להציג תצוגה מקדימה של תוכן PDF.'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _bookContent = ['סוג ספר לא נתמך לתצוגה מקדימה.'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'שגיאה בטעינת הספר: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _loadTextBookContent(TextBook book) async {
    try {
      // נשתמש ב-API של TextBook לטעינת התוכן
      final content = await book.text;
      final lines = content.split('\n');
      
      // נחזיר רק את 50 השורות הראשונות
      return lines.take(50).where((line) => line.trim().isNotEmpty).toList();
    } catch (e) {
      return ['שגיאה בקריאת הספר: $e'];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('טוען תוכן הספר...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.book.heShortDesc != null && widget.book.heShortDesc!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'תיאור הספר:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.book.heShortDesc!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'תוכן הספר:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (_bookContent != null)
            ...(_bookContent!.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ))),
          if (_bookContent != null && _bookContent!.length >= 50) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '... המשך הספר זמין בתצוגה המלאה',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BookPlaceholderPanel extends StatelessWidget {
  const BookPlaceholderPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'בחר ספר מהרשימה כדי לראות תצוגה מקדימה',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}