import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'login_screen.dart';

enum UserType { merchant, driver }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  UserType? _selectedUserType;
  bool _agreedToTerms = false;
  final _supabase = Supabase.instance.client;

  // --- للأنميشن ---
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_selectedUserType == null ||
        !_agreedToTerms ||
        _fullNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackbar('الرجاء تعبئة جميع الحقول والموافقة على الشروط');
      return;
    }
    final phoneRegex = RegExp(r'^07[3-9]\d{8}$');
    if (!phoneRegex.hasMatch(_phoneController.text)) {
      _showSnackbar('الرجاء إدخال رقم هاتف عراقي صحيح');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'user_type': _selectedUserType == UserType.merchant
              ? 'merchant'
              : 'driver',
          'full_name': _fullNameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
        },
      );

      if (result.user != null) {
        _showSnackbar(
          'تم إرسال رابط التأكيد إلى بريدك الإلكتروني',
          isError: false,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                email: _emailController.text,
                password: _passwordController.text,
              ),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (e.message.contains('unique constraint')) {
        _showSnackbar('رقم الهاتف هذا مستخدم بالفعل');
      } else {
        _showSnackbar(e.message);
      }
    } catch (e) {
      _showSnackbar('حدث خطأ غير متوقع');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Theme.of(
            context,
          ).scaffoldBackgroundColor.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('الشروط والأحكام'),
          content: SingleChildScrollView(
            // --- النص الكامل للشروط والأحكام ---
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'مقدمة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'مرحبًا بك في ويراگ. باستخدامك لتطبيقنا، فإنك توافق على الالتزام بالشروط والأحكام التالية. الرجاء قراءتها بعناية. تشكل هذه الشروط اتفاقية ملزمة قانونًا بينك وبين ويراگ.',
                  style: TextStyle(height: 1.5),
                ),
                SizedBox(height: 16),
                Text(
                  '1. استخدام الخدمات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'يجب أن تكون في السن القانوني لاستخدام خدماتنا. أنت توافق على تقديم معلومات دقيقة وكاملة عند إنشاء حسابك، وتتحمل المسؤولية الكاملة عن جميع الأنشطة التي تحدث تحت حسابك.',
                  style: TextStyle(height: 1.5),
                ),
                SizedBox(height: 16),
                Text(
                  '2. مسؤوليات المستخدم',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'كمستخدم (سائق أو تاجر)، أنت مسؤول عن الحفاظ على سرية معلومات حسابك. يمنع استخدام التطبيق لأي أغراض غير قانونية أو غير مصرح بها. يجب على السائقين الالتزام بجميع قوانين المرور والنقل المحلية. يجب على التجار التأكد من أن شحناتهم لا تحتوي على مواد محظورة.',
                  style: TextStyle(height: 1.5),
                ),
                SizedBox(height: 16),
                Text(
                  '3. إخلاء المسؤولية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'ويراگ هي منصة لربط الطرفين ولا نتحمل مسؤولية أي اتفاقات أو خلافات قد تنشأ بين التاجر والسائق. نحن نقدم المنصة لتسهيل التواصل ولكن لا نضمن جودة الخدمات المقدمة من أي طرف.',
                  style: TextStyle(height: 1.5),
                ),
                SizedBox(height: 16),
                Text(
                  '4. إنهاء الخدمة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'نحتفظ بالحق في تعليق أو إنهاء حسابك في أي وقت ولأي سبب، بما في ذلك انتهاك هذه الشروط، دون إشعار مسبق.',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إغلاق',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.shadow,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'انضم إلى ويراگ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'اختر نوع حسابك للبدء',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.shadow,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: UserTypeCard(
                          icon: Icons.storefront,
                          label: 'تاجر',
                          isSelected: _selectedUserType == UserType.merchant,
                          onTap: () => setState(
                            () => _selectedUserType = UserType.merchant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: UserTypeCard(
                          icon: Icons.local_shipping,
                          label: 'سائق',
                          isSelected: _selectedUserType == UserType.driver,
                          onTap: () => setState(
                            () => _selectedUserType = UserType.driver,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.person_outline),
                        border: InputBorder.none,
                        hintText: 'الاسم الكامل',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.phone_outlined),
                        border: InputBorder.none,
                        hintText: 'رقم الهاتف',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.email_outlined),
                        border: InputBorder.none,
                        hintText: 'البريد الإلكتروني',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.lock_outline),
                        border: InputBorder.none,
                        hintText: 'كلمة المرور',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) =>
                            setState(() => _agreedToTerms = value!),
                        activeColor: Theme.of(context).colorScheme.secondary,
                      ),
                      const Text('أوافق على'),
                      TextButton(
                        onPressed: _showTermsDialog,
                        child: Text(
                          'الشروط والأحكام',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _isLoading ? null : _signUp,
                    child: NeumorphicContainer(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      color: _isLoading || !_agreedToTerms
                          ? Theme.of(context).colorScheme.shadow
                          : Theme.of(context).colorScheme.secondary,
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'إنشاء حساب',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UserTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const UserTypeCard({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 140,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondary
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.5),
                    offset: const Offset(4, 4),
                    blurRadius: 15,
                  ),
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: theme.colorScheme.inversePrimary,
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : theme.colorScheme.shadow,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.shadow,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
