import 'dart:io';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:native_opencv/native_opencv.dart';

Future<List<File>> createTemporaryPath(
    List<Map<Map<String, ffi.Pointer<ffi.Uint8>>, int>> filenames) async {
  final dir = await getApplicationDocumentsDirectory();
  List<File> filelist = [];

  for (int i = 0; i < filenames.length; i++) {
    var name = filenames[i].keys.first.keys.first;

    if (await File('${dir.path}/${name}.jpg').exists()) {
      await File('${dir.path}/${name}.jpg').delete();
    }

    var file = await File('${dir.path}/${name}.jpg').create();
    file.writeAsBytesSync(filenames[i]
        .keys
        .first
        .values
        .first
        .asTypedList(filenames[i].values.first));
    filelist.add(file);
  }

  return filelist;
}

Future<List<File>> getProcessedImageList(
    Uint8List bytes, List<String> nameList) async {
  var image = await decodeImageFromList(bytes);

  // Get image dimensions
  int height = image.height;
  int width = image.width;

  // Get path for input image
  final tempDir = await getTemporaryDirectory();

  if (await File('${tempDir.path}/input.jpg').exists()) {
    await File('${tempDir.path}/input.jpg').delete();
    imageCache.clear();
  }

  // Write to file
  File inputPath = await File('${tempDir.path}/input.jpg').create();
  inputPath.writeAsBytesSync(bytes);

  // Allocating space from native heap
  ffi.Pointer<ffi.Uint8> grayScale =
      malloc.allocate<ffi.Uint8>(height * width * 1);

  ffi.Pointer<ffi.Uint8> filtered =
      malloc.allocate<ffi.Uint8>(height * width * 1);

  ffi.Pointer<ffi.Uint8> negative =
      malloc.allocate<ffi.Uint8>(height * width * 1);

  ffi.Pointer<ffi.Uint8> DM = malloc.allocate<ffi.Uint8>(height * width * 3);

  // Structure args
  final args = ProcessImageArguments(
      height, width, inputPath.path, grayScale, filtered, negative, DM);

  // Run processing func
  processImage(args);

  List<Map<Map<String, ffi.Pointer<ffi.Uint8>>, int>> imagesToProcess = [
    {
      {nameList[0]: grayScale}: width * height
    },
    {
      {nameList[1]: filtered}: width * height
    },
    {
      {nameList[2]: negative}: width * height
    },
    {
      {nameList[3]: DM}: width * height * 3
    },
  ];

  List<File> processedImages = await createTemporaryPath(imagesToProcess);

  // Free pointers
  malloc.free(grayScale);
  malloc.free(filtered);
  malloc.free(negative);
  malloc.free(DM);

  return processedImages;
}
