import 'dart:async';
import 'dart:html';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math' as math;


void main() {
  runApp(WatermarkApp());
}

class WatermarkApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web Image Watermark',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageWatermarkPage(),
    );
  }
}

class ImageWatermarkPage extends StatefulWidget {
  @override
  _ImageWatermarkPageState createState() => _ImageWatermarkPageState();
}

class _ImageWatermarkPageState extends State<ImageWatermarkPage> {
  Uint8List? _imageData;
  String _watermarkText = "Watermark";
  Uint8List? _watermarkedImageData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image Watermark")),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text("Upload Image"),
              ),
              if (_imageData != null)
                Image.memory(_imageData!),
              TextField(
                onChanged: (text) {
                  setState(() {
                    _watermarkText = text;
                  });
                },
                decoration: InputDecoration(labelText: 'Watermark Text'),
              ),
              ElevatedButton(
                onPressed: _applyWatermark,
                child: Text("Apply Watermark"),
              ),
              if (_watermarkedImageData != null)
                Image.memory(_watermarkedImageData!),
              if (_watermarkedImageData != null)
                ElevatedButton(
                  onPressed: _downloadImage,
                  child: Text("Download Image"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _uploadImage() async {
    FileUploadInputElement uploadInput = FileUploadInputElement();
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files!;
      final file = files[0];
      final reader = FileReader();

      reader.onLoadEnd.listen((e) {
        setState(() {
          _imageData = reader.result as Uint8List;
        });
      });

      reader.readAsArrayBuffer(file);
    });
  }

  _applyWatermark() async {
    final Completer<Uint8List> completer = Completer();

    // Convert Uint8List to Image
    final codec = await ui.instantiateImageCodec(_imageData!);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(image.width.toDouble(), image.height.toDouble())));

    // Draw the original image onto the canvas
    canvas.drawImage(image, Offset.zero, Paint());

    // Define a TextStyle for the watermark text
    final style = ui.TextStyle(
      color: Colors.white.withOpacity(0.7),
      fontSize: 50.0,
      background: Paint()..color = Colors.black.withOpacity(0.5),
    );
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle())
      ..pushStyle(style)
      ..addText(_watermarkText);
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: image.width.toDouble()));

    // List of positions for the watermark
    final List<Offset> positions = [
      Offset(0, image.height.toDouble() * 0.75),   // Near bottom-left
      Offset(0, image.height.toDouble() * 0.25),   // Near top-left
      Offset(image.width.toDouble() * 0.5, image.height.toDouble()),   // Near bottom-right
      Offset(image.width.toDouble() * 0.5, 0),     // Near top-right
    ];

    for (var position in positions) {
      // Save the current state of the canvas
      canvas.save();

      // Rotate and translate the canvas for diagonal watermark
      canvas.translate(position.dx, position.dy);
      canvas.rotate(-45 * (math.pi / 180));

      // Draw the watermark text on the canvas
      canvas.drawParagraph(paragraph, Offset(0, -25));  // Adjust the vertical offset as needed

      // Restore the canvas state to its original
      canvas.restore();
    }

    // Convert the canvas drawing (Picture) back to Uint8List
    final picture = recorder.endRecording();
    final img = await picture.toImage(image.width, image.height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    setState(() {
      _watermarkedImageData = pngBytes;
    });
  }


  _downloadImage() {
    final blob = Blob([_watermarkedImageData]);
    final url = Url.createObjectUrlFromBlob(blob);
    final anchor = AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'download.png'
      ..click();
  }
}
