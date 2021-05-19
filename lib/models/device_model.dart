
class DeviceModel {
  String version = "";
  String pass = "";
  String apSsid = "";
  String apPass = "";
  String apIp = "";
  String wifiSsid = "";
  String wifiPass = "";
  String wifiIp = "";
  String gatewayIp = "";
  String subnetMask = "";
  String macAddress = "";
  String state = "";
  String channel = "?";
  String engineStart = "?";
  String confidence = "?";

  DeviceModel({this.version, this.apPass, this.apSsid, this.pass, this.apIp, this.wifiSsid, this.wifiPass, this.wifiIp, this.gatewayIp, this.subnetMask, this.macAddress, this.state, this.channel, this.engineStart, this.confidence});

  static DeviceModel fromJSON(Map<String, dynamic> data) {
    String version = data["version"];
    String pass = data["pass"];
    String apSsid = data["ap_ssid"];
    String apPass = data["ap_pass"];
    String apIp = data["ap_ip"];
    String wifiSsid = data["wifi_ssid"];
    String wifiPass = data["wifi_pass"];
    String wifiIp = data["wifi_ip"];
    String gatewayIp  = data["wifi_gateway"];
    String subnetMask = data["wifi_subnet"];
    String macAddress = data["wifi_mac"];
    String state = data["wifi_state"] == "1" ? "Connected" : "Disconnected";
    String channel = data["wifi_channel"];
    String engineStart = data["engine_start"];
    String confidence = data["confidence"];

    return DeviceModel(version: version, apPass: apPass, apSsid: apSsid, apIp: apIp, pass: pass, wifiSsid: wifiSsid, wifiPass: wifiPass, wifiIp: wifiIp, gatewayIp: gatewayIp, subnetMask: subnetMask, macAddress: macAddress, state: state, channel: channel, engineStart: engineStart, confidence: confidence);
  }

}