library shallowWater;

import '../utils.dart';
import 'dart:typed_data';
import 'dart:web_gl';
import 'package:vector_math/vector_math.dart';
import 'shallowWaterCalc.dart';



class shallowWater{

  RenderingContext gl;
  int tileResolution;
  List<List<int>> baseLayout;
  List renderingData;

  List<double> g, h, h1, u, u1, v, v1;
  List<bool> b;

  Program shader;

  shallowWaterUpdate swu;

  var modelView;
  var projectionMat;
  var cameraLoc;

  var vertPosition;
  var vertNormal;

  int x;
  int y;

  shallowWater(int tileRes, RenderingContext gl, int x, int y, [List<List<int>> baseLayout]){
    this.gl = gl;
    this.tileResolution = tileRes;
    this.baseLayout = baseLayout;
    this.x = x;
    this.y = y;

    //print(baseLayout);

    initLists();
    shader = createShader();
    setupProgram();

    swu = new shallowWaterUpdate(gl);

    swu.waterSetup(g,b,h,h1,u,u1,v,v1, tileRes, this.baseLayout);
    renderingData = swu.waterCreateBuffers(this.baseLayout, gl);

  }

  void render(Float32List modelMX, Float32List projectionMX, Float32List viewMX, Vector3 cameraLoc){

    gl.useProgram(this.shader);

    gl.uniformMatrix4fv(projectionMat, false, projectionMX);

    Matrix4 modelViewMatrix = (new Matrix4.fromList(viewMX));
    modelViewMatrix.multiply(new Matrix4.fromList(modelMX));
    gl.uniformMatrix4fv(modelView, false, modelViewMatrix.storage);

    gl.uniform3fv(this.cameraLoc, cameraLoc.storage);

    gl.enableVertexAttribArray(vertPosition);
    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.renderingData[0]);
    gl.vertexAttribPointer(vertPosition, 3, FLOAT, false, 0, 0);

    gl.enableVertexAttribArray(vertNormal);
    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.renderingData[1]);
    gl.vertexAttribPointer(vertNormal, 3, FLOAT, false, 0, 0);

    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, this.renderingData[2]);
    gl.drawElements(RenderingContext.TRIANGLES, this.renderingData[3].length, RenderingContext.UNSIGNED_SHORT, 0);

  }

  double dt = 0.001;

  update(){
    List _elements = this.renderingData[3];
    List _updatedRenderingData = swu.updateWater(g, b, h, h1, u, u1, v, v1, this.tileResolution, _elements, this.baseLayout, dt, x,y);
    renderingData[0] = _updatedRenderingData[0];
    renderingData[1] = _updatedRenderingData[1];
    dt += 0.001;
  }


  initLists(){

    g = new List<double>(this.tileResolution * this.tileResolution);
    b = new List<bool>(this.tileResolution * this.tileResolution);
    h = new List<double>(this.tileResolution * this.tileResolution);
    h1 = new List<double>(this.tileResolution * this.tileResolution);
    u = new List<double>(this.tileResolution * this.tileResolution);
    u1 = new List<double>(this.tileResolution * this.tileResolution);
    v = new List<double>(this.tileResolution * this.tileResolution);
    v1 = new List<double>(this.tileResolution * this.tileResolution);

    //If no layout is provided, create a large empty grid
    if(this.baseLayout == null){
      baseLayout = new List(this.tileResolution+2);
      for(int i = 0; i < this.tileResolution+2; i++){
        baseLayout[i] = new List(this.tileResolution+2);
        for(int j = 0; j < this.tileResolution+2; j++){
            //Create boundaries around the layouts edges
          if((i == 0) || (j == 0) || (i == this.tileResolution+2) || (j == this.tileResolution+2)){
            this.baseLayout[i][j] = 200;
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

}