import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:audioplayers/audio_cache.dart';

import 'definitions.dart';

class BarcodeScanner extends StatefulWidget {
  @override
  BarcodeScannerState createState() => BarcodeScannerState();
}

class BarcodeScannerState extends State<BarcodeScanner> {
  static const platform = const MethodChannel('net.plzft.poc_od');
  QRReaderController controller;
  final referencController = TextEditingController(text: "");
  final pwController = TextEditingController(text: "");
  String publicRegistrationId;
  bool useCam = true;
  final player = AudioCache();
  var beep = 'beep.mp3';

  @override
  void initState() {
    super.initState();
    setState(() {
      useCam = true;
      controller = null;
      publicRegistrationId = null;
    });
  }

  void requestCredential(String barCodeReference) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString('registrationType') == 'Email') {
      setState(() {
        publicRegistrationId = 'email#' + prefs.getString('email');
      });
    } else {
      setState(() {
        publicRegistrationId = prefs.getString('mobile');
      });
    }

    String url =
        "http://legicmobile.plasticard.de:80/v1/WriteDataToMobileDevice";
    barCodeReference = barCodeReference.replaceAll('""', '"');
    Map<String, String> userHeader = {
      "Content-type": "application/json",
      "Access-Control-Allow-Origin": "*"
    };

    void notificate(notification) {
      switch (notification) {
        case 1:
          player.play('beep.mp3');
          Vibration.vibrate(duration: 500);
          return;
        case 2:
          Vibration.vibrate(duration: 1000);
          return;
        case 3:
          player.play('beep.mp3');
          return;
        case 4:
          print('silent');
          return;
      }
    }

    String body = jsonEncode({
      "publicRegistrationId": publicRegistrationId,
      "barCodeReference": jsonDecode(barCodeReference)["ref"]
    });
    print(body);
    try {
      http
          .post(url, body: body, headers: userHeader)
          .then((http.Response response) {
        final int statusCode = response.statusCode;
        print(response.body);
        if (statusCode < 200 || statusCode >= 400) {
          controller.startScanning();
        } else {
          notificate(prefs.getInt('notifications'));
          synchronizeWithBackend();
          Future.delayed(Duration(seconds: 1),
              () => Navigator.popAndPushNamed(context, '/home_page'));
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> getCameras() async {
    final _formKey = GlobalKey<FormState>();
    if (controller != null) return;
    List<CameraDescription> cameras = await availableCameras();
    if (cameras.length > 0) {
      controller = QRReaderController(
          cameras[0], ResolutionPreset.medium, [CodeFormat.qr],
          (dynamic value) {
        controller.stopScanning();
        var controllerData = () {
          if (_formKey.currentState.validate()) {
            _formKey.currentState.save();
          }
          requestCredential(value);
          Navigator.of(context).pop();
        };

        var controllerStopDate = () {
          if (_formKey.currentState.validate()) {
            _formKey.currentState.save();
          }
          controller.startScanning();
          Navigator.of(context).pop();
        };
        print('value');
        print(jsonDecode(value)["ref"]);
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return getAcceptDialog(_formKey, jsonDecode(value)["ref"],
                  controllerData, controllerStopDate, "Scanned Credentials:");
            });
      });
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        controller.startScanning();
      }).catchError((error) {
        print("no cam exist");
      });
    }
    setState(() {
      this.controller = controller;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void toogleCam() {
    if (controller != null && controller.value.isInitialized)
      setState(() {
        useCam = !useCam;
      });
  }

  Future<void> synchronizeWithBackend() async {
    try {
      await platform.invokeMethod('synchronizeWithBackend', {});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    getCameras();
    Widget cardInputWiget = Center(
      child: Form(
          child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(right: 12.0),
            margin: new EdgeInsets.only(right: 50.0, top: 50, left: 50.0),
            child: TextFormField(
              controller: referencController,
              decoration: InputDecoration(
                labelText: 'Card Number',
              ),
              keyboardType: TextInputType.text,
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            width: 100,
            height: 36,
            margin: new EdgeInsets.only(top: 50.0),
            child: RaisedButton(
              textColor: Colors.white,
              color: Colors.blue[900],
              onPressed: () {
                requestCredential('{"ref":"' + referencController.text + '"}');
              },
              child: const Text('ENTER'),
            ),
          ),
        ],
      )),
    );
    if (useCam && controller != null && controller.value.isInitialized) {
      cardInputWiget = SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: QRReaderPreview(controller)),
      );
    }

    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Scan QR Code'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context, false),
          ),
          actions: <Widget>[
            IconButton(
              color: Colors.white,
              icon: Icon(
                useCam ? Icons.keyboard : Icons.camera_alt,
              ),
              onPressed: toogleCam,
            ),
          ]),
      body: cardInputWiget,
    );
  }
}
