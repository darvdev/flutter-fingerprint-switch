import 'package:fingerprint/models/sensor_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class SensorPage extends StatelessWidget {
  final SensorModel sensor;
  final bool isSensorAvailable;
  final bool sensorInfoRequested;
  final Function callback;
  const SensorPage(this.sensor, {this.isSensorAvailable = false, this.sensorInfoRequested = false, this.callback, Key key}) : super(key: key);

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
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Status Reg", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text("0x${sensor.statusReg}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("System ID", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text("0x${sensor.systemId}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Capacity", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text(sensor.capacity, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Security Level", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text(sensor.securityLevel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Device Address", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text(sensor.deviceAddress, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
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
                    Text("Packet Length", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text(sensor.packetLength, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Baud Rate", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text(sensor.baudRate, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
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
                padding: EdgeInsets.fromLTRB(30, 0, 5, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Registered Fingerprints", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Row(
                      children: [
                        Text(sensor.templateCount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
              onTap: (){
                callback();
              },
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}