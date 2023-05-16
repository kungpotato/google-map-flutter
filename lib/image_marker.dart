import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ImageData {
  final SendPort sendPort;
  final String imageUrl;
  ImageData(this.sendPort, this.imageUrl);
}

loadImage(ImageData imageData) async {
  final response = await http.get(Uri.parse(imageData.imageUrl));
  imageData.sendPort.send(response.bodyBytes);
}

Future<Uint8List> getNetworkImageMarker(
    String imageUrl, double diameter, Color circleColor) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(loadImage, ImageData(receivePort.sendPort, imageUrl));
  final response = await receivePort.first as Uint8List;

  final codec = await ui.instantiateImageCodec(response);
  final frame = await codec.getNextFrame();
  final image = frame.image;

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
