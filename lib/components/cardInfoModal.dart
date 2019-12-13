import 'package:flutter/material.dart';

class InfoModal extends StatefulWidget {
  final Map file;

  InfoModal(this.file, {Key key}) : super(key: key);

  @override
  InfoModalState createState() => new InfoModalState();
}

Widget renderInfoItem(name, value) {
  return Card(
    child: Container(
        decoration: new BoxDecoration(
            border: new Border(
                bottom: new BorderSide(width: 1.0, color: Colors.grey[100]))),
        child: Row(children: <Widget>[
          Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 20),
              width: 100,
              decoration: new BoxDecoration(
                  border: new Border(
                      right:
                          new BorderSide(width: 1.0, color: Colors.grey[100]))),
              child: Text(
                name != null ? '$name' : "Empty",
                textAlign: TextAlign.center,
              )),
          Expanded(
            child: Container(
                padding: EdgeInsets.all(20),
                child: Column(children: [
                  Text(
                    // value.runtimeType is List
                    //     ? value.map((entry) => entry.value)
                    // :
                    value != null ? '$value' : "Empty",
                    overflow: TextOverflow.fade,
                    softWrap: true,
                    maxLines: 2,
                  )
                ])),
          )
        ])),
  );
}

void renderData(data) {}

class InfoModalState extends State<InfoModal> {
  @override
  Widget build(BuildContext context) {
    // final Map<dynamic, dynamic> data = Map.of(widget.file);
    return new Scaffold(
        appBar: new AppBar(
          title: const Text('Card Info'),
        ),
        body: ListView(children: widget.file.entries.map((entry) =>
            // (entry.value.toString().isEmpty ?? true) ??
            renderInfoItem(entry.key, entry.value)).toList()));
  }
}
