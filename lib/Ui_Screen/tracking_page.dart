import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utilities/MyString.dart';
import 'history_page.dart';
import 'login_page.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  String _userName = "";
  GoogleMapController? _mapController;
  bool _isJourneyActive = false;
  LatLng? _startLatLng;
  LatLng? _lastLatLng;
  double _journeyDistanceKm = 0;
  bool _isSelected = false;

  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final List<LatLng> _routeCoords = [];

  List<Map<String, dynamic>> _journeyHistory = [];
  StreamSubscription<Position>? _posSub;

  // ---------- Lifecycle ----------
  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadHistory();
    _checkPermission().then((_) => _restoreActiveJourney());
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString("userName") ?? "";
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("journeyHistory");
    if (jsonStr != null) {
      final decoded =
          (jsonDecode(jsonStr) as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
      setState(() => _journeyHistory = decoded);
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("journeyHistory", jsonEncode(_journeyHistory));
  }

  Future<void> _persistActiveJourney() async {
    final prefs = await SharedPreferences.getInstance();
    final active = {
      "isActive": _isJourneyActive,
      "start":
          _startLatLng == null
              ? null
              : {"lat": _startLatLng!.latitude, "lng": _startLatLng!.longitude},
      "last":
          _lastLatLng == null
              ? null
              : {"lat": _lastLatLng!.latitude, "lng": _lastLatLng!.longitude},
      "distanceKm": _journeyDistanceKm,
      "route":
          _routeCoords
              .map((e) => {"lat": e.latitude, "lng": e.longitude})
              .toList(),
      "startedAt": DateTime.now().toIso8601String(),
    };
    await prefs.setString("activeJourney", jsonEncode(active));
  }

  Future<void> _clearActiveJourneyPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("activeJourney");
  }

  Future<void> _restoreActiveJourney() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString("activeJourney");
    if (jsonStr == null) return;

    final data = Map<String, dynamic>.from(jsonDecode(jsonStr));
    final isActive = data["isActive"] == true;
    if (!isActive) return;

    final start = data["start"];
    final last = data["last"];
    final route = data["route"] as List?;

    setState(() {
      _isJourneyActive = true;
      if (start != null) {
        _startLatLng = LatLng(start["lat"], start["lng"]);
      }
      if (last != null) {
        _lastLatLng = LatLng(last["lat"], last["lng"]);
      }
      _journeyDistanceKm = (data["distanceKm"] ?? 0).toDouble();
      _routeCoords
        ..clear()
        ..addAll(
          (route ?? []).map(
            (p) => LatLng(p["lat"] as double, p["lng"] as double),
          ),
        );

      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: _routeCoords,
            color: Colors.blue,
            width: 5,
          ),
        );

      _markers.clear();
      if (_startLatLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId("start"),
            position: _startLatLng!,
            infoWindow: const InfoWindow(title: "Start"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
      if (_lastLatLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId("last"),
            position: _lastLatLng!,
            infoWindow: const InfoWindow(title: "Current"),
          ),
        );
      }
    });

    _listenToPositions();
  }

  Future<void> _checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _logout() async {
    await _posSub?.cancel();
    _posSub = null;

    final prefs = await SharedPreferences.getInstance();

    final historyJson = prefs.getString("journeyHistory"); // backup
    await prefs.clear();
    if (historyJson != null) {
      await prefs.setString("journeyHistory", historyJson); // restore
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _startJourney() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      await _posSub?.cancel();

      setState(() {
        _isJourneyActive = true;
        _startLatLng = LatLng(pos.latitude, pos.longitude);
        _lastLatLng = _startLatLng;
        _journeyDistanceKm = 0;
        _routeCoords
          ..clear()
          ..add(_startLatLng!);
        _markers
          ..clear()
          ..add(
            Marker(
              markerId: const MarkerId("start"),
              position: _startLatLng!,
              infoWindow: const InfoWindow(title: "Start"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );
        _polylines
          ..clear()
          ..add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: _routeCoords,
              color: Colors.blue,
              width: 5,
            ),
          );
      });

      await _persistActiveJourney();
      _listenToPositions();

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_startLatLng!));
      }
    } catch (e) {
      debugPrint("StartJourney error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to start journey.")),
        );
      }
    }
  }

  void _listenToPositions() {
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // every 5 meters
      ),
    ).listen((pos) async {
      if (!_isJourneyActive || _lastLatLng == null) return;

      final newPoint = LatLng(pos.latitude, pos.longitude);
      final stepMeters = Geolocator.distanceBetween(
        _lastLatLng!.latitude,
        _lastLatLng!.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );

      if (stepMeters < 2) return;

      _journeyDistanceKm += stepMeters / 1000.0;
      _lastLatLng = newPoint;
      _routeCoords.add(newPoint);

      setState(() {
        _polylines
          ..clear()
          ..add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: _routeCoords,
              color: Colors.blue,
              width: 5,
            ),
          );
        _markers.removeWhere((m) => m.markerId.value == "last");
        _markers.add(
          Marker(
            markerId: const MarkerId("last"),
            position: newPoint,
            infoWindow: const InfoWindow(title: "Current"),
          ),
        );
      });

      await _persistActiveJourney();

      _mapController?.animateCamera(CameraUpdate.newLatLng(newPoint));
    });
  }

  Future<void> _endJourney() async {
    if (!_isJourneyActive || _startLatLng == null || _lastLatLng == null) {
      return;
    }

    await _posSub?.cancel();
    final endLatLng = _lastLatLng!;
    setState(() => _isJourneyActive = false);

    _markers.add(
      Marker(
        markerId: const MarkerId("end"),
        position: endLatLng,
        infoWindow: const InfoWindow(title: "End"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Resolve start/end into human-readable names (best-effort)
    final startAddress = await _getAddress(
      _startLatLng!.latitude,
      _startLatLng!.longitude,
    );
    final endAddress = await _getAddress(
      endLatLng.latitude,
      endLatLng.longitude,
    );

    // Save history (recent first style is in UI; here we append)
    _journeyHistory.add({
      "start": {
        "lat": _startLatLng!.latitude,
        "lng": _startLatLng!.longitude,
        "address": startAddress,
      },
      "end": {
        "lat": endLatLng.latitude,
        "lng": endLatLng.longitude,
        "address": endAddress,
      },
      "distance": _journeyDistanceKm,
      "date": DateTime.now().toIso8601String(),
      "route":
          _routeCoords
              .map((e) => {"lat": e.latitude, "lng": e.longitude})
              .toList(),
    });

    await _saveHistory();

    // Clear active persisted
    await _clearActiveJourneyPersisted();

    // Reset in-memory
    setState(() {
      _startLatLng = null;
      _lastLatLng = null;
      _journeyDistanceKm = 0;
      _routeCoords.clear();
      _polylines.clear();
      _markers.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Journey saved to history.")),
      );
    }
  }

  Future<String> _getAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final street = (p.street?.isNotEmpty ?? false) ? p.street : null;
        final subLocality =
            (p.subLocality?.isNotEmpty ?? false) ? p.subLocality : null;
        final locality = (p.locality?.isNotEmpty ?? false) ? p.locality : null;
        final admin =
            (p.administrativeArea?.isNotEmpty ?? false)
                ? p.administrativeArea
                : null;
        final country = (p.country?.isNotEmpty ?? false) ? p.country : null;

        final parts =
            [
              street,
              subLocality,
              locality,
              admin,
              country,
            ].whereType<String>().toList();

        if (parts.isNotEmpty) return parts.join(", ");
      }
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
    return "$lat, $lng";
  }

  String _formatDistance(double km) {
    if (km < 1) return "${(km * 1000).toStringAsFixed(0)} m";
    return "${km.toStringAsFixed(1)} km";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xff0D0D3C)),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    _userName.isNotEmpty ? "Hello, $_userName" : "Menu",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: MyString.poppins,
                    ),
                  ),
                ),
              ),

              // History ListTile
              InkWell(
                onTap: () {
                  setState(() {
                    _isSelected = true; // ✅ mark selected
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(history: _journeyHistory),
                    ),
                  ).then((_) {
                    // reset when coming back
                    setState(() {
                      _isSelected = false;
                    });
                  });
                },
                child: Container(
                  color:
                      _isSelected
                          ? Colors.blueGrey
                          : Colors.transparent, // ✅ change bg
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.black87),
                      const SizedBox(width: 12),
                      Text(
                        "History",
                        style: TextStyle(
                          fontFamily: MyString.poppins,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(), // 👈 pushes logout button to bottom
              // Logout Button inside Container at bottom
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffA2D65F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Logout",
                      style: TextStyle(
                        fontFamily: MyString.poppins,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff0D0D3C),
        title: Text(
          "Welcome, $_userName",
          style: const TextStyle(
            fontFamily: MyString.poppins,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear active",
            onPressed: () async {
              await _posSub?.cancel();
              await _clearActiveJourneyPersisted();
              setState(() {
                _isJourneyActive = false;
                _startLatLng = null;
                _lastLatLng = null;
                _journeyDistanceKm = 0;
                _routeCoords.clear();
                _polylines.clear();
                _markers.clear();
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cleared active journey.")),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(20, 78),
                zoom: 5,
              ),
              polylines: _polylines,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isJourneyActive
                          ? "Journey Distance: ${_formatDistance(_journeyDistanceKm)}"
                          : "Press Start Journey",
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: MyString.poppins,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xffA2D65F),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 50,
                        ), // button height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // rounded corners
                        ),
                      ),
                      onPressed: _isJourneyActive ? null : _startJourney,
                      child: const Text(
                        "Start Journey",
                        style: TextStyle(fontFamily: MyString.poppins),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xffA2D65F),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 50,
                        ), // button height
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // rounded corners
                        ),
                      ),
                      onPressed: _isJourneyActive ? _endJourney : null,
                      child: const Text(
                        "End Journey",
                        style: TextStyle(fontFamily: MyString.poppins),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isJourneyActive && _startLatLng != null)
                      Text(
                        "Started: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}",
                        style: const TextStyle(fontFamily: MyString.poppins),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
