// class IndividualBusDetail {
//   final String busId;
//   final String busNumber;
//   final String pickupPoint;
//   final String dropPoint;
//   final String farAwayFromPickup;
//   final String farAwayFromDrop;
//   final String duration;
//   final String arrivalEstimate;

//   IndividualBusDetail({
//     required this.busId,
//     required this.busNumber,
//     required this.pickupPoint,
//     required this.dropPoint,
//     required this.farAwayFromPickup,
//     required this.farAwayFromDrop,
//     required this.duration,
//     required this.arrivalEstimate,
//   });

//   factory IndividualBusDetail.fromJson(Map<String, dynamic> json) {
//     return IndividualBusDetail(
//       busId: json['bus_id'] ?? '',
//       busNumber: json['bus_number'] ?? '',
//       pickupPoint: json['pickup_address'] ?? '',
//       dropPoint: json['drop_address'] ?? '',
//       farAwayFromPickup: json['far_from_pickup'] ?? '',
//       farAwayFromDrop: json['far_from_drop'] ?? '',
//       duration: json['duration'] ?? '',
//       arrivalEstimate: json['arrival_estimate'] ?? '',
//     );
//   }
// }
