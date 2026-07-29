import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sepet_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SepetProvider(),
      child: const MusteriSiparisApp(),
    ),
  );
}

class MusteriSiparisApp extends StatelessWidget {
  const MusteriSiparisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Şeker Restoran',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepOrange, useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}
