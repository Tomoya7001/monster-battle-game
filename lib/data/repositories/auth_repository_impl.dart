import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repository.dart';

/// 認証リポジトリ実装（開発用簡易版）
/// 
/// 注：本格的なGoogle認証は後で実装します
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  
  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;
  
  @override
  Future<User?> signInWithGoogle() async {
    // TODO: 本番ではGoogle認証を実装
    // 現在は未実装
    throw UnimplementedError('Google Sign Inは後で実装します');
  }
  
  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
  
  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  @override
  User? get currentUser => _firebaseAuth.currentUser;
}