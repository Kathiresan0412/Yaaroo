import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Exception thrown when Firebase initialization fails after all retries.
class FirebaseInitException implements Exception {
  const FirebaseInitException(this.message, {this.failedService});

  final String message;
  final String? failedService;

  @override
  String toString() =>
      'FirebaseInitException: $message${failedService != null ? ' (service: $failedService)' : ''}';
}

/// Service responsible for initializing all Firebase services on app startup.
///
/// Implements retry logic (max 3 attempts by default) and configures
/// Firestore offline persistence with the default cache size.
class FirebaseInitService {
  FirebaseInitService._();

  static final FirebaseInitService instance = FirebaseInitService._();

  bool _initialized = false;

  /// Whether Firebase has been successfully initialized.
  bool get isInitialized => _initialized;

  /// Initializes Firebase Core, Auth, Firestore, Storage, and FCM.
  ///
  /// Retries up to [maxRetries] times before throwing [FirebaseInitException].
  /// Each retry waits with exponential backoff (1s, 2s, 4s).
  Future<void> initialize({int maxRetries = 3}) async {
    if (_initialized) return;

    FirebaseInitException? lastException;

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _initializeServices();
        _initialized = true;
        return;
      } catch (e) {
        lastException = e is FirebaseInitException
            ? e
            : FirebaseInitException(
                'Initialization failed on attempt $attempt: $e',
              );

        if (attempt < maxRetries) {
          // Exponential backoff: 1s, 2s, 4s...
          final delay = Duration(seconds: 1 << (attempt - 1));
          debugPrint(
            'Firebase init attempt $attempt failed. Retrying in ${delay.inSeconds}s...',
          );
          await Future.delayed(delay);
        }
      }
    }

    throw lastException ??
        const FirebaseInitException(
          'Firebase initialization failed after maximum retry attempts.',
        );
  }

  /// Performs the actual initialization of all Firebase services.
  Future<void> _initializeServices() async {
    // Initialize Firebase Core
    try {
      await Firebase.initializeApp();
    } catch (e) {
      throw FirebaseInitException(
        'Firebase Core initialization failed: $e',
        failedService: 'Firebase Core',
      );
    }

    // Verify Firebase Auth is accessible
    try {
      FirebaseAuth.instance;
    } catch (e) {
      throw FirebaseInitException(
        'Firebase Auth initialization failed: $e',
        failedService: 'Firebase Auth',
      );
    }

    // Verify Cloud Firestore is accessible and configure persistence
    try {
      FirebaseFirestore.instance;
      await configureOfflinePersistence();
    } catch (e) {
      throw FirebaseInitException(
        'Cloud Firestore initialization failed: $e',
        failedService: 'Cloud Firestore',
      );
    }

    // Verify Firebase Storage is accessible
    try {
      FirebaseStorage.instance;
    } catch (e) {
      throw FirebaseInitException(
        'Firebase Storage initialization failed: $e',
        failedService: 'Firebase Storage',
      );
    }

    // Verify Firebase Cloud Messaging is accessible
    try {
      FirebaseMessaging.instance;
    } catch (e) {
      throw FirebaseInitException(
        'Firebase Messaging initialization failed: $e',
        failedService: 'Firebase Messaging',
      );
    }
  }

  /// Configures Firestore offline persistence with the default cache size.
  ///
  /// On web, persistence is enabled explicitly. On mobile, persistence is
  /// enabled by default but we ensure the settings are applied.
  Future<void> configureOfflinePersistence() async {
    final firestore = FirebaseFirestore.instance;

    firestore.settings = const Settings(
      persistenceEnabled: true,
      // Use default cache size (40 MB) by not specifying cacheSizeBytes,
      // or use the unlimited sentinel.
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}
