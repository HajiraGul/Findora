const { initializeApp, applicationDefault, cert, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

let firestore = null;

function isFirebaseConfigured() {
  return Boolean(
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH || process.env.FIREBASE_PROJECT_ID
  );
}

function getDb() {
  if (firestore) return firestore;

  if (!isFirebaseConfigured()) {
    const error = new Error(
      'Chat is not configured. Set FIREBASE_PROJECT_ID and FIREBASE_SERVICE_ACCOUNT_PATH in backend/.env'
    );
    error.statusCode = 503;
    throw error;
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  const app = getApps().length
    ? getApps()[0]
    : initializeApp({
        credential: serviceAccountPath
          ? cert(require(serviceAccountPath))
          : applicationDefault(),
        projectId: process.env.FIREBASE_PROJECT_ID,
      });

  firestore = getFirestore(app);
  return firestore;
}

module.exports = {
  getDb,
  isFirebaseConfigured,
};
