import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

void main() {
  runApp(
    MaterialApp(
      title: "Lista de tarefas",
      home: Home(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _itemController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo['title'] = _itemController.text;
      newToDo['ok'] = false;
      _itemController.text = '';
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _toDoList.sort((a, b) {
        if (a['ok'] && !b['ok'])
          return 1;
        else if (!a['ok'] && b['ok'])
          return -1;
        else
          return 0;
      });

      _saveData();
    });

    return Null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Lista de tarefas"),
          centerTitle: true,
          backgroundColor: Colors.blueAccent),
      body: Column(
        children: <Widget>[
          Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(children: <Widget>[
                Expanded(
                  child: TextField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        labelText: "Adicionar nova tarefa",
                        labelStyle: TextStyle(color: Colors.lightBlueAccent),
                      )),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text('Adicionar'),
                  textColor: Colors.white,
                  onPressed: () => _addToDo(),
                ),
              ])),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          )
        ],
      ),
    );
  }

  //Aqui estamos criando uma fun????o modularizada para o c??digo n??o ficar muito
  // poluido dentro do scaffold
  Widget buildItem(BuildContext context, int index) {
    ///Dismissible ?? o widget que permite que a gente arraste um item para a esquerda para deletar o item
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['ok'] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]['ok'] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved['title']} removida!"),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  /// aqui estamos criando uma fun????o privada do tipo Future que nos retorna um File.
  /// Como ?? uma fun????o do tipo fulture temos que especificar que ela ?? uma fun????o ass??ncrona.
  Future<File> _getFile() async {
    ///aqui criamos uma varivale final chamada directory. Nessa vari??vel vamos colocar o diret??rio
    ///do aparelho onde nosso arquivo File ser?? salvo. Fazemos isso porque cada sistema operacional
    /// android ou ios t??m caminhos e permiss??es diferentes para salvar as informa????es que passamos.
    /// ?? nesse sentido que a biblioteca path_provider nos ajuda, a partir do m??todo getApplicationSupportDirectory()
    /// podemos pegar o caminho daquele aparelho em espec??fico.
    ///
    /// Como essa informa????o vai ser pega no futuro ent??o temos que colocar o await
    final directory = await getApplicationSupportDirectory();

    ///aqui depois de pegarmos o diret??rio retornamos um objeto do tipo File
    ///com o diret??rio e a extens??o desse File.
    return File("${directory.path}/data.json");
  }

  //aqui criamos uma fun????o do tipo future que retorna um File que tamb??m ?? uma fun????o async.
  Future<File> _saveData() async {
    ///aqui criamos uma variavel que vai receber as informa????es da lista _toDoList que estamos
    ///transformando para o tipo json
    String data = json.encode(_toDoList);

    //aqui criamos uma variavel do tipo final que pega o arquivo que criamos
    final file = await _getFile();

    // depois de pegar o arquivo pegamos as informa????es de data e escrevemos dentro dele como string
    return file.writeAsString(data);
  }

  //aqui criamos uma fun????o future que retorna uma string
  Future<String> _readData() async {
    //aqui iniciamos um try catch
    try {
      //aqui criamos uma variavel do tipo final que pega o arquivo que criamos
      final file = await _getFile();

      //aqui retornamos o arquivo que pegamos para ler como string
      return file.readAsString();
    } catch (e) {
      // se der algum erro no try retornamos uma mensagem de erro.
      return null;
    }
  }
}
