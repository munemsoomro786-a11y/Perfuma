import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_service.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // 2-Step OTP Verification state
  bool _awaitingOtp = false;
  String? _generatedOtp;
  DateTime? _otpExpiresAt;
  final _otpController = TextEditingController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_animController);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _awaitingOtp = false;
      _formKey.currentState?.reset();
    });
    _animController.forward(from: 0);
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isGoogleLoading = true; _errorMessage = null; });
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      await FirebaseAuth.instance.signInWithPopup(googleProvider);
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.message ?? 'Google sign-in failed. Try again.'; });
    } catch (e) {
      setState(() { _errorMessage = 'Google sign-in failed. Try again.'; });
    } finally {
      if (mounted) setState(() { _isGoogleLoading = false; });
    }
  }

  // Step 1: Pre-authenticate and Send 6-digit OTP to user's real email
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Validate credentials first with Firebase without establishing persistent full session yet
      if (_isLogin) {
        // Test sign in
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        // Test registration
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        await cred.user?.updateDisplayName(_nameController.text.trim());
      }

      // Temporarily sign out until OTP is verified!
      await FirebaseAuth.instance.signOut();

      // Generate secure 6-digit numeric OTP (e.g. 748192)
      final random = Random();
      final code = (100000 + random.nextInt(900000)).toString();
      _generatedOtp = code;
      _otpExpiresAt = DateTime.now().add(const Duration(minutes: 10));

      // Send OTP via EmailJS
      final sent = await EmailService.sendOtpEmail(
        recipientEmail: email,
        otpCode: code,
      );

      if (!sent) {
        throw Exception('Could not send verification email. Please check your connection.');
      }

      // Switch view to OTP input
      setState(() {
        _awaitingOtp = true;
        _isLoading = false;
      });
      _animController.forward(from: 0);

    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'user-not-found': _errorMessage = 'No account found with this email.'; break;
          case 'wrong-password': _errorMessage = 'Incorrect password. Please try again.'; break;
          case 'invalid-credential': _errorMessage = 'Incorrect email or password.'; break;
          case 'email-already-in-use': _errorMessage = 'An account already exists with this email.'; break;
          case 'weak-password': _errorMessage = 'Password must be at least 6 characters.'; break;
          case 'invalid-email': _errorMessage = 'Please enter a valid email address.'; break;
          default: _errorMessage = e.message ?? 'An error occurred. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // Step 2: Verify OTP and finalize login
  Future<void> _verifyOtp() async {
    final entered = _otpController.text.trim();
    if (entered.length != 6) {
      setState(() => _errorMessage = 'Please enter the full 6-digit verification code.');
      return;
    }

    if (_otpExpiresAt != null && DateTime.now().isAfter(_otpExpiresAt!)) {
      setState(() => _errorMessage = 'Code has expired. Please click Resend Code.');
      return;
    }

    if (entered != _generatedOtp) {
      setState(() => _errorMessage = 'Invalid verification code. Please check your email.');
      return;
    }

    // OTP Verified! Log user in for real
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _errorMessage = 'Verification succeeded, but login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Resend OTP
  Future<void> _resendOtp() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    _generatedOtp = code;
    _otpExpiresAt = DateTime.now().add(const Duration(minutes: 10));

    final sent = await EmailService.sendOtpEmail(
      recipientEmail: _emailController.text.trim(),
      otpCode: code,
    );

    setState(() {
      _isLoading = false;
      if (sent) {
        _errorMessage = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A fresh 6-digit code has been sent to your email.'),
            backgroundColor: Color(0xFFc9a063),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _errorMessage = 'Failed to resend email. Try again shortly.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? double.infinity : 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(28),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    child: _awaitingOtp ? _buildOtpView() : _buildLoginForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Standard Login / Signup Form
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isLogin ? 'Welcome\nBack' : 'Create\nAccount',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Georgia', height: 1.2),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Google Sign-In Button
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isGoogleLoading ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDDDDDD)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: _isGoogleLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(
                            child: Text('G', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Continue with Google', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),

          // Error message
          if (_errorMessage != null) ...[
            _buildErrorBox(_errorMessage!),
            const SizedBox(height: 14),
          ],

          // Name field (only signup)
          if (!_isLogin) ...[
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Full Name', Icons.person_outline),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 14),
          ],

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email Address', Icons.email_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.black38),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 22),

          // Submit Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a1a1a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? "Don't have an account? " : 'Already have an account? ',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              TextButton(
                onPressed: _toggleMode,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _isLogin ? 'Sign Up' : 'Login',
                  style: const TextStyle(
                    color: Color(0xFFc9a063),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFc9a063),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6-Digit OTP Verification View
  Widget _buildOtpView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Security\nVerification',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Georgia', height: 1.2),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFc9a063).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFc9a063).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_read_outlined, color: Color(0xFFc9a063), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A 6-digit code has been sent to ${_emailController.text.trim()}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_errorMessage != null) ...[
          _buildErrorBox(_errorMessage!),
          const SizedBox(height: 14),
        ],

        // 6-Digit input field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8, color: Color(0xFF1a1a1a)),
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: const TextStyle(color: Colors.black26, letterSpacing: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFc9a063), width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 20),

        // Verify button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a1a1a),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: _isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('VERIFY & LOGIN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 16),

        // Resend or Back
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() { _awaitingOtp = false; _errorMessage = null; }),
              child: const Text('← Back to Login', style: TextStyle(color: Colors.black54, fontSize: 13)),
            ),
            TextButton(
              onPressed: _isLoading ? null : _resendOtp,
              child: const Text(
                'Resend Code',
                style: TextStyle(color: Color(0xFFc9a063), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.black38),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.black26)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFc9a063), width: 2)),
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
