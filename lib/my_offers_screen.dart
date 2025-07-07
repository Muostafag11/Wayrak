import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'auth_screen.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  late Future<List<Map<String, dynamic>>> _myOffersFuture;

  @override
  void initState() {
    super.initState();
    _myOffersFuture = _fetchMyOffers();
  }

  Future<List<Map<String, dynamic>>> _fetchMyOffers() async {
    final response = await Supabase.instance.client
        .from('offers')
        .select('*, shipment:shipments(*, merchant:profiles(id, full_name))')
        .eq('driver_id', Supabase.instance.client.auth.currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _refreshOffers() async {
    setState(() {
      _myOffersFuture = _fetchMyOffers();
    });
  }

  // --- دالة جديدة لتأكيد التسليم ---
  Future<void> _markAsDelivered(String shipmentId) async {
    try {
      await Supabase.instance.client.rpc(
        'mark_shipment_delivered',
        params: {'p_shipment_id': shipmentId},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إعلام التاجر بالتسليم'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshOffers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('عروضي المقدمة')),
      body: RefreshIndicator(
        onRefresh: _refreshOffers,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _myOffersFuture,
          builder: (context, snapshot) {
            // ... (loading and error states remain the same)
            final offers = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                final shipment = offer['shipment'] as Map<String, dynamic>?;
                if (shipment == null)
                  return const SizedBox.shrink(); // تجاهل العروض على شحنات محذوفة

                final merchant = shipment['merchant'] as Map<String, dynamic>;
                final offerStatus = offer['status'];
                final shipmentStatus = shipment['status'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: NeumorphicContainer(
                    child: ListTile(
                      title: Text(
                        shipment['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'عرضك: ${offer['price']} د.ع | الحالة: $offerStatus',
                      ),
                      // --- عرض زر مختلف بناءً على حالة الشحنة ---
                      trailing: _buildTrailingWidget(
                        context,
                        offerStatus,
                        shipmentStatus,
                        shipment['id'],
                        merchant,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // --- ويدجت مساعد لعرض الزر المناسب ---
  Widget? _buildTrailingWidget(
    BuildContext context,
    String offerStatus,
    String shipmentStatus,
    String shipmentId,
    Map<String, dynamic> merchant,
  ) {
    if (offerStatus != 'accepted') return null;

    if (shipmentStatus == 'in_progress') {
      return ElevatedButton(
        onPressed: () => _markAsDelivered(shipmentId),
        child: const Text('تم التسليم'),
      );
    } else if (shipmentStatus == 'pending_completion') {
      return const Text('بانتظار التأكيد');
    } else if (shipmentStatus == 'completed') {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    return TextButton(
      onPressed: () async {
        /* navigate to chat */
      },
      child: const Text('محادثة'),
    );
  }
}
