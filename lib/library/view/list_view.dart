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
                  child: const BookDetailsPanel(),
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
        onTap: () {
          onBookSelected?.call(book);
          onBookClickCallback();
        },
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

class CategoryListItem extends StatelessWidget {
  final Category category;
  final VoidCallback onCategoryClickCallback;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.onCategoryClickCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          Icons.folder,
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
        ),
        title: Text(
          category.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: category.shortDescription.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {},
                tooltip: category.shortDescription,
              )
            : const Icon(Icons.chevron_right),
        onTap: onCategoryClickCallback,
      ),
    );
  }
}

class BookDetailsPanel extends StatelessWidget {
  final Book? selectedBook;
  final Function(Book)? onOpenBook;

  const BookDetailsPanel({
    super.key,
    this.selectedBook,
    this.onOpenBook,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedBook == null) {
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
              'בחר ספר כדי לראות פרטים',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // כותרת הספר
          Text(
            selectedBook!.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // מחבר
          if (selectedBook!.author != null && selectedBook!.author!.isNotEmpty)
            _buildDetailRow(context, 'מחבר:', selectedBook!.author!),

          // תאריך פרסום
          if (selectedBook!.pubDate != null && selectedBook!.pubDate!.isNotEmpty)
            _buildDetailRow(context, 'תאריך פרסום:', selectedBook!.pubDate!),

          // נושאים
          if (selectedBook!.topics.isNotEmpty)
            _buildDetailRow(context, 'נושאים:', selectedBook!.topics),

          // תיאור
          if (selectedBook!.heShortDesc != null &&
              selectedBook!.heShortDesc!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'תיאור:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedBook!.heShortDesc!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // כפתור פתיחה
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (selectedBook != null && onOpenBook != null) {
                  onOpenBook!(selectedBook!);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('פתח ספר'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}