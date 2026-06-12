import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/chat_message.dart';

/// Exception thrown when a chat message fails validation.
class MessageValidationException implements Exception {
  final String message;
  const MessageValidationException(this.message);

  @override
  String toString() => 'MessageValidationException: $message';
}

/// Exception thrown when sending a message fails.
///
/// Retains the original content so the UI can offer a retry option without
/// losing the user's message.
class MessageSendException implements Exception {
  final String message;
  final String? retainedText;
  final File? retainedImage;

  const MessageSendException(
    this.message, {
    this.retainedText,
    this.retainedImage,
  });

  @override
  String toString() => 'MessageSendException: $message';
}

/// Minimum message length (inclusive).
const int minMessageLength = 1;

/// Maximum message length (inclusive).
const int maxMessageLength = 5000;

/// Validates a text message.
///
/// Returns `true` if the [text] contains at least one non-whitespace character
/// and its length is between [minMessageLength] and [maxMessageLength]
/// inclusive. Returns `false` otherwise.
bool isValidMessage(String text) {
  if (text.isEmpty) return false;
  if (text.trim().isEmpty) return false;
  if (text.length < minMessageLength || text.length > maxMessageLength) {
    return false;
  }
  return true;
}

/// Abstract interface for real-time chat operations.
///
/// Messages are stored in the Firestore subcollection
/// `matches/{matchId}/messages/{messageId}`.
abstract class ChatService {
  /// Real-time stream of messages ordered by timestamp ascending.
  Stream<List<ChatMessage>> watchMessages(String matchId);

  /// Sends a text message.
  ///
  /// Validates the [text] before creating the message document. Updates
  /// `lastMessage` and `lastMessageAt` on the parent Match_Document.
  ///
  /// Throws [MessageValidationException] if [text] is invalid.
  /// Throws [MessageSendException] if the write fails.
  Future<void> sendTextMessage(String matchId, String senderId, String text);

  /// Sends an image message.
  ///
  /// Uploads the [image] to Firebase Storage, then creates a message document
  /// with the resulting image URL. Updates `lastMessage` and `lastMessageAt`
  /// on the parent Match_Document.
  ///
  /// Throws [MessageSendException] if the upload or write fails.
  Future<void> sendImageMessage(String matchId, String senderId, File image);
}

/// Firestore-backed implementation of [ChatService].
class FirestoreChatService implements ChatService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid;

  FirestoreChatService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _uuid = uuid ?? const Uuid();

  @override
  Stream<List<ChatMessage>> watchMessages(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromFirestore(doc);
      }).toList();
    });
  }

  @override
  Future<void> sendTextMessage(
    String matchId,
    String senderId,
    String text,
  ) async {
    // Validate message content
    if (!isValidMessage(text)) {
      if (text.isEmpty || text.trim().isEmpty) {
        throw const MessageValidationException(
          'Message cannot be empty or contain only whitespace.',
        );
      }
      if (text.length > maxMessageLength) {
        throw const MessageValidationException(
          'Message exceeds maximum length of 5000 characters.',
        );
      }
      throw const MessageValidationException(
        'Message must be between 1 and 5000 characters.',
      );
    }

    final messageId = _uuid.v4();
    final now = DateTime.now();

    final message = ChatMessage(
      messageId: messageId,
      senderId: senderId,
      text: text,
      type: 'text',
      timestamp: now,
    );

    try {
      // Create message document
      await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Update lastMessage and lastMessageAt on the Match_Document
      await _firestore.collection('matches').doc(matchId).update({
        'lastMessage': text,
        'lastMessageAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      throw MessageSendException(
        'Failed to send message: ${e.toString()}',
        retainedText: text,
      );
    }
  }

  @override
  Future<void> sendImageMessage(
    String matchId,
    String senderId,
    File image,
  ) async {
    final messageId = _uuid.v4();
    final now = DateTime.now();

    String imageUrl;

    try {
      // Upload image to Firebase Storage
      final fileName = '${_uuid.v4()}.jpg';
      final storagePath = 'chats/$matchId/$fileName';
      final ref = _storage.ref().child(storagePath);

      await ref.putFile(
        image,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      imageUrl = await ref.getDownloadURL();
    } catch (e) {
      throw MessageSendException(
        'Failed to upload image: ${e.toString()}',
        retainedImage: image,
      );
    }

    try {
      final message = ChatMessage(
        messageId: messageId,
        senderId: senderId,
        text: '',
        type: 'image',
        timestamp: now,
        imageUrl: imageUrl,
      );

      // Create message document
      await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Update lastMessage and lastMessageAt on the Match_Document
      await _firestore.collection('matches').doc(matchId).update({
        'lastMessage': '📷 Image',
        'lastMessageAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      throw MessageSendException(
        'Failed to send image message: ${e.toString()}',
        retainedImage: image,
      );
    }
  }
}
