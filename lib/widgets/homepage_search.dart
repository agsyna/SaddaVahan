import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:saadibus/models/prediction.dart';
import 'package:saadibus/providers/homepageProvider.dart';
import 'package:saadibus/utils/common_utils.dart';

class SearchContainer extends StatefulWidget {
  const SearchContainer({super.key});

  @override
  State<SearchContainer> createState() => _SearchContainerState();
}

class _SearchContainerState extends State<SearchContainer> {
  final TextEditingController leavingController = TextEditingController();
  final TextEditingController goingController = TextEditingController();
  final FocusNode leavingFocus = FocusNode();
  final FocusNode goingFocus = FocusNode();
  DateTime selectedDate = DateTime.now();
  OverlayEntry? leavingOverlay;
  OverlayEntry? goingOverlay;
  List<PredictionsModel> leavingPredictions = [];
  List<PredictionsModel> goingPredictions = [];
  bool _isSearching = false;
  bool _isCurrentLocationSet = false;
  bool _hasTriedAutoLocation = false;
  
  // Store coordinates for both locations
  Map<String, double>? pickupCoords;
  Map<String, double>? dropCoords;

  void swapLocations() {
    String tempText = leavingController.text;
    leavingController.text = goingController.text;
    goingController.text = tempText;
    
    // Also swap coordinates
    Map<String, double>? tempCoords = pickupCoords;
    pickupCoords = dropCoords;
    dropCoords = tempCoords;
  }

  // Search function to call Google Places Autocomplete API.
  searchLocation(String query, {required bool isLeaving}) async {
    if (query.length < 3) {
      setState(() {
        if (isLeaving) {
          leavingPredictions = [];
        } else {
          goingPredictions = [];
        }
      });
      return;
    }
    String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query"
        "&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}"
        "&components=country:in";
    try {
      var resp = await CUtils.getResponse(url: url);
      if (resp["status"] != "OK") return;
      var predictions = resp["predictions"] as List;
      var predictionsList = predictions
          .map((e) => PredictionsModel.fromJson(e))
          .toList();
      setState(() {
        if (isLeaving) {
          leavingPredictions = predictionsList;
          _showOverlay(isLeaving: true);
        } else {
          goingPredictions = predictionsList;
          _showOverlay(isLeaving: false);
        }
      });
    } catch (e) {
      setState(() {
        if (isLeaving) {
          leavingPredictions = [];
        } else {
          goingPredictions = [];
        }
      });
    }
  }

