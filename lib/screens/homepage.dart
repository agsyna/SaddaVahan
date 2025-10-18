import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:saadibus/providers/homepageProvider.dart';
import 'package:saadibus/providers/languageProvider.dart';
import 'package:saadibus/screens/RecordingScreen.dart';
import 'package:saadibus/services/authservice.dart';
import 'package:saadibus/widgets/homepage_search.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:animations/animations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController dropController = TextEditingController();
  final TextEditingController busSearchController = TextEditingController();

  List<Map<String, String>> recentSearches = [
    {"route": "Delhi → Gurgaon", "code": "DL01"},
    {"route": "Noida → Faridabad", "code": "UP16"},
    {"route": "Jaipur → Delhi", "code": "RJ14"},
  ];

  DateTime selectedDate = DateTime.now();

  // Audio recording variables
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isSigningIn = false;
  String? _userId;
  String? _userName;

  final stt.SpeechToText _speech = stt.SpeechToText();

  void swapLocations() {
    String temp = pickupController.text;
    pickupController.text = dropController.text;
    dropController.text = temp;
  }

  void _changeLanguage(String lang) {
    Provider.of<LanguageProvider>(context, listen: false).setAppLanguage(lang);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Language switched to $lang"),
        backgroundColor: const Color(0xFF0C2353),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        debugPrint('Auth state changed: ${data.event}');
        debugPrint('Current user: ${supabase.auth.currentUser?.email}');
        debugPrint('Current user: ${supabase.auth.currentUser?.email}');
        _userId = data.session?.user.id;
        _userName =
            data.session?.user.userMetadata?['full_name'] ??
            data.session?.user.userMetadata?['name'] ??
            data.session?.user.email?.split('@')[0];
      });
    });
    _initSpeechState();
    _requestPermissions();
    _initializeLocation();
    // _loadSettings();
  }

  void _initializeLocation() async {
    // Initialize location in the provider and trigger location fetching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HomepageProvider>(context, listen: false);
      // Check permission and also initialize location for pickup
      provider.checkLocationPermission().then((_) {
        // Try to get location immediately to prime the cache
        provider.getCurrentLocationAddress();
      });
    });
  }

  void _initSpeechState() async {
    await _speech.initialize(
      onStatus: (status) => debugPrint('status: $status'),
      onError: (error) => debugPrint('error: $error'),
    );
    setState(() {});
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  // Future<void> _loadSettings() async {
  //   final saved = await MySharedPrefs.getBool('dataSaver') ?? false;
  //   if (mounted) setState(() => _dataSaver = saved);
  // }

  // Future<void> _toggleDataSaver(bool value) async {
  //   setState(() => _dataSaver = value);
  //   await MySharedPrefs.setValue('dataSaver', value);
  //   _showSnackBar(value ? 'Data Saver enabled' : 'Data Saver disabled');
  // }

  void _handleLocationsFromRecording(List<String> locations) {
    debugPrint('HOMEPAGE: Received locations from RecordingScreen: $locations');
    debugPrint('Locations array length: ${locations.length}');

    if (locations.length >= 2) {
      debugPrint('✅ Setting location fields:');
      debugPrint('  📍 Pickup: "${locations[0]}"');
      debugPrint('  🎯 Drop-off: "${locations[1]}"');

      setState(() {
        pickupController.text = locations[0];
        dropController.text = locations[1];
      });

      debugPrint('🔄 Auto-navigation scheduled in 500ms...');

      // Auto navigate to available buses screen after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          debugPrint('🚀 Starting navigation to available buses screen');
          debugPrint('📦 Provider updated with locations');

          // Navigate to available buses screen with pickup and drop locations
          final pickup = Uri.encodeComponent(pickupController.text);
          final drop = Uri.encodeComponent(dropController.text);
          GoRouter.of(context).push('/availableBuses?pickup=$pickup&drop=$drop');
          debugPrint('✅ Navigation completed with pickup: $pickup, drop: $drop');
        } else {
          debugPrint('❌ Navigation cancelled - widget not mounted');
        }
      });
    } else {
      debugPrint(
        '❌ Invalid locations array - expected 2 locations, got ${locations.length}',
      );
    }
  }

  void _openLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              _buildLanguageOption(context, 'English', 'eng', Icons.language),
              _buildLanguageOption(context, 'Hindi', 'hin', Icons.translate),
              _buildLanguageOption(
                context,
                'Punjabi',
                'pun',
                Icons.g_translate,
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String language,
    String code,
    IconData icon,
  ) {
    final currentLang = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).language;
    final isSelected = currentLang == code;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.cyan : const Color(0xFF0C2353),
        ),
        title: Text(language),
        trailing: isSelected
            ? const Icon(Icons.check, color: Colors.cyan)
            : null,
        onTap: () {
          _changeLanguage(code);
          context.pop();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: isSelected ? Colors.cyan.withOpacity(0.1) : null,
      ),
    );
  }

  Widget _buildAuthSection(HomepageProvider provider) {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    if (isLoggedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.recentSearchesTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: recentSearches.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final search = recentSearches[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Extract pickup and drop locations from the route
                      final route = search["route"]!;
                      final locations = route.split(' → ');
                      print("$locations");
                      if (locations.length == 2) {
                        final pickup = Uri.encodeComponent(locations[0].trim());
                        final drop = Uri.encodeComponent(locations[1].trim());
                        GoRouter.of(context).push('/availableBuses?pickup=$pickup&drop=$drop');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.04),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.history,
                              color: Colors.cyan,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  search["route"] ?? "Unknown Route",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  search["code"] ?? "N/A",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isSmallScreen = screenWidth < 360;
            final buttonPadding = isSmallScreen ? 16.0 : 24.0;
            final fontSize = isSmallScreen ? 14.0 : 16.0;
            final iconSize = isSmallScreen ? 18.0 : 20.0;
            final spacing = isSmallScreen ? 12.0 : 16.0;

            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05, // 5% margin on each side
              ),
              constraints: BoxConstraints(
                maxWidth: 400, // Maximum width for larger screens
                minWidth: 200, // Minimum width for very small screens
              ),
              child: InkWell(
                onTap: _isSigningIn
                    ? null
                    : () async {
                        if (_isSigningIn) return; // Prevent multiple taps

                        setState(() {
                          _isSigningIn = true;
                        });

                        try {
                          await AuthService().signInWithGoogle();
                        } catch (e) {
                          debugPrint('Sign in error: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Sign in failed. Please try again.',
                                ),
                                backgroundColor: Colors.red.shade400,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSigningIn = false;
                            });
                          }
                        }
                      },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: buttonPadding,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: _isSigningIn
                        ? Row(
                            key: const ValueKey('loading'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: iconSize,
                                height: iconSize,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.cyan,
                                  ),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Flexible(
                                child: Text(
                                  'Signing in...',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(
                                      0xFF0C2353,
                                    ).withOpacity(0.7),
                                    letterSpacing: 0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('default'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Image.network(
                                  'https://developers.google.com/identity/images/g-logo.png',
                                  width: iconSize,
                                  height: iconSize,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: iconSize,
                                        height: iconSize,
                                        decoration: BoxDecoration(
                                          color: Colors.cyan.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Icon(
                                          FontAwesomeIcons.google,
                                          size: iconSize * 0.6,
                                          color: Colors.cyan,
                                        ),
                                      ),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Flexible(
                                child: Text(
                                  provider.signInButtonText,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0C2353),
                                    letterSpacing: 0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    pickupController.dispose();
    dropController.dispose();
    busSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomepageProvider>(
        context,
        listen: false,
      ).updateContext(context);
    });

    return Consumer<HomepageProvider>(
      builder: (context, provider, child) {
        final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

        return SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                isLoggedIn
                    ? "${provider.welcomeText}, ${_userName?.split(' ')[0] ?? 'User'}!"
                    : provider.appBarTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton.icon(
                    onPressed: () => _openLanguageModal(context),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.language),
                    label: Text(() {
                      final code = Provider.of<LanguageProvider>(
                        context,
                        listen: true,
                      ).language;
                      switch (code) {
                        case 'hin':
                          return 'ही';
                        case 'pun':
                          return 'ਪੰ';
                        default:
                          return 'EN';
                      }
                    }(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            drawer: Drawer(
              width: MediaQuery.of(context).size.width * 0.68,

              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.drawerHeaderTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${provider.languageText}: ${Provider.of<LanguageProvider>(context, listen: true).language.toUpperCase()}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: Text(provider.homeText),
                      onTap: () => context.pop(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(provider.languageText),
                      subtitle: Text(
                        Provider.of<LanguageProvider>(
                          context,
                          listen: true,
                        ).language.toUpperCase(),
                      ),
                      onTap: () {
                        context.pop();
                        _openLanguageModal(context);
                      },
                    ),
                    isLoggedIn
                        ? ListTile(
                            leading: const Icon(
                              Icons.exit_to_app,
                              color: Color(0xFF0C2353),
                            ),
                            title: Text(
                              provider.signOutText,
                              style: TextStyle(
                                color: Color(0xFF0C2353),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              AuthService().signOut();
                              context.pop();
                              setState(() {});
                            },
                          )
                        : const SizedBox.shrink(),

                    // SwitchListTile.adaptive(
                    //   secondary: const Icon(Icons.data_saver_on_outlined),
                    //   title: const Text('Data Saver'),
                    //   subtitle: const Text('Reduce network usage and animations'),
                    //   value: _dataSaver,
                    //   onChanged: _toggleDataSaver,
                    // ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: Text(provider.helpAndSupportText),
                      onTap: () async {
                        await launchUrl(
                          Uri.parse('mailto:support@saaddavaahan.app'),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(provider.aboutText),
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: provider.appBarTitle,
                        applicationVersion: '1.0.0',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Search container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SearchContainer(),
                ),

                const SizedBox(height: 32),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildAuthSection(provider),
                  ),
                ),
              ],
            ),

            floatingActionButton: OpenContainer(
              transitionDuration: const Duration(milliseconds: 500),
              closedElevation: 8,
              openElevation: 0,
              closedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              closedColor: _isRecording
                  ? Colors.red.shade400
                  : _isProcessing
                  ? Colors.orange.shade400
                  : Theme.of(context).colorScheme.primary,
              openColor: Theme.of(context).scaffoldBackgroundColor,
              transitionType: ContainerTransitionType.fadeThrough,
              openBuilder: (context, closeContainer) => RecordingScreen(
                onLocationsFilled: _handleLocationsFromRecording,
              ),
              closedBuilder: (context, openContainer) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isRecording
                                  ? Colors.red.shade400
                                  : _isProcessing
                                  ? Colors.orange.shade400
                                  : Theme.of(context).colorScheme.primary)
                              .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isProcessing ? null : openContainer,
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: _isProcessing
                          ? const Center(
                              key: ValueKey('loading'),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : Icon(
                              key: ValueKey(_isRecording ? 'stop' : 'mic'),
                              _isRecording
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // FloatingActionButton(
            //   onPressed: _isProcessing ? null : _handleMicPress,
            //   child: _isProcessing
            //       ? const SizedBox(
            //           width: 22,
            //           height: 22,
            //           child: CircularProgressIndicator(strokeWidth: 2),
            //         )
            //       : Icon(_isRecording ? Icons.stop : Icons.mic),
            //   backgroundColor: _isRecording
            //       ? Colors.red.shade400
            //       : (_isProcessing ? Colors.orange.shade400 : null),
            // ),
          ),
        );
      },
    );
  }
}
