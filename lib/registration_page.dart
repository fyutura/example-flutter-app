import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_credential/confirm_registration_page.dart';

class RegistrationPage extends StatefulWidget {
  final String registrationType;
  RegistrationPage(this.registrationType, {Key key}) : super(key: key);

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  static const platform = const MethodChannel('net.plzft.poc_od');

  String registerBy;
  @override
  void initState() {
    super.initState();
    setState(() {
      registerBy = widget.registrationType;
    });
  }

  Future<void> startRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (registerBy == 'Email') {
        prefs.setString('email', _loginController.text);
        print(prefs.getString("email"));
      }
      if (registerBy == 'Phone') {
        prefs.setString('mobile', _loginController.text);
        print(prefs.getString("mobile"));
      }
      final String result = await platform.invokeMethod('StartRegistration', {
        "email": _loginController.text,
        "mobile": _loginController.text,
        "is_mobile": (registerBy == 'Phone') ? 1 : 0,
      });
      print(result);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlzftConfirmRegistrationPage(
              registerBy,
            ),
          ));
    } on PlatformException catch (e) {
      print(e);
    }
  }

  final _loginController = TextEditingController(text: "");
  final globalKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
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
                margin: new EdgeInsets.only(top: 56),
                child: Text(
                  'Registation',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.normal, fontSize: 34),
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: TextFormField(
                        controller: _loginController,
                        decoration: InputDecoration(
                          labelText: widget.registrationType,
                          hintText: registerBy == 'Email'
                              ? 'example@plasticard.de'
                              : '+4934455...',
                        ),
                        keyboardType: registerBy == 'Email'
                            ? TextInputType.emailAddress
                            : TextInputType.phone,
                        validator: registerBy == 'Email'
                            ? ((value) {
                                Pattern pattern =
                                    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                                RegExp regex = new RegExp(pattern);
                                if (!regex.hasMatch(value))
                                  return 'Enter Valid Email';
                                else
                                  return null;
                              })
                            : ((value) {
                                Pattern pattern = r'^\+.*$';
                                RegExp regex = new RegExp(pattern);
                                if (value.length <= 8)
                                  return 'Mobile Number must be of 8 digit';
                                else if (!regex.hasMatch(value))
                                  return 'Enter Valid Phone in international format (with "+" symbol)';
                                else
                                  return null;
                              }),
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 36,
                      child: RaisedButton(
                        textColor: Colors.white,
                        color: Colors.blue[900],
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            startRegistration();
                            globalKey.currentState.showSnackBar(
                                SnackBar(content: Text("Token was sent")));
                          }
                        },
                        child: const Text('ENTER'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  void showSnackbar(BuildContext context) {
    final snackBar = SnackBar(content: Text('Profile saved'));
    globalKey.currentState.showSnackBar(snackBar);
  }
}
