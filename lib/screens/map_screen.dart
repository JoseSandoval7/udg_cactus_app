import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:udg_cactus_app/helpers/map_screen_arguments.dart';

class MapScreen extends StatefulWidget {
  final MapScreenArguments arguments;

  const MapScreen({
    super.key,
    required this.arguments,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _mapController;

  Widget buildMap() => OSMFlutter(
        controller: _mapController!,
        mapIsLoading: const Center(
          child: CircularProgressIndicator(),
        ),
        osmOption: const OSMOption(
          zoomOption: ZoomOption(
            initZoom: 17,
            minZoomLevel: 4,
            maxZoomLevel: 19,
          ),
        ),
        onMapIsReady: (_) async {
          await _mapController!.addMarker(
            GeoPoint(
                latitude: widget.arguments.initPoint.latitude,
                longitude: widget.arguments.initPoint.longitude),
            markerIcon: const MarkerIcon(
              icon: Icon(Icons.location_on, color: Colors.red, size: 30),
            ),
          );
        },
        onGeoPointClicked: ((_) {
          showModalBottomSheet(
              context: context,
              builder: (context) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: SizedBox(
                            height: 50,
                            child: Text("COORDENADAS"),
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                  padding: EdgeInsets.only(left: 10.0),
                                  child: Text("Latitud:")),
                              Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: Text(
                                    "${widget.arguments.initPoint.latitude}"),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                  padding: EdgeInsets.only(left: 10.0),
                                  child: Text("Longitud")),
                              Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: Text(
                                    "${widget.arguments.initPoint.longitude}"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: kBottomNavigationBarHeight,
                        ),
                      ],
                    ),
                  ),
                );
              });
        }),
      );

  @override
  void initState() {
    super.initState();

    _mapController = MapController(initPosition: widget.arguments.initPoint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          buildMap(),
        ],
      ),
    );
  }
}
