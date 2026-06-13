const path = require('path');
const { initializeApp, applicationDefault, cert, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

let firebaseApp = null;
let firestore = null;
let messaging = null;

function isFirebaseConfigured() {
  return Boolean(
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH || process.env.FIREBASE_PROJECT_ID
  );
}

// Resolve the service-account path so both absolute paths and paths relative to
// the backend root (e.g. ./service-account.json) work. Without this, require()
// would resolve a relative path against this file's folder (src/config) and a
// bare filename would be treated as an npm module.
function resolveServiceAccountPath() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!raw) return null;
  return path.isAbsolute(raw) ? raw : path.resolve(process.cwd(), raw);
}

function getApp() {
  if (firebaseApp) return firebaseApp;

  if (!isFirebaseConfigured()) {
    const error = new Error(
      'Firebase is not configured. Set FIREBASE_PROJECT_ID and FIREBASE_SERVICE_ACCOUNT_PATH in backend/.env'
    );
    error.statusCode = 503;
    throw error;
  }

  const serviceAccountPath = resolveServiceAccountPath();

  firebaseApp = getApps().length
    ? getApps()[0]
    : initializeApp({
        credential: serviceAccountPath
          ? cert(require(serviceAccountPath))
          : applicationDefault(),
        projectId: process.env.FIREBASE_PROJECT_ID,
      });

  return firebaseApp;
}

function getDb() {
  if (firestore) return firestore;
  firestore = getFirestore(getApp());
  return firestore;
}

// FCM client, used by the notification service to push directly from the
// backend (the Admin SDK can push without a Cloud Function, since the backend
// itself authors the notifications — unlike chat, where the client writes).
function getMessagingClient() {
  if (messaging) return messaging;
  messaging = getMessaging(getApp());
  return messaging;
}

module.exports = {
  getDb,
  getMessagingClient,
  isFirebaseConfigured,
};
