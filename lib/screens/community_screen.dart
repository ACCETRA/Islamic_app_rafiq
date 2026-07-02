import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

// ==================== COMMUNITY SCREEN ====================
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Your Progress',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.share, color: colorScheme.primary),
                title: const Text('Share Quran Reading'),
                subtitle: const Text('Share your current surah progress'),
                onTap: () {
                  const text =
                      'I just read Surah Al-Fatihah in the Islamic Companion App! #Quran #Islam';
                  SharePlus.instance.share(ShareParams(text: text));
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.workspace_premium_rounded, color: Colors.orange),
                title: const Text('Achievements'),
                subtitle: const Text('View your spiritual milestones'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Achievement system coming soon!')),
                  );
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.group, color: Colors.blue),
                title: const Text('Study Groups'),
                subtitle: const Text('Join local or virtual study circles'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Study groups feature coming soon!')),
                  );
                },
              ),
            ),
            const Spacer(),
            const Center(
              child: Text(
                'Community features are in development',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

