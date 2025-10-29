import 'package:flutter/material.dart';

class TestIconsScreen extends StatelessWidget {
  const TestIconsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final candidateIcons = [
      {'icon': Icons.local_fire_department, 'name': 'local_fire_department', 'color': Colors.orange[700]},
      {'icon': Icons.whatshot, 'name': 'whatshot', 'color': Colors.red[600]},
      {'icon': Icons.fireplace, 'name': 'fireplace', 'color': Colors.brown[600]},
      {'icon': Icons.light_mode, 'name': 'light_mode', 'color': Colors.amber[700]},
      {'icon': Icons.brightness_high, 'name': 'brightness_high', 'color': Colors.yellow[700]},
      {'icon': Icons.flare, 'name': 'flare', 'color': Colors.orange[600]},
      {'icon': Icons.favorite, 'name': 'favorite', 'color': Colors.red[400]},
      {'icon': Icons.star, 'name': 'star', 'color': Colors.amber[600]},
      {'icon': Icons.auto_awesome, 'name': 'auto_awesome', 'color': Colors.purple[400]},
      {'icon': Icons.diamond, 'name': 'diamond', 'color': Colors.blue[400]},
      {'icon': Icons.emoji_events, 'name': 'emoji_events', 'color': Colors.amber[600]},
      {'icon': Icons.volunteer_activism, 'name': 'volunteer_activism', 'color': Colors.green[600]},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('בחירת אייקון לנר זיכרון'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: candidateIcons.length,
            itemBuilder: (context, index) {
              final iconData = candidateIcons[index];
              return Card(
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    // העתק את שם האייקון ללוח
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('נבחר: Icons.${iconData['name']}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        iconData['icon'] as IconData,
                        size: 32,
                        color: iconData['color'] as Color?,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        iconData['name'] as String,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}