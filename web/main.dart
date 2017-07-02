// Copyright (c) 2017, McMullen. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'autoConfigFramework/testBench.dart';
import 'dart:html';

void main() {

  //number of times to run benchmark
  //1 for testing
  int testSize = 1;

  //the tiles resolution
  int tileRes = 129;
  //the number of tiles to benchmark
  int tileCount = 1;
  //the quality of the generated tile
  int tileQuality = 1;

  //allow for stepping through the program, rather than a defined update cycle
  bool autoRun = false;

  testBench unit;

  for(int i = 0; i < testSize; i++){

    unit = new testBench(tileRes, tileCount, tileQuality, autoRun);
    //keep rendering and logic separate
    unit.logic();
    unit.render(1);

  }



}
