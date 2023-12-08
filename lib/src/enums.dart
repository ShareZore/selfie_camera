import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

enum ImageResolution {
  /// 352x288 on iOS, 240p (320x240) on Android and Web
  low,

  /// 480p (640x480 on iOS, 720x480 on Android and Web)
  medium,

  /// 720p (1280x720)
  high,

  /// 1080p (1920x1080)
  veryHigh,

  /// 2160p (3840x2160 on Android and iOS, 4096x2160 on Web)
  ultraHigh,

  /// The highest resolution available.
  max,
}

extension ImageResolutionExtension on ImageResolution {
  ResolutionPreset get resolutionPreset {
    switch (this) {
      case ImageResolution.low:
        return ResolutionPreset.low;
      case ImageResolution.medium:
        return ResolutionPreset.medium;
      case ImageResolution.high:
        return ResolutionPreset.high;
      case ImageResolution.veryHigh:
        return ResolutionPreset.veryHigh;
      case ImageResolution.ultraHigh:
        return ResolutionPreset.ultraHigh;
      case ImageResolution.max:
        return ResolutionPreset.max;
    }
  }
}

enum CameraType {
  /// Front facing camera (a user looking at the screen is seen by the camera).
  front,

  /// Back facing camera (a user looking at the screen is not seen by the camera).
  back,

  /// External camera which may not be mounted to the device.
  external,
}

extension CameraTypeExtension on CameraType {
  CameraLensDirection? get cameraLensDirection {
    switch (this) {
      case CameraType.front:
        return CameraLensDirection.front;
      case CameraType.back:
        return CameraLensDirection.back;
      case CameraType.external:
        return CameraLensDirection.external;
      default:
        return null;
    }
  }
}

extension CameraLensDirectionExtension on CameraLensDirection {
  CameraType? get cameraType {
    switch (this) {
      case CameraLensDirection.front:
        return CameraType.front;
      case CameraLensDirection.back:
        return CameraType.back;
      case CameraLensDirection.external:
        return CameraType.external;
      default:
        return null;
    }
  }
}

/// The possible flash modes that can be set for a camera
enum CameraFlashType {
  /// Do not use the flash when taking a picture.
  off,

  /// Let the device decide whether to flash the camera when taking a picture.
  auto,

  /// Always use the flash when taking a picture.
  always
}

extension CameraFlashTypeExtension on CameraFlashType {
  FlashMode get flashMode {
    switch (this) {
      case CameraFlashType.off:
        return FlashMode.off;
      case CameraFlashType.auto:
        return FlashMode.auto;
      case CameraFlashType.always:
        return FlashMode.always;
    }
  }
}

enum CameraOrientation {
  /// If the device shows its boot logo in portrait, then the boot logo is shown
  /// in [portraitUp]. Otherwise, the device shows its boot logo in landscape
  /// and this orientation is obtained by rotating the device 90 degrees
  /// clockwise from its boot orientation.
  portraitUp,

  /// The orientation that is 90 degrees clockwise from [portraitUp].
  ///
  /// If the device shows its boot logo in landscape, then the boot logo is
  /// shown in [landscapeLeft].
  landscapeLeft,

  /// The orientation that is 180 degrees from [portraitUp].
  portraitDown,

  /// The orientation that is 90 degrees counterclockwise from [portraitUp].
  landscapeRight,
}

enum ImageScale {
  none,

  /// 4:3
  small,

  /// 1:1
  middle,

  /// 16:9
  big,
}

extension ImageScaleExtension on ImageScale {
  double get scale {
    switch (this) {
      case ImageScale.small:
        return 3 / 4;
      case ImageScale.middle:
        return 1 / 1;
      case ImageScale.big:
        return 9 / 16;
      case ImageScale.none:
        return 0;
    }
  }
}

extension CameraOrientationExtension on CameraOrientation {
  DeviceOrientation? get deviceOrientation {
    switch (this) {
      case CameraOrientation.portraitUp:
        return DeviceOrientation.portraitUp;
      case CameraOrientation.landscapeLeft:
        return DeviceOrientation.landscapeLeft;
      case CameraOrientation.portraitDown:
        return DeviceOrientation.portraitDown;
      case CameraOrientation.landscapeRight:
        return DeviceOrientation.landscapeRight;
      default:
        return null;
    }
  }
}
