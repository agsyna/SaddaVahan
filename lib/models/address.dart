import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressModel {
  String readableAddress;
  double latitude, longitude;
  String? placeId;

  AddressModel({
    required this.readableAddress,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  LatLng getLatLng() {
    return LatLng(latitude, longitude);
  }
}
