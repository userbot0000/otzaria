import 'package:flutter/material.dart';
import 'package:otzaria/utils/word_dictionary.dart';
import 'package:otzaria/utils/auto_link_processor.dart';

/// מסך הגדרות מילון המילים לקישורים אוטומטיים
class WordDictionarySettingsScreen extends StatefulWidget {
  const WordDictionarySettingsScreen({super.key});

  @override
  State<WordDictionarySettingsScreen> createState() => _WordDictionarySettingsScreenState();
}

class _WordDictionarySettingsScreenState extends State<WordDictionarySettingsScreen> {
  Map<String, WordLink> _dictionary = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDictionary();
  }

  Future<void> _loadDictionary() async {
    try {
      await WordDictionary.instance.loadDictionary();
      setState(() {
        _dictionary = WordDictionary.instance.getAllWords();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת המילון: $e')),
        );
      }
    }
  }

  List<MapEntry<String, WordLink>> get _filteredEntries {
    if (_searchQuery.isEmpty) {
      return _dictionary.entries.toList();
    }
    return _dictionary.entries
        .where((entry) =>
            entry.key.contains(_searchQuery) ||
            entry.value.bookTitle.contains(_searchQuery) ||
            entry.value.description.contains(_searchQuery))
        .toList();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מילון מילים לקישורים'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
            tooltip: 'מידע',
          ),
        ],
      ),
      body: Column(
        children: [
          // סרגל חיפוש
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'חיפוש במילון',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // סטטיסטיקות
          if (!_isLoading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('סה"כ מילים', _dictionary.length.toString()),
                  _buildStatItem('ספרים', _dictionary.values.where((l) => l.type == LinkType.book).length.toString()),
                  _buildStatItem('פירושים', _dictionary.values.where((l) => l.type == LinkType.commentary).length.toString()),
                  _buildStatItem('מושגים', _dictionary.values.where((l) => l.type == LinkType.concept).length.toString()),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // רשימת המילים
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                    ? const Center(
                        child: Text(
                          'לא נמצאו מילים במילון',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredEntries[index];
                          return _buildWordTile(entry.key, entry.value);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildWordTile(String word, WordLink link) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        title: Text(
          word,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${link.bookTitle} (${_getTypeDisplayName(link.type)})'),
            if (link.description.isNotEmpty)
              Text(
                link.description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(link.type),
          child: Icon(
            _getTypeIcon(link.type),
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  String _getTypeDisplayName(LinkType type) {
    switch (type) {
      case LinkType.book:
        return 'ספר';
      case LinkType.commentary:
        return 'פירוש';
      case LinkType.concept:
        return 'מושג';
      case LinkType.reference:
        return 'הפניה';
    }
  }

  Color _getTypeColor(LinkType type) {
    switch (type) {
      case LinkType.book:
        return Colors.blue;
      case LinkType.commentary:
        return Colors.green;
      case LinkType.concept:
        return Colors.orange;
      case LinkType.reference:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(LinkType type) {
    switch (type) {
      case LinkType.book:
        return Icons.book;
      case LinkType.commentary:
        return Icons.comment;
      case LinkType.concept:
        return Icons.lightbulb;
      case LinkType.reference:
        return Icons.link;
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מידע על מילון המילים'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'מילון המילים מוסיף קישורים אוטומטיים לטקסט הספרים.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('המילון מנוהל אוטומטית על ידי המערכת וכולל:'),
              SizedBox(height: 8),
              Text('• מסכתות התלמוד'),
              Text('• ספרי תנ"ך'),
              Text('• מפרשים ראשונים ואחרונים'),
              Text('• מושגים הלכתיים'),
              SizedBox(height: 16),
              Text(
                'המילון מתעדכן באופן אוטומטי עם עדכוני המערכת.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }
}

