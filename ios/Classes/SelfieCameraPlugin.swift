import Flutter
import UIKit

public class SelfieCameraPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "selfie_camera", binaryMessenger: registrar.messenger())
    let instance = SelfieCameraPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

   public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "getPlatformVersion":
        result("iOS " + UIDevice.current.systemVersion)
      default:
        result(FlutterMethodNotImplemented)
      }
   }
}
