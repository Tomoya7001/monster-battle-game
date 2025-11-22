#!/usr/bin/env node

/**
 * 技マスターデータ Firestoreインポートスクリプト
 * 
 * 使用方法:
 *   1. npm install firebase-admin
 *   2. Firebaseサービスアカウントキーをダウンロード
 *   3. node import_skills.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// カラー出力用
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// サービスアカウントキーのパスを環境変数またはデフォルトから取得
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || 
                           './serviceAccountKey.json';

// Firebase Admin初期化
try {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  log('✅ Firebase Admin初期化完了', 'green');
} catch (error) {
  log('❌ Firebase Admin初期化失敗', 'red');
  log('サービスアカウントキーが見つかりません', 'red');
  log(`パス: ${serviceAccountPath}`, 'yellow');
  log('\n以下の手順でキーを取得してください:', 'cyan');
  log('1. https://console.firebase.google.com/ にアクセス', 'cyan');
  log('2. プロジェクト設定 → サービスアカウント', 'cyan');
  log('3. 「新しい秘密鍵の生成」をクリック', 'cyan');
  log('4. ダウンロードしたJSONを serviceAccountKey.json として保存', 'cyan');
  process.exit(1);
}

const db = admin.firestore();

/**
 * 既存のskill_mastersコレクションを削除
 */
async function deleteExistingSkills() {
  log('\n🗑️  既存データ削除中...', 'yellow');
  
  try {
    const snapshot = await db.collection('skill_masters').get();
    const count = snapshot.size;
    
    if (count === 0) {
      log('削除対象のドキュメントがありません', 'cyan');
      return 0;
    }

    log(`${count}件のドキュメントを削除します`, 'yellow');
    
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    log(`✅ ${count}件のドキュメントを削除完了`, 'green');
    return count;
  } catch (error) {
    log('❌ 削除エラー:', 'red');
    console.error(error);
    throw error;
  }
}

/**
 * 技データをインポート
 */
async function importSkills() {
  log('\n📥 技データインポート開始', 'cyan');
  
  try {
    // JSONファイル読み込み
    const jsonPath = path.join(__dirname, 'all_skills.json');
    
    if (!fs.existsSync(jsonPath)) {
      throw new Error(`JSONファイルが見つかりません: ${jsonPath}`);
    }
    
    const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    const skills = data.skills;

    log(`${skills.length}件の技データを読み込みました`, 'cyan');

    // バリデーション
    log('\n🔍 データバリデーション中...', 'yellow');
    const requiredFields = ['skill_id', 'name', 'type', 'element', 'cost', 
                           'power_multiplier', 'accuracy', 'target', 'description'];
    
    for (const skill of skills) {
      for (const field of requiredFields) {
        if (!(field in skill)) {
          throw new Error(`必須フィールド不足: ${skill.skill_id || 'unknown'} - ${field}`);
        }
      }
    }
    log('✅ バリデーション完了', 'green');

    // インポート実行
    log('\n💾 Firestoreへ保存中...', 'yellow');
    const batch = db.batch();
    let count = 0;

    for (const skill of skills) {
      const docRef = db.collection('skill_masters').doc(skill.skill_id);
      
      // タイムスタンプ追加
      const skillData = {
        ...skill,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };
      
      batch.set(docRef, skillData);
      count++;

      // 進捗表示
      if (count % 10 === 0) {
        log(`  ${count}/${skills.length}件処理中...`, 'cyan');
      }

      // 500件ごとにコミット（Firestoreのバッチ制限）
      if (count % 500 === 0) {
        await batch.commit();
        log(`  ${count}件コミット完了`, 'green');
      }
    }

    // 残りをコミット
    if (count % 500 !== 0) {
      await batch.commit();
    }

    log(`\n✅ インポート完了: ${count}件`, 'green');
    return count;

  } catch (error) {
    log('\n❌ インポートエラー:', 'red');
    console.error(error);
    throw error;
  }
}

/**
 * インポート結果を検証
 */
async function verifyImport() {
  log('\n🔎 インポート結果を検証中...', 'yellow');
  
  try {
    const snapshot = await db.collection('skill_masters').get();
    const count = snapshot.size;
    
    log(`✅ ${count}件のドキュメントが存在します`, 'green');

    // サンプルドキュメント表示
    if (count > 0) {
      const sampleDoc = snapshot.docs[0];
      log('\n📄 サンプルドキュメント:', 'cyan');
      log(`ID: ${sampleDoc.id}`, 'cyan');
      const data = sampleDoc.data();
      log(JSON.stringify({
        skill_id: data.skill_id,
        name: data.name,
        type: data.type,
        element: data.element,
        cost: data.cost,
      }, null, 2), 'cyan');
    }

    // 統計情報
    log('\n📊 統計情報:', 'cyan');
    const stats = {
      cost: {},
      element: {},
      type: {}
    };

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      stats.cost[data.cost] = (stats.cost[data.cost] || 0) + 1;
      stats.element[data.element] = (stats.element[data.element] || 0) + 1;
      stats.type[data.type] = (stats.type[data.type] || 0) + 1;
    });

    log('【コスト別】', 'cyan');
    Object.entries(stats.cost).sort((a, b) => a[0] - b[0]).forEach(([cost, count]) => {
      log(`  コスト${cost}: ${count}種`, 'cyan');
    });

    log('【属性別】', 'cyan');
    Object.entries(stats.element).forEach(([element, count]) => {
      log(`  ${element}: ${count}種`, 'cyan');
    });

    log('【タイプ別】', 'cyan');
    Object.entries(stats.type).forEach(([type, count]) => {
      log(`  ${type}: ${count}種`, 'cyan');
    });

    return count;
  } catch (error) {
    log('❌ 検証エラー:', 'red');
    console.error(error);
    throw error;
  }
}

/**
 * メイン処理
 */
async function main() {
  try {
    log('╔════════════════════════════════════════╗', 'cyan');
    log('║  技マスターデータ インポートツール  ║', 'cyan');
    log('╚════════════════════════════════════════╝', 'cyan');

    // 確認プロンプト
    log('\n⚠️  以下の処理を実行します:', 'yellow');
    log('  1. 既存のskill_mastersコレクションを削除', 'yellow');
    log('  2. 新しい60件の技データをインポート', 'yellow');
    log('  3. インポート結果を検証', 'yellow');
    
    // 削除実行
    const deletedCount = await deleteExistingSkills();
    
    // インポート実行
    const importedCount = await importSkills();
    
    // 検証実行
    const verifiedCount = await verifyImport();

    // 完了報告
    log('\n╔════════════════════════════════════════╗', 'green');
    log('║          🎉 完了しました！           ║', 'green');
    log('╚════════════════════════════════════════╝', 'green');
    log(`削除: ${deletedCount}件`, 'green');
    log(`インポート: ${importedCount}件`, 'green');
    log(`検証: ${verifiedCount}件`, 'green');

    process.exit(0);

  } catch (error) {
    log('\n╔════════════════════════════════════════╗', 'red');
    log('║          ❌ エラー発生            ║', 'red');
    log('╚════════════════════════════════════════╝', 'red');
    console.error(error);
    process.exit(1);
  }
}

// 実行
main();
