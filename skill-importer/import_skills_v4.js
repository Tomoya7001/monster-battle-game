#!/usr/bin/env node

/**
 * 技マスターデータ Firestoreインポートスクリプト v4.0
 * 
 * 新しいディレクトリ構造（skills/フォルダ内の分割ファイル）に対応
 * 
 * 使用方法:
 *   1. npm install firebase-admin
 *   2. Firebaseサービスアカウントキーをダウンロード
 *   3. node import_skills_v4.js
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
  magenta: '\x1b[35m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// サービスアカウントキーのパス
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
  process.exit(1);
}

const db = admin.firestore();

// 技データファイルのパス定義
const SKILLS_DIR = path.join(__dirname, '..', 'assets', 'data', 'skills');
const SKILL_FILES = [
  { name: 'common', file: 'skill_masters_common.json', description: '共通技' },
  { name: 'star5', file: 'skill_masters_star5.json', description: '★5専用技' },
  { name: 'star4', file: 'skill_masters_star4.json', description: '★4専用技' },
  { name: 'star3', file: 'skill_masters_star3.json', description: '★3専用技' },
  { name: 'star2', file: 'skill_masters_star2.json', description: '★2専用技' },
  { name: 'shared', file: 'skill_masters_shared.json', description: '共有技' },
];

/**
 * 全ての技データファイルを読み込む
 */
function loadAllSkillFiles() {
  log('\n📂 技データファイル読み込み中...', 'cyan');
  
  const allSkills = [];
  const loadStats = {};

  for (const fileInfo of SKILL_FILES) {
    const filePath = path.join(SKILLS_DIR, fileInfo.file);
    
    if (!fs.existsSync(filePath)) {
      log(`⚠️  ファイルが見つかりません: ${fileInfo.file}`, 'yellow');
      loadStats[fileInfo.name] = 0;
      continue;
    }

    try {
      const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      const skills = data.skills || [];
      
      // 各技にソースファイル情報を追加
      skills.forEach(skill => {
        skill._source = fileInfo.name;
      });

      allSkills.push(...skills);
      loadStats[fileInfo.name] = skills.length;
      log(`  ✅ ${fileInfo.description}: ${skills.length}件`, 'green');
    } catch (error) {
      log(`  ❌ ${fileInfo.file} 読み込みエラー: ${error.message}`, 'red');
      loadStats[fileInfo.name] = 0;
    }
  }

  log(`\n📊 合計: ${allSkills.length}件の技データ`, 'magenta');
  return { skills: allSkills, stats: loadStats };
}

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
    
    // バッチ削除（500件ごと）
    const batchSize = 500;
    const docs = snapshot.docs;
    
    for (let i = 0; i < docs.length; i += batchSize) {
      const batch = db.batch();
      const chunk = docs.slice(i, i + batchSize);
      chunk.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
      log(`  ${Math.min(i + batchSize, docs.length)}/${count}件削除...`, 'cyan');
    }
    
    log(`✅ ${count}件のドキュメントを削除完了`, 'green');
    return count;
  } catch (error) {
    log('❌ 削除エラー:', 'red');
    console.error(error);
    throw error;
  }
}

/**
 * 技データをバリデーション
 */
function validateSkills(skills) {
  log('\n🔍 データバリデーション中...', 'yellow');
  
  const requiredFields = ['skill_id', 'name', 'element', 'cost', 'accuracy', 'description'];
  const errors = [];
  const skillIds = new Set();

  for (const skill of skills) {
    // 必須フィールドチェック
    for (const field of requiredFields) {
      if (!(field in skill)) {
        errors.push(`必須フィールド不足: ${skill.skill_id || 'unknown'} - ${field}`);
      }
    }

    // 重複IDチェック
    if (skillIds.has(skill.skill_id)) {
      errors.push(`重複ID: ${skill.skill_id}`);
    }
    skillIds.add(skill.skill_id);

    // コスト範囲チェック
    if (skill.cost < 0 || skill.cost > 7) {
      errors.push(`コスト範囲外: ${skill.skill_id} (cost: ${skill.cost})`);
    }

    // 命中率範囲チェック
    if (skill.accuracy < 0 || skill.accuracy > 100) {
      errors.push(`命中率範囲外: ${skill.skill_id} (accuracy: ${skill.accuracy})`);
    }
  }

  if (errors.length > 0) {
    log('⚠️  バリデーションエラー:', 'yellow');
    errors.forEach(err => log(`  - ${err}`, 'yellow'));
    return false;
  }

  log('✅ バリデーション完了（エラーなし）', 'green');
  return true;
}

