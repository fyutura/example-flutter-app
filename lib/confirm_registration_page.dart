import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class PlzftConfirmRegistrationPage extends StatefulWidget {
  final String registerBy;
  PlzftConfirmRegistrationPage(this.registerBy, {Key key}) : super(key: key);

  @override
  PlzftConfirmRegistrationPageState createState() =>
      PlzftConfirmRegistrationPageState();
}

class PlzftConfirmRegistrationPageState
    extends State<PlzftConfirmRegistrationPage> {
  static const platform = const MethodChannel('net.plzft.poc_od');

  String registerBy;
  String pin;
  @override
  void initState() {
    super.initState();
    setState(() {
      registerBy = widget.registerBy;
      pin = '';
    });
  }

  Future<void> confrimRegistration(pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', pin);
      await platform.invokeMethod(
          'completeRegistration', {"token": prefs.getString("token")});
    } on PlatformException catch (e) {
      log('error: $e');
    }
  }

  Future<void> isRegisteredToBackend() async {
    var response;
    try {
      response = await platform.invokeMethod('isRegisteredToBackend');
    } on PlatformException catch (e) {
      print(e);
    }
    if (response == true) {
      Navigator.popAndPushNamed(context, '/home_page');
    }
    if (response == false) {
      globalKey.currentState.showSnackBar(
          SnackBar(content: Text("Something went wrong. Please try again 😭")));
    }
  }

  Future<void> synchronizeWithBackend() async {
    try {
      await platform.invokeMethod('synchronizeWithBackend', {});
    } on PlatformException catch (e) {
      print(e);
    }
  }

  void pressEnterKey() {
    if (_formKey.currentState.validate()) {
      print(pin);
      confrimRegistration(pin);
      globalKey.currentState
          .showSnackBar(SnackBar(content: Text("Token was sent")));
    }
  }

  Future<dynamic> myUtilsHandler(MethodCall methodCall) async {
    if (methodCall.method == 'backendRegistrationFinishedDoneEvent') {
      isRegisteredToBackend();
    }
  }

  final globalKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _confirmCode = TextEditingController(text: "");

  @override
  Widget build(BuildContext context) {
    platform.setMethodCallHandler(myUtilsHandler);
    return MaterialApp(
      home: Scaffold(
          key: globalKey,
          appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              leading: IconButton(
                color: Color(0xFF1E88E5),
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context, false),
              )),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: new EdgeInsets.only(right: 50.0, left: 50.0, top: 56),
                child: registerBy == 'Email'
                    ? Text(
                        'We were send you on Email confirmation code. Please enter a code below',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.normal, fontSize: 14),
                      )
                    : Text(
                        'We were send you on SMS confirmation code . Please enter a code below',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    Container(
                        width: 200,
                        margin: new EdgeInsets.only(
                            right: 20.0, left: 20.0, top: 50),
                        child: TextFormField(
                          autofocus: true,
                          obscureText: true,
                          keyboardType: TextInputType.phone,
                          maxLength: 6,
                          controller: _confirmCode,
                          onChanged: (String newVal) {
                            if (newVal.length == 6) {
                              setState(() {
                                pin = _confirmCode.text;
                              });
                            }
                          },
                          onFieldSubmitted: (value) {
                            print(value);
                            pressEnterKey();
                          },
                          style: TextStyle(
                              fontSize: 25.0, fontWeight: FontWeight.w500),
                        )
                        //  PinView(
                        //     count: 6,
                        //     autoFocusFirstField: true,
                        //     margin: EdgeInsets.all(2.5),
                        //     obscureText: true,
                        //     style: TextStyle(
                        //         fontSize: 19.0, fontWeight: FontWeight.w500),
                        //     submit: (String pinCode) {
                        //       setState(() {
                        //         pin = pinCode;
                        //       });
                        //     }),
                        ),
                    FlatButton(
                      textColor: Colors.blue[900],
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          print(pin);
                          confrimRegistration(pin);
                          globalKey.currentState.showSnackBar(
                              SnackBar(content: Text("Token was sent")));
                        }
                      },
                      child: const Text(
                        'CONFIRM',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
