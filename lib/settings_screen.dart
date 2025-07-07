import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart'; // For NeumorphicContainer
import 'edit_profile_screen.dart';
import 'splash_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات والملف الشخصي')),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          NeumorphicContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? 'مستخدم',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildSettingsTile(
            context,
            icon: Icons.edit_outlined,
            title: 'تعديل الملف الشخصي',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.shield_outlined,
            title: 'الأمان وكلمة المرور',
            onTap: () {},
          ),
          const Divider(height: 40),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            color: Colors.redAccent,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: Icon(icon, color: color ?? theme.colorScheme.primary),
          title: Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
