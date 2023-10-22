import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:intl/intl.dart';

void main() {
  runApp(WatermarkApp());
}

class WatermarkApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marky - Image Marker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageWatermarkPage(),
      routes: {
        '/home': (context) => ImageWatermarkPage(),
      },
      initialRoute: '/home',
    );
  }
}

class ImageWatermarkPage extends StatefulWidget {
  @override
  _ImageWatermarkPageState createState() => _ImageWatermarkPageState();
}

class _ImageWatermarkPageState extends State<ImageWatermarkPage> {
  String _watermarkText = "Watermark";

  double _estrangementValue = 0.48;
  List<Uint8List?> _imageDataList = [];
  List<Uint8List?> _watermarkedImageDataList = [];
  final TextEditingController _watermarkTextController =
      TextEditingController();
  List<String> _watermarkedImageNames = [];  // This keeps track of the names of watermarked images.
  double _watermarkOpacity = 0.7;  // default opacity value


  @override
  void initState() {
    super.initState();

    // Format the current date
    String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _watermarkText = "for Business at $formattedDate";
    _watermarkTextController.text = _watermarkText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Marky")),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _uploadImages,
                child: Text("Upload Images"),
              ),
              if (_imageDataList.isNotEmpty)
                Container(
                  height: 400,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _imageDataList.length,
                    itemBuilder: (context, index) {
                      return AspectRatio(
                        aspectRatio: 1, // This will be a square container
                        child: Image.memory(
                          _imageDataList[index]!,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
              TextField(
                controller: _watermarkTextController,
                onChanged: (text) {
                  setState(() {
                    _watermarkText = text;
                  });
                },
                decoration: InputDecoration(labelText: 'Watermark Text'),
              ),

              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Text(
                  "Watermark Opacity",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),

              Slider(
                value: _watermarkOpacity,
                onChanged: (double newValue) {
                  setState(() {
                    _watermarkOpacity = newValue;
                  });
                },
                onChangeEnd: ((double newValue) {
                  setState(() {
                    _applyWatermarkToAll();
                  });
                }),
                min: 0.0,
                max: 1.0,
                divisions: 100,
                label: "Opacity: ${(_watermarkOpacity * 100).toInt()}%",
              ),

              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Text(
                  "Watermark Density",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Slider(
                value: _estrangementValue,
                onChangeEnd: ((double newValue) {
                  setState(() {
                    _applyWatermarkToAll();
                  });
                }),
                onChanged: (double newValue) {
                  setState(() {
                    _estrangementValue = newValue;
                  });
                },
                min: 0.0,
                max: 0.6,
                divisions: 60,
                label: "${_estrangementValue * 100}% density",
              ),
              GestureDetector(
                onTap: () {
                  if (_imageDataList.isEmpty ||
                      _processedImageNames.length == _imageDataList.length) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('No images left to be marked!')));
                  }
                },
                child: ElevatedButton(
                  onPressed: _imageDataList.isEmpty ||
                          _processedImageNames.length == _imageDataList.length
                      ? null
                      : _applyWatermarkToAll,
                  child: Text("Apply Watermark to All"),
                ),
              ),
              if (_watermarkedImageDataList.isNotEmpty)
                ElevatedButton(
                  onPressed: _downloadAllImages,
                  child: const Text("Download All Images"),
                ),
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio:
                      1, // This maintains the item's width and height ratio. Adjust if necessary.
                ),
                itemCount: _watermarkedImageDataList.length,
                shrinkWrap: true,
                // This will fit the GridView's height to its content
                physics: NeverScrollableScrollPhysics(),
                // Disable GridView's own scroll
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Image.memory(
                          _watermarkedImageDataList[index]!,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: IconButton(
                          icon: Icon(Icons.download_sharp, color: Colors.grey),
                          onPressed: () => _downloadSingleImage(
                              _watermarkedImageDataList[index]!, index),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  _uploadImages() async {
    FileUploadInputElement uploadInput = FileUploadInputElement()
      ..multiple = true;
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files!;
      for (var file in files) {
        final reader = FileReader();

        reader.onLoadEnd.listen((e) {
          setState(() {
            _imageDataList.add(reader.result as Uint8List?);
          });
        });

        reader.readAsArrayBuffer(file);
      }
    });
  }

  void _downloadAllImages() {
    // Create a new Zip encoder
    final encoder = ZipEncoder();

    // Create an Archive object
    final archive = Archive();

    // Add all watermarked images to the archive
    for (int i = 0; i < _watermarkedImageDataList.length; i++) {
      final data = _watermarkedImageDataList[i];
      final fileName = generateImageName();
      archive.addFile(ArchiveFile(fileName, data!.length, data));
    }

    // Encode the archive as a Uint8List
    final zipData = encoder.encode(archive);

    // Prepare a blob and anchor element for downloading
    final blob = Blob([zipData]);
    final url = Url.createObjectUrlFromBlob(blob);
    final anchor = AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'watermarked_images.zip'
      ..click();
    Url.revokeObjectUrl(url);
  }

  _downloadSingleImage(Uint8List data, int index) {
    final blob = Blob([data]);
    final url = Url.createObjectUrlFromBlob(blob);
    final fileName = generateImageName();
    // 'watermarked_image_${index + 1}.png'; // Create a unique name based on index
    final anchor = AnchorElement(href: url)
      ..target = 'blank'
      ..download = fileName
      ..click();
  }

  int _nameCounter = 0;

  String generateImageName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _nameCounter++; // Increment counter every time we generate a name
    return 'marky_$timestamp\_$_nameCounter.png';
  }



