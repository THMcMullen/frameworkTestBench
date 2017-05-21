library core;

import 'dart:html';
import 'dart:typed_data';
import 'dart:web_gl';
import 'dart:async';

import 'diamondSquare/diamondSqure.dart';
import 'package:vector_math/vector_math.dart';

import 'perlinNoise/PerlinNoise.dart';
import 'testCube/testCube.dart';
import 'inputController.dart';

class core {

  //used for webgl
  RenderingContext gl;
  CanvasElement canvas;

  Matrix4 projectionMat;

  //used for rendering the skybox
  List images;
  Texture skyBox;

  //Create a cube for testing
  testCube cube;

  //DiamondSqure;
  diamondSqure ds;

  //Camera, input handler
  inputController ic;

  bool ready = false;

  core(RenderingContext gl, CanvasElement canvas, int tileRes, int tileCount, int tileQuality ){

    this.gl = gl;
    this.canvas = canvas;

    ic = new inputController(this.canvas);

    cube = new testCube(this.gl);
    ds = new diamondSqure(0, 0, tileRes, this.gl);

    gl.clearColor(0.66, 0.66, 0.66, 1.0);
    gl.clearDepth(1.0);
    gl.enable(RenderingContext.DEPTH_TEST);

    ready = true;

  }

  draw(){
    if(ready) {
      ic.updateCam();
      gl.clear(RenderingContext.COLOR_BUFFER_BIT | RenderingContext
          .DEPTH_BUFFER_BIT);
      gl.bindTexture(TEXTURE_CUBE_MAP, skyBox);

      cube.render(ic.model, ic.projection, ic.view);
      ds.render(ic.model, ic.projection, ic.view, ic.normal);
    }

  }

  update(){
    if(ready) {

    }

  }

  //Loads textures, and stores them as a texture cube map
  loadTextures() {
    skyBox = gl.createTexture();
    gl.bindTexture(TEXTURE_CUBE_MAP, skyBox);
    for (int i = 0; i < images.length; i++) {
      gl.texImage2D(TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, RGB, RGB, UNSIGNED_BYTE,
          images[i]);
    }

    gl.texParameteri(TEXTURE_CUBE_MAP, TEXTURE_MAG_FILTER, LINEAR);
    gl.texParameteri(TEXTURE_CUBE_MAP, TEXTURE_MIN_FILTER, LINEAR);
    gl.texParameteri(TEXTURE_CUBE_MAP, TEXTURE_WRAP_S, CLAMP_TO_EDGE);
    gl.texParameteri(TEXTURE_CUBE_MAP, TEXTURE_WRAP_T, CLAMP_TO_EDGE);
  }

  void loadSkybox() {
    ImageElement right = new ImageElement(src: "images/right.jpg");
    ImageElement left = new ImageElement(src: "images/left.jpg");
    ImageElement top = new ImageElement(src: "images/top.jpg");
    ImageElement bottom = new ImageElement(src: "images/bottom.jpg");
    ImageElement back = new ImageElement(src: "images/back.jpg");
    ImageElement front = new ImageElement(src: "images/front.jpg");
    images = [left, right, top, bottom, front, back];
    //images = [left, right, front, back, top, bottom];

    var futures = [
      right.onLoad.first,
      left.onLoad.first,
      top.onLoad.first,
      bottom.onLoad.first,
      back.onLoad.first,
      front.onLoad.first
    ];

    Future.wait(futures).then((_) => loadTextures());
  }

}