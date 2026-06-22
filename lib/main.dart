import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LanChatApp());
}

class LanChatApp extends StatelessWidget {
  const LanChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAN Чат',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2F80ED),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
