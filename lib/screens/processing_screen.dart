import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:croppy/croppy.dart';
import 'package:image/image.dart' as img;
import 'package:udg_cactus_app/helpers/preview_screen_arguments.dart';
import 'package:udg_cactus_app/helpers/route_generator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:udg_cactus_app/models/observation_model.dart';
import '../helpers/processing_screen_arguments.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProcessingScreen extends StatefulWidget {
  final ProcessingScreenArguments arguments;

  const ProcessingScreen({
    required this.arguments,
  });

  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _isCropped = false;
  bool _isBlurred = false;
  File? croppedImage;
  Uint8List? imageBytes;

  double posx = 0.0;
  double posy = 0.0;

  Offset localPosition = const Offset(-1, -1);
  Color _selectedColor = const Color(0xffffffff);
  final StreamController<Color> _stateController = StreamController<Color>();
  img.Image? photo;
  GlobalKey imageKey = GlobalKey();

  int counter = 0;

  SharedPreferences? preferences;

  Future<void> initStorage() async {
    preferences = await SharedPreferences.getInstance();

    // init 1st time to 0
    int? savedData = preferences?.getInt("counter");

    if (savedData == null) {
      await preferences!.setInt("counter", counter);
    } else {
      counter = savedData;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initStorage();
  }

  @override
  void dispose() {
    super.dispose();
    imageCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _isCropped
              ? Opacity(
                  opacity: _isBlurred ? 1.0 : 0.3,
                  child: StreamBuilder(
                    stream: _stateController.stream,
                    builder: (context, snapshot) {
                      _selectedColor = snapshot.data ?? const Color(0xffffffff);
                      return GestureDetector(
                        onPanDown: (details) {
                          searchPixel(details.globalPosition);
                        },
                        onPanUpdate: (details) {
                          searchPixel(details.globalPosition);
                        },
                        child: Stack(
                          children: [
                            Center(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Image.memory(
                                  imageBytes!,
                                  key: imageKey,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              width: 50,
                              height: 50,
                              top: 130,
                              left: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedColor,
                                  border: Border.all(
                                      width: 2.0, color: Colors.white),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 10,
                              top: 100,
                              child: Text(
                                '$_selectedColor',
                                style: const TextStyle(
                                    color: Colors.white,
                                    backgroundColor: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              : Container(),
          !_isBlurred
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                      ),
                      child: Text(
                        _isCropped
                            ? "Seleccionar el pixel que represente el color del cactus"
                            : "Seleccionar el area del cactus adecuada",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 50.0,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: (() async {
                        if (!_isCropped) {
                          final result = await showMaterialImageCropper(
                            context,
                            imageProvider:
                                FileImage(widget.arguments.imageFile),
                          );

                          if (result == null) {
                            return;
                          }

                          final image = result.uiImage;
                          final bytes = await image.toByteData(
                              format: ui.ImageByteFormat.png);

                          imageBytes = bytes!.buffer.asUint8List();

                          image.dispose();

                          setState(() {
                            _isCropped = true;
                          });

                          return;
                        }

                        if (!_isBlurred) {
                          setState(() {
                            _isBlurred = true;
                          });
                        }
                      }),
                      child: const Text(
                        'Ok',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : Container(),
          _isBlurred
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 500,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Uint8List originalBytes =
                              widget.arguments.imageFile.readAsBytesSync();

                          final address = await getAddress();

                          String tag =
                              "Observacion ${preferences?.getInt("counter")}";

                          preferences?.setInt("counter", counter += 1);

                          final Observation model = Observation(
                            tag: tag,
                            date: DateTime.now(),
                            latitude: widget.arguments.position.latitude,
                            longitude: widget.arguments.position.longitude,
                            address: address,
                            image: originalBytes,
                            zoom: imageBytes!,
                            pixelColor: _selectedColor.value,
                          );

                          final args = PreviewScreenArguments(
                              model: model, toSave: true);

                          if (!context.mounted) return;
                          Navigator.pushNamed(
                            context,
                            AppRoutes.preview,
                            arguments: args,
                          );
                        },
                        child: const Text("Ok"),
                      ),
                    ],
                  ),
                )
              : Container(),
          Align(
            alignment: const Alignment(-0.95, -0.90),
            child: InkWell(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.camera, (route) => false);
                },
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 35,
                  color: Colors.white70,
                ),
            ),
          ),
        ],
      ),
    );
  }

  void searchPixel(Offset globalPosition) async {
    if (photo == null) {
      await (loadImageBundleBytes());
    }
    _calculatePixel(globalPosition);
  }

  void _calculatePixel(Offset globalPosition) {
    final RenderObject? box = imageKey.currentContext!.findRenderObject();

    double px = 0.0;
    double py = 0.0;

    double meanA = 0.0;
    double meanR = 0.0;
    double meanG = 0.0;
    double meanB = 0.0;

    img.Pixel tmpPixel;
    double count = 0.0;

    if (box is RenderBox) {
      Offset localPosition = box.globalToLocal(globalPosition);

      px = localPosition.dx;
      py = localPosition.dy;

      double widgetScale = box.size.width / photo!.width;

      px = (px / widgetScale);
      py = (py / widgetScale);

      for (int i = px.toInt() - 3; i < px.toInt() + 3; i++) {
        for (int j = py.toInt() - 3; j < py.toInt() + 3; j++) {
          tmpPixel = photo!.getPixelSafe(i, j);
          meanA = meanA + tmpPixel.a;
          meanR = meanR + tmpPixel.r;
          meanG = meanG + tmpPixel.g;
          meanB = meanB + tmpPixel.b;
          count++;
        }
      }

      meanA = meanA / count;
      meanR = meanR / count;
      meanG = meanG / count;
      meanB = meanB / count;

      Color color = Color.fromARGB(
          meanA.toInt(), meanR.toInt(), meanG.toInt(), meanB.toInt());

      _stateController.add(color);
    }
  }

  Future<void> loadImageBundleBytes() async {
    photo = null;
    photo = img.decodeImage(imageBytes!);
  }

  Future<String> getAddress() async {
    List<Placemark> placemark = await placemarkFromCoordinates(
        widget.arguments.position.latitude,
        widget.arguments.position.longitude);

    String address = "";

    if (placemark[0].street != "") address = "${placemark[0].street}";

    if (placemark[0].subAdministrativeArea != "") {
      address = "$address, ${placemark[0].subAdministrativeArea}";
    }

    if (placemark[0].postalCode != "") {
      address = "$address, ${placemark[0].postalCode}";
    }

    if (address == "") {
      return "Unknown Place";
    }

    return address;
  }
}
