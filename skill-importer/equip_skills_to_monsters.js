#!/usr/bin/env node

/**
 * モンスターに技を装備するスクリプト
 * 
 * 使用方法:
 *   node equip_skills_to_monsters.js
 */

const admin = require('firebase-admin');

// サービスアカウントキー読み込み
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// カラー出力
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

/**
 * 属性に応じたデフォルト技を取得
 */
function getDefaultSkillsForElement(element) {
  const skillMap = {
    fire: ['skill_001', 'skill_101', 'skill_102', 'skill_801'],
    water: ['skill_001', 'skill_201', 'skill_202', 'skill_203'],
    thunder: ['skill_001', 'skill_301', 'skill_302', 'skill_304'],
    wind: ['skill_001', 'skill_401', 'skill_402', 'skill_404'],
    earth: ['skill_001', 'skill_501', 'skill_502', 'skill_505'],
    light: ['skill_001', 'skill_601', 'skill_602', 'skill_604'],
    dark: ['skill_001', 'skill_701', 'skill_702', 'skill_704'],
    none: ['skill_001', 'skill_002', 'skill_005', 'skill_009'],
  };

  return skillMap[element.toLowerCase()] || ['skill_001', 'skill_002', 'skill_005', 'skill_007'];
}

/**
 * 全モンスターに技を装備
 */
async function equipSkillsToAllMonsters() {
  try {
    log('\n╔════════════════════════════════════════╗', 'cyan');
    log('║     モンスター技装備スクリプト     ║', 'cyan');
    log('╚════════════════════════════════════════╝', 'cyan');

    // 全ユーザーモンスターを取得
    log('\n📥 モンスターデータ取得中...', 'yellow');
    const monstersSnapshot = await db.collection('user_monsters').get();
    const totalCount = monstersSnapshot.size;

    if (totalCount === 0) {
      log('❌ モンスターが見つかりません', 'red');
      process.exit(1);
    }

    log(`✅ ${totalCount}体のモンスターを取得`, 'green');

    // 技マスターデータを取得（存在確認用）
    log('\n🔍 技マスターデータ確認中...', 'yellow');
    const skillsSnapshot = await db.collection('skill_masters').get();
    const skillIds = new Set(skillsSnapshot.docs.map(doc => doc.id));
    log(`✅ ${skillIds.size}種類の技を確認`, 'green');

    // モンスターマスターデータも取得（属性確認用）
    log('\n🔍 モンスターマスターデータ確認中...', 'yellow');
    const monsterMastersSnapshot = await db.collection('monster_masters').get();
    const monsterMasters = {};
    monsterMastersSnapshot.docs.forEach(doc => {
      monsterMasters[doc.id] = doc.data();
    });
    log(`✅ ${Object.keys(monsterMasters).length}種類のモンスターマスター確認`, 'green');

    // バッチ処理
    log('\n💾 技装備中...', 'yellow');
    let updated = 0;
    let skipped = 0;
    let errors = 0;

    for (const doc of monstersSnapshot.docs) {
      try {
        const monsterData = doc.data();
        const masterId = monsterData.monster_id;
        const currentSkills = monsterData.equipped_skills || [];

        // 既に技が装備されている場合はスキップ
        if (currentSkills.length >= 4) {
          skipped++;
          if ((skipped + updated) % 10 === 0) {
            log(`  処理中: ${skipped + updated}/${totalCount}件`, 'cyan');
          }
          continue;
        }

        // マスターデータから属性取得
        const masterData = monsterMasters[masterId];
        if (!masterData) {
          log(`  ⚠️  ${doc.id}: マスターデータなし`, 'yellow');
          skipped++;
          continue;
        }

        // 属性に応じたデフォルト技を取得
        const element = masterData.element || 'none';
        const defaultSkills = getDefaultSkillsForElement(element);

        // 技の存在確認
        const validSkills = defaultSkills.filter(skillId => skillIds.has(skillId));
        if (validSkills.length === 0) {
          log(`  ⚠️  ${doc.id}: 有効な技がありません`, 'yellow');
          skipped++;
          continue;
        }

        // 更新
        await doc.ref.update({
          equipped_skills: validSkills,
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        });

        updated++;
        if (updated % 10 === 0) {
          log(`  更新完了: ${updated}/${totalCount}件`, 'green');
        }

      } catch (error) {
        log(`  ❌ ${doc.id}: エラー - ${error.message}`, 'red');
        errors++;
      }
    }

    // 完了報告
    log('\n╔════════════════════════════════════════╗', 'green');
    log('║          🎉 完了しました！           ║', 'green');
    log('╚════════════════════════════════════════╝', 'green');
    log(`更新: ${updated}件`, 'green');
    log(`スキップ: ${skipped}件`, 'yellow');
    log(`エラー: ${errors}件`, 'red');

    // サンプル確認
    if (updated > 0) {
      log('\n📄 サンプル確認:', 'cyan');
      const sampleDoc = await db.collection('user_monsters')
        .where('equipped_skills', '!=', [])
        .limit(1)
        .get();
      
      if (!sampleDoc.empty) {
        const data = sampleDoc.docs[0].data();
        const masterId = data.monster_id;
        const masterData = monsterMasters[masterId];
        log(`  モンスター: ${masterData?.name || 'Unknown'} (${masterData?.element || 'none'})`, 'cyan');
        log(`  装備技: ${data.equipped_skills.join(', ')}`, 'cyan');
      }
    }

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
equipSkillsToAllMonsters();
