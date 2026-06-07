import 'dart:convert';
import 'package:drift/drift.dart';
import 'chat_database.dart';
import 'media_cache_service.dart';
import '../api_client.dart';

/// Coordinates between local cache, REST API, and WebSocket events.
///
/// Flow:
/// 1. Open chat → load from local DB instantly (offline-first)
/// 2. Sync newer messages from server
/// 3. Real-time messages via socket get written to local DB
/// 4. Media is prefetched to device storage
class ChatRepository {
  ChatRepository._internal();
  static final ChatRepository instance = ChatRepository._internal();

  ChatDatabase? _db;
  final MediaCacheService _mediaCache = MediaCacheService.instance;

  Future<ChatDatabase> get db async {
    _db ??= await ChatDatabase.getInstance();
    return _db!;
  }

  // ---------------------------------------------------------------------------
  // Load messages — local first, then sync from server
  // ---------------------------------------------------------------------------

  /// Returns cached messages immediately. Call [syncFromServer] after.
  Future<List<Map<String, dynamic>>> loadCachedMessages(String matchId,
      {int limit = 50, int offset = 0}) async {
    final database = await db;
    final rows = await database.getMessagesForMatch(matchId,
        limit: limit, offset: offset);
    return rows.map(_rowToJson).toList();
  }

  /// Fetches new messages from server and merges into local cache.
  /// Returns only the NEW messages that weren't in the cache.
  Future<List<Map<String, dynamic>>> syncFromServer(
    ApiClient apiClient,
    String matchId, {
    String? cursor,
  }) async {
    final database = await db;

    try {
      final payload = await apiClient.getMessages(matchId, cursor: cursor);
      final rawMessages = payload['messages'] as List? ?? [];
      final messages = rawMessages.whereType<Map<String, dynamic>>().toList();

      if (messages.isNotEmpty) {
        final companions = messages.map(_jsonToCompanion).toList();
        await database.upsertMessages(companions);

        // Update sync state
        final newestId = messages.first['id']?.toString();
        await database.updateSyncState(matchId, newestId);

        // Prefetch media in background
        _prefetchMedia(messages);
      }

      final nextCursor = payload['nextCursor']?.toString();
      return messages..add({'_nextCursor': nextCursor});
    } catch (e) {
      // If server fetch fails, we still have local cache
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Write operations — called when socket receives or sends messages
  // ---------------------------------------------------------------------------

  /// Persist a single message received via WebSocket.
  Future<void> cacheMessage(Map<String, dynamic> messageJson) async {
    final database = await db;
    await database.upsertMessages([_jsonToCompanion(messageJson)]);

    // Cache media if present
    final mediaUrl = messageJson['mediaUrl']?.toString();
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      _mediaCache.prefetch(mediaUrl);
    }
  }

  /// Persist a pending (optimistic) message before server confirms.
  Future<void> cachePendingMessage(Map<String, dynamic> messageJson) async {
    final database = await db;
    await database.upsertMessages([_jsonToCompanion(messageJson)]);
  }

  /// Replace a pending message with the server-confirmed version.
  Future<void> replacePendingMessage(
      String localId, Map<String, dynamic> confirmedJson) async {
    final database = await db;
    // Delete the local pending entry
    await (database.delete(database.cachedMessages)
          ..where((m) => m.id.equals(localId)))
        .go();
    // Insert the confirmed one
    await database.upsertMessages([_jsonToCompanion(confirmedJson)]);
  }

  // ---------------------------------------------------------------------------
  // Status updates
  // ---------------------------------------------------------------------------

  /// Mark messages as read in local cache.
  Future<void> markMessagesRead(String matchId) async {
    final database = await db;
    await database.markMatchMessagesRead(matchId);
  }

  /// Update delivery status for a specific message.
  Future<void> updateDeliveryStatus(String messageId, String status) async {
    final database = await db;
    await database.updateMessage(
      messageId,
      CachedMessagesCompanion(deliveryStatus: Value(status)),
    );
  }

  /// Update read receipt on own messages.
  Future<void> markOwnMessagesRead(String matchId, String? readAt) async {
    final database = await db;
    final messages = await database.getMessagesForMatch(matchId, limit: 200);
    for (final msg in messages) {
      if (msg.isMine && !msg.isRead) {
        await database.updateMessage(
          msg.id,
          CachedMessagesCompanion(
            isRead: const Value(true),
            readAt: Value(readAt),
            deliveryStatus: const Value('read'),
          ),
        );
      }
    }
  }

  /// Update reactions on a message.
  Future<void> updateReactions(
      String messageId, List<Map<String, dynamic>> reactions) async {
    final database = await db;
    await database.updateMessage(
      messageId,
      CachedMessagesCompanion(
        reactionsJson: Value(jsonEncode(reactions)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /// Delete all cached data for a conversation (e.g. unmatch).
  Future<void> clearConversation(String matchId) async {
    final database = await db;
    await database.deleteMessagesForMatch(matchId);
  }

  /// Clear everything (e.g. logout).
  Future<void> clearAll() async {
    final database = await db;
    await database.clearAll();
    await _mediaCache.clearAll();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _prefetchMedia(List<Map<String, dynamic>> messages) {
    final urls = messages
        .map((m) => m['mediaUrl']?.toString())
        .where((url) => url != null && url.isNotEmpty)
        .cast<String>()
        .toList();
    if (urls.isNotEmpty) {
      _mediaCache.prefetchAll(urls);
    }
  }

  Map<String, dynamic> _rowToJson(CachedMessage row) {
    return {
      'id': row.id,
      'matchId': row.matchId,
      'conversationId': row.conversationId,
      'senderId': row.senderId,
      'type': row.type,
      'content': row.content,
      'mediaUrl': row.mediaUrl,
      'durationSeconds': row.durationSeconds,
      'reactions': jsonDecode(row.reactionsJson),
      'isMine': row.isMine,
      'isRead': row.isRead,
      'readAt': row.readAt,
      'isDeleted': row.isDeleted,
      'createdAt': row.createdAt,
      'deliveryStatus': row.deliveryStatus,
      'localMediaPath': row.localMediaPath,
    };
  }

  CachedMessagesCompanion _jsonToCompanion(Map<String, dynamic> json) {
    final reactions = json['reactions'];
    String reactionsJson;
    if (reactions is List) {
      reactionsJson = jsonEncode(reactions);
    } else if (reactions is String) {
      reactionsJson = reactions;
    } else {
      reactionsJson = '[]';
    }

    return CachedMessagesCompanion(
      id: Value(json['id']?.toString() ?? ''),
      matchId: Value(json['matchId']?.toString() ?? ''),
      conversationId: Value(json['conversationId']?.toString() ?? ''),
      senderId: Value(json['senderId']?.toString() ?? ''),
      type: Value(json['type']?.toString() ?? 'text'),
      content: Value(json['content']?.toString()),
      mediaUrl: Value(json['mediaUrl']?.toString()),
      durationSeconds:
          Value(int.tryParse(json['durationSeconds']?.toString() ?? '')),
      reactionsJson: Value(reactionsJson),
      isMine: Value(json['isMine'] == true),
      isRead: Value(json['isRead'] == true),
      readAt: Value(json['readAt']?.toString()),
      isDeleted: Value(json['isDeleted'] == true),
      createdAt: Value(
          json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      deliveryStatus: Value(json['deliveryStatus']?.toString() ?? 'sent'),
    );
  }
}
