import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sepet_provider.dart';
import 'screens/menu_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SepetProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lezzet Durağı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
      ),
      home: const MenuScreen(),
    );
  }
}