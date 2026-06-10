import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


// used the create the custom marker for each responder on the map
Future<BitmapDescriptor> buildIndexMarker(int index,String serviceType) async {
  final assetPath = switch (serviceType) {
    'Ambulance' => 'assets/markers/amb_marker.png',
    'Fire Brigade' => 'assets/markers/fb_marker.png',
    'Police' => 'assets/markers/p_marker.png',
    _ => 'assets/markers/amb_marker.png',
  };

  // 2. Load the PNG as a ui.Image
  final ByteData assetData = await rootBundle.load(assetPath);
  final ui.Codec codec = await ui.instantiateImageCodec(
    assetData.buffer.asUint8List(),
    targetWidth: 60,
    targetHeight: 80,
  );
  final ui.Image vehicleImage = (await codec.getNextFrame()).image;

  // Dimensions
  const double imgWidth = 60;
  const double imgHeight = 80;
  const double boxWidth = 44;
  const double boxHeight = 26;
  const double triangleH = 6;
  const double totalWidth = imgWidth;
  const double totalHeight = boxHeight + triangleH + imgHeight;

  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);

  // 3. Draw the vehicle PNG at the bottom
  paintImage(
    canvas: canvas,
    rect: const Rect.fromLTWH(0, boxHeight + triangleH, imgWidth, imgHeight),
    image: vehicleImage,
    fit: BoxFit.contain,
  );

  // 4. Draw the label box centered above the image
  final double boxLeft = (totalWidth - boxWidth) / 2;
  final boxPaint = Paint()..color = const Color(0xFF1A1C24);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(boxLeft, 0, boxWidth, boxHeight),
      const Radius.circular(6),
    ),
    boxPaint,
  );

  // 5. Draw the triangle connecting box to image
  final triPaint = Paint()..color = const Color(0xFF1A1C24);
  final triPath = Path()
    ..moveTo(totalWidth / 2 - 5, boxHeight)
    ..lineTo(totalWidth / 2 + 5, boxHeight)
    ..lineTo(totalWidth / 2, boxHeight + triangleH)
    ..close();
  canvas.drawPath(triPath, triPaint);

  // 6. Draw the index number inside the box
  final textPainter = TextPainter(
    text: TextSpan(
      text: '$index',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      boxLeft + (boxWidth - textPainter.width) / 2,
      (boxHeight - textPainter.height) / 2,
    ),
  );

  // 7. Convert to BitmapDescriptor
  final picture = pictureRecorder.endRecording();
  final image = await picture.toImage(totalWidth.toInt(), totalHeight.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
}


void fitRouteBounds(LatLng p1, LatLng p2, GoogleMapController? mapController) {
  LatLngBounds bounds;
  if (p1.latitude > p2.latitude) {
    bounds = LatLngBounds(
      southwest: LatLng(
        p2.latitude,
        p1.longitude < p2.longitude ? p1.longitude : p2.longitude,
      ),
      northeast: LatLng(
        p1.latitude,
        p1.longitude > p2.longitude ? p1.longitude : p2.longitude,
      ),
    );
  } else {
    bounds = LatLngBounds(
      southwest: LatLng(
        p1.latitude,
        p1.longitude < p2.longitude ? p1.longitude : p2.longitude,
      ),
      northeast: LatLng(
        p2.latitude,
        p1.longitude > p2.longitude ? p1.longitude : p2.longitude,
      ),
    );
  }

  // Animates map view with a clean 80px boundary padding
  mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
}
