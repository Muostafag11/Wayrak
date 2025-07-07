import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart'; // شاشة الترحيب
import 'home_screen.dart'; // تم التغيير هنا

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // استدعاء الدالة التي توجه المستخدم
    _redirect();
  }

  Future<void> _redirect() async {
    // انتظار بسيط للتأكد من أن كل شيء جاهز
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // إذا كان المستخدم مسجلاً، اذهب للشاشة الرئيسية الجديدة
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ), // تم التغيير هنا
      );
    } else {
      // إذا لم يكن مسجلاً، اذهب للشاشات الترحيبية
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // عرض شاشة تحميل بسيطة أثناء التحقق
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
