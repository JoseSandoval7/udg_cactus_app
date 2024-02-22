import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:udg_cactus_app/helpers/appcolors.dart';
import 'package:udg_cactus_app/helpers/map_screen_arguments.dart';
import 'package:udg_cactus_app/helpers/preview_screen_arguments.dart';
import 'package:udg_cactus_app/helpers/route_generator.dart';
import 'package:udg_cactus_app/models/observation_model.dart';
import 'package:udg_cactus_app/helpers/processing_helper.dart';
import 'package:udg_cactus_app/services/db_helper.dart';

class PreviewScreen extends StatefulWidget {
  final PreviewScreenArguments arguments;

  const PreviewScreen({
    required this.arguments,
  });

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  String dropdownvalue = 'Original';

  var items = [
    'Original',
    'Zoom',
  ];

  TextEditingController? _textController;

  MapController? _mapController;
  GlobalKey _mapKey = GlobalKey();

  String? text;

  int _index = 0;
  bool _isCover = false;
  bool _isEnable = false;
  bool _isProcessed = false;
  bool _isSaved = false;

  List<File>? originalImages;
  List<File>? croppedImages;

  List<StaticPositionGeoPoint> points = [];

  proccessImages() async {
    var names = ['grayScale', 'filtered', 'negative', 'DM'];

    originalImages =
        await getProcessedImageList(widget.arguments.model.image, names);

    names = ['grayscale_z', 'filtered_z', 'negative_z', 'DM_z'];

    croppedImages =
        await getProcessedImageList(widget.arguments.model.zoom, names);
  }

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
                latitude: widget.arguments.model.latitude,
                longitude: widget.arguments.model.longitude),
            markerIcon: const MarkerIcon(
              icon: Icon(Icons.location_on, color: Colors.red, size: 30),
            ),
          );
        },
      );

  @override
  void initState() {
    super.initState();

    var initPosition = GeoPoint(
        latitude: widget.arguments.model.latitude,
        longitude: widget.arguments.model.longitude);

    _mapController = MapController(
      initPosition: initPosition,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await proccessImages();

      setState(() {
        _isProcessed = true;
      });
    });

    text = widget.arguments.model.tag;
    _textController = TextEditingController(text: text);
  }

  @override
  void dispose() {
    _textController!.dispose();
    _mapController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color pixel = Color(widget.arguments.model.pixelColor);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {},
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverAppBar(
              floating: false,
              pinned: true,
              expandedHeight: 200,
              backgroundColor: AppColors.MAIN_COLOR,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 25,
                  color: Colors.white,
                ),
                onPressed: (() {
                  if (widget.arguments.toSave) {
                    Navigator.of(context).pushNamed(AppRoutes.camera);
                  } else {
                    Navigator.of(context).pop();
                  }
                }),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.fullscreen_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                    onPressed: (() {
                      setState(() {
                        _isCover = !_isCover;
                      });
                    }),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.black,
                  child: Hero(
                    tag: widget.arguments.model.id.toString(),
                    child: Image.memory(
                      widget.arguments.model.image,
                      fit: _isCover ? BoxFit.cover : BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 30.0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _isEnable
                              ? Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    autofocus: true,
                                    style: const TextStyle(
                                      fontSize: 25.0,
                                      fontFamily: 'OpenSans',
                                    ),
                                    decoration: const InputDecoration.collapsed(
                                      hintText: "",
                                      border: InputBorder.none,
                                    ),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(20)
                                    ],
                                    onTapOutside: (event) async =>
                                        setState(() => _isEnable = false),
                                    onSubmitted: (value) async {
                                      Observation newObservation = Observation(
                                          id: widget.arguments.model.id,
                                          tag: value,
                                          date: widget.arguments.model.date,
                                          latitude:
                                              widget.arguments.model.latitude,
                                          longitude:
                                              widget.arguments.model.longitude,
                                          address:
                                              widget.arguments.model.address,
                                          image: widget.arguments.model.image,
                                          zoom: widget.arguments.model.zoom,
                                          pixelColor: widget
                                              .arguments.model.pixelColor);

                                      await DatabaseHelper.instance
                                          .updateObservation(newObservation);

                                      setState(() {
                                        text = value;
                                        _isEnable = false;
                                      });
                                    },
                                  ),
                                )
                              : Text(
                                  text!,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 25.0,
                                    fontFamily: 'OpenSans',
                                  ),
                                ),
                          !_isEnable ? const Spacer() : Container(),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_square,
                              size: 30,
                              color: Colors.grey,
                            ),
                            onPressed: (() {
                              setState(() {
                                _isEnable = true;
                              });
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          const WidgetSpan(
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                          TextSpan(
                              text:
                                  ' Observado el ${formatDate(widget.arguments.model.date)}')
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          const WidgetSpan(
                            child: Icon(
                              Icons.location_pin,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                          TextSpan(text: '  ${widget.arguments.model.address}')
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    GestureDetector(
                      onTap: () {
                        final args = MapScreenArguments(
                          initPoint: GeoPoint(
                              latitude: widget.arguments.model.latitude,
                              longitude: widget.arguments.model.longitude),
                        );

                        Navigator.pushNamed(
                          context,
                          AppRoutes.map,
                          arguments: args,
                        );
                      },
                      child: SizedBox(
                        key: _mapKey,
                        height: 300,
                        child: AbsorbPointer(
                          child: buildMap(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    const Text(
                      'RESULTADOS',
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(
                      height: 130,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                const WidgetSpan(
                                  child: Icon(Icons.square,
                                      size: 16, color: Colors.red),
                                ),
                                TextSpan(
                                  text: " Media Canal Rojo:  ${pixel.red}",
                                  style: const TextStyle(
                                    fontFamily: 'OpenSans',
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                const WidgetSpan(
                                  child: Icon(Icons.square,
                                      size: 16, color: Colors.green),
                                ),
                                TextSpan(
                                  text: " Media Canal verde:  ${pixel.green}",
                                  style: const TextStyle(
                                    fontFamily: 'OpenSans',
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                const WidgetSpan(
                                  child: Icon(Icons.square,
                                      size: 16, color: Colors.blue),
                                ),
                                TextSpan(
                                  text: " Media Canal Azul:  ${pixel.blue}",
                                  style: const TextStyle(
                                    fontFamily: 'OpenSans',
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        borderRadius: BorderRadius.circular(10),
                        elevation: 6,
                        child: Container(
                          height: 50,
                          width: 120,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: dropdownvalue,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: items.map(
                              (String items) {
                                return DropdownMenuItem(
                                  value: items,
                                  child: Text(
                                    items,
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                            onChanged: ((String? newValue) {
                              setState(() {
                                dropdownvalue = newValue!;
                              });
                            }),
                            underline: const SizedBox(),
                            isExpanded: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      height: 300.0,
                      child: PageView.builder(
                        itemCount: 4,
                        controller: PageController(viewportFraction: 1.0),
                        onPageChanged: (int index) {
                          setState(() => _index = index);
                        },
                        itemBuilder: (context, i) {
                          return Transform.scale(
                            scale: i == _index ? 1 : 0.9,
                            child: Card(
                              semanticContainer: true,
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 250.0,
                                    child: _isProcessed
                                        ? Image.file(
                                            dropdownvalue == 'Original'
                                                ? originalImages![i]
                                                : croppedImages![i],
                                            fit: BoxFit.fitWidth,
                                          )
                                        : const Center(
                                            child: Text("Cargando..."),
                                          ),
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Center(
                                    child: _isProcessed
                                        ? Text(
                                            "${originalImages![i].path.split('/').last.split('.').first.toUpperCase()}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          )
                                        : const Text(""),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 20.0,
                    ),
                    widget.arguments.toSave
                        ? SizedBox(
                            height: 50.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(50.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'Escanear',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () async {
                                      if (_isSaved) return;

                                      DatabaseHelper.instance.addObservation(
                                          widget.arguments.model);

                                      setState(() {
                                        _isSaved = true;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor:
                                          !_isSaved ? Colors.red : Colors.grey,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(50.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'Guardar',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    const SizedBox(
                      height: 60,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatDate(DateTime date) {
  Map<int, String> months = {
    1: 'Enero',
    2: 'Febrero',
    3: 'Marzo',
    4: 'Abril',
    5: 'Mayo',
    6: 'Junio',
    7: 'Julio',
    8: 'Agosto',
    9: 'Septiembte',
    10: 'Octubre',
    11: 'Noviembre',
    12: 'Diciembre',
  };

  var monthList = months.values.toList();

  return '${date.day} de ${monthList[date.month - 1]} del ${date.year}';
}
