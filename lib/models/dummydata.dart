class DummyData {
  final String name;
  final String startPoint;
  final String endPoint;
  final String latitude;
  final String longitude;
  final DateTime timestamp;
  final String? batteryPer;
  final String? speed;
  final String? networkStatus;

  DummyData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    this.batteryPer,
    this.speed,
    this.networkStatus,
  });

  // Convert DummyData → Map (for DB/API)
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'name': name,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'batteryPer': batteryPer,
      'speed': speed,
      'networkStatus': networkStatus,
    };
  }

  // Convert Map → UserLoc (from DB/API)
  factory DummyData.fromMap(Map<String, dynamic> map) {
    return DummyData(
      latitude: map['latitude'],
      name: map['name'],
      startPoint: map['startPoint'],
      endPoint: map['endPoint'],
      longitude: map['longitude'],
      timestamp: DateTime.parse(map['timestamp']),
      batteryPer: map['batteryPer'],
      speed: map['speed'],
      networkStatus: map['networkStatus'],
    );
  }
}
