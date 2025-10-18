import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _busAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _busAnimation = Tween<double>(
      begin: 0.0,
      end: 80.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated bus icon moving slightly forward
            AnimatedBuilder(
              animation: _busAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_busAnimation.value, 0),
                  child: FaIcon(
                    FontAwesomeIcons.vanShuttle,
                    // color: Colors.cyan,
                    size: 80,
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'साड्डाVaahan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
