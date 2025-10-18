import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:saadibus/models/busDetail.dart';
import 'package:saadibus/models/detailedBusDetail.dart';

class IndividualBusCard extends StatelessWidget {
  final IndividualBusDetail busDetail;
  final String arrivingInText;
  final String estimatedTimeText;

  const IndividualBusCard({super.key, required this.busDetail, required this.arrivingInText, required this.estimatedTimeText});




  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        
  final url = Uri.parse("https://tstkypmfvfvzstcovbdj.supabase.co/functions/v1/bright-function");

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({"bus_id": busDetail.busId}),
    );

   if (response.statusCode == 200) {
  final data = jsonDecode(response.body);

  // create model from response
  final detailedBus = DetailedBusDetail.fromJson(data);

  // pass model to next screen
  context.push('/detailedBus', extra: detailedBus);
}
else {
      print("Error: ${response.statusCode} - ${response.body}");
      return null;
    }
  } catch (e) {
    print("Exception: $e");
    return null;
  }

      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 0.5,
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          busDetail.busNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.cyan,
                          size: 16,
                        ),
                        Text(
                          "$arrivingInText${busDetail.arrivalEstimate}",
                          style: TextStyle(color: Colors.cyan, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 45,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 25,
                            color: Colors.grey.shade300,
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  busDetail.pickupPoint.length > 30
                                      ? "${busDetail.pickupPoint.substring(0, 30)}..."
                                      : busDetail.pickupPoint,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                busDetail.farAwayFromPickup.length > 10
                                    ? "${busDetail.farAwayFromPickup.substring(0, 10)}..."
                                    : busDetail.farAwayFromPickup,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      busDetail.dropPoint,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "$estimatedTimeText ${busDetail.duration}",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                busDetail.farAwayFromDrop,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
    );
  }
}
