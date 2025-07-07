import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';
import 'view_profile_screen.dart';

class ShipmentOffersScreen extends StatefulWidget {
  final Map<String, dynamic> shipment;
  const ShipmentOffersScreen({super.key, required this.shipment});

  @override
  State<ShipmentOffersScreen> createState() => _ShipmentOffersScreenState();
}

class _ShipmentOffersScreenState extends State<ShipmentOffersScreen> {
  late Future<List<Map<String, dynamic>>> _offersFuture;
  bool _isProcessing = false;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _offersFuture = _fetchOffers();
  }

  Future<List<Map<String, dynamic>>> _fetchOffers() async {
    final response = await _supabase
        .from('offers')
        .select(
          '*, driver:profiles(id, full_name, avatar_url, vehicle_type, rating)',
        )
        .eq('shipment_id', widget.shipment['id'])
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  void _showSnackbar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Future<void> _acceptOffer(String offerId, String driverId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final response = await _supabase
          .rpc(
            'accept_offer',
            params: {
              'offer_id_to_accept': offerId,
              'shipment_id_to_update': widget.shipment['id'],
            },
          )
          .single();

      final conversationId = response['conversation_id'];

      if (conversationId != null && mounted) {
        await _sendAutoMessages(
          conversationId,
          _supabase.auth.currentUser!.id,
          driverId,
        );

        _showSnackbar('تم قبول العرض! سيتم فتح المحادثة.', isError: false);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              recipientId: driverId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('*** DETAILED ACCEPT OFFER ERROR: $e ***');
      _showSnackbar('حدث خطأ أثناء قبول العرض.');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendAutoMessages(
    String conversationId,
    String merchantId,
    String driverId,
  ) async {
    try {
      final merchantData = await _supabase
          .from('profiles')
          .select('full_name, phone_number')
          .eq('id', merchantId)
          .single();
      final driverData = await _supabase
          .from('profiles')
          .select('full_name, phone_number')
          .eq('id', driverId)
          .single();

      final merchantMessage =
          'السلام عليكم، معك التاجر ${merchantData['full_name']}. رقم هاتفي هو ${merchantData['phone_number']}.';
      final driverMessage =
          'وعليكم السلام، أنا السائق ${driverData['full_name']}. رقم هاتفي هو ${driverData['phone_number']}. بانتظار تعليماتك.';

      await _supabase.from('messages').insert([
        {
          'conversation_id': conversationId,
          'sender_id': merchantId,
          'content': merchantMessage,
        },
        {
          'conversation_id': conversationId,
          'sender_id': driverId,
          'content': driverMessage,
        },
      ]);
    } catch (e) {
      debugPrint('Error sending auto messages: $e');
    }
  }

  Future<void> _rejectOffer(String offerId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _supabase
          .from('offers')
          .update({'status': 'rejected'})
          .eq('id', offerId);
      _showSnackbar('تم رفض العرض', isError: false);
    } catch (e) {
      debugPrint('*** DETAILED REJECT OFFER ERROR: $e ***');
      _showSnackbar('حدث خطأ أثناء رفض العرض');
    } finally {
      if (mounted) _refreshData();
    }
  }

  void _refreshData() {
    if (mounted) {
      setState(() {
        _offersFuture = _fetchOffers();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('عروض شحنة: ${widget.shipment['title']}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _offersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          final offers = snapshot.data!;
          if (offers.isEmpty) {
            return const Center(child: Text('لم يتم تقديم أي عروض بعد'));
          }

          final bool isShipmentOpen = widget.shipment['status'] == 'open';

          return ListView.builder(
            itemCount: offers.length,
            padding: const EdgeInsets.all(12.0),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final driver = offer['driver'] as Map<String, dynamic>?;
              final status = offer['status'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: NeumorphicContainer(
                  padding: const EdgeInsets.all(16),
                  color: status == 'accepted'
                      ? Colors.green.withOpacity(0.1)
                      : status == 'rejected'
                      ? Colors.red.withOpacity(0.1)
                      : null,
                  child: Column(
                    children: [
                      // --- تم تعديل ListTile هنا ---
                      ListTile(
                        onTap: () {
                          if (driver != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ViewProfileScreen(profileData: driver),
                              ),
                            );
                          }
                        },
                        leading: CircleAvatar(
                          child: Text(driver?['full_name']?[0] ?? 'S'),
                        ),
                        title: Text(
                          driver?['full_name'] ?? 'سائق غير معروف',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('السعر المقدم: ${offer['price']} د.ع'),
                            Text(
                              'المركبة: ${driver?['vehicle_type'] ?? 'غير محدد'} | التقييم: ${driver?['rating'] ?? 'جديد'} ★',
                            ),
                          ],
                        ),
                        trailing: Text(
                          status,
                          style: TextStyle(
                            color: status == 'accepted'
                                ? Colors.green
                                : status == 'rejected'
                                ? Colors.red
                                : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isShipmentOpen && status == 'pending')
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _rejectOffer(offer['id']),
                                child: const Text('رفض'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () {
                                        final driverId = driver?['id'];
                                        if (driverId != null) {
                                          _acceptOffer(offer['id'], driverId);
                                        } else {
                                          _showSnackbar(
                                            'خطأ: لا يمكن تحديد السائق من البيانات المستلمة.',
                                          );
                                        }
                                      },
                                child: const Text('قبول العرض'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
