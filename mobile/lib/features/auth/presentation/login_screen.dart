import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart' show YaaroColors;
import '../data/firebase_auth_service.dart';
import '../providers/auth_providers.dart';

/// Login screen wired to Firebase Auth service for phone OTP, Google Sign-In,
/// and email/password authentication.
///
/// Requirements: 2.1, 3.1, 4.1, 18.1
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  // Phone OTP state
  bool _showPhoneFlow = false;
  bool _showOtpInput = false;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;

  // Email flow state
  bool _showEmailFlow = false;
  bool _isRegistering = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() => setState(() => _errorMessage = null);

  void _setError(String msg) => setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------
  Future<void> _signInWithGoogle() async {
    _clearError();
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      // Auth state listener handles navigation
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'sign-in-cancelled') {
        // User cancelled — no error shown
        setState(() => _isLoading = false);
        return;
      }
      _setError(e.message);
    } catch (e) {
      if (!mounted) return;
      _setError('Sign-in failed. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Phone OTP Flow
  // ---------------------------------------------------------------------------
  Future<void> _sendOtp() async {
    _clearError();
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _setError('Please enter your phone number.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendOtp(phone);
      if (!mounted) return;
      setState(() {
        _showOtpInput = true;
        _verificationId = authService.lastVerificationId;
        _isLoading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      _setError(e.message);
    } catch (e) {
      if (!mounted) return;
      _setError('Failed to send OTP. Please try again.');
    }
  }

  Future<void> _verifyOtp() async {
    _clearError();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _setError('Please enter the OTP code.');
      return;
    }

    if (_verificationId == null) {
      _setError('Verification session expired. Please request a new code.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyOtp(_verificationId!, otp);
      // Auth state listener handles navigation
    } on AuthException catch (e) {
      if (!mounted) return;
      _setError(e.message);
    } catch (e) {
      if (!mounted) return;
      _setError('Verification failed. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Email/Password Flow
  // ---------------------------------------------------------------------------
  Future<void> _signInOrRegisterWithEmail() async {
    _clearError();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _setError('Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      if (_isRegistering) {
        await authService.registerWithEmail(email, password);
      } else {
        await authService.signInWithEmail(email, password);
      }
      // Auth state listener handles navigation
    } on AuthException catch (e) {
      if (!mounted) return;
      _setError(e.message);
    } catch (e) {
      if (!mounted) return;
      _setError('Authentication failed. Please try again.');
    }
  }

  Future<void> _resetPassword() async {
    _clearError();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _setError('Please enter your email to reset password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'If an account exists with this email, a reset link has been sent.'),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _setError(e.message);
    } catch (e) {
      if (!mounted) return;
      _setError('Failed to send reset email.');
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite,
                  size: 72,
                  color: YaaroColors.rose,
                ),
                const SizedBox(height: 24),
                Text(
                  'YaaRo0',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to find your match',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: YaaroColors.mutedFor(context),
                      ),
                ),
                const SizedBox(height: 32),

                // Error display
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Main auth method buttons (shown when no sub-flow active)
                if (!_showPhoneFlow && !_showEmailFlow) ...[
                  _buildMainButtons(),
                ],

                // Phone OTP flow
                if (_showPhoneFlow) ...[
                  _buildPhoneFlow(),
                ],

                // Email flow
                if (_showEmailFlow) ...[
                  _buildEmailFlow(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isLoading
                ? null
                : () => setState(() {
                      _showPhoneFlow = true;
                      _showEmailFlow = false;
                      _clearError();
                    }),
            icon: const Icon(Icons.phone),
            label: const Text('Continue with Phone'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _signInWithGoogle,
            icon: const Icon(Icons.g_mobiledata),
            label: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue with Google'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : () => setState(() {
                      _showEmailFlow = true;
                      _showPhoneFlow = false;
                      _clearError();
                    }),
            icon: const Icon(Icons.email_outlined),
            label: const Text('Continue with Email'),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneFlow() {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.phone),
          ),
        ),
        if (_showOtpInput) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: '6-digit OTP',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _isLoading ? null : (_showOtpInput ? _verifyOtp : _sendOtp),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(_showOtpInput ? 'Verify OTP' : 'Send OTP'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _showPhoneFlow = false;
            _showOtpInput = false;
            _clearError();
          }),
          child: const Text('Back to sign-in options'),
        ),
      ],
    );
  }

  Widget _buildEmailFlow() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _signInOrRegisterWithEmail,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(_isRegistering ? 'Register' : 'Sign In'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() => _isRegistering = !_isRegistering),
              child: Text(
                _isRegistering
                    ? 'Already have an account? Sign In'
                    : 'Need an account? Register',
              ),
            ),
          ],
        ),
        if (!_isRegistering)
          TextButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: const Text('Forgot password?'),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _showEmailFlow = false;
            _clearError();
          }),
          child: const Text('Back to sign-in options'),
        ),
      ],
    );
  }
}
