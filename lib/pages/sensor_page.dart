import 'package:fingerprint/models/sensor_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SensorPage extends StatelessWidget {
  final SensorModel sensor;
  final bool isSensorAvailable;
  final bool sensorInfoRequested;
  const SensorPage(this.sensor, {this.isSensorAvailable = false, this.sensorInfoRequested = false, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    if (!sensorInfoRequested) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Getting sensor information...", style: TextStyle(color: Colors.grey.shade600, fontSize: 16),),
          ],
        ),
      );
    }

    if (!isSensorAvailable) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.fingerprint, size: 50, color: Colors.grey,),
            SizedBox(height: 10),
            Text("Sensor is not available", style: TextStyle(fontSize: 18, color: Colors.grey),),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.teal, width: 2)),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Status Reg:", style: TextStyle(fontSize: 18, color: Colors.grey),),
                            SizedBox(width: 10),
                            Text("0x${sensor.statusReg}", style: TextStyle(fontSize: 18),),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Text("System ID:", style: TextStyle(fontSize: 18, color: Colors.grey),),
                            SizedBox(width: 10),
                            Text("0x${sensor.systemId}", style: TextStyle(fontSize: 18),),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Text("Capacity: ", style: TextStyle(fontSize: 18, color: Colors.grey),),
                            SizedBox(width: 10),
                            Text("${sensor.capacity}", style: TextStyle(fontSize: 18),),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Text("Security Level: ", style: TextStyle(fontSize: 18, color: Colors.grey),),
                            SizedBox(width: 10),
                            Text("${sensor.securityLevel}", style: TextStyle(fontSize: 18),),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Text("Device Address: ", style: TextStyle(fontSize: 18, color: Colors.grey),),
                            SizedBox(width: 10),
                            Text("0x${sensor.deviceAddress}", style: TextStyle(fontSize: 18),),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Text("Packet Length ", style: TextStyle(fontSize: 18, color: Colors.grey),),
                            SizedBox(width: 10),
                            Text("${sensor.packetLength}", style: TextStyle(fontSize: 18),),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Text("Baud Rate: ", style: TextStyle(fontSize: 18, color: Colors.grey),),
                            SizedBox(width: 10),
                            Text("${sensor.baudRate}", style: TextStyle(fontSize: 18),),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Text("Registered fingerprint: ", style: TextStyle(fontSize: 18, color: Colors.grey),),
                            SizedBox(width: 10),
                            Text("${sensor.templateCount}", style: TextStyle(fontSize: 18),),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
