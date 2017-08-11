library isolateController;

import 'dart:async';
import 'dart:isolate';

import 'perlinNoise/PerlinNoise.dart';



class isolateController{

  ReceivePort receivePort;
  List<SendPort> sendPort;

  List<perlinNoise> pnl;

  isolateController(List<perlinNoise> pnl){
    this.pnl = pnl;

    sendPort = new List<SendPort>(this.pnl.length);
    receivePort = new ReceivePort();
    //receivePort.timeout(const Duration(milliseconds: 0));

    createIsolatePerlinNoise();

  }

  createIsolatePerlinNoise(){
    print("using isolate");

    receivePort.listen((msg){
      int ID = int.parse(msg[0]);
      if (sendPort[ID] == null) {
        sendPort[ID] = msg[1];
        sendPort[ID].send(["init", this.pnl[ID].x, this.pnl[ID].y, this.pnl[ID].tileResolution]);
      } else {
        if(msg[1] == "init"){
          this.pnl[ID].createWebGLBuffers(msg);
        }else{
          this.pnl[ID].updateWebGLBuffers(msg);
        }
      }
    });
    String workerUri = "autoConfigFramework/perlinNoise/PerlinNoiseIsolate.dart";
    for(int i = 0; i < pnl.length; i++) {
      Isolate.spawnUri(Uri.parse(workerUri), ["$i"], receivePort.sendPort);
          //.whenComplete(temp);
    }

  }

  update(change){
    for(int i = 0; i < pnl.length; i++) {
      if(sendPort[i] != null) {
        sendPort[i].send([change]);
      }
    }
  }


}