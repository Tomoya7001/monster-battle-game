#!/bin/bash

# モンスター対戦ゲーム - フルセットアップスクリプト
# 実行前に以下を確認してください:
# 1. Flutter SDKがインストールされている
# 2. プロジェクトディレクトリに移動している (~/Documents/Projects/monster_battle_game)

set -e  # エラーが発生したら停止

echo "=========================================="
echo "モンスター対戦ゲーム - 初期セットアップ"
echo "=========================================="
echo ""

# 現在のディレクトリを確認
CURRENT_DIR=$(pwd)
echo "📁 現在のディレクトリ: $CURRENT_DIR"
echo ""

# プロジェクト名を確認
if [[ ! "$CURRENT_DIR" =~ "monster_battle_game" ]]; then
    echo "⚠️  警告: monster_battle_gameディレクトリにいない可能性があります"
    echo "続行しますか？ (y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
        echo "セットアップを中止しました"
        exit 1
    fi
fi

echo "🔧 Step 1/5: プロジェクト構造を作成中..."
echo ""

# Clean Architecture構造のディレクトリ作成
mkdir -p lib/core/{constants,utils,errors,theme,extensions}
mkdir -p lib/data/{models,repositories,datasources/remote,datasources/local}
mkdir -p lib/domain/{entities,repositories,usecases/battle,usecases/monster,usecases/gacha}
mkdir -p lib/presentation/{screens,widgets,blocs}
mkdir -p lib/l10n

# 各画面のディレクトリ
mkdir -p lib/presentation/screens/{home,battle,monster,gacha,equipment,shop,settings,auth}
mkdir -p lib/presentation/screens/home/widgets
mkdir -p lib/presentation/screens/battle/widgets
mkdir -p lib/presentation/screens/monster/widgets
mkdir -p lib/presentation/screens/gacha/widgets

# 共通ウィジェット
mkdir -p lib/presentation/widgets/{common,battle,monster}

# BLoC
mkdir -p lib/presentation/blocs/{auth,battle,monster,gacha,equipment}

# Assets
mkdir -p assets/{images,data,fonts}
mkdir -p assets/images/{monsters,backgrounds,ui,icons}

# Firebase
mkdir -p firebase/functions/src/{battle,gacha,purchase,utils}

# Tests
mkdir -p test/{unit,widget}

# Docs
mkdir -p docs

# Scripts
mkdir -p scripts

echo "✅ プロジェクト構造作成完了"
echo ""

echo "🔧 Step 2/5: 基本ファイルを作成中..."
echo ""

# .gitignoreファイルの更新
cat >> .gitignore << 'EOF'

# Firebase設定 (セキュリティ上公開しない)
ios/Runner/GoogleService-Info.plist
android/app/google-services.json
firebase_options.dart

# Firebaseキャッシュ
.firebase/

# ビルドファイル
*.g.dart
*.freezed.dart

# 環境設定
.env
.env.local
EOF

echo "✅ .gitignore更新完了"

# READMEファイルの作成
cat > README.md << 'EOF'
# Monster Battle Game

ターン制対戦型モンスター育成ゲーム

## 🎮 プロジェクト概要

- **ジャンル**: ターン制対戦型モンスター育成ゲーム
- **プラットフォーム**: iOS / Android / Web
- **開発期間**: 6ヶ月 (Phase 1)
- **技術スタック**: Flutter + Firebase

## 🛠️ 開発環境

- Flutter 3.24+
- Dart 3.5+
- Firebase (Firestore, Auth, Storage, Functions)
- Node.js 20+ (Firebase Functions)

## 📦 セットアップ

1. **Flutter SDK インストール**
   ```bash
   # 公式サイトからインストール
   https://docs.flutter.dev/get-started/install
   ```

2. **プロジェクトのクローン**
   ```bash
   git clone [リポジトリURL]
   cd monster_battle_game
   ```

3. **依存関係のインストール**
   ```bash
   flutter pub get
   ```

4. **Firebase設定**
   ```bash
   # Firebase CLIログイン
   firebase login
   
   # Firebase初期化
   firebase init
   
   # FlutterFire設定
   flutterfire configure
   ```

5. **実行**
   ```bash
   # Chrome (Web)
   flutter run -d chrome
   
   # iOS Simulator
   flutter run -d ios
   
   # Android Emulator
   flutter run -d android
   ```

## 📁 プロジェクト構造

```
lib/
├── core/           # コア機能・ユーティリティ
├── data/           # データ層 (Model, Repository実装)
├── domain/         # ドメイン層 (Entity, Repository Interface, UseCase)
└── presentation/   # プレゼンテーション層 (UI, BLoC)
```

## 📚 ドキュメント

- [開発方針完全版](docs/開発方針_完全版.md)
- [プロジェクト仕様書](docs/プロジェクト仕様書.md)
- [データベース設計](docs/データベース設計.md)

## 🚀 開発フロー

