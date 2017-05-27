library utils;

import 'dart:math';
import 'dart:web_gl' as webgl;

import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';

webgl.Program loadShaderSource(webgl.RenderingContext gl, String vertShaderSource, String fragShaderSource){

  webgl.Shader fragShader = gl.createShader(webgl.RenderingContext.FRAGMENT_SHADER);
  webgl.Shader vertShader = gl.createShader(webgl.RenderingContext.VERTEX_SHADER);

  //Link Shaders and source code together
  gl.shaderSource(fragShader, fragShaderSource);
  gl.shaderSource(vertShader, vertShaderSource);

  gl.compileShader(vertShader);
  gl.compileShader(fragShader);

  //Create Shader Program, and link the shaders to it
  webgl.Program shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, vertShader);
  gl.attachShader(shaderProgram, fragShader);
  gl.linkProgram(shaderProgram);

  //check to make sure the shaders are set up correctly
  if(!gl.getProgramParameter(shaderProgram, webgl.RenderingContext.LINK_STATUS)){

    var s =  gl.deleteProgram(shaderProgram);
    print(gl.getShaderInfoLog(vertShader));
    print(gl.getShaderInfoLog(fragShader));
    print("$s shaders failed");

  }

  //shaders compiled correctly and should be working
  return shaderProgram;

}
/*
Map<String, int> linkAttributes(webgl.RenderingContext gl, webgl.Program shader, attr){
  Map<String, int> attrib = new Map.fromIterable(attr,
      key: (item) => item,
      value: (item) => gl.getAttribLocation(shader, item));

  return attrib;
}

Map<String, int> linkUniforms(webgl.RenderingContext gl, webgl.Program shader, uni){
  Map<String, int> uniform = new Map.fromIterable(uni,
      key: (item) => item,
      value: (item) => gl.getUniformLocation(shader, item));

  return uniform;
}
*/



//remove or replace this, there needs to be a better way
void setMatrixUniforms(webgl.RenderingContext gl, Matrix4 mvMatrix, Matrix4 pMatrix, webgl.UniformLocation pMatrixUniform, webgl.UniformLocation mvMatrixUniform, webgl.UniformLocation nMatrixUniform ){
  Float32List tempMV = new Float32List(16);
  Float32List tempP = new Float32List(16);
  Float32List tempN = new Float32List(9);

  normalFromMat4(out, a) {
    var a00 = a[0], a01 = a[1], a02 = a[2], a03 = a[3],
        a10 = a[4], a11 = a[5], a12 = a[6], a13 = a[7],
        a20 = a[8], a21 = a[9], a22 = a[10], a23 = a[11],
        a30 = a[12], a31 = a[13], a32 = a[14], a33 = a[15],

        b00 = a00 * a11 - a01 * a10,
        b01 = a00 * a12 - a02 * a10,
        b02 = a00 * a13 - a03 * a10,
        b03 = a01 * a12 - a02 * a11,
        b04 = a01 * a13 - a03 * a11,
        b05 = a02 * a13 - a03 * a12,
        b06 = a20 * a31 - a21 * a30,
        b07 = a20 * a32 - a22 * a30,
        b08 = a20 * a33 - a23 * a30,
        b09 = a21 * a32 - a22 * a31,
        b10 = a21 * a33 - a23 * a31,
        b11 = a22 * a33 - a23 * a32;

    // Calculate the determinant
    var det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

    det = 1.0 / det;

    out[0] = (a11 * b11 - a12 * b10 + a13 * b09) * det;
    out[1] = (a12 * b08 - a10 * b11 - a13 * b07) * det;
    out[2] = (a10 * b10 - a11 * b08 + a13 * b06) * det;

    out[3] = (a02 * b10 - a01 * b11 - a03 * b09) * det;
    out[4] = (a00 * b11 - a02 * b08 + a03 * b07) * det;
    out[5] = (a01 * b08 - a00 * b10 - a03 * b06) * det;

    out[6] = (a31 * b05 - a32 * b04 + a33 * b03) * det;
    out[7] = (a32 * b02 - a30 * b05 - a33 * b01) * det;
    out[8] = (a30 * b04 - a31 * b02 + a33 * b00) * det;

  }

  Matrix3 normMatrix = new Matrix3.zero();
  normalFromMat4(normMatrix, mvMatrix);

  for(int i = 0; i < 16 ; i++){
    tempMV[i] = mvMatrix[i];
    tempP[i] = pMatrix[i];
  }

  for(int j = 0; j < 9; j++){
    tempN[j] = normMatrix[j];
  }

  gl.uniformMatrix4fv(pMatrixUniform, false, tempP);
  gl.uniformMatrix4fv(mvMatrixUniform, false, tempMV);
  gl.uniformMatrix3fv(nMatrixUniform, false, tempN);

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


  }

  return _normals;
}


