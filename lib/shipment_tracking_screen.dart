import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;

class ShipmentTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> shipment;
  const ShipmentTrackingScreen({super.key, required this.shipment});

  @override
  State<ShipmentTrackingScreen> createState() => _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState extends State<ShipmentTrackingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final Location _locationController = Location();

  StreamSubscription<LocationData>? _locationSubscription;
  RealtimeChannel? _realtimeChannel;

  final Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isCurrentUserTheDriver = false;
  Uint8List? _truckIconBytes;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadCustomMarker();
    await _determineUserRole();
    _setupInitialMarkers();

    _realtimeChannel = Supabase.instance.client.channel(
      'shipment_${widget.shipment['id']}',
    );

    await _realtimeChannel!.subscribe();

    if (_isCurrentUserTheDriver) {
      _startBroadcastingLocation();
    } else {
      _startListeningToLocation();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadCustomMarker() async {
    _truckIconBytes = await _getBytesFromAsset(
      'assets/images/truck_marker.png',
      100,
    );
  }

  Future<void> _determineUserRole() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      final offerResponse = await Supabase.instance.client
          .from('offers')
          .select('driver_id')
          .eq('shipment_id', widget.shipment['id'])
          .eq('status', 'accepted')
          .maybeSingle();

      if (mounted && offerResponse != null) {
        final driverId = offerResponse['driver_id'];
        setState(() {
          _isCurrentUserTheDriver = currentUserId == driverId;
        });
      }
    } catch (e) {
      // يمكنك هنا طباعة الخطأ إن أردت
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  void _setupInitialMarkers() {
    final destLat = widget.shipment['destination_lat'];
    final destLng = widget.shipment['destination_lng'];
    if (destLat != null && destLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destinationMarker'),
          position: LatLng(destLat, destLng),
          infoWindow: const InfoWindow(title: 'وجهة التوصيل'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  Future<void> _startBroadcastingLocation() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _locationController
        .hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    await _locationController.changeSettings(
      interval: 5000,
      distanceFilter: 10,
    );

    _locationSubscription = _locationController.onLocationChanged.listen((
      currentLocation,
    ) async {
      final lat = currentLocation.latitude;
      final lng = currentLocation.longitude;
      if (lat == null || lng == null) return;

      await _realtimeChannel?.sendBroadcastMessage(
        event: 'driver_location',
        payload: {'lat': lat, 'lng': lng},
      );

      _updateMarkerPosition(LatLng(lat, lng));
    });
  }

  void _startListeningToLocation() {
    _realtimeChannel?.onBroadcast(
      event: 'driver_location',
      callback: (payload, [ref]) {
        final lat = payload['lat'];
        final lng = payload['lng'];
        if (lat != null && lng != null && mounted) {
          final newPosition = LatLng(lat, lng);
          _updateMarkerPosition(newPosition);
        }
      },
    );
  }

  void _updateMarkerPosition(LatLng newPosition) {
    if (!mounted || _truckIconBytes == null) return;

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driverMarker');
      _markers.add(
        Marker(
          markerId: const MarkerId('driverMarker'),
          position: newPosition,
          icon: BitmapDescriptor.fromBytes(_truckIconBytes!),
          infoWindow: const InfoWindow(title: 'موقع السائق الحالي'),
        ),
      );
    });

    _mapController.future.then((controller) {
      controller.animateCamera(CameraUpdate.newLatLng(newPosition));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('جاري التحميل...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final initialCameraPosition = LatLng(
      widget.shipment['destination_lat'] ?? 33.3152,
      widget.shipment['destination_lng'] ?? 44.3661,
    );

    return Scaffold(
      appBar: AppBar(title: Text('تتبع الشحنة: ${widget.shipment['title']}')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialCameraPosition,
          zoom: 12,
        ),
        onMapCreated: (GoogleMapController controller) {
          if (!_mapController.isCompleted) {
            _mapController.complete(controller);
          }
        },
        markers: _markers,
      ),
    );
  }
}

Future<Uint8List> _getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: width,
  );
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
}
