// One-off script to provision an Expeditioneer Admin Console account: creates
// (or reuses) a Firebase Auth email/password user and grants it an
// `admins/{uid}` Firestore doc. Uses the Admin SDK (bypasses security rules).
//
// Usage:
//   GOOGLE_APPLICATION_CREDENTIALS=~/.config/expeditioneer/service-account.json \
//   ADMIN_EMAIL=you@example.com ADMIN_PASSWORD=choose-a-password \
//   node seed_admin.mjs
//
// Idempotent: reuses the existing Auth user for ADMIN_EMAIL if one already
// exists (password is left untouched in that case), and set(..., {merge:
// true}) on the admins/{uid} doc.

import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const email = process.env.ADMIN_EMAIL;
const password = process.env.ADMIN_PASSWORD;

if (!email || !password) {
  console.error("Set ADMIN_EMAIL and ADMIN_PASSWORD environment variables before running.");
  process.exitCode = 1;
  process.exit();
}

initializeApp({ credential: applicationDefault() });
const auth = getAuth();
const db = getFirestore();

async function seedAdmin() {
  let user;
  try {
    user = await auth.getUserByEmail(email);
    console.log(`Reusing existing Auth user for ${email} (uid: ${user.uid}).`);
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
    user = await auth.createUser({ email, password });
    console.log(`Created Auth user for ${email} (uid: ${user.uid}).`);
  }

  await db.collection("admins").doc(user.uid).set(
    {
      role: "superadmin",
      managedEventIds: [],
    },
    { merge: true },
  );

  console.log(`Granted admin access to ${email} (uid: ${user.uid}).`);
}

seedAdmin().catch((error) => {
  console.error("Admin seed failed:", error);
  process.exitCode = 1;
});
