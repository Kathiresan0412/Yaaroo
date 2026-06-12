import 'package:flutter_test/flutter_test.dart';
import 'package:yaro0_mobile/core/services/offline_write_queue.dart';

void main() {
  group('QueuedWrite', () {
    test('serializes and deserializes correctly', () {
      final write = QueuedWrite(
        id: 'test_1',
        collection: 'messages',
        documentId: 'msg_123',
        data: {'text': 'hello', 'senderId': 'user1'},
        operationType: 'set',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        retryCount: 2,
      );

      final json = write.toJson();
      final restored = QueuedWrite.fromJson(json);

      expect(restored.id, 'test_1');
      expect(restored.collection, 'messages');
      expect(restored.documentId, 'msg_123');
      expect(restored.data['text'], 'hello');
      expect(restored.data['senderId'], 'user1');
      expect(restored.operationType, 'set');
      expect(restored.retryCount, 2);
      expect(restored.createdAt, DateTime(2024, 1, 15, 10, 30));
    });

    test('isExhausted returns true when retryCount >= maxRetries', () {
      final write = QueuedWrite(
        id: 'test_2',
        collection: 'users',
        documentId: 'user_1',
        data: {'name': 'Test'},
        operationType: 'update',
        createdAt: DateTime.now(),
        retryCount: 5,
      );

      expect(write.isExhausted, isTrue);
    });

    test('isExhausted returns false when retryCount < maxRetries', () {
      final write = QueuedWrite(
        id: 'test_3',
        collection: 'users',
        documentId: 'user_1',
        data: {'name': 'Test'},
        operationType: 'update',
        createdAt: DateTime.now(),
        retryCount: 4,
      );

      expect(write.isExhausted, isFalse);
    });

    test('maxRetries is 5', () {
      expect(QueuedWrite.maxRetries, 5);
    });

    test('defaults retryCount to 0 when not in JSON', () {
      final json = {
        'id': 'test_4',
        'collection': 'likes',
        'documentId': 'like_1',
        'data': {'type': 'superLike'},
        'operationType': 'set',
        'createdAt': '2024-01-15T10:30:00.000',
      };

      final write = QueuedWrite.fromJson(json);
      expect(write.retryCount, 0);
    });
  });

  group('WriteQueueResult', () {
    test('holds correct values', () {
      const result = WriteQueueResult(
        succeeded: 3,
        failed: 1,
        discarded: 2,
      );

      expect(result.succeeded, 3);
      expect(result.failed, 1);
      expect(result.discarded, 2);
    });
  });
}
