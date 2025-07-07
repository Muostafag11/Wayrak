import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // تأكد من عدم وجود أي مسافات قبل بداية علامة الاقتباس
    url: 'https://qchjifosovxcnkcswsvp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjaGppZm9zb3Z4Y25rY3N3c3ZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4MDI2OTAsImV4cCI6MjA2NzM3ODY5MH0.plksMAhV1CTCTH5TAIWenCAHAFpCX7l2nwt54h4cJVE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ويراگ',
      theme: ThemeData(
        fontFamily: 'Tajawal',
        scaffoldBackgroundColor: const Color(0xFFE6EBF0),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF622347),
          secondary: Color(0xFF122E34),
          surface: Color(0xFFE6EBF0),
          onSurface: Color(0xFF0E1D21),
          background: Color(0xFFE6EBF0),
          shadow: Color(0xFFAAB2BA),
          inversePrimary: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
