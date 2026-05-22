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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: YaaroColors.rose,
              onPrimary: Colors.white,
              surface: YaaroColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected != null) {
      setState(() => _dateOfBirth = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: YaaroColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(top: BorderSide(color: YaaroColors.line)),
        ),
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
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  if (_message != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? YaaroColors.teal.withOpacity(0.12)
                            : YaaroColors.saffron.withOpacity(0.12),
                        border: Border.all(
                          color: _isSuccess ? YaaroColors.teal : YaaroColors.saffron,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isSuccess ? YaaroColors.teal : YaaroColors.saffron,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildFormFields(),
                  const SizedBox(height: 18),
                  _buildActionButton(),
                  const SizedBox(height: 10),
                  _buildSwitchLinks(),
                ],
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
        kicker = 'Enter your email to request a reset token';
        break;
      case AuthMode.reset:
        titleText = 'Choose new password';
        kicker = 'Enter your reset token and new password';
        break;
      case AuthMode.verify:
        titleText = 'Email verification';
        kicker = 'Enter the verification token sent to your email';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          kicker,
          style: const TextStyle(color: YaaroColors.muted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    switch (_mode) {
      case AuthMode.login:
        return Column(
          children: [
            AppTextField(
              controller: _email,
              label: 'Email address',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _password,
              label: 'Password',
              obscureText: true,
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
            InkWell(
              onTap: _selectDateOfBirth,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake, color: YaaroColors.rose, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dateOfBirth == null
                          ? 'Select date of birth (18+)'
                          : 'DOB: ${DateFormat('yyyy-MM-dd').format(_dateOfBirth!)}',
                      style: TextStyle(
                        color: _dateOfBirth == null ? Colors.white54 : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.white54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              dropdownColor: YaaroColors.surface,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                labelText: 'Select gender',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: const [
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'non_binary', child: Text('Non-binary')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (val) => setState(() => _gender = val),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _password,
              label: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 8),
            _buildPasswordValidationGuide(),
            const SizedBox(height: 8),
            AppTextField(
              controller: _confirmPassword,
              label: 'Confirm password',
              obscureText: true,
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
              label: 'Reset Token',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _password,
              label: 'New Password',
              obscureText: true,
            ),
            const SizedBox(height: 8),
            _buildPasswordValidationGuide(),
            const SizedBox(height: 8),
            AppTextField(
              controller: _confirmPassword,
              label: 'Confirm New Password',
              obscureText: true,
            ),
          ],
        );
      case AuthMode.verify:
        return Column(
          children: [
            AppTextField(
              controller: _verifyToken,
              label: 'Verification Token',
            ),
            const SizedBox(height: 6),
            const Text(
              'Copy the verification token from the link in your email and enter it here.',
              style: TextStyle(color: YaaroColors.muted, fontSize: 12),
            ),
          ],
        );
    }
  }

  Widget _buildPasswordValidationGuide() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Password Requirements:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: YaaroColors.muted)),
          const SizedBox(height: 6),
          _buildValidatorRow('8+ characters', _hasMinLength),
          _buildValidatorRow('Uppercase letter (A-Z)', _hasUppercase),
          _buildValidatorRow('Numeric digit (0-9)', _hasDigit),
          _buildValidatorRow('Special character (!@#\$%&*)', _hasSpecial),
        ],
      ),
    );
  }

  Widget _buildValidatorRow(String text, bool valid) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.circle_outlined,
          color: valid ? YaaroColors.teal : Colors.white30,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: valid ? Colors.white : Colors.white54,
            decoration: valid ? TextDecoration.lineThrough : null,
          ),
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
        label = 'Send Reset Token';
        break;
      case AuthMode.reset:
        label = 'Reset Password';
        break;
      case AuthMode.verify:
        label = 'Verify Email';
        break;
    }

    return FilledButton(
      onPressed: _loading ? null : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: YaaroColors.rose,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                TextButton(
                  onPressed: () => setState(() {
                    _message = null;
                    _mode = AuthMode.forgot;
                  }),
                  child: const Text('Forgot password?'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _message = null;
                    _mode = AuthMode.verify;
                  }),
                  child: const Text('Verify account manually'),
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
              child: const Text('Have a verification token? Verify manually'),
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
          gender: _gender!,
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
          _message = 'Reset token has been dispatched. Enter it below.';
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
          throw ApiException('Please key in your verification token.');
        }
        await api.verifyEmail(_verifyToken.text.trim());
        setState(() {
          _isSuccess = true;
          _message = 'Email verified successfully! You can now log in.';
          _mode = AuthMode.login;
        });
      }
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
