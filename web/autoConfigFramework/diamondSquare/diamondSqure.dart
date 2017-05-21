library diamondSqure;

import 'dart:typed_data';
import 'dart:web_gl';
import 'diamondSqureAlgorithm.dart';
import '../utils.dart' as utils;

import 'package:vector_math/vector_math.dart';

class diamondSqure{

  var heightMap;
  double height;

  int x = 0;
  int y = 0;
  int tileResolution = 0;

  RenderingContext gl;
  Program shader;

  Buffer positions;
  Buffer elements;
  Buffer normals;

  int numberOfElements = 0;

  //var modelmat;
  //var viewmat;
  var projectionmat;
  var normalmatrix;
  var modelView;

  var positionmat;
  var normalmat;

  diamondSqure(int x, int y, int tileResolution, RenderingContext gl){

    this.x = x;
    this.y = y;
    this.tileResolution = tileResolution;
    this.gl = gl;

    positions = this.gl.createBuffer();
    elements = this.gl.createBuffer();
    normals = this.gl.createBuffer();

    heightMap = createHeightMap(this.tileResolution);

    convertHeightMap();
    createShaders();
    setupProgram();

  }

  render(Float32List modelMX, Float32List projectionMX, Float32List viewMX, Float32List normalMX){

    gl.useProgram(this.shader);

    //gl.uniformMatrix4fv(modelmat, false, modelMX);
    //gl.uniformMatrix4fv(viewmat, false, viewMX);
    gl.uniformMatrix4fv(projectionmat, false, projectionMX);

    Matrix4 modelViewMatrix = (new Matrix4.fromList(viewMX));
    modelViewMatrix.multiply(new Matrix4.fromList(modelMX));
    gl.uniformMatrix4fv(modelView, false, modelViewMatrix.storage);

    gl.uniformMatrix3fv(normalmatrix, false, normalMX);

    gl.enableVertexAttribArray(positionmat);
    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.positions);
    gl.vertexAttribPointer(positionmat, 3, FLOAT, false, 0, 0);

    gl.enableVertexAttribArray(normalmat);
    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.normals);
    gl.vertexAttribPointer(normalmat, 3, FLOAT, false, 0, 0);

    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, this.elements);

    gl.drawElements(RenderingContext.TRIANGLES, numberOfElements, RenderingContext.UNSIGNED_SHORT, 0);

  }

  convertHeightMap(){

    List _positions = new List();
    List _elements = new List();
    List _normals = new List();

    int pos = 0;

    for (double i = 0.0; i < this.tileResolution; i++) {
      for (double j = 0.0; j < this.tileResolution; j++) {
        _positions.add(i);// * (128 / (this.tileResolution - 1)) + (128 * this.x) - (5 * 128));// + (locX*res) - res);
        _positions.add(heightMap[i.toInt()][j.toInt()]);
        _positions.add(j);// * (128 / (this.tileResolution - 1)) + (128 * this.y) - (5 * 128));// + (locY*res) - res);
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

    for (int i = 0; i < this.tileResolution; i++) {
      for (int j = 0; j < this.tileResolution; j++) {

        var r = new Vector3.zero();

        r.normalize();

        _normals.add(r.x);
        _normals.add(r.y);
        _normals.add(r.z);

      }
    }

    numberOfElements = _elements.length;

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.positions);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_positions), RenderingContext.DYNAMIC_DRAW);
    
    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, this.normals);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_normals), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, this.elements);
    gl.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(_elements), RenderingContext.STATIC_DRAW);

  }

  setupProgram(){

    //modelmat = gl.getUniformLocation(shader, "model");
    //viewmat = gl.getUniformLocation(shader, "view");
    modelView = gl.getUniformLocation(shader, "modelView");
    projectionmat = gl.getUniformLocation(shader, "projection");
    normalmatrix = gl.getUniformLocation(shader, "normalMatrix");

    positionmat = gl.getAttribLocation(shader, "position");
    normalmat = gl.getAttribLocation(shader, "normal");
  }

  createShaders() {
    String vertex = """
    //Each point has a position and color
    attribute vec3 position;
    attribute vec3 normal;

    // The transformation matrices
    //uniform mat4 model;
    //uniform mat4 view;
    uniform mat4 modelView;
    uniform mat4 projection;
    uniform mat3 normalMatrix;

    // Pass the color attribute down to the fragment shader
    varying vec4 vColor;
    varying vec3 vLighting;

    void main() {
      
      vec3 ambientLight = vec3(0.6,0.6,0.6);
      vec3 directionalLightColor = vec3(0.5, 0.5, 0.75);
      vec3 directionalVector = vec3(0.85, 0.8, 0.75);
    
      vec3 transformedNormal = normalMatrix * normal;
    
      float directional = max(dot(transformedNormal, directionalVector), 0.0);
      vLighting = ambientLight + (directionalLightColor * directional);
      
      // Pass the color down to the fragment shader
      vColor = vec4( position, 1.0 );

      // Read the multiplication in reverse order, the point is taken from
      // the original model space and moved into world space. It is then
      // projected into clip space as a homogeneous point. Generally the
      // W value will be something other than 1 at the end of it.
      
      //mat4 modelView = view * model;
      
      gl_Position = projection * modelView  * vec4( position, 1.0 );
    }

    """;

    String fragment = """
      precision mediump float;
      varying vec4 vColor;
      varying vec3 vLighting;

      void main() {
      
       vec4 color = vec4(vColor);
       float alpha = vColor.y / 5.0;
  
       if(vColor.y < -0.5)
         color = vec4(0.0, 0.0,1.0, 1.0 + alpha );
       else if(vColor.y < 1.5)
         color = vec4(0.3 + alpha, 0.8, 0.3 + alpha, 1.0);
       else
         color = vec4(0.8, 0.42, 0.42, (.6 + alpha) );
      
        gl_FragColor = color * vec4(vLighting,0.5);
      //  gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
      }
    """;

    this.shader = utils.loadShaderSource(this.gl, vertex, fragment);
  }



}