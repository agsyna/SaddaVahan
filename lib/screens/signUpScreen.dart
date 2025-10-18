
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saadibus/services/authservice.dart';

class SignUpScreen  extends StatefulWidget{
  const SignUpScreen ({super.key});

  @override
  State<SignUpScreen > createState() => _SignUpScreenState();

}


class _SignUpScreenState extends State<SignUpScreen> {

    final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

    void _signUp(BuildContext context) async {
    try {
      await _auth.signUp(_email.text, _password.text);
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sign up failed: $e")));
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
            ElevatedButton(onPressed: () => _signUp(context), child: Text('Sign Up')),
            TextButton(
              child: Text('Already have an account? Log in'),
              onPressed: () => context.go('/login')
            )
          ],
        ),
      ),
    );
  }
}