import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:saadibus/providers/recordingScreenProvider.dart';

class RecordingScreen extends StatefulWidget {
  final Function()? onStartRecording;
  final Function()? onStopRecording;
  final Function(List<String>)? onLocationsFilled;

  const RecordingScreen({
    super.key,
    this.onStartRecording,
    this.onStopRecording,
    this.onLocationsFilled,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  bool _isRecording = true;
  bool _isProcessing = false;
  bool _isCompleted = false;

  // Audio recording variables
  final AudioRecorder _audioRecorder = AudioRecorder();
  // ignore: unused_field
  String? _audioPath;

  // Auto-stop timer
  Timer? _autoStopTimer;
  int _remainingSeconds = 8;
  final String GEMINI_API_KEY = dotenv.env['GEMINI_API_KEY'] ?? '';
  static String GEMINI_API_URL =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _requestPermissions().then((_) => _startActualRecording());
  }

  void _initAnimations() {
    // Light pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _startActualRecording() async {
    try {
      debugPrint('🎤 Starting recording process...');
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocumentsDir =
            await getApplicationDocumentsDirectory();
        final String filePath = '${appDocumentsDir.path}/audio_record.m4a';

        debugPrint('📁 Audio file path: $filePath');

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        setState(() {
          _audioPath = filePath;
          _remainingSeconds = 8;
        });

        debugPrint('✅ Recording started successfully: $filePath');
        widget.onStartRecording?.call();

        // Start auto-stop timer
        _startAutoStopTimer();
      } else {
        debugPrint('❌ Recording permission denied');
        _showSnackBar('Microphone permission required');
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      _showSnackBar('Error starting recording: $e');
      Navigator.of(context).pop();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startAutoStopTimer() {
    _autoStopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          timer.cancel();
          _processRecording();
        }
      }
    });
  }

  Future<List<String>?> _sendAudioToGemini(String audioPath) async {
    try {
      final File audioFile = File(audioPath);
      final Uint8List audioBytes = await audioFile.readAsBytes();
      final String base64Audio = base64Encode(audioBytes);

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Extract pickup and drop-off locations from the audio. You must validate that both locations are real places in India. Return a JSON array with exactly two strings: [pickup_location, dropoff_location]. If either location doesn\'t exist in India or is not a valid Indian city/place, return an empty array []. Only return locations that are actual cities, towns, or places in India like Delhi, Mumbai, Bangalore, Chennai, Kolkata, Hyderabad, Pune, Ahmedabad, Jaipur, etc.',
              },
              {
                'inline_data': {'mime_type': 'audio/m4a', 'data': base64Audio},
              },
            ],
          },
        ],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 1000},
      };

      final response = await http.post(
        Uri.parse(GEMINI_API_URL),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': GEMINI_API_KEY,
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('🤖 Gemini API Response:');
      debugPrint('📊 Status: ${response.statusCode}');
      debugPrint('📄 Raw Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        final candidates = jsonResp['candidates'];
        if (candidates != null && candidates is List && candidates.isNotEmpty) {
          final candidate = candidates[0];
          final parts = candidate['content']?['parts'];
          if (parts != null && parts is List && parts.isNotEmpty) {
            String candidateText = parts[0]['text'] as String;
            candidateText = candidateText.replaceAll(RegExp('```'), '').trim();

            int startIndex = candidateText.indexOf('[');
            if (startIndex != -1) {
              candidateText = candidateText.substring(startIndex);
            }
            debugPrint('Cleaned candidate text: $candidateText');

            try {
              final List<dynamic> locations = jsonDecode(candidateText);
              if (locations.isEmpty) {
                debugPrint(
                  "❌ VALIDATION: Empty array returned - locations not found in India",
                );
                return null;
              } else if (locations.length >= 2) {
                final List<String> result = locations
                    .map((e) => e.toString())
                    .toList();
                debugPrint(
                  "✅ VALIDATION: Valid Indian locations found: $result",
                );
                return result;
              } else {
                debugPrint("❌ VALIDATION: Insufficient locations extracted");
                return null;
              }
            } catch (e) {
              debugPrint('❌ Error parsing locations JSON: $e');
              return null;
            }
          } else {
            debugPrint("Gemini response error: No parts found.");
            return null;
          }
        } else {
          debugPrint("Gemini response error: No candidates found.");
          return null;
        }
      } else {
        debugPrint(
          'Gemini API Error: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error sending audio to Gemini: $e');
      return null;
    }
  }

  void _processRecording() async {
    // Cancel auto-stop timer if it's still running
    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    try {
      // Stop recording
      final path = await _audioRecorder.stop();
      widget.onStopRecording?.call();

      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      if (path != null) {
        debugPrint('Recording stopped: $path');
        final locations = await _sendAudioToGemini(path);

        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isCompleted = true;
          });

          if (locations != null && locations.length >= 2) {
            debugPrint('🎯 SUCCESS: Extracted locations: $locations');
            debugPrint(
              '📤 Calling onLocationsFilled callback with: $locations',
            );
            widget.onLocationsFilled?.call(locations);
            // Don't pop here - let OpenContainer handle navigation
            await Future.delayed(const Duration(milliseconds: 1500));
          } else {
            debugPrint('❌ FAILURE: No valid locations extracted');
            debugPrint('📊 Locations received: $locations');
            _showSnackBar(
              'Please mention valid locations in India (e.g., Delhi, Mumbai, Bangalore)',
            );
            await Future.delayed(const Duration(milliseconds: 1500));
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      } else {
        setState(() {
          _isProcessing = false;
        });
        _showSnackBar('Recording failed');
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error processing recording: $e');
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Error processing audio: $e');
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoStopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecordingScreenProvider>(
        context,
        listen: false,
      ).updateContext(context);
    });
    return Consumer<RecordingScreenProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white.withOpacity(0.95),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Light animated recording indicator
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Single subtle pulse circle
                        if (_isRecording)
                          Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.cyan.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),

                        // Main mic container
                        Transform.scale(
                          scale: _isRecording ? _scaleAnimation.value : 1.0,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCompleted
                                  ? Colors.green.shade400
                                  : _isProcessing
                                  ? Colors.orange.shade300
                                  : Colors.cyan.shade300,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (_isCompleted
                                              ? Colors.green
                                              : _isProcessing
                                              ? Colors.orange
                                              : Colors.cyan)
                                          .withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: _isProcessing
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _isCompleted
                                        ? Icons.check_rounded
                                        : Icons.mic_rounded,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Status text
                if (_isRecording) ...[
                  Text(
                    provider.listeningText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.listeningHintText,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Tap to stop
                  GestureDetector(
                    onTap: _processRecording,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.cyan.shade300),
                        color: Colors.cyan.shade50,
                      ),
                      child: Text(
                        provider.tapToStopText,
                        style: TextStyle(
                          color: Colors.cyan.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ] else if (_isProcessing) ...[
                  Text(
                    provider.processingText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.understandingText,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ] else if (_isCompleted) ...[
                  Text(
                    provider.recordingCompleteText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.recordingSuccessText,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],

                const SizedBox(height: 32),

                // Navigate to home button
                if (_isCompleted)
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      provider.goToHomeButtonText,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
