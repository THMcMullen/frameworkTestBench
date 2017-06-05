library diamondSquareAlgorithm;

import 'dart:math';

//Takes a desired resolution, along with linking edges if they exist.
List createHeightMap(int tileResolution, [List _above, List _below, List _left, List _right]){

  List above;
  List below;
  List left;
  List right;

  if(_above != null){
    above = _above;
  }
  if(_below != null){
    below = _below;
  }
  if(_left != null){
    left = _left;
  }
  if(_left != null){
    left = _left;
  }

  //Create the heightmap to be of the desired size,
  //Initialize the heightmap to 0.0, to produce smooth ground
  List heightMap = new List(tileResolution);
  for(int i = 0; i < tileResolution; i++){
    heightMap[i] = new List(tileResolution);
    for(int j = 0; j < tileResolution; j++){
      heightMap[i][j] = 0.0;
    }
  }

  Random rng = new Random(5);
  double height = 5.0;


  for (int sideLength = tileResolution - 1; sideLength >= 2; sideLength = sideLength ~/ 2, height /= 2) {

    int halfSide = sideLength ~/ 2;
//print("Diamond Step ${sideLength}");
    for (int x = 0; x < tileResolution - 1; x += sideLength) {
      for (int y = 0; y < tileResolution - 1; y += sideLength) {

        double avg = heightMap[x][y]
                   + heightMap[x + sideLength][y]
                   + heightMap[x][y + sideLength]
                   + heightMap[x + sideLength][y + sideLength];

        avg /= 4.0;

        double offset = (-height) + rng.nextDouble() * (height - (-height));
        heightMap[x + halfSide][y + halfSide] = avg + offset;

      }
    }
//print("Square Step ${sideLength}");
    for (int x = 0; x < tileResolution; x += halfSide) {
      for (int y = (x + halfSide) % sideLength; y < tileResolution; y += sideLength) {

        double avg = heightMap[(x - halfSide + tileResolution) % tileResolution][y]
                   + heightMap[(x + halfSide) % tileResolution][y]
                   + heightMap[x][(y + halfSide) % tileResolution]
                   + heightMap[x][(y - halfSide + tileResolution) % tileResolution];

        avg /= 4.0;

        double offset = (-height) + rng.nextDouble() * (height - (-height));
        heightMap[x][y] = avg + offset;

        if (above != null && x == tileResolution - 1) {
          heightMap[tileResolution - 1][y] = above[y];
        }
        if (below != null && x == 0) {
          heightMap[0][y] = below[y];
        }
        if (left != null && y == 0) {
          heightMap[x][0] = left[x];
        }
        if (right != null && y == tileResolution - 1) {
          heightMap[x][tileResolution - 1] = right[x];
        }


      }
    }
  }

  return heightMap;

}