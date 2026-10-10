//
//  FeatureButton.swift
//  CoordinatorPattern
//
//  Created by Sudheshna Tholikonda on 06/10/26.
//

import SwiftUI

/*
 FeatureButton: ONE round button (icon in a circle + label underneath).
 Same idea as Latest's FeatureButton, simplified:
 - SF Symbols instead of image assets
 - system colours instead of the design-system colours
 - a normal Button instead of Latest's custom press gesture
 */
struct FeatureButton: View {
    let feature: Feature
    private let action: () -> Void

    /*
     init(_ feature:action:): same call style as Latest:
         FeatureButton(.entry) { ... }
     - The `_` means no label: FeatureButton(.visit), not FeatureButton(feature: .entry).
     - action: what to do on tap. HomeView passes this in (Step 3).
       FeatureButton itself doesn't know about the Presenter.
     */
    init(_ feature: Feature, action: @escaping () -> Void) {
        self.feature = feature
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                /*
                 The circle with the icon in the centre.
                 - fill: white background
                 - overlay: the icon, tinted with the feature's colour
                 - second overlay: the thin grey border (Latest draws it separately too)
                 */
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: Constants.circleSize, height: Constants.circleSize)
                    .overlay(
                        Image(systemName: feature.iconName)
                            .font(.system(size: Constants.iconSize, weight: .semibold))
                            .foregroundStyle(feature.iconColor)
                    )
                    .overlay(
                        Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                Text(feature.title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)   // no default blue tint on the whole button
        .frame(maxWidth: .infinity)   // the 3 buttons share the row width equally
    }

    /*
     Feature: which button this is (Latest has the same enum, nested inside FeatureButton).
     Every per-button difference (icon, colour, title) is a computed property,
     so adding a 4th button (e.g. .comms) means adding a case + one line per switch.
     - Hashable: lets HomeView use ForEach(..., id: \.self) over the cases.
     */
    enum Feature: Hashable {
           case entry
           case drill
           case urgent

           // Buttons in display order (same name as Latest)
           static let homeRow: [Feature] = [.entry, .drill, .urgent]

           var title: String {
               switch self {
               case .entry:  "Entry"
               case .drill:  "Drill"
               case .urgent: "Urgent"     // was "Urgency". Change it back if you prefer that
               }
           }

           var iconName: String {
               switch self {
               case .entry:  "door.left.hand.open"
               case .drill:  "exclamationmark.triangle.fill"
               case .urgent: "sos"
               }
           }

           // Same colour idea as Latest: green / yellow / red
           var iconColor: Color {
               switch self {
               case .entry:  .green
               case .drill:  .yellow
               case .urgent: .red
               }
           }
       }

    private enum Constants {
        static let circleSize: CGFloat = 64
        static let iconSize: CGFloat = 26
    }
}

#Preview {
    HStack {
        ForEach(FeatureButton.Feature.homeRow, id: \.self) { feature in
            FeatureButton(feature) { print("tapped", feature) }
        }
    }
    .padding()
}