1. `develop`ブランチから`feature/xxx`ブランチを作成
2. 機能開発・テスト
3. プルリクエスト作成
4. レビュー・マージ
5. `main`ブランチにマージしてリリース

## 📝 コミット規約

```
feat: 新機能
fix: バグ修正
docs: ドキュメント変更
style: コードフォーマット
refactor: リファクタリング
test: テスト追加・修正
chore: ビルド・設定変更
```

## 🧪 テスト

```bash
# 単体テスト
flutter test

# カバレッジ付き
flutter test --coverage
```

## 📄 ライセンス

Copyright © 2025 Monster Battle Game Team
EOF

echo "✅ README.md作成完了"

# analysis_options.yamlの作成
cat > analysis_options.yaml << 'EOF'
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # 推奨ルール
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_final_fields: true
    prefer_final_locals: true
    avoid_print: true
    avoid_unnecessary_containers: true
    sized_box_for_whitespace: true
    use_key_in_widget_constructors: true
    
    # コメント
    lines_longer_than_80_chars: false

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore
EOF

echo "✅ analysis_options.yaml作成完了"
echo ""

echo "🔧 Step 3/5: pubspec.yamlを更新中..."
echo ""

# pubspec.yamlのバックアップ
cp pubspec.yaml pubspec.yaml.backup

# 新しいpubspec.yamlを作成
cat > pubspec.yaml << 'EOF'
name: monster_battle_game
description: ターン制対戦型モンスター育成ゲーム
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  firebase_storage: ^11.5.6
  firebase_crashlytics: ^3.4.9
  firebase_analytics: ^10.7.4

  # 状態管理
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # ルーティング
  go_router: ^12.1.3

  # データモデル
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

  # 認証
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^5.0.0

  # 課金
  in_app_purchase: ^3.1.11

  # UI
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  lottie: ^2.7.0

  # ユーティリティ
  intl: ^0.19.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  uuid: ^4.2.1
  http: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

  # コード生成
  build_runner: ^2.4.6
  freezed: ^2.4.5
  json_serializable: ^6.7.1

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/images/monsters/
    - assets/images/backgrounds/
    - assets/images/ui/
    - assets/images/icons/
    - assets/data/

  # fonts:
  #   - family: CustomFont
  #     fonts:
  #       - asset: assets/fonts/CustomFont-Regular.ttf
  #       - asset: assets/fonts/CustomFont-Bold.ttf
  #         weight: 700
EOF

echo "✅ pubspec.yaml更新完了"
echo ""

echo "🔧 Step 4/5: 基本的なDartファイルを作成中..."
echo ""

# main.dartの作成
cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化 (firebase_options.dartは後で生成)
  try {
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    print('Firebase初期化は flutterfire configure 実行後に有効化してください');
  } catch (e) {
    print('Firebase初期化エラー: $e');
  }

  runApp(const MonsterBattleGame());
}

class MonsterBattleGame extends StatelessWidget {
  const MonsterBattleGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monster Battle Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.purple.shade500,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.catching_pokemon,
                size: 120,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 24),
              const Text(
                'Monster Battle Game',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '開発環境セットアップ完了！',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'Phase 1 - Week 1\nプロジェクト構造構築完了',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOF

echo "✅ main.dart作成完了"

# app_constants.dartの作成
cat > lib/core/constants/app_constants.dart << 'EOF'
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
EOF

echo "✅ app_constants.dart作成完了"

# strings.dartの作成
cat > lib/core/constants/strings.dart << 'EOF'
/// 文字列定数 (後で多言語対応に移行)
class Strings {
  // 共通
  static const String ok = 'OK';
  static const String cancel = 'キャンセル';
  static const String confirm = '確認';
  static const String close = '閉じる';
  static const String loading = '読み込み中...';
  static const String error = 'エラー';
  static const String retry = '再試行';
  
  // ホーム
  static const String home = 'ホーム';
  static const String battle = 'バトル';
  static const String party = 'パーティ';
  static const String gacha = 'ガチャ';
  static const String shop = 'ショップ';
  static const String settings = '設定';
  
  // バトル
  static const String attack = '攻撃';
  static const String skill = '技';
  static const String switchMonster = '交代';
  static const String battleStart = 'バトル開始';
  static const String victory = '勝利';
  static const String defeat = '敗北';
  
  // モンスター
  static const String level = 'レベル';
  static const String hp = 'HP';
  static const String attack_ = '攻撃力';
  static const String defense = '防御力';
  static const String speed = '素早さ';
  
  // エラーメッセージ
  static const String networkError = 'ネットワークエラーが発生しました';
  static const String unknownError = '不明なエラーが発生しました';
}
EOF

echo "✅ strings.dart作成完了"

# app_theme.dartの作成
cat > lib/core/theme/app_theme.dart << 'EOF'
import 'package:flutter/material.dart';

class AppTheme {
  // プライマリカラー (ダーク基調)
  static const Color primaryColor = Color(0xFF7C4DFF);
  static const Color secondaryColor = Color(0xFFFF4081);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  
  // テキストカラー
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  
  // 属性カラー
  static const Color fireColor = Color(0xFFFF5722);
  static const Color waterColor = Color(0xFF2196F3);
  static const Color grassColor = Color(0xFF4CAF50);
  static const Color electricColor = Color(0xFFFFC107);
  static const Color darkColor = Color(0xFF9C27B0);
  static const Color lightColor = Color(0xFFFFEB3B);
  
  // レアリティカラー
  static const Color rarity1 = Color(0xFF9E9E9E); // ★1
  static const Color rarity2 = Color(0xFF4CAF50); // ★2
  static const Color rarity3 = Color(0xFF2196F3); // ★3
  static const Color rarity4 = Color(0xFF9C27B0); // ★4
  static const Color rarity5 = Color(0xFFFFD700); // ★5
  
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
    ),
    useMaterial3: true,
  );
}
EOF

