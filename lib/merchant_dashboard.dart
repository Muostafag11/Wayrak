import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantDashboard extends StatelessWidget {
  final String merchantName;
  const MerchantDashboard({super.key, required this.merchantName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('أهلاً بك، $merchantName'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              // تسجيل الخروج سيعيد المستخدم تلقائيًا لشاشة الدخول
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'واجهة التاجر',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // لاحقًا: فتح شاشة إنشاء شحنة جديدة
        },
        label: const Text('شحنة جديدة'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
