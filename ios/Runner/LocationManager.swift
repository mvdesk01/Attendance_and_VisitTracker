import Foundation
import CoreLocation
import Flutter

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private var locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastTime: Date?
    var methodChannel: FlutterMethodChannel?

    override private init() {
        super.init()
        locationManager.delegate = self
               // ✅ Avoid over-triggering
                locationManager.distanceFilter = 10  // meters

  // ✅ Lower accuracy to reduce battery drain
//         locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false

         // ✅ iOS 11+: prevent deferred updates
                if #available(iOS 11.0, *) {
                    locationManager.showsBackgroundLocationIndicator = false
                }
    }

    func configureChannel(with channel: FlutterMethodChannel) {
        self.methodChannel = channel
    }

     func startTracking() {
          locationManager.requestAlwaysAuthorization()
          locationManager.startUpdatingLocation()
          locationManager.startMonitoringSignificantLocationChanges() // backup wake-up
          UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
      }
//     func startTracking() {
//         locationManager.requestAlwaysAuthorization()
//         locationManager.startUpdatingLocation()
//     }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let current = locations.last else { return }

        let now = Date()
        var speed: Double = 0
        var distance: Double = 0

        if let last = lastLocation, let lastTime = lastTime {
            distance = current.distance(from: last)
            let duration = now.timeIntervalSince(lastTime)

            if duration > 0 {
                speed = (distance / duration) * 3.6
            }

            // ✅ Jitter filter: ignore small movements or poor accuracy
            if distance < 12 || current.horizontalAccuracy > 40 {
                print("⛔️ Skipped: distance < 5m or accuracy > 40m. Distance: \(distance), Accuracy: \(current.horizontalAccuracy)")
                return
            }

            // ✅ Skip near-identical points in <10s window
            if distance < 5 && duration < 10 {
                print("⛔️ Skipped: duplicate point. Distance: \(distance)m, Duration: \(duration)s")
                return
            }
        }

        lastLocation = current
        lastTime = now

        print("📍 Location: \(current.coordinate.latitude), \(current.coordinate.longitude), Speed: \(speed)km/h, Distance: \(distance)m")

        let data: [String: Any] = [
            "lat": current.coordinate.latitude,
            "lng": current.coordinate.longitude,
            "speed": speed,
            "distance": distance
        ]
        methodChannel?.invokeMethod("nativeLocationUpdate", arguments: data)
    }

   func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       if status == .authorizedAlways {
           print("✅ Authorized — will start tracking only when instructed")
       }
   }

   func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
           print("❌ Location error: \(error.localizedDescription)")
       }

   func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
       print("⚠️ Paused, resuming updates")
       manager.startUpdatingLocation()
   }

   func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
       print("✅ Resumed location updates")
   }

}














// code comment 22-12-2025
/*
import Foundation
import CoreLocation
import Flutter

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private var locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastTime: Date?
    var methodChannel: FlutterMethodChannel?

    override private init() {
        super.init()
        locationManager.delegate = self
               // ✅ Avoid over-triggering
                locationManager.distanceFilter = 10  // meters

  // ✅ Lower accuracy to reduce battery drain
//         locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false

         // ✅ iOS 11+: prevent deferred updates
                if #available(iOS 11.0, *) {
                    locationManager.showsBackgroundLocationIndicator = false
                }
    }

    func configureChannel(with channel: FlutterMethodChannel) {
        self.methodChannel = channel
    }

     func startTracking() {
          locationManager.requestAlwaysAuthorization()
          locationManager.startUpdatingLocation()
          locationManager.startMonitoringSignificantLocationChanges() // backup wake-up
          UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
      }
//     func startTracking() {
//         locationManager.requestAlwaysAuthorization()
//         locationManager.startUpdatingLocation()
//     }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let current = locations.last else { return }

        let now = Date()
        var speed: Double = 0
        var distance: Double = 0
        let maxValidSpeed = 150.0   // 150 km/h (even for car)
        var initCount = 0

        if let last = lastLocation, let lastTime = lastTime {
            distance = current.distance(from: last)
            let duration = now.timeIntervalSince(lastTime)

            if duration > 0 {
                speed = (distance / duration) * 3.6
            }

//             // Remove initial cached points
//             if initCount < 2 {
//                 initCount += 1
//                 print("⛔ Ignoring initial cached point")
//                 return
//             }
//
//             // Reject timestamp older than 5 seconds (stale points)
//             // YES — iOS often gives a location that is 1 to 10 minutes old.
//             if abs(current.timestamp.timeIntervalSinceNow) > 5 {
//                 print("⛔ Reject: stale / old CLLocation: timestamp = \(current.timestamp)")
//                 return
//             }

          // 1️⃣ Accuracy filter
            if current.horizontalAccuracy < 0 || current.horizontalAccuracy > 50 {
                print("⛔️ Reject: poor accuracy = \(current.horizontalAccuracy)m")
                return
            }
            // ✅ Jitter filter: ignore small movements or poor accuracy
            if distance < 12 || current.horizontalAccuracy > 40 {
                print("⛔️ Skipped: distance < 5m or accuracy > 40m. Distance: \(distance), Accuracy: \(current.horizontalAccuracy)")
                return
            }

            // ✅ Skip near-identical points in <10s window
            if distance < 5 && duration < 10 {
                print("⛔️ Skipped: duplicate point. Distance: \(distance)m, Duration: \(duration)s")
                return
            }
             // 3️⃣ Reject impossible speeds
              if speed > 150 {
                  print("⛔️ Reject: impossible speed = \(speed) km/h")
                  return
              }

              // 4️⃣ Reject large sudden jumps
               */
