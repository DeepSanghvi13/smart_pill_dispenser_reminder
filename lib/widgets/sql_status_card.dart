import 'package:flutter/material.dart';

class SqlStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final String? subtitle;
  final Color color;
  final Widget? trailing;

  const SqlStatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    required this.color,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing ??
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      ),
    );
  }
}
<<<<<<< HEAD

=======
>>>>>>> a81a2003f258a402588cbb6d9cbe91bc18214c26
