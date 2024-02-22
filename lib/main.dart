import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:udg_cactus_app/helpers/route_generator.dart';

List<CameraDescription> cameras = [];
Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error in fetching the cameras: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: getInitialPage(),
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }

  String getInitialPage() => AppRoutes.home;
}
