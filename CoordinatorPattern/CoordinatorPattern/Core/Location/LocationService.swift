//
//  LocationService.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 07/10/26.
//

import CoreLocation
import Combine

/*
 LocationService: the app's ONE source of "where is the user?".
 - Wraps CLLocationManager (Apple's GPS + permission API).
 - ObservableObject + @Published: views (MapView) redraw when location changes.
 - NSObject: CLLocationManagerDelegate is an Objective-C protocol, so we must inherit NSObject.
 - final class: one shared instance (created in the App, like Presenter).
 */
final class LocationService: NSObject, ObservableObject {

    /*
     authorizationStatus: what the user chose in the permission popup.
     - .notDetermined       -> not asked yet
     - .authorizedWhenInUse -> allowed while the app is open ✅
     - .denied / .restricted -> no location
     private(set): views can READ it, only LocationService changes it.
     */
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    /*
     location: the latest known position (nil until the first GPS fix).
     CLLocation holds coordinate (lat/long), accuracy, timestamp, etc.
     */
    @Published private(set) var location: CLLocation?

    /*
     manager: Apple's object that does the real work.
     private: only LocationService talks to it.
     */
    private let manager = CLLocationManager()
    
    /*
         isAuthorized: a simple yes/no for views.
         true if the user allowed location (while using the app, or always).
         */
        var isAuthorized: Bool {
            authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        }

    override init() {
        // Read the CURRENT permission (the user may have answered on an earlier launch)
        authorizationStatus = manager.authorizationStatus
        super.init()

        /*
         delegate = self: CLLocationManager reports back by calling
         our delegate methods (see the extension below).
         desiredAccuracy: Best = most precise. Fine for a map; uses more battery.
         */
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /*
     requestPermission: shows the iOS popup, but ONLY the first time.
     - .notDetermined -> show the popup (uses the Info.plist text from Step 1)
     - already allowed -> start updates straight away
     - denied -> do nothing (iOS never shows the popup twice;
                 the user must change it in Settings)
     Called from MapView in Step 3.
     */
    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
}

/*
 CLLocationManagerDelegate: the methods CLLocationManager CALLS on us.
 We never call these ourselves.

 nonisolated + Task { @MainActor in ... }:
 - Your project runs code on the MainActor by default (build setting
   "Default Actor Isolation = MainActor").
 - Apple's delegate protocol isn't tied to the main actor, so we mark the
   methods `nonisolated` and hop back to the main thread before changing
   @Published values (UI state must change on the main thread).
 */
extension LocationService: CLLocationManagerDelegate {

    /*
     Called when the permission changes (the user tapped Allow / Don't Allow),
     and also once right after the manager is created.
     */
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status

            // Allowed -> start receiving GPS updates
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.startUpdatingLocation()
            }
        }
    }

    /*
     Called every time the GPS has a new position.
     locations: newest is LAST, so we keep .last.
     */
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.location = latest
        }
    }

    /*
     Called if getting the location fails (e.g. no GPS signal, or the Simulator
     has no location set). We just log it for now.
     */
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
}
