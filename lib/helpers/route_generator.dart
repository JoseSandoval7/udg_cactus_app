import 'package:flutter/material.dart';
import 'package:udg_cactus_app/helpers/map_screen_arguments.dart';
import 'package:udg_cactus_app/helpers/preview_screen_arguments.dart';
import 'package:udg_cactus_app/helpers/processing_screen_arguments.dart';
import 'package:udg_cactus_app/screens/map_screen.dart';
import 'package:udg_cactus_app/screens/processing_screen.dart';
import '../screens/preview_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/library_screen.dart';

class AppRoutes {
  static const home = '/home';
  static const library = "/library";
  static const camera = "/camera";
  static const processing = "/processing";
  static const preview = "/preview";
  static const results = "/results";
  static const map = "/map";
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => WelcomeScreen());
      case AppRoutes.library:
        return buildRoute(const LibraryScreen(), settings: settings);
      case AppRoutes.camera:
        return buildRoute(CameraScreen(), settings: settings);
      case AppRoutes.processing:
        return buildRoute(
            ProcessingScreen(
              arguments: args as ProcessingScreenArguments,
            ),
            settings: settings);
      case AppRoutes.preview:
        return buildRoute(
            PreviewScreen(
              arguments: args as PreviewScreenArguments,
            ),
            settings: settings);
      case AppRoutes.map:
        return buildRoute(
            MapScreen(
              arguments: args as MapScreenArguments,
            ),
            settings: settings);
      default:
        return _errorRoute();
    }
  }

  static MaterialPageRoute buildRoute(Widget child,
      {required RouteSettings settings}) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => child,
    );
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('ERROR'),
        ),
      );
    });
  }
}
