import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saadibus/services/authservice.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
{

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  void _login(BuildContext context) async {
    try {
      await _auth.signIn(_email.text, _password.text);
      context.go('/'); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login failed: $e")));
      context.go('/'); 
    }
  }

@override
Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            ElevatedButton(onPressed: () => _login(context), child: Text('Login')),
            TextButton(
              child: Text('No account? Sign up'),
              onPressed: () => context.go('/signup')
            )
          ],
        ),
      ),
    );
  }
}