/**
 * 技データをFirestoreにインポート
 */
async function importSkills(skills) {
  log('\n💾 Firestoreへ保存中...', 'yellow');
  
  const batchSize = 500;
  let count = 0;

  for (let i = 0; i < skills.length; i += batchSize) {
    const batch = db.batch();
    const chunk = skills.slice(i, i + batchSize);

    for (const skill of chunk) {
      const docRef = db.collection('skill_masters').doc(skill.skill_id);
      
      // _sourceフィールドを削除してからFirestoreに保存
      const { _source, ...skillData } = skill;
      
      batch.set(docRef, {
        ...skillData,
        sourceFile: _source, // ソースファイル情報は別フィールドで保存
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      count++;
    }

    await batch.commit();
    log(`  ${count}/${skills.length}件保存完了...`, 'cyan');
  }

  log(`✅ インポート完了: ${count}件`, 'green');
  return count;
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

    // 統計情報
    const stats = {
      sourceFile: {},
      cost: {},
      element: {},
      category: {}
    };

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      
      // ソースファイル別
      const source = data.sourceFile || 'unknown';
      stats.sourceFile[source] = (stats.sourceFile[source] || 0) + 1;
      
      // コスト別
      stats.cost[data.cost] = (stats.cost[data.cost] || 0) + 1;
      
      // 属性別
      stats.element[data.element] = (stats.element[data.element] || 0) + 1;
      
      // カテゴリ別
      const cat = data.category || 'unknown';
      stats.category[cat] = (stats.category[cat] || 0) + 1;
    });

    log('\n📊 統計情報:', 'cyan');
    
    log('【ソースファイル別】', 'magenta');
    Object.entries(stats.sourceFile).forEach(([source, cnt]) => {
      log(`  ${source}: ${cnt}件`, 'cyan');
    });

    log('【コスト別】', 'magenta');
    Object.entries(stats.cost).sort((a, b) => Number(a[0]) - Number(b[0])).forEach(([cost, cnt]) => {
      log(`  コスト${cost}: ${cnt}件`, 'cyan');
    });

    log('【属性別】', 'magenta');
    Object.entries(stats.element).forEach(([element, cnt]) => {
      log(`  ${element}: ${cnt}件`, 'cyan');
    });

    log('【カテゴリ別】', 'magenta');
    Object.entries(stats.category).forEach(([cat, cnt]) => {
      log(`  ${cat}: ${cnt}件`, 'cyan');
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
    log('╔══════════════════════════════════════════════╗', 'cyan');
    log('║  技マスターデータ インポートツール v4.0   ║', 'cyan');
    log('║  (★ごと分割ファイル対応版)                ║', 'cyan');
    log('╚══════════════════════════════════════════════╝', 'cyan');

    // ファイル読み込み
    const { skills, stats } = loadAllSkillFiles();

    if (skills.length === 0) {
      log('❌ 読み込める技データがありません', 'red');
      process.exit(1);
    }

    // バリデーション
    if (!validateSkills(skills)) {
      log('\n⚠️  バリデーションエラーがありますが続行します', 'yellow');
    }

    // 確認
    log('\n⚠️  以下の処理を実行します:', 'yellow');
    log('  1. 既存のskill_mastersコレクションを削除', 'yellow');
    log(`  2. ${skills.length}件の技データをインポート`, 'yellow');
    log('  3. インポート結果を検証', 'yellow');

    // 削除実行
    const deletedCount = await deleteExistingSkills();
    
    // インポート実行
    const importedCount = await importSkills(skills);
    
    // 検証実行
    const verifiedCount = await verifyImport();

    // 完了報告
    log('\n╔══════════════════════════════════════════════╗', 'green');
    log('║            🎉 完了しました！              ║', 'green');
    log('╚══════════════════════════════════════════════╝', 'green');
    log(`削除: ${deletedCount}件`, 'green');
    log(`インポート: ${importedCount}件`, 'green');
    log(`検証: ${verifiedCount}件`, 'green');

    process.exit(0);

  } catch (error) {
    log('\n╔══════════════════════════════════════════════╗', 'red');
    log('║            ❌ エラー発生                 ║', 'red');
    log('╚══════════════════════════════════════════════╝', 'red');
    console.error(error);
    process.exit(1);
  }
}

// 実行
main();