/* if distance > 200 {
                  print("⛔️ Reject: unrealistic jump = \(distance)m")
                  return
              } *//*

        }


        lastLocation = current
        lastTime = now

        print("📍 Location: \(current.coordinate.latitude), \(current.coordinate.longitude), Speed: \(speed)km/h, Distance: \(distance)m")

        let data: [String: Any] = [
            "lat": current.coordinate.latitude,
            "lng": current.coordinate.longitude,
            "speed": speed,
            "distance": distance
        ]
        methodChannel?.invokeMethod("nativeLocationUpdate", arguments: data)
    }

   func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       if status == .authorizedAlways {
           print("✅ Authorized — will start tracking only when instructed")
       }
   }

   func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
           print("❌ Location error: \(error.localizedDescription)")
       }

   func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
       print("⚠️ Paused, resuming updates")
       manager.startUpdatingLocation()
   }

   func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
       print("✅ Resumed location updates")
   }

}
 */




/*
import Foundation
import CoreLocation
import Flutter

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private var locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastTime: Date?
    var methodChannel: FlutterMethodChannel?

    override private init() {
        super.init()
        locationManager.delegate = self
               // ✅ Avoid over-triggering
                locationManager.distanceFilter = 10  // meters

  // ✅ Lower accuracy to reduce battery drain
//         locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false

         // ✅ iOS 11+: prevent deferred updates
                if #available(iOS 11.0, *) {
                    locationManager.showsBackgroundLocationIndicator = false
                }
    }

    func configureChannel(with channel: FlutterMethodChannel) {
        self.methodChannel = channel
    }

    func startTracking() {
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let current = locations.last else { return }

        let now = Date()
        var speed: Double = 0
        var distance: Double = 0

        if let last = lastLocation, let lastTime = lastTime {
            distance = current.distance(from: last)
            let duration = now.timeIntervalSince(lastTime)

            if duration > 0 {
                speed = (distance / duration) * 3.6
            }

            // ✅ Jitter filter: ignore small movements or poor accuracy
            if distance < 12 || current.horizontalAccuracy > 40 {
                print("⛔️ Skipped: distance < 5m or accuracy > 40m. Distance: \(distance), Accuracy: \(current.horizontalAccuracy)")
                return
            }

            // ✅ Skip near-identical points in <10s window
            if distance < 5 && duration < 10 {
                print("⛔️ Skipped: duplicate point. Distance: \(distance)m, Duration: \(duration)s")
                return
            }
        }

        lastLocation = current
        lastTime = now

        print("📍 Location: \(current.coordinate.latitude), \(current.coordinate.longitude), Speed: \(speed)km/h, Distance: \(distance)m")

        let data: [String: Any] = [
            "lat": current.coordinate.latitude,
            "lng": current.coordinate.longitude,
            "speed": speed,
            "distance": distance
        ]
        methodChannel?.invokeMethod("nativeLocationUpdate", arguments: data)
    }

   func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       if status == .authorizedAlways {
           print("✅ Authorized — will start tracking only when instructed")
       }
   }

   func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
           print("❌ Location error: \(error.localizedDescription)")
       }

}
 */










/*
import Foundation
import CoreLocation
import UIKit
import Flutter

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private var locationManager = CLLocationManager()

    // Flutter method channel to send location to Dart
    var methodChannel: FlutterMethodChannel?

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func startTracking() {
        print("📍 iOS Native: Start tracking called")
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        print("🛑 iOS Native: Stop tracking called")
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📡 Native Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

//         Send to Flutter via method channel
        methodChannel?.invokeMethod("nativeLocationUpdate", arguments: [
            "lat": location.coordinate.latitude,
            "lng": location.coordinate.longitude
        ])
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}
 */









/*
import Foundation
import CoreLocation
import UIKit


class LocationManager:NSObject,CLLocationManagerDelegate{
static let shared = LocationManager()
private var locationManager = CLLocationManager()

override private init(){
super.init()
locationManager.delegate = self
locationManager.desiredAccuracy = kCLLocationAccuracyBest
locationManager.allowsBackgroundLocationUpdates =  true
locationManager.pausesLocationUpdatesAutomatically = false
}

func startTracking(){
locationManager.requestAlwaysAuthorization()
locationManager.startUpdatingLocation()
}

func stopTracking(){
locationManager.stopUpdatingLocation()
}

func locationManager(_ manager: CLLocationManager,didUpdateLocations location:[CLLocation]){
guard let location = location.last else{ return }
print("Locationnn: \(location.coordinate.latitude), \(location.coordinate.longitude)")
}

func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if status == .authorizedAlways {
        manager.startUpdatingLocation()
    }
}
}
 */
