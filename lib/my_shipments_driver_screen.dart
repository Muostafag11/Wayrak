import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart'; // For NeumorphicContainer
import 'shipment_tracking_screen.dart'; // <-- استيراد شاشة التتبع

class MyShipmentsDriverScreen extends StatefulWidget {
  const MyShipmentsDriverScreen({super.key});

  @override
  State<MyShipmentsDriverScreen> createState() =>
      _MyShipmentsDriverScreenState();
}

class _MyShipmentsDriverScreenState extends State<MyShipmentsDriverScreen> {
  late Future<List<Map<String, dynamic>>> _myShipmentsFuture;

  @override
  void initState() {
    super.initState();
    _myShipmentsFuture = _fetchMyActiveShipments();
  }

  Future<List<Map<String, dynamic>>> _fetchMyActiveShipments() async {
    final response = await Supabase.instance.client.rpc(
      'get_my_active_shipments_as_driver',
    );
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _refresh() async {
    setState(() {
      _myShipmentsFuture = _fetchMyActiveShipments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شحناتي الحالية')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _myShipmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(
                child: Text('ليس لديك أي شحنات نشطة حاليًا.'),
              );
            }

            final shipments = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: shipments.length,
              itemBuilder: (context, index) {
                final shipment = shipments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: NeumorphicContainer(
                    child: ListTile(
                      title: Text(
                        shipment['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('الحالة: ${shipment['status']}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      // --- تم تفعيل الضغط هنا للانتقال لشاشة التتبع ---
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ShipmentTrackingScreen(shipment: shipment),
                          ),
                        );
                      },
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
}
