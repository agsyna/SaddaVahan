import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:saadibus/providers/languageProvider.dart';
import 'package:saadibus/utils/globals.dart';
import 'package:saadibus/utils/keywords.dart';

class HomepageProvider extends ChangeNotifier {
  String lang = currentLanguage;
  String? _currentLocationAddress;
  Map<String, double>? _currentLocationCoords;
  bool _isLoadingLocation = false;
  bool _hasLocationPermission = false;
  bool _hasInitializedLocation = false;
  bool _isRequestingPermission = false; // Prevent multiple permission requests

  BuildContext? _context;
  void updateContext(BuildContext context) {
    _context = context;
    notifyListeners();
  }

  String? get currentLocationAddress => _currentLocationAddress;
  Map<String, double>? get currentLocationCoords => _currentLocationCoords;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get hasLocationPermission => _hasLocationPermission;

  String get language {
    try {
      if (_context == null) return currentLanguage;
      return Provider.of<LanguageProvider>(_context!, listen: true).language;
    } catch (e) {
      return currentLanguage;
    }
  }

  String getAltFloatIconText() {
    final lang = language;
    return applicationText[lang]!['floatIconText'] ?? '';
  }

  String get appBarTitle {
    final lang = language;
    return applicationText[lang]!['appBarTitle'] ??
        applicationText['eng']!['appBarTitle']!;
  }

  String get drawerHeaderTitle {
    final lang = language;
    return applicationText[lang]!['drawerHeaderTitle'] ??
        applicationText['eng']!['drawerHeaderTitle']!;
  }

  String get recentSearchesTitle {
    final lang = language;
    return applicationText[lang]!['recentSearchesTitle'] ??
        applicationText['eng']!['recentSearchesTitle']!;
  }

  String get leaveingHint {
    final lang = language;
    return applicationText[lang]!['leaveingHint'] ??
        applicationText['eng']!['leaveingHint']!;
  }

  String get goingHint {
    final lang = language;
    return applicationText[lang]!['goingHint'] ??
        applicationText['eng']!['goingHint']!;
  }

  String get departure {
    final lang = language;
    return applicationText[lang]!['departure'] ??
        applicationText['eng']!['departure']!;
  }

  String get search {
    final lang = language;
    return applicationText[lang]!['search'] ??
        applicationText['eng']!['search']!;
  }

  String get signInButtonText {
    final lang = language;
    return applicationText[lang]!['signInButtonText'] ??
        applicationText['eng']!['signInButtonText']!;
  }

  String get signOutText {
    final lang = language;
    return applicationText[lang]!['signOut'] ??
        applicationText['eng']!['signOut']!;
  }

  String get homeText {
    final lang = language;
    return applicationText[lang]!['home'] ?? applicationText['eng']!['home']!;
  }

  String get languageText {
    final lang = language;
    return applicationText[lang]!['language'] ??
        applicationText['eng']!['language']!;
  }

  String get helpAndSupportText {
    final lang = language;
    return applicationText[lang]!['helpAndSupport'] ??
        applicationText['eng']!['helpAndSupport']!;
  }

  String get feedbackText {
    final lang = language;
    return applicationText[lang]!['feedback'] ??
        applicationText['eng']!['feedback']!;
  }

  String get aboutText {
    final lang = language;
    return applicationText[lang]!['about'] ?? applicationText['eng']!['about']!;
  }

  String get welcomeText {
    final lang = language;
    return applicationText[lang]!['welcome'] ??
        applicationText['eng']!['welcome']!;
  }

  String get currentLocationText {
    final lang = language;
    return applicationText[lang]!['currentLocation'] ??
        applicationText['eng']!['currentLocation'] ??
        'Current Location';
  }

  // Check location permission with single request lock
  Future<bool> checkLocationPermission() async {
    try {
      debugPrint('📍 Checking location permission...');
      
      // First check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 Current permission status: $permission');
      
      // If already granted, return true
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        debugPrint('✅ Location permission already granted: $permission');
        _hasLocationPermission = true;
        notifyListeners();
        return true;
      }
      
      // If permission is permanently denied, can't request again
      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions are permanently denied');
        _hasLocationPermission = false;
        notifyListeners();
        return false;
      }
      
