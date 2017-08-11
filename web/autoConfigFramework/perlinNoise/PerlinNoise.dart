library perlinNoise;

import '../utils.dart';
import 'dart:async';
import 'dart:html';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math';
import 'dart:web_gl';
import 'package:vector_math/vector_math.dart';
import '../utils.dart' as utils;

import 'perlinCalc.dart' as perlinCalc;

class perlinNoise{

  Program shader;
  RenderingContext gl;

  int tileResolution;
  int x;
  int y;

  DateTime t0;
  DateTime t1;

  ReceivePort receivePort;
  SendPort sendPort;
  bool useIsolate;
  bool readyToRender = false;

  var modelView;
  var projectionMat;

  Buffer positions;
  Buffer elements;
  Buffer normals;

  var vertPosition;
  var vertNormal;
  var cameraLoc;

  int numberOfElements = 0;
  List _positions = new List();
  List _elements = new List();

  List<List<int>> grid;


  perlinNoise(int x, int y, int tileRes, RenderingContext gl, bool usingIsolate, [List<List<int>> grid]){

    this.gl = gl;
    this.tileResolution = tileRes;
    this.x = x;
    this.y = y;
    this.useIsolate = usingIsolate;
    this.grid = grid;

    positions = this.gl.createBuffer();
    elements = this.gl.createBuffer();
    normals = this.gl.createBuffer();

    this.shader = createShader();

    setupProgram();
    setupPerlinData();

  }

  temp() {
    if (sendPort == null) {
      new Future.delayed(const Duration(milliseconds: 15), temp);
    } else {
      sendPort.send(["init", this.x, this.y, this.tileResolution, grid]);
    }
  }

  createIsolatePerlinNoise(){
    print("using isolate");

    receivePort.listen((msg){
      if (sendPort == null) {
        sendPort = msg;

      } else {
        if(msg[0] == "init"){
          createWebGLBuffers(msg);
        }else{
          updateWebGLBuffers(msg);
          msg = null;
        }
      }
    });

    String workerUri = "autoConfigFramework/perlinNoise/PerlinNoiseIsolate.dart";
    Isolate.spawnUri(Uri.parse(workerUri), [], receivePort.sendPort).whenComplete(temp);

  }

  updateWebGLBuffers(isolateData){

    for(int i = 1, j = 0; i < _positions.length; i+=3, j++){
      _positions[i] = isolateData[0][j];
    }

    //print(isolateData[1]);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.positions);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_positions), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.normals);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(isolateData[1]), RenderingContext.DYNAMIC_DRAW);

  }

