import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'image_marker.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = <Marker>{};
  String imageUrl = 'https://storage-wp.thaipost.net/2022/10/289885331_1392441634600010_443505897198829281_n.jpg';

  @override
  void initState() {
    super.initState();
    _createCustomImageMarker();
  }

  Future<void> _createCustomImageMarker() async {
    final markerIcon = await getNetworkImageMarker(imageUrl, 200, Colors.blue);
    final marker = Marker(
      markerId: const MarkerId('custom_marker'),
      position: const LatLng(40.7128, -74.0060), // New York City coordinates
      icon: BitmapDescriptor.fromBytes(markerIcon),
    );
    setState(() {
      _markers.add(marker);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(40.7128, -74.0060),
          zoom: 14,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}
