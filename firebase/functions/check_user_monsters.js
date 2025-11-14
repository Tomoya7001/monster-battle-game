const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'monster-battle-game-2025'
});

const db = admin.firestore();

async function checkUserMonsters() {
  try {
    console.log('\n========================================');
    console.log('user_monsters コレクション（全データ）');
    console.log('========================================\n');

    const snapshot = await db.collection('user_monsters')
      .limit(3)
      .get();

    console.log(`ドキュメント数: ${snapshot.size}\n`);

    if (snapshot.empty) {
      console.log('⚠️  user_monstersコレクションが空です\n');
      process.exit(0);
    }

    snapshot.forEach((doc, index) => {
      const data = doc.data();
      console.log(`📄 [${index + 1}] ID: ${doc.id}`);
      console.log('\n   📋 全フィールド:');
      Object.keys(data).sort().forEach(key => {
        const value = data[key];
        let type = typeof value;
        if (Array.isArray(value)) {
          type = `Array[${value.length}]`;
          console.log(`      ${key}: ${type} → ${JSON.stringify(value)}`);
        } else if (value === null) {
          console.log(`      ${key}: null`);
        } else if (typeof value === 'object') {
          console.log(`      ${key}: ${type} → ${JSON.stringify(value)}`);
        } else {
          console.log(`      ${key}: ${type} → ${value}`);
        }
      });
      console.log('\n========================================\n');
    });

    process.exit(0);
  } catch (error) {
    console.error('エラー:', error);
    process.exit(1);
  }
}

checkUserMonsters();