  @override
  void dispose() {
    leavingController.dispose();
    goingController.dispose();
    leavingFocus.dispose();
    goingFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  void _clearPredictions(bool isLeaving) {
    setState(() {
      if (isLeaving) {
        leavingPredictions = [];
        leavingOverlay?.remove();
        leavingOverlay = null;
      } else {
        goingPredictions = [];
        goingOverlay?.remove();
        goingOverlay = null;
      }
    });
  }

  Future<Map<String, double>?> getLatLngFromPlaceId(String placeId) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}";
    try {
      final resp = await CUtils.getResponse(url: url);
      if (resp["status"] != "OK") return null;

      final location = resp["result"]["geometry"]["location"];
      return {
        "lat": location["lat"],
        "lng": location["lng"],
      };
    } catch (e) {
      debugPrint("LatLng fetch error: $e");
      return null;
    }
  }

  void _showOverlay({required bool isLeaving}) {
    final focusNode = isLeaving ? leavingFocus : goingFocus;
    final controller = isLeaving ? leavingController : goingController;
    final predictions = isLeaving ? leavingPredictions : goingPredictions;

    // Remove any existing overlay first.
    if (isLeaving) {
      leavingOverlay?.remove();
    } else {
      goingOverlay?.remove();
    }
    if (predictions.isEmpty) return;

    // Get position & size of the text field.
    final RenderBox renderBox =
        focusNode.context!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    final dropdownWidth = size.width;
    double leftPosition = offset.dx;
    if (leftPosition + dropdownWidth > screenWidth - 16) {
      leftPosition = screenWidth - dropdownWidth - 16;
    }
    if (leftPosition < 16) {
      leftPosition = 16;
    }

    // Build the overlay. Wrap the dropdown in a GestureDetector that clears it if tapped outside.
    final entry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _clearPredictions(isLeaving);
        },
        child: Stack(
          children: [
            Positioned(
              left: leftPosition - 60,
              top: offset.dy + size.height + 4,
              width: dropdownWidth + 80,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.08),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: predictions.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.cyan.withOpacity(0.1),
                        ),
                        itemBuilder: (context, index) {
                          final prediction = predictions[index];
                          return GestureDetector(
                            onTap: () async {
                              final address =
                                  "${prediction.mainText} ${prediction.secondaryText}"
                                      .trim();
                              controller.text = address;
                              
                              // Get coordinates for this place
                              final coords = await getLatLngFromPlaceId(prediction.placeId ?? "");
                              if (coords != null) {
                                setState(() {
                                  if (isLeaving) {
                                    pickupCoords = coords;
                                    _isCurrentLocationSet = false; // Clear current location flag
                                  } else {
                                    dropCoords = coords;
                                  }
                                });
                                debugPrint("${isLeaving ? 'Pickup' : 'Drop'} coordinates set: $coords");
                              }
                              
                              _clearPredictions(isLeaving);
                              focusNode.unfocus();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.cyan.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.cyan,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prediction.mainText,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                              decoration:
                                                  TextDecoration.none),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          prediction.secondaryText,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color:
                                                  Colors.grey.shade600,
                                              fontSize: 12,
                                              decoration:
                                                  TextDecoration.none),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    if (isLeaving) {
      leavingOverlay = entry;
    } else {
      goingOverlay = entry;
    }
  }

  // Get current location coordinates using HomepageProvider
  Future<void> _getCurrentLocationCoordinates() async {
    final provider = Provider.of<HomepageProvider>(context, listen: false);
    final address = await provider.getCurrentLocationAddress();
    
    if (address != null && address.isNotEmpty) {
      // Get actual coordinates from the provider
      final coords = provider.currentLocationCoords;
      if (coords != null) {
        setState(() {
          leavingController.text = "Current Location"; // Show simple text instead of full address
          _isCurrentLocationSet = true;
          pickupCoords = coords; // Store actual GPS coordinates from provider
        });
        debugPrint("✅ Current location coordinates set: $coords");
      } else {
        debugPrint("❌ No coordinates available from provider");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<HomepageProvider>(
    builder : (context, provider, child) {
      // Update provider context only once, not on every build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          provider.updateContext(context);
        }
      });

      // Auto-initialize location when app starts - try immediately regardless of permission status
      if (!_hasTriedAutoLocation && 
          leavingController.text.isEmpty &&
          !_isCurrentLocationSet) {
        _hasTriedAutoLocation = true;
        
        debugPrint('🚀 Attempting auto-location initialization...');
        debugPrint('🚀 Provider hasLocationPermission: ${provider.hasLocationPermission}');
        debugPrint('🚀 Provider isLoadingLocation: ${provider.isLoadingLocation}');
        
        // Use Future.microtask to avoid setState during build
        Future.microtask(() async {
          if (!mounted) return;
          
          try {
            debugPrint('🚀 Starting automatic location initialization...');
            final address = await provider.getCurrentLocationAddress();
            debugPrint('🚀 Auto-initialization result: $address');
            debugPrint('🚀 Provider hasLocationPermission after attempt: ${provider.hasLocationPermission}');
            debugPrint('🚀 Provider isLoadingLocation after attempt: ${provider.isLoadingLocation}');
            
            if (address != null && address.isNotEmpty && mounted) {
              // Get actual coordinates from the provider
              final coords = provider.currentLocationCoords;
              if (coords != null) {
                setState(() {
                  leavingController.text = "Current Location"; // Show simple text instead of full address
                  _isCurrentLocationSet = true;
                  pickupCoords = coords; // Store actual GPS coordinates from provider
                });
                debugPrint('✅ Auto-location set successfully: Current Location with coordinates: $coords');
              } else {
                debugPrint('❌ Coordinates not available from provider');
              }
            } else {
              debugPrint('❌ Auto-location failed: address is null or empty');
              if (!provider.hasLocationPermission) {
                debugPrint('⚠️ Auto-location failed due to missing permission - user can still use manual location button');
              }
            }
          } catch (e) {
            debugPrint('❌ Auto-location error: $e');
          }
        });
      }
      
      return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leaving from with current location support
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    TextField(
                      controller: leavingController,
                      focusNode: leavingFocus,
                      keyboardType: TextInputType.name,
                      onChanged: (value) {
                        // If user starts typing, clear the current location flag
                        if (_isCurrentLocationSet) {
                          setState(() {
                            _isCurrentLocationSet = false;
                            pickupCoords = null; // Clear coordinates when user types
                          });
                        }
                        searchLocation(value, isLeaving: true);
                      },
                      style: TextStyle(
                        color: _isCurrentLocationSet ? Colors.transparent : Colors.black,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: const Icon(
                            Icons.trip_origin,
                            color: Colors.cyan,
                            size: 22,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        hintText: provider.leaveingHint,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                    // Show "Current Location" overlay when current location is set
                    if (_isCurrentLocationSet && leavingController.text.isNotEmpty)
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 48), // Account for icon space
                          child: Text(
                            'Current Location',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  if (provider.isLoadingLocation) return;
                  
                  await _getCurrentLocationCoordinates();
                  _clearPredictions(true);
                  
                  if (_isCurrentLocationSet) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Expanded(child: Text('Current location set')),
                          ],
                        ),
                        backgroundColor: Colors.green.shade400,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  } else {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.location_off, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Expanded(child: Text('Unable to get current location')),
                          ],
                        ),
                        backgroundColor: Colors.red.shade400,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: provider.isLoadingLocation
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                          ),
                        )
                      : Icon(
                          Icons.my_location,
                          color: provider.hasLocationPermission ? Colors.cyan : Colors.grey,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Going To with swap
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: goingController,
                  focusNode: goingFocus,
                  keyboardType: TextInputType.name,
                  onChanged: (value) {
                    searchLocation(value, isLeaving: false);
                  },
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: const Icon(
                        Icons.place_outlined,
                        color: Colors.cyan,
                        size: 22,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    hintText: provider.goingHint,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              InkWell(
                onTap: swapLocations,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                    border: Border.all(color: Colors.cyan, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.swap_vert, color: Colors.cyan),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Departure date strip
          Text(
            provider.departure,
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                DateTime date = DateTime.now().add(Duration(days: index));
                bool isSelected =
                    DateFormat('d').format(date) ==
                    DateFormat('d').format(selectedDate);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.cyan : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          DateFormat('E').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Search Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSearching ? null : () async {
                if (_isSearching) return; // Prevent multiple taps
                
                if (leavingController.text.isEmpty ||
                    goingController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Please enter both locations"),
                      backgroundColor: Colors.red.shade400,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  return;
                }

                if (pickupCoords == null || dropCoords == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Please select valid pickup and drop locations from the suggestions"),
                      backgroundColor: Colors.orange.shade400,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  _isSearching = true;
                });

                try {
                  // Clear any overlays and unfocus
                  _clearPredictions(true);
                  _clearPredictions(false);
                  if (mounted) {
                    FocusScope.of(context).unfocus();
                  }

                  if (mounted) {
                    // Navigate to available buses screen with coordinates and addresses
                    final pickup = Uri.encodeComponent(leavingController.text.trim());
                    final drop = Uri.encodeComponent(goingController.text.trim());
                    final dateParam = Uri.encodeComponent(DateFormat('yyyy-MM-dd').format(selectedDate));
                    final pickupLat = pickupCoords!['lat'].toString();
                    final pickupLng = pickupCoords!['lng'].toString();
                    final dropLat = dropCoords!['lat'].toString();
                    final dropLng = dropCoords!['lng'].toString();
                    
                    debugPrint('🚀 Navigating with coordinates:');
                    debugPrint('Pickup: $pickup (${pickupCoords!['lat']}, ${pickupCoords!['lng']})');
                    debugPrint('Drop: $drop (${dropCoords!['lat']}, ${dropCoords!['lng']})');
                    
                    context.go('/availableBuses?pickup=$pickup&drop=$drop&date=$dateParam&pickupLat=$pickupLat&pickupLng=$pickupLng&dropLat=$dropLat&dropLng=$dropLng');
                  }
                } catch (e) {
                  debugPrint('Navigation error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Navigation failed. Please try again.'),
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
                      _isSearching = false;
                    });
                  }
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _isSearching
                    ? Row(
                        key: const ValueKey('searching'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Searching...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        key: const ValueKey('search'),
                        provider.search,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
    });
  }
}
