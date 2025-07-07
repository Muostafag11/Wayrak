import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart'; // For NeumorphicContainer

class ShipmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> shipment;
  const ShipmentDetailsScreen({super.key, required this.shipment});

  @override
  State<ShipmentDetailsScreen> createState() => _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends State<ShipmentDetailsScreen> {
  final _offerPriceController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitOffer() async {
    if (_offerPriceController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('offers').insert({
        'shipment_id': widget.shipment['id'],
        'driver_id': Supabase.instance.client.auth.currentUser!.id,
        'price': num.parse(_offerPriceController.text),
      });

      if (mounted) {
        Navigator.of(context).pop(); // إغلاق نافذة تقديم العرض
        _showSnackbar('تم تقديم عرضك بنجاح!', isError: false);
      }
    } catch (e) {
      _showSnackbar('حدث خطأ، الرجاء المحاولة مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOfferDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تقديم عرض سعر',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _offerPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'أدخل السعر المقترح',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitOffer,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('إرسال العرض'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shipment['title'] ?? 'تفاصيل الشحنة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('وصف الشحنة:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(widget.shipment['description'] ?? 'لا يوجد وصف'),
          const Divider(height: 30),
          Text('من:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(widget.shipment['pickup_location']),
          const SizedBox(height: 16),
          Text('إلى:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(widget.shipment['destination']),
          const Divider(height: 30),
          Text(
            'السعر المقترح من التاجر:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('${widget.shipment['suggested_price']} د.ع'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showOfferDialog,
        label: const Text('تقديم عرض'),
        icon: const Icon(Icons.gavel),
      ),
    );
  }
}