      // Check if another permission request is already in progress
      if (_isRequestingPermission) {
        debugPrint('⏳ Permission request already in progress, waiting...');
        // Wait for the current request to complete with timeout
        int waitTime = 0;
        const int maxWaitTime = 10000; // 10 seconds timeout
        while (_isRequestingPermission && waitTime < maxWaitTime) {
          await Future.delayed(const Duration(milliseconds: 500));
          waitTime += 500;
        }
        
        // If timeout occurred, reset the flag
        if (_isRequestingPermission) {
          debugPrint('⚠️ Permission request timeout, resetting flag');
          _isRequestingPermission = false;
        }
        
        // Return the current permission status
        return _hasLocationPermission;
      }
      
      // Start permission request
      if (permission == LocationPermission.denied) {
        _isRequestingPermission = true;
        debugPrint('📍 Permission denied, requesting permission...');
        
        try {
          permission = await Geolocator.requestPermission().timeout(
            const Duration(seconds: 30), // 30 second timeout for permission request
            onTimeout: () {
              debugPrint('⚠️ Permission request timed out');
              return LocationPermission.denied;
            },
          );
          debugPrint('📍 Permission request result: $permission');
        } catch (e) {
          debugPrint('❌ Permission request error: $e');
          permission = LocationPermission.denied;
        } finally {
          _isRequestingPermission = false;
        }
      }
      
