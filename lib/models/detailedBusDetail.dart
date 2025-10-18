class DetailedBusDetail {
  final String busNumber;
  final String busName;
  final String date;
  final String statusMessage;
  final String lastUpdated;
  final List<Stop> stops;

  DetailedBusDetail({
    required this.busNumber,
    required this.busName,
    required this.date,
    required this.statusMessage,
    required this.lastUpdated,
    required this.stops,
  });

  factory DetailedBusDetail.fromJson(Map<String, dynamic> json) {
    return DetailedBusDetail(
      busNumber: json['busNumber'],
      busName: json['busName'],
      date: json['date'],
      statusMessage: json['statusMessage'],
      lastUpdated: json['lastUpdated'],
      stops: (json['stops'] as List)
          .map((stop) => Stop.fromJson(stop))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busNumber': busNumber,
      'busName': busName,
      'date': date,
      'statusMessage': statusMessage,
      'lastUpdated': lastUpdated,
      'stops': stops.map((s) => s.toJson()).toList(),
    };
  }
}

class Stop {
  final String station;
  final String arrival;
  final String departure;
  final String distance;
  final String bay;
  final String status;

  Stop({
    required this.station,
    required this.arrival,
    required this.departure,
    required this.distance,
    required this.bay,
    required this.status,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      station: json['station'],
      arrival: json['arrival'],
      departure: json['departure'],
      distance: json['distance'],
      bay: json['bay'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station': station,
      'arrival': arrival,
      'departure': departure,
      'distance': distance,
      'bay': bay,
      'status': status,
    };
  }
}
