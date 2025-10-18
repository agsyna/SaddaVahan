import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:saadibus/models/busDetail.dart';
import 'package:saadibus/providers/languageProvider.dart';
import 'package:saadibus/utils/globals.dart';
import 'package:saadibus/utils/keywords.dart';

enum SortType {
  arrivalTimeAsc,
  arrivalTimeDesc,
  pickupDistanceAsc,
  pickupDistanceDesc,
  dropDistanceAsc,
  dropDistanceDesc,
}

class AvailableBusScreenProvider extends ChangeNotifier {
  /// Address strings (for UI)
  String pickupLocation = '';
  String dropLocation = '';

  /// Coordinates (for API call)
  double? pickupLat;
  double? pickupLng;
  double? dropLat;
  double? dropLng;

  List<IndividualBusDetail> availableBuses = [];
  bool isLoading = false;
  SortType? currentSortType;
  BuildContext? _context;

  void updateContext(BuildContext context) {
    _context = context;
    notifyListeners();
  }

  void setPickup(String address, double lat, double lng) {
    pickupLocation = address;
    pickupLat = lat;
    pickupLng = lng;
    notifyListeners();
  }

  void setDrop(String address, double lat, double lng) {
    dropLocation = address;
    dropLat = lat;
    dropLng = lng;
    notifyListeners();
  }

  void sortBuses(SortType sortType) {
    currentSortType = sortType;
    switch (sortType) {
      case SortType.arrivalTimeAsc:
        availableBuses.sort((a, b) =>
            _extractMinutes(a.arrivalEstimate).compareTo(_extractMinutes(b.arrivalEstimate)));
        break;
      case SortType.arrivalTimeDesc:
        availableBuses.sort((a, b) =>
            _extractMinutes(b.arrivalEstimate).compareTo(_extractMinutes(a.arrivalEstimate)));
        break;
      case SortType.pickupDistanceAsc:
        availableBuses.sort((a, b) =>
            _extractDistance(a.farAwayFromPickup).compareTo(_extractDistance(b.farAwayFromPickup)));
        break;
      case SortType.pickupDistanceDesc:
        availableBuses.sort((a, b) =>
            _extractDistance(b.farAwayFromPickup).compareTo(_extractDistance(a.farAwayFromPickup)));
        break;
      case SortType.dropDistanceAsc:
        availableBuses.sort((a, b) =>
            _extractDistance(a.farAwayFromDrop).compareTo(_extractDistance(b.farAwayFromDrop)));
        break;
      case SortType.dropDistanceDesc:
        availableBuses.sort((a, b) =>
            _extractDistance(b.farAwayFromDrop).compareTo(_extractDistance(a.farAwayFromDrop)));
        break;
    }
    notifyListeners();
  }

  int _extractMinutes(String time) {
    return int.tryParse(time.split(' ')[0]) ?? 0;
  }

  double _extractDistance(String distance) {
    return double.tryParse(distance.split(' ')[0]) ?? 0.0;
  }

  final lang = currentLanguage;
  String get language {
    try {
      if (_context == null) return currentLanguage;
      return Provider.of<LanguageProvider>(_context!, listen: true).language;
    } catch (e) {
      return currentLanguage;
    }
  }

  String get noBusText => applicationText[language]?['noBusAvailable'] ??
      applicationText['eng']!['noBusAvailable']!;
  String get arrivingInText => applicationText[language]?['arrivingIn'] ??
      applicationText['eng']!['arrivingIn']!;
  String get estimatedTimeText => applicationText[language]?['estimatedTime'] ??
      applicationText['eng']!['estimatedTime']!;
  String get sortByText => applicationText[language]?['sortBy'] ??
      applicationText['eng']!['sortBy']!;
  String get arrivalTimeEarliestText =>
      applicationText[language]?['arrivalTimeEarliest'] ??
      applicationText['eng']!['arrivalTimeEarliest']!;
  String get arrivalTimeLatestText =>
      applicationText[language]?['arrivalTimeLatest'] ??
      applicationText['eng']!['arrivalTimeLatest']!;
  String get pickupDistanceNearestText =>
      applicationText[language]?['pickupDistanceNearest'] ??
      applicationText['eng']!['pickupDistanceNearest']!;
  String get pickupDistanceFarthestText =>
      applicationText[language]?['pickupDistanceFarthest'] ??
      applicationText['eng']!['pickupDistanceFarthest']!;
  String get dropDistanceNearestText =>
      applicationText[language]?['dropDistanceNearest'] ??
      applicationText['eng']!['dropDistanceNearest']!;
  String get dropDistanceFarthestText =>
      applicationText[language]?['dropDistanceFarthest'] ??
      applicationText['eng']!['dropDistanceFarthest']!;

