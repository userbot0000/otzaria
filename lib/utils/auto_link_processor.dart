/// מעבד טקסט ומוסיף קישורים אוטומטיים
class AutoLinkProcessor {
  static AutoLinkProcessor? _instance;
  static AutoLinkProcessor get instance => _instance ??= AutoLinkProcessor._();

  AutoLinkProcessor._();

  /// מעבד טקסט HTML ומוסיף קישורים אוטומטיים
  String processText(
    String htmlText, {
    bool enableAutoLinks = true,
    bool fileLinksOnly = false,
    bool excludeExistingLinks = true,
  }) {
    // אם הקישורים מושבתים לחלוטין, נסיר את כל הקישורים
    if (!enableAutoLinks) {
      return _removeAllLinks(htmlText);
    }

    // אם מוגדר "קישורים מהקובץ בלבד", נשמור קישורים קיימים אבל לא נוסיף חדשים
    if (fileLinksOnly) {
      return htmlText; // קישורים קיימים יישארו, לא נוסיף חדשים
    }

    // כאן נוסיף את הזיהוי האוטומטי החדש לפי הכללים שלך
    return _processAutoLinks(htmlText, excludeExistingLinks);
  }

  /// מעבד קישורים אוטומטיים לפי הכללים החדשים
  String _processAutoLinks(String htmlText, bool excludeExistingLinks) {
    // כאן נבנה את הזיהוי החדש לפי הכללים שתסביר
    return htmlText;
  }

  /// מסיר את כל הקישורים מהטקסט (משאיר רק את התוכן)
  String _removeAllLinks(String htmlText) {
    // מסיר תגי <a> אבל משאיר את התוכן שלהם
    return htmlText.replaceAllMapped(
      RegExp(r'<a\s[^>]*>(.*?)</a>', dotAll: true),
      (match) => match.group(1) ?? '',
    );
  }
}
