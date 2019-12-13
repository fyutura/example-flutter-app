import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audio_cache.dart';

import 'definitions.dart';
import 'package:mobile_credential/components/cardInfoModal.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const platform = const MethodChannel('net.plzft.poc_od');

  final pwController = TextEditingController(text: "");
  final player = AudioCache();

  var files;
  var openTime;
  var timeout = 0;
  var isOpen = false;
  var filesObject;
  var vibrate = true;
  var fileList;
  var cardsList;
  var fileInfo;
  var notifications;
  var publicRegistrationId;
  var beep = 'beep.mp3';

  IconData notificationsIcon = Icons.notifications_active;

  @override
  void initState() {
    super.initState();
    synchronizeWithBackend();
    WidgetsBinding.instance.addObserver(this);
    initNotificationsState();
    platform.setMethodCallHandler(myUtilsHandler);
  }

  void initNotificationsState() async {
    final prefs = await SharedPreferences.getInstance();
    var initNotifications = prefs.getInt('notifications');
    setState(() {
      notifications = initNotifications;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("--------------------------------------------- " + state.toString());
    if (state == AppLifecycleState.resumed) {
      if (isOpen) {
        var now = new DateTime.now();

        openTime.add(new Duration(seconds: timeout));

        print(now);
        print(openTime);
        var difference = now.difference(openTime);
        print(difference.toString() + " s");
        if (difference.inSeconds >= 10) {
          print("wuerde schliesen");
          Navigator.of(context).pop(true);
          setState(() {
            isOpen = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> isRegisteredToBackend() async {
    try {
      await platform.invokeMethod('isRegisteredToBackend');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> synchronizeWithBackend() async {
    try {
      await platform.invokeMethod('synchronizeWithBackend', {});
      getAllFiles();
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> unregister() async {
    try {
      await platform.invokeMethod('unregister', {});
    } on PlatformException catch (e) {
      print(e);
    }
    await synchronizeWithBackend();
    await isRegisteredToBackend();
    Future.delayed(
        Duration(seconds: 2), () => Navigator.popAndPushNamed(context, "/"));
  }

  Future<void> deleteFile(fileIdHex) async {
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
    String url = "http://legicmobile.plasticard.de:80/v1/RemoveCredentials";

    Map<String, String> userHeader = {
      "Content-type": "application/json",
      "Access-Control-Allow-Origin": "*"
    };
    String body = jsonEncode({
      "publicRegistrationId": publicRegistrationId,
      "fileId": fileIdHex,
    });

    try {
      http
          .post(url, body: body, headers: userHeader)
          .then((http.Response response) {
        final int statusCode = response.statusCode;
        print("staus vom ws: " + statusCode.toString() + response.body);
        if (statusCode < 200 || statusCode >= 400) {
        } else {
          synchronizeWithBackend();
        }
      });
    } catch (e) {
      print(e.toString() + e + e.data);
    }
    synchronizeWithBackend();
    Navigator.of(context).pop();
    getAllFiles();
    synchronizeWithBackend();
  }

  Future<void> toogleActivation(fileIdHex) async {
    try {
      await platform
          .invokeMethod('toggleFileActivation', {"fileIdHex": fileIdHex});
      getAllFiles();
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> getAllFiles() async {
    try {
      final String result = await platform.invokeMethod('getAllFiles', {});
      final prefs = await SharedPreferences.getInstance();
      var jsonArray = json.decode(result);
      setState(() {
        fileList = jsonArray;
      });
      List<String> aktiveHexIdsList = new List();

      jsonArray.forEach((elem) async {
        if (elem["isActivated"]) aktiveHexIdsList.add(elem["fileIdHex"]);
        await getInfo(
            '0' + elem['displayName'].toString().split("_")[0].substring(1));
        elem.addAll(fileInfo['fileDefinition']);
      });
      String aktiveHexIds = aktiveHexIdsList.join(",");
      prefs.setString("aktiveHexIds", aktiveHexIds);

      var boxes = getListViewFiles(
          jsonArray, toogleActivation, deleteFile, context, _openInfoModal);
      setState(() {
        filesObject = boxes;
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        filesObject = [];
      });
    }
  }

  Future<void> getInfo(fileIdHex) async {
    final prefs = await SharedPreferences.getInstance();
    log('getInfo: "$fileIdHex"');
    if (prefs.getString('registrationType') == 'Email') {
      setState(() {
        publicRegistrationId = 'email#' + prefs.getString('email');
      });
    } else {
      setState(() {
        publicRegistrationId = prefs.getString('mobile');
      });
    }
    String url = "http://legicmobile.plasticard.de:80/v1/GetCardInfo";
    Map<String, String> userHeader = {
      "Content-type": "application/json",
      "Access-Control-Allow-Origin": "*"
    };
    String body = jsonEncode({
      "publicRegistrationId": publicRegistrationId,
      "barCodeReference": fileIdHex,
    });

    try {
      await http
          .post(url, body: body, headers: userHeader)
          .then((http.Response response) {
        var fileInfoResponse = json.decode(response.body);
        setState(() {
          fileInfo = fileInfoResponse;
        });
        return;
      });
    } catch (e) {
      print("ELSE staus vom ws: " + e.toString() + e + e.data);
    }
  }

  void _showLogOutDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: new Text("Are you sure you want to log out?"),
              content:
                  new Text("This will reset you app and delete you profile"),
              actions: <Widget>[
                new FlatButton(
                  child: new Text("CANCEL"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                new FlatButton(
                  child: new Text(
                    "LOG OUT",
                    style: TextStyle(color: Colors.red[500]),
                  ),
                  onPressed: () {
                    unregister();
                  },
                ),
              ]);
        });
  }

  void _openInfoModal(file) {
    Navigator.of(context).push(new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return new InfoModal(file);
        },
        fullscreenDialog: true));
  }

  Future<void> sendRequestAnswer(flag, doorMode) async {
    print("start send answer");
    try {
      final String result = await platform.invokeMethod(
          'sendAccessRequestAnswer', {"answer": flag, "doorMode": doorMode});
      print(result);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> sendRequestAnswerWithPin(flag, doorMode) async {
    final prefs = await SharedPreferences.getInstance();

    var msg = prefs.getString("doorPin");
    if (!flag) msg = "0000";
    print("Pin: " + msg + "  " + flag.toString());
    try {
      final String result = await platform.invokeMethod(
          'sendRequestAnswerWithPin',
          {"answer": flag, "pin": msg, 'doorMode': doorMode});
      print(result);
      prefs.setString('doorPin', null);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> sendRequestAnswerWithTwoPin(flag, doorMode) async {
    final prefs = await SharedPreferences.getInstance();

    var globalPin = prefs.getString("doorPin");
    var secondMsg = prefs.getString('secondPersonalPin');
    if (!flag) globalPin = "0000";
    if (!flag) secondMsg = "0000";

    print("sendRequestAnswerWithTwoPin: " +
        globalPin +
        secondMsg +
        "  " +
        flag.toString());
    try {
      final String result =
          await platform.invokeMethod('sendRequestAnswerWithTwoPin', {
        'answer': flag,
        'globalPin': globalPin,
        'personalPin': secondMsg,
        'doorMode': doorMode
      });
      print(result);
      prefs.setString('doorPin', null);
      prefs.setString('secondPersonalPin', null);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> updateFileState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String aktiveHexIds = prefs.getString("aktiveHexIds");
      if (aktiveHexIds == null) {
        aktiveHexIds = "";
      }
      await platform
          .invokeMethod('initFileState', {"aktiveHexIds": aktiveHexIds});
      getAllFiles();
    } on PlatformException catch (e) {
      print(e);
    }
  }

  void notificationsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notifications = notifications != 4 ? notifications + 1 : 0;
    });
    await prefs.setInt(
        'notifications', notifications != 4 ? notifications + 1 : 0);
    notificationEnable(notifications);
  }

  void notificationEnable(notifications) async {
    switch (notifications) {
      case 1:
        vibratingAndSound();
        return;
      case 2:
        sounding();
        return;
      case 3:
        vibrating();
        return;
      case 4:
        print('silent');
        silenting();
        return;
    }
  }

  void vibrating() {
    Vibration.vibrate(duration: 1000);
    print('vibrating');
    setState(() {
      notificationsIcon = Icons.vibration;
    });
  }

  void vibratingAndSound() {
    Vibration.vibrate(duration: 500);
    player.play('beep.mp3');
    print('vibratingAndSound');
    setState(() {
      notificationsIcon = Icons.notifications_active;
    });
  }

  void sounding() {
    print('sounding');
    player.play('beep.mp3');
    setState(() {
      notificationsIcon = Icons.notifications;
    });
  }

  void silenting() {
    print('sounding');
    setState(() {
      notificationsIcon = Icons.notifications_off;
    });
  }

  Future<dynamic> myUtilsHandler(MethodCall methodCall) async {
    if (methodCall.method == 'backendFileChangedEvent') {
      print('deleted or added file');
      getAllFiles();
    }
    if (methodCall.method == 'lsMessageEvent') {
      notificationEnable(notifications);

      print('!!!!!!!!lsMessageEvent!!!!!!' + methodCall.arguments);
      var doorMode = methodCall.arguments.substring(4, 6);
      var timeOut = int.parse(methodCall.arguments.substring(10, 12));
      var globalPinLength = int.parse(methodCall.arguments.substring(10, 11));
      var personalPinLength = int.parse(methodCall.arguments.substring(11, 12));

      log('TimeOut:');
      print(timeOut);
      print('DoorMode: ' + doorMode);
      print('PIN LENGHT:');
      print(globalPinLength + personalPinLength);

      if (doorMode == '80' || doorMode == 'C0') {
        print('RequestAccess!!!!!!');

        final _formKey = GlobalKey<FormState>();
        var sendFlag = (flag) {
          if (_formKey.currentState.validate()) {
            _formKey.currentState.save();
          }
          sendRequestAnswer(flag, doorMode);
          Navigator.of(context).pop();
        };

        print("is open : " + isOpen.toString());
        if (isOpen == true) {
          Navigator.of(context).pop(true);
        }
        setState(() {
          isOpen = true;
          openTime = new DateTime.now();
        });
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              Future.delayed(Duration(seconds: timeOut), () {
                if (isOpen) {
                  sendFlag(false);
                  // Navigator.of(context).pop(true);
                  setState(() {
                    isOpen = false;
                  });
                } else {
                  print("not pop");
                }
              });
              return getAcceptDialog(_formKey, "Should the door be opened?",
                  () {
                setState(() {
                  isOpen = false;
                });
                sendFlag(true);
              }, () {
                setState(() {
                  isOpen = false;
                });
                sendFlag(false);
              }, "");
            });
      } //req mode

      if (doorMode == 'A0' || doorMode == 'E0') {
        print('Request GLOBAL Pin!!!!!!');

        final _formKey = GlobalKey<FormState>();
        var sendFlag = (flag) {
          if (_formKey.currentState.validate()) {
            _formKey.currentState.save();
          }
          sendRequestAnswerWithPin(flag, doorMode);
          Navigator.of(context).pop();
        };

        print("is open : " + isOpen.toString());
        if (isOpen == true) {
          Navigator.of(context).pop(true);
        }
        pwController.text = "";
        setState(() {
          isOpen = true;
        });
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              Future.delayed(Duration(seconds: timeOut), () {
                if (isOpen) {
                  sendFlag(false);
                  // Navigator.of(context).pop(true);
                  setState(() {
                    isOpen = false;
                  });
                } else {
                  print("not pop");
                }
              });
              return getPinDialog(_formKey, "The door requires the global pin",
                  () {
                setState(() {
                  isOpen = false;
                });
                sendFlag(true);
              }, () {
                setState(() {
                  isOpen = false;
                });
                sendFlag(false);
              }, "", pwController, globalPinLength);
            });
      } //Global Pin

      if (doorMode == '90' || doorMode == 'D0') {
        print('Request Personal Pin!!!!!!');

        final _formKey = GlobalKey<FormState>();
        var sendFlag = (flag) {
          if (_formKey.currentState.validate()) {
            _formKey.currentState.save();
          }
          sendRequestAnswerWithPin(flag, doorMode);
          Navigator.of(context).pop();
        };

        print("is open : " + isOpen.toString());
        if (isOpen == true) {
          Navigator.of(context).pop(true);
        }
        pwController.text = "";
        setState(() {
          isOpen = true;
        });
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              Future.delayed(Duration(seconds: timeOut), () {
                if (isOpen) {
                  sendFlag(false);
                  // Navigator.of(context).pop(true);
                  setState(() {
                    isOpen = false;
                  });
                } else {
                  print("not pop");
                }
              });
              return getPinDialog(
                  _formKey, "The door requires the personal pin", () {
                setState(() {
                  isOpen = false;
                });
                sendFlag(true);
              }, () {
                setState(() {
                  isOpen = false;
                });
                sendFlag(false);
              }, "", pwController, personalPinLength);
            });
      } //Personal pin 90 D0

      if (doorMode == 'B0' || doorMode == 'F0') {
        print('Request Global + Personal Pin!!!!!!');

        final _formKey = GlobalKey<FormState>();
        var sendFlag = (flag) {
          if (_formKey.currentState.validate()) {
            _formKey.currentState.save();
          }
          sendRequestAnswerWithTwoPin(flag, doorMode);
          Navigator.of(context).pop();
        };

        print("is open : " + isOpen.toString());
        if (isOpen == true) {
          Navigator.of(context).pop(true);
        }
        pwController.text = "";
        setState(() {
          isOpen = true;
        });
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              Future.delayed(Duration(seconds: timeOut), () {
                if (isOpen) {
                  sendFlag(false);
                  // Navigator.of(context).pop(true);
                  setState(() {
                    isOpen = false;
                  });
                } else {
                  print("not pop");
                }
              });
              return getTwoPinDialog(
                  context, _formKey, "The door requires the global pin", () {
                setState(() {
                  isOpen = false;
                });
                sendFlag(true);
              }, () {
                setState(() {
                  isOpen = false;
                });
                sendFlag(false);
              }, "and the personal pin", pwController, globalPinLength,
                  personalPinLength);
            });
      } // Personal and Global Pin B0 F0

    }
  }

  @override
  Widget build(BuildContext context) {
    platform.setMethodCallHandler(myUtilsHandler);
    return WillPopScope(
        onWillPop: () async {
          try {
            final String result = await platform.invokeMethod('minimize', {});
            print(result);
          } on PlatformException catch (e) {
            print(e);
          }
          return false;
        },
        child: Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.blue[900],
                elevation: 0.0,
                title: Text('Cards'),
                actions: <Widget>[
                  IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.add),
                    onPressed: () =>
                        Navigator.pushNamed(context, "/barcode_scanner"),
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(
                      Icons.refresh,
                    ),
                    onPressed: () => synchronizeWithBackend(),
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(notificationsIcon),
                    onPressed: () => notificationsSettings(),
                  ),
                  IconButton(
                      color: Colors.white,
                      icon: Icon(Icons.exit_to_app),
                      onPressed: () {
                        _showLogOutDialog();
                      }),
                ]),
            body: filesObject));
  }
}
