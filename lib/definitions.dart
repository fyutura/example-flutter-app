import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<int, Color> colorMap = {
  50: Color.fromRGBO(0, 51, 135, .1),
  100: Color.fromRGBO(0, 51, 135, .2),
  200: Color.fromRGBO(0, 51, 135, .3),
  300: Color.fromRGBO(0, 51, 135, .4),
  400: Color.fromRGBO(0, 51, 135, .5),
  500: Color.fromRGBO(0, 51, 135, .6),
  600: Color.fromRGBO(0, 51, 135, .7),
  700: Color.fromRGBO(0, 51, 135, .8),
  800: Color.fromRGBO(0, 51, 135, .9),
  900: Color.fromRGBO(0, 51, 135, 1),
};
Color appDarkGreyColor = colorMap[900];
Color appGreyColor = colorMap[800];

String cardsSVG = 'assets/cards.svg';
Widget cardsWidget =
    new SvgPicture.asset(cardsSVG, height: 128.0, semanticsLabel: 'Cards');

Widget getListViewFiles(files, onClick, onClickDel, context, _openInfoModal) {
  List<Widget> tmp = new List<Widget>();
  if (files != null)
    files.forEach((elem) {
      Widget tmpFile =
          getFileContainer(elem, onClick, onClickDel, _openInfoModal);
      tmp.add(tmpFile);
    });
  if (tmp.length == 0) {
    tmp.add(Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.2,
          ),
          padding: new EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.3,
            vertical: 10,
          ),
          child: Text(
            'Please add your card',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 24,
                color: Color.fromRGBO(190, 213, 252, 1)),
          ),
        ),
        cardsWidget
      ],
    ));
  }

  return ListView(
    children: tmp,
  );
}

Widget getFileContainer(file, onClick, onClickDel, _openInfoModal) {
  var displayedName = "Credential for project | " +
      file["displayName"].toString().split("_")[1];
  return Card(
    key: ValueKey(file["displayName"]),
    elevation: 0.0,
    margin: new EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
    child: Container(
      decoration: new BoxDecoration(
          border: new Border(
              bottom: new BorderSide(width: 1.0, color: Colors.grey[100]))),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
        leading: Container(
            padding: EdgeInsets.only(right: 0.0),
            child: Hero(
                tag: "avatar_" + file["displayName"],
                child: SizedBox(
                    width: 30,
                    child: FlatButton(
                      child: Icon(
                        file["isActivated"] ? Icons.check_circle : Icons.error,
                        color: file["isActivated"] ? Colors.green : Colors.red,
                        size: 30.0,
                      ),
                      padding: EdgeInsets.all(0.0),
                      shape: new CircleBorder(),
                      onPressed: () {
                        onClick(file["fileIdHex"]);
                      },
                    )))),
        title: Container(
            margin: EdgeInsets.only(bottom: 15),
            child: Text(
              displayedName,
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            )),
        trailing: Container(
            padding: EdgeInsets.all(0.0),
            margin: EdgeInsets.all(0.0),
            decoration: new BoxDecoration(
                border: new Border(
                    left: new BorderSide(width: 1.0, color: Colors.grey[100]))),
            child: SizedBox(
              width: 30,
              child: PopupMenuButton<String>(
                  itemBuilder: (context) => [
                        PopupMenuItem(
                            child: new InkWell(
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                      title: new Text(
                                          "Are you sure you want to delete file " +
                                              file["displayName"]
                                                  .toString()
                                                  .split("_")[1] +
                                              "?"),
                                      content: new Text("This will delete " +
                                          "AN: " +
                                          file["displayName"]
                                              .toString()
                                              .split("_")[0] +
                                          " file from your profile"),
                                      actions: <Widget>[
                                        new FlatButton(
                                          child: new Text("CANCEL"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        new FlatButton(
                                          child: new Text(
                                            "DELETE",
                                            style: TextStyle(
                                                color: Colors.red[500]),
                                          ),
                                          onPressed: () {
                                            onClickDel(file["fileIdHex"]);
                                          },
                                        ),
                                      ]);
                                });
                          },
                          child: Row(
                            children: <Widget>[
                              Container(
                                  margin: EdgeInsets.only(right: 10),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.grey[600],
                                  )),
                              Text(
                                "Delete",
                                style: TextStyle(color: Colors.grey[600]),
                              )
                            ],
                          ),
                        )),
                        PopupMenuItem(
                            child: new InkWell(
                          onTap: () => {},
                          child: Row(
                            children: <Widget>[
                              Container(
                                  margin: EdgeInsets.only(right: 10),
                                  child: Icon(Icons.edit,
                                      color: Colors.grey[600])),
                              Text(
                                "Edit",
                                style: TextStyle(color: Colors.grey[600]),
                              )
                            ],
                          ),
                        )),
                        PopupMenuItem(
                            child: new InkWell(
                          onTap: () => _openInfoModal(file),
                          child: Row(
                            children: <Widget>[
                              Container(
                                  margin: EdgeInsets.only(right: 10),
                                  child: Icon(Icons.info,
                                      color: Colors.grey[600])),
                              Text(
                                "Info",
                                style: TextStyle(color: Colors.grey[600]),
                              )
                            ],
                          ),
                        )),
                      ]),
            )),
        subtitle: Row(
          children: <Widget>[
            new Flexible(
                child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                  RichText(
                    text: TextSpan(
                      text:
                          "AN: " + file["displayName"].toString().split("_")[0],
                      style: TextStyle(
                          color: Colors.blue[900], fontWeight: FontWeight.w500),
                    ),
                    maxLines: 3,
                    softWrap: true,
                  )
                ])),
          ],
        ),
      ),
    ),
  );
}

