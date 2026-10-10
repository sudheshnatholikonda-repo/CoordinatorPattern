//
//  MapView.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 06/10/26.
//


//
//  MapView.swift
//  CoordinatorPattern
//

import SwiftUI
import GoogleMaps
import CoreLocation

/*
 MapView: the SwiftUI screen that shows the map.
 - The BASE layer of RootView's ZStack (never pushed or dismissed).
 - Same structure as Latest: outer SwiftUI View + inner UIViewRepresentable.
 */
struct MapView: View {

    /*
     NEW: the shared LocationService (the App put it in the environment, Step 2).
     Because it's an ObservableObject, MapView redraws whenever
     `location` or `authorizationStatus` changes, which calls
     MapGMSView.updateUIView with the new values.
     */
    @EnvironmentObject private var locationService: LocationService

    var body: some View {
        ZStack {
            /*
             Pass the values DOWN into the UIKit map.
             MapGMSView doesn't read the environment itself; it just gets
             plain values, which keeps it simple.
             */
            MapGMSView(
                userLocation: locationService.location,
                isLocationAllowed: locationService.isAuthorized
            )
            .ignoresSafeArea()
        }
        /*
         NEW: ask for permission when the map first appears.
         - First launch: shows the iOS popup (text from Info.plist, Step 1).
         - Already allowed: starts GPS updates straight away.
         - Denied: does nothing.
         */
        .onAppear {
            locationService.requestPermission()
        }
    }
}

/*
 MapGMSView: bridge from UIKit (GMSMapView) to SwiftUI.
 */
@MainActor
private struct MapGMSView: UIViewRepresentable {

    /*
     NEW: inputs from MapView.
     - userLocation: latest GPS position (nil until the first fix).
     - isLocationAllowed: did the user tap "Allow"?
     */
    let userLocation: CLLocation?
    let isLocationAllowed: Bool

    /*
     NEW: makeCoordinator creates a small helper object that SwiftUI keeps
     alive for as long as the map exists.
     We use it to REMEMBER "have we already centred on the user?".
     (A struct like MapGMSView is recreated on every redraw, so it can't remember.)

     ⚠️ Name clash: this "Coordinator" is SwiftUI's term for a
     UIViewRepresentable helper. It has NOTHING to do with your Coordinator
     navigation pattern (Presenter / Destination).
     */
    func makeCoordinator() -> MapCoordinator {
        MapCoordinator()
    }

    /*
     makeUIView: called ONCE. Build the map with a starting camera.
     Sydney is just the starting view until the user's location arrives.
     */
    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(
            withLatitude: -33.8688,
            longitude: 151.2093,
            zoom: 12
        )
        return GMSMapView(options: options)
    }

    /*
     updateUIView: called on EVERY redraw, i.e. every time LocationService
     publishes a new location or permission.
     */
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        /*
         Blue dot + "my location" button (bottom-right),
         only once the user has allowed location.
         - isMyLocationEnabled: Google draws the blue dot itself.
         - myLocationButton: tap it to jump back to the user.
         (Latest turns these OFF because it draws its own avatar marker.)
         */
        mapView.isMyLocationEnabled = isLocationAllowed
        mapView.settings.myLocationButton = isLocationAllowed

        /*
         Move the camera to the user ONCE (on the first GPS fix).
         - If we did this on every update, the map would keep snapping back
           while the user is trying to pan around.
         - context.coordinator.hasCenteredOnUser remembers it across redraws.
         - animate(to:): smooth fly-over instead of a jump.
         - zoom 15 = street level.
         */
        guard let userLocation, !context.coordinator.hasCenteredOnUser else { return }
        context.coordinator.hasCenteredOnUser = true
        mapView.animate(to: GMSCameraPosition.camera(
            withTarget: userLocation.coordinate,
            zoom: 15
        ))
    }

    /*
     MapCoordinator: the "memory" object for this map (see makeCoordinator).
     final class: one instance, kept alive by SwiftUI.
     */
    final class MapCoordinator {
        var hasCenteredOnUser = false
    }
}

/*
 Preview needs a LocationService too, or it crashes
 (@EnvironmentObject has nothing to read).
 The map itself may be grey here; test in the Simulator.
 */
#Preview {
    MapView()
        .environmentObject(LocationService())
}

