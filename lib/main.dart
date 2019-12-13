import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'init_page.dart';
import 'definitions.dart';
import 'barcode_scanner_page.dart';
import 'welcome_page.dart';
import 'home_page.dart';

void main() {
  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((_) => runApp(new MyApp()));
}

var context;
const platform = const MethodChannel('net.plzft.poc_od');

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context = context;

    return MaterialApp(
        title: 'Plastic Card ZFT',
        theme: ThemeData(
            primaryColor: MaterialColor(0xFF003387, colorMap),
            primarySwatch: MaterialColor(0xFF003387, colorMap)),
        home: InitPage(),
        routes: <String, WidgetBuilder>{
          '/barcode_scanner': (BuildContext context) => BarcodeScanner(),
          '/welcome_page': (BuildContext context) => WelcomePage(),
          '/home_page': (BuildContext context) => HomePage(),
        });
  }
}
