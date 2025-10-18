import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:saadibus/providers/languageProvider.dart';
import 'package:saadibus/providers/homepageProvider.dart';
import 'package:saadibus/providers/availableBusScreenProvider.dart';
import 'package:saadibus/providers/recordingScreenProvider.dart';
import 'package:saadibus/utils/routers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  String supabaseKey = dotenv.env['SUPABASE_KEY'] ?? '';
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.cyan, // Set your desired color here
      // You can also adjust statusBarIconBrightness for icon/text color
      statusBarIconBrightness: Brightness.light, // For dark background
    ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => HomepageProvider()),
        ChangeNotifierProvider(create: (_) => AvailableBusScreenProvider()),
        ChangeNotifierProvider(create: (_) => RecordingScreenProvider()),
      ],
      child: MaterialApp.router(
debugShowCheckedModeBanner: false,
        title: 'SaadiBus',
        routerConfig: router,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: const Color(0xFF00BCD4), // cyan
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFF00BCD4), // cyan
                secondary: const Color(
                  0xFF00BCD4,
                ), // keep CTA cyan for consistency
              ),
          scaffoldBackgroundColor: const Color(0xFFF6F8FB),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF00BCD4),
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

class AuthStateWrapper extends StatefulWidget {
  final Widget child;
  const AuthStateWrapper({super.key, required this.child});
  
  @override
  State<AuthStateWrapper> createState() => _AuthStateWrapperState();
}

class _AuthStateWrapperState extends State<AuthStateWrapper> {
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
    _authStream.listen((event) {
      // Trigger a rebuild when auth state changes.
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
