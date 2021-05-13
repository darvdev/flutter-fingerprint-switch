import 'package:fingerprint/models/fingerprint_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FingerprintsPage extends StatefulWidget {
  final bool fingerprintsRequested;
  final List<FingerprintModel> fingerprints;
  final Function callback;
  const FingerprintsPage(this.fingerprints, {this.callback, this.fingerprintsRequested = false, Key key}) : super(key: key);

  @override
  _FingerprintsPageState createState() => _FingerprintsPageState();
}

class _FingerprintsPageState extends State<FingerprintsPage> {

  @override
  Widget build(BuildContext context) {

    if (!widget.fingerprintsRequested) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Getting fingerprint templates...", style: TextStyle(color: Colors.grey.shade600, fontSize: 16),),
          ],
        ),
      );
    }

    if (widget.fingerprints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(FontAwesomeIcons.fingerprint, color: Colors.grey, size: 50,),
            SizedBox(height: 20),
            Text("No fingerprint registered", style: TextStyle(color: Colors.grey.shade600, fontSize: 16),),
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
            child: ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: widget.fingerprints.length,
              separatorBuilder: (context, index) => SizedBox(height: 10),
              itemBuilder: (context, index){
                FingerprintModel fingerprint = widget.fingerprints[index];
                print("Error $index: ${fingerprint.error}");
                return Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text("Fingerprint ID: ${fingerprint.id}", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),),
                            ),
                            SizedBox(width: 20),
                            InkWell(
                              customBorder: CircleBorder(),
                              child: Container(
                                height: 50,
                                width: 50,
                                alignment: Alignment.center,
                                child: Icon(FontAwesomeIcons.trashAlt, size: 18,),
                              ),
                              onTap: (){
                                print("delete ${fingerprint.id}");
                                widget.callback(fingerprint.id);
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.teal, width: 2),
                              ),
                              child: Text("${fingerprint.error.isNotEmpty ? "Error getting packet (${fingerprint.error})" : fingerprint.packet}", maxLines: 3, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: fingerprint.error.isNotEmpty ? Colors.grey : Colors.grey.shade700),),
                            ),
                            Positioned(
                              left: 20,
                              top: -7,
                              child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  color: Colors.white,
                                  child: Text("Packet", style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.bold),)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

}
