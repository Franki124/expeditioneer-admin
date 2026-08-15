// One-off dev seed script for the Expeditioneer QR Treasure Hunt demo event.
// Uses the Admin SDK (bypasses Firestore security rules) so it works
// regardless of what phase-1 client rules currently allow.
//
// Usage:
//   GOOGLE_APPLICATION_CREDENTIALS=~/.config/expeditioneer/service-account.json node seed.mjs
//
// Idempotent: fixed doc IDs + set(..., {merge: true}), safe to re-run.

import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";

initializeApp({ credential: applicationDefault() });
const db = getFirestore();

const EVENT_ID = "demo-event";
const now = Date.now();

const journals = [
  {
    id: "journal-01",
    title: "The Weary Traveler's Page",
    blurb: "A rain-smudged entry describing the first steps into the festival grounds.",
    order: 1,
    artUrl: "",
    has3D: false,
    model3dUrl: null,
    manualCode: "TRV294",
  },
  {
    id: "journal-02",
    title: "Sketch of a Gate-Warden",
    blurb: "A hurried charcoal sketch of something watching from the treeline.",
    order: 2,
    artUrl: "",
    has3D: false,
    model3dUrl: null,
    manualCode: "GTW817",
  },
  {
    id: "gestral-01",
    title: "Mossbound Gestral",
    blurb: "A small companion creature, moss-covered and quietly curious.",
    order: 3,
    artUrl: "",
    has3D: true,
    model3dUrl: "",
    manualCode: "MOS453",
  },
  {
    id: "journal-03",
    title: "The Merchant's Warning",
    blurb: "A page torn from a merchant's ledger, warning of the coming dusk.",
    order: 4,
    artUrl: "",
    has3D: false,
    model3dUrl: null,
    manualCode: "MER602",
  },
  {
    id: "gestral-02",
    title: "Emberling Gestral",
    blurb: "A small ember-warm companion, said to guide lost expeditioneers home.",
    order: 5,
    artUrl: "",
    has3D: true,
    model3dUrl: "",
    manualCode: "EMB759",
  },
];

async function seed() {
  const eventRef = db.collection("events").doc(EVENT_ID);
  await eventRef.set(
    {
      name: "Summer Fest Demo",
      location: "Demo Venue Grounds",
      joinCode: "DEMO2026",
      startAt: Timestamp.fromMillis(now - 60 * 60 * 1000),
      endAt: Timestamp.fromMillis(now + 6 * 60 * 60 * 1000),
      status: "live",
      maxParticipants: null,
      journalCount: journals.length,
      createdBy: "seed-script",
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  const batch = db.batch();
  for (const journal of journals) {
    const ref = eventRef.collection("journals").doc(journal.id);
    const { id, ...data } = journal;
    batch.set(ref, { ...data, qrToken: `token-${id}`, scanCount: 0 }, { merge: true });
  }
  await batch.commit();

  console.log(`Seeded event "${EVENT_ID}" with join code DEMO2026 and ${journals.length} journals.`);
}

seed().catch((error) => {
  console.error("Seed failed:", error);
  process.exitCode = 1;
});
