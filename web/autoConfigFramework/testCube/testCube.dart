library testCube;

import 'dart:typed_data';
import 'dart:web_gl';

import '../utils.dart' as utils;


class testCube{

  RenderingContext gl;
  Program shader;

  var positions2;
  var colors2;
  var elements2;

  var modelmat;
  var viewmat;
  var projectionmat;
  var positionmat;
  var colormat;

  testCube(RenderingContext gl){
    this.gl = gl;

    positions2 = gl.createBuffer();
    colors2 = gl.createBuffer();
    elements2 = gl.createBuffer();

    createCubeData();
    createShaders();
    setupProgram();


  }

  render(Float32List modelMX, Float32List projectionMX, Float32List viewMX){

    gl.useProgram(this.shader);

    gl.uniformMatrix4fv(modelmat, false, modelMX);
    gl.uniformMatrix4fv(projectionmat, false, projectionMX);
    gl.uniformMatrix4fv(viewmat, false, viewMX);

    gl.enableVertexAttribArray(positionmat);
    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, positions2);
    gl.vertexAttribPointer(positionmat, 3, FLOAT, false, 0, 0);

    gl.enableVertexAttribArray(colormat);
    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, colors2);
    gl.vertexAttribPointer(colormat, 3, FLOAT, false, 0, 0);

    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, elements2);

    gl.drawElements(RenderingContext.TRIANGLES, 36, RenderingContext.UNSIGNED_SHORT, 0);

  }

  setupProgram(){
    modelmat = gl.getUniformLocation(shader, "model");
    viewmat = gl.getUniformLocation(shader, "view");
    projectionmat = gl.getUniformLocation(shader, "projection");

    positionmat = gl.getAttribLocation(shader, "position");
    colormat = gl.getAttribLocation(shader, "color");

  }

  createCubeData() {
    var positions = [
      // Front face
      -1.0, -1.0, 1.0,
      1.0, -1.0, 1.0,
      1.0, 1.0, 1.0,
      -1.0, 1.0, 1.0,

      // Back face
      -1.0, -1.0, -1.0,
      -1.0, 1.0, -1.0,
      1.0, 1.0, -1.0,
      1.0, -1.0, -1.0,

      // Top face
      -1.0, 1.0, -1.0,
      -1.0, 1.0, 1.0,
      1.0, 1.0, 1.0,
      1.0, 1.0, -1.0,

      // Bottom face
      -1.0, -1.0, -1.0,
      1.0, -1.0, -1.0,
      1.0, -1.0, 1.0,
      -1.0, -1.0, 1.0,

      // Right face
      1.0, -1.0, -1.0,
      1.0, 1.0, -1.0,
      1.0, 1.0, 1.0,
      1.0, -1.0, 1.0,

      // Left face
      -1.0, -1.0, -1.0,
      -1.0, -1.0, 1.0,
      -1.0, 1.0, 1.0,
      -1.0, 1.0, -1.0
    ];

    var colorsOfFaces = [
      [0.3, 1.0, 1.0, 1.0], // Front face: cyan
      [1.0, 0.3, 0.3, 1.0], // Back face: red
      [0.3, 1.0, 0.3, 1.0], // Top face: green
      [0.3, 0.3, 1.0, 1.0], // Bottom face: blue
      [1.0, 1.0, 0.3, 1.0], // Right face: yellow
      [1.0, 0.3, 1.0, 1.0] // Left face: purple
    ];

    List<double> colors = [];

    for (var j = 0; j < 6; j++) {
      List<double> polygonColor = colorsOfFaces[j];

      for (var i = 0; i < 4; i++) {
        //colors.addAll(polygonColor);
        colors = []..addAll(colors)..addAll(polygonColor);

      }
    }

    var elements = [
      0, 1, 2, 0, 2, 3, // front
      4, 5, 6, 4, 6, 7, // back
      8, 9, 10, 8, 10, 11, // top
      12, 13, 14, 12, 14, 15, // bottom
      16, 17, 18, 16, 18, 19, // right
      20, 21, 22, 20, 22, 23 // left
    ];


    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, positions2);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(positions), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ARRAY_BUFFER, colors2);
    gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(colors), RenderingContext.DYNAMIC_DRAW);

    gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, elements2);
    gl.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(elements), RenderingContext.STATIC_DRAW);
  }

  createShaders(){
    String vertex = """
    //Each point has a position and color
    attribute vec3 position;
    attribute vec4 color;

    // The transformation matrices
    uniform mat4 model;
    uniform mat4 view;
    uniform mat4 projection;

    // Pass the color attribute down to the fragment shader
    varying vec4 vColor;
    varying vec3 pos;

    void main() {

      // Pass the color down to the fragment shader
      vColor = color;

      // Read the multiplication in reverse order, the point is taken from
      // the original model space and moved into world space. It is then
      // projected into clip space as a homogeneous point. Generally the
      // W value will be something other than 1 at the end of it.
      gl_Position = projection * view * model * vec4( position, 1.0 );
      pos = vec3(view * model * vec4(position, 1.0));
    }

    """;

    String fragment = """
      precision mediump float;
      varying vec4 vColor;
      varying vec3 pos;

      uniform samplerCube skyMap;

      void main() {
        vec3 cameraPos = vec3(0.0,0.0,0.0);

        vec3 norm = vec3(0.0,1.0,0.0);

        vec3 I = normalize(cameraPos - pos);
        vec3 R = reflect(I, normalize(norm));
        //gl_FragColor = textureCube(skyMap, R);
        //gl_FragColor = vColor;
        gl_FragColor = vec4(0.6, 0.6, 0.6, 1.0);
      }
    """;

    this.shader = utils.loadShaderSource(this.gl, vertex, fragment);
  }

}