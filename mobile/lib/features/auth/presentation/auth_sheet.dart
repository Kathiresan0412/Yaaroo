import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api_client.dart';
import '../../../main.dart' show YaaroScope, YaaroColors, AppTextField;

class AuthSheet extends StatefulWidget {
  const AuthSheet({
    this.initialSignup = false,
    this.initialMode,
    this.token,
    super.key,
  });

  final bool initialSignup;
  final AuthMode? initialMode;
  final String? token;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

enum AuthMode { login, signup, forgot, reset, verify }

class _AuthSheetState extends State<AuthSheet> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _resetToken = TextEditingController();
  final _verifyToken = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  late AuthMode _mode;
  bool _loading = false;
  String? _message;
  bool _isSuccess = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Password Validation States
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) {
      _mode = widget.initialMode!;
      if (_mode == AuthMode.verify && widget.token != null) {
        _verifyToken.text = widget.token!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _submit();
        });
      } else if (_mode == AuthMode.reset && widget.token != null) {
        _resetToken.text = widget.token!;
      }
    } else {
      _mode = widget.initialSignup ? AuthMode.signup : AuthMode.login;
    }
    _password.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _resetToken.dispose();
    _verifyToken.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final text = _password.text;
    setState(() {
      _hasMinLength = text.length >= 8;
      _hasUppercase = text.contains(RegExp(r'[A-Z]'));
      _hasDigit = text.contains(RegExp(r'[0-9]'));
      _hasSpecial = text.contains(RegExp(r'[!@#\$&*~•°#%^&*(),.?":{}|<>]'));
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasDigit && _hasSpecial;

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: eighteenYearsAgo,
      firstDate: DateTime(now.year - 100),
      lastDate: eighteenYearsAgo,
      barrierColor: Colors.black.withOpacity(0.28),
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const SizedBox.expand(),
              ),
            ),
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: YaaroColors.rose,
                  onPrimary: Colors.white,
                  surface: YaaroColors.surface,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            ),
          ],
        );
      },
    );
    if (selected != null) {
      setState(() => _dateOfBirth = selected);
    }
  }

  Widget _buildActionButtonWithHeart() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildActionButton(),
        Positioned(
          right: -4,
          top: -12,
          bottom: -12,
          child: IgnorePointer(
            child: CustomPaint(
              size: const Size(48, 48),
              painter: NeonHeartPainter(
                color: const Color(0xFFFF2D79),
                strokeWidth: 1.5,
                fill: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
        ),
        child: PremiumAuthBackground(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SafeArea(
              top: false,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      if (_message != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isSuccess
                                ? YaaroColors.teal.withOpacity(0.12)
                                : YaaroColors.rose.withOpacity(0.12),
                            border: Border.all(
                              color: _isSuccess ? YaaroColors.teal : YaaroColors.rose,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color: _isSuccess ? YaaroColors.teal : YaaroColors.rose,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildFormFields(),
                      const SizedBox(height: 22),
                      _buildActionButtonWithHeart(),
                      const SizedBox(height: 12),
                      _buildSwitchLinks(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String titleText = '';
    String kicker = '';
    switch (_mode) {
      case AuthMode.login:
        titleText = 'Welcome back';
        kicker = 'Enter your credentials to continue';
        break;
      case AuthMode.signup:
        titleText = 'Create your account';
        kicker = 'Join Yaaro0 and start meeting verified members';
        break;
      case AuthMode.forgot:
        titleText = 'Reset password';
        kicker = 'Enter your email to request a reset code';
        break;
      case AuthMode.reset:
        titleText = 'Choose new password';
        kicker = 'Enter your reset code and new password';
        break;
      case AuthMode.verify:
        titleText = 'Email verification';
        kicker = 'Enter the verification code sent to your email';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Color(0x9BFF2D79), // Hot pink neon shadow
                blurRadius: 10,
                offset: Offset(0, 0),
              ),
              Shadow(
                color: Color(0x44FF2D79),
                blurRadius: 20,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          kicker,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        // Google Button
        OutlinedButton.icon(
          onPressed: _loading
              ? null
              : () => _handleOAuthLogin(
                    provider: 'google',
                    oauthId: 'google_oauth_100200300',
                    email: 'googleuser@gmail.com',
                    firstName: 'Google',
                    lastName: 'User',
                  ),
          icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
          label: const Text('Continue with Google',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: YaaroColors.line),
            backgroundColor: YaaroColors.surfaceAlt,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 10),
        // TikTok Button
        OutlinedButton.icon(
          onPressed: _loading
              ? null
              : () => _handleOAuthLogin(
                    provider: 'tiktok',
                    oauthId: 'tiktok_oauth_400500600',
                    email: 'tiktokuser@gmail.com',
                    firstName: 'TikTok',
                    lastName: 'User',
                  ),
          icon: const Icon(Icons.music_note, color: Colors.white, size: 20),
          label: const Text('Continue with TikTok',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: YaaroColors.line),
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Container(height: 1, color: Colors.white10)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('or use email', style: TextStyle(color: YaaroColors.muted, fontSize: 12)),
            ),
            Expanded(child: Container(height: 1, color: Colors.white10)),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFormFields() {
    switch (_mode) {
      case AuthMode.login:
        return Column(
          children: [
            _buildSocialButtons(),
            AppTextField(
              controller: _email,
              label: 'Email address',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _password,
              label: 'Password',
              visible: _showPassword,
              onToggle: () => setState(() => _showPassword = !_showPassword),
            ),
          ],
        );
      case AuthMode.signup:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _firstName,
                    label: 'First name',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    controller: _lastName,
                    label: 'Last name',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _email,
              label: 'Email address',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildDateOfBirthField(),
            const SizedBox(height: 12),
            _buildGenderField(),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _password,
              label: 'Password',
              visible: _showPassword,
              onToggle: () => setState(() => _showPassword = !_showPassword),
            ),
            const SizedBox(height: 8),
            _buildPasswordValidationGuide(),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _confirmPassword,
              label: 'Confirm password',
              visible: _showConfirmPassword,
              onToggle: () => setState(
                () => _showConfirmPassword = !_showConfirmPassword,
              ),
            ),
          ],
        );
      case AuthMode.forgot:
        return AppTextField(
          controller: _email,
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
        );
      case AuthMode.reset:
        return Column(
          children: [
            AppTextField(
              controller: _resetToken,
              label: 'Reset Code',
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _password,
              label: 'New Password',
              visible: _showPassword,
              onToggle: () => setState(() => _showPassword = !_showPassword),
            ),
            const SizedBox(height: 8),
            _buildPasswordValidationGuide(),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _confirmPassword,
              label: 'Confirm New Password',
              visible: _showConfirmPassword,
              onToggle: () => setState(
                () => _showConfirmPassword = !_showConfirmPassword,
              ),
            ),
          ],
        );
      case AuthMode.verify:
        return Column(
          children: [
            AppTextField(
              controller: _verifyToken,
              label: 'Verification Code',
            ),
            const SizedBox(height: 6),
            const Text(
              'Check your email to verify your account. If the app did not open automatically, copy the verification code from your email and enter it above.',
              style: TextStyle(color: YaaroColors.muted, fontSize: 12),
            ),
          ],
        );
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: YaaroColors.rose,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.045),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: YaaroColors.rose, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: visible ? 'Hide password' : 'Show password',
            icon: Icon(
              visible ? Icons.visibility_off : Icons.visibility,
              color: Colors.white60,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    final selectedDate = _dateOfBirth == null
        ? null
        : DateFormat('yyyy-MM-dd').format(_dateOfBirth!);

    return _buildPickerField(
      icon: Icons.cake,
      label: 'Date of birth (18+)',
      value: selectedDate ?? 'Select date of birth (18+)',
      hasValue: selectedDate != null,
      onTap: _selectDateOfBirth,
      isDob: true,
    );
  }

  Widget _buildGenderField() {
    return _buildPickerField(
      icon: Icons.person_outline,
      label: 'Gender',
      value: _genderLabel(_gender) ?? 'Select gender',
      hasValue: _gender != null,
      onTap: _selectGender,
    );
  }

  Widget _buildPickerField({
    required IconData icon,
    required String label,
    required String value,
    required bool hasValue,
    required VoidCallback onTap,
    bool isDob = false,
  }) {
    final innerWidget = Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        border: isDob ? null : Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: isDob ? const Color(0xFFFF2D79) : YaaroColors.rose, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasValue) ...[
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasValue ? Colors.white : Colors.white54,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white60, size: 20),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: isDob
          ? CustomPaint(
              painter: VineBorderPainter(glowColor: const Color(0xFFFF2D79)),
              child: innerWidget,
            )
          : innerWidget,
    );
  }

  Future<void> _selectGender() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        const genders = ['female', 'male', 'non_binary', 'other'];

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF16062A), // Match deep purple bottom sheet
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select Gender',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                for (final gender in genders)
                  ListTile(
                    title: Text(
                      _genderLabel(gender)!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: _gender == gender
                        ? const Icon(Icons.check, color: Color(0xFFFF2D79))
                        : null,
                    onTap: () => Navigator.pop(context, gender),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _gender = selected);
    }
  }

  String? _genderLabel(String? value) {
    switch (value) {
      case 'female':
        return 'Female';
      case 'male':
        return 'Male';
      case 'non_binary':
        return 'Non-binary';
      case 'other':
        return 'Other';
    }
    return null;
  }

  Widget _buildPasswordValidationGuide() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password Requirements:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _buildValidatorRow(':=', '8+ characters (more for safety)', _hasMinLength),
          const SizedBox(height: 6),
          _buildValidatorRow('Az', 'At least 1 Uppercase letter (A-Z)', _hasUppercase),
          const SizedBox(height: 6),
          _buildValidatorRow('123', 'At least 1 Numeric digit (0-9)', _hasDigit),
          const SizedBox(height: 6),
          _buildValidatorRow('!@', 'At least 1 Special character (!@#\$%&*^)', _hasSpecial),
        ],
      ),
    );
  }

  Widget _buildValidatorRow(String prefix, String text, bool valid) {
    const activeColor = Color(0xFF31D0B2); // Teal
    final inactiveColor = Colors.white.withOpacity(0.6);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          alignment: Alignment.centerLeft,
          child: Text(
            prefix,
            style: TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: valid ? activeColor : inactiveColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valid ? activeColor.withOpacity(0.9) : inactiveColor.withOpacity(0.8),
              decoration: valid ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Icon(
          valid ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: valid ? activeColor : Colors.white24,
          size: 14,
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    String label = '';
    switch (_mode) {
      case AuthMode.login:
        label = 'Log in';
        break;
      case AuthMode.signup:
        label = 'Request Access';
        break;
      case AuthMode.forgot:
        label = 'Send Reset Code';
        break;
      case AuthMode.reset:
        label = 'Reset Password';
        break;
      case AuthMode.verify:
        label = 'Verify Email';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF2D79), // Hot Pink
            Color(0xFFFF6D3B), // Coral Orange
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D79).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _submit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchLinks() {
    if (_loading) return const SizedBox.shrink();

    switch (_mode) {
      case AuthMode.login:
        return Column(
          children: [
            TextButton(
              onPressed: () => setState(() {
                _message = null;
                _mode = AuthMode.signup;
              }),
              child: const Text('New to Yaaro0? Create account'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _message = null;
                      _mode = AuthMode.forgot;
                    }),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Forgot password?',
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _message = null;
                      _mode = AuthMode.verify;
                    }),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Verify account manually',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case AuthMode.signup:
        return Column(
          children: [
            TextButton(
              onPressed: () => setState(() {
                _message = null;
                _mode = AuthMode.login;
              }),
              child: const Text('Already have an account? Log in'),
            ),
            TextButton(
              onPressed: () => setState(() {
                _message = null;
                _mode = AuthMode.verify;
              }),
              child: const Text('Have a verification code? Verify manually'),
            ),
          ],
        );
      case AuthMode.forgot:
        return TextButton(
          onPressed: () => setState(() {
            _message = null;
            _mode = AuthMode.login;
          }),
          child: const Text('Back to Log in'),
        );
      case AuthMode.reset:
      case AuthMode.verify:
        return TextButton(
          onPressed: () => setState(() {
            _message = null;
            _mode = AuthMode.login;
          }),
          child: const Text('Return to Log in'),
        );
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _message = null;
      _isSuccess = false;
    });

    final api = YaaroScope.of(context);
    try {
      if (_mode == AuthMode.login) {
        if (_email.text.isEmpty || _password.text.isEmpty) {
          throw ApiException('Please fill in all fields.');
        }
        await api.login(_email.text.trim(), _password.text);
        if (mounted) {
          Navigator.pop(context);
        }
      } else if (_mode == AuthMode.signup) {
        if (_firstName.text.trim().isEmpty ||
            _lastName.text.trim().isEmpty ||
            _email.text.trim().isEmpty ||
            _password.text.isEmpty ||
            _dateOfBirth == null ||
            _gender == null) {
          throw ApiException('All signup fields are required.');
        }

        if (!_isPasswordValid) {
          throw ApiException('Your password does not satisfy all validation criteria.');
        }

        if (_password.text != _confirmPassword.text) {
          throw ApiException('Passwords do not match.');
        }

        final dobStr = DateFormat('yyyy-MM-dd').format(_dateOfBirth!);
        await api.signup(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          dateOfBirth: dobStr,
          gender: _gender!.trim(),
        );

        setState(() {
          _isSuccess = true;
          _message = 'Account request created! Check your email to verify your account.';
          _mode = AuthMode.verify;
        });
      } else if (_mode == AuthMode.forgot) {
        if (_email.text.isEmpty) {
          throw ApiException('Please enter your email address.');
        }
        await api.forgotPassword(_email.text.trim());
        setState(() {
          _isSuccess = true;
          _message = 'Reset code has been sent. Enter it below.';
          _mode = AuthMode.reset;
        });
      } else if (_mode == AuthMode.reset) {
        if (_resetToken.text.isEmpty || _password.text.isEmpty) {
          throw ApiException('All fields are required.');
        }
        if (!_isPasswordValid) {
          throw ApiException('Your password does not satisfy all validation criteria.');
        }
        if (_password.text != _confirmPassword.text) {
          throw ApiException('Passwords do not match.');
        }
        await api.resetPassword(_resetToken.text.trim(), _password.text);
        setState(() {
          _isSuccess = true;
          _message = 'Password has been updated! You can now log in.';
          _mode = AuthMode.login;
        });
      } else if (_mode == AuthMode.verify) {
        if (_verifyToken.text.isEmpty) {
          throw ApiException('Please key in your verification code.');
        }
        try {
          await api.verifyEmail(_verifyToken.text.trim());
          setState(() {
            _isSuccess = true;
            _message = 'Email verified successfully! You can now log in.';
            _mode = AuthMode.login;
          });
        } catch (error) {
          final errStr = error.toString().toLowerCase();
          if (errStr.contains('invalid') || errStr.contains('expired')) {
            setState(() {
              _isSuccess = true;
              _message = 'This link may have already been verified! Please try logging in.';
              _mode = AuthMode.login;
            });
          } else {
            rethrow;
          }
        }
      }
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleOAuthLogin({
    required String provider,
    required String oauthId,
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    setState(() {
      _loading = true;
      _message = null;
      _isSuccess = false;
    });

    try {
      final api = YaaroScope.of(context);
      await api.loginWithOAuth(
        provider: provider,
        oauthId: oauthId,
        email: email,
        firstName: firstName,
        lastName: lastName,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      setState(() {
        _message = e.message;
      });
    } catch (e) {
      setState(() {
        _message = 'OAuth login failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}

// Custom Painters and Custom Widgets for Premium Glassmorphism Redesign

class PremiumAuthBackground extends StatelessWidget {
  const PremiumAuthBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Stack(
        children: [
          // 1. Base vertical purple gradient matching main theme
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2E0F4D), // Dark purple/magenta
                    Color(0xFF16062A), // Deep indigo
                    Color(0xFF0C021A), // Darkest purple-black
                  ],
                ),
              ),
            ),
          ),

          // 2. Neon Magenta Ambient Glow in Top-Right
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.9, -0.9),
                  radius: 0.9,
                  colors: [
                    Color(0x3BFF2D79), // Translucent hot pink
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Neon Cyan Ambient Glow in Bottom-Right
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.9, 0.9),
                  radius: 1.1,
                  colors: [
                    Color(0x2800FFFF), // Translucent neon cyan
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 4. Sparkling star at top-right
          Positioned(
            top: 24,
            right: 48,
            child: CustomPaint(
              size: const Size(20, 20),
              painter: SparklePainter(color: Colors.white.withOpacity(0.9)),
            ),
          ),

          // 5. Sparkling star at bottom-right
          Positioned(
            bottom: 32,
            right: 28,
            child: CustomPaint(
              size: const Size(28, 28),
              painter: SparklePainter(color: const Color(0x99E0F7FA)),
            ),
          ),

          // 6. Floating Neon Pink Hearts (3D/Outlined)
          Positioned(
            top: 28,
            right: 24,
            child: Transform.rotate(
              angle: 0.18,
              child: CustomPaint(
                size: const Size(42, 42),
                painter: NeonHeartPainter(
                  color: const Color(0xFFFF4F6D),
                  strokeWidth: 1.5,
                  fill: true,
                ),
              ),
            ),
          ),
          Positioned(
            top: 86,
            left: -12,
            child: Transform.rotate(
              angle: -0.22,
              child: CustomPaint(
                size: const Size(32, 32),
                painter: NeonHeartPainter(
                  color: const Color(0x8BFF4F6D),
                  strokeWidth: 1.2,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -16,
            child: Transform.rotate(
              angle: -0.15,
              child: CustomPaint(
                size: const Size(38, 38),
                painter: NeonHeartPainter(
                  color: const Color(0x66FF4F6D),
                  strokeWidth: 1.2,
                ),
              ),
            ),
          ),

          // 7. Neon Green Wireframe Globes
          // Bottom-left Globe
          Positioned(
            bottom: -54,
            left: -54,
            child: CustomPaint(
              size: const Size(128, 128),
              painter: WireframeGlobePainter(color: const Color(0xFF81C784)),
            ),
          ),
          // Top-right Globe
          Positioned(
            top: -46,
            right: -46,
            child: CustomPaint(
              size: const Size(96, 96),
              painter: WireframeGlobePainter(color: const Color(0xAA81C784)),
            ),
          ),

          // 8. Content
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class WireframeGlobePainter extends CustomPainter {
  final Color color;
  WireframeGlobePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw bounds circle
    canvas.drawCircle(center, radius, paint);

    // Draw horizontal grid lines (latitudes)
    const segments = 6;
    for (int i = 1; i < segments; i++) {
      final ratio = i / segments;
      // latitude offset from center
      final offset = radius * (2.0 * ratio - 1.0);
      final latRad = math.acos(offset.abs() / radius);
      final r = radius * math.sin(latRad);
      final rect = Rect.fromLTRB(
        center.dx - r,
        center.dy + offset - r * 0.2,
        center.dx + r,
        center.dy + offset + r * 0.2,
      );
      canvas.drawOval(rect, paint);
    }

    // Draw vertical grid lines (longitudes)
    for (int i = 0; i < 180; i += 30) {
      final rad = i * math.pi / 180;
      final rx = radius * math.sin(rad);
      final ry = radius;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rad);
      canvas.drawOval(
        Rect.fromLTRB(-rx * 0.3, -ry, rx * 0.3, ry),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NeonHeartPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool fill;

  NeonHeartPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.fill = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    // Standard Heart Parametric Path
    path.moveTo(width / 2, height * 0.3);
    path.cubicTo(
      width * 0.15, height * 0.02,
      -width * 0.05, height * 0.45,
      width / 2, height * 0.88,
    );
    path.cubicTo(
      width * 1.05, height * 0.45,
      width * 0.85, height * 0.02,
      width / 2, height * 0.3,
    );
    path.close();

    if (fill) {
      final fillPaint = Paint()
        ..color = color.withOpacity(0.06)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    // Soft outer neon glow shadow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 3.5
      ..imageFilter = ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5);
    canvas.drawPath(path, glowPaint);

    // Sharp inner neon outline
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SparklePainter extends CustomPainter {
  final Color color;

  SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Circular base glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill
      ..imageFilter = ImageFilter.blur(sigmaX: 4, sigmaY: 4);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 4, glowPaint);

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width / 2;
    final ry = size.height / 2;

    path.moveTo(cx, cy - ry);
    path.quadraticBezierTo(cx, cy, cx + rx, cy);
    path.quadraticBezierTo(cx, cy, cx, cy + ry);
    path.quadraticBezierTo(cx, cy, cx - rx, cy);
    path.quadraticBezierTo(cx, cy, cx, cy - ry);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VineBorderPainter extends CustomPainter {
  final Color glowColor;
  VineBorderPainter({required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );

    // 1. Neon glowing base border
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..imageFilter = ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5);
    canvas.drawRRect(rect, glowPaint);

    final borderPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(rect, borderPaint);

    // 2. Detailed golden-green leaves and vines climbing along the corners
    final vinePaint = Paint()
      ..color = const Color(0xFFC0CA33) // Lime gold vine stems
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final leafPaint = Paint()
      ..color = const Color(0xFF81C784) // Soft green leaf fill
      ..style = PaintingStyle.fill;

    // Bottom-Left Corner Climbing Vine
    final path1 = Path();
    path1.moveTo(28, size.height);
    path1.quadraticBezierTo(12, size.height + 2, 4, size.height - 12);
    path1.quadraticBezierTo(-2, size.height - 24, 6, size.height - 20);
    canvas.drawPath(path1, vinePaint);

    _drawLeaf(canvas, Offset(20, size.height), 0.3, leafPaint);
    _drawLeaf(canvas, Offset(8, size.height - 6), -0.4, leafPaint);
    _drawLeaf(canvas, Offset(3, size.height - 16), -1.1, leafPaint);

    // Top-Right Corner Climbing Vine
    final path2 = Path();
    path2.moveTo(size.width - 28, 0);
    path2.quadraticBezierTo(size.width - 12, -2, size.width - 4, 12);
    path2.quadraticBezierTo(size.width + 2, 24, size.width - 6, 20);
    canvas.drawPath(path2, vinePaint);

    _drawLeaf(canvas, Offset(size.width - 20, 0), -0.3, leafPaint);
    _drawLeaf(canvas, Offset(size.width - 8, 6), 0.4, leafPaint);
    _drawLeaf(canvas, Offset(size.width - 3, 16), 1.1, leafPaint);
  }

  void _drawLeaf(Canvas canvas, Offset position, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    final path = Path();
    path.moveTo(0, 0);
    path.cubicTo(-3.5, -5.5, -6.5, -5.5, 0, -11);
    path.cubicTo(6.5, -5.5, 3.5, -5.5, 0, 0);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

