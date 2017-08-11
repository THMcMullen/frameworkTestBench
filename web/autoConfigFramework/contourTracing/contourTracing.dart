library contourTracing;


class contourTracing{

  List layout;
  List updatedHeightMap;

  int tileRes;
  int counter = 0;
  int dir;
  int turnTries;

  int workingX;
  int workingY;

  double level = -0.5;


  contourTracing(List heightMap){
    this.tileRes = heightMap.length +2;

    layout = new List(tileRes);
    for(int i = 0; i < tileRes; i++){
      layout[i] = new List(tileRes);
      for(int j = 0; j < tileRes; j++){
        layout[i][j] = 0;
      }
    }

    updatedHeightMap = new List(tileRes);
    for(int i = 0; i < tileRes; i++){
      updatedHeightMap[i] = new List(tileRes);
      for(int j = 0; j < tileRes; j++){
        if( i == 0 || j == 0 || i == tileRes - 1 || j == tileRes - 1){
          updatedHeightMap[i][j] = 99;
        }else{
          updatedHeightMap[i][j] = heightMap[j-1][i-1];
        }
      }
    }

    createLayout();

  }

  createLayout(){
    for (int Oy = 0; Oy < tileRes; Oy++) {
      for (int Ox = 0; Ox < tileRes; Ox++) {
        workingY = Oy;
        workingX = Ox;

        if ((updatedHeightMap[workingY][workingX] <= level) && (layout[workingY][workingX] == 0)) {

          counter++;
          layout[workingX][workingY] = counter;

          dir = 2;

          do {
            dir = turnLeft(dir);
            turnTries = 0;
            while (move(dir) == false) {
              var Ndir = turnRight(dir);
              turnTries++;
              if (turnTries >= 4) {
                break;
              }
              dir = Ndir;
            }
            if (turnTries >= 4) {
              break;
            }
            if (move(dir)) {
              moveX(dir);
              moveY(dir);
            }

          } while (workingX != Ox || workingY != Oy);



        } else if (updatedHeightMap[workingY][workingX] <= level && layout[workingY][workingX] != 0) {
          int temp = layout[workingY][workingX];
          for (int z = Ox + 1; z < tileRes; z++) {
            //if we are still in the blob and have not found the end of it
            if (layout[Oy][z] != temp) {} else {
              //we have found the end of the blob, so skip x to the end part, and update z to get out of this loop
              Ox = z;
            }
          }
        }
      }
    }

    for (int i = 1; i < tileRes - 1; i++) {
      for (int j = 1; j < tileRes - 1; j++) {
        //check that above and left have the same label, and we fit the water condition
        if (layout[i - 1][j] != 0 && updatedHeightMap[i][j] <= level) {
          layout[i][j] = layout[i - 1][j];
        } else if (layout[i][j - 1] != 0 && updatedHeightMap[i][j] <= level) {
          layout[i][j] = layout[i][j - 1];
        }
      }
    }

    /*
    List temp = new List(layout.length);
    for(int i = 0; i < temp.length; i++){
      temp[i] = new List(layout.length);
    }
    for(int i = 0; i < temp.length; i++){
      for(int j = 0; j < temp.length; j++){
        temp[i][j] = layout[i][j];
      }
    }

    layout = temp;
    */
  }


  int turnLeft(var dir) {
    if (dir == 0) {
      dir = 3;
    } else if (dir == 1) {
      dir = 0;
    } else if (dir == 2) {
      dir = 1;
    } else if (dir == 3) {
      dir = 2;
    }
    return dir;
  }

  int turnRight(var dir) {
    if (dir == 0) {
      dir = 1;
    } else if (dir == 1) {
      dir = 2;
    } else if (dir == 2) {
      dir = 3;
    } else if (dir == 3) {
      dir = 0;
    }
    return dir;
  }

  bool move(var dir) {
    bool moving = false;

    if (dir == 0) {
      if (updatedHeightMap[workingY - 1][workingX] <= level &&
          ((layout[workingY - 1][workingX] == 0) ||
              (layout[workingY - 1][workingX] == counter))) {
        moving = true;
      }
    } else if (dir == 1) {
      if (updatedHeightMap[workingY][workingX + 1] <= level &&
          ((layout[workingY][workingX + 1] == 0) ||
              (layout[workingY][workingX + 1] == counter))) {
        moving = true;
      }
    } else if (dir == 2) {
      if (updatedHeightMap[workingY + 1][workingX] <= level &&
          ((layout[workingY + 1][workingX] == 0) ||
              (layout[workingY + 1][workingX] == counter))) {
        moving = true;
      }
    } else if (dir == 3) {
      if (updatedHeightMap[workingY][workingX - 1] <= level &&
          ((layout[workingY][workingX - 1] == 0) ||
              (layout[workingY][workingX - 1] == counter))) {
        moving = true;
      }
    }

    return moving;
  }

  void moveX(dir) {
    //right
    if (dir == 1) {
      if (updatedHeightMap[workingY][workingX + 1] <= level) {
        workingX = workingX + 1;
        layout[workingY][workingX] = counter;
      }
      //left
    } else if (dir == 3) {
      if (updatedHeightMap[workingY][workingX - 1] <= level) {
        workingX = workingX - 1;
        layout[workingY][workingX] = counter;
      }
    }
  }
  void moveY(dir) {
    //up
    if (dir == 0) {
      if (updatedHeightMap[workingY - 1][workingX] <= level) {
        workingY = workingY - 1;
        layout[workingY][workingX] = counter;
      }
      //down
    } else if (dir == 2) {
      if (updatedHeightMap[workingY + 1][workingX] <= level) {
        workingY = workingY + 1;
        layout[workingY][workingX] = counter;
      }
    }
  }

}