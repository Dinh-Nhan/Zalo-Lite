/**
 * Cloud Functions for Zalo Lite Admin — Notification Dispatcher
 *
 * Trigger: onDocumentCreated('admin_notifications/{notifId}')
 * Purpose: Auto-send FCM push notification when admin creates a notification
 *          document with status = 'sent' | 'scheduled'
 *
 * Setup:
 *   1. cd functions && npm install
 *   2. firebase deploy --only functions
 *   3. Set FCM Server Key: firebase functions:config:set fcm.server_key="YOUR_KEY"
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const { getFirestore } = require('firebase-admin/firestore');
const { CloudTasksClient } = require('@google-cloud/tasks');

initializeApp();

// ─── Send Immediately ────────────────────────────────────────
exports.onNotificationCreated = onDocumentCreated(
  'admin_notifications/{notifId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const { title, body, status, target_audience, target_user_id } = data;

    // Only dispatch if status === 'sent'
    if (status !== 'sent') return;

    const messaging = getMessaging();

    if (target_audience === 'all') {
      // Send to topic 'all_users' (mobile app must subscribe on login)
      await messaging.send({
        topic: 'all_users',
        notification: { title, body },
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
    } else if (target_audience === 'specific' && target_user_id) {
      // Get FCM token from user document
      const db = getFirestore();
      const userDoc = await db.collection('users').doc(target_user_id).get();
      const fcmToken = userDoc.data()?.fcm_token;

      if (fcmToken) {
        await messaging.send({
          token: fcmToken,
          notification: { title, body },
          android: { priority: 'high' },
          apns: { payload: { aps: { sound: 'default' } } },
        });
      }
    }

    console.log(`[Notification] Sent: "${title}" to ${target_audience}`);
  }
);
