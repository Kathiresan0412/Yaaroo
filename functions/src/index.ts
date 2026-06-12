import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Generates a deterministic match ID from two UIDs by sorting them
 * alphabetically and joining with an underscore.
 * This prevents duplicate Match_Documents from concurrent like operations.
 */
function generateMatchId(uid1: string, uid2: string): string {
  return [uid1, uid2].sort().join("_");
}

/**
 * Sends an FCM notification to a user. Handles missing token gracefully
 * by skipping notification without throwing.
 */
async function sendNotification(
  targetUid: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  try {
    const userDoc = await db.collection("users").doc(targetUid).get();
    const userData = userDoc.data();

    if (!userData || !userData.fcmToken) {
      functions.logger.info(
        `Skipping notification for user ${targetUid}: no FCM token`
      );
      return;
    }

    const fcmToken: string = userData.fcmToken;

    await messaging.send({
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data,
    });

    functions.logger.info(`Notification sent to user ${targetUid}`);
  } catch (error) {
    // Handle invalid/expired token gracefully
    functions.logger.warn(
      `Failed to send notification to user ${targetUid}:`,
      error
    );
  }
}

/**
 * Trigger: onLikeCreated
 *
 * Fires when a new like document is created at likes/{uid}/liked/{targetUid}.
 * Performs two actions:
 * 1. If the like is a super like, sends an FCM notification to the target user.
 * 2. Checks for a reciprocal like. If mutual, creates a Match_Document and
 *    sends FCM notifications to both users.
 *
 * Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 18.3, 18.4, 18.5
 */
export const onLikeCreated = functions.firestore
  .document("likes/{uid}/liked/{targetUid}")
  .onCreate(async (snapshot, context) => {
    const { uid, targetUid } = context.params;
    const likeData = snapshot.data();

    // Handle super like notification (Requirement 9.6, 18.5)
    if (likeData?.superLike === true) {
      const likerDoc = await db.collection("users").doc(uid).get();
      const likerName = likerDoc.data()?.name || "Someone";

      await sendNotification(
        targetUid,
        "You received a Super Like! ⭐",
        `${likerName} super liked you!`,
        {
          type: "super_like",
          fromUid: uid,
        }
      );
    }

    // Check for reciprocal like (Requirement 9.1)
    const reciprocalRef = db
      .collection("likes")
      .doc(targetUid)
      .collection("liked")
      .doc(uid);

    const reciprocalDoc = await reciprocalRef.get();

    if (!reciprocalDoc.exists) {
      functions.logger.info(
        `No reciprocal like from ${targetUid} to ${uid}. No match created.`
      );
      return;
    }

    // Mutual like detected — create Match_Document (Requirement 9.2, 9.3)
    const matchId = generateMatchId(uid, targetUid);
    const matchRef = db.collection("matches").doc(matchId);

    // Use a transaction to prevent duplicate creation from race conditions
    await db.runTransaction(async (transaction) => {
      const existingMatch = await transaction.get(matchRef);

      if (existingMatch.exists) {
        functions.logger.info(
          `Match ${matchId} already exists. Skipping creation.`
        );
        return;
      }

      // Create Match_Document with required structure
      transaction.set(matchRef, {
        matchId,
        users: [uid, targetUid].sort(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastMessage: null,
        lastMessageAt: null,
        unreadCount: {
          [uid]: 0,
          [targetUid]: 0,
        },
      });
    });

    // Send match notifications to both users (Requirement 9.4, 9.5)
    const [userDoc, targetDoc] = await Promise.all([
      db.collection("users").doc(uid).get(),
      db.collection("users").doc(targetUid).get(),
    ]);

    const userName = userDoc.data()?.name || "Someone";
    const targetName = targetDoc.data()?.name || "Someone";

    await Promise.all([
      sendNotification(uid, "It's a Match! 🎉", `You and ${targetName} liked each other!`, {
        type: "match",
        matchId,
      }),
      sendNotification(targetUid, "It's a Match! 🎉", `You and ${userName} liked each other!`, {
        type: "match",
        matchId,
      }),
    ]);

    functions.logger.info(`Match created: ${matchId}`);
  });

/**
 * Trigger: onNewMessage
 *
 * Fires when a new message is created in matches/{matchId}/messages/{messageId}.
 * Performs two actions:
 * 1. Updates lastMessage and lastMessageAt on the Match_Document.
 * 2. Sends an FCM push notification to the recipient if they are not the sender.
 *
 * Requirements: 13.5, 13.6, 18.3
 */
export const onNewMessage = functions.firestore
  .document("matches/{matchId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const { matchId } = context.params;
    const messageData = snapshot.data();

    if (!messageData) {
      functions.logger.warn("Message data is empty, skipping.");
      return;
    }

    const senderId: string = messageData.senderId;
    const text: string = messageData.text || "";
    const type: string = messageData.type || "text";

    // Determine lastMessage display text
    const lastMessageText = type === "image" ? "📷 Photo" : text;

    // Update lastMessage and lastMessageAt on Match_Document
    const matchRef = db.collection("matches").doc(matchId);

    await matchRef.update({
      lastMessage: lastMessageText,
      lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Get match document to identify the recipient
    const matchDoc = await matchRef.get();
    const matchData = matchDoc.data();

    if (!matchData || !matchData.users) {
      functions.logger.warn(`Match ${matchId} not found or has no users.`);
      return;
    }

    const users: string[] = matchData.users;
    const recipientUid = users.find((u: string) => u !== senderId);

    if (!recipientUid) {
      functions.logger.warn("Could not determine recipient from match users.");
      return;
    }

    // Get sender name for notification
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.data()?.name || "Someone";

    // Send notification to recipient
    const notificationBody =
      type === "image" ? `${senderName} sent a photo` : `${senderName}: ${text}`;

    await sendNotification(recipientUid, "New Message 💬", notificationBody, {
      type: "message",
      matchId,
      senderId,
    });
  });
