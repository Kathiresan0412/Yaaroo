// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_database.dart';

// ignore_for_file: type=lint
class $CachedMessagesTable extends CachedMessages
    with TableInfo<$CachedMessagesTable, CachedMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _matchIdMeta = VerificationMeta('matchId');
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
      'match_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _conversationIdMeta =
      VerificationMeta('conversationId');
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _senderIdMeta = VerificationMeta('senderId');
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _contentMeta = VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaUrlMeta = VerificationMeta('mediaUrl');
  @override
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
      'media_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _reactionsJsonMeta =
      VerificationMeta('reactionsJson');
  @override
  late final GeneratedColumn<String> reactionsJson = GeneratedColumn<String>(
      'reactions_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _isMineMeta = VerificationMeta('isMine');
  @override
  late final GeneratedColumn<bool> isMine = GeneratedColumn<bool>(
      'is_mine', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_mine" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isReadMeta = VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _readAtMeta = VerificationMeta('readAt');
  @override
  late final GeneratedColumn<String> readAt = GeneratedColumn<String>(
      'read_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta = VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta = VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deliveryStatusMeta =
      VerificationMeta('deliveryStatus');
  @override
  late final GeneratedColumn<String> deliveryStatus = GeneratedColumn<String>(
      'delivery_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sent'));
  static const VerificationMeta _localMediaPathMeta =
      VerificationMeta('localMediaPath');
  @override
  late final GeneratedColumn<String> localMediaPath = GeneratedColumn<String>(
      'local_media_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        matchId,
        conversationId,
        senderId,
        type,
        content,
        mediaUrl,
        durationSeconds,
        reactionsJson,
        isMine,
        isRead,
        readAt,
        isDeleted,
        createdAt,
        deliveryStatus,
        localMediaPath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_messages';
  @override
  VerificationContext validateIntegrity(Insertable<CachedMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(_matchIdMeta,
          matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta));
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('media_url')) {
      context.handle(_mediaUrlMeta,
          mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    if (data.containsKey('reactions_json')) {
      context.handle(
          _reactionsJsonMeta,
          reactionsJson.isAcceptableOrUnknown(
              data['reactions_json']!, _reactionsJsonMeta));
    }
    if (data.containsKey('is_mine')) {
      context.handle(_isMineMeta,
          isMine.isAcceptableOrUnknown(data['is_mine']!, _isMineMeta));
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    }
    if (data.containsKey('read_at')) {
      context.handle(_readAtMeta,
          readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('delivery_status')) {
      context.handle(
          _deliveryStatusMeta,
          deliveryStatus.isAcceptableOrUnknown(
              data['delivery_status']!, _deliveryStatusMeta));
    }
    if (data.containsKey('local_media_path')) {
      context.handle(
          _localMediaPathMeta,
          localMediaPath.isAcceptableOrUnknown(
              data['local_media_path']!, _localMediaPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      matchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}match_id'])!,
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      mediaUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_url']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds']),
      reactionsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reactions_json'])!,
      isMine: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_mine'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      readAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}read_at']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      deliveryStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}delivery_status'])!,
      localMediaPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_media_path']),
    );
  }

  @override
  $CachedMessagesTable createAlias(String alias) {
    return $CachedMessagesTable(attachedDatabase, alias);
  }
}

