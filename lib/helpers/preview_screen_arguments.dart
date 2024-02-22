import 'package:udg_cactus_app/models/observation_model.dart';

class PreviewScreenArguments {
  final Observation model;
  final bool toSave;

  const PreviewScreenArguments({
    required this.model,
    required this.toSave,
  });
}
