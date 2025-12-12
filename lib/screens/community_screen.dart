import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'author': 'Ahmad',
      'avatar': 'A',
      'content':
          'Just completed reading Surah Al-Kahf this Friday. SubhanAllah, the story of the companions of the cave is so inspiring! 📖',
      'likes': 45,
      'comments': 12,
      'time': '2h ago',
      'liked': false,
    },
    {
      'id': 2,
      'author': 'Fatima',
      'avatar': 'F',
      'content':
          'Alhamdulillah, started my 30-day Quran challenge today. May Allah give us all the strength to complete it. Who wants to join? 🤲',
      'likes': 128,
      'comments': 34,
      'time': '5h ago',
      'liked': true,
    },
    {
      'id': 3,
      'author': 'Ibrahim',
      'avatar': 'I',
      'content':
          '"The best among you are those who learn the Quran and teach it." - Prophet Muhammad ﷺ\n\nLet\'s spread this beautiful message! 🌙',
      'likes': 256,
      'comments': 45,
      'time': '1d ago',
      'liked': false,
    },
  ];

  final List<Map<String, dynamic>> _challenges = [
    {
      'title': '30-Day Quran Challenge',
      'description': 'Read one Juz daily for 30 days',
      'participants': 1547,
      'daysLeft': 25,
      'progress': 0.17,
      'icon': Icons.menu_book,
    },
    {
      'title': 'Fajr Warriors',
      'description': 'Pray Fajr on time for 40 days',
      'participants': 892,
      'daysLeft': 32,
      'progress': 0.2,
      'icon': Icons.wb_sunny,
    },
    {
      'title': 'Memorize Al-Mulk',
      'description': 'Memorize Surah Al-Mulk in 2 weeks',
      'participants': 423,
      'daysLeft': 10,
      'progress': 0.3,
      'icon': Icons.psychology,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Feed', icon: Icon(Icons.dynamic_feed)),
            Tab(text: 'Challenges', icon: Icon(Icons.emoji_events)),
            Tab(text: 'Groups', icon: Icon(Icons.groups)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(),
          _buildChallengesTab(),
          _buildGroupsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFeedTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _buildPostCard(post, index);
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text(
                    post['avatar'],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['author'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        post['time'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            Text(
              post['content'],
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                _buildActionButton(
                  icon: post['liked'] ? Icons.favorite : Icons.favorite_border,
                  label: '${post['likes']}',
                  color: post['liked'] ? Colors.red : null,
                  onTap: () {
                    setState(() {
                      _posts[index]['liked'] = !post['liked'];
                      _posts[index]['likes'] += post['liked'] ? -1 : 1;
                    });
                  },
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${post['comments']}',
                  onTap: () {},
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    SharePlus.instance
                        .share(ShareParams(text: post['content']));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: color ?? Colors.grey[600]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Active Challenges',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._challenges.map((challenge) => _buildChallengeCard(challenge)),
        const SizedBox(height: 24),
        const Text(
          'Create Your Challenge',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Create challenge feature coming soon!')),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_circle_outline,
                        color: Colors.teal, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start a New Challenge',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Invite friends to join your journey',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(challenge['icon'] as IconData, color: Colors.teal),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge['title'],
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        challenge['description'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: challenge['progress'] as double,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${challenge['participants']} participants',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  '${challenge['daysLeft']} days left',
                  style: const TextStyle(
                      color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Joined: ${challenge['title']}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Join Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsTab() {
    final groups = [
      {'name': 'Quran Study Circle', 'members': 234, 'icon': Icons.menu_book},
      {'name': 'Sisters Only', 'members': 156, 'icon': Icons.group},
      {'name': 'New Muslims Support', 'members': 89, 'icon': Icons.favorite},
      {'name': 'Islamic History', 'members': 312, 'icon': Icons.history_edu},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Your Groups',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...groups.map((group) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(group['icon'] as IconData, color: Colors.white),
                ),
                title: Text(group['name'] as String),
                subtitle: Text('${group['members']} members'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening ${group['name']}...')),
                  );
                },
              ),
            )),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Browse groups feature coming soon!')),
            );
          },
          icon: const Icon(Icons.explore),
          label: const Text('Browse All Groups'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _showCreatePostDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create Post',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share your thoughts with the community...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      _posts.insert(0, {
                        'id': _posts.length + 1,
                        'author': AuthService.currentUser?['name'] ?? 'You',
                        'avatar': (AuthService.currentUser?['name'] ?? 'Y')[0],
                        'content': controller.text,
                        'likes': 0,
                        'comments': 0,
                        'time': 'Just now',
                        'liked': false,
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Post'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