Widget getAcceptDialog(
    GlobalKey<FormState> _formKey, String text, pressOk, pressReject, title) {
  return AlertDialog(
    content: Form(
      key: _formKey,
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(title),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(text),
        ),
        Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              FlatButton(
                  child: new Text(
                    "CANCEL",
                    style: TextStyle(color: Colors.red[500]),
                  ),
                  onPressed: pressReject),
              FlatButton(
                  child: new Text(
                    "ENTER",
                    style: TextStyle(color: Colors.green[500]),
                  ),
                  onPressed: pressOk),
            ])),
      ]),
    ),
  );
}

Widget getPinDialog(GlobalKey<FormState> _formKey, String text, pressOk,
    pressReject, String title, TextEditingController pwController, passLength) {
  Future<void> sendDoorPin(pinSender) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString("doorPin") != null) {
        pinSender();
      }
    } catch (e) {
      print(e);
    }
  }

  return AlertDialog(
    content: Form(
      key: _formKey,
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Padding(
          padding: EdgeInsets.all(0.0),
          child: Text(title),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(text),
        ),
        Padding(
            padding: EdgeInsets.all(8.0),
            child: TextFormField(
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.phone,
              maxLength: passLength,
              onChanged: (String pinCode) async {
                if (pinCode.length == passLength) {
                  try {
                    final prefs = await SharedPreferences.getInstance();

                    prefs.setString('doorPin', pinCode);
                    print(' pin' + pinCode);
                  } catch (e) {
                    print(e);
                  }
                }
              },
              onFieldSubmitted: (value) {
                sendDoorPin(pressOk());
              },
              style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.w500),
            )),
        Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              FlatButton(
                  child: new Text(
                    "CANCEL",
                    style: TextStyle(color: Colors.red[500]),
                  ),
                  onPressed: pressReject),
              FlatButton(
                child: new Text(
                  "ENTER",
                  style: TextStyle(color: Colors.green[500]),
                ),
                onPressed: () {
                  sendDoorPin(pressOk());
                },
              ),
            ])),
      ]),
    ),
  );
}

