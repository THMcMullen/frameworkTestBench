import 'dart:isolate';
import 'dart:async';
import 'diamondSqureAlgorithm.dart';

import 'package:vector_math/vector_math.dart';

main(List<String> args, SendPort sendPort) {
  ReceivePort receivePort = new ReceivePort();
  sendPort.send(receivePort.sendPort);

  int tileResolution;
  List _above;
  List _below;
  List _left;
  List _right;



  createHeightMapData(){

    List heightMap = createHeightMap(tileResolution, _above, _below, _left, _right);

    List _positions = new List();
    List _elements = new List();
    List _normals = new List();
    List _colors = new List();

    int pos = 0;

    for (double i = 0.0; i < tileResolution; i++) {
      for (double j = 0.0; j < tileResolution; j++) {
        _positions.add(i/4);
        _positions.add(heightMap[i.toInt()][j.toInt()] + 1.0);
        _positions.add(j/4);

        double alpha = heightMap[i.toInt()][j.toInt()] / 5;
        if(heightMap[i.toInt()][j.toInt()] < -0.5){
          _colors.add(0.0);
          _colors.add(0.0);
          _colors.add(1.0);
          _colors.add(1.0);
        }else if(heightMap[i.toInt()][j.toInt()] < 1.5){
          _colors.add(0.3 + alpha);
          _colors.add(0.8);
          _colors.add(0.3 + alpha);
          _colors.add(1.0);
        }else{
          _colors.add(0.8);
          _colors.add(0.42);
          _colors.add(0.42);
          _colors.add(0.6 + alpha);
        }
      }
    }

    for (int i = 0; i < tileResolution - 1; i++) {
      for (int j = 0; j < tileResolution - 1; j++) {
        pos = i * tileResolution + j;

        _elements.add(pos);
        _elements.add(pos + 1);
        _elements.add(pos + tileResolution);

        _elements.add(pos + tileResolution);
        _elements.add(pos + tileResolution + 1);
        _elements.add(pos + 1);

      }
    }

    for (int i = 0; i < tileResolution; i++) {
      for (int j = 0; j < tileResolution; j++) {

        var r = new Vector3.zero();

        r.normalize();

        _normals.add(r.x);
        _normals.add(r.y);
        _normals.add(r.z);

      }
    }

    sendPort.send([_positions, _colors, _elements, _normals]);

  }


  receivePort.listen((msg) {
    tileResolution = msg[0];
    _above = msg[1];
    _below = msg[2];
    _left = msg[3];
    _right = msg[4];

    createHeightMapData();

  });
}
