import 'package:flutter/material.dart';
import 'package:selfie_camera/selfie_camera.dart';

void logError(String message, [String? code]) {
  if (!SelfieCamera.isLog) return;
  if (code != null) {
    debugPrint('Error: $code\nError Message: $message');
  } else {
    debugPrint('Error: $code');
  }
}
