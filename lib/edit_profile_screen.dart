import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart'; // For NeumorphicContainer

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _vehicleController = TextEditingController();
  bool _isLoading = true;
  String _userType = '';

  File? _idCardImage;
  File? _vehicleLicenseImage;
  File? _merchantIdImage;
  File? _businessLicenseImage;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', _supabase.auth.currentUser!.id)
          .single();
      if (mounted) {
        _nameController.text = response['full_name'] ?? '';
        _vehicleController.text = response['vehicle_type'] ?? '';
        setState(() {
          _userType = response['user_type'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source, Function(File) onPicked) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        onPicked(File(pickedFile.path));
      });
    }
  }

  Future<String?> _uploadFile(File file, String fileName) async {
    try {
      final path = '${_supabase.auth.currentUser!.id}/$fileName';
      await _supabase.storage
          .from('user-documents')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));
      return _supabase.storage.from('user-documents').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final idCardUrl = _userType == 'driver' && _idCardImage != null
          ? await _uploadFile(_idCardImage!, 'id_card.jpg')
          : null;
      final vehicleLicenseUrl = _vehicleLicenseImage != null
          ? await _uploadFile(_vehicleLicenseImage!, 'vehicle_license.jpg')
          : null;
      final merchantIdUrl = _userType == 'merchant' && _merchantIdImage != null
          ? await _uploadFile(_merchantIdImage!, 'merchant_id.jpg')
          : null;
      final businessLicenseUrl = _businessLicenseImage != null
          ? await _uploadFile(_businessLicenseImage!, 'business_license.jpg')
          : null;

      await _supabase
          .from('profiles')
          .update({
            'full_name': _nameController.text,
            if (_userType == 'driver') 'vehicle_type': _vehicleController.text,
            if (idCardUrl != null) 'id_card_url': idCardUrl,
            if (vehicleLicenseUrl != null)
              'vehicle_license_url': vehicleLicenseUrl,
            if (merchantIdUrl != null) 'merchant_id_url': merchantIdUrl,
            if (businessLicenseUrl != null)
              'business_license_url': businessLicenseUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _supabase.auth.currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء التحديث')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                    ),
                    validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
                  ),
                  if (_userType == 'driver') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vehicleController,
                      decoration: const InputDecoration(
                        labelText: 'نوع المركبة (مثال: كيا حمل)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'توثيق حساب السائق',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildImagePicker(
                      'صورة الهوية',
                      _idCardImage,
                      (file) => _idCardImage = file,
                    ),
                    _buildImagePicker(
                      'صورة سنوية المركبة',
                      _vehicleLicenseImage,
                      (file) => _vehicleLicenseImage = file,
                    ),
                  ],
                  if (_userType == 'merchant') ...[
                    const SizedBox(height: 20),
                    const Text(
                      'توثيق حساب التاجر',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildImagePicker(
                      'صورة الهوية',
                      _merchantIdImage,
                      (file) => _merchantIdImage = file,
                    ),
                    _buildImagePicker(
                      'هوية غرفة التجارة (اختياري)',
                      _businessLicenseImage,
                      (file) => _businessLicenseImage = file,
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('حفظ التغييرات'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImagePicker(String title, File? image, Function(File) onPicked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: image != null
                ? Image.file(image, fit: BoxFit.cover)
                : const Icon(Icons.image),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery, onPicked),
              child: Text(title),
            ),
          ),
        ],
      ),
    );
  }
}
