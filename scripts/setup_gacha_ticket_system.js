// scripts/setup_gacha_ticket_system.js
// Firebase Admin SDKを使用してFirestoreに初期データを投入するスクリプト

const admin = require('firebase-admin');

// Firebase Admin初期化
admin.initializeApp({
    credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function setupGachaTicketExchangeOptions() {
    console.log('ガチャチケット交換オプションをセットアップ中...');

    const options = [
        {
            name: '★4以上確定召喚',
            requiredTickets: 50,
            rewardType: 'star4',
            guaranteeRate: 97,
            description: '97%で★4、3%で★5が排出されます',
        },
        {
            name: '★5以上確定召喚',
            requiredTickets: 100,
            rewardType: 'star5',
            guaranteeRate: 97,
            description: '97%で★5、3%で★4が排出されます',
        },
    ];

    const batch = db.batch();

    for (const option of options) {
        const docRef = db.collection('gacha_ticket_exchange').doc();
        batch.set(docRef, option);
    }

    await batch.commit();
    console.log('✅ ガチャチケット交換オプションのセットアップ完了');
}

async function createIndexes() {
    console.log('インデックスを作成中...');

    // Note: Firestoreのインデックスは通常、Firebaseコンソールまたは
    // firestore.indexes.jsonで定義します

    console.log('⚠️ 以下のインデックスをFirebaseコンソールで作成してください:');
    console.log('1. user_gacha_tickets: userId (昇順)');
    console.log('2. gacha_ticket_exchange: requiredTickets (昇順)');
    console.log('3. gacha_ticket_exchange_history: userId (昇順), exchangedAt (降順)');
}

async function main() {
    try {
        await setupGachaTicketExchangeOptions();
        await createIndexes();

        console.log('\n🎉 天井システムのセットアップが完了しました!');
        console.log('\n次のステップ:');
        console.log('1. Firebaseコンソールでインデックスを作成');
        console.log('2. firestore.rulesをデプロイ');
        console.log('3. Flutter アプリをビルド & テスト');

        process.exit(0);
    } catch (error) {
        console.error('❌ エラーが発生しました:', error);
        process.exit(1);
    }
}

main();