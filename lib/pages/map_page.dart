import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:maps/const.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _location = new Location();

  static const LatLng _pGooglePlex = LatLng(37.7749, -122.4194);
  static const LatLng _pApplePark = LatLng(37.3346, -122.0090);
  LatLng? _currentLocation = null;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  Map<PolylineId, Polyline> _polyLines = {};

  @override
  void initState() {
    super.initState();
    _getLocationUpdates().then((value) {
      getPolyline().then((cordinates) {
        print(cordinates);
        generatePoluLineFromPoints(cordinates);
        // setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Page'),
      ),
      body: _currentLocation == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) =>
                  _controllerGoogleMap.complete(controller),
              initialCameraPosition: const CameraPosition(
                target: _pGooglePlex,
                zoom: 13,
              ),
              markers: {
                const Marker(
                  markerId: MarkerId('_currentLocation'),
                  icon: BitmapDescriptor.defaultMarker,
                ),
                const Marker(
                  markerId: MarkerId('_sourceLocation'),
                  position: _pGooglePlex,
                  icon: BitmapDescriptor.defaultMarker,
                ),
                const Marker(
                  markerId: MarkerId('_destinationLocation'),
                  position: _pApplePark,
                  icon: BitmapDescriptor.defaultMarker,
                )
              },
              polylines: Set<Polyline>.of(_polyLines.values),
            ),
    );
  }

  Future<void> _moveCamera(LatLng pos) async {
    final GoogleMapController controller = await _controllerGoogleMap.future;
    CameraPosition cameraPosition = CameraPosition(target: pos, zoom: 15);
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  Future<void> _getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus permissionGranted;
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
    } else {
      return;
    }
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
    }
    if (permissionGranted == PermissionStatus.granted) {
      return;
    }
    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude == null ||
          currentLocation.longitude == null) {
        setState(() {
          _currentLocation =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        _moveCamera(_currentLocation!);
      }
    });
  }

  Future<List<LatLng>> getPolyline() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineRequest request = PolylineRequest(
      origin: PointLatLng(_pGooglePlex.latitude, _pGooglePlex.longitude),
      destination: PointLatLng(_pApplePark.latitude, _pApplePark.longitude),
      mode: TravelMode.driving,
    );
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
      googleApiKey: Google_MAPS_API_key,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    return polylineCoordinates;
  }

  void generatePoluLineFromPoints(List<LatLng> polylineCoordinates) {
    final PolylineId id = PolylineId('poly');
    final Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 8,
    );
    setState(() {
      _polyLines[id] = polyline;
    });
  }
}
