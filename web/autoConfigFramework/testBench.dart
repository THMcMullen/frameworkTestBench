library testBench;

import 'dart:html';
import 'dart:web_gl';
import 'dart:async';


import 'core.dart';

class testBench{

  core nexus;
  bool autoRun;

  testBench(tileRes, tileCount, tileQuality, autoRun){
    //Select the canvas as our render target
    CanvasElement canvas = querySelector("#render-target");
    RenderingContext gl = canvas.getContext3d();

    window.onKeyDown.listen(keyDown);

    this.nexus = new core(gl, canvas, tileRes, tileCount, tileQuality);
    this.nexus.loadSkybox();
    this.autoRun = autoRun;

  }

  logic(){
    if(autoRun) {
      new Future.delayed(const Duration(milliseconds: 30), logic);//.timeout((const Duration(milliseconds: 30)), onTimeout: () =>_onTimeOut());
    }
    nexus.update();
  }

  render(time){
    window.requestAnimationFrame(render);
    nexus.draw();
  }

  void _onTimeOut(){
    print("Timeout");
  }


  //small custom event, just for handling the enabling and disabling of autoRun
  keyDown(KeyboardEvent e) {
    //toggle autoRun
    if(e.keyCode == KeyCode.R){
      this.autoRun = !this.autoRun;
      logic();
    }
    //step through the logic / update cycle
    if(e.keyCode == KeyCode.T){
      logic();
    }
  }


}