      // Check final permission status
      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions are permanently denied after request');
        _hasLocationPermission = false;
        notifyListeners();
        return false;
      }
      
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permissions are denied by user after request');
        _hasLocationPermission = false;
        notifyListeners();
        return false;
      }
      
      debugPrint('✅ Location permission granted: $permission');
      _hasLocationPermission = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error checking location permission: $e');
      _isRequestingPermission = false;
      _hasLocationPermission = false;
      notifyListeners();
      return false;
    }
  }

  // Get current location address
  Future<String?> getCurrentLocationAddress() async {
    // Return cached result if available and not loading
    if (_currentLocationAddress != null && !_isLoadingLocation) {
      debugPrint('📍 Returning cached location: $_currentLocationAddress');
      return _currentLocationAddress;
    }
    
    if (_isLoadingLocation) {
      debugPrint('📍 Location already being loaded, waiting...');
      return _currentLocationAddress;
    }
    
    try {
      _isLoadingLocation = true;
      notifyListeners();

      debugPrint('📍 === LOCATION SERVICE CHECK STARTED ===');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📍 Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled - asking user to enable');
        _isLoadingLocation = false;
        notifyListeners();
        return null;
      }

      // Check permission
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        _isLoadingLocation = false;
        notifyListeners();
        return null;
      }

      // Get current position with multiple fallback strategies
      Position? position;
      
      try {
        // First try with high accuracy and short timeout
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (e) {
        debugPrint('High accuracy location failed, trying medium accuracy: $e');
        try {
          // Fallback to medium accuracy with longer timeout
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 20),
          );
        } catch (e2) {
          debugPrint('Medium accuracy location failed, trying last known location: $e2');
          // Fallback to last known position
          position = await Geolocator.getLastKnownPosition();
          if (position == null) {
            debugPrint('No last known position available, trying low accuracy');
            // Final fallback to low accuracy
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 30),
            );
          }
        }
      }

      if (position == null) {
        debugPrint('Unable to get any location');
        _isLoadingLocation = false;
        notifyListeners();
        return null;
      }

      debugPrint('Got position: ${position.latitude}, ${position.longitude}');

      // Store coordinates
      _currentLocationCoords = {
        'lat': position.latitude,
        'lng': position.longitude,
      };

      // Get address using Google Geocoding API
      String? address = await _getAddressFromGoogleAPI(
        position.latitude,
        position.longitude,
      );

      if (address != null && address.isNotEmpty) {
        _currentLocationAddress = address;
        debugPrint('Current location address from Google API: $address');
      } else {
        // If Google API fails, use coordinates
        _currentLocationAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
        debugPrint('Google API geocoding failed, using coordinates: $_currentLocationAddress');
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      _currentLocationAddress = null;
      
      // Show user-friendly error message based on error type
      if (e.toString().contains('PERMISSION')) {
        debugPrint('Location permission error');
      } else if (e.toString().contains('UNAVAILABLE') || e.toString().contains('IO_ERROR')) {
        debugPrint('Location service unavailable - check if GPS is enabled and try again');
      } else {
        debugPrint('Unknown location error: $e');
      }
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }

    return _currentLocationAddress;
  }

  // Get address from Google Geocoding API
  Future<String?> _getAddressFromGoogleAPI(double latitude, double longitude) async {
    try {
      final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        debugPrint('Google Maps API key not found in .env file');
        return null;
      }

      final String url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$latitude,$longitude'
          '&key=$apiKey'
          '&result_type=street_address|route|sublocality|locality|administrative_area_level_3|administrative_area_level_2|administrative_area_level_1'
          '&location_type=ROOFTOP|RANGE_INTERPOLATED|GEOMETRIC_CENTER';

      debugPrint('Making Google Geocoding API request to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final results = data['results'] as List;
          
          // Try to find the best result (prefer street address)
          Map<String, dynamic>? bestResult;
          
          for (var result in results) {
            final types = result['types'] as List<dynamic>? ?? [];
            
            // Prefer street_address type
            if (types.contains('street_address')) {
              bestResult = result;
              break;
            }
            // Fallback to route
            else if (types.contains('route') && bestResult == null) {
              bestResult = result;
            }
            // Fallback to sublocality
            else if (types.contains('sublocality') && bestResult == null) {
              bestResult = result;
            }
            // Fallback to any result
            else if (bestResult == null) {
              bestResult = result;
            }
          }
          
          if (bestResult != null) {
            // Get formatted address or build from components
            String? formattedAddress = bestResult['formatted_address'];
            
            if (formattedAddress != null && formattedAddress.isNotEmpty) {
              // Clean up the formatted address for better display
              String cleanAddress = _cleanFormattedAddress(formattedAddress);
              debugPrint('Google API formatted address: $cleanAddress');
              return cleanAddress;
            } else {
              // Build address from components if formatted_address is not available
              String? componentAddress = _buildAddressFromComponents(bestResult);
              if (componentAddress != null) {
                debugPrint('Google API component address: $componentAddress');
                return componentAddress;
              }
            }
          }
        } else {
          debugPrint('Google Geocoding API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error calling Google Geocoding API: $e');
    }
    
    return null;
  }

  // Clean formatted address to make it more concise and readable
  String _cleanFormattedAddress(String address) {
    // Remove country (typically at the end after last comma)
    List<String> parts = address.split(', ');
    
    // Remove "India" or other country names if present at the end
    if (parts.length > 1 && 
        (parts.last.toLowerCase().contains('india') || 
         parts.last.toLowerCase().contains('भारत'))) {
      parts.removeLast();
    }
    
    // Remove postal codes (6-digit numbers)
    parts = parts.where((part) => !RegExp(r'^\d{6}$').hasMatch(part.trim())).toList();
    
    // Limit to first 3 most relevant parts for conciseness
    if (parts.length > 3) {
      parts = parts.take(3).toList();
    }
    
    return parts.join(', ');
  }

  // Build address from address components
  String? _buildAddressFromComponents(Map<String, dynamic> result) {
    try {
      final components = result['address_components'] as List<dynamic>? ?? [];
      
      List<String> addressParts = [];
      String? streetNumber;
      String? route;
      String? sublocality;
      String? locality;
      String? administrativeArea;
      
      for (var component in components) {
        final types = component['types'] as List<dynamic>? ?? [];
        final longName = component['long_name'] as String? ?? '';
        
        if (types.contains('street_number')) {
          streetNumber = longName;
        } else if (types.contains('route')) {
          route = longName;
        } else if (types.contains('sublocality') || types.contains('sublocality_level_1')) {
          sublocality = longName;
        } else if (types.contains('locality')) {
          locality = longName;
        } else if (types.contains('administrative_area_level_2') || 
                   types.contains('administrative_area_level_1')) {
          administrativeArea = longName;
        }
      }
      
      // Build address in a logical order
      if (streetNumber != null && route != null) {
        addressParts.add('$streetNumber $route');
      } else if (route != null) {
        addressParts.add(route);
      }
      
      if (sublocality != null && sublocality != route) {
        addressParts.add(sublocality);
      }
      
      if (locality != null && locality != sublocality) {
        addressParts.add(locality);
      }
      
      if (administrativeArea != null && 
          administrativeArea != locality && 
          addressParts.length < 3) {
        addressParts.add(administrativeArea);
      }
      
      return addressParts.isNotEmpty ? addressParts.join(', ') : null;
    } catch (e) {
      debugPrint('Error building address from components: $e');
      return null;
    }
  }

  // Reset permission state - useful for debugging stuck states
  void resetPermissionState() {
    debugPrint('🔄 Resetting permission state...');
    _isRequestingPermission = false;
    _hasLocationPermission = false;
    _isLoadingLocation = false;
    notifyListeners();
  }

  // Initialize location on app start
  Future<void> initializeLocation() async {
    // Reset any stuck states first
    if (_isRequestingPermission) {
      debugPrint('⚠️ Found stuck permission request on init, resetting...');
      resetPermissionState();
    }
    
    await getCurrentLocationAddress();
  }
}
