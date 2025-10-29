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
