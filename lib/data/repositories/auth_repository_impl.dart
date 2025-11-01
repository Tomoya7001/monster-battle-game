import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  
  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();
  
  @override
  Future<User?> signInWithGoogle() async {
    try {
      // Google認証フロー開始
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // ユーザーがキャンセルした場合
      if (googleUser == null) return null;
      
      // 認証情報取得
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      // Firebase用のクレデンシャル作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Firebaseにサインイン
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);
      
      return userCredential.user;
    } catch (e) {
      print('Google Sign In Error: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
  
  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  @override
  User? get currentUser => _firebaseAuth.currentUser;
}