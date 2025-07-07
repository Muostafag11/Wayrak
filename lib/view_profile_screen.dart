import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';

class ViewProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  const ViewProfileScreen({super.key, required this.profileData});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  // Future لجلب تاريخ الشحنات
  late final Future<List<Map<String, dynamic>>> _shipmentHistoryFuture;

  @override
  void initState() {
    super.initState();
    // عند فتح الشاشة، قم باستدعاء دالة جلب البيانات
    _shipmentHistoryFuture = _fetchShipmentHistory();
  }

  // دالة لجلب تاريخ الشحنات المشتركة باستخدام الدالة في قاعدة البيانات
  Future<List<Map<String, dynamic>>> _fetchShipmentHistory() async {
    final response = await Supabase.instance.client.rpc(
      'get_shipment_history_with_user',
      params: {'other_user_id': widget.profileData['id']},
    );
    return List<Map<String, dynamic>>.from(response);
  }

  // دالة لبدء المحادثة
  Future<void> _startChat(BuildContext context) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'create_or_get_conversation',
        params: {'recipient_id_input': widget.profileData['id']},
      );
      final conversationId = response as String?;

      if (conversationId != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              recipientId: widget.profileData['id'],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ عند بدء المحادثة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userType = widget.profileData['user_type'] == 'driver'
        ? 'سائق'
        : 'تاجر';
    final isVerified = widget.profileData['is_verified'] ?? false;
    final rating = widget.profileData['rating']?.toString() ?? 'جديد';
    final vehicleType = widget.profileData['vehicle_type'] ?? 'لم يحدد';

    return Scaffold(
      appBar: AppBar(
        title: Text('الملف الشخصي لـ ${widget.profileData['full_name']}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 50,
            child: Text(
              widget.profileData['full_name']?[0] ?? 'U',
              style: const TextStyle(fontSize: 40),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.profileData['full_name'] ?? 'مستخدم',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isVerified)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.verified, color: Colors.blueAccent),
                  ),
              ],
            ),
          ),
          Center(
            child: Text(
              'التقييم: $rating ★',
              style: TextStyle(color: theme.colorScheme.shadow, fontSize: 16),
            ),
          ),

          const Divider(height: 40),

          Text(
            'معلومات إضافية',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          NeumorphicContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (widget.profileData['user_type'] == 'driver')
                  ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: const Text('نوع المركبة'),
                    subtitle: Text(vehicleType),
                  ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('رقم الهاتف'),
                  subtitle: Text(
                    widget.profileData['phone_number'] ?? 'غير متوفر',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _startChat(context),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('بدء محادثة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const Divider(height: 40),

          // --- قسم عرض تاريخ الشحنات المشتركة ---
          Text(
            'تاريخ الشحنات المشتركة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _shipmentHistoryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const NeumorphicContainer(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('لا يوجد تاريخ شحنات مشترك.')),
                );
              }
              final shipments = snapshot.data!;
              return Column(
                children: shipments
                    .map(
                      (shipment) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: NeumorphicContainer(
                          child: ListTile(
                            title: Text(shipment['title'] ?? 'شحنة'),
                            trailing: Text(shipment['status'] ?? ''),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
