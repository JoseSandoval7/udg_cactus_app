import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:udg_cactus_app/helpers/processin_screen_arguments.dart';
import 'package:udg_cactus_app/helpers/route_generator.dart';
import 'package:udg_cactus_app/models/observation_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:udg_cactus_app/services/db_helper.dart';

import '../main.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;

  File? _imageFile;
  Image? _thumbnail;
  late Position currentPosition;

  // Initial value
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  bool _isLocationPermissionGranted = false;
  bool _isRearCameraSelected = true;
  bool _isFlashOn = false;
  bool _isTorchOn = false;
  bool _isPictureTaken = false;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  // Current values
  double _currentZoomLevel = 1.0;
  FlashMode? _currentFlashMode = FlashMode.off;

  List<Observation> allFileList = [];

  final resolutionPresets = ResolutionPreset.values;

  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;

  Future<bool> _pickImageFromGallery() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image == null) return false;
    setState(() {
      _imageFile = File(image.path);
    });
    return true;
  }

  getPermissionStatus() async {
    await Permission.camera.request();
    var status = await Permission.camera.status;

    if (status.isGranted) {
      log('Camera Permission: GRANTED');
      setState(() {
        _isCameraPermissionGranted = true;
      });
      // Set and initialize the new camera
      onNewCameraSelected(cameras[0]);
      refreshCapturedImages();
    } else {
      log('Camera Permission: DENIED');
    }
  }

  refreshCapturedImages() async {
    // Clean file list
    allFileList.clear();

    // Fetch from db
    DatabaseHelper.instance
        .fetchAllObservation()
        .then((List<Observation>? observations) {
      if (observations == null) return;

      for (var observation in observations) {
        allFileList.add(observation);
      }

      if (allFileList.isNotEmpty) {
        _thumbnail = Image.memory(allFileList.last.image);
      }

      setState(() {});
    }).catchError((error) {
      print("Error fetching observations: $error");
    });
  }

  _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return;
    }

    setState(() {
      _isLocationPermissionGranted = true;
    });
  }

  Future<void> getLocation() async {
    currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;

    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();

      XFile rotatedFile = await rotateImage(file);

      return rotatedFile;
    } on CameraException catch (e) {
      print('Error occured while taking picture: $e');
      return null;
    }
  }

  Future<XFile> rotateImage(XFile imageFile) async {
    // Load the image using the image package
    img.Image image = img.decodeImage(File(imageFile.path).readAsBytesSync())!;

    // Rotate the image based on the device orientation
    img.Image rotatedImage = img.copyRotate(image, angle: 0);

    File(imageFile.path).writeAsBytesSync(img.encodeJpg(rotatedImage));

    return XFile(imageFile.path);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    //Replace with the new controller
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    cameraController
        .getMaxZoomLevel()
        .then((value) => _maxAvailableZoom = value);

    cameraController
        .getMinZoomLevel()
        .then((value) => _minAvailableZoom = value);

    await cameraController.setFlashMode(FlashMode.off);

    // Update the boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
        _isFlashOn = false;
      });
    }
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    controller!.setExposurePoint(offset);
    controller!.setFocusPoint(offset);
  }

  @override
  void initState() {
    // Hide the status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Lock orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _handleLocationPermission();
    getPermissionStatus();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    // Release orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isCameraPermissionGranted && _isLocationPermissionGranted
            ? _isCameraInitialized
                ? Stack(
                    children: [
                      Transform.scale(
                        scale: 1 /
                            (controller!.value.aspectRatio *
                                MediaQuery.of(context).size.aspectRatio),
                        alignment: Alignment.topCenter,
                        child: Stack(
                          children: [
                            CameraPreview(
                              controller!,
                              child: LayoutBuilder(builder:
                                  (BuildContext context,
                                      BoxConstraints constraints) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) =>
                                      onViewFinderTap(details, constraints),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          height: screenHeight * 0.12,
                          color: const Color.fromRGBO(255, 255, 255, 0.4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isCameraInitialized = false;
                                  });
                                  onNewCameraSelected(
                                    cameras[_isRearCameraSelected ? 1 : 0],
                                  );
                                  setState(() {
                                    _isRearCameraSelected =
                                        !_isRearCameraSelected;
                                  });
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      color: Colors.black38,
                                      size: 60,
                                    ),
                                    Icon(
                                      _isRearCameraSelected
                                          ? Icons.camera_front
                                          : Icons.camera_rear,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  setState(() {
                                    _isPictureTaken = true;
                                  });

                                  XFile? rawImage = await takePicture();

                                  controller!.pausePreview();

                                  setState(() {
                                    _imageFile = File(rawImage!.path);
                                  });

                                  await getLocation();

                                  final arguments = ProcessingScreenArguments(
                                      imageFile: _imageFile!,
                                      position: currentPosition);

                                  if (!context.mounted) return;

                                  Navigator.of(context).pop();

                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.processing,
                                    arguments: arguments,
                                  );
                                },
                                child: const Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(Icons.circle,
                                        color: Colors.white38, size: 80),
                                    Icon(Icons.circle,
                                        color: Colors.white, size: 65),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  bool ok;
                                  ok = await _pickImageFromGallery();

                                  if (!ok) return;

                                  await getLocation();

                                  final arguments = ProcessingScreenArguments(
                                      imageFile: _imageFile!,
                                      position: currentPosition);

                                  if (!context.mounted) return;
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.processing,
                                    arguments: arguments,
                                  );
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    image: _thumbnail != null
                                        ? DecorationImage(
                                            image: _thumbnail!.image,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: Container(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: const Alignment(0.95, -0.90),
                        child: SizedBox(
                          height: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    right: 8.0,
                                  ),
                                  child: DropdownButton<ResolutionPreset>(
                                    dropdownColor: Colors.black87,
                                    underline: Container(),
                                    value: currentResolutionPreset,
                                    items: [
                                      for (ResolutionPreset preset
                                          in resolutionPresets)
                                        DropdownMenuItem(
                                          value: preset,
                                          child: Text(
                                            preset
                                                .toString()
                                                .split('.')[1]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        )
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        currentResolutionPreset = value!;
                                        _isCameraInitialized = false;
                                      });
                                      onNewCameraSelected(
                                          controller!.description);
                                    },
                                    hint: const Text("Select Item"),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: InkWell(
                                  onTap: () async {
                                    setState(() {
                                      _isFlashOn =
                                          !_isTorchOn ? !_isFlashOn : false;

                                      _isTorchOn = false;

                                      _currentFlashMode = _isFlashOn
                                          ? FlashMode.always
                                          : FlashMode.off;
                                    });

                                    await controller!.setFlashMode(
                                      _currentFlashMode!,
                                    );
                                  },
                                  onLongPress: () async {
                                    setState(() {
                                      _isTorchOn = true;
                                      _isFlashOn = true;
                                    });

                                    await controller!.setFlashMode(
                                      FlashMode.torch,
                                    );
                                  },
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: const BoxDecoration(
                                      color: Colors.black87,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isFlashOn
                                          ? Icons.flash_on
                                          : Icons.flash_off,
                                      color: _isTorchOn
                                          ? Colors.amber
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: const Alignment(-0.95, -0.95),
                        child: InkWell(
                            onTap: () {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, AppRoutes.home, (route) => false);
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              size: 35,
                              color: Colors.white70,
                            )),
                      ),
                      Align(
                        alignment: const Alignment(0.0, 0.7),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: screenHeight * 0.1,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _currentZoomLevel,
                                    min: _minAvailableZoom,
                                    max: _maxAvailableZoom,
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.white30,
                                    onChanged: (value) async {
                                      setState(() {
                                        _currentZoomLevel = value;
                                      });
                                      await controller!.setZoomLevel(value);
                                    },
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _currentZoomLevel.toStringAsFixed(1) +
                                          'x',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _isPictureTaken
                          ? Stack(
                              children: [
                                Opacity(
                                  opacity: 0.3,
                                  child: Container(
                                    color: Colors.grey,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )
                          : Container(),
                    ],
                  )
                : const Center(
                    child: Text(
                      'LOADING',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(),
                  const Text(
                    'Permission denied',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      _handleLocationPermission();
                      getPermissionStatus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Give permission',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