  createWebGLBuffers(isolateData){

    numberOfElements = isolateData[2].length;
    _positions = isolateData[1];

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.positions);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_positions), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.normals);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(isolateData[3]), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, this.elements);
    gl.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(isolateData[2]), RenderingContext.STATIC_DRAW);

    readyToRender = true;

  }

  void update(change){

    if(useIsolate){
      if(sendPort != null){
        //t0 = new DateTime.now();
        sendPort.send(["update",change]);
      }
    }else{
      updateSequential(change);
    }
  }

  void updateSequential(change){
    _positions = new List();
    List _normals = new List();

    for (double i = 0.0; i < grid.length-1; i++) {
      for (double j = 0.0; j < grid[i.toInt()].length-1; j++) {

        _positions.add(((i - 1.0 +  (x * this.tileResolution))-x)/4);
        var z = 0.6 * perlinCalc.perlinOctaveNoise(((i + (x * this.tileResolution))-x)/4/tileResolution, ((j + (y * this.tileResolution))-y)/4/tileResolution, change, 1.0, 8, 0.707);
        _positions.add(z);
        _positions.add(((j - 1.0 +  (y * this.tileResolution))-y)/4);

      }
    }

    numberOfElements = _elements.length;
    _normals = createNormals(_elements, _positions);

    //_normals.removeWhere((item) => item == 0.0);

    //print(_normals);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.positions);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_positions), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.normals);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_normals), RenderingContext.DYNAMIC_DRAW);

  }

  void setupPerlinDataSequential(){
    _positions = new List();
    _elements = new List();
    List _normals = new List();

    int pos = 0;

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

    numberOfElements = _elements.length;
    _normals = createNormals(_elements, _positions);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.positions);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_positions), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.normals);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_normals), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, this.elements);
    gl.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(_elements), RenderingContext.STATIC_DRAW);

  }

  void render(Float32List modelMX, Float32List projectionMX, Float32List viewMX, Vector3 cameraLoc){

    gl.useProgram(this.shader);

    gl.uniformMatrix4fv(projectionMat, false, projectionMX);

    Matrix4 modelViewMatrix = (new Matrix4.fromList(viewMX));
    modelViewMatrix.multiply(new Matrix4.fromList(modelMX));
    gl.uniformMatrix4fv(modelView, false, modelViewMatrix.storage);

    gl.uniform3fv(this.cameraLoc, cameraLoc.storage);

    gl.enableVertexAttribArray(vertPosition);
    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.positions);
    gl.vertexAttribPointer(vertPosition, 3, FLOAT, false, 0, 0);

    gl.enableVertexAttribArray(vertNormal);
    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.normals);
    gl.vertexAttribPointer(vertNormal, 3, FLOAT, false, 0, 0);

    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, this.elements);
    gl.drawElements(RenderingContext.TRIANGLES, this.numberOfElements, RenderingContext.UNSIGNED_SHORT, 0);

  }

  //need to fix the x, y, z
  void setupPerlinData(){

    if(grid == null){
      grid = new List(this.tileResolution+2);
      for(int i = 0; i < this.tileResolution+2; i++){
        grid[i] = new List(this.tileResolution+2);
        for(int j = 0; j < this.tileResolution+2; j++){
          //Create boundaries around the layouts edges
          if((i == 0) || (j == 0) || (i == this.tileResolution+2) || (j == this.tileResolution+2)){
            this.grid[i][j] = 200;
          }else {
            //This tells the algorithm that there are no boundaries at a given location.
            this.grid[i][j] = 1;
          }
        }
      }
    }

    if(useIsolate){
      receivePort = new ReceivePort();
      createIsolatePerlinNoise();
    }else{
      setupPerlinDataSequential();
    }
  }

  setupProgram(){

    modelView = gl.getUniformLocation(shader, "modelView");
    projectionMat = gl.getUniformLocation(shader, "projection");

    cameraLoc = gl.getUniformLocation(shader, "cameraLoc");

    vertPosition = gl.getAttribLocation(shader, "position");
    vertNormal = gl.getAttribLocation(shader, "normal");



  }

  Program createShader(){

    String vertex = """
        attribute vec3 position;
        attribute vec3 normal;


        uniform mat4 modelView;
        uniform mat4 projection;
        uniform vec3 cameraLoc;

        varying vec3 pos;
        varying vec3 norm;
        varying vec3 cameraPos;

        void main(void) {
            gl_Position = projection * modelView * vec4(position, 1.0);

//            pos = vec3(modelView * vec4(position, 1.0));
//            norm = vec3(modelView * vec4(normal, 0.0));
//
//            cameraPos = vec3(modelView * vec4(cameraLoc, 1.0));
            //norm = normal;

            pos = position;
            norm = normal;
            cameraPos = cameraLoc;


      }""";

    String fragment = """
         precision mediump float;

          varying vec3 pos;
          varying vec3 norm;
          varying vec3 cameraPos;

          uniform samplerCube skyMap;

          void main(void) {

              vec3 _cameraPos = vec3(0.0,0.0,0.0);

              //vec3 I = normalize(cameraPos - pos);
              vec3 I = normalize(pos - cameraPos);
              vec3 R = reflect(I, normalize(norm));
              gl_FragColor = textureCube(skyMap, R);
              //gl_FragColor = vec4(1.0,0.0,0.0,1.0);

      }""";

    return utils.loadShaderSource(gl, vertex, fragment);

  }

}