// ///////////////////////////////////////map with default straight line,api data etc....
// import 'package:flutter/material.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:trackingapp/utilities/MyString.dart';

// class JourneyMapPage extends StatefulWidget {
//   final LatLng start;
//   final LatLng end;
//   final List<dynamic>? route; // travelled path if provided

//   const JourneyMapPage({
//     super.key,
//     required this.start,
//     required this.end,
//     this.route,
//   });

//   @override
//   State<JourneyMapPage> createState() => _JourneyMapPageState();
// }

// class _JourneyMapPageState extends State<JourneyMapPage> {
//   Set<Marker> markers = {};
//   Set<Polyline> polylines = {};
//   final PolylinePoints polylinePoints = PolylinePoints();
//   GoogleMapController? _mapController;

//   @override
//   void initState() {
//     super.initState();
//     _setMarkers();

//     // If actual travelled route exists → show it
//     if (widget.route != null && widget.route!.isNotEmpty) {
//       _setActualPath(widget.route!);
//     } else {
//       // Otherwise fallback to Google Directions API
//       _getRouteFromAPI();
//     }
//   }

//   /// Add Start & End markers
//   void _setMarkers() {
//     markers = {
//       Marker(
//         markerId: const MarkerId("start"),
//         position: widget.start,
//         infoWindow: const InfoWindow(title: "Start"),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//       ),
//       Marker(
//         markerId: const MarkerId("end"),
//         position: widget.end,
//         infoWindow: const InfoWindow(title: "End"),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//       ),
//     };
//   }

//   /// Draw the actual travelled path from Firestore
//   void _setActualPath(List<dynamic> rawCoords) {
//     final routeCoords = rawCoords.map((e) {
//       final lat = (e['lat'] as num).toDouble();
//       final lng = (e['lng'] as num).toDouble();
//       return LatLng(lat, lng);
//     }).toList();

//     setState(() {
//       polylines = {
//         Polyline(
//           polylineId: const PolylineId("actual_route"),
//           points: routeCoords,
//           color: Colors.blue,
//           width: 5,
//         ),
//       };
//     });

//     _fitBounds(routeCoords);
//   }

//   /// If no actual route stored, fetch one from Google Directions API
//   Future<void> _getRouteFromAPI() async {
//     try {
//       PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//         request: PolylineRequest(
//           origin: PointLatLng(widget.start.latitude, widget.start.longitude),
//           destination: PointLatLng(widget.end.latitude, widget.end.longitude),
//           mode: TravelMode.driving,
//         ),
//         googleApiKey: "YOUR_GOOGLE_API_KEY_HERE", // replace with your real key
//       );

//       if (result.points.isNotEmpty) {
//         List<LatLng> routeCoords = result.points
//             .map((point) => LatLng(point.latitude, point.longitude))
//             .toList();

//         setState(() {
//           polylines = {
//             Polyline(
//               polylineId: const PolylineId("api_route"),
//               points: routeCoords,
//               color: Colors.blue,
//               width: 5,
//             ),
//           };
//         });

//         _fitBounds(routeCoords);
//       } else {
//         _drawFallbackLine();
//       }
//     } catch (e) {
//       _drawFallbackLine();
//     }
//   }

//   /// Fallback: just connect start → end with a straight line
//   void _drawFallbackLine() {
//     final coords = [widget.start, widget.end];
//     setState(() {
//       polylines = {
//         Polyline(
//           polylineId: const PolylineId("fallback_route"),
//           points: coords,
//           color: Colors.red,
//           width: 4,
//         ),
//       };
//     });
//     _fitBounds(coords);
//   }

//   /// Adjust the camera to fit the route
//   void _fitBounds(List<LatLng> coords) {
//     if (_mapController == null || coords.isEmpty) return;

//     double minLat = coords.first.latitude;
//     double maxLat = coords.first.latitude;
//     double minLng = coords.first.longitude;
//     double maxLng = coords.first.longitude;

//     for (LatLng coord in coords) {
//       if (coord.latitude < minLat) minLat = coord.latitude;
//       if (coord.latitude > maxLat) maxLat = coord.latitude;
//       if (coord.longitude < minLng) minLng = coord.longitude;
//       if (coord.longitude > maxLng) maxLng = coord.longitude;
//     }

//     LatLngBounds bounds = LatLngBounds(
//       southwest: LatLng(minLat, minLng),
//       northeast: LatLng(maxLat, maxLng),
//     );

//     _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         centerTitle: true,
//         title: const Text(
//           "Journey Map",
//           style: TextStyle(color: Colors.white, fontFamily: MyString.poppins),
//         ),
//         backgroundColor: const Color(0xff0D0D3C),
//       ),
//       body: GoogleMap(
//         initialCameraPosition: CameraPosition(
//           target: widget.start,
//           zoom: 12,
//         ),
//         onMapCreated: (controller) {
//           _mapController = controller;
//         },
//         markers: markers,
//         polylines: polylines,
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class JourneyMapPage extends StatefulWidget {
  final LatLng start;
  final LatLng end;
  final List<dynamic>? route; // 🔹 Route points fetched from Firestore

  const JourneyMapPage({
    super.key,
    required this.start,
    required this.end,
    this.route,
  });

  @override
  State<JourneyMapPage> createState() => _JourneyMapPageState();
}

class _JourneyMapPageState extends State<JourneyMapPage> {
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setMarkers();
    _setRouteFromFirestore(); // 🔹 Directly show stored route
  }

  void _setMarkers() {
    _markers.add(Marker(
      markerId: const MarkerId("start"),
      position: widget.start,
      infoWindow: const InfoWindow(title: "Start"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));

    _markers.add(Marker(
      markerId: const MarkerId("end"),
      position: widget.end,
      infoWindow: const InfoWindow(title: "End"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));
  }

  void _setRouteFromFirestore() {
    if (widget.route == null || widget.route!.isEmpty) return;

    List<LatLng> polylineCoordinates = [];

    for (var point in widget.route!) {
      polylineCoordinates.add(
        LatLng(point['lat'] as double, point['lng'] as double),
      );
    }

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("travelled_route"),
          color: Colors.blue,
          width: 5,
          points: polylineCoordinates,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Journey Route")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.start,
          zoom: 14,
        ),
        polylines: _polylines,
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
