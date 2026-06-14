"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onNewMessage = exports.onLikeCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
/**
 * Generates a deterministic match ID from two UIDs by sorting them
 * alphabetically and joining with an underscore.
 * This prevents duplicate Match_Documents from concurrent like operations.
 */
function generateMatchId(uid1, uid2) {
    return [uid1, uid2].sort().join("_");
}
/**
 * Sends an FCM notification to a user. Handles missing token gracefully
 * by skipping notification without throwing.
 */
async function sendNotification(targetUid, title, body, data) {
    try {
        const userDoc = await db.collection("users").doc(targetUid).get();
        const userData = userDoc.data();
        if (!userData || !userData.fcmToken) {
            functions.logger.info(`Skipping notification for user ${targetUid}: no FCM token`);
            return;
        }
        const fcmToken = userData.fcmToken;
        await messaging.send({
            token: fcmToken,
            notification: {
                title,
                body,
            },
            data,
        });
        functions.logger.info(`Notification sent to user ${targetUid}`);
    }
    catch (error) {
        // Handle invalid/expired token gracefully
        functions.logger.warn(`Failed to send notification to user ${targetUid}:`, error);
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
exports.onLikeCreated = functions.firestore
    .document("likes/{uid}/liked/{targetUid}")
    .onCreate(async (snapshot, context) => {
    var _a, _b, _c;
    const { uid, targetUid } = context.params;
    const likeData = snapshot.data();
    // Handle super like notification (Requirement 9.6, 18.5)
    if ((likeData === null || likeData === void 0 ? void 0 : likeData.superLike) === true) {
        const likerDoc = await db.collection("users").doc(uid).get();
        const likerName = ((_a = likerDoc.data()) === null || _a === void 0 ? void 0 : _a.name) || "Someone";
        await sendNotification(targetUid, "You received a Super Like! ⭐", `${likerName} super liked you!`, {
            type: "super_like",
            fromUid: uid,
        });
    }
    // Check for reciprocal like (Requirement 9.1)
    const reciprocalRef = db
        .collection("likes")
        .doc(targetUid)
        .collection("liked")
        .doc(uid);
    const reciprocalDoc = await reciprocalRef.get();
    if (!reciprocalDoc.exists) {
        functions.logger.info(`No reciprocal like from ${targetUid} to ${uid}. No match created.`);
        return;
    }
    // Mutual like detected — create Match_Document (Requirement 9.2, 9.3)
    const matchId = generateMatchId(uid, targetUid);
    const matchRef = db.collection("matches").doc(matchId);
    // Use a transaction to prevent duplicate creation from race conditions
    await db.runTransaction(async (transaction) => {
        const existingMatch = await transaction.get(matchRef);
        if (existingMatch.exists) {
            functions.logger.info(`Match ${matchId} already exists. Skipping creation.`);
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
    const userName = ((_b = userDoc.data()) === null || _b === void 0 ? void 0 : _b.name) || "Someone";
    const targetName = ((_c = targetDoc.data()) === null || _c === void 0 ? void 0 : _c.name) || "Someone";
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
exports.onNewMessage = functions.firestore
    .document("matches/{matchId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
    var _a;
    const { matchId } = context.params;
    const messageData = snapshot.data();
    if (!messageData) {
        functions.logger.warn("Message data is empty, skipping.");
        return;
    }
    const senderId = messageData.senderId;
    const text = messageData.text || "";
    const type = messageData.type || "text";
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
    const users = matchData.users;
    const recipientUid = users.find((u) => u !== senderId);
    if (!recipientUid) {
        functions.logger.warn("Could not determine recipient from match users.");
        return;
    }
    // Get sender name for notification
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = ((_a = senderDoc.data()) === null || _a === void 0 ? void 0 : _a.name) || "Someone";
    // Send notification to recipient
    const notificationBody = type === "image" ? `${senderName} sent a photo` : `${senderName}: ${text}`;
    await sendNotification(recipientUid, "New Message 💬", notificationBody, {
        type: "message",
        matchId,
        senderId,
    });
});
//# sourceMappingURL=index.js.map