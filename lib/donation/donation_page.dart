import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('תרומה לפרויקט אוצריא'),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              _buildHeaderSection(context),
              
              // Main Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Why Donate Section
                    _buildWhyDonateSection(context),
                    const SizedBox(height: 40),
                    
                    // Payment Methods
                    _buildPaymentMethodsSection(context),
                    const SizedBox(height: 40),
                    
                    // Impact Section
                    _buildImpactSection(context),
                    const SizedBox(height: 40),
                    
                    // Memorial Section
                    _buildMemorialSection(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/icon/icon.png',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'תרומה לפרויקט אוצריא',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            const Text(
              'עזרו לנו להמשיך לפתח ולשפר את המאגר התורני החינמי',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyDonateSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'למה לתרום?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildReasonItem(
              icon: Icons.book,
              title: 'מאגר ספרים רחב',
              description: 'אלפי ספרי קודש זמינים בחינם לכל הציבור',
            ),
            _buildReasonItem(
              icon: Icons.phone_android,
              title: 'נגישות מלאה',
              description: 'זמין במחשב ובנייד, בכל מקום ובכל זמן',
            ),
            _buildReasonItem(
              icon: Icons.update,
              title: 'פיתוח מתמיד',
              description: 'עדכונים קבועים ותכונות חדשות',
            ),
            _buildReasonItem(
              icon: Icons.group,
              title: 'קהילה פעילה',
              description: 'מפתחים ומתנדבים הפועלים למען הציבור',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'דרכי תרומה',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // PayPal
            _buildPaymentButton(
              title: 'PayPal',
              subtitle: 'תרומה מאובטחת דרך PayPal',
              icon: FontAwesomeIcons.paypal,
              color: const Color(0xFF0070BA),
              onTap: () => _launchPayPal(),
            ),
            const SizedBox(height: 16),
            
            // Credit Card
            _buildPaymentButton(
              title: 'כרטיס אשראי',
              subtitle: 'תשלום מאובטח בכרטיס אשראי',
              icon: FontAwesomeIcons.creditCard,
              color: const Color(0xFF28A745),
              onTap: () => _launchCreditCard(),
            ),
            const SizedBox(height: 16),
            
            // Bank Transfer
            _buildPaymentButton(
              title: 'העברה בנקאית',
              subtitle: 'העברה ישירה לחשבון הפרויקט',
              icon: FontAwesomeIcons.university,
              color: const Color(0xFF6C757D),
              onTap: () => _showBankDetails(context),
            ),
            const SizedBox(height: 16),
            
            // Crypto
            _buildPaymentButton(
              title: 'מטבעות דיגיטליים',
              subtitle: 'תרומה במטבעות קריפטו',
              icon: FontAwesomeIcons.bitcoin,
              color: const Color(0xFFF7931A),
              onTap: () => _showCryptoDetails(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'השפעת התרומה',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildImpactCard(
                    amount: '₪50',
                    description: 'מממן שרת למשך חודש',
                    icon: Icons.cloud,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImpactCard(
                    amount: '₪200',
                    description: 'מוסיף ספר חדש למאגר',
                    icon: Icons.library_books,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildImpactCard(
                    amount: '₪500',
                    description: 'מפתח תכונה חדשה',
                    icon: Icons.code,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImpactCard(
                    amount: '₪1000',
                    description: 'תומך בפרויקט לשנה',
                    icon: Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactCard({
    required String amount,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 32),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorialSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.orange[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'תרומה לזכר ולעילוי נשמת',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'ניתן לתרום לזכר יקיריכם ולהנציח את שמם במאגר התורני. התרומה תסייע בפיתוח התוכנה ובהוספת ספרים חדשים.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchMemorialForm(),
                icon: const Icon(Icons.email),
                label: const Text('צור קשר לתרומה לזכר'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Payment Methods
  Future<void> _launchPayPal() async {
    const url = 'https://www.paypal.com/donate/?hosted_button_id=YOUR_PAYPAL_ID';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchCreditCard() async {
    const url = 'https://donate.stripe.com/your-stripe-link';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMemorialForm() async {
    const url = 'https://forms.gle/Dq8bn7mw7he4wtTC9';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showBankDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('פרטי חשבון בנק'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('בנק: בנק לאומי'),
              Text('מספר חשבון: 123-456-789'),
              Text('מספר סניף: 123'),
              Text('שם המוטב: פרויקט אוצריא'),
              SizedBox(height: 16),
              Text(
                'אנא ציינו בהעברה "תרומה לאוצריא"',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('סגור'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCryptoDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('כתובות מטבעות דיגיטליים'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bitcoin (BTC):'),
              Text('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'),
              SizedBox(height: 12),
              Text('Ethereum (ETH):'),
              Text('0x742d35Cc6634C0532925a3b8D4C9db96590645d8'),
              SizedBox(height: 16),
              Text(
                'אנא וודאו את הכתובת לפני השליחה',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('סגור'),
            ),
          ],
        ),
      ),
    );
  }
}