class FingerprintModel {
  String id = "?";
  String packet = "?";
  String error = "";
  FingerprintModel({this.id, this.packet, this.error});

  static FingerprintModel fromJSON(Map<String, dynamic> data) {
    String id = data["id"];
    String packet = data["packet"] ?? "";
    String error = data["error"] ?? "";
    return FingerprintModel(id: id, packet: packet, error: error);
  }
}