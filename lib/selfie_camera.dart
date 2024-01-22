import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'selfie_camera.dart';
import 'src/logger.dart';
import 'src/selfie_widget.dart';
export 'src/enums.dart';

class SelfieCamera {
  static List<CameraDescription> _cameras = [];

  static bool _isLog = false;

  static Future<void> initialize({bool isLog = false}) async {
    try {
      _cameras = await availableCameras();
      _isLog = isLog;
    } on CameraException catch (e) {
      logError(e.code, e.description);
    }
  }
  
  static List<CameraDescription> get cameras {
    return _cameras;
  }

  static bool get isLog {
    return _isLog;
  }

  static Future<XFile?> selfieCameraFile(
    BuildContext context, {
    ImageResolution imageResolution = ImageResolution.medium,
    CameraType defaultCameraType = CameraType.front,
    CameraFlashType defaultFlashType = CameraFlashType.off,
    CameraOrientation? orientation,
    bool showControls = true,
    bool showCaptureControl = true,
    bool showFlashControl = true,
    bool showCameraTypeControl = true,
    bool showCloseControl = true,
    Widget? captureControlIcon,
    Widget? typeControlIcon,
    FlashControlBuilder? flashControlBuilder,
    Widget? closeControlIcon,
    ImageScale imageScale = ImageScale.none,
  }) async {
    XFile? cameraFile;
    await showDialog(
      barrierColor: Colors.black,
      context: context,
      builder: (context) {
        return SelfieWidget(
          imageResolution: imageResolution,
          defaultCameraType: defaultCameraType,
          defaultFlashType: defaultFlashType,
          orientation: orientation,
          showControls: showControls,
          showCaptureControl: showCaptureControl,
          showFlashControl: showFlashControl,
          showCameraTypeControl: showCameraTypeControl,
          showCloseControl: showCloseControl,
          onCapture: (file) {
            cameraFile = file;
            Navigator.pop(context);
          },
          captureControlIcon: captureControlIcon,
          typeControlIcon: typeControlIcon,
          flashControlBuilder: flashControlBuilder,
          closeControlIcon: closeControlIcon,
          imageScale: imageScale,
        );
      },
    );
    return cameraFile;
  }
}
