import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/app/app_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 認証BLoC
        BlocProvider(
          create: (context) => AuthBloc(),
        ),
        // アプリBLoC
        BlocProvider(
          create: (context) => AppBloc(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Monster Battle Game',
        debugShowCheckedModeBanner: false,
        
        // テーマ設定
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        
        // ルーティング設定
        routerConfig: AppRouter.router,
      ),
    );
  }
}