import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BaojiaApp());
}

class BaojiaApp extends StatelessWidget {
  const BaojiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '报价工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1E40AF),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const HomeScreen(),
    );
  }
}
