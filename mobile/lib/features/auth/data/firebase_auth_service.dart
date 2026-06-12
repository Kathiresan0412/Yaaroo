import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Exception thrown when authentication operations fail.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' ($code)' : ''}';
}

/// Abstract interface for Firebase Authentication operations.
abstract class FirebaseAuthService {
  /// Sends a 6-digit OTP to the given phone number in E.164 format.
  Future<void> sendOtp(String phoneNumber);

  /// Verifies the OTP code against the verification ID returned by [sendOtp].
  Future<UserCredential> verifyOtp(String verificationId, String otp);

  /// Signs in the user using their Google account.
  Future<UserCredential> signInWithGoogle();

  /// Registers a new account with email and password.
  Future<UserCredential> registerWithEmail(String email, String password);

  /// Signs in with existing email and password credentials.
  Future<UserCredential> signInWithEmail(String email, String password);

  /// Sends a password reset email to the given address.
  Future<void> sendPasswordResetEmail(String email);

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges;

  /// The currently authenticated user, or null if not authenticated.
  User? get currentUser;

  /// Signs out the current user.
  Future<void> signOut();
}

/// Concrete implementation of [FirebaseAuthService] using Firebase Auth and Firestore.
///
/// Handles Phone OTP authentication with:
/// - E.164 phone number validation
/// - Retry limits (max 3 OTP verification attempts per session)
/// - OTP expiry tracking (60 seconds)
/// - SMS delivery failure error handling
/// - Automatic User_Document creation for new phone-authenticated users
class FirebaseAuthServiceImpl implements FirebaseAuthService {
  FirebaseAuthServiceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  /// Regex for E.164 phone number validation: '+' followed by 7-15 digits.
  static final RegExp _e164Regex = RegExp(r'^\+[0-9]{7,15}$');

  /// Maximum number of OTP verification attempts per session.
  static const int _maxVerificationAttempts = 3;

  /// OTP expiry duration in seconds.
  static const int otpExpirySeconds = 60;

  /// Tracks the number of OTP verification attempts in the current session.
  int _verificationAttempts = 0;

  /// Timestamp when the OTP was sent (for expiry display purposes).
  DateTime? _otpSentAt;

  /// The verification ID from the last sendOtp call (used on mobile auto-resolve).
  String? _lastVerificationId;

  /// Returns the last verification ID for use in verifyOtp calls.
  String? get lastVerificationId => _lastVerificationId;

  /// Returns the timestamp when the OTP was sent, for UI countdown display.
  DateTime? get otpSentAt => _otpSentAt;

  /// Returns the number of verification attempts used in the current session.
  int get verificationAttempts => _verificationAttempts;

  /// Returns whether the verification session is locked (max attempts reached).
  bool get isVerificationLocked =>
      _verificationAttempts >= _maxVerificationAttempts;

  /// Validates that the phone number conforms to E.164 format.
  ///
  /// Returns `true` if valid, `false` otherwise.
  static bool isValidE164(String phoneNumber) {
    return _e164Regex.hasMatch(phoneNumber);
  }

  /// Resets the verification attempt counter (e.g., for a new session).
  void resetVerificationAttempts() {
    _verificationAttempts = 0;
    _otpSentAt = null;
    _lastVerificationId = null;
  }

