import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart'; // For NeumorphicContainer
import 'shipment_details_screen.dart'; // استيراد شاشة التفاصيل

class BrowseShipmentsScreen extends StatefulWidget {
  const BrowseShipmentsScreen({super.key});

  @override
  State<BrowseShipmentsScreen> createState() => _BrowseShipmentsScreenState();
}

class _BrowseShipmentsScreenState extends State<BrowseShipmentsScreen> {
  late Future<List<Map<String, dynamic>>> _shipmentsFuture;

  @override
  void initState() {
    super.initState();
    _shipmentsFuture = _fetchOpenShipments();
  }

  Future<List<Map<String, dynamic>>> _fetchOpenShipments() async {
    final response = await Supabase.instance.client
        .from('shipments')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تصفح الشحنات المتاحة')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _shipmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          final shipments = snapshot.data!;
          if (shipments.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد شحنات متاحة حاليًا',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: shipments.length,
            padding: const EdgeInsets.all(12.0),
            itemBuilder: (context, index) {
              final shipment = shipments[index];
              return ShipmentCard(shipment: shipment);
            },
          );
        },
      ),
    );
  }
}

// -- ويدجت مخصص لعرض بطاقة الشحنة --
class ShipmentCard extends StatelessWidget {
  final Map<String, dynamic> shipment;
  const ShipmentCard({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- تم التعديل هنا لجعل البطاقة كلها قابلة للضغط ---
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ShipmentDetailsScreen(shipment: shipment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: NeumorphicContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shipment['title'] ?? 'بدون عنوان',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('من: ${shipment['pickup_location']}')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('إلى: ${shipment['destination']}')),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'السعر: ${shipment['suggested_price'] ?? 'لم يحدد'} د.ع',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  // --- تم استبدال الزر بأيقونة للإشارة إلى إمكانية الضغط ---
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.shadow,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
