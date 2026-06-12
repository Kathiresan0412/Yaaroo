import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat message stored at
/// `matches/{matchId}/messages/{messageId}` in Firestore.
class ChatMessage {
  final String messageId;
  final String senderId;
  final String text;
  final String type;
  final DateTime timestamp;
  final String? imageUrl;

  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.type,
    required this.timestamp,
    this.imageUrl,
  });

  /// Converts this [ChatMessage] to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  /// Creates a [ChatMessage] from a Firestore document snapshot.
  factory ChatMessage.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChatMessage(
      messageId: data['messageId'] as String,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      type: data['type'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  /// Creates a [ChatMessage] from a raw map.
  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      messageId: data['messageId'] as String,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      type: data['type'] as String,
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : data['timestamp'] as DateTime,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  ChatMessage copyWith({
    String? messageId,
    String? senderId,
    String? text,
    String? type,
    DateTime? timestamp,
    String? imageUrl,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
