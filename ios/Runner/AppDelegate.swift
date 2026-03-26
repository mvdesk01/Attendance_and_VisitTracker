import UIKit
import Flutter
import flutter_local_notifications
import GoogleMaps  // <-- Add this
import flutter_background_service_ios // add this
import CoreLocation


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

if let controller = window?.rootViewController as? FlutterViewController {
  let channel = FlutterMethodChannel(name: "location_channel", binaryMessenger: controller.binaryMessenger)
  LocationManager.shared.methodChannel = channel

  // Handle Flutter-to-native calls
  channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
    switch call.method {
    case "startNativeTracking":
      LocationManager.shared.startTracking()
      result("Started native location tracking")
    case "stopNativeTracking":
      LocationManager.shared.stopTracking()
      result("Stopped native location tracking")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
//   LocationManager.shared.startTracking()

   // 🔧 Set background task identifier
       SwiftFlutterBackgroundServicePlugin.taskIdentifier = "dev.flutter.background.refresh"

    // ✅ Replace with your actual Google Maps API key
    GMSServices.provideAPIKey("AIzaSyBC90u7o29p3ewzEWoTzXNlt1EQuYOZGV8")

    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
