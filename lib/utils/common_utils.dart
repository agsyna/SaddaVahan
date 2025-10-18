import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';

class CUtils {
  CUtils._();

  static void toastMessage(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.purple,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }


  static Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  static getResponse({required url}) async {
    Response resp = await get(Uri.parse(url));
    return jsonDecode(resp.body);
  }

  static Future<String> getHumanReadableAddress({
    required BuildContext context,
    required LatLng pos,
  }) async {
    String address = "error";
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${pos.latitude},${pos.longitude}&location_type=ROOFTOP&result_type=street_address&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}";
    try {
      var resp = await getResponse(url: url);
      address = resp["results"][0]["formatted_address"];
      // CUtils.toastMessage(address);
      return address;
    } catch (e) {
      //  there was error while getting the response;
      // CUtils.toastMessage(e.toString());
      // print("error: $e");
      List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      address =
          "Unnamed Road,${placemarks.last.name}, ${placemarks.last.locality}, ${placemarks.last.administrativeArea}, ${placemarks.last.country}";
      // address = "${pos.latitude}, ${pos.longitude}";
    }
    return address;
  }

  static bool allDigits(String str) {
    String pattern = r'^\d+$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(str);
  }





  static showDialogBox(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            Container(
              margin: const EdgeInsets.only(left: 12),
              child: const Text("Loading..."),
            ),
          ],
        ),
      ),
    );
  }
}