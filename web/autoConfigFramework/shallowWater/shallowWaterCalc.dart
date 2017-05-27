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

List updateWater(List g, List b, List h, List h1, List u, List u1, List v, List v1, int tileRes, List _elements, List<List<int>> grid, RenderingContext gl, double dt ){

  List _positions = new List();
  List _normals = new List();

  int X = tileRes;
  int Y = tileRes;

  upwind(0, tileRes, b,  h,  u,  v,  dt);
  upwind(1, tileRes, b,  h,  u,  v,  dt);
  upwind(2, tileRes, b,  h,  u,  v,  dt);

  // Update h
  //#pragma omp parallel for
  for (int iy = 0; iy < Y; iy++) {
    for (int ix = 0; ix < X; ix++) {
      // Temporary variables
      double u_yx;
      double u_yxp1;
      double v_yx;
      double v_yp1x;

      // Don't update boundaries
      if (b[iy * X + ix] == false) {
        // Velocity across a boundary is zero
        if (b[iy * X + ix - 1] == true) {
          u_yx = 0.0;
        } else {
          u_yx = u[iy * X + ix];
        }

        // Velocity across a boundary is zero
        if (b[iy * X + ix + 1] == true) {
          u_yxp1 = 0.0;
        } else {
          u_yxp1 = u[iy * X + ix + 1];
        }

        // Velocity across a boundary is zero
        if (b[(iy - 1) * X + ix] == true) {
          v_yx = 0.0;
        } else {
          v_yx = v[iy * X + ix];
        }

        // Velocity across a boundary is zero
        if (b[(iy + 1) * X + ix] == true) {
          v_yp1x = 0.0;
        } else {
          v_yp1x = v[(iy + 1) * X + ix];
        }

        // Update the Height
        h[iy * X + ix] = h[iy * X + ix] +
            0.5 * h[iy * X + ix] * ((u_yx - u_yxp1) + (v_yx - v_yp1x)) * dt;
      } else {
        h[iy * X + ix] = 0.0;
      }
    }
  }

  // Update U
  //#pragma omp parallel for
  for (int iy = 0; iy < Y; iy++) {
    for (int ix = 0; ix < X; ix++) {
      // Don't update boundaries
      if (b[iy * X + ix] == false) {
        if (b[iy * X + ix - 1] == true) {
          u[iy * X + ix] = 0.0;
        } else {
          u[iy * X + ix] = u[iy * X + ix] +
              (0.98 *
                  ((g[iy * X + ix - 1] + h[iy * X + ix - 1]) -
                      (g[iy * X + ix] + h[iy * X + ix])) *
                  dt);
        }
      } else {
        u[iy * X + ix] = 0.0;
      }
    }
  }

  //Update V
  //#pragma omp parallel for
  for (int iy = 0; iy < Y; iy++) {
    for (int ix = 0; ix < X; ix++) {
      // Don't update boundaries
      if (b[iy * X + ix] == false) {
        if (b[(iy - 1) * X + ix] == true) {
          v[iy * X + ix] = 0.0;
        } else {
          v[
          iy * X + ix] =
              v[iy * X + ix] +
                  (0.98 *
                      ((g[(iy - 1) * X + ix] + h[(iy - 1) * X + ix]) -
                          (g[iy * X + ix] + h[iy * X + ix])) *
                      dt);
        }
      } else {
        v[iy * X + ix] = 0.0;
      }
    }
  }


  for(int i = 0; i < X; i++){
    for(int j = 0; j < Y; j++){
      _positions.add(i.toDouble());
      _positions.add(h[i * X + j] * 10.0);
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
      _positions.add(10.0);
      _positions.add(j);
    }
  }

  int current = null;
  int cm1 = null;
  int cp1 = null;
  int currentp1 = null;

  //Produce the indices only if they can be used to produce a completed fragment
  for (int i = 1; i < grid.length-1; i++) {
    for (int j = 1; j < grid[i].length-1; j++) {
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

upwind(type, int tileRes, List b, List h, List u, List v, double dt) {
  
  int X = tileRes;
  int Y = tileRes;
  
  var t = new List<double>(X * Y);

  int x1, x2, y1, y2;
  double u_xy, v_xy;

  // Loop through each point
  for (int iy = 0; iy < Y; iy++) {
    int yp1 = iy + 1;
    int ym1 = iy - 1;
    for (int ix = 0; ix < X; ix++) {
      int xp1 = ix + 1;
      int xm1 = ix - 1;
      // Select a certain array
      switch (type) {
        case 0:
        // h
        // Don't update a boundary
          if (b[iy * X + ix] == true) {
            t[iy * X + ix] = h[iy * X + ix];
            break;
          }

          // Calculate velocity
          u_xy = (u[iy * X + ix] + u[iy * X + xp1]) / 2.0;
          v_xy = (v[iy * X + ix] + v[yp1 * X + ix]) / 2.0;

          // Horizontal coordinates
          x1 = (u_xy < 0) ? xp1 : ix;
          x2 = (u_xy < 0) ? ix : xm1;

          // Vertical coordinates
          y1 = (v_xy < 0) ? yp1 : iy;
          y2 = (v_xy < 0) ? iy : ym1;

          // Advected value
          t[iy * X + ix] = h[iy * X + ix] -
              ((u_xy * (h[iy * X + x1] - h[iy * X + x2])) +
                  (v_xy * (h[y1 * X + ix] - h[y2 * X + ix]))) *
                  dt;

          break;
        case 1:
        // u
        // Don't update a boundary
          if (b[iy * X + ix] == true) {
            t[iy * X + ix] = u[iy * X + ix];
            break;
          }

          // Calculate velocity
          u_xy = u[iy * X + ix];
          v_xy = (v[iy * X + xm1] +
              v[iy * X + ix] +
              v[yp1 * X + xm1] +
              v[yp1 * X + ix]) /
              4.0;

          // Horizontal coordinates
          x1 = (u_xy < 0) ? xp1 : ix;
          x2 = (u_xy < 0) ? ix : xm1;

          // Vertical coordinates
          y1 = (v_xy < 0) ? yp1 : iy;
          y2 = (v_xy < 0) ? iy : ym1;

          // Advected value
          t[iy * X + ix] = u[iy * X + ix] -
              ((u_xy * (u[iy * X + x1] - u[iy * X + x2])) +
                  (v_xy * (u[y1 * X + ix] - u[y2 * X + ix]))) *
                  dt;
          break;
        case 2:
        // v
        // Don't update a boundary
          if (b[iy * X + ix] == true) {
            t[iy * X + ix] = v[iy * X + ix];
            break;
          }

          // Calculate velocity
          u_xy = (u[ym1 * X + ix] +
              u[ym1 * X + xp1] +
              u[iy * X + ix] +
              u[iy * X + xp1]) /
              4.0;
          v_xy = v[iy * X + ix];

          // Horizontal coordinates
          x1 = (u_xy < 0) ? xp1 : ix;
          x2 = (u_xy < 0) ? ix : xm1;

          // Vertical coordinates
          y1 = (v_xy < 0) ? yp1 : iy;
          y2 = (v_xy < 0) ? iy : ym1;

          // Advected value
          t[iy * X + ix] = v[iy * X + ix] -
              ((u_xy * (v[iy * X + x1] - v[iy * X + x2])) +
                  (v_xy * (v[y1 * X + ix] - v[y2 * X + ix]))) *
                  dt;
          break;
      }
    }
  }

  switch (type) {
    case 0:
      copy(h, t);
      break;
    case 1:
      copy(u, t);
      break;
    case 2:
      copy(v, t);
      break;
  }
}

copy(List original, List update) {
  for (int i = 0; i < original.length; i++) {
    original[i] = update[i];
  }
}