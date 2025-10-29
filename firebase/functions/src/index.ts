import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Firebase Admin初期化
admin.initializeApp();

// サンプル関数
export const helloWorld = functions.https.onRequest((request, response) => {
  response.send("Monster Battle Game Functions - Ready!");
});

// バトル処理 (後で実装)
// export { executeTurn } from './battle/executeTurn';
// export { pullGacha } from './gacha/pullGacha';
// export { verifyReceipt } from './purchase/verifyReceipt';
