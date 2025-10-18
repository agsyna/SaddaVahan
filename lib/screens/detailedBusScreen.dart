import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:saadibus/models/detailedBusDetail.dart';

class DetailedBusScreen extends StatefulWidget {
  const DetailedBusScreen({super.key, required this.detailedBusDetail});

  final DetailedBusDetail detailedBusDetail;

  @override
  State<DetailedBusScreen> createState() => _DetailedBusScreenState();
}

class _DetailedBusScreenState extends State<DetailedBusScreen> {
  bool isTravelling = false;
  double currentSpeed = 0.0;
  Stream<Position>? positionStream;
  StreamSubscription<Position>? positionSubscription;

  late TextEditingController busIdController;

  @override
  void initState() {
    super.initState();
    busIdController = TextEditingController(text: widget.detailedBusDetail.busNumber);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.cyan,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    );

    positionSubscription = positionStream!.listen((Position position) {
      setState(() {
        currentSpeed = position.speed;
      });
    });
  }

  void _stopLocationTracking() {
    positionSubscription?.cancel();
    positionSubscription = null;
    positionStream = null;
    setState(() {
      currentSpeed = 0.0;
    });
  }

  void _toggleTravelling() async {
    if (!isTravelling) {
      await _startLocationTracking();
    } else {
      _stopLocationTracking();
    }

    setState(() {
      isTravelling = !isTravelling;
    });
  }

  void _editBusId() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Bus ID"),
          content: TextField(
            controller: busIdController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Bus ID",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Update bus ID on screen
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.cyan;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: primaryColor,
          titleSpacing: 0,
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(busIdController.text,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    Text(widget.detailedBusDetail.busName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              if (isTravelling) // show pencil only when travelling ON
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editBusId,
                ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
        ),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.grey.shade200,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.calendar_today, size: 14),
                            SizedBox(width: 4),
                            Text("Today"),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(widget.detailedBusDetail.date,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: widget.detailedBusDetail.stops.length,
                    itemBuilder: (context, index) {
                      final stop = widget.detailedBusDetail.stops[index];
                      final isStart = index == 0;
                      return TimelineTile(
                        isStart: isStart,
                        station: stop.station,
                        arrival: stop.arrival,
                        departure: stop.departure,
                        distance: stop.distance,
                        platform: stop.bay,
                        status: stop.status,
                        primaryColor: primaryColor,
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off,
                          size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.detailedBusDetail.statusMessage.length > 30
                                ? "${widget.detailedBusDetail.statusMessage.substring(0, 30)}..."
                                : widget.detailedBusDetail.statusMessage,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(
                            "Updated: ${widget.detailedBusDetail.lastUpdated}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {},
                      )
                    ],
                  ),
                )
              ],
            ),

            /// Travelling Toggle
            Positioned(
              bottom: 80,
              right: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: isTravelling ? Colors.green : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_bus,
                      size: 20,
                      color: isTravelling ? Colors.green : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isTravelling ? "Travelling ON" : "Travelling OFF",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isTravelling
                                ? Colors.green
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (isTravelling)
                          Text(
                            "${currentSpeed.toStringAsFixed(1)} m/s",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Switch.adaptive(
                      value: isTravelling,
                      activeColor: Colors.green,
                      onChanged: (value) => _toggleTravelling(),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TimelineTile extends StatelessWidget {
  final bool isStart;
  final String station;
  final String arrival;
  final String departure;
  final String distance;
  final String platform;
  final String status;
  final Color primaryColor;

  const TimelineTile({
    super.key,
    required this.isStart,
    required this.station,
    required this.arrival,
    required this.departure,
    required this.distance,
    required this.platform,
    required this.status,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                if (isStart)
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: primaryColor,
                    child: const Icon(Icons.directions_bus,
                        color: Colors.white, size: 16),
                  )
                else
                  const Icon(Icons.circle, size: 10, color: Colors.grey),
                Container(
                  width: 2,
                  height: 50,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  if (distance.isNotEmpty)
                    Text(
                        "$distance  ${platform.isNotEmpty ? platform : ''}",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(arrival,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text(departure,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Text(status,
                      style: TextStyle(
                          fontSize: 12,
                          color: status == "On Time"
                              ? Colors.green
                              : Colors.redAccent)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
