import 'package:flutter/material.dart';

class HelpArticlesScreen extends StatefulWidget {
  const HelpArticlesScreen({super.key});

  @override
  State<HelpArticlesScreen> createState() => _HelpArticlesScreenState();
}

class _HelpArticlesScreenState extends State<HelpArticlesScreen> {
  final List<HelpArticle> articles = [
    HelpArticle(
      title: 'How to add a medicine',
      subtitle: 'Steps to add and manage medicines',
      icon: Icons.medication,
      content: '''
Steps to add a new medicine:

1. Navigate to the "Medications" tab from the home screen
2. Click the "+" button to add a new medicine
3. Enter the medicine name and dosage
4. Select the frequency (Once, Twice, Thrice, or Custom)
5. Set the time for each dose
6. Add any special notes or instructions
7. Tap "Save" to add the medicine

Tips:
• Use the exact medicine name for easy identification
• Set reminders 5-10 minutes before taking
• Add notes about food interactions or side effects
      ''',
    ),
    HelpArticle(
      title: 'How reminders work',
      subtitle: 'Understand reminder notifications',
      icon: Icons.notifications_active,
      content: '''
Reminder system explained:

How Reminders are Scheduled:
• Reminders are set based on your medication schedule
• You receive notifications at the scheduled time
• Notifications include the medicine name and dosage

Notification Features:
• Sound alerts to grab your attention
• Vibration to notify you
• Persistent notification until you dismiss it

Managing Reminders:
• Enable/disable reminders in app settings
• Customize notification time offsets
• Set quiet hours if needed

Troubleshooting:
• Ensure notifications are enabled in device settings
• Check if the app has notification permissions
• Restart the app if reminders aren't working
      ''',
    ),
    HelpArticle(
      title: 'Edit or delete medicines',
      subtitle: 'Manage your medicine list',
      icon: Icons.edit,
      content: '''
Editing and Managing Medicines:

To Edit a Medicine:
1. Go to the "Medications" tab
2. Find the medicine you want to edit
3. Tap the medicine card or edit icon
4. Modify the medicine details
5. Save the changes

To Delete a Medicine:
1. Navigate to the "Medications" tab
2. Long-press on the medicine or tap the menu icon
3. Select "Delete" from the options
4. Confirm the deletion

Important Notes:
• Deleting a medicine will remove all its reminders
• You can re-add the medicine anytime
• Keep a backup of important medicine records
• Edit medicines if dosage changes
      ''',
    ),
    HelpArticle(
      title: 'Profile and account help',
      subtitle: 'Manage your profile and account',
      icon: Icons.person,
      content: '''
Profile and Account Management:

Viewing Your Profile:
1. Tap the Profile icon in the navigation menu
2. View your personal information
3. See your medication history

Editing Profile Information:
1. Go to Profile section
2. Tap "Edit Profile"
3. Update your details (name, email, phone)
4. Save the changes

Account Security:
• Use a strong password
• Keep your credentials private
• Logout before leaving shared devices
• Enable two-factor authentication if available

Need More Help:
• Contact support through the app
• Check the FAQ section
• Email us for detailed assistance

Account Settings:
• Manage notification preferences
• Set language preferences
• Control data privacy options
• Clear app cache if experiencing issues
      ''',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Articles'),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return _buildHelpArticleCard(articles[index]);
        },
      ),
    );
  }

  Widget _buildHelpArticleCard(HelpArticle article) {
    return HelpArticleCard(article: article);
  }
}

class HelpArticle {
  final String title;
  final String subtitle;
  final IconData icon;
  final String content;

  HelpArticle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.content,
  });
}

class HelpArticleCard extends StatefulWidget {
  final HelpArticle article;

  const HelpArticleCard({required this.article, super.key});

  @override
  State<HelpArticleCard> createState() => _HelpArticleCardState();
}

class _HelpArticleCardState extends State<HelpArticleCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              widget.article.icon,
              color: Colors.blue,
              size: 28,
            ),
            title: Text(
              widget.article.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(widget.article.subtitle),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.expand_more),
            ),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Text(
                widget.article.content.trim(),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.grey[800],
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
