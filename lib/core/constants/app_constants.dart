/// アプリケーション全体で使用する定数
class AppConstants {
  // アプリ情報
  static const String appName = 'Monster Battle Game';
  static const String appVersion = '1.0.0';
  
  // タイミング
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration loadingTimeout = Duration(seconds: 10);
  
  // ページング
  static const int itemsPerPage = 20;
  static const int maxPartySize = 5;
  static const int maxBattlePartySize = 3;
  
  // バトル
  static const int maxCost = 100;
  static const int costRecoveryPerTurn = 20;
  
  // ガチャ
  static const int normalGachaCost = 300;
  static const int premiumGachaCost = 3000;
  static const int pityLimit = 100;
  
  // 課金
  static const List<int> stonePacks = [160, 500, 1020, 2300, 5500, 12000];
  static const List<int> stonePackPrices = [160, 490, 980, 2000, 4800, 10000];
}
