import 'package:flutter_test/flutter_test.dart';
import 'package:yaro0_mobile/features/auth/data/firebase_auth_service.dart';

void main() {
  group('FirebaseAuthServiceImpl - E.164 Phone Validation', () {
    test('accepts valid E.164 numbers with minimum digits (7)', () {
      expect(FirebaseAuthServiceImpl.isValidE164('+1234567'), isTrue);
    });

    test('accepts valid E.164 numbers with maximum digits (15)', () {
      expect(FirebaseAuthServiceImpl.isValidE164('+123456789012345'), isTrue);
    });

    test('accepts typical phone numbers', () {
      expect(FirebaseAuthServiceImpl.isValidE164('+14155552671'), isTrue);
      expect(FirebaseAuthServiceImpl.isValidE164('+442071234567'), isTrue);
      expect(FirebaseAuthServiceImpl.isValidE164('+919876543210'), isTrue);
    });

    test('rejects numbers without + prefix', () {
      expect(FirebaseAuthServiceImpl.isValidE164('14155552671'), isFalse);
    });

    test('rejects numbers with fewer than 7 digits', () {
      expect(FirebaseAuthServiceImpl.isValidE164('+123456'), isFalse);
    });

    test('rejects numbers with more than 15 digits', () {
      expect(FirebaseAuthServiceImpl.isValidE164('+1234567890123456'), isFalse);
    });

    test('rejects empty string', () {
      expect(FirebaseAuthServiceImpl.isValidE164(''), isFalse);
    });

    test('rejects string with only +', () {
      expect(FirebaseAuthServiceImpl.isValidE164('+'), isFalse);
    });

    test('rejects numbers with non-digit characters', () {
      expect(FirebaseAuthServiceImpl.isValidE164('+1234567abc'), isFalse);
      expect(FirebaseAuthServiceImpl.isValidE164('+123-456-7890'), isFalse);
      expect(FirebaseAuthServiceImpl.isValidE164('+123 456 7890'), isFalse);
    });

    test('rejects numbers with + in wrong position', () {
      expect(FirebaseAuthServiceImpl.isValidE164('1+234567890'), isFalse);
      expect(FirebaseAuthServiceImpl.isValidE164('1234567890+'), isFalse);
    });

    test('accepts exactly 7 digits (boundary)', () {
      expect(FirebaseAuthServiceImpl.isValidE164('+1234567'), isTrue);
    });

    test('accepts exactly 15 digits (boundary)', () {
      expect(FirebaseAuthServiceImpl.isValidE164('+123456789012345'), isTrue);
    });

    test('rejects exactly 6 digits (below boundary)', () {
      expect(FirebaseAuthServiceImpl.isValidE164('+123456'), isFalse);
    });

    test('rejects exactly 16 digits (above boundary)', () {
      expect(FirebaseAuthServiceImpl.isValidE164('+1234567890123456'), isFalse);
    });
  });

  group('AuthException', () {
    test('toString includes message and code', () {
      const exception = AuthException('Test error', code: 'test-code');
      expect(exception.toString(), 'AuthException: Test error (test-code)');
    });

    test('toString without code omits code part', () {
      const exception = AuthException('Test error');
      expect(exception.toString(), 'AuthException: Test error');
    });

    test('message and code are accessible', () {
      const exception = AuthException('msg', code: 'code-1');
      expect(exception.message, 'msg');
      expect(exception.code, 'code-1');
    });

    test('code defaults to null', () {
      const exception = AuthException('msg');
      expect(exception.code, isNull);
    });
  });
}
