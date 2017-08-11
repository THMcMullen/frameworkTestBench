library shallowWater;

import 'dart:async';
import 'dart:isolate';

import '../utils.dart';
import 'dart:typed_data';
import 'dart:web_gl';
import 'package:vector_math/vector_math.dart';
import 'shallowWaterCalc.dart';



class shallowWater{

  RenderingContext gl;
  int tileResolution;
  List<List<int>> baseLayout;
  List bufferData;
  List<shallowWater> swl;

  List<double> g, h, h1, u, u1, v, v1;
  List<bool> b;

  Program shader;

  shallowWaterUpdate swu = new shallowWaterUpdate();

  ReceivePort receivePort;
  SendPort sendPort;
  bool useIsolate;

  var modelView;
  var projectionMat;
  var cameraLoc;

  var vertPosition;
  var vertNormal;

  Buffer positions;
  Buffer elements;
  Buffer normals;

  List _positions = new List();
  List _elements = new List();

  int numberOfElements = 0;

  int x;
  int y;

  double dt = 0.001;

  int _xp1 = null;
  int _xm1 = null;
  int _yp1 = null;
  int _ym1 = null;

  shallowWater(int tileRes, RenderingContext gl, int x, int y, bool useIsolate, List<shallowWater> swl, [List<List<int>> baseLayout]){
    this.gl = gl;
    this.tileResolution = tileRes;
    this.baseLayout = baseLayout;
    this.x = x;
    this.y = y;
    this.useIsolate = useIsolate;
    this.swl = swl;

    positions = this.gl.createBuffer();
    elements = this.gl.createBuffer();
    normals = this.gl.createBuffer();

    initLists();
    shader = createShader();
    setupProgram();

    checkEdges();

    if(useIsolate){
      receivePort = new ReceivePort();
      createIsolateShallowWater();
    }else{
      createShallowWaterSequential();
    }

  }

  void createShallowWaterSequential(){
    //swu = new shallowWaterUpdate();
    swu.waterSetup(g,b,h,h1,u,u1,v,v1, tileResolution, this.baseLayout, y);
    bufferData = swu.waterCreateBuffers(this.baseLayout, tileResolution, x, y);
    createTotalRenderData();
  }

