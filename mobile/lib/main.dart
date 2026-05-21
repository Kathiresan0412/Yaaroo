import 'package:flutter/material.dart';

void main() {
  runApp(const YaaroMobileApp());
}

class YaaroMobileApp extends StatelessWidget {
  const YaaroMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yaaro0',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Yaaro0 mobile app is running'),
        ),
      ),
    );
  }
}