Widget getTwoPinDialog(
    context,
    GlobalKey<FormState> _formKey,
    String text,
    pressOk,
    pressReject,
    String title,
    TextEditingController pwController,
    globalPassLength,
    personalPassLength) {
  Future<void> sendDoorPin(pinSender) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString("doorPin") != null &&
          prefs.getString("secondPersonalPin") != null) {
        pinSender();
      }
    } catch (e) {
      print(e);
    }
  }

  final FocusNode _globalInput = FocusNode();
  final FocusNode _personalInput = FocusNode();

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  return AlertDialog(
    content: Form(
      key: _formKey,
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(text),
        ),
        Padding(
            padding: EdgeInsets.all(8.0),
            child: TextFormField(
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.phone,
              maxLength: globalPassLength,
              focusNode: _globalInput,
              textInputAction: TextInputAction.next,
              onChanged: (String pinCode) async {
                if (pinCode.length == globalPassLength) {
                  try {
                    final prefs = await SharedPreferences.getInstance();

                    prefs.setString('doorPin', pinCode);
                    print('pin' + pinCode);
                  } catch (e) {
                    print(e);
                  }
                }
              },
              onFieldSubmitted: (term) {
                _fieldFocusChange(context, _globalInput, _personalInput);
              },
              style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.w500),
            )),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(title),
        ),
        Padding(
            padding: EdgeInsets.all(8.0),
            child: TextFormField(
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.phone,
              maxLength: personalPassLength,
              focusNode: _personalInput,
              onChanged: (String secondPersonalPin) async {
                if (secondPersonalPin.length == personalPassLength) {
                  try {
                    final prefs = await SharedPreferences.getInstance();

                    prefs.setString('secondPersonalPin', secondPersonalPin);
                    print('second pin' + secondPersonalPin);
                  } catch (e) {
                    print(e);
                  }
                }
              },
              onFieldSubmitted: (value) {
                sendDoorPin(pressOk());
              },
              style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.w500),
            )),
        Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              FlatButton(
                  child: new Text(
                    "CANCEL",
                    style: TextStyle(color: Colors.red[500]),
                  ),
                  onPressed: pressReject),
              FlatButton(
                child: new Text(
                  "ENTER",
                  style: TextStyle(color: Colors.green[500]),
                ),
                onPressed: () {
                  sendDoorPin(pressOk());
                },
              ),
            ])),
      ]),
    ),
  );
}

Widget getLogEntryContainer(logEnty, index) {
  var icon = Icons.notifications;
  return Card(
    key: ValueKey(index),
    elevation: 8.0,
    margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
    child: Container(
      decoration: BoxDecoration(color: Colors.grey[500]),
      child: ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
              padding: EdgeInsets.only(right: 12.0),
              decoration: new BoxDecoration(
                  border: new Border(
                      right:
                          new BorderSide(width: 1.0, color: Colors.grey))), //
              child: Hero(
                  tag: "avatar_" + index.toString(),
                  child: InkWell(
                    child: Icon(
                      icon,
                      color: Colors.grey,
                      size: 30.0,
                    ),
                    onTap: () {},
                  ))),
          title: Text(
            logEnty["logType"],
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(children: <Widget>[
            Row(
              children: <Widget>[
                new Flexible(
                    child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                      RichText(
                        text: TextSpan(
                          text: logEnty["logMessage"],
                          style: TextStyle(color: Colors.grey),
                        ),
                        maxLines: 3,
                        softWrap: true,
                      )
                    ])),
              ],
            ),
            Row(
              children: <Widget>[
                new Flexible(
                    child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                      RichText(
                        text: TextSpan(
                          text: logEnty["status"] + " " + logEnty["time"],
                          style: TextStyle(color: Colors.grey),
                        ),
                        maxLines: 3,
                        softWrap: true,
                      )
                    ])),
              ],
            ),
          ])),
    ),
  );
}

Widget getListLogEntrys(entrys) {
  List<Widget> tmp = new List<Widget>();
  print(entrys);
  if (entrys != null) {
    var index = 0;
    for (var element in entrys) {
      tmp.add(getLogEntryContainer(element, index));
      index++;
    }
  }
  tmp = tmp.reversed.toList();
  return ListView(
    padding: const EdgeInsets.only(top: 20.0),
    children: tmp,
  );
}
