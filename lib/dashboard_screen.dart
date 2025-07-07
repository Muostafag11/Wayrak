import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'driver_dashboard.dart';
import 'merchant_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // متغير لحفظ بيانات المستخدم التي سيتم جلبها
  late final Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    // عند فتح الشاشة، قم باستدعاء دالة جلب البيانات
    _profileFuture = _getProfile();
  }

  // دالة لجلب بيانات المستخدم من جدول profiles
  Future<Map<String, dynamic>> _getProfile() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance.client
        .from('profiles')
        .select() // اجلب كل الأعمدة
        .eq('id', userId)
        .single();
    return response;
  }

  @override
  Widget build(BuildContext context) {
    // استخدام FutureBuilder لعرض واجهة مناسبة أثناء التحميل أو عند حدوث خطأ
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        // --- حالة التحميل ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --- حالة وجود خطأ ---
        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('حدث خطأ أثناء جلب بيانات الملف الشخصي')),
          );
        }

        // --- حالة نجاح جلب البيانات ---
        final profileData = snapshot.data!;
        final userType = profileData['user_type'];
        // إذا لم يكن الاسم موجودًا، اعرض نصًا افتراضيًا
        final fullName = profileData['full_name'] ?? 'مستخدم جديد';

        // بناء الواجهة بناءً على نوع المستخدم
        if (userType == 'merchant') {
          return MerchantDashboard(merchantName: fullName);
        } else if (userType == 'driver') {
          return DriverDashboard(driverName: fullName);
        } else {
          // في حالة عدم تحديد النوع
          return const Scaffold(
            body: Center(child: Text('خطأ: لم يتم تحديد نوع المستخدم.')),
          );
        }
      },
    );
  }
}
