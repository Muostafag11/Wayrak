import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'conversations_screen.dart';
import 'home_tab_driver.dart';
import 'home_tab_merchant.dart';
import 'splash_screen.dart';
import 'settings_screen.dart';
import 'my_shipments_driver_screen.dart'; // Import the new screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _getProfile();
  }

  Future<Map<String, dynamic>> _getProfile() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _switchUser(String email) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await Supabase.instance.client.auth.signOut();
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: 'Zxcvzxcv123',
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('فشل تسجيل الدخول، تأكد من صحة الحساب')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SplashScreen();
        }

        final profileData = snapshot.data!;
        final userType = profileData['user_type'];
        final fullName = profileData['full_name'] ?? 'مستخدم';
        final isVerified = profileData['is_verified'] ?? false;

        Widget homeTab;
        Widget shipmentsTab;

        if (userType == 'merchant') {
          homeTab = HomeTabMerchant(profileData: profileData);
          shipmentsTab = const Center(
            child: Text('All Merchant Shipments Page'),
          );
        } else {
          homeTab = HomeTabDriver(profileData: profileData);
          shipmentsTab = const MyShipmentsDriverScreen();
        }

        final List<Widget> widgetOptions = <Widget>[
          homeTab,
          shipmentsTab,
          const ConversationsScreen(),
          const SettingsScreen(),
        ];

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: theme.scaffoldBackgroundColor.withOpacity(0.7),
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.shadow.withOpacity(0.5),
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'أهلاً بك، $fullName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isVerified)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.verified,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                  ),
              ],
            ),
            centerTitle: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.swap_horiz, color: Colors.white),
                onSelected: _switchUser,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'muostafa@internet.ru',
                    child: Text('التبديل إلى التاجر'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'ghani@internet.ru',
                    child: Text('التبديل إلى السائق'),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _signOut,
              ),
            ],
          ),
          body: IndexedStack(index: _selectedIndex, children: widgetOptions),
          bottomNavigationBar: CustomBottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        );
      },
    );
  }
}

// ويدجت الشريط السفلي
class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_rounded, 'الرئيسية', 0, context),
              _buildNavItem(
                Icons.local_shipping_rounded,
                'الشحنات',
                1,
                context,
              ),
              _buildNavItem(Icons.chat_bubble_rounded, 'المحادثات', 2, context),
              _buildNavItem(Icons.settings_rounded, 'الإعدادات', 3, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    BuildContext context,
  ) {
    final bool isSelected = selectedIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.shadow;

    return InkWell(
      onTap: () => onItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: isSelected ? 12 : 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Tajawal',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
