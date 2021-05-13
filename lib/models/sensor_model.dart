class SensorModel {
  String statusReg = "?";
  String systemId = "?";
  String capacity = "?";
  String securityLevel = "?";
  String deviceAddress = "?";
  String packetLength = "?";
  String baudRate = "?";
  String templateCount = "?";
  SensorModel({this.statusReg, this.systemId, this.capacity, this.securityLevel, this.deviceAddress, this.packetLength, this.baudRate, this.templateCount});

  static SensorModel fromJSON(Map<String, dynamic> data) {
    String statusReg = data["status_reg"];
    String systemId = data["system_id"];
    String capacity = data["capacity"];
    String securityLevel = data["security_level"];
    String deviceAddress = data["device_addr"];
    String packetLength = data["packet_len"];
    String baudRate = data["baud_rate"];
    String templateCount = data["template_count"];

    return SensorModel(statusReg: statusReg, systemId: systemId, capacity: capacity, securityLevel: securityLevel, deviceAddress: deviceAddress, packetLength: packetLength, baudRate: baudRate, templateCount: templateCount);
  }
}