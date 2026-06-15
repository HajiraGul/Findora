const path = require('path');
const { initializeApp, applicationDefault, cert, getApps } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

let firebaseApp = null;
let firestore = null;
let messaging = null;

function isFirebaseConfigured() {
  return Boolean(
    process.env.FIREBASE_SERVICE_ACCOUNT ||
      process.env.FIREBASE_SERVICE_ACCOUNT_BASE64 ||
      process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
      process.env.FIREBASE_PROJECT_ID
  );
}

// Load the service-account credential. Order of preference:
//   1. FIREBASE_SERVICE_ACCOUNT        — the raw JSON (set this on Vercel)
//   2. FIREBASE_SERVICE_ACCOUNT_BASE64 — base64 of the JSON (avoids newline/quoting issues)
//   3. FIREBASE_SERVICE_ACCOUNT_PATH   — a file path (convenient for local dev)
// On serverless (Vercel) the key file isn't deployed, so the env-var forms are
// the only ones that work there; the path form stays for local development.
function loadServiceAccount() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (raw && raw.trim()) {
    return JSON.parse(raw);
  }

  const b64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  if (b64 && b64.trim()) {
    return JSON.parse(Buffer.from(b64, 'base64').toString('utf8'));
  }

  const filePath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (filePath && filePath.trim()) {
    // Resolve relative paths (e.g. ./service-account.json) against the backend
    // root, not this file's folder, and avoid bare names being treated as modules.
    const resolved = path.isAbsolute(filePath)
      ? filePath
      : path.resolve(process.cwd(), filePath);
    return require(resolved);
  }

  return null;
}

function getApp() {
  if (firebaseApp) return firebaseApp;

  if (!isFirebaseConfigured()) {
    const error = new Error(
      'Firebase is not configured. Set FIREBASE_SERVICE_ACCOUNT (or _BASE64 / _PATH) and FIREBASE_PROJECT_ID'
    );
    error.statusCode = 503;
    throw error;
  }

  const serviceAccount = loadServiceAccount();

  firebaseApp = getApps().length
    ? getApps()[0]
    : initializeApp({
        credential: serviceAccount ? cert(serviceAccount) : applicationDefault(),
        projectId:
          process.env.FIREBASE_PROJECT_ID ||
          (serviceAccount && serviceAccount.project_id),
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
