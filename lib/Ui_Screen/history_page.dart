import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../utilities/MyString.dart';
import 'journeymap_page.dart';

class HistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const HistoryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Journey History",
          style: TextStyle(color: Colors.white, fontFamily: MyString.poppins),
        ),
        backgroundColor: const Color(0xff0D0D3C),
      ),
      body:
          history.isEmpty
              ? const Center(
                child: Text(
                  "No journeys yet",
                  style: TextStyle(fontFamily: MyString.poppins),
                ),
              )
              : ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[history.length - 1 - index];

                  final dateTime = DateTime.parse(item['date']);
                  final formattedDate = DateFormat(
                    'dd MMM yyyy, hh:mm a',
                  ).format(dateTime);

                  double distance = item['distance'];
                  String distanceText;
                  if (distance < 1) {
                    // less than 1 km → show in meters
                    distanceText = "${(distance * 1000).toStringAsFixed(0)} m";
                  } else {
                    distanceText = "${distance.toStringAsFixed(1)} km";
                  }

                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.directions),
                        title: Text(
                          "${item['start']['address']} → ${item['end']['address']}",
                          style: TextStyle(
                            fontFamily: MyString.poppins,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "Distance: $distanceText\nDate: $formattedDate",
                          style: TextStyle(fontFamily: MyString.poppins),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => JourneyMapScreen(
                                    start: LatLng(
                                      item['start']['lat'],
                                      item['start']['lng'],
                                    ),
                                    end: LatLng(
                                      item['end']['lat'],
                                      item['end']['lng'],
                                    ),
                                    route:
                                        (item['route'] as List)
                                            .map(
                                              (p) => LatLng(p['lat'], p['lng']),
                                            )
                                            .toList(), // ✅ send route
                                  ),
                            ),
                          );
                        },
                      ),
                      Divider(
                        color: Colors.grey.shade400,
                        thickness: 1,
                        indent: 15,
                        endIndent: 15,
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