  Future<void> loadBusData() async {
    debugPrint("🚌 === BUS DATA LOADING STARTED ===");
    debugPrint("🚌 Coordinates: Pickup($pickupLat, $pickupLng), Drop($dropLat, $dropLng)");
    debugPrint("🚌 Locations: Pickup='$pickupLocation', Drop='$dropLocation'");
    
    if (pickupLat == null ||
        pickupLng == null ||
        dropLat == null ||
        dropLng == null) {
      debugPrint("❌ BUS DATA LOADING FAILED: Coordinates not set");
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(
          "https://tstkypmfvfvzstcovbdj.supabase.co/functions/v1/quick-processor");

      final requestBody = jsonEncode({
        "pickup": {"lat": pickupLat, "lng": pickupLng},
        "drop": {"lat": dropLat, "lng": dropLng},
      });

      debugPrint("🚌 API REQUEST URL: $url");
      debugPrint("🚌 API REQUEST BODY: $requestBody");
      debugPrint("🚌 Making API call...");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: requestBody,
      ).timeout(Duration(seconds: 30));

      debugPrint("🚌 API RESPONSE STATUS: ${response.statusCode}");
      debugPrint("🚌 API RESPONSE HEADERS: ${response.headers}");
      debugPrint("🚌 API RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final dynamic responseData = jsonDecode(response.body);
          debugPrint("🚌 PARSED RESPONSE TYPE: ${responseData.runtimeType}");
          debugPrint("🚌 PARSED RESPONSE: $responseData");

          if (responseData is List) {
            final List<dynamic> data = responseData;
            debugPrint("🚌 FOUND ${data.length} buses in response");

            availableBuses = data.map((bus) {
              debugPrint("🚌 Processing bus: $bus");
              return IndividualBusDetail(
                busId: bus["bus_id"] ?? "",
                busNumber: bus["bus_number"] ?? "",
                arrivalEstimate: bus["arrival_estimate"] ?? "",
                duration: bus["duration"] ?? "",
                pickupPoint: bus["pickup_address"] ?? pickupLocation,
                dropPoint: bus["drop_address"] ?? dropLocation,
                farAwayFromPickup: bus["far_from_pickup"] ?? "",
                farAwayFromDrop: bus["far_from_drop"] ?? "",
              );
            }).toList();

            debugPrint("🚌 SUCCESSFULLY CREATED ${availableBuses.length} bus objects");
          } else {
            debugPrint("❌ UNEXPECTED RESPONSE FORMAT: Expected List, got ${responseData.runtimeType}");
            availableBuses = [];
          }
        } catch (parseError) {
          debugPrint("❌ JSON PARSING ERROR: $parseError");
          debugPrint("❌ RAW RESPONSE BODY: '${response.body}'");
          availableBuses = [];
        }
      } else {
        debugPrint("❌ API CALL FAILED: ${response.statusCode}");
        debugPrint("❌ ERROR RESPONSE: ${response.body}");
        availableBuses = [];
      }

      if (currentSortType != null) {
        sortBuses(currentSortType!);
      }
    } catch (e) {
      debugPrint("🔥 NETWORK/EXCEPTION ERROR: $e");
      debugPrint("🔥 ERROR TYPE: ${e.runtimeType}");
      availableBuses = [];
    }

    isLoading = false;
    notifyListeners();
    
    debugPrint("🚌 === BUS DATA LOADING COMPLETED ===");
    debugPrint("🚌 FINAL BUS COUNT: ${availableBuses.length}");
    debugPrint("🚌 IS LOADING: $isLoading");
  }
}
