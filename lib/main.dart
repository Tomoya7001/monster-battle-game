import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/bloc/gacha/gacha_bloc.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'core/services/gacha_service.dart';

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
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: AuthRepositoryImpl(),
            userRepository: UserRepositoryImpl(),
          )..add(const AuthCheckRequested()), // 起動時に認証状態をチェック
        ),
        
        // ガチャBLoC
        BlocProvider<GachaBloc>(
          create: (context) => GachaBloc(
            gachaService: GachaService(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Monster Battle Game',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}