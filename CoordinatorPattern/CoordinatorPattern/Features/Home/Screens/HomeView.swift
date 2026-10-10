//
//  HomeView.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 07/10/26.
//


import SwiftUI

/*
 HomeView: the panel at the bottom of the map with the feature buttons.
 - Same job as Latest's HomeView: build the ROW of FeatureButtons
   and decide what each tap does.
 - Latest puts the tap logic in HomeViewModel.handleViewAction.
   We keep it in the view for now (no ViewModel yet). Same idea, fewer files.
 - It's NOT a Destination: it's pinned in RootView (Step 4), always over the map.
 */
struct HomeView: View {

    /*
     The shared Presenter: HomeView asks it to open screens.
     FeatureButton itself never touches the Presenter. HomeView does.
     */
    @EnvironmentObject private var presenter: Presenter
    @EnvironmentObject private var authService: AuthService   // 👈 NEW
    var body: some View {
        /*
         HStack + ForEach: one FeatureButton per entry in homeRow.
         - This is the ForEach that was only in FeatureButton's preview:
           the SCREEN builds the row, the button draws one button.
         - id: \.self works because Feature is Hashable.
         */
        VStack(spacing: 12) {
            HStack {
                ForEach(FeatureButton.Feature.homeRow, id: \.self) { feature in
                    FeatureButton(feature) {
                        handleTap(feature)
                    }
                }
            }
            
            /*
             NEW: Log out. HomeView only calls AuthService.
             state -> .unauthenticated -> RootView.route -> Welcome.
             Task { }: logout() is async (it calls the server).
             */
            Button("Log out", role: .destructive) {
                Task { await authService.logout() }
            }
            .font(.footnote)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        /*
         Panel look: white card with rounded top corners and a soft shadow,
         so it reads as a panel
         */
        .background(
                   UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                    .fill(Color(.systemBackground).opacity(0.8))
                       .shadow(color: .black.opacity(0.5), radius: 8, y: -2)
                       .ignoresSafeArea(edges: .bottom)   // white goes under the home bar too
               )
    }

    /*
     handleTap: the BRIDGE from button -> screen.
     Feature (which button) -> D
     Same role as Latest's HomeViewModel.handleViewAction.

     All three use present(): they're sheets (isFullScreen == false),
     so the Presenter sets `sheethe map.

     Why not replaceAll like Lat
     - Our replaceAll ALWAYS puts the screen in fullScreenStack,
       even if it's meant to be as a full screen
       and Home would be hidden behind it.
     - Latest's Presenter is smaits SheetManager).
       present() is the correct call for ours.
     */
    private func handleTap(_ feature: FeatureButton.Feature) {
        switch feature {
               case .entry:  presenter.present(.entry)
               case .drill:  presenter.present(.drill)
               case .urgent: presenter.present(.urgent)
        }
    }
}

/*
 Preview: grey background stands in for the map,
 HomeView pinned at the bottom liew.
 */
#Preview {
    ZStack(alignment: .bottom) {
          Color.gray.opacity(0.5).ignoresSafeArea()
          HomeView()
      }
    .environmentObject(Presenter())
    .environmentObject(AuthService())
}

