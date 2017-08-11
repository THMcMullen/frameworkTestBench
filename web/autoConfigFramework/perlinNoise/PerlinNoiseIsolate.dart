import '../utils.dart';
import 'dart:html';
import 'dart:isolate';
import 'dart:async';
import 'dart:web_gl';
import 'perlinCalc.dart' as perlinCalc;

import 'package:vector_math/vector_math.dart';

main(List<String> args, SendPort sendPort) {
  ReceivePort receivePort = new ReceivePort();
  //receivePort.timeout(const Duration(milliseconds: 0));
  //String isolateID = args[0];
  sendPort.send(receivePort.sendPort);

  int x;
  int y;
  int tileResolution;
  List _elements;
  List<List<int>> grid;


  updatePerlinNoise(change){

    List _positions = new List();
    List _normals = new List();
    List _posToSend = new List();

    for (double i = 0.0; i < grid.length-1; i++) {
      for (double j = 0.0; j < grid[i.toInt()].length-1; j++) {

        _positions.add(((i - 1.0 +  (x * tileResolution))-x)/4);
        var z = 0.8 * perlinCalc.perlinOctaveNoise(((i + (x * tileResolution))-x)/4/tileResolution, ((j + (y * tileResolution))-y)/4/tileResolution, change, 1.0, 4, 0.606);
        _positions.add(z);
        _posToSend.add(z);
        _positions.add(((j - 1.0 +  (y * tileResolution))-y)/4);

      }
    }

    _normals = createNormals(_elements, _positions);
    /*int _normalsEnd = _normals.length;
    for(int i = 0; i < _normals.length; i++){
      if(_normals[i] == 0.0){
        _normalsEnd = i;
        break;
      }
    }
    */
    //_normals.removeWhere((item) => item == 0.0);

    sendPort.send([_posToSend,_normals]);//.sublist(0,_normalsEnd)]);
    //sendPort.send([_posToSend]);
    _normals = null;
    _positions = null;

  }

  createPerlinNoise(List<List<int>> CTMap){

    grid = CTMap;

    List _positions = new List();
    List _normals = new List();
    _elements = new List();

    //Create the vertices only if
    for (double i = 0.0; i < grid.length-1; i++) {
      for (double j = 0.0; j < grid[i.toInt()].length-1; j++) {
        _positions.add(i);
        _positions.add(10.0);
        _positions.add(j);
      }
    }

    int current = null;
    int cm1 = null;
    int cp1 = null;
    int currentp1 = null;

    //Produce the indices only if they can be used to produce a completed fragment
    for (int i = 0; i < grid.length-1; i++) {
      for (int j = 0; j < grid[i].length-1; j++) {
        if (grid[i][j] != 0) {
          if (i + 1 <= grid.length - 1) {
            if (grid[i + 1][j] != 0) {
              current = null;
              cm1 = null;
              cp1 = null;
              currentp1 = null;
              //This is really bad, but works.
              //Search through all vertices to check if the current one we are working on exists,
              //if it does then create the indices,
              //else do nothing
              for (int k = 0; k < _positions.length; k += 3) {
                if (_positions[k] == j && _positions[k + 2] == i) {
                  current = k ~/ 3;
                } else if (_positions[k] == j + 1 && _positions[k + 2] == i) {
                  currentp1 = k ~/ 3;
                } else if (_positions[k] == j && _positions[k + 2] == i + 1) {
                  cm1 = k ~/ 3;
                } else
                if (_positions[k] == j + 1 && _positions[k + 2] == i + 1) {
                  cp1 = k ~/ 3;
                }
              }
              if (cp1 == null ||
                  cm1 == null ||
                  current == null ||
                  currentp1 == null) {
                //print("$i:, \n $j:");
              } else {
                _elements.add(currentp1);
                _elements.add(cm1);
                _elements.add(cp1);
                _elements.add(current);
                _elements.add(currentp1);
                _elements.add(cm1);
              }
            }
          } else {
            if (grid[i - 1][j] != 0) {
              current = null;
              cm1 = null;
              cp1 = null;
              currentp1 = null;
              for (int k = 0; k < _positions.length; k += 3) {
                if (_positions[k] == j && _positions[k + 2] == i) {
                  current = k ~/ 3;
                } else if (_positions[k] == j + 1 && _positions[k + 2] == i) {
                  currentp1 = k ~/ 3;
                } else if (_positions[k] == j && _positions[k + 2] == i - 1) {
                  cm1 = k ~/ 3;
                } else
                if (_positions[k] == j + 1 && _positions[k + 2] == i - 1) {
                  cp1 = k ~/ 3;
                }
              }
              if (cp1 == null ||
                  cm1 == null ||
                  current == null ||
                  currentp1 == null) {
                //print("$i:, \n $j:");
              } else {
                _elements.add(currentp1);
                _elements.add(cm1);
                _elements.add(cp1);
                _elements.add(current);
                _elements.add(currentp1);
                _elements.add(cm1);
              }
            }
          }
        }
      }
    }

    _positions = new List();

    for (double i = 0.0; i < grid.length-1; i++) {
      for (double j = 0.0; j < grid[i.toInt()].length-1; j++) {

        _positions.add(((i - 1.0 +  (x * tileResolution))-x)/4);
        var z = 0.6 * perlinCalc.perlinOctaveNoise(((i + (x * tileResolution))-x)/4/tileResolution, ((j + (y * tileResolution))-y)/4/tileResolution, 1.0, 1.0, 4, 0.707);
        _positions.add(z);
        _positions.add(((j - 1.0 +  (y * tileResolution))-y)/4);

      }
    }
    _normals = createNormals(_elements, _positions);

    sendPort.send(["init",_positions, _elements, _normals]);
    _normals = null;
    _positions = null;

  }

  receivePort.listen((msg) {
    if(msg[0] == "init"){
      x = msg[1];
      y = msg[2];
      tileResolution = msg[3];
      createPerlinNoise(msg[4]);
    }else{
      updatePerlinNoise(msg[1]);
    }
  });
}
