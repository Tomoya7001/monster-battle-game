const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'monster-battle-game-2025'
});

const db = admin.firestore();

async function checkDevUserMonsters() {
  try {
    const snapshot = await db.collection('user_monsters')
      .where('user_id', '==', 'dev_user_12345')
      .get();

    console.log(`\ndev_user_12345のモンスター数: ${snapshot.size}\n`);

    snapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`📄 [${index + 1}] ID: ${doc.id}`);
      console.log('   フィールドチェック:');
      
      // 配列チェック
      ['equipped_skills', 'equipped_equipment', 'main_trait_id'].forEach(field => {
        const val = data[field];
        console.log(`   ${field}:`);
        console.log(`      型: ${Array.isArray(val) ? 'Array' : typeof val}`);
        console.log(`      値: ${JSON.stringify(val)}`);
      });
      console.log('');
    });

    process.exit(0);
  } catch (error) {
    console.error('エラー:', error);
    process.exit(1);
  }
}

checkDevUserMonsters();
