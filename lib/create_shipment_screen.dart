import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart'; // To use the NeumorphicContainer
import 'package:flutter/services.dart';

class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedPickupGovernorate;
  String? _selectedDestinationGovernorate;

  // List of Iraqi Governorates
  final List<String> _governorates = [
    'بغداد',
    'البصرة',
    'نينوى',
    'أربيل',
    'الأنبار',
    'ذي قار',
    'بابل',
    'ديالى',
    'كربلاء',
    'كركوك',
    'ميسان',
    'المثنى',
    'النجف',
    'القادسية',
    'صلاح الدين',
    'السليمانية',
    'واسط',
    'دهوك',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pickupAddressController.dispose();
    _destinationAddressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitShipment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Check if governorates are selected
    if (_selectedPickupGovernorate == null ||
        _selectedDestinationGovernorate == null) {
      _showSnackbar('الرجاء اختيار محافظة الاستلام والتوصيل');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      // Combine governorate and address for a full location string
      final fullPickupLocation =
          '$_selectedPickupGovernorate, ${_pickupAddressController.text}';
      final fullDestination =
          '$_selectedDestinationGovernorate, ${_destinationAddressController.text}';

      await Supabase.instance.client.from('shipments').insert({
        'merchant_id': userId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'pickup_location': fullPickupLocation,
        'destination': fullDestination,
        'suggested_price': num.tryParse(_priceController.text) ?? 0,
      });

      if (mounted) {
        _showSnackbar('تم إنشاء الشحنة بنجاح!', isError: false);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('حدث خطأ. الرجاء المحاولة مرة أخرى.');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnackbar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء شحنة جديدة')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildTextField(
              controller: _titleController,
              hint: 'عنوان الشحنة (مثال: أجهزة إلكترونية)',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _descriptionController,
              hint: 'وصف الشحنة (اختياري)',
              isRequired: false,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // --- Pickup Location Section ---
            const Text(
              'موقع الاستلام',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildLocationInput(
              governorateHint: 'اختر محافظة الاستلام',
              addressController: _pickupAddressController,
              addressHint: 'العنوان التفصيلي (المنطقة، الشارع)',
              selectedValue: _selectedPickupGovernorate,
              onChanged: (value) {
                setState(() {
                  _selectedPickupGovernorate = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // --- Destination Section ---
            const Text(
              'وجهة التوصيل',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildLocationInput(
              governorateHint: 'اختر محافظة التوصيل',
              addressController: _destinationAddressController,
              addressHint: 'العنوان التفصيلي (المنطقة، الشارع)',
              selectedValue: _selectedDestinationGovernorate,
              onChanged: (value) {
                setState(() {
                  _selectedDestinationGovernorate = value;
                });
              },
            ),

            const SizedBox(height: 20),
            _buildTextField(
              controller: _priceController,
              hint: 'السعر المقترح (دينار عراقي)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              isRequired: true,
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _isLoading ? null : _submitShipment,
              child: NeumorphicContainer(
                padding: const EdgeInsets.symmetric(vertical: 20),
                color: _isLoading
                    ? Theme.of(context).colorScheme.shadow
                    : Theme.of(context).colorScheme.primary,
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          'أنشئ الشحنة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for a single text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isRequired = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text, // إضافة
    List<TextInputFormatter>? inputFormatters, // إضافة
  }) {
    return NeumorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType, // استخدام
        inputFormatters: inputFormatters, // استخدام
        decoration: InputDecoration(border: InputBorder.none, hintText: hint),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'هذا الحقل مطلوب';
          }
          return null;
        },
      ),
    );
  }

  // New helper widget for the combined location input
  Widget _buildLocationInput({
    required String governorateHint,
    required TextEditingController addressController,
    required String addressHint,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      children: [
        NeumorphicContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            hint: Text(governorateHint),
            isExpanded: true,
            decoration: const InputDecoration(border: InputBorder.none),
            items: _governorates.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: onChanged,
            validator: (value) => value == null ? 'الرجاء اختيار محافظة' : null,
          ),
        ),
        const SizedBox(height: 10),
        _buildTextField(controller: addressController, hint: addressHint),
      ],
    );
  }
}
