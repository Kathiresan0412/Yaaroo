import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'chat_database.g.dart';

/// Local SQLite table mirroring messages for offline access.
class CachedMessages extends Table {
  TextColumn get id => text()();
  TextColumn get matchId => text()();
  TextColumn get conversationId => text().withDefault(const Constant(''))();
  TextColumn get senderId => text()();
  TextColumn get type => text().withDefault(const Constant('text'))();
  TextColumn get content => text().nullable()();
  TextColumn get mediaUrl => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get reactionsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get isMine => boolean().withDefault(const Constant(false))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get readAt => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get deliveryStatus => text().withDefault(const Constant('sent'))();
  TextColumn get localMediaPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tracks sync state per conversation so we know what's already cached.
class ConversationSyncState extends Table {
  TextColumn get matchId => text()();
  TextColumn get lastSyncedMessageId => text().nullable()();
  TextColumn get lastSyncedAt => text()();

  @override
  Set<Column> get primaryKey => {matchId};
}

@DriftDatabase(tables: [CachedMessages, ConversationSyncState])
class ChatDatabase extends _$ChatDatabase {
  ChatDatabase._internal(super.e);

  static ChatDatabase? _instance;

  static Future<ChatDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/yaaro_chat.db');
    _instance = ChatDatabase._internal(NativeDatabase.createInBackground(file));
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  // ---------------------------------------------------------------------------
  // Message operations
  // ---------------------------------------------------------------------------

  /// Insert or update a batch of messages for a conversation.
  Future<void> upsertMessages(List<CachedMessagesCompanion> messages) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedMessages, messages);
    });
  }

  /// Get all cached messages for a match, ordered newest first.
  Future<List<CachedMessage>> getMessagesForMatch(String matchId,
      {int limit = 50, int offset = 0}) async {
    return (select(cachedMessages)
          ..where((m) => m.matchId.equals(matchId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Get the newest message timestamp for a match (used as sync cursor).
  Future<String?> getLatestMessageTime(String matchId) async {
    final row = await (select(cachedMessages)
          ..where((m) => m.matchId.equals(matchId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.createdAt;
  }

  /// Update read status for all messages in a match from the other user.
  Future<void> markMatchMessagesRead(String matchId) async {
    await (update(cachedMessages)
          ..where((m) => m.matchId.equals(matchId) & m.isMine.equals(false)))
        .write(const CachedMessagesCompanion(isRead: Value(true)));
  }

  /// Update a single message (e.g. delivery status, read receipt).
  Future<void> updateMessage(
      String messageId, CachedMessagesCompanion data) async {
    await (update(cachedMessages)..where((m) => m.id.equals(messageId)))
        .write(data);
  }

  /// Delete all messages for a match (e.g. user unmatched).
  Future<void> deleteMessagesForMatch(String matchId) async {
    await (delete(cachedMessages)..where((m) => m.matchId.equals(matchId)))
        .go();
    await (delete(conversationSyncState)
          ..where((s) => s.matchId.equals(matchId)))
        .go();
  }

  /// Update sync state after fetching from server.
  Future<void> updateSyncState(String matchId, String? lastMessageId) async {
    await into(conversationSyncState).insertOnConflictUpdate(
      ConversationSyncStateCompanion(
        matchId: Value(matchId),
        lastSyncedMessageId: Value(lastMessageId),
        lastSyncedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  /// Nuke entire cache (e.g. on logout).
  Future<void> clearAll() async {
    await delete(cachedMessages).go();
    await delete(conversationSyncState).go();
  }
}
