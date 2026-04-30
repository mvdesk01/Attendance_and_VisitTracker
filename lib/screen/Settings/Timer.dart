
import 'package:flutter/material.dart';
import '../Punchremainder/Punchreminderscreennew.dart';
import 'DataDeletionRequestScreen.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "General Settings",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingItem(
              context,
              icon: Icons.notifications_active_outlined,
              title: 'Set Punch In-Out Reminder',
              description: 'Get reminders to punch in and out on time.',
              onTap: () {
                // Navigate to TimerPage when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Uncomment the appropriate screen to navigate
                    // builder: (context) => PunchRemainderScreen(),
                    builder: (context) => AlarmScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text(
              "Account & Privacy",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingItem(
              context,
              icon: Icons.delete_outline,
              title: 'Request Data Deletion',
              description: 'Request permanent deletion of your account and data.',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DataDeletionRequestScreen()));
                // _showDataDeletionDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: Colors.blueAccent,
                ),
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
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.black45,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
