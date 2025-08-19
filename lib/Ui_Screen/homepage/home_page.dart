import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:trackingapp/Ui_Screen/historypage/history_page.dart';
import 'package:trackingapp/Ui_Screen/login/login_page.dart';
import 'package:trackingapp/utilities/MyString.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  String _userName = "";
  GoogleMapController? _mapController;

  bool _isJourneyActive = false;
  Position? _startPosition;
  Position? _lastPosition;
  double _journeyDistance = 0;

  final Set<Polyline> _polylines = {};
  final List<LatLng> _routeCoords = [];
  final Set<Marker> _markers = {};

  List<Map<String, dynamic>> _journeyHistory = [];
  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadHistory();
    _checkPermission();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  // Future<String> getPlaceName(double lat, double lng) async {
  //   try {
  //     List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

  //     if (placemarks.isNotEmpty) {
  //       final place = placemarks.first;
  //       return "${place.name}, ${place.locality}, ${place.administrativeArea}";
  //       // You can customize: place.street, place.subLocality, place.country etc.
  //     }
  //   } catch (e) {
  //     print("Error in geocoding: $e");
  //   }
  //   return "$lat, $lng"; // fallback
  // }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString("userName") ?? "";
    });
  }

  Future<void> _loadHistory() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final prefs = await SharedPreferences.getInstance();

    try {
      // 🔹 Fetch from Firestore (where you're actually saving data)
      final snapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("journeys")
              .get();

      if (snapshot.docs.isNotEmpty) {
        _journeyHistory =
            snapshot.docs
                .map(
                  (doc) => {
                    "id": doc.id, // keep Firestore doc ID
                    ...doc.data(),
                  },
                )
                .toList();

        // 🔹 Save to SharedPreferences for offline use
        await prefs.setString("journeyHistory", jsonEncode(_journeyHistory));
      } else {
        _journeyHistory = [];
      }
    } catch (e) {
      // 🔹 If Firestore fetch fails (offline), load from SharedPreferences
      final historyJson = prefs.getString("journeyHistory");
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson) as List;
        _journeyHistory =
            decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _journeyHistory = [];
      }
    }

    setState(() {});
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.name}, ${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return "$lat, $lng"; // fallback
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("journeyHistory", jsonEncode(_journeyHistory));
  }

  Future<void> _logout() async {
    // Stop any active location tracking
    await _posSub?.cancel();
    _posSub = null;

    // Clear all saved data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    // Navigate to login and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()), // Login Page
      (route) => false,
    );
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
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
    }
  }

  void _startJourney() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    // Cancel any previous stream before starting a new one
    await _posSub?.cancel();

    setState(() {
      _isJourneyActive = true;
      _startPosition = position;
      _lastPosition = position;
      _journeyDistance = 0;
      _routeCoords.clear();
      _markers.clear();
      _polylines.clear();

      _routeCoords.add(LatLng(position.latitude, position.longitude));
      _markers.add(
        Marker(
          markerId: const MarkerId("start"),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: "Start"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    });

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!_isJourneyActive || _lastPosition == null) return;

      final stepMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      _journeyDistance += stepMeters / 1000.0;
      _lastPosition = pos;
      _routeCoords.add(LatLng(pos.latitude, pos.longitude));

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
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
      );
    });
  }

  void _endJourney() async {
    if (!_isJourneyActive || _startPosition == null || _lastPosition == null) {
      return;
    }

    await _posSub?.cancel();
    final endPosition = _lastPosition!;
    _isJourneyActive = false;

    _markers.add(
      Marker(
        markerId: const MarkerId("end"),
        position: LatLng(endPosition.latitude, endPosition.longitude),
        infoWindow: const InfoWindow(title: "End"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
    final startAddress = await _getAddressFromLatLng(
      _startPosition!.latitude,
      _startPosition!.longitude,
    );
    final endAddress = await _getAddressFromLatLng(
      endPosition.latitude,
      endPosition.longitude,
    );
  

    final journeyData = {
      "start": {
        "lat": _startPosition!.latitude,
        "lng": _startPosition!.longitude,
        "address": startAddress,
      },
      "end": {
        "lat": endPosition.latitude,
        "lng": endPosition.longitude,
        "address": endAddress,
      },
      "distance": _journeyDistance,
      "date": DateTime.now().toIso8601String(),
      "route":
          _routeCoords
              .map((e) => {"lat": e.latitude, "lng": e.longitude})
              .toList(), // 👈 save full path
    };

    // Save locally
    _journeyHistory.add(journeyData);
    await _saveHistory();

    // Save to Firestore under logged-in user
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("journeys")
          .add(journeyData);
    }

    setState(() {});
  }



  @override
  Widget build(BuildContext context) {
    final User? user=FirebaseAuth.instance.currentUser;
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: const Color.fromARGB(255, 152, 253, 198),
              ),
              child: Text(
                _userName.isNotEmpty ? "Hello, $_userName" : "Menu",
                style: const TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 24,
                  fontFamily: MyString.poppins,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(
                "History",
                style: TextStyle(fontFamily: MyString.poppins),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryPage(history: _journeyHistory),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(
                "Logout",
                style: TextStyle(fontFamily: MyString.poppins),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // white drawer icon
        backgroundColor: const Color(0xff0D0D3C),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Welcome,",
              style: const TextStyle(
                fontSize: 14,
                fontFamily: MyString.poppins,
                color: Colors.white,
              ),
            ),
             Text(
              "${user?.email}",
              style: const TextStyle(
                fontSize: 14,
                fontFamily: MyString.poppins,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: (){

          }, icon: Icon( size: 30, Icons.notifications,color:const Color.fromARGB(255, 152, 253, 198),)),
           IconButton(onPressed: (){

          }, icon: Icon( size: 30, Icons.logout,color:const Color.fromARGB(255, 255, 106, 108),))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(
                  11.1271,
                  78.6569,
                ), 
                zoom: 6.2,
              ),
              polylines: _polylines,
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Journey Distance: ${_journeyDistance.toStringAsFixed(2)} km",
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: MyString.poppins,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 300,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isJourneyActive ? null : _startJourney,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 152, 253, 198),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      "Start Journey",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: MyString.poppins,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 300,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isJourneyActive ? _endJourney : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 152, 253, 198),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      "End Journey",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: MyString.poppins,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}