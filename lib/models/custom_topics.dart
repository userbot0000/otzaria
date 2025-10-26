/// מודל לנושאים מותאמים אישית
/// כל נושא מכיל רשימה ספציפית של ספרים

class CustomTopic {
  final String name;
  final String displayName;
  final List<String> bookTitles;
  final String? description;
  final int order;

  const CustomTopic({
    required this.name,
    required this.displayName,
    required this.bookTitles,
    this.description,
    this.order = 999,
  });

  factory CustomTopic.fromJson(Map<String, dynamic> json) {
    return CustomTopic(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      bookTitles: List<String>.from(json['bookTitles'] as List),
      description: json['description'] as String?,
      order: json['order'] as int? ?? 999,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'bookTitles': bookTitles,
      'description': description,
      'order': order,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomTopic &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// מנהל הנושאים המותאמים אישית
class CustomTopicsManager {
  static const String _configFileName = 'custom_topics.json';
  
  List<CustomTopic> _topics = [];
  
  List<CustomTopic> get topics => List.unmodifiable(_topics);

  /// טוען את הנושאים המותאמים אישית מקובץ ההגדרות
  Future<void> loadCustomTopics() async {
    try {
      // לעת עתה נשתמש בהגדרות ברירת מחדל
      // בעתיד ניתן לטעון מקובץ JSON או מבסיס נתונים
      _topics = _getDefaultTopics();
      
      // מיון לפי סדר
      _topics.sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      // אם יש שגיאה, נשתמש בהגדרות ברירת מחדל
      _topics = _getDefaultTopics();
    }
  }

  /// מחזיר את הנושאים המותאמים אישית לפי ברירת מחדל
  List<CustomTopic> _getDefaultTopics() {
    return [
      const CustomTopic(
        name: 'pesach',
        displayName: 'פסח',
        order: 1,
        description: 'ספרים הקשורים לחג הפסח',
        bookTitles: [
          'הגדה',
          'פסח',
          'חמץ',
          'מצה',
          'יציאת מצרים',
          'ליל שימורים',
          'ארבע כוסות',
          'מרור',
          'אפיקומן',
          'חירות',
        ],
      ),
      const CustomTopic(
        name: 'shabbat',
        displayName: 'שבת',
        order: 2,
        description: 'ספרים העוסקים בהלכות ומנהגי שבת',
        bookTitles: [
          'הלכות שבת',
          'שמירת שבת כהלכתה',
          'אור השבת',
          'שבת במלכותה',
          'נר מצוה',
          'שולחן שבת',
        ],
      ),
      const CustomTopic(
        name: 'rosh_hashana',
        displayName: 'ראש השנה',
        order: 3,
        description: 'ספרים לחג ראש השנה',
        bookTitles: [
          'הלכות ראש השנה',
          'ימים נוראים',
          'תפילות ראש השנה',
          'מחזור לראש השנה',
          'שופר ותקיעותיו',
        ],
      ),
      const CustomTopic(
        name: 'yom_kippur',
        displayName: 'יום כיפור',
        order: 4,
        description: 'ספרים ליום הכיפורים',
        bookTitles: [
          'הלכות יום הכיפורים',
          'עבודת יום הכיפור',
          'מחזור ליום כיפור',
          'תפילות יום כיפור',
          'וידוי וסליחות',
        ],
      ),
      const CustomTopic(
        name: 'sukkot',
        displayName: 'סוכות',
        order: 5,
        description: 'ספרים לחג הסוכות',
        bookTitles: [
          'הלכות סוכה',
          'הלכות לולב',
          'ארבעת המינים',
          'חג הסוכות',
          'שמחת בית השואבה',
        ],
      ),
      const CustomTopic(
        name: 'chanukah',
        displayName: 'חנוכה',
        order: 6,
        description: 'ספרים לחג החנוכה',
        bookTitles: [
          'הלכות חנוכה',
          'נר חנוכה',
          'מעשה חנוכה',
          'נסי חנוכה',
          'אור החנוכה',
        ],
      ),
      const CustomTopic(
        name: 'purim',
        displayName: 'פורים',
        order: 7,
        description: 'ספרים לחג הפורים',
        bookTitles: [
          'מגילת אסתר',
          'הלכות פורים',
          'נס פורים',
          'משלוח מנות',
          'מתנות לאביונים',
        ],
      ),
      const CustomTopic(
        name: 'tefila',
        displayName: 'תפילה',
        order: 8,
        description: 'ספרי תפילה והלכותיה',
        bookTitles: [
          'סידור תפילה',
          'הלכות תפילה',
          'כוונת התפילה',
          'תפילת השחר',
          'תפילת המנחה',
          'תפילת הערב',
          'קריאת שמע',
        ],
      ),
      const CustomTopic(
        name: 'kashrut',
        displayName: 'כשרות',
        order: 9,
        description: 'ספרים העוסקים בהלכות כשרות',
        bookTitles: [
          'הלכות כשרות',
          'בדיקת מזון',
          'שחיטה וטריפות',
          'בשר וחלב',
          'יין נסך',
          'פת עכו"ם',
        ],
      ),
      const CustomTopic(
        name: 'family_purity',
        displayName: 'טהרת המשפחה',
        order: 10,
        description: 'ספרים בנושא טהרת המשפחה',
        bookTitles: [
          'הלכות נידה',
          'טהרת המשפחה',
          'דיני טבילה',
          'הלכות אישות',
          'קדושת הבית',
          'מקווה ישראל',
        ],
      ),
      const CustomTopic(
        name: 'lifecycle',
        displayName: 'מחזור החיים',
        order: 11,
        description: 'ספרים העוסקים באירועי מחזור החיים',
        bookTitles: [
          'הלכות מילה',
          'פדיון הבן',
          'בר מצווה',
          'הלכות חתונה',
          'שבע ברכות',
          'הלכות אבלות',
          'קדיש ויהרצייט',
          'זכרון נשמות',
        ],
      ),
      const CustomTopic(
        name: 'study_methods',
        displayName: 'שיטות לימוד',
        order: 12,
        description: 'ספרים על שיטות לימוד התורה',
        bookTitles: [
          'דרכי הלימוד',
          'עיון והבנה',
          'חזרה וזכירה',
          'לימוד בחברותא',
          'הבנת הסוגיה',
          'פלפול ולוגיקה',
        ],
      ),
    ];
  }

  /// מחזיר רשימת ספרים לנושא מסוים
  List<String> getBooksForTopic(String topicName) {
    final topic = _topics.firstWhere(
      (t) => t.name == topicName,
      orElse: () => const CustomTopic(
        name: '',
        displayName: '',
        bookTitles: [],
      ),
    );
    return topic.bookTitles;
  }

  /// בדיקה האם ספר שייך לנושא מסוים
  bool isBookInTopic(String bookTitle, String topicName) {
    final booksInTopic = getBooksForTopic(topicName);
    final normalizedBookTitle = bookTitle.toLowerCase().trim();
    
    return booksInTopic.any((title) {
      final normalizedTitle = title.toLowerCase().trim();
      // בדיקה אם אחד מהמילים בכותרת הספר מכיל את המילה מהנושא או להיפך
      return normalizedBookTitle.contains(normalizedTitle) || 
             normalizedTitle.contains(normalizedBookTitle) ||
             _containsWords(normalizedBookTitle, normalizedTitle);
    });
  }

  /// בדיקה אם יש מילים משותפות בין שתי מחרוזות
  bool _containsWords(String text1, String text2) {
    final words1 = text1.split(' ').where((w) => w.length > 2).toSet();
    final words2 = text2.split(' ').where((w) => w.length > 2).toSet();
    return words1.intersection(words2).isNotEmpty;
  }

  /// מחזיר את כל הנושאים שספר מסוים שייך אליהם
  List<String> getTopicsForBook(String bookTitle) {
    return _topics
        .where((topic) => isBookInTopic(bookTitle, topic.name))
        .map((topic) => topic.displayName)
        .toList();
  }
}