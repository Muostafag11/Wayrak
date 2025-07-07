import 'package:flutter/material.dart';
import 'auth_screen.dart'; // لاستخدام الويدجت المخصص
import 'browse_shipments_screen.dart'; // استيراد الشاشة الجديدة
import 'my_offers_screen.dart';

class HomeTabDriver extends StatelessWidget {
  final Map<String, dynamic> profileData;
  const HomeTabDriver({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const SizedBox(height: 80),
        _buildStatusCards(context),
        const SizedBox(height: 30),
        const Text(
          'الإجراءات السريعة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 20),
        _buildActionButtons(context),
        const SizedBox(height: 30),
        const Text(
          'شحنات مقترحة لك',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 20),
        _buildShipmentCard(context, 'شحنة أثاث', 'المنصور إلى الكرادة'),
        _buildShipmentCard(context, 'مواد غذائية', 'دهوك إلى النجف'),
      ],
    );
  }

  Widget _buildStatusCards(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: NeumorphicContainer(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [Text('22'), SizedBox(height: 8), Text('شحنة متاحة')],
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: NeumorphicContainer(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [Text('3'), SizedBox(height: 8), Text('عروض مُقدّمة')],
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: NeumorphicContainer(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [Text('4.8'), SizedBox(height: 8), Text('تقييمك')],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // --- هذا هو الزر الذي تم تعديله ---
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const BrowseShipmentsScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(50),
          child: const Column(
            children: [
              NeumorphicContainer(
                borderRadius: 50,
                child: Icon(Icons.explore_outlined, size: 30),
              ),
              SizedBox(height: 8),
              Text('تصفح الشحنات'),
            ],
          ),
        ),
        // --- باقي الأزرار ---
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MyOffersScreen()),
            );
          },
          borderRadius: BorderRadius.circular(50),
          child: const Column(
            children: [
              NeumorphicContainer(
                borderRadius: 50,
                child: Icon(Icons.list_alt, size: 30),
              ),
              SizedBox(height: 8),
              Text('عروضي'),
            ],
          ),
        ),
        const Column(
          children: [
            NeumorphicContainer(
              borderRadius: 50,
              child: Icon(Icons.history, size: 30),
            ),
            SizedBox(height: 8),
            Text('السجل'),
          ],
        ),
      ],
    );
  }

  Widget _buildShipmentCard(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: NeumorphicContainer(
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}
