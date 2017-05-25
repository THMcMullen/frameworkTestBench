library shallowWaterCalc;

import '../utils.dart';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'dart:web_gl';


waterSetup(List g, List b, List h, List h1, List u, List u1, List v, List v1, int tileRes, List<List<int>> baseLayout){

  int X = tileRes;
  int Y = tileRes;

  // Boundaries
  for (int iy = 0; iy < Y; iy++) {
    for (int ix = 0; ix < X; ix++) {
      if (ix == 0 || iy == 0 || ix == X - 1 || iy == Y - 1) {
        b[iy * tileRes + ix] = true;
      } else {
        b[iy * tileRes + ix] = false;
      }
    }
  }
  //Not needed for testing
  /*
  for (int iy = 0; iy < tileRes; iy++) {
    for (int ix = 0; ix < tileRes; ix++) {
      if (grid[iy][ix] == 0) {
        b[iy * X + ix] = true;
      }
    }
  }
  */
  // Ground
  for (int iy = 0; iy < Y; iy++) {
    for (int ix = 0; ix < X; ix++) {
      g[iy * X + ix] = 0.0;
      //g[iy*X + ix] = iy * 0.2;
    }
  }

  // Height
  for (int iy = 0; iy < Y; iy++) {
    for (int ix = 0; ix < X; ix++) {
      h[iy * X + ix] = 0.0;
      h1[iy * X + ix] = h[iy * X + ix];
    }
  }

  // Horizontal Velocity
  for (int iy = 0; iy < Y; iy++) {
    for (int ix = 0; ix < X; ix++) {
      u[iy * X + ix] = 0.0;
      u1[iy * X + ix] = 0.0;
    }
  }

  // Vertical Velocity
  for (int iy = 0; iy < Y; iy++) {
    for (int ix = 0; ix < X; ix++) {
      v[iy * X + ix] = 0.0;
      v1[iy * X + ix] = 0.0;
    }
  }

  for (int iy = 0; iy < Y; iy++) {
    for (int ix = 0; ix < X; ix++) {

      double r = sqrt((ix - X / 2) * (ix - X / 2) + (iy - Y / 2) * (iy - Y / 2));

      if (r > Y / 2) {
        r = (r / (Y / 2)) * 4;
        double PI = 3.14159;
        h[iy * X + ix] += Y * (1 / sqrt(2 * PI)) * exp(-(r * r) / 2) + (1/r);

        //h[iy*X + ix] += ((Y/4) - r) * ((Y/4) - r);
      }
    }
  }

}

List updateWater(List g, List b, List h, List h1, List u, List u1, List v, List v1, int tileRes, List _elements, List<List<int>> grid, RenderingContext gl ){

  List _positions = new List();
  List _elements = new List<int>();
  List _normals = new List();

  int X = tileRes;
  int Y = tileRes;

  for(int i = 0; i < X; i++){
    for(int j = 0; j < Y; j++){
      _positions.add(i.toDouble());
      _positions.add(h[i * X + j]);
      _positions.add(j.toDouble());
    }
  }

  _normals = createNormals(_elements, _positions);

  Buffer positions = gl.createBuffer();
  Buffer normals = gl.createBuffer();

  gl.bindBuffer(RenderingContext.ARRAY_BUFFER, positions);
  gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_positions), RenderingContext.DYNAMIC_DRAW);

  gl.bindBuffer(RenderingContext.ARRAY_BUFFER, normals);
  gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_normals), RenderingContext.DYNAMIC_DRAW);

  return [positions,normals];



}

List waterCreateBuffers(List<List<int>> grid, RenderingContext gl){

  List _positions = new List();
  List _elements = new List<int>();
  List _normals = new List();

  //Create the vertices only if
  for (double i = 0.0; i < grid.length-2; i++) {
    for (double j = 0.0; j < grid[i.toInt()].length-2; j++) {
      _positions.add(i);
      _positions.add(0.5);
      _positions.add(j);
    }
  }

  int current = null;
  int cm1 = null;
  int cp1 = null;
  int currentp1 = null;

  //Produce the indices only if they can be used to produce a completed fragment
  for (int i = 0; i < grid.length-2; i++) {
    for (int j = 0; j < grid[i].length-2; j++) {
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
              } else if (_positions[k] == j + 1 && _positions[k + 2] == i + 1) {
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
              } else if (_positions[k] == j + 1 && _positions[k + 2] == i - 1) {
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

  _normals = createNormals(_elements, _positions);

  Buffer positions = gl.createBuffer();
  Buffer normals = gl.createBuffer();
  Buffer elements = gl.createBuffer();
  List returnList = new List(4);

  gl.bindBuffer(RenderingContext.ARRAY_BUFFER, positions);
  gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_positions), RenderingContext.DYNAMIC_DRAW);
  returnList[0] = positions;

  gl.bindBuffer(RenderingContext.ARRAY_BUFFER, normals);
  gl.bufferData(RenderingContext.ARRAY_BUFFER, new Float32List.fromList(_normals), RenderingContext.DYNAMIC_DRAW);
  returnList[1] = normals;

  gl.bindBuffer(RenderingContext.ELEMENT_ARRAY_BUFFER, elements);
  gl.bufferData(RenderingContext.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList(_elements), RenderingContext.STATIC_DRAW);
  returnList[2] = elements;
  returnList[3] = _elements;

  return returnList;

}

