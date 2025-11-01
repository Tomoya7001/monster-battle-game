import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/di/injection.dart';
import 'firebase_options.dart';
import 'presentation/screens/home_screen.dart'; // ← この行を追加

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 依存性注入の設定
  await setupDependencies();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monster Battle Game',
      theme: ThemeData.dark(),
      home: const HomeScreen(), // ← これでエラーが消える
    );
  }
}