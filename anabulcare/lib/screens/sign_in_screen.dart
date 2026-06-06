import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anabulcare/screens/admin_home_screen.dart';
import 'package:anabulcare/screens/main_navigation_screen.dart';
import 'package:anabulcare/screens/sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _errorMessage = '';

  static const _adminUsername = 'admin';
  static const _adminEmail = 'admin@gmail.com';
  static const _adminPassword = 'admin123';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32.0),
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Username atau Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _handleLogin,
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  );
                },
                child: const Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    final credential = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;

    final isAdminUsername = credential == _adminUsername;
    final isAdminEmail = credential == _adminEmail.toLowerCase();
    final isValidAdmin =
        (isAdminUsername || isAdminEmail) && password == _adminPassword;

    if (isValidAdmin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_logged_in', true);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
      );
      return;
    }

    if (!credential.contains('@')) {
      setState(() {
        _errorMessage =
            'Gunakan email untuk login pengguna atau gunakan kredensial admin.';
      });
      _showError(_errorMessage);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('admin_logged_in');

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: password,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage =
            e.message ?? 'Gagal melakukan login. Periksa kembali data Anda.';
      });
      _showError(_errorMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
