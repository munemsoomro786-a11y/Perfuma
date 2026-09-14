import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool isLogin = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isLogin ? 'Welcome Back' : 'Create Account',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Georgia'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.red.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: 15),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
              ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFc9a063),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isLogin ? 'LOGIN' : 'SIGN UP', style: const TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                  _errorMessage = null;
                });
              },
              child: Text(
                isLogin ? 'Need an account? Sign up' : 'Already have an account? Login',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
