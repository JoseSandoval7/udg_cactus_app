import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:udg_cactus_app/helpers/appcolors.dart';
import 'package:udg_cactus_app/helpers/preview_screen_arguments.dart';
import 'package:udg_cactus_app/helpers/processing_helper.dart';
import 'package:udg_cactus_app/helpers/route_generator.dart';
import 'package:udg_cactus_app/models/observation_model.dart';
import 'package:udg_cactus_app/services/db_helper.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Observation> allFileList = [];

  bool _isLoading = true;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.initState();
    readFiles();
  }

  Future readFiles() async {
    // Clean file list
    allFileList.clear();

    // Fetch from db
    DatabaseHelper.instance
        .fetchAllObservation()
        .then((List<Observation>? observations) {

      if (observations != null) {
        for (var observation in observations) {
          allFileList.add(observation);
        }
      }

      setState(() {
        _isLoading = false;
      });
    }).catchError((error) {
      print("Error fetching observations: $error");
    });
  }

  void deleteFiles() {
    for (Observation observation in allFileList) {
      DatabaseHelper.instance.deleteObservation(observation);
    }

    allFileList.clear();

    setState(() {});
  }

  showAlertDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        deleteFiles();
        Navigator.of(context).pop();
      },
    );

    Widget cancelButton = TextButton(
      child: Text("CANCELAR"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Eliminar registros"),
      content: Text("¿Estas seguro que deseas eliminar todos los registros?"),
      actions: [
        okButton,
        cancelButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Biblioteca"),
        foregroundColor: Colors.white,
        backgroundColor: AppColors.MAIN_COLOR,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 25,
            color: Colors.white,
          ),
          onPressed: (() {
            Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.home, (route) => false);
          }),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
              onPressed: (() {
                showAlertDialog(context);
              }),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: !_isLoading
          ? Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      for (Observation observation in allFileList)
                        Slidable(
                          endActionPane: ActionPane(
                            motion: const StretchMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) async {
                                  DatabaseHelper.instance
                                      .deleteObservation(observation);

                                  readFiles();

                                  setState(() {});
                                },
                                backgroundColor: Colors.red,
                                icon: Icons.delete,
                                label: 'Eliminar',
                              ),
                            ],
                          ),
                          child: Card(
                            child: ListTile(
                              onTap: () async {
                                var names = [
                                  'grayScale',
                                  'filtered',
                                  'negative',
                                  'DM'
                                ];

                                await getProcessedImageList(
                                    observation.image, names);

                                names = [
                                  'grayscale_z',
                                  'filtered_z',
                                  'negative_z',
                                  'DM_z'
                                ];

                                await getProcessedImageList(
                                    observation.zoom, names);

                                final args = PreviewScreenArguments(
                                  model: observation,
                                  toSave: false,
                                );

                                if (!mounted) return;

                                var result = await Navigator.pushNamed(
                                  context,
                                  AppRoutes.preview,
                                  arguments: args,
                                );

                                if (result == null) {
                                  readFiles();
                                  setState(() {});
                                }
                              },
                              title: Text("${observation.tag.toString()}"),
                              subtitle: Text(
                                  "Observacion hecha el ${formatDateTime(observation.date)}"),
                              leading: Hero(
                                tag: observation.id.toString(),
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      Image.memory(observation.image).image,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).padding.bottom,
                )
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: AppColors.MAIN_COLOR),
            ),
    );
  }
}

String formatDateTime(DateTime now) {
  String convertedDateTime =
      "${now.year.toString()}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

  return convertedDateTime;
}
