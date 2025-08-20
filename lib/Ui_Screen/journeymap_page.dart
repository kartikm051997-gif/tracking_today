import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utilities/MyString.dart';

class JourneyMapScreen extends StatelessWidget {
  final LatLng start;
  final LatLng end;
  final List<LatLng> route;

  const JourneyMapScreen({
    super.key,
    required this.start,
    required this.end,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId("start"),
        position: start,
        infoWindow: const InfoWindow(title: "Start"),
      ),
      Marker(
        markerId: const MarkerId("end"),
        position: end,
        infoWindow: const InfoWindow(title: "End"),
      ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId("route"),
        points: route.isNotEmpty ? route : [start, end], // ✅ show full journey
        color: Colors.blue,
        width: 5,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Journey Map",
          style: TextStyle(color: Colors.white, fontFamily: MyString.poppins),
        ),
        backgroundColor: const Color(0xff0D0D3C),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target:
              route.isNotEmpty
                  ? route[route.length ~/ 2] // center on middle of path
                  : LatLng(
                    (start.latitude + end.latitude) / 2,
                    (start.longitude + end.longitude) / 2,
                  ),
          zoom: 12,
        ),
        markers: markers,
        polylines: polylines,
      ),
    );
  }
}
