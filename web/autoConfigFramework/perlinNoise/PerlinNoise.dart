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

  Map<String, int> attributes;
  Map<String, int> uniforms;

  Buffer indices;
  Buffer vertices;
  Buffer normals;

  int tileRes;
  int indicesLength;

  perlinNoise(RenderingContext gl, int tileRes){

    this.gl = gl;
    this.tileRes = tileRes;
    this.shader = createShader();

    setupPerlinData();

  }
  //wait till x, y, z is fixed
  void update(){

  }

  void render(Matrix4 viewMat, Matrix4 projectMat){
    gl.useProgram(this.shader);

    utils.setMatrixUniforms(gl, viewMat, projectMat, uniforms['uPMatrix'], uniforms['uMVMatrix'], uniforms['uNormalMatrix']);

    gl.enableVertexAttribArray(attributes['aVertexPosition']);
    gl.bindBuffer(ARRAY_BUFFER, vertices);
    gl.vertexAttribPointer(attributes['aVertexPosition'], 3, FLOAT, false, 0, 0);

    gl.enableVertexAttribArray(attributes['aVertexNormal']);
    gl.bindBuffer(ARRAY_BUFFER, normals);
    gl.vertexAttribPointer(attributes['aVertexNormal'], 3, FLOAT, false, 0, 0);


    gl.bindBuffer(ELEMENT_ARRAY_BUFFER, indices);
    gl.drawElements(TRIANGLES, indicesLength, UNSIGNED_SHORT, 0);

  }

  //need to fix the x, y, z
  void setupPerlinData(){
    var attrib = ['aVertexPosition', 'aVertexNormal'];
    var unif = ['uMVMatrix', 'uPMatrix', 'uNormalMatrix'];

    attributes = utils.linkAttributes(gl, shader, attrib);
    uniforms = utils.linkUniforms(gl, shader, unif);

    indices = gl.createBuffer();
    vertices = gl.createBuffer();
    normals = gl.createBuffer();

    int pos = 0;

    List indicesList = new List();
    List vertcesList = new List();
    List normalList = new List();

    //Generate a basic lattice

    for(int i = 0; i < tileRes-1; i++){
      for(int j = 0; j < tileRes-1; j++){

        //the position of the vertices in the indices array we want to draw.
        pos = (i*tileRes+j);

        //top half of square
        indicesList.add(pos);
        indicesList.add(pos+1);
        indicesList.add(pos+tileRes);

        //bottom half of square
        indicesList.add(pos+tileRes);
        indicesList.add(pos+tileRes+1);
        indicesList.add(pos+1);

      }
    }

    indicesLength = indicesList.length;

    for(double i = 0.0; i < tileRes; i++){
      for(double j = 0.0; j < tileRes; j++){

        vertcesList.add(j);
        vertcesList.add(0.0);
        vertcesList.add(i);

      }
    }

    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, indices);
    gl.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(indicesList), STATIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, vertices);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertcesList), DYNAMIC_DRAW);

    //needs to be completed after the vertices are bound, as the "createNormals" function changes the vertices
    normalList = createNormals(indicesList, vertcesList);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, normals);
    gl.bufferData(ARRAY_BUFFER, new Float32List.fromList(normalList), DYNAMIC_DRAW);

  }

  Program createShader(){

    String vertex = """
        attribute vec3 aVertexPosition;
        attribute vec3 aVertexNormal;

        uniform mat4 uMVMatrix;
        uniform mat4 uPMatrix;

        varying vec3 pos;
        varying vec3 norm;

        void main(void) {
            gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);

            pos = vec3(uMVMatrix * vec4(aVertexPosition, 1.0));
            norm = aVertexNormal;


      }""";

    String fragment = """
         precision mediump float;

          varying vec3 pos;
          varying vec3 norm;

          uniform samplerCube skyMap;

          void main(void) {

              vec3 cameraPos = vec3(0.0,10.0,0.0);

              vec3 I = normalize(cameraPos - pos);
              vec3 R = reflect(I, normalize(norm));
              gl_FragColor = textureCube(skyMap, R);
              //gl_FragColor = vec4(1.0,0.0,0.0,1.0);

      }""";

    return utils.loadShaderSource(gl, vertex, fragment);

  }

  List createNormals(List indices, List vertices){

    List normals = new List();

    for(int i = 0; i < vertices.length; i++) {
      normals.add(0.0);
      normals.add(0.0);
      normals.add(0.0);
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

      normals[(indices[i-2])*3 + 0] += N.x / l;
      normals[(indices[i-2])*3 + 1] += N.y / l;
      normals[(indices[i-2])*3 + 2] += N.z / l;

      normals[(indices[i-1])*3 + 0] += N.x / l;
      normals[(indices[i-1])*3 + 1] += N.y / l;
      normals[(indices[i-1])*3 + 2] += N.z / l;

      normals[(indices[i])*3 + 0] += N.x / l;
      normals[(indices[i])*3 + 1] += N.y / l;
      normals[(indices[i])*3 + 2] += N.z / l;

    }

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

    return normals;
  }


}