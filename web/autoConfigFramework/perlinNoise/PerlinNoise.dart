library perlinNoise;

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


  var modelView;
  var projectionMat;

  Buffer positions;
  Buffer elements;
  Buffer normals;

  var vertPosition;
  var vertNormal;
  var cameraLoc;

  int numberOfElements = 0;

  var change  = 0.001;

  perlinNoise(int tileRes, RenderingContext gl){

    this.gl = gl;
    this.tileResolution = 50;

    positions = this.gl.createBuffer();
    elements = this.gl.createBuffer();
    normals = this.gl.createBuffer();

    this.shader = createShader();

    setupProgram();
    setupPerlinData();


  }
  //wait till x, y, z is fixed
  void update(){

    List _positions = new List();
    List _elements = new List();
    List _normals = new List();

    int pos = 0;

    if(change >= 256.0){
      change -= 256.0;
    }
    change += 0.001;

    for(double i = 0.0; i < this.tileResolution; i++){
      for(double j = 0.0; j < this.tileResolution; j++){

        _positions.add(i);
        var y = 5.0 * perlinCalc.perlinOctaveNoise(i/this.tileResolution, j/this.tileResolution, change, 1.0, 4, 0.707);
        _positions.add(y);
        _positions.add(j);

      }
    }

    for (int i = 0; i < this.tileResolution - 1; i++) {
      for (int j = 0; j < this.tileResolution - 1; j++) {

        pos = i * this.tileResolution + j;

        _elements.add(pos);
        _elements.add(pos + 1);
        _elements.add(pos + this.tileResolution);

        _elements.add(pos + this.tileResolution);
        _elements.add(pos + this.tileResolution + 1);
        _elements.add(pos + 1);

      }
    }

    numberOfElements = _elements.length;
    _normals = createNormals(_elements, _positions);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.positions);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_positions), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.normals);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_normals), RenderingContext.DYNAMIC_DRAW);

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

    List _positions = new List();
    List _elements = new List();
    List _normals = new List();

    int pos = 0;

    Random rng = new Random();

    for(double i = 0.0; i < this.tileResolution; i++){
      for(double j = 0.0; j < this.tileResolution; j++){

        _positions.add(i);
        _positions.add(0.0);
        _positions.add(j);

      }
    }

    for (int i = 0; i < this.tileResolution - 1; i++) {
      for (int j = 0; j < this.tileResolution - 1; j++) {

        pos = i * this.tileResolution + j;

        _elements.add(pos);
        _elements.add(pos + 1);
        _elements.add(pos + this.tileResolution);

        _elements.add(pos + this.tileResolution);
        _elements.add(pos + this.tileResolution + 1);
        _elements.add(pos + 1);

      }
    }

    numberOfElements = _elements.length;

    _normals = createNormals(_elements, _positions);
    print(_normals.length);
/*
    _normals = new List();

    for (int i = 0; i < this.tileResolution; i++) {
      for (int j = 0; j < this.tileResolution; j++) {

        var r = new Vector3.zero();

        r.normalize();

        _normals.add(r.x);
        _normals.add(r.y);
        _normals.add(r.z);

      }
    }
*/
    print(_normals.length);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.positions);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_positions), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.normals);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_normals), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, this.elements);
    gl.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(_elements), RenderingContext.STATIC_DRAW);



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

  List createNormals(List indices, List vertices){

    List _normals = new List();

    for(int i = 0; i < vertices.length; i++) {
      _normals.add(0.0);
      _normals.add(0.0);
      _normals.add(0.0);
    }

    Vector3 pointOne = new Vector3.zero();
    Vector3 pointTwo = new Vector3.zero();
    Vector3 pointThree = new Vector3.zero();

    Vector3 U = new Vector3.zero();
    Vector3 V = new Vector3.zero();

    for(int i = 0; i < indices.length; i++) {
      //every 3 indices equals one triangle
      //work out the vector that makes up the first point of the triangle
      pointOne.x = vertices[(indices[i]) * 3];
      pointOne.y = vertices[(indices[i]) * 3 + 1];
      pointOne.z = vertices[(indices[i]) * 3 + 2];
      i++;
      pointTwo.x = vertices[(indices[i]) * 3];
      pointTwo.y = vertices[(indices[i]) * 3 + 1];
      pointTwo.z = vertices[(indices[i]) * 3 + 2];
      i++;
      pointThree.x = vertices[(indices[i]) * 3];
      pointThree.y = vertices[(indices[i]) * 3 + 1];
      pointThree.z = vertices[(indices[i]) * 3 + 2];

      U = pointTwo - pointOne;
      V = pointThree - pointOne;

      Vector3 N = new Vector3.zero();

      N.x = ((U.y * V.z) - (U.z * V.y)); // * -1.0);
      N.y = ((U.z * V.x) - (U.x * V.z)); // * -1.0);
      N.z = ((U.x * V.y) - (U.y * V.x)); // * -1.0);

      if(N.y < 0.0) {
        N = -N;
      }

      double l = sqrt(N.x*N.x + N.y*N.y + N.z*N.z);

      _normals[(indices[i-2])*3 + 0] += N.x / l;
      _normals[(indices[i-2])*3 + 1] += N.y / l;
      _normals[(indices[i-2])*3 + 2] += N.z / l;

      _normals[(indices[i-1])*3 + 0] += N.x / l;
      _normals[(indices[i-1])*3 + 1] += N.y / l;
      _normals[(indices[i-1])*3 + 2] += N.z / l;

      _normals[(indices[i])*3 + 0] += N.x / l;
      _normals[(indices[i])*3 + 1] += N.y / l;
      _normals[(indices[i])*3 + 2] += N.z / l;

//      normals.add(N.x); normals.add(N.y); normals.add(N.z);
//      normals.add(N.x); normals.add(N.y); normals.add(N.z);
//      normals.add(N.x); normals.add(N.y); normals.add(N.z);

//      normals.add(((U.y * V.z) - (U.z * V.y))); // * -1.0);
//      normals.add(((U.z * V.x) - (U.x * V.z))); // * -1.0);
//      normals.add(((U.x * V.y) - (U.y * V.x))); // * -1.0);
//
//      normals.add(((U.y * V.z) - (U.z * V.y))); // * -1.0);
//      normals.add(((U.z * V.x) - (U.x * V.z))); // * -1.0);
//      normals.add(((U.x * V.y) - (U.y * V.x))); // * -1.0);
//
//      normals.add(((U.y * V.z) - (U.z * V.y))); // * -1.0);
//      normals.add(((U.z * V.x) - (U.x * V.z))); // * -1.0);
//      normals.add(((U.x * V.y) - (U.y * V.x))); // * -1.0);
    }
/*
    for(int i = 0; i < vertices.length; i += 3) {
      Vector3 N = new Vector3.zero();

      N.x = vertices[i];
      N.y = vertices[i+1];
      N.z = vertices[i+2];

      double l = sqrt(N.x*N.x + N.y*N.y + N.z*N.z);

      vertices[i]   = N.x / l;
      vertices[i+1] = N.y / l;
      vertices[i+2] = N.z / l;
    }
*/
    return _normals;
  }

}