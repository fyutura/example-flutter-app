import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_credential/registration_page.dart';

class WelcomePage extends StatefulWidget {
  @override
  WelcomePageState createState() => WelcomePageState();
}

class WelcomePageState extends State<WelcomePage> {
  static const platform = const MethodChannel('net.plzft.poc_od');

  var registrationType;

  @override
  void initState() {
    super.initState();

    setState(() {
      registrationType = null;
    });
  }

  Future<void> _chooseRegistrationType(registrationType) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      registrationType = registrationType;
    });
    prefs.setString('registrationType', registrationType);
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationPage(
            registrationType,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/lines.png"), fit: BoxFit.cover)),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: Image.asset(
                    'assets/Logo_Plasticard_RGB.png',
                    scale: 1,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 87),
                  height: 36,
                  width: 288,
                  child: RaisedButton(
                    textColor: Colors.white,
                    color: Color(0xFF1E88E5),
                    onPressed: () {
                      _chooseRegistrationType('Email');
                    },
                    child: const Text('REGISTRATION BY EMAIL'),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  height: 36,
                  width: 288,
                  child: RaisedButton(
                    textColor: Colors.white,
                    color: Color(0xFF1E88E5),
                    onPressed: () {
                      _chooseRegistrationType('Phone');
                    },
                    child: const Text('REGISTRATION BY PHONE'),
                  ),
                )
              ],
            ))),
      ),
    );
  }
}
