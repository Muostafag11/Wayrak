import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'create_shipment_screen.dart';
import 'shipment_offers_screen.dart';

class HomeTabMerchant extends StatefulWidget {
  final Map<String, dynamic> profileData;
  const HomeTabMerchant({super.key, required this.profileData});

  @override
  State<HomeTabMerchant> createState() => _HomeTabMerchantState();
}

class _HomeTabMerchantState extends State<HomeTabMerchant> {
  late Future<List<Map<String, dynamic>>> _shipmentsFuture;

  @override
  void initState() {
    super.initState();
    _shipmentsFuture = _fetchMyShipments();
  }

  Future<void> _refreshShipments() async {
    setState(() {
      _shipmentsFuture = _fetchMyShipments();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchMyShipments() async {
    final response = await Supabase.instance.client
        .from('shipments')
        .select()
        .eq('merchant_id', Supabase.instance.client.auth.currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // --- دالة جديدة لتأكيد استلام الشحنة ---
  Future<void> _confirmReceipt(String shipmentId) async {
    try {
      await Supabase.instance.client.rpc(
        'confirm_shipment_receipt',
        params: {'p_shipment_id': shipmentId},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تأكيد استلام الشحنة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _refreshShipments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ عند تأكيد الاستلام'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _shipmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('حدث خطأ في جلب الشحنات: ${snapshot.error}'),
          );
        }
        final myShipments = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: _refreshShipments,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              const SizedBox(height: 80),
              _buildStatusCards(context, myShipments),
              const SizedBox(height: 30),
              const Text(
                'الإجراءات السريعة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              _buildActionButtons(context),
              const SizedBox(height: 30),
              const Text(
                'شحناتي الحالية',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              if (myShipments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'ليس لديك أي شحنات حاليًا.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...myShipments.map(
                  (shipment) => _buildShipmentCard(
                    context,
                    shipment['title'] ?? 'شحنة بدون عنوان',
                    'من: ${shipment['pickup_location']}',
                    shipment,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCards(
    BuildContext context,
    List<Map<String, dynamic>> shipments,
  ) {
    // حساب الإحصائيات من البيانات الحقيقية
    final open = shipments.where((s) => s['status'] == 'open').length;
    final inProgress = shipments
        .where((s) => s['status'] == 'in_progress')
        .length;
    final pendingCompletion = shipments
        .where((s) => s['status'] == 'pending_completion')
        .length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(open.toString()),
                const SizedBox(height: 8),
                const Text('مفتوحة'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(inProgress.toString()),
                const SizedBox(height: 8),
                const Text('قيد التنفيذ'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(pendingCompletion.toString()),
                const SizedBox(height: 8),
                const Text('بانتظار التأكيد'),
              ],
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
        InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateShipmentScreen(),
              ),
            );
            _refreshShipments();
          },
          borderRadius: BorderRadius.circular(50),
          child: const Column(
            children: [
              NeumorphicContainer(
                borderRadius: 50,
                child: Icon(Icons.add_box_outlined, size: 30),
              ),
              SizedBox(height: 8),
              Text('شحنة جديدة'),
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
    Map<String, dynamic> shipmentData,
  ) {
    final shipmentStatus = shipmentData['status'];
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: NeumorphicContainer(
        child: ListTile(
          onTap: () async {
            if (shipmentStatus != 'completed') {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ShipmentOffersScreen(shipment: shipmentData),
                ),
              );
              _refreshShipments();
            }
          },
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: theme.colorScheme.shadow),
          ),
          // --- عرض زر أو حالة مختلفة بناءً على حالة الشحنة ---
          trailing: shipmentStatus == 'pending_completion'
              ? ElevatedButton(
                  onPressed: () => _confirmReceipt(shipmentData['id']),
                  child: const Text('تأكيد الاستلام'),
                )
              : shipmentStatus == 'completed'
              ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
              : const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}
