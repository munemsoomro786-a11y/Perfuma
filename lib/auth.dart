import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await credential.user?.updateDisplayName(_nameController.text.trim());
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
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
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
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
        child: Row(
          children: [
            // Left decorative panel (hidden on mobile)
            if (!isMobile)
              Container(
                width: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFF1a1a1a),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('PERFUMA', style: TextStyle(color: Colors.white, fontFamily: 'Georgia', fontSize: 16, letterSpacing: 4)),
                    const SizedBox(height: 16),
                    Container(height: 1, width: 40, color: const Color(0xFFc9a063)),
                    const SizedBox(height: 16),
                    const Text('Luxury\nFragrances', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6, letterSpacing: 1)),
                  ],
                ),
              ),

            // Right form panel
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    child: Form(
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
                                      // Google G logo using text
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
                          Container(
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
                                Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                              ],
                            ),
                          ),
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
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter your password';
                            if (!_isLogin && v.length < 6) return 'Password must be at least 6 characters';
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
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                                    style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
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
                            GestureDetector(
                              onTap: _toggleMode,
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
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              ),
            ),
          ],
        ),
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