echo "✅ app_theme.dart作成完了"
echo ""

echo "🔧 Step 5/5: Firebase設定ファイルを作成中..."
echo ""

# firestore.rulesの作成
cat > firestore.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ユーザーは自分のデータのみアクセス可能
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // マスターデータは認証済みユーザー全員が読み取り可能
    match /monsters/{monsterId} {
      allow read: if request.auth != null;
      allow write: if false; // 管理者のみ（Firebase Consoleから）
    }
    
    match /skills/{skillId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    match /equipment/{equipmentId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    
    // バトルログは参加者のみ読み取り可能
    match /battleLogs/{battleId} {
      allow read: if request.auth != null && 
                     request.auth.uid in resource.data.participants;
      allow write: if false; // Cloud Functionsのみ
    }
  }
}
EOF

echo "✅ firestore.rules作成完了"

# firebase.jsonの作成
cat > firebase.json << 'EOF'
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": [
    {
      "source": "firebase/functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log"
      ],
      "predeploy": [
        "npm --prefix \"$RESOURCE_DIR\" run lint",
        "npm --prefix \"$RESOURCE_DIR\" run build"
      ]
    }
  ],
  "storage": {
    "rules": "storage.rules"
  }
}
EOF

echo "✅ firebase.json作成完了"

# firestore.indexes.jsonの作成
cat > firestore.indexes.json << 'EOF'
{
  "indexes": [],
  "fieldOverrides": []
}
EOF

echo "✅ firestore.indexes.json作成完了"

# storage.rulesの作成
cat > storage.rules << 'EOF'
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // モンスター画像は全員読み取り可能
    match /monsters/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false; // 管理者のみ
    }
    
    // ユーザーアバターは本人のみ書き込み可能
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
EOF

echo "✅ storage.rules作成完了"

# Firebase Functions package.jsonの作成
cat > firebase/functions/package.json << 'EOF'
{
  "name": "monster-battle-functions",
  "version": "1.0.0",
  "description": "Cloud Functions for Monster Battle Game",
  "main": "lib/index.js",
  "scripts": {
    "lint": "eslint --ext .js,.ts .",
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "engines": {
    "node": "20"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0"
  },
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.50.0",
    "typescript": "^5.2.2"
  },
  "private": true
}
EOF

echo "✅ Firebase Functions package.json作成完了"

# Firebase Functions tsconfig.jsonの作成
cat > firebase/functions/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017"
  },
  "compileOnSave": true,
  "include": [
    "src"
  ]
}
EOF

echo "✅ Firebase Functions tsconfig.json作成完了"

# Firebase Functions index.tsの作成
cat > firebase/functions/src/index.ts << 'EOF'
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Firebase Admin初期化
admin.initializeApp();

// サンプル関数
export const helloWorld = functions.https.onRequest((request, response) => {
  response.send("Monster Battle Game Functions - Ready!");
});

// バトル処理 (後で実装)
// export { executeTurn } from './battle/executeTurn';
// export { pullGacha } from './gacha/pullGacha';
// export { verifyReceipt } from './purchase/verifyReceipt';
EOF

echo "✅ Firebase Functions index.ts作成完了"
echo ""

echo "=========================================="
echo "✅ セットアップ完了！"
echo "=========================================="
echo ""
echo "📋 次のステップ:"
echo ""
echo "1. パッケージをインストール:"
echo "   flutter pub get"
echo ""
echo "2. Firebaseプロジェクトを作成:"
echo "   https://console.firebase.google.com/"
echo ""
echo "3. Firebase CLIでログイン:"
echo "   firebase login"
echo ""
echo "4. Firebaseを初期化:"
echo "   firebase init"
echo "   → Firestore, Functions, Storageを選択"
echo ""
echo "5. FlutterFireを設定:"
echo "   dart pub global activate flutterfire_cli"
echo "   flutterfire configure"
echo ""
echo "6. アプリを実行:"
echo "   flutter run -d chrome"
echo ""
echo "📚 詳細は README.md を確認してください"
echo ""
echo "🎮 開発を楽しんでください！"
echo ""