  @override
  Future<void> sendOtp(String phoneNumber) async {
    // Validate E.164 format
    if (!isValidE164(phoneNumber)) {
      throw const AuthException(
        'Invalid phone number format. Please enter a valid phone number starting with + followed by 7-15 digits.',
        code: 'invalid-phone-number',
      );
    }

    // Reset attempts for a new OTP session
    _verificationAttempts = 0;

    final completer = Completer<String>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: otpExpirySeconds),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android (auto-resolve SMS)
          // Complete the flow automatically
          if (!completer.isCompleted) {
            completer.complete(credential.verificationId ?? '');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(
              AuthException(
                _mapFirebaseAuthError(e),
                code: e.code,
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _lastVerificationId = verificationId;
          _otpSentAt = DateTime.now();
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Called when auto-retrieval times out
          _lastVerificationId = verificationId;
        },
      );

      // Wait for the verification ID or error
      await completer.future;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException(
        'SMS could not be sent. Please check your connection and try again.',
        code: 'sms-delivery-failed',
      );
    }
  }

  @override
  Future<UserCredential> verifyOtp(String verificationId, String otp) async {
    // Check if verification session is locked
    if (isVerificationLocked) {
      throw const AuthException(
        'Maximum verification attempts reached. Please request a new OTP.',
        code: 'too-many-attempts',
      );
    }

    // Validate OTP format (must be exactly 6 digits)
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      _verificationAttempts++;
      throw const AuthException(
        'Invalid OTP format. Please enter a 6-digit code.',
        code: 'invalid-otp-format',
      );
    }

    // Check OTP expiry (60 seconds)
    if (_otpSentAt != null) {
      final elapsed = DateTime.now().difference(_otpSentAt!).inSeconds;
      if (elapsed > otpExpirySeconds) {
        throw const AuthException(
          'OTP has expired. Please request a new code.',
          code: 'otp-expired',
        );
      }
    }

    // Increment attempt counter
    _verificationAttempts++;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Check if this is a new user and create User_Document if needed
      await _ensureUserDocument(userCredential);

      // Reset attempts on successful verification
      _verificationAttempts = 0;

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw AuthException(
          'The code you entered is invalid. ${_maxVerificationAttempts - _verificationAttempts} attempt(s) remaining.',
          code: 'invalid-otp',
        );
      }
      if (e.code == 'session-expired') {
        throw const AuthException(
          'OTP has expired. Please request a new code.',
          code: 'otp-expired',
        );
      }
      throw AuthException(
        _mapFirebaseAuthError(e),
        code: e.code,
      );
    }
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in flow
      if (googleUser == null) {
        throw const AuthException(
          'Google sign-in was cancelled.',
          code: 'sign-in-cancelled',
        );
      }

      // Obtain the auth details from the Google Sign-In
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a credential from the Google auth tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Ensure User_Document exists for this Google-authenticated user
      await _ensureGoogleUserDocument(userCredential);

      return userCredential;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw const AuthException(
          'An account already exists with a different sign-in method. Please sign in using your original method.',
          code: 'account-exists-with-different-credential',
        );
      }
      throw AuthException(
        _mapFirebaseAuthError(e),
        code: e.code,
      );
    } catch (e) {
      // Handle network errors and other unexpected failures
      if (e.toString().contains('network') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('NetworkError')) {
        throw const AuthException(
          'Network error. Please check your connection and try again.',
          code: 'network-request-failed',
        );
      }
      throw const AuthException(
        'Google sign-in failed. Please try again.',
        code: 'google-sign-in-failed',
      );
    }
  }

  /// Regex for basic email format validation: contains @, has domain with dot.
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Validates that the email conforms to basic email format.
  ///
  /// Returns `true` if the email contains @, has a domain with a dot.
  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }

  /// Validates that the password meets length requirements (8-128 characters).
  ///
  /// Returns `true` if the password length is between 8 and 128 inclusive.
  static bool isValidPassword(String password) {
    return password.length >= 8 && password.length <= 128;
  }

  /// Validates email and password inputs, throwing [AuthException] on failure.
  void _validateEmailAndPassword(String email, String password) {
    if (!isValidEmail(email)) {
      throw const AuthException(
        'Invalid email format. Please enter a valid email address.',
        code: 'invalid-email',
      );
    }
    if (!isValidPassword(password)) {
      throw const AuthException(
        'Password must be between 8 and 128 characters.',
        code: 'invalid-password',
      );
    }
  }

  @override
  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    // Validate inputs first
    _validateEmailAndPassword(email, password);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create User_Document for new email-authenticated user
      await _ensureUserDocumentForEmail(userCredential);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const AuthException(
          'An account with this email already exists. Please sign in instead.',
          code: 'email-already-in-use',
        );
      }
      throw AuthException(
        _mapFirebaseAuthError(e),
        code: e.code,
      );
    }
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    // Validate inputs first
    _validateEmailAndPassword(email, password);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'invalid-credential') {
        throw const AuthException(
          'Invalid credentials. Please check your email and password.',
          code: 'invalid-credentials',
        );
      }
      throw AuthException(
        _mapFirebaseAuthError(e),
        code: e.code,
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!isValidEmail(email)) {
      throw const AuthException(
        'Invalid email format. Please enter a valid email address.',
        code: 'invalid-email',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Do NOT reveal that the email doesn't exist — return silently
        return;
      }
      throw AuthException(
        _mapFirebaseAuthError(e),
        code: e.code,
      );
    }
  }

  /// Ensures a User_Document exists at `users/{uid}` for email-authenticated users.
  ///
  /// If no document exists, creates one with the email and uid.
  Future<void> _ensureUserDocumentForEmail(
      UserCredential userCredential) async {
    final user = userCredential.user;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    resetVerificationAttempts();
  }

  /// Ensures a User_Document exists at `users/{uid}` for phone-authenticated users.
  ///
  /// If no document exists, creates one with the phone number and uid.
  Future<void> _ensureUserDocument(UserCredential userCredential) async {
    final user = userCredential.user;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'phoneNumber': user.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Ensures a User_Document exists at `users/{uid}` for Google-authenticated users.
  ///
  /// If no document exists, creates one with email, displayName, and uid.
  Future<void> _ensureGoogleUserDocument(UserCredential userCredential) async {
    final user = userCredential.user;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Maps Firebase Auth error codes to user-friendly error messages.
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number format is invalid. Please check and try again.';
      case 'too-many-requests':
        return 'Too many requests. Please wait before trying again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'invalid-verification-code':
        return 'The verification code is invalid. Please try again.';
      case 'session-expired':
        return 'The verification session has expired. Please request a new code.';
      default:
        return e.message ??
            'An authentication error occurred. Please try again.';
    }
  }
}
