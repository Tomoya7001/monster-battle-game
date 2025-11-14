const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'monster-battle-game-2025'
});

const db = admin.firestore();

async function checkMaster() {
  try {
    const doc = await db.collection('monster_masters').doc('8').get();
    
    if (!doc.exists) {
      console.log('❌ ID:8のマスターデータが存在しません');
      process.exit(1);
    }

    const data = doc.data();
    console.log('\n📄 monster_masters ID: 8');
    console.log(JSON.stringify(data, null, 2));
    
    console.log('\n🔍 フィールド型チェック:');
    Object.keys(data).forEach(key => {
      const val = data[key];
      console.log(`${key}: ${Array.isArray(val) ? 'Array' : typeof val}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('エラー:', error);
    process.exit(1);
  }
}

checkMaster();
