import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'login_screen.dart';

// ----------------------------------------------------
// --   ويدجت مخصص لإنشاء حاويات بنمط Neumorphism   --
// ----------------------------------------------------
class NeumorphicContainer extends StatelessWidget {
  final Widget? child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool isCircle; // خاصية الشكل الدائري

  const NeumorphicContainer({
    super.key,
    this.child,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(12),
    this.color,
    this.isCircle = false, // القيمة الافتراضية
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = color ?? theme.colorScheme.background;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        // تطبيق الشكل بناءً على isCircle
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        // تطبيق حواف دائرية فقط إذا لم يكن الشكل دائريًا
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        boxShadow: [
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
      child: child,
    );
  }
}

// ----------------------------------------------------
// --  البيانات الخاصة بكل صفحة من الشاشات الترحيبية  --
// ----------------------------------------------------
class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
  });
}

// ----------------------------------------------------
// --         الشاشة الرئيسية التي تجمع كل شيء        --
// ----------------------------------------------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final PageController _pageController = PageController();
  double _pageOffset = 0.0;
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "اربط تجارتك بالسائقين",
      description: "اعثر على أفضل السائقين لنقل شحناتك بكل سهولة وأمان.",
      icon: Icons.local_shipping_outlined,
    ),
    OnboardingPageData(
      title: "عروض أسعار تنافسية",
      description: "استلم عروضًا متعددة واختر الأنسب لميزانيتك.",
      icon: Icons.price_change_outlined,
    ),
    OnboardingPageData(
      title: "تواصل ومتابعة مباشرة",
      description: "تتبع حالة شحنتك وتحدث مع السائق مباشرة.",
      icon: Icons.chat_bubble_outline_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  double distortion = (_pageOffset - index).abs();
                  return OnboardingPageView(
                    data: _pages[index],
                    distortion: distortion,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => buildDot(index, theme),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Hero(
                    tag: 'auth_button',
                    child: Material(
                      color: Colors.transparent,
                      child: GestureDetector(
                        onTap: () async {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('showLogin', true);

                            if (mounted) {
                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => const LoginScreen(),
                                  transitionDuration: const Duration(
                                    milliseconds: 600,
                                  ),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                ),
                              );
                            }
                          }
                        },
                        child: NeumorphicContainer(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 60,
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'ابدأ الآن'
                                : 'التالي',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot(int index, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 10,
      width: _currentPage == index ? 25 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? theme.colorScheme.secondary
            : theme.colorScheme.shadow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class OnboardingPageView extends StatefulWidget {
  final OnboardingPageData data;
  final double distortion;

  const OnboardingPageView({
    super.key,
    required this.data,
    required this.distortion,
  });

  @override
  State<OnboardingPageView> createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends State<OnboardingPageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _loopController;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loopController,
            builder: (context, child) {
              final loopValue = _loopController.value * 0.1;
              return Transform.translate(
                offset: Offset(0, math.sin(loopValue * 2 * math.pi) * 5),
                child: child,
              );
            },
            child: Transform.scale(
              scale: 1.0 - (widget.distortion * 0.3),
              child: Transform.rotate(
                angle: -widget.distortion * 0.5,
                child: NeumorphicContainer(
                  borderRadius: 100,
                  padding: const EdgeInsets.all(40),
                  child: Icon(
                    widget.data.icon,
                    size: 80,
                    color: theme.colorScheme.secondary.withOpacity(
                      (1.0 - widget.distortion).clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
          Transform.translate(
            offset: Offset(0, widget.distortion * 50),
            child: Opacity(
              opacity: (1.0 - widget.distortion).clamp(0.0, 1.0),
              child: Column(
                children: [
                  Text(
                    widget.data.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.data.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.shadow,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
