//
//  MapView.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 06/10/26.
//


import SwiftUI
import GoogleMaps

/*
 MapView: the SwiftUI screen that shows the map.
 - This is what ContentView will put at the BASE of its ZStack (Step D).
 - It is NOT a Destination: it's never pushed or dismissed,
   it's always there underneath the screens.
 - Same structure as Latest: an outer SwiftUI View + an inner
   UIViewRepresentable that holds the real GMSMapView.
 - The ZStack is where you'll add buttons on top of the map later
   (Latest puts its mapControls here).
 */
struct MapView: View {
    var body: some View {
        ZStack {
            MapGMSView()
                .ignoresSafeArea()   // map fills the whole screen, behind the notch/home bar
        }
    }
}

/*
 MapGMSView: a bridge from UIKit to SwiftUI.
 - GMSMapView is a UIKit view (UIView); SwiftUI can't show UIViews directly.
 - UIViewRepresentable is Apple's adapter: you tell SwiftUI how to
   CREATE the UIView (makeUIView) and how to UPDATE it (updateUIView).
 - private: only MapView uses it (same as Latest).
 - @MainActor: UIKit views must be created on the main thread.
 */
@MainActor
private struct MapGMSView: UIViewRepresentable {

    /*
     makeUIView: called ONCE, when SwiftUI first shows this view.
     Build and configure the GMSMapView here.
     - The API key must ALREADY be set (AppDelegate does that at launch),
       otherwise this line crashes.
     */
    func makeUIView(context: Context) -> GMSMapView {
        /*
         GMSMapViewOptions: the map's starting settings (Latest uses this too).
         camera: where the map starts looking.
         - latitude/longitude: change these to your city.
           (Example: Sydney.)
         - zoom: 1 = whole world, 15 = streets, 20 = buildings.
         */
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(
            withLatitude: -33.8688,
            longitude: 151.2093,
            zoom: 12
        )

        let mapView = GMSMapView(options: options)

        /*
         Turn off Google's built-in location dot and button for now.
         (Latest does the same; turning them on needs location permission,
         which we haven't set up.)
         */
        mapView.isMyLocationEnabled = false
        mapView.settings.myLocationButton = false

        return mapView
    }

    /*
     updateUIView: called whenever SwiftUI redraws this view.
     - Empty for now: nothing from SwiftUI changes the map yet.
     - Later: move the camera, add markers, etc. here (or through a ViewModel, like Latest).
     */
    func updateUIView(_ uiView: GMSMapView, context: Context) {}
}

/*
 Preview: Google Maps usually shows grey or blank in Xcode previews
 because AppDelegate (which sets the API key) doesn't run there.
 Test the map in the Simulator instead (⌘R).
 */
#Preview {
    MapView()
}
