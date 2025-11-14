const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'monster-battle-game-2025'
});

const db = admin.firestore();

async function createDummyMonsters() {
  const userId = 'dev_user_12345';
  const monsters = [
    { monster_id: '1', level: 10 },
    { monster_id: '2', level: 15 },
    { monster_id: '5', level: 20 },
  ];

  const batch = db.batch();

  for (const monster of monsters) {
    const docRef = db.collection('user_monsters').doc();
    batch.set(docRef, {
      user_id: userId,
      monster_id: monster.monster_id,
      level: monster.level,
      exp: 0,
      current_hp: 100,
      last_hp_update: admin.firestore.FieldValue.serverTimestamp(),
      intimacy_level: 1,
      intimacy_exp: 0,
      iv_hp: Math.floor(Math.random() * 21) - 10,
      iv_attack: Math.floor(Math.random() * 21) - 10,
      iv_defense: Math.floor(Math.random() * 21) - 10,
      iv_magic: Math.floor(Math.random() * 21) - 10,
      iv_speed: Math.floor(Math.random() * 21) - 10,
      point_hp: 0,
      point_attack: 0,
      point_defense: 0,
      point_magic: 0,
      point_speed: 0,
      remaining_points: 0,
      main_trait_id: null,
      equipped_skills: [],
      equipped_equipment: [],
      skin_id: 1,
      is_favorite: false,
      is_locked: false,
      acquired_at: admin.firestore.FieldValue.serverTimestamp(),
      last_used_at: null,
    });
  }

  await batch.commit();
  console.log(`✅ ${monsters.length}体のモンスターを作成しました`);
  process.exit(0);
}

createDummyMonsters();