  Set<String> _processedImageNames =
      {}; // To track images we've already processed

  _applyWatermarkToAll() async {
    // Temporary lists to hold our newly processed images and their names
    List<Uint8List> newWatermarkedImageDataList = [];
    List<String> newWatermarkedImageNames = [];

    for (int i = 0; i < _imageDataList.length; i++) {
      Uint8List? imageData = _imageDataList[i];
      if (imageData != null) {
        // Convert Uint8List to Image
        final codec = await ui.instantiateImageCodec(imageData);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
            recorder,
            Rect.fromPoints(
                Offset(0, 0),
                Offset(image.width.toDouble(), image.height.toDouble())));

        // Draw the original image onto the canvas
        canvas.drawImage(image, Offset.zero, Paint());

        // Define a TextStyle for the watermark text
        final style = ui.TextStyle(
          color: Colors.white.withOpacity(_watermarkOpacity),
          fontSize: 50.0,
          background: Paint()..color = Colors.black.withOpacity(_watermarkOpacity),
        );

        final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle())
          ..pushStyle(style)
          ..addText(_watermarkText);
        final paragraph = paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: image.width.toDouble()));

        // Calculate the positions for the watermark based on estrangementValue
        final List<Offset> positions =
        calculateWatermarkPositions(image, _estrangementValue);

        for (var position in positions) {
          // Save the current state of the canvas
          canvas.save();

          // Rotate and translate the canvas for diagonal watermark
          canvas.translate(position.dx, position.dy);
          canvas.rotate(-45 * (math.pi / 180));

          // Draw the watermark text on the canvas
          canvas.drawParagraph(paragraph, Offset(0, -25));

          // Restore the canvas state to its original
          canvas.restore();
        }

        // Convert the canvas drawing (Picture) back to Uint8List
        final picture = recorder.endRecording();
        final img = await picture.toImage(image.width, image.height);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        // Calculate name for the watermarked image based on the original index and estrangement value
        String imageName = "watermarked_${i}_${_estrangementValue.toStringAsFixed(2)}";

        // If not, add the new watermarked image to the list
        newWatermarkedImageNames.add(imageName);
        newWatermarkedImageDataList.add(pngBytes);
      }
    }

    // Once the entire processing is done, we'll update our main lists
    setState(() {
      _watermarkedImageDataList = newWatermarkedImageDataList;
      _watermarkedImageNames = newWatermarkedImageNames;
    });
  }

  List<Offset> calculateWatermarkPositions(
      ui.Image image, double estrangementValue) {
    List<Offset> positions = [];

    // Calculate the number of watermark positions based on estrangementValue
    // The factor "10" can be adjusted based on your preferred density.
    int numberOfPositions = (estrangementValue * 10).toInt();

    // Distribute the watermarks across the image
    for (int i = 0; i <= numberOfPositions; i++) {
      double xFactor = i / numberOfPositions;
      for (int j = 0; j <= numberOfPositions; j++) {
        double yFactor = j / numberOfPositions;
        positions.add(Offset(
          xFactor * image.width.toDouble(),
          yFactor * image.height.toDouble(),
        ));
      }
    }

    return positions;
  }

// ...

// _downloadImage() {
//   final blob = Blob([_watermarkedImageData]);
//   final url = Url.createObjectUrlFromBlob(blob);
//   final anchor = AnchorElement(href: url)
//     ..target = 'blank'
//     ..download = 'download.png'
//     ..click();
// }
}