  void createTotalRenderData(){

    //[_positions, _normals, _elements];
    numberOfElements = bufferData[2].length;

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.positions);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(bufferData[0]), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.normals);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(bufferData[1]), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, this.elements);
    gl.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(bufferData[2]), RenderingContext.STATIC_DRAW);
  }

  void updateRenderData(List updateData){
    for(int i = 1, j = 0; i < bufferData[0].length; i+=3, j++){
      bufferData[0][i] = updateData[0][j];
    }
    //bufferData[0] = updateData[0];

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.positions);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(bufferData[0]), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.normals);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(updateData[1]), RenderingContext.DYNAMIC_DRAW);
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

  updateSequential(){
    List _updatedRenderingData = swu.updateWater(g, b, h, h1, u, u1, v, v1, this.tileResolution, this.baseLayout, dt, x,y);
    updateRenderData(_updatedRenderingData);
  }

  checkEdges(){
    for(int i = 0; i < swl.length; i++){
      if(swl[i] != null){
        if(swl[i].x == this.x + 1 && swl[i].y == this.y){
          _xp1 = i;
        }
        if(swl[i].x == this.x - 1 && swl[i].y == this.y){
          _xm1 = i;
        }
        if(swl[i].x == this.x && swl[i].y == this.y - 1){
          _ym1 = i;
        }
        if(swl[i].x == this.x && swl[i].y == this.y + 1){
          _yp1 = i;
        }
      }
    }
    updateEdges();
  }

  updateEdges(){
    int size = tileResolution+2;
    String s = "";

    //print(h);
    for(int i = 0; i < size; i++){
      List l = (h.sublist(i * size, (i * size)+size));
      s += "$l \n";
    }
    s+= "----------------------------------------\n";
    //print(s);
    if(_xp1 != null){
      swu.setXp1(true);
      //print("_xp1");
      for(int i = 0; i < tileResolution+2; i++){
        int selfPos = (size*size) - (size*2) + i;
        int _xp1Pos = i + size + size;

        h [selfPos]  = swl[_xp1].h [_xp1Pos];
        h1[selfPos]  = swl[_xp1].h1[_xp1Pos];
        u [selfPos]  = swl[_xp1].u [_xp1Pos];
        u1[selfPos]  = swl[_xp1].u1[_xp1Pos];
        v [selfPos]  = swl[_xp1].v [_xp1Pos];
        v1[selfPos]  = swl[_xp1].v1[_xp1Pos];
      }
    }
    if(_xm1 != null){
      swu.setXm1(true);
      //print("_xm1");
      for(int i = 0; i < tileResolution+2; i++){
        int selfPos = i + size;
        int _xm1Pos = (size*size) - (size*3) + i;

        h [selfPos]  = swl[_xm1].h [_xm1Pos];
        h1[selfPos]  = swl[_xm1].h1[_xm1Pos];
        u [selfPos]  = swl[_xm1].u [_xm1Pos];
        u1[selfPos]  = swl[_xm1].u1[_xm1Pos];
        v [selfPos]  = swl[_xm1].v [_xm1Pos];
        v1[selfPos]  = swl[_xm1].v1[_xm1Pos];
      }
    }
    if(_yp1 != null){
      for(int i = 0; i < tileResolution+2; i++){

        int selfPos = (size * i) + size - 1;
        int _yp1Pos = (size * i) + 2;

        h [selfPos]  = swl[_yp1].h [_yp1Pos];
        h1[selfPos]  = swl[_yp1].h1[_yp1Pos];
        u [selfPos]  = swl[_yp1].u [_yp1Pos];
        u1[selfPos]  = swl[_yp1].u1[_yp1Pos];
        v [selfPos]  = swl[_yp1].v [_yp1Pos];
        v1[selfPos]  = swl[_yp1].v1[_yp1Pos];
      }
    }

    if(_ym1 != null){
      for(int i = 0; i < tileResolution+2; i++){

        int selfPos = (size * i) + 1;
        int _ym1Pos = (size * i) + size - 2;

        h [selfPos]  = swl[_ym1].h [_ym1Pos];
        h1[selfPos]  = swl[_ym1].h1[_ym1Pos];
        u [selfPos]  = swl[_ym1].u [_ym1Pos];
        u1[selfPos]  = swl[_ym1].u1[_ym1Pos];
        v [selfPos]  = swl[_ym1].v [_ym1Pos];
        v1[selfPos]  = swl[_ym1].v1[_ym1Pos];
      }
    }
  }

  update(){
    dt += 0.001;
    if(useIsolate){
      checkEdgesIsolate();
      updateIsolate();
    }else{
      checkEdges();
      updateSequential();
    }
  }

  initLists(){

    int res = this.tileResolution+2;

    g = new List<double>(res * res);
    b = new List<bool>(res * res);
    h = new List<double>(res * res);
    h1 = new List<double>(res * res);
    u = new List<double>(res * res);
    u1 = new List<double>(res * res);
    v = new List<double>(res * res);
    v1 = new List<double>(res * res);

    //If no layout is provided, create a large empty grid
    if(this.baseLayout == null){
      baseLayout = new List(res);
      for(int i = 0; i < res; i++){
        baseLayout[i] = new List(res);
        for(int j = 0; j < res; j++){
            //Create boundaries around the layouts edges
          if((i == 0) || (j == 0) || (i == res-1) || (j == res-1)){
            this.baseLayout[i][j] = 0;
          }else {
            //This tells the algorithm that there are no boundaries at a given location.
            this.baseLayout[i][j] = 1;
          }
        }
      }
    }
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

    return loadShaderSource(gl, vertex, fragment);

  }

  setupProgram(){

    modelView = gl.getUniformLocation(shader, "modelView");
    projectionMat = gl.getUniformLocation(shader, "projection");

    cameraLoc = gl.getUniformLocation(shader, "cameraLoc");

    vertPosition = gl.getAttribLocation(shader, "position");
    vertNormal = gl.getAttribLocation(shader, "normal");

  }

  //Isolate

  checkEdgesIsolate(){
    Map edgeMap = new Map();
    for(int i = 0; i < swl.length; i++){
      if(swl[i] != null){
        if(swl[i].x == this.x + 1 && swl[i].y == this.y){
          edgeMap["_xp1"] = swl[i].sendPort;
        }
        if(swl[i].x == this.x - 1 && swl[i].y == this.y){
          edgeMap["_xm1"] = swl[i].sendPort;
        }
        if(swl[i].x == this.x && swl[i].y == this.y - 1){
          edgeMap["_ym1"] = swl[i].sendPort;
        }
        if(swl[i].x == this.x && swl[i].y == this.y + 1){
          edgeMap["_yp1"] = swl[i].sendPort;
        }
      }
    }

    //print(edgeMap.keys);

    if(sendPort != null){
      sendPort.send(["edges", edgeMap]);
    }

  }

  updateIsolate(){
    if(sendPort != null){
      sendPort.send(["update",dt]);
    }
  }

  temp() {
    if (sendPort == null) {
      new Future.delayed(const Duration(milliseconds: 15), temp);
    } else {
      sendPort.send(["init", tileResolution, this.baseLayout, x, y]);
    }
  }

  createIsolateShallowWater(){
    print("using isolate");

    receivePort.listen((msg){
      //print(msg);
      if (sendPort == null) {
        sendPort = msg;
      } else {
        if(msg[0] == "init"){
          bufferData = msg.sublist(1,4);
          createTotalRenderData();
        }else{
          updateRenderData(msg);
          //msg = null;

        }
        //print(msg);
      }
    });

    String workerUri = "autoConfigFramework/shallowWater/shallowWaterIsolate.dart";
    Isolate.spawnUri(Uri.parse(workerUri), [], receivePort.sendPort).whenComplete(temp);

  }

}