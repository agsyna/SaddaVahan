class PredictionsModel {
  String? placeId;
  late String mainText, secondaryText;

  PredictionsModel({
    this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  PredictionsModel.fromJson(Map<String, dynamic> json) {
    placeId = json["place_id"];
    mainText = json["structured_formatting"]["main_text"];
    secondaryText = json["structured_formatting"]["secondary_text"];
  }
}
