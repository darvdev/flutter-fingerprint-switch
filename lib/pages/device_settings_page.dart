import 'package:fingerprint/models/device_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DeviceSettingsPage extends StatelessWidget {

  final bool deviceInfoRequested;
  final DeviceModel device;
  final Function callback;
  const DeviceSettingsPage({this.deviceInfoRequested, this.device, this.callback, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    if (!deviceInfoRequested) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Getting device information...", style: TextStyle(color: Colors.grey.shade600, fontSize: 16),),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                // alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Version", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text(device.version, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                  ],
                ),
              ),
              onTap: (){},
            ),
          ),
          Divider(height: 1),
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                // alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Device Password", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text(device.pass, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                  ],
                ),
              ),
              onTap: (){
                callback("pass");
              },
            ),
          ),
          Divider(height: 1),
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                // alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Battery Level", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text("59%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                  ],
                ),
              ),
              onTap: (){},
            ),
          ),
          Divider(height: 1),
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                // alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Mac Address", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text(device.macAddress, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                  ],
                ),
              ),
              onTap: (){},
            ),
          ),
          SizedBox(height: 15),
          Material(
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Access Point", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),),
                          Material(
                            color: Colors.white,
                            child: InkWell(
                              customBorder: CircleBorder(),
                              child: Container(
                                height: 50,
                                width: 50,
                                alignment: Alignment.center,
                                child: Icon(FontAwesomeIcons.edit, color: Colors.teal, size: 16,),
                              ),
                              onTap: (){
                                callback("ap");
                              },
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 1, thickness: 1.5,),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("SSID", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.apSsid, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Password", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.apPass, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("IP Address", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.apIp, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          SizedBox(height: 15),
          Material(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Wifi Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),),
                          Material(
                            color: Colors.white,
                            child: InkWell(
                              customBorder: CircleBorder(),
                              child: Container(
                                height: 50,
                                width: 50,
                                alignment: Alignment.center,
                                child: Icon(FontAwesomeIcons.edit, color: Colors.teal, size: 16,),
                              ),
                              onTap: (){
                                callback("wifi");
                              },
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 1, thickness: 1.5,),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Column(
                    children: [
                      SizedBox(height: 5),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("SSID", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.wifiSsid, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Password", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.wifiPass, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("IP Address", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.wifiIp, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Gateway", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.gatewayIp, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Subnet Mask", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.subnetMask, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Channel", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.channel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("State", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.state, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          SizedBox(height: 15),
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                alignment: Alignment.center,
                child: Text("Reboot Device", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),),
              ),
              onTap: (){
                callback("reset");
              },
            ),
          ),
          Divider(height: 1),
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                alignment: Alignment.center,
                child: Text("Factory Reset", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),),
              ),
              onTap: (){},
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );

  }
}