class CachedMessage extends DataClass implements Insertable<CachedMessage> {
  final String id;
  final String matchId;
  final String conversationId;
  final String senderId;
  final String type;
  final String? content;
  final String? mediaUrl;
  final int? durationSeconds;
  final String reactionsJson;
  final bool isMine;
  final bool isRead;
  final String? readAt;
  final bool isDeleted;
  final String createdAt;
  final String deliveryStatus;
  final String? localMediaPath;
  const CachedMessage(
      {required this.id,
      required this.matchId,
      required this.conversationId,
      required this.senderId,
      required this.type,
      this.content,
      this.mediaUrl,
      this.durationSeconds,
      required this.reactionsJson,
      required this.isMine,
      required this.isRead,
      this.readAt,
      required this.isDeleted,
      required this.createdAt,
      required this.deliveryStatus,
      this.localMediaPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['match_id'] = Variable<String>(matchId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender_id'] = Variable<String>(senderId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String>(mediaUrl);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['reactions_json'] = Variable<String>(reactionsJson);
    map['is_mine'] = Variable<bool>(isMine);
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<String>(readAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<String>(createdAt);
    map['delivery_status'] = Variable<String>(deliveryStatus);
    if (!nullToAbsent || localMediaPath != null) {
      map['local_media_path'] = Variable<String>(localMediaPath);
    }
    return map;
  }

  CachedMessagesCompanion toCompanion(bool nullToAbsent) {
    return CachedMessagesCompanion(
      id: Value(id),
      matchId: Value(matchId),
      conversationId: Value(conversationId),
      senderId: Value(senderId),
      type: Value(type),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      mediaUrl: mediaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUrl),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      reactionsJson: Value(reactionsJson),
      isMine: Value(isMine),
      isRead: Value(isRead),
      readAt:
          readAt == null && nullToAbsent ? const Value.absent() : Value(readAt),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      deliveryStatus: Value(deliveryStatus),
      localMediaPath: localMediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localMediaPath),
    );
  }

  factory CachedMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMessage(
      id: serializer.fromJson<String>(json['id']),
      matchId: serializer.fromJson<String>(json['matchId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String?>(json['content']),
      mediaUrl: serializer.fromJson<String?>(json['mediaUrl']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      reactionsJson: serializer.fromJson<String>(json['reactionsJson']),
      isMine: serializer.fromJson<bool>(json['isMine']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      readAt: serializer.fromJson<String?>(json['readAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      deliveryStatus: serializer.fromJson<String>(json['deliveryStatus']),
      localMediaPath: serializer.fromJson<String?>(json['localMediaPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'matchId': serializer.toJson<String>(matchId),
      'conversationId': serializer.toJson<String>(conversationId),
      'senderId': serializer.toJson<String>(senderId),
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String?>(content),
      'mediaUrl': serializer.toJson<String?>(mediaUrl),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'reactionsJson': serializer.toJson<String>(reactionsJson),
      'isMine': serializer.toJson<bool>(isMine),
      'isRead': serializer.toJson<bool>(isRead),
      'readAt': serializer.toJson<String?>(readAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<String>(createdAt),
      'deliveryStatus': serializer.toJson<String>(deliveryStatus),
      'localMediaPath': serializer.toJson<String?>(localMediaPath),
    };
  }

  CachedMessage copyWith(
          {String? id,
          String? matchId,
          String? conversationId,
          String? senderId,
          String? type,
          Value<String?> content = const Value.absent(),
          Value<String?> mediaUrl = const Value.absent(),
          Value<int?> durationSeconds = const Value.absent(),
          String? reactionsJson,
          bool? isMine,
          bool? isRead,
          Value<String?> readAt = const Value.absent(),
          bool? isDeleted,
          String? createdAt,
          String? deliveryStatus,
          Value<String?> localMediaPath = const Value.absent()}) =>
      CachedMessage(
        id: id ?? this.id,
        matchId: matchId ?? this.matchId,
        conversationId: conversationId ?? this.conversationId,
        senderId: senderId ?? this.senderId,
        type: type ?? this.type,
        content: content.present ? content.value : this.content,
        mediaUrl: mediaUrl.present ? mediaUrl.value : this.mediaUrl,
        durationSeconds: durationSeconds.present
            ? durationSeconds.value
            : this.durationSeconds,
        reactionsJson: reactionsJson ?? this.reactionsJson,
        isMine: isMine ?? this.isMine,
        isRead: isRead ?? this.isRead,
        readAt: readAt.present ? readAt.value : this.readAt,
        isDeleted: isDeleted ?? this.isDeleted,
        createdAt: createdAt ?? this.createdAt,
        deliveryStatus: deliveryStatus ?? this.deliveryStatus,
        localMediaPath:
            localMediaPath.present ? localMediaPath.value : this.localMediaPath,
      );
  @override
  String toString() {
    return (StringBuffer('CachedMessage(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('reactionsJson: $reactionsJson, ')
          ..write('isMine: $isMine, ')
          ..write('isRead: $isRead, ')
          ..write('readAt: $readAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('localMediaPath: $localMediaPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      matchId,
      conversationId,
      senderId,
      type,
      content,
      mediaUrl,
      durationSeconds,
      reactionsJson,
      isMine,
      isRead,
      readAt,
      isDeleted,
      createdAt,
      deliveryStatus,
      localMediaPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMessage &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.conversationId == this.conversationId &&
          other.senderId == this.senderId &&
          other.type == this.type &&
          other.content == this.content &&
          other.mediaUrl == this.mediaUrl &&
          other.durationSeconds == this.durationSeconds &&
          other.reactionsJson == this.reactionsJson &&
          other.isMine == this.isMine &&
          other.isRead == this.isRead &&
          other.readAt == this.readAt &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.deliveryStatus == this.deliveryStatus &&
          other.localMediaPath == this.localMediaPath);
}

class CachedMessagesCompanion extends UpdateCompanion<CachedMessage> {
  final Value<String> id;
  final Value<String> matchId;
  final Value<String> conversationId;
  final Value<String> senderId;
  final Value<String> type;
  final Value<String?> content;
  final Value<String?> mediaUrl;
  final Value<int?> durationSeconds;
  final Value<String> reactionsJson;
  final Value<bool> isMine;
  final Value<bool> isRead;
  final Value<String?> readAt;
  final Value<bool> isDeleted;
  final Value<String> createdAt;
  final Value<String> deliveryStatus;
  final Value<String?> localMediaPath;
  const CachedMessagesCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.reactionsJson = const Value.absent(),
    this.isMine = const Value.absent(),
    this.isRead = const Value.absent(),
    this.readAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deliveryStatus = const Value.absent(),
    this.localMediaPath = const Value.absent(),
  });
  CachedMessagesCompanion.insert({
    required String id,
    required String matchId,
    this.conversationId = const Value.absent(),
    required String senderId,
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.reactionsJson = const Value.absent(),
    this.isMine = const Value.absent(),
    this.isRead = const Value.absent(),
    this.readAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required String createdAt,
    this.deliveryStatus = const Value.absent(),
    this.localMediaPath = const Value.absent(),
  })  : id = Value(id),
        matchId = Value(matchId),
        senderId = Value(senderId),
        createdAt = Value(createdAt);
  static Insertable<CachedMessage> custom({
    Expression<String>? id,
    Expression<String>? matchId,
    Expression<String>? conversationId,
    Expression<String>? senderId,
    Expression<String>? type,
    Expression<String>? content,
    Expression<String>? mediaUrl,
    Expression<int>? durationSeconds,
    Expression<String>? reactionsJson,
    Expression<bool>? isMine,
    Expression<bool>? isRead,
    Expression<String>? readAt,
    Expression<bool>? isDeleted,
    Expression<String>? createdAt,
    Expression<String>? deliveryStatus,
    Expression<String>? localMediaPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (senderId != null) 'sender_id': senderId,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (reactionsJson != null) 'reactions_json': reactionsJson,
      if (isMine != null) 'is_mine': isMine,
      if (isRead != null) 'is_read': isRead,
      if (readAt != null) 'read_at': readAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (deliveryStatus != null) 'delivery_status': deliveryStatus,
      if (localMediaPath != null) 'local_media_path': localMediaPath,
    });
  }

  CachedMessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? matchId,
      Value<String>? conversationId,
      Value<String>? senderId,
      Value<String>? type,
      Value<String?>? content,
      Value<String?>? mediaUrl,
      Value<int?>? durationSeconds,
      Value<String>? reactionsJson,
      Value<bool>? isMine,
      Value<bool>? isRead,
      Value<String?>? readAt,
      Value<bool>? isDeleted,
      Value<String>? createdAt,
      Value<String>? deliveryStatus,
      Value<String?>? localMediaPath}) {
    return CachedMessagesCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      reactionsJson: reactionsJson ?? this.reactionsJson,
      isMine: isMine ?? this.isMine,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      localMediaPath: localMediaPath ?? this.localMediaPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (reactionsJson.present) {
      map['reactions_json'] = Variable<String>(reactionsJson.value);
    }
    if (isMine.present) {
      map['is_mine'] = Variable<bool>(isMine.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<String>(readAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (deliveryStatus.present) {
      map['delivery_status'] = Variable<String>(deliveryStatus.value);
    }
    if (localMediaPath.present) {
      map['local_media_path'] = Variable<String>(localMediaPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessagesCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('reactionsJson: $reactionsJson, ')
          ..write('isMine: $isMine, ')
          ..write('isRead: $isRead, ')
          ..write('readAt: $readAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('deliveryStatus: $deliveryStatus, ')
          ..write('localMediaPath: $localMediaPath')
          ..write(')'))
        .toString();
  }
}

class $ConversationSyncStateTable extends ConversationSyncState
    with TableInfo<$ConversationSyncStateTable, ConversationSyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationSyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matchIdMeta = VerificationMeta('matchId');
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
      'match_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncedMessageIdMeta =
      VerificationMeta('lastSyncedMessageId');
  @override
  late final GeneratedColumn<String> lastSyncedMessageId =
      GeneratedColumn<String>('last_synced_message_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedAtMeta =
      VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<String> lastSyncedAt = GeneratedColumn<String>(
      'last_synced_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [matchId, lastSyncedMessageId, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversation_sync_state';
  @override
  VerificationContext validateIntegrity(
      Insertable<ConversationSyncStateData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('match_id')) {
      context.handle(_matchIdMeta,
          matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta));
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('last_synced_message_id')) {
      context.handle(
          _lastSyncedMessageIdMeta,
          lastSyncedMessageId.isAcceptableOrUnknown(
              data['last_synced_message_id']!, _lastSyncedMessageIdMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matchId};
  @override
  ConversationSyncStateData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationSyncStateData(
      matchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}match_id'])!,
      lastSyncedMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_synced_message_id']),
      lastSyncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_synced_at'])!,
    );
  }

  @override
  $ConversationSyncStateTable createAlias(String alias) {
    return $ConversationSyncStateTable(attachedDatabase, alias);
  }
}

class ConversationSyncStateData extends DataClass
    implements Insertable<ConversationSyncStateData> {
  final String matchId;
  final String? lastSyncedMessageId;
  final String lastSyncedAt;
  const ConversationSyncStateData(
      {required this.matchId,
      this.lastSyncedMessageId,
      required this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['match_id'] = Variable<String>(matchId);
    if (!nullToAbsent || lastSyncedMessageId != null) {
      map['last_synced_message_id'] = Variable<String>(lastSyncedMessageId);
    }
    map['last_synced_at'] = Variable<String>(lastSyncedAt);
    return map;
  }

  ConversationSyncStateCompanion toCompanion(bool nullToAbsent) {
    return ConversationSyncStateCompanion(
      matchId: Value(matchId),
      lastSyncedMessageId: lastSyncedMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedMessageId),
      lastSyncedAt: Value(lastSyncedAt),
    );
  }

  factory ConversationSyncStateData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationSyncStateData(
      matchId: serializer.fromJson<String>(json['matchId']),
      lastSyncedMessageId:
          serializer.fromJson<String?>(json['lastSyncedMessageId']),
      lastSyncedAt: serializer.fromJson<String>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matchId': serializer.toJson<String>(matchId),
      'lastSyncedMessageId': serializer.toJson<String?>(lastSyncedMessageId),
      'lastSyncedAt': serializer.toJson<String>(lastSyncedAt),
    };
  }

  ConversationSyncStateData copyWith(
          {String? matchId,
          Value<String?> lastSyncedMessageId = const Value.absent(),
          String? lastSyncedAt}) =>
      ConversationSyncStateData(
        matchId: matchId ?? this.matchId,
        lastSyncedMessageId: lastSyncedMessageId.present
            ? lastSyncedMessageId.value
            : this.lastSyncedMessageId,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
  @override
  String toString() {
    return (StringBuffer('ConversationSyncStateData(')
          ..write('matchId: $matchId, ')
          ..write('lastSyncedMessageId: $lastSyncedMessageId, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(matchId, lastSyncedMessageId, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationSyncStateData &&
          other.matchId == this.matchId &&
          other.lastSyncedMessageId == this.lastSyncedMessageId &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class ConversationSyncStateCompanion
    extends UpdateCompanion<ConversationSyncStateData> {
  final Value<String> matchId;
  final Value<String?> lastSyncedMessageId;
  final Value<String> lastSyncedAt;
  const ConversationSyncStateCompanion({
    this.matchId = const Value.absent(),
    this.lastSyncedMessageId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
  });
  ConversationSyncStateCompanion.insert({
    required String matchId,
    this.lastSyncedMessageId = const Value.absent(),
    required String lastSyncedAt,
  })  : matchId = Value(matchId),
        lastSyncedAt = Value(lastSyncedAt);
  static Insertable<ConversationSyncStateData> custom({
    Expression<String>? matchId,
    Expression<String>? lastSyncedMessageId,
    Expression<String>? lastSyncedAt,
  }) {
    return RawValuesInsertable({
      if (matchId != null) 'match_id': matchId,
      if (lastSyncedMessageId != null)
        'last_synced_message_id': lastSyncedMessageId,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
    });
  }

  ConversationSyncStateCompanion copyWith(
      {Value<String>? matchId,
      Value<String?>? lastSyncedMessageId,
      Value<String>? lastSyncedAt}) {
    return ConversationSyncStateCompanion(
      matchId: matchId ?? this.matchId,
      lastSyncedMessageId: lastSyncedMessageId ?? this.lastSyncedMessageId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (lastSyncedMessageId.present) {
      map['last_synced_message_id'] =
          Variable<String>(lastSyncedMessageId.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<String>(lastSyncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationSyncStateCompanion(')
          ..write('matchId: $matchId, ')
          ..write('lastSyncedMessageId: $lastSyncedMessageId, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$ChatDatabase extends GeneratedDatabase {
  _$ChatDatabase(QueryExecutor e) : super(e);
  late final $CachedMessagesTable cachedMessages = $CachedMessagesTable(this);
  late final $ConversationSyncStateTable conversationSyncState =
      $ConversationSyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cachedMessages, conversationSyncState];
}
