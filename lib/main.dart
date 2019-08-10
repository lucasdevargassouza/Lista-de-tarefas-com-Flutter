import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(
      title: "Lista de tarefas",
      home: Home(),
    ));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController itemToAddController = TextEditingController();
  List _todoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  void _addItemTodoList() {
    setState(() {
      _todoList.add({"title": itemToAddController.text, "ok": false});
    });
    itemToAddController.clear();
  }

  void _showSnackBar(myContext, label, onDesfazerPress) {
    final snack = SnackBar(
      content: Text(label),
      action: SnackBarAction(
        label: "Desfazer",
        onPressed: onDesfazerPress,
      ),
      duration: Duration(seconds: 2),
    );
    Scaffold.of(myContext).removeCurrentSnackBar();
    Scaffold.of(myContext).showSnackBar(snack);
  }

  Future<Null> _onRefresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _todoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });

    return null;
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    _readData().then((value) {
      setState(() {
        _todoList = json.decode(value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Lista de tarefas"),
        ),
        body: Container(
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: itemToAddController,
                        decoration: InputDecoration(
                          labelText: "Nova tarefa",
                        ),
                      ),
                    ),
                    RaisedButton(
                      child: Text("ADD"),
                      onPressed: _addItemTodoList,
                      textColor: Colors.white,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _todoList.length,
                    itemBuilder: itemBuilder,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget itemBuilder(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      onDismissed: (indexToRemove) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPos = index;

          _todoList.removeAt(index);
          _saveData();

          _showSnackBar(
            context,
            "Tarefa \"${_lastRemoved["title"]}\" removida!",
            () { setState(() {
              _todoList.insert(_lastRemovedPos, _lastRemoved);
              _saveData();
            });},
          );
        });
      },
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_todoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (bool value) {
          setState(() {
            _todoList[index]["ok"] = value;
            _saveData();
          });
        },
      ),
    );
  }

}
