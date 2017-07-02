library inputController;

import 'dart:collection';
import 'dart:html';
import 'dart:math';
import 'dart:typed_data';
import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

class inputController{

  Float32List model;
  Float32List projection;
  Float32List view;
  Float32List normal;

  double viewChangeX = 0.0;
  double viewChangeY = 0.0;

  Matrix4 modelMatrix = new Matrix4.identity();
  Matrix4 viewMatrix = new Matrix4.identity();
  Matrix3 normalMatrix= new Matrix3.identity();

  List<bool> keysPressed;
  bool mousePressed = false;

  Vector3 cameraPosition = new Vector3(0.0,0.0, -15.0);
  Vector3 cameraFocusPosition = new Vector3(0.0, 0.0, 0.0);
  Vector3 upDirection = new Vector3(0.0, 1.0, 0.0);

  //Testing

  int accumDX = 0;
  int accumDY = 0;

  var lastX = 0.0;
  var lastY = 0.0;

  bool up = false;
  bool down = false;
  bool strafeLeft = false;
  bool strafeRight = false;
  bool forward = false;
  bool backward = false;

  num floatVelocity = 1.0;
  num strafeVelocity = 1.0;
  num forwardVelocity = 1.0;
  num mouseSensitivity = 360.0;

  static const keyCodeA = 65;
  static const keyCodeD = 68;
  static const keyCodeS = 83;
  static const keyCodeW = 87;

  //End testing

  inputController(CanvasElement canvas){

    //Model
    /*
    model = new Float32List.fromList([
        4.045084971874737,
        0.0,
        2.938926261462366,
        0.0,
        1.7274575140626314,
        4.045084971874737,
        -2.377641290737884,
        0.0,
        -2.377641290737884,
        2.938926261462366,
        3.2725424859373686,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0
      ]);
  */
    //Code to create the initial model matrix
    //This really should be controlled in the model itself
    modelMatrix.scale(5.0,5.0,5.0);
    model = modelMatrix.storage;

    //Projection
    /*
      projection = new Float32List.fromList([
        0.8609958506224068,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0000000000000002,
        0.0,
        0.0,
        0.0,
        0.0,
        -1.040816326530612,
        -1.0,
        0.0,
        0.0,
        -2.0408163265306123,
        0.0
      ]);

      */
    //Code to create and set the perspective Matrix
    Matrix4 projectionMatrix = makePerspectiveMatrix(PI * 0.5, (canvas.width / canvas.height), 1.0, 1000.0);
    projection = projectionMatrix.storage;

    //View
    /*
      view = new Float32List.fromList([
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        -15.023358168141243,
        1.0
      ]);
*/
    //Code to create the initial view matrix

    viewMatrix = makeViewMatrix(cameraPosition, cameraFocusPosition, upDirection);
    view = viewMatrix.storage;

    Matrix4 _normalMatrix = viewMatrix * modelMatrix;
    normalMatrix = _normalMatrix.getNormalMatrix();
    normal = normalMatrix.storage;


    keysPressed = new List();
    for(int i = 0; i < 126; i++){
      keysPressed.add(false);
    }

    window.onKeyDown.listen(keyDown);
    window.onKeyUp.listen(keyUp);

    window.onMouseDown.listen(mouseDown);
    window.onMouseMove.listen(mouseMove);
    window.onMouseUp.listen(mouseUp);

    window.onTouchStart.listen(touchDown);
    window.onTouchMove.listen(touchMove);
    window.onTouchEnd.listen(touchUp);


  }

  updateCam(){

    int seconds = 1;

    _moveFloat(seconds, up, down);
    _moveStrafe(seconds, strafeRight, strafeLeft);
    _moveForward(seconds, forward, backward);
    _rotateView(seconds);

    viewMatrix = makeViewMatrix(cameraPosition, cameraFocusPosition, upDirection);
    view = viewMatrix.storage;

    Matrix4 _normalMatrix = viewMatrix * modelMatrix;
    normalMatrix = _normalMatrix.getNormalMatrix();
    normal = normalMatrix.storage;

  }

  //Basic control
  keyDown(KeyboardEvent e){
    switch (e.keyCode) {
      case keyCodeW:
        forward = true;
        break;
      case keyCodeA:
        strafeLeft = true;
        break;
      case keyCodeD:
        strafeRight = true;
        break;
      case keyCodeS:
        backward = true;
        break;
    }
  }

