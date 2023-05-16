import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const MyHomePage(title: 'Flutter Example App'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = <Marker>{};
  String imageUrl = 'https://storage-wp.thaipost.net/2022/10/289885331_1392441634600010_443505897198829281_n.jpg';

  Future<void> _createCustomImageMarker() async {
    final Uint8List markerIcon =
    await getNetworkImageMarker(imageUrl, 200, Colors.blue);
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
  void initState() {
    super.initState();
    _createCustomImageMarker();
  }

  Future<Uint8List> getNetworkImageMarker(
      String imageUrl, double diameter, Color circleColor) async {
    final Completer<ui.Image> completer = Completer();

    // Load the network image
    CachedNetworkImageProvider(imageUrl)
        .resolve(const ImageConfiguration())
        .addListener(
      ImageStreamListener(
            (ImageInfo info, bool _) {
          completer.complete(info.image);
        },
      ),
    );

    // Await the image loading
    final ui.Image image = await completer.future;

    // Create a PictureRecorder
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);

    // Draw the circle
    final circlePaint = Paint()..color = circleColor;
    canvas.drawCircle(
        Offset(diameter / 2, diameter / 2), diameter / 2, circlePaint);

    // Clip the image to a circle
    final imageSize = diameter * 0.85;
    final src = Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(
      (diameter - imageSize) / 2,
      (diameter - imageSize) / 2,
      imageSize,
      imageSize,
    );

    final clipPath = Path()..addOval(dst);
    canvas.clipPath(clipPath);

    // Draw the image
    canvas.drawImageRect(image, src, dst, Paint());

    // Get the recorded picture as bytes
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(diameter.toInt(), diameter.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
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

