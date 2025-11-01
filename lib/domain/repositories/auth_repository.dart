import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  /// Googleでサインイン
  Future<User?> signInWithGoogle();
  
  /// サインアウト
  Future<void> signOut();
  
  /// 認証状態の変更を監視
  Stream<User?> get authStateChanges;
  
  /// 現在のユーザーを取得
  User? get currentUser;
}