  keyUp(KeyboardEvent e){
    switch (e.keyCode) {
      case keyCodeW:
        forward = false;
        break;
      case keyCodeA:
        strafeLeft = false;
        break;
      case keyCodeD:
        strafeRight = false;
        break;
      case keyCodeS:
        backward = false;
        break;
    }
  }

  mouseDown(MouseEvent e){
    if(e.button == 0){
      mousePressed = true;
    }
  }

  mouseMove(MouseEvent e){
    if(mousePressed){

      accumDX += e.movement.x;
      accumDY += e.movement.y;

    }
  }

  mouseUp(MouseEvent e){
    if(e.button == 0){
      mousePressed = false;
    }
  }

  touchMove(TouchEvent event){
    if(mousePressed){

      accumDX += event.touches[0].client.x - lastX;
      accumDY += event.touches[0].client.y - lastY;

      lastX = event.touches[0].client.x;
      lastY = event.touches[0].client.y;

    }
  }

  touchDown(TouchEvent event){
    print("Touch");
    if(event.touches.length == 1){
      mousePressed = true;

      lastX = event.touches[0].client.x;
      lastY = event.touches[0].client.y;
    }
  }

  touchUp(TouchEvent event){
    mousePressed = false;
  }

  double degToRad(degrees) {
    return degrees * PI / 180;
  }

  //Testing

  Vector3 get frontDirection => cameraFocusPosition - cameraPosition;


  num _velocityScale(bool positive, bool negative) {
    num scale = 0.0;
    if (positive) {
      scale += 1.0;
    }
    if (negative) {
      scale -= 1.0;
    }
    return scale;
  }

  void _moveFloat(num dt, bool positive, bool negative) {
    var scale = _velocityScale(positive, negative);
    if (scale == 0.0) {
      return;
    }
    scale = scale * dt * floatVelocity;
    Vector3 upDirection = new Vector3(0.0, 1.0, 0.0);
    upDirection.scale(scale);
    cameraFocusPosition.add(upDirection);
    cameraPosition.add(upDirection);
  }

  void _moveStrafe(num dt, bool positive, bool negative) {
    var scale = _velocityScale(positive, negative);
    if (scale == 0.0) {
      return;
    }
    scale = scale * dt * strafeVelocity;
    Vector3 frontDirection = this.frontDirection;
    frontDirection.normalize();
    Vector3 upDirection = new Vector3(0.0, 1.0, 0.0);
    Vector3 strafeDirection = frontDirection.cross(upDirection);
    strafeDirection.scale(scale);
    cameraFocusPosition.add(strafeDirection);
    cameraPosition.add(strafeDirection);
  }

  void _moveForward(num dt, bool positive, bool negative) {
    var scale = _velocityScale(positive, negative);
    if (scale == 0.0) {
      return;
    }
    scale = scale * dt * forwardVelocity;

    Vector3 frontDirection = this.frontDirection;
    frontDirection.normalize();
    frontDirection.scale(scale);
    cameraFocusPosition.add(frontDirection);
    cameraPosition.add(frontDirection);
  }

  void _rotateView(num dt) {
    Vector3 frontDirection = this.frontDirection;
    frontDirection.normalize();
    Vector3 upDirection = new Vector3(0.0, 1.0, 0.0);
    Vector3 strafeDirection = frontDirection.cross(upDirection);
    strafeDirection.normalize();

    num mouseYawDelta = accumDX / mouseSensitivity;
    num mousePitchDelta = accumDY / mouseSensitivity;
    accumDX = 0;
    accumDY = 0;

    // Pitch rotation
    bool above = false;
    if (frontDirection.y > 0.0) {
      above = true;
    }
    num fDotUp = frontDirection.dot(upDirection);
    num pitchAngle = acos(fDotUp);
    num pitchDegrees = degrees(pitchAngle);

    const minPitchAngle = 0.785398163;
    const maxPitchAngle = 2.35619449;
    num minPitchDegrees = degrees(minPitchAngle);
    num maxPitchDegrees = degrees(maxPitchAngle);

    _rotateEyeAndLook(mousePitchDelta, strafeDirection);

    _rotateEyeAndLook(mouseYawDelta, upDirection);
  }

  void _rotateEyeAndLook(num delta_angle, Vector3 axis) {
    Quaternion q = new Quaternion.axisAngle(axis, delta_angle);

    Vector3 frontDirection = this.frontDirection;
    frontDirection.normalize();
    q.rotate(frontDirection);
    frontDirection.normalize();
    cameraFocusPosition = cameraPosition + frontDirection;
  }

  //end testing

}