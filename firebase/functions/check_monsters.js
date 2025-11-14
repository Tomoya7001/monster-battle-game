const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'monster-battle-game-2025'
});

const db = admin.firestore();

async function checkMonsterMasters() {
  console.log('\n========================================');
  console.log('monster_masters コレクション');
  console.log('========================================\n');

  try {
    const snapshot = await db.collection('monster_masters').get();
    console.log(`ドキュメント数: ${snapshot.docs.length}\n`);

    snapshot.docs.forEach((doc, index) => {
      console.log(`📄 [${index + 1}] ID: ${doc.id}`);
      const data = doc.data();
      
      // 主要なフィールドを表示
      console.log(`   名前: ${data.name || data.monster_name || '不明'}`);
      console.log(`   種族: ${data.species || '不明'}`);
      console.log(`   属性: ${data.attributes || data.element || '不明'}`);
      console.log(`   レアリティ: ${data.rarity || '不明'}`);
      
      // base_stats がある場合
      if (data.base_stats) {
        console.log(`   基礎ステータス:`, data.base_stats);
      }
      
      console.log('');
    });
  } catch (error) {
    console.error('❌ エラー:', error.message);
  }
  
  process.exit(0);
}

checkMonsterMasters();
