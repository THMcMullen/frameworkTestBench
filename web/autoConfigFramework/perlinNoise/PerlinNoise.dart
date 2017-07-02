library perlinNoise;

import '../utils.dart';
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
    this.tileResolution = tileRes;

    positions = this.gl.createBuffer();
    elements = this.gl.createBuffer();
    normals = this.gl.createBuffer();

    this.shader = createShader();

    setupProgram();
    setupPerlinData();


  }

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

        _positions.add(i /2);
        var y = 5.0 * perlinCalc.perlinOctaveNoise(i/this.tileResolution, j/this.tileResolution, change, 1.0, 4, 0.707);
        _positions.add(y);
        _positions.add(j /2);

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

}