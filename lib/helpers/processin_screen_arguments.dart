import 'dart:io';
import 'package:geolocator/geolocator.dart';

class ProcessingScreenArguments {
  final File imageFile;
  final Position position;

  const ProcessingScreenArguments({
    required this.imageFile,
    required this.position,
  });
}
