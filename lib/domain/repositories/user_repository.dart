import '../entities/app_user.dart';

abstract class UserRepository {
  /// ユーザー情報を取得
  Future<AppUser?> getUser(String userId);
  
  /// ユーザー情報を作成
  Future<void> createUser(AppUser user);
  
  /// ユーザー情報を更新
  Future<void> updateUser(AppUser user);
  
  /// ユーザー情報を削除
  Future<void> deleteUser(String userId);
}