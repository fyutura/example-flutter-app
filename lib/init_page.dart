import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitPage extends StatefulWidget {
  @override
  InitPageState createState() => InitPageState();
}

class InitPageState extends State<InitPage> {
  @override
  void initState() {
    super.initState();

    setState(() {
      _isRegisteredToBackend = null;
    });

    initIsRegisteredToBackend();
    initVibrateState();
  }

  void initVibrateState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('notifications', 1);
  }

  static const platform = const MethodChannel('net.plzft.poc_od');

  bool _isRegisteredToBackend = false;

  bool isRegisteredToBackend() {
    return _isRegisteredToBackend;
  }

  initIsRegisteredToBackend() {
    platform.invokeMethod('isRegisteredToBackend').then((result) {
      if (!result && _isRegisteredToBackend != result) {
        log('_isRegisteredToBackend: $result');
        setState(() {
          _isRegisteredToBackend = result;
        });
        Navigator.popAndPushNamed(context, '/welcome_page');
      }
      if (result) {
        Navigator.popAndPushNamed(context, '/home_page');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            new